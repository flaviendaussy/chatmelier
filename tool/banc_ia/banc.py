#!/usr/bin/env python3
"""Banc d'essai des modèles de lecture (V2.3 · A4).

Lance scan-menu et scan-label dans l'edge runtime local, contre le VRAI Gemini (la clé est
lue dans l'environnement de la personne qui lance le banc, jamais affichée ni écrite), avec
un faux Supabase qui impose la variante de modèle et de réflexion. Compare chaque lecture à
une référence écrite à la main et chiffre le coût réel de chaque variante.

    GEMINI_API_KEY=… python3 tool/banc_ia/banc.py ~/chatmelier-banc

Dossier attendu (les cartes se fabriquent avec tool/banc_ia/fabriquer_cartes.py) :
    cartes/<nom>/page1.jpg, page2.jpg…   + cartes/<nom>/reference.json
    etiquettes/<nom>.jpg                 + etiquettes/<nom>.json
Référence d'une carte : {"mode": "carte" | "ardoise", "vins": [{"nom": …, "producteur": …,
"millesime": 2019, "prix": 68, "prix_verre": 9}]} — un prix nul veut dire « pas imprimé ».
Référence d'une étiquette : {"producteur": …, "nom": …, "millesime": 2019, "appellation": …}

Sortie : <dossier>/rapport.md et <dossier>/rapport.json. Coût d'un passage complet : de
l'ordre d'un euro pour 10 cartes et 10 étiquettes sur 4 variantes.
"""
import base64
import json
import os
import re
import subprocess
import sys
import time
import unicodedata
import urllib.request
from pathlib import Path

ICI = Path(__file__).resolve().parent
DEPOT = ICI.parent.parent
PORT_FONCTION = 9123

# (nom, réglage) — la première est le comportement d'avant la V2.3 (réflexion par défaut,
# « medium » pour 3.8-flash selon la doc du 30/09).
VARIANTES = [
    ('3.8-flash, réflexion par défaut', {'modele': 'gemini-3.8-flash', 'reflexion': 'medium'}),
    ('3.8-flash, réflexion basse', {'modele': 'gemini-3.8-flash', 'reflexion': 'low'}),
    ('3.6-flash, réflexion minimale', {'modele': 'gemini-3.6-flash', 'reflexion': 'minimal'}),
    ('3.1-flash-lite, réflexion minimale', {'modele': 'gemini-3.1-flash-lite', 'reflexion': 'minimal'}),
]

# Tarifs du 30/09/2026, en dollars par million de jetons (entrée, sortie réflexion comprise).
TARIFS = [('3.1-flash-lite', 0.25, 1.50), ('lite', 0.30, 2.50), ('3.5-flash', 1.50, 9.00), ('flash', 0.75, 3.75)]


def cout_eur(modele, usage):
    usage = usage or {}
    entree = usage.get('promptTokenCount', 0)
    sortie = usage.get('candidatesTokenCount', 0) + usage.get('thoughtsTokenCount', 0)
    for motif, e, s in TARIFS:
        if motif in modele:
            return (entree * e + sortie * s) / 1e6 * 0.92
    return (entree * 0.75 + sortie * 3.75) / 1e6 * 0.92


def norme(t):
    t = unicodedata.normalize('NFD', str(t or '')).encode('ascii', 'ignore').decode().lower()
    return re.sub(r'[^a-z0-9]+', ' ', t).strip()


def proche(a, b):
    a, b = norme(a), norme(b)
    return bool(a) and bool(b) and (a == b or a in b or b in a)


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


def arreter(faux):
    subprocess.run(['docker', 'rm', '-f', 'edge-banc'], capture_output=True)
    faux.terminate()


def appeler(corps):
    req = urllib.request.Request(f'http://127.0.0.1:{PORT_FONCTION}/', data=json.dumps(corps).encode(),
                                 headers={'Content-Type': 'application/json', 'Authorization': 'Bearer banc'})
    debut = time.time()
    with urllib.request.urlopen(req, timeout=200) as r:
        return json.loads(r.read()), time.time() - debut


def b64(chemin):
    return base64.b64encode(Path(chemin).read_bytes()).decode()


def prix_juste(lu, attendu):
    """Un prix lu contre le prix imprimé ; sans prix imprimé, un prix lu est inventé."""
    if attendu is None:
        return lu in (None, 0, 0.0)
    return lu is not None and abs(float(lu) - attendu) < 0.01


