#!/usr/bin/env python3
"""Banc d'essai des modèles de lecture (V2.3 · A4, K3, K8).

Lance scan-menu et scan-label dans l'edge runtime local, contre le VRAI Gemini (la clé est
lue dans l'environnement de la personne qui lance le banc, jamais affichée ni écrite), avec
un faux Supabase qui impose le modèle et la réflexion de chaque variante. Juge chaque
réponse sur deux plans : la LECTURE (vins trouvés, producteurs, millésimes, prix, sans prix
inventé) et le SOMMELIER (couleur et profil des vins dont le profil ne fait pas débat :
Madiran tannique, Muscadet vif, Sauternes doux…). Chiffre le coût réel de chaque variante.

Aucune version de Gemini n'est écrite ici. Par défaut, le banc demande à Google la liste des
modèles et essaie les deux plus récents modèles stables de chaque famille (Flash,
Flash-Lite), à leur réflexion la plus basse : Gemini 3.9 ou 4.0 y entrera de lui-même. Le
rapport se termine par la ligne SQL qui adopte la variante la moins chère parmi celles qui
lisent presque aussi bien que la meilleure (97 %) et jugent presque aussi bien (95 %).

    python3 tool/banc_ia/banc.py ~/chatmelier-banc
    python3 tool/banc_ia/banc.py ~/chatmelier-banc --variantes gemini-3.8-flash:low,gemini-3.1-flash-lite:minimal
    python3 tool/banc_ia/banc.py ~/chatmelier-banc --rejuger    # après une correction des références :
                                                                # rejuge les réponses gardées, sans clé ni appel

Dossier attendu (les cartes se fabriquent avec tool/banc_ia/fabriquer_cartes.py) :
    cartes/<nom>/page1.jpg, page2.jpg…   + cartes/<nom>/reference.json
    etiquettes/<nom>.jpg                 + etiquettes/<nom>.json
Référence d'une carte : {"mode": "carte" | "ardoise", "pepites_au_plus": 2, "vins": [{"nom",
"producteur", "millesime", "prix", "prix_verre", "attendu": {"type": "red", "tannins": [7.5, 10]…},
"pepite_possible": true}]} — un prix nul veut dire « pas imprimé » ; « attendu »,
« pepites_au_plus » et « pepite_possible » sont facultatifs.
Référence d'une étiquette : {"producteur": …, "nom": …, "millesime": 2019, "appellation": …}

Sortie : <dossier>/rapport.md, rapport.json, les réponses entières dans reponses/, et le
journal des fonctions (journal_fonctions.txt), la clé toujours masquée.
"""
import base64
import datetime
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
import urllib.error
import urllib.request
from collections import Counter
from pathlib import Path

ICI = Path(__file__).resolve().parent
DEPOT = ICI.parent.parent
PORT_FONCTION = 9123
GEMINI_BASE = os.environ.get('GEMINI_BASE_URL') or 'https://generativelanguage.googleapis.com'
SEUIL_LECTURE = 0.97
SEUIL_SOMMELIER = 0.95


# ─── Les modèles : découverts, jamais écrits en dur ─────────────────────────────────────
def version(nom):
    m = re.match(r'gemini-(\d+(?:\.\d+)*)-', nom)
    return tuple(int(x) for x in m.group(1).split('.')) if m else ()


def famille(nom):
    return 'flash-lite' if '-flash-lite' in nom else ('flash' if '-flash' in nom else 'pro')


def modeles_stables():
    """Les modèles stables que Google publie pour cette clé, du plus récent au plus ancien."""
    req = urllib.request.Request(f'{GEMINI_BASE}/v1beta/models?pageSize=1000',
                                 headers={'x-goog-api-key': os.environ['GEMINI_API_KEY']})
    with urllib.request.urlopen(req, timeout=20) as r:
        data = json.loads(r.read())
    noms = [str(m.get('name', '')).split('/', 1)[-1] for m in data.get('models', [])
            if 'generateContent' in (m.get('supportedGenerationMethods') or [])]
    stables = [n for n in noms if re.fullmatch(r'gemini-\d+(?:\.\d+)*-(flash-lite|flash|pro)', n)]
    return sorted(set(stables), key=version, reverse=True)


NIVEAUX = {'minimal': 'minimale', 'low': 'basse', 'medium': 'moyenne', 'high': 'haute'}


