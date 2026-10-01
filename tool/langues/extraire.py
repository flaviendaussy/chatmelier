#!/usr/bin/env python3
"""Recense toutes les phrases de l'app à traduire (V2.3 · H4).

    python3 tool/langues/extraire.py es          # met à jour app/l10n_catalogues/es.json

Sources :
  - tr('fr', 'en'), trSi(x, 'fr', 'en'), Phrase('fr', 'en') — chaînes littérales,
    éventuellement adjacentes ;
  - les paires d'arguments nommés « …Fr: 'fr' » / « …En: 'en' » d'un même appel
    (énumérations et questions du matchmaker) ;
  - les tables de référentiel français → anglais : les fichiers *_en.dart et les
    dictionnaires « const Map<String, String> …En = {…} » (trDonnee) ;
  - les appels t('fr', 'en') dans les fichiers qui définissent String t(String fr, String en).

La clé est la phrase française telle que l'app la voit à l'exécution (échappements
résolus). Les traductions déjà écrites sont conservées ; une phrase qui n'existe plus dans
le code est retirée. Le fichier est une liste ordonnée par emplacement, pour traduire avec
le contexte sous les yeux.
"""
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from convertir import analyser, suite_de_litteraux, sauter  # noqa: E402

DEPOT = Path(__file__).resolve().parents[2]
LIB = DEPOT / 'app' / 'lib'


def decoder(lx):
    """La valeur d'exécution d'une chaîne littérale Dart (sans interpolation)."""
    morceaux = []
    for m in lx.morceaux:
        if m[0] != 't':
            return None  # une interpolation : pas une clé stable
        brut = m[1]
        if lx.brut:
            morceaux.append(brut)
            continue
        i, sortie = 0, []
        while i < len(brut):
            c = brut[i]
            if c == '\\' and i + 1 < len(brut):
                s = brut[i + 1]
                if s == 'n':
                    sortie.append('\n')
                elif s == 't':
                    sortie.append('\t')
                elif s == 'r':
                    sortie.append('\r')
                elif s == 'u':
                    if brut[i + 2:i + 3] == '{':
                        fin = brut.index('}', i + 3)
                        sortie.append(chr(int(brut[i + 3:fin], 16)))
                        i = fin + 1
                        continue
                    sortie.append(chr(int(brut[i + 2:i + 6], 16)))
                    i += 6
                    continue
                elif s == 'x':
                    sortie.append(chr(int(brut[i + 2:i + 4], 16)))
                    i += 4
                    continue
                else:
                    sortie.append(s)
                i += 2
                continue
            sortie.append(c)
            i += 1
        morceaux.append(''.join(sortie))
    return ''.join(morceaux)


def valeur(liste):
    parts = [decoder(lx) for lx in liste]
    return None if any(p is None for p in parts) else ''.join(parts)


def paires_du_fichier(p):
    src = p.read_text()
    nature, lexemes = analyser(src)
    par_debut = {lx.debut: lx for lx in lexemes}
    rel = p.relative_to(DEPOT / 'app')
    trouvees = []

    def ligne(pos):
        return src.count('\n', 0, pos) + 1

    def en_code(i):
        return 0 <= i < len(nature) and nature[i] == 'c'

    def deux_litteraux(depuis):
        l1, f1 = suite_de_litteraux(src, depuis, par_debut)
        if not l1:
            return None
        j = sauter(src, f1)
        if j >= len(src) or src[j] != ',':
            return None
        l2, _ = suite_de_litteraux(src, j + 1, par_debut)
        if not l2:
            return None
        fr, en = valeur(l1), valeur(l2)
        return (fr, en) if fr is not None and en is not None else None

    appels = [r'(?<![\w.])tr\(', r'(?<![\w.])Phrase\(']
    if re.search(r'String t\(String fr, String en\)', src):
        appels.append(r'(?<![\w.])t\(')
    for motif in appels:
        for m in re.finditer(motif, src):
            if en_code(m.start()):
                paire = deux_litteraux(m.end())
                if paire:
                    trouvees.append((*paire, f'{rel}:{ligne(m.start())}'))
    for m in re.finditer(r'(?<![\w.])trSi\(', src):
        if not en_code(m.start()):
            continue
        # trSi(condition, 'fr', 'en') : sauter la condition jusqu'à la première virgule.
        j = src.find(',', m.end())
        if j != -1:
            paire = deux_litteraux(j + 1)
            if paire:
                trouvees.append((*paire, f'{rel}:{ligne(m.start())}'))

    # Arguments nommés « …Fr: '…' » suivis de « …En: '…' » dans le même appel.
    for m in re.finditer(r'\b(\w+)Fr:\s*', src):
        if not en_code(m.start()):
            continue
        l1, f1 = suite_de_litteraux(src, m.end(), par_debut)
        if not l1:
            continue
        m2 = re.compile(r'\b' + re.escape(m.group(1)) + r'En:\s*').search(src, f1, f1 + 800)
        if not m2:
            continue
        l2, _ = suite_de_litteraux(src, m2.end(), par_debut)
        if l2 and valeur(l1) is not None and valeur(l2) is not None:
            trouvees.append((valeur(l1), valeur(l2), f'{rel}:{ligne(m.start())}'))

    # Tables de référentiel français → anglais.
    for m in re.finditer(r'const (?:Map<String, String> )?(\w*(?:En|EnAnglais|Anglais))\s*=\s*(?:<String, String>)?\{', src):
        if not (p.name.endswith('_en.dart') or m.group(1).endswith(('En', 'EnAnglais', 'Anglais'))):
            continue
        i = m.end()
        profondeur = 1
        while i < len(src) and profondeur:
            if nature[i] == 'c':
                if src[i] == '{':
                    profondeur += 1
                elif src[i] == '}':
                    profondeur -= 1
                    if profondeur == 0:
                        break
            if i in par_debut and nature[i] != 'm':
                cle, fin_cle = suite_de_litteraux(src, i, par_debut)
                k = sauter(src, fin_cle)
                if k < len(src) and src[k] == ':':
                    val, fin_val = suite_de_litteraux(src, k + 1, par_debut)
                    if val and valeur(cle) is not None and valeur(val) is not None:
                        trouvees.append((valeur(cle), valeur(val), f'{rel}:{ligne(i)}'))
                        i = fin_val
                        continue
                i = fin_cle
                continue
            i += 1
    return trouvees


def main():
    langue = sys.argv[1] if len(sys.argv) > 1 else 'es'
    chemin = DEPOT / 'app' / 'l10n_catalogues' / f'{langue}.json'
    anciennes = {}
    if chemin.exists():
        for e in json.loads(chemin.read_text()):
            anciennes[e['fr']] = e.get(langue, '')
    vues, entrees = set(), []
    for p in sorted(LIB.rglob('*.dart')):
        if '/l10n/' in str(p) or str(p).endswith('.g.dart') or p.name == 'langue.dart':
            continue
        for fr, en, ou in paires_du_fichier(p):
            if not fr.strip() or fr in vues:
                continue
            vues.add(fr)
            entrees.append({'fr': fr, 'en': en, langue: anciennes.get(fr, ''), 'ou': ou})
    chemin.parent.mkdir(parents=True, exist_ok=True)
    chemin.write_text(json.dumps(entrees, ensure_ascii=False, indent=1) + '\n')
    faites = sum(1 for e in entrees if e[langue])
    print(f'{len(entrees)} phrases, {faites} déjà traduites en {langue}, {len(entrees) - faites} à traduire')


if __name__ == '__main__':
    main()