def juger_carte(reponse, reference):
    vins = reponse.get('wines', [])
    attendus = reference.get('vins', [])
    trouves = prod = mill = prix = 0
    for a in attendus:
        v = next((w for w in vins if proche(w.get('name'), a.get('nom'))
                  and (a.get('millesime') is None or w.get('vintage') == a.get('millesime'))), None)
        if not v:
            continue
        trouves += 1
        prod += a.get('producteur') is None or proche(v.get('producer'), a.get('producteur'))
        mill += v.get('vintage') == a.get('millesime')
        # La bouteille, et le verre quand la référence le dit (« prix_verre ») : sur une
        # ardoise ou une carte sans prix, un prix inventé est une faute.
        verres = [g.get('price') for g in (v.get('glass_prices') or []) if isinstance(g, dict)]
        ok = prix_juste(v.get('bottle_price'), a.get('prix'))
        if 'prix_verre' in a:
            ok = ok and (any(prix_juste(g, a['prix_verre']) for g in verres) if a['prix_verre'] is not None
                         else not any(g not in (None, 0, 0.0) for g in verres))
        prix += ok
    n = max(len(attendus), 1)
    return {'vins_trouves': trouves / n, 'producteur': prod / n, 'millesime': mill / n, 'prix': prix / n,
            'vins_en_trop': max(0, len(vins) - trouves)}


def juger_etiquette(reponse, reference):
    champs = {'producteur': 'producer', 'nom': 'name', 'millesime': 'vintage', 'appellation': 'appellation'}
    ok = {}
    for fr, en in champs.items():
        if fr not in reference:
            continue
        ok[fr] = (reponse.get(en) == reference[fr]) if fr == 'millesime' else proche(reponse.get(en), reference[fr])
    return {k: 1.0 if v else 0.0 for k, v in ok.items()}


def main():
    if not os.environ.get('GEMINI_API_KEY'):
        sys.exit('GEMINI_API_KEY absente de l\'environnement : le banc appelle le vrai Gemini.')
    dossier = Path(sys.argv[1]).expanduser()
    cartes = sorted(p for p in (dossier / 'cartes').glob('*') if (p / 'reference.json').exists())
    etiquettes = sorted(p for p in (dossier / 'etiquettes').glob('*.jpg') if p.with_suffix('.json').exists())
    resultats = []
    for nom, reglage in VARIANTES:
        if cartes:
            faux = lancer('scan-menu', {'scan_carte': reglage})
            try:
                for c in cartes:
                    pages = sorted(c.glob('page*.jpg'))
                    reference = json.loads((c / 'reference.json').read_text())
                    rep, duree = appeler({'imagesBase64': [b64(p) for p in pages], 'languageCode': 'fr',
                                          'mode': reference.get('mode', 'carte')})
                    jugement = juger_carte(rep, reference)
                    usage = rep.get('usageMetadata') or {}
                    resultats.append({'variante': nom, 'type': 'carte', 'element': c.name, 'modele': rep.get('modele'),
                                      'duree_s': round(duree, 1), 'cout_eur': cout_eur(rep.get('modele', ''), usage),
                                      'reflexion_jetons': usage.get('thoughtsTokenCount', 0), **jugement})
                    print(f'{nom} · carte {c.name} : {jugement}', flush=True)
            finally:
                arreter(faux)
        if etiquettes:
            faux = lancer('scan-label', {'scan_etiquette_lecture': reglage})
            try:
                for e in etiquettes:
                    rep, duree = appeler({'imageBase64': b64(e), 'forceRefresh': True})
                    jugement = juger_etiquette(rep, json.loads(e.with_suffix('.json').read_text()))
                    lecture = next((x for x in rep.get('couts', []) if x.get('fonction') == 'scan_vision'), {})
                    resultats.append({'variante': nom, 'type': 'etiquette', 'element': e.stem, 'modele': lecture.get('modele'),
                                      'duree_s': round(duree, 1), 'cout_eur': cout_eur(lecture.get('modele', ''), lecture.get('usageMetadata')),
                                      'reflexion_jetons': (lecture.get('usageMetadata') or {}).get('thoughtsTokenCount', 0), **jugement})
                    print(f'{nom} · étiquette {e.stem} : {jugement}', flush=True)
            finally:
                arreter(faux)

    (dossier / 'rapport.json').write_text(json.dumps(resultats, ensure_ascii=False, indent=1))
    lignes = ['# Banc d\'essai des modèles de lecture', '',
              '| Variante | Type | Exactitude moyenne | Coût moyen | Jetons de réflexion | Durée moyenne |',
              '|---|---|---|---|---|---|']
    for nom, _ in VARIANTES:
        for t in ('carte', 'etiquette'):
            rs = [r for r in resultats if r['variante'] == nom and r['type'] == t]
            if not rs:
                continue
            notes = [v for r in rs for k, v in r.items() if k in ('vins_trouves', 'producteur', 'millesime', 'prix', 'nom', 'appellation')]
            lignes.append(f'| {nom} | {t} | {100 * sum(notes) / max(len(notes), 1):.1f} % | '
                          f'{100 * sum(r["cout_eur"] for r in rs) / len(rs):.2f} c€ | '
                          f'{sum(r["reflexion_jetons"] for r in rs) / len(rs):.0f} | {sum(r["duree_s"] for r in rs) / len(rs):.1f} s |')
    (dossier / 'rapport.md').write_text('\n'.join(lignes) + '\n')
    print('\n'.join(lignes))


if __name__ == '__main__':
    main()