def variante(modele, niveau):
    return (f'{modele}, réflexion {NIVEAUX.get(niveau, niveau)}', {'modele': modele, 'reflexion': niveau})


def variantes_par_defaut(par_famille=2):
    stables = modeles_stables()
    choix = [m for f in ('flash', 'flash-lite') for m in [x for x in stables if famille(x) == f][:par_famille]]
    # « minimal » : le plus bas ; la fonction monte d'un cran si le modèle le refuse.
    return [variante(m, 'minimal') for m in choix]


def variantes_demandees(texte):
    variantes = []
    for morceau in texte.split(','):
        modele, _, niveau = morceau.strip().partition(':')
        if modele:
            variantes.append(variante(modele, niveau or 'minimal'))
    return variantes


# ─── Les tarifs : ceux de la base (migration 051), même règle que cout_ia_usd ───────────
def charger_tarifs():
    sql = (DEPOT / 'supabase' / 'migrations' / '051_tarifs_ia.sql').read_text()
    lignes = re.findall(r"\('([^']+)',\s*(\d+),\s*([\d.]+),\s*([\d.]+),\s*DATE '([\d-]+)',\s*(?:NULL|DATE '([\d-]+)')", sql)
    return sorted([(motif, int(p), float(e), float(s), du, au or None) for motif, p, e, s, du, au in lignes],
                  key=lambda t: t[1])


TARIFS = charger_tarifs()


def comme(texte, motif):
    """Le LIKE de PostgreSQL : % pour n'importe quelle suite, _ pour un caractère."""
    return re.fullmatch(re.escape(motif).replace('%', '.*').replace('_', '.'), texte) is not None


def cout_eur(modele, usage):
    usage = usage or {}
    entree = usage.get('promptTokenCount', 0)
    sortie = usage.get('candidatesTokenCount', 0) + usage.get('thoughtsTokenCount', 0)
    jour = datetime.date.today().isoformat()
    e, s = 0.75, 3.75  # inconnu : au tarif Flash, comme la base
    for motif, _, te, ts, du, au in TARIFS:
        if comme((modele or '').lower(), motif) and du <= jour and (au is None or jour < au):
            e, s = te, ts
            break
    return (entree * e + sortie * s) / 1e6 * 0.92


# ─── Les comparaisons ───────────────────────────────────────────────────────────────────
MOTS_VIDES = {'de', 'du', 'des', 'la', 'le', 'les', 'del', 'di', 'della', 'y', 'et', 'and', 'the', 'l', 'd'}


def norme(t):
    t = unicodedata.normalize('NFD', str(t or '')).encode('ascii', 'ignore').decode().lower()
    return re.sub(r'[^a-z0-9]+', ' ', t).strip()


def ressemblance(a, b):
    """La part des mots du plus court que l'autre contient : l'ordre ne compte pas
    (« Pétalos del Bierzo » et « Bierzo Pétalos » se reconnaissent)."""
    # Un millésime recopié dans le nom (« Valdeorras Godello 2021 ») ne fait pas un autre vin.
    mots_a = {w for w in norme(a).split() if w not in MOTS_VIDES and not re.fullmatch(r'(19|20)\d\d', w)}
    mots_b = {w for w in norme(b).split() if w not in MOTS_VIDES and not re.fullmatch(r'(19|20)\d\d', w)}
    if not mots_a or not mots_b:
        return 0.0
    return len(mots_a & mots_b) / min(len(mots_a), len(mots_b))


def proche(a, b):
    return ressemblance(a, b) >= 0.75


def prix_juste(lu, attendu):
    """Un prix lu contre le prix imprimé ; sans prix imprimé, un prix lu est inventé."""
    if attendu is None:
        return lu in (None, 0, 0.0)
    return lu is not None and abs(float(lu) - attendu) < 0.01


def juger_sommelier(v, attendu):
    """Les attentes tenues sur un vin : sa couleur, et chaque mesure dans sa fourchette."""
    ok = total = 0
    for cle, cible in (attendu or {}).items():
        total += 1
        if cle == 'type':
            ok += v.get('wine_type') == cible
        else:
            val = (v.get('metrics') or {}).get(cle)
            ok += val is not None and cible[0] <= float(val) <= cible[1]
    return ok, total


def juger_carte(reponse, reference):
    vins = reponse.get('wines', [])
    attendus = reference.get('vins', [])
    pris = set()
    reference_de = {}
    trouves = prod = mill = prix = 0
    ok_s = tot_s = 0
    for a in attendus:
        candidats = [(ressemblance(w.get('name'), a.get('nom')), i) for i, w in enumerate(vins)
                     if i not in pris and (a.get('millesime') is None or w.get('vintage') == a.get('millesime'))]
        candidats = [c for c in candidats if c[0] >= 0.75]
        if not candidats:
            continue
        _, i = max(candidats)
        pris.add(i)
        reference_de[i] = a
        v = vins[i]
        trouves += 1
        prod += a.get('producteur') is None or proche(v.get('producer'), a.get('producteur'))
        mill += v.get('vintage') == a.get('millesime')
        verres = [g.get('price') for g in (v.get('glass_prices') or []) if isinstance(g, dict)]
        ok = prix_juste(v.get('bottle_price'), a.get('prix'))
        if 'prix_verre' in a:
            ok = ok and (any(prix_juste(g, a['prix_verre']) for g in verres) if a['prix_verre'] is not None
                         else not any(g not in (None, 0, 0.0) for g in verres))
        prix += ok
        s_ok, s_tot = juger_sommelier(v, a.get('attendu'))
        ok_s += s_ok
        tot_s += s_tot
    n = max(len(attendus), 1)
    # Les pépites (V2.3 · K9) : combien, si la carte en supporte autant, et si un sommelier
    # les défendrait (vin marqué « pepite_possible » dans la référence).
    pepites = [i for i, w in enumerate(vins) if w.get('is_gem')]
    jugement = {'vins_trouves': trouves / n, 'producteur': prod / n, 'millesime': mill / n, 'prix': prix / n,
                'sommelier': ok_s / tot_s if tot_s else None, 'vins_en_trop': max(0, len(vins) - trouves),
                'pepites': len(pepites), 'bons_plans': sum(1 for w in vins if w.get('is_deal')),
                'pepites_defendables': sum(1 for i in pepites if (reference_de.get(i) or {}).get('pepite_possible'))}
    if 'pepites_au_plus' in reference:
        jugement['pepites_dans_la_borne'] = 1.0 if len(pepites) <= reference['pepites_au_plus'] else 0.0
    return jugement


def juger_etiquette(reponse, reference):
    """Les champs que la photo montre. Une liste accepte plusieurs écritures (« Port »,
    « Porto ») ; un millésime nul attend qu'aucun ne soit inventé (tawny, champagne sans année)."""
    champs = {'producteur': 'producer', 'nom': 'name', 'millesime': 'vintage', 'appellation': 'appellation'}
    ok = {}
    for fr, en in champs.items():
        if fr not in reference:
            continue
        attendu = reference[fr]
        if fr == 'millesime':
            ok[fr] = reponse.get(en) == attendu
        else:
            ok[fr] = any(proche(reponse.get(en), x) for x in (attendu if isinstance(attendu, list) else [attendu]))
    return {k: 1.0 if v else 0.0 for k, v in ok.items()}


def juger_texte(reponse, attendu):
    """Identifier un vin depuis son nom (V2.4 · R1). « invente » est éliminatoire : un pays
    faux, ou un vin imaginaire présenté comme reconnu. Un vin réel non reconnu, ou sans pays,
    n'est qu'un manque."""
    resultat = reponse.get('resultat') if isinstance(reponse.get('resultat'), dict) else {}
    reconnu = resultat.get('reconnu') is not False
    pays = norme(resultat.get('country'))
    if attendu is None:
        return {'verdict': 'invente' if reconnu else 'juste', 'pays_lu': resultat.get('country')}
    if not reconnu:
        return {'verdict': 'non_reconnu', 'pays_lu': None}
    if not pays:
        return {'verdict': 'sans_pays', 'pays_lu': None}
    juste = any(norme(x) == pays or norme(x) in pays for x in attendu)
    return {'verdict': 'juste' if juste else 'invente', 'pays_lu': resultat.get('country')}


# ─── L'edge runtime local ───────────────────────────────────────────────────────────────
def lancer(fonction, reglages_par_tache):
    """Démarre le faux Supabase et l'edge runtime pour cette fonction et cette variante."""
    env = dict(os.environ, FAUX_MODELES_IA=json.dumps(reglages_par_tache))
    faux = subprocess.Popen([sys.executable, str(ICI / 'faux_serveur.py'), 'banc', '/tmp/banc_ia_journal.jsonl'], env=env)
    subprocess.run(['docker', 'rm', '-f', 'edge-banc'], capture_output=True)
    subprocess.run([
        'docker', 'run', '-d', '--name', 'edge-banc', '--network', 'host',
        '-v', f'{DEPOT}/supabase/functions:/home/deno/functions:ro',
        '-e', 'SUPABASE_URL=http://127.0.0.1:8765', '-e', 'SUPABASE_ANON_KEY=factice',
        '-e', 'SUPABASE_SERVICE_ROLE_KEY=factice',
        # La clé vient de l'environnement de la personne qui lance le banc (docker -e NOM
        # sans valeur la recopie) : elle n'apparaît ni dans ce script ni dans le rapport.
        '-e', 'GEMINI_API_KEY',
        # Essai à blanc seulement : pointer vers le faux Gemini (tool/banc_ia/faux_serveur.py).
        '-e', 'GEMINI_BASE_URL',
        'public.ecr.aws/supabase/edge-runtime:v1.74.3', 'start',
        '--main-service', f'/home/deno/functions/{fonction}', '--port', str(PORT_FONCTION),
    ], check=True, capture_output=True, env=os.environ)
    for _ in range(60):
        try:
            urllib.request.urlopen(urllib.request.Request(f'http://127.0.0.1:{PORT_FONCTION}/', method='OPTIONS'), timeout=1)
            break
        except Exception:
            time.sleep(0.5)
    return faux


def masquer(texte):
    """Jamais la clé dans ce qui s'affiche ou s'écrit : ni sa valeur, ni un « key=… »."""
    texte = str(texte)
    cle = os.environ.get('GEMINI_API_KEY', '')
    if len(cle) >= 8:
        texte = texte.replace(cle, '[CLÉ MASQUÉE]')
    texte = re.sub(r'(key=)[^&\s"\']+', r'\1[MASQUÉE]', texte)
    return re.sub(r'AIza[0-9A-Za-z_\-]{20,}', '[CLÉ MASQUÉE]', texte)


def arreter(faux, journal=None, entete=''):
    # Le journal de la fonction dit ce que Google a répondu : on le garde, clé masquée,
    # avant de supprimer le conteneur (le 02/10, il disparaissait avec lui).
    if journal is not None:
        logs = subprocess.run(['docker', 'logs', 'edge-banc'], capture_output=True, text=True)
        with open(journal, 'a') as f:
            f.write(f'=== {entete} ===\n{masquer(logs.stdout + logs.stderr)}\n')
    subprocess.run(['docker', 'rm', '-f', 'edge-banc'], capture_output=True)
    faux.terminate()


def appeler(corps):
    """La réponse de la fonction, sa durée, et l'erreur (masquée) si elle a échoué."""
    req = urllib.request.Request(f'http://127.0.0.1:{PORT_FONCTION}/', data=json.dumps(corps).encode(),
                                 headers={'Content-Type': 'application/json', 'Authorization': 'Bearer banc'})
    debut = time.time()
    try:
        with urllib.request.urlopen(req, timeout=200) as r:
            return json.loads(r.read()), time.time() - debut, None
    except urllib.error.HTTPError as e:
        corps_erreur = e.read().decode('utf-8', 'replace')
        return {}, time.time() - debut, masquer(f'HTTP {e.code} : {corps_erreur[:400]}')
    except Exception as e:  # délai dépassé, fonction tombée : la carte suivante continue
        return {}, time.time() - debut, masquer(f'{type(e).__name__} : {e}')


def b64(chemin):
    return base64.b64encode(Path(chemin).read_bytes()).decode()


def garder(dossier, variante, element, reponse):
    """La réponse entière, pour relire ce que le modèle a vraiment dit."""
    nom = norme(variante).replace(' ', '_')
    chemin = dossier / 'reponses' / nom / f'{element}.json'
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(masquer(json.dumps(reponse, ensure_ascii=False, indent=1)))


# ─── Le rapport et la recommandation ────────────────────────────────────────────────────
def moyenne(valeurs):
    valeurs = [v for v in valeurs if v is not None]
    return sum(valeurs) / len(valeurs) if valeurs else None


def le_plus_frequent(valeurs):
    valeurs = [v for v in valeurs if v]
    return Counter(valeurs).most_common(1)[0][0] if valeurs else None


def bilan(resultats, nom, t):
    rs = [r for r in resultats if r['variante'] == nom and r['type'] == t]
    if not rs:
        return None
    criteres = ('vins_trouves', 'producteur', 'millesime', 'prix', 'nom', 'appellation')
    return {
        'lecture': moyenne([v for r in rs for k, v in r.items() if k in criteres]) or 0.0,
        'sommelier': moyenne([r.get('sommelier') for r in rs]),
        'echecs': sum(1 for r in rs if r.get('erreur')),
        'n': len(rs),
        'cout': sum(r['cout_eur'] for r in rs) / len(rs),
        'reflexion_jetons': sum(r['reflexion_jetons'] for r in rs) / len(rs),
        'duree': sum(r['duree_s'] for r in rs) / len(rs),
        'niveau': le_plus_frequent([r.get('niveau') for r in rs]),
        'pepites': moyenne([r.get('pepites') for r in rs]),
        'bons_plans': moyenne([r.get('bons_plans') for r in rs]),
        'borne': moyenne([r.get('pepites_dans_la_borne') for r in rs]),
        'defendables': (sum(r.get('pepites_defendables', 0) for r in rs) / sum(r.get('pepites', 0) for r in rs)
                        if sum(r.get('pepites', 0) for r in rs) else None),
    }


def pourcent(x):
    return '—' if x is None else f'{100 * x:.1f} %'


def recommandation(resultats, variantes):
    lignes = []
    for t, tache in (('carte', 'scan_carte'), ('etiquette', 'scan_etiquette_lecture')):
        stats = [(nom, reglage, bilan(resultats, nom, t)) for nom, reglage in variantes]
        stats = [(nom, reglage, b) for nom, reglage, b in stats if b and b['echecs'] < b['n']]
        if not stats:
            continue
        meilleure_lecture = max(b['lecture'] for _, _, b in stats)
        sommeliers = [b['sommelier'] for _, _, b in stats if b['sommelier'] is not None]
        meilleur_sommelier = max(sommeliers) if sommeliers else None
        eligibles = [(nom, reglage, b) for nom, reglage, b in stats
                     if b['echecs'] == 0 and b['lecture'] >= SEUIL_LECTURE * meilleure_lecture
                     and (meilleur_sommelier is None or b['sommelier'] is None
                          or b['sommelier'] >= SEUIL_SOMMELIER * meilleur_sommelier)]
        if not eligibles:
            lignes.append(f'\n**{t}** : aucune variante sans échec ne tient les seuils ; rien à changer.')
            continue
        nom, reglage, b = min(eligibles, key=lambda x: x[2]['cout'])
        valeur = {tache: {'modele': reglage['modele'], 'reflexion': b['niveau'] or reglage['reflexion']}}
        lignes += [
            f'\n**{t}** : {nom} — lecture {pourcent(b["lecture"])}, sommelier {pourcent(b["sommelier"])}, '
            f'{100 * b["cout"]:.2f} c€ par appel.',
            '', 'Pour l\'adopter (SQL Editor) :', '', '```sql',
            "INSERT INTO public.app_config (cle, valeur)",
            f"VALUES ('modeles_ia', '{json.dumps(valeur, ensure_ascii=False)}'::jsonb)",
            "ON CONFLICT (cle) DO UPDATE SET valeur = public.app_config.valeur || EXCLUDED.valeur, maj_le = now();",
            '```',
        ]
    stats = []
    for nom, reglage in variantes:
        rs = [r for r in resultats if r['variante'] == nom and r['type'] == 'texte']
        if rs and not any(r.get('verdict') in ('invente', 'echec') for r in rs):
            stats.append((nom, reglage, sum(r.get('verdict') == 'juste' for r in rs), sum(r['cout_eur'] for r in rs) / len(rs),
                          le_plus_frequent([r.get('niveau') for r in rs])))
    if stats:
        meilleur = max(s[2] for s in stats)
        nom, reglage, justes, cout, niveau = min((s for s in stats if s[2] == meilleur), key=lambda s: s[3])
        valeur = {'vin_depuis_texte': {'modele': reglage['modele'], 'reflexion': niveau or reglage['reflexion']}}
        lignes += [f'\n**texte** : {nom} — aucune invention, {justes} justes, {100 * cout:.2f} c€ par appel.', '',
                   'Pour l\'adopter (SQL Editor) :', '', '```sql', "INSERT INTO public.app_config (cle, valeur)",
                   f"VALUES ('modeles_ia', '{json.dumps(valeur, ensure_ascii=False)}'::jsonb)",
                   "ON CONFLICT (cle) DO UPDATE SET valeur = public.app_config.valeur || EXCLUDED.valeur, maj_le = now();", '```']
    elif any(r['type'] == 'texte' for r in resultats):
        lignes.append('\n**texte** : toutes les variantes ont inventé au moins une fois ; ne rien adopter.')
    return lignes


def main():
    args = sys.argv[1:]
    dossier = Path(args[0]).expanduser()
    if '--rejuger' in args:
        return rejuger(dossier)
    if not os.environ.get('GEMINI_API_KEY'):
        sys.exit('GEMINI_API_KEY absente de l\'environnement : le banc appelle le vrai Gemini.')
    demandees = args[args.index('--variantes') + 1] if '--variantes' in args else ''
    try:
        variantes = variantes_demandees(demandees) if demandees else variantes_par_defaut()
    except Exception as e:
        sys.exit(masquer(f'Liste des modèles indisponible ({e}) : vérifier la connexion, ou nommer les variantes '
                         'avec --variantes modele:reflexion,…'))
    if not variantes:
        sys.exit('Aucun modèle stable trouvé : nommer les variantes avec --variantes modele:reflexion,…')
    print('Variantes :', ' · '.join(nom for nom, _ in variantes), flush=True)
    cartes = sorted(p for p in (dossier / 'cartes').glob('*') if (p / 'reference.json').exists())
    etiquettes = sorted(p for p in (dossier / 'etiquettes').glob('*.jpg') if p.with_suffix('.json').exists())
    # Identifier un vin depuis son nom (V2.4 · R1) : le jeu du dossier, sinon celui du dépôt.
    source_textes = dossier / 'textes.json' if (dossier / 'textes.json').exists() else ICI / 'textes_hors_de_france.json'
    textes = [] if '--sans-textes' in args else json.loads(source_textes.read_text())['textes']
    resultats = []
    journal = dossier / 'journal_fonctions.txt'
    journal.write_text('')
    for nom, reglage in variantes:
        if cartes:
            faux = lancer('scan-menu', {'scan_carte': reglage})
            try:
                for c in cartes:
                    pages = sorted(c.glob('page*.jpg'))
                    reference = json.loads((c / 'reference.json').read_text())
                    rep, duree, erreur = appeler({'imagesBase64': [b64(p) for p in pages], 'languageCode': 'fr',
                                                  'mode': reference.get('mode', 'carte')})
                    if erreur:
                        print(f'{nom} · carte {c.name} : ÉCHEC — {erreur}', flush=True)
                        resultats.append({'variante': nom, 'type': 'carte', 'element': c.name, 'erreur': erreur,
                                          'duree_s': round(duree, 1), 'cout_eur': 0, 'reflexion_jetons': 0,
                                          'vins_trouves': 0, 'producteur': 0, 'millesime': 0, 'prix': 0})
                        continue
                    garder(dossier, nom, c.name, rep)
                    jugement = juger_carte(rep, reference)
                    usage = rep.get('usageMetadata') or {}
                    cout = (rep.get('couts') or [{}])[0]
                    resultats.append({'variante': nom, 'type': 'carte', 'element': c.name, 'modele': rep.get('modele'),
                                      'niveau': cout.get('reflexion'),
                                      'duree_s': round(duree, 1), 'cout_eur': cout_eur(rep.get('modele', ''), usage),
                                      'reflexion_jetons': usage.get('thoughtsTokenCount', 0), **jugement})
                    print(f'{nom} · carte {c.name} : {jugement}', flush=True)
            finally:
                arreter(faux, journal, f'{nom} · scan-menu')
        if etiquettes:
            faux = lancer('scan-label', {'scan_etiquette_lecture': reglage})
            try:
                for e in etiquettes:
                    rep, duree, erreur = appeler({'imageBase64': b64(e), 'forceRefresh': True})
                    if erreur:
                        print(f'{nom} · étiquette {e.stem} : ÉCHEC — {erreur}', flush=True)
                        resultats.append({'variante': nom, 'type': 'etiquette', 'element': e.stem, 'erreur': erreur,
                                          'duree_s': round(duree, 1), 'cout_eur': 0, 'reflexion_jetons': 0,
                                          'producteur': 0, 'nom': 0, 'millesime': 0, 'appellation': 0})
                        continue
                    garder(dossier, nom, e.stem, rep)
                    jugement = juger_etiquette(rep, json.loads(e.with_suffix('.json').read_text()))
                    lecture = next((x for x in rep.get('couts', []) if x.get('fonction') == 'scan_vision'), {})
                    resultats.append({'variante': nom, 'type': 'etiquette', 'element': e.stem, 'modele': lecture.get('modele'),
                                      'niveau': lecture.get('reflexion'),
                                      'duree_s': round(duree, 1),
                                      'cout_eur': cout_eur(lecture.get('modele', ''), lecture.get('usageMetadata')),
                                      'reflexion_jetons': (lecture.get('usageMetadata') or {}).get('thoughtsTokenCount', 0),
                                      **jugement})
                    print(f'{nom} · étiquette {e.stem} : {jugement}', flush=True)
            finally:
                arreter(faux, journal, f'{nom} · scan-label')
        if textes:
            faux = lancer('taches-ia', {'vin_depuis_texte': reglage})
            try:
                for t in textes:
                    rep, duree, erreur = appeler({'tache': 'vin_depuis_texte', 'texte': t['texte'], 'langue': 'fr'})
                    if erreur:
                        print(f'{nom} · texte « {t["texte"]} » : ÉCHEC — {erreur}', flush=True)
                        resultats.append({'variante': nom, 'type': 'texte', 'element': t['texte'], 'erreur': erreur,
                                          'duree_s': round(duree, 1), 'cout_eur': 0, 'reflexion_jetons': 0, 'verdict': 'echec'})
                        continue
                    garder(dossier, nom, 'texte_' + norme(t['texte']).replace(' ', '_'), rep)
                    jugement = juger_texte(rep, t['pays'])
                    cout = (rep.get('couts') or [{}])[0]
                    resultats.append({'variante': nom, 'type': 'texte', 'element': t['texte'], 'modele': rep.get('modele'),
                                      'niveau': cout.get('reflexion'), 'duree_s': round(duree, 1),
                                      'cout_eur': cout_eur(rep.get('modele', ''), cout.get('usageMetadata') or {}),
                                      'recherches': cout.get('requetes', 0),
                                      'reflexion_jetons': (cout.get('usageMetadata') or {}).get('thoughtsTokenCount', 0),
                                      **jugement})
                    print(f'{nom} · texte « {t["texte"]} » : {jugement["verdict"]} ({jugement["pays_lu"]})', flush=True)
            finally:
                arreter(faux, journal, f'{nom} · taches-ia')

    ecrire_rapport(dossier, resultats, variantes)


def ecrire_rapport(dossier, resultats, variantes, quand=None):
    if quand is None:  # un vrai passage ; un rejugement laisse ses résultats d'origine
        (dossier / 'rapport.json').write_text(json.dumps(resultats, ensure_ascii=False, indent=1))
    lignes = ['# Banc d\'essai des modèles de lecture', '',
              f'{quand or "Le " + datetime.date.today().isoformat()}. Lecture : vins trouvés, producteurs, millésimes, prix '
              '(sans prix inventé). Sommelier : couleur et profil des vins dont le profil ne fait pas débat.', '',
              '| Variante | Type | Lecture | Sommelier | Échecs | Coût moyen | Jetons de réflexion | Durée moyenne |',
              '|---|---|---|---|---|---|---|---|']
    for nom, _ in variantes:
        for t in ('carte', 'etiquette'):
            b = bilan(resultats, nom, t)
            if not b:
                continue
            lignes.append(f'| {nom} | {t} | {pourcent(b["lecture"])} | {pourcent(b["sommelier"])} | '
                          f'{b["echecs"]}/{b["n"]} | {100 * b["cout"]:.2f} c€ | {b["reflexion_jetons"]:.0f} | '
                          f'{b["duree"]:.1f} s |')
    lignes += ['', '## Pépites et bons plans', '',
               'Une pépite ne veut dire quelque chose que si elle est rare : aucune sur une carte banale, une ou '
               'deux au plus, davantage seulement sur une carte exceptionnelle (borne écrite carte par carte). '
               'Défendable : un vin qu\'un sommelier désignerait sur cette carte.', '',
               '| Variante | Pépites par carte | Borne tenue | Pépites défendables | Bons plans par carte |',
               '|---|---|---|---|---|']
    for nom, _ in variantes:
        b = bilan(resultats, nom, 'carte')
        if b and b['pepites'] is not None:
            lignes.append(f'| {nom} | {b["pepites"]:.1f} | {pourcent(b["borne"])} | {pourcent(b["defendables"])} | '
                          f'{b["bons_plans"]:.1f} |')
    textes = [r for r in resultats if r['type'] == 'texte']
    if textes:
        lignes += ['', '## Identifier un vin depuis son nom', '',
                   'Vins hors de France et vins imaginaires (V2.4 · R1). Une invention (un pays faux, ou un vin '
                   'imaginaire présenté comme reconnu) est éliminatoire : il en faut zéro.', '',
                   '| Variante | Inventions | Justes | Non reconnus ou sans pays | Recherches | Coût moyen |',
                   '|---|---|---|---|---|---|']
        for nom, _ in variantes:
            rs = [r for r in textes if r['variante'] == nom]
            if not rs:
                continue
            compte = Counter(r.get('verdict') for r in rs)
            lignes.append(f'| {nom} | **{compte["invente"]}** | {compte["juste"]}/{len(rs)} | '
                          f'{compte["non_reconnu"] + compte["sans_pays"]} | {sum(r.get("recherches", 0) for r in rs)} | '
                          f'{100 * sum(r["cout_eur"] for r in rs) / len(rs):.2f} c€ |')
        inventions = [r for r in textes if r.get('verdict') == 'invente']
        if inventions:
            lignes += ['', 'Inventions relevées :', '']
            lignes += [f'- {r["variante"]} : « {r["element"]} » → {r.get("pays_lu")}' for r in inventions]
    lignes += ['', '## Recommandation'] + recommandation(resultats, variantes)
    (dossier / 'rapport.md').write_text('\n'.join(lignes) + '\n')
    print('\n'.join(lignes))



def rejuger(dossier):
    """Le dernier passage rejugé avec les références d'aujourd'hui : mêmes réponses, mêmes
    coûts, aucun appel à Gemini."""
    anciens = json.loads((dossier / 'rapport.json').read_text())
    source_textes = dossier / 'textes.json' if (dossier / 'textes.json').exists() else ICI / 'textes_hors_de_france.json'
    attendus_textes = {t['texte']: t['pays'] for t in json.loads(source_textes.read_text())['textes']}
    niveaux = {v: k for k, v in NIVEAUX.items()}
    variantes = []
    for nom in dict.fromkeys(r['variante'] for r in anciens):
        modele, _, niveau = nom.partition(', réflexion ')
        variantes.append(variante(modele, niveaux.get(niveau, niveau)))
    resultats = []
    for r in anciens:
        fichier = ('texte_' + norme(r['element']).replace(' ', '_')) if r['type'] == 'texte' else r['element']
        reponse = dossier / 'reponses' / norme(r['variante']).replace(' ', '_') / f"{fichier}.json"
        if r.get('erreur') or not reponse.exists():
            resultats.append(r)
            continue
        rep = json.loads(reponse.read_text())
        if r['type'] == 'texte':
            jugement = juger_texte(rep, attendus_textes.get(r['element']))
        elif r['type'] == 'carte':
            jugement = juger_carte(rep, json.loads((dossier / 'cartes' / r['element'] / 'reference.json').read_text()))
        else:
            jugement = juger_etiquette(rep, json.loads((dossier / 'etiquettes' / f"{r['element']}.json").read_text()))
        garde = ('variante', 'type', 'element', 'modele', 'niveau', 'duree_s', 'cout_eur', 'reflexion_jetons', 'recherches')
        resultats.append({**{k: r[k] for k in garde if k in r}, **jugement})
    passage = datetime.date.fromtimestamp((dossier / 'rapport.json').stat().st_mtime).isoformat()
    ecrire_rapport(dossier, resultats, variantes,
                   quand=f'Passage du {passage}, rejugé le {datetime.date.today().isoformat()} avec les références du jour')

if __name__ == '__main__':
    main()
