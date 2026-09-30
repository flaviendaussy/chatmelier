#!/usr/bin/env python3
"""Rend les textes de l'app extensibles à d'autres langues (V2.3 · H2, H3).

    python3 tool/langues/convertir.py app/lib            # réécrit les fichiers
    python3 tool/langues/convertir.py app/lib --essai    # montre, n'écrit rien

Deux transformations, idempotentes :
  1. tr('…$x…', '…${y.z}…')  →  tr('…{x}…', '…{z}…', {'x': x, 'z': y.z})
     Une phrase avec variables devient un modèle à marques nommées : c'est ce modèle
     français qui sert de clé aux catalogues des autres langues.
  2. isFr ? 'A' : 'B'  →  trSi(isFr, 'A', 'B')        (Langue.estFr ? … → tr(…))
     Les deux branches doivent être des chaînes littérales ; l'expression doit être
     entière (rien ne la prolonge après la seconde chaîne).

Tout ce qui ne rentre pas dans ces formes est laissé tel quel et listé à la fin.
"""
import re
import sys
from pathlib import Path

CONDITIONS = r'(?:Langue\.estFr|widget\.isFr|widget\.fr|isFrench|_isFr|estFr|isFr|fr)'
GENERIQUES = {'length', 'first', 'last', 'name', 'value', 'toString', 'label', 'text'}


class Lexeme:
    """Une chaîne littérale : ses bornes et ses morceaux (texte brut ou interpolation)."""

    def __init__(self, debut, fin, guillemet, brut, morceaux):
        self.debut, self.fin, self.guillemet, self.brut, self.morceaux = debut, fin, guillemet, brut, morceaux

    @property
    def interpole(self):
        return any(m[0] == 'i' for m in self.morceaux)


def analyser(src):
    """Rend (nature, lexemes) : nature[i] vaut 'c' (code), 's' (texte de chaîne) ou 'm'
    (commentaire) ; lexemes liste toutes les chaînes, y compris celles des interpolations."""
    n = len(src)
    nature = ['c'] * n
    lexemes = []

    def code(i, fin_accolade=False):
        profondeur = 0
        while i < n:
            c = src[i]
            if src.startswith('//', i):
                j = src.find('\n', i)
                j = n if j == -1 else j
                for k in range(i, j):
                    nature[k] = 'm'
                i = j
                continue
            if src.startswith('/*', i):
                niveau, j = 1, i + 2
                while j < n and niveau:
                    if src.startswith('/*', j):
                        niveau, j = niveau + 1, j + 2
                    elif src.startswith('*/', j):
                        niveau, j = niveau - 1, j + 2
                    else:
                        j += 1
                for k in range(i, j):
                    nature[k] = 'm'
                i = j
                continue
            brut = False
            if c == 'r' and i + 1 < n and src[i + 1] in '\'"' and (i == 0 or not (src[i - 1].isalnum() or src[i - 1] == '_')):
                brut, i = True, i + 1
                c = src[i]
            if c in '\'"':
                i = chaine(i, brut)
                continue
            if fin_accolade:
                if c == '{':
                    profondeur += 1
                elif c == '}':
                    if profondeur == 0:
                        return i
                    profondeur -= 1
            i += 1
        return i

    def chaine(i, brut):
        debut = i - 1 if brut else i
        g = src[i:i + 3] if src[i:i + 3] in ("'''", '"""') else src[i]
        i += len(g)
        morceaux, texte_debut = [], i
        while i < n and not src.startswith(g, i):
            if not brut and src[i] == '\\':
                nature[i] = 's'
                if i + 1 < n:
                    nature[i + 1] = 's'
                i += 2
                continue
            if not brut and src[i] == '$' and i + 1 < n:
                if src[i + 1] == '{':
                    if i > texte_debut:
                        morceaux.append(('t', src[texte_debut:i]))
                    fin = code(i + 2, fin_accolade=True)
                    morceaux.append(('i', src[i + 2:fin].strip(), i, fin + 1))
                    i = fin + 1
                    texte_debut = i
                    continue
                m = re.match(r'[A-Za-z_][A-Za-z0-9_]*', src[i + 1:])
                if m:
                    if i > texte_debut:
                        morceaux.append(('t', src[texte_debut:i]))
                    morceaux.append(('i', m.group(0), i, i + 1 + len(m.group(0))))
                    i = i + 1 + len(m.group(0))
                    texte_debut = i
                    continue
            nature[i] = 's'
            i += 1
        if i > texte_debut:
            morceaux.append(('t', src[texte_debut:i]))
        fin = min(n, i + len(g))
        lexemes.append(Lexeme(debut, fin, g, brut, morceaux))
        for k in range(debut, debut + (1 if brut else 0) + len(g)):
            nature[k] = 's'
        for k in range(max(debut, fin - len(g)), fin):
            nature[k] = 's'
        return fin

    code(0)
    return nature, lexemes


def suite_de_litteraux(src, i, par_debut):
    """Une ou plusieurs chaînes adjacentes à partir de i (espaces sautés) : (liste, fin)."""
    j = sauter(src, i)
    if j not in par_debut:
        return None, i
    liste = []
    while j in par_debut:
        lx = par_debut[j]
        liste.append(lx)
        j = sauter(src, lx.fin)
    return liste, liste[-1].fin


def sauter(src, i):
    while i < len(src):
        if src[i].isspace():
            i += 1
        elif src.startswith('//', i):
            j = src.find('\n', i)
            i = len(src) if j == -1 else j
        else:
            break
    return i


def nom_de(expr, noms):
    """Un nom de marque lisible pour l'expression : `widget.nom` → nom, `vins.length` →
    vins_length, une expression composée → v1, v2…"""
    pris = set(noms.values())
    if re.fullmatch(r'[A-Za-z_]\w*(?:\.[A-Za-z_]\w*)*', expr):
        seg = expr.split('.')
        base = seg[-1]
        if base in GENERIQUES and len(seg) > 1:
            base = f'{seg[-2]}_{base}'
        base = base.lstrip('_') or 'v'
        nom, k = base, 2
        while nom in pris:
            nom, k = f'{base}{k}', k + 1
        return nom
    k = 1
    while f'v{k}' in pris:
        k += 1
    return f'v{k}'


def modele(liste, noms):
    """Le texte source des chaînes, interpolations remplacées par {nom}."""
    sortie = []
    for lx in liste:
        corps = []
        for m in lx.morceaux:
            if m[0] == 't':
                corps.append(m[1])
            else:
                expr = m[1]
                if expr not in noms:
                    noms[expr] = nom_de(expr, noms)
                corps.append('{' + noms[expr] + '}')
        prefixe = 'r' if lx.brut else ''
        sortie.append(prefixe + lx.guillemet + ''.join(corps) + lx.guillemet)
    return ' '.join(sortie)


def texte_original(src, liste):
    return src[liste[0].debut:liste[-1].fin]


def convertir(src):
    nature, lexemes = analyser(src)
    par_debut = {lx.debut: lx for lx in lexemes}
    remplacements, refus = [], []

    def en_code(i):
        return 0 <= i < len(nature) and nature[i] == 'c'

    # 1. tr('…$x…', '…') sans troisième argument.
    for m in re.finditer(r'(?<![\w.])tr\(', src):
        if not en_code(m.start()):
            continue
        l1, f1 = suite_de_litteraux(src, m.end(), par_debut)
        if not l1:
            continue
        j = sauter(src, f1)
        if j >= len(src) or src[j] != ',':
            continue
        l2, f2 = suite_de_litteraux(src, j + 1, par_debut)
        if not l2:
            continue
        k = sauter(src, f2)
        if k < len(src) and src[k] == ',':
            k2 = sauter(src, k + 1)
            if k2 < len(src) and src[k2] == ')':
                k = k2
            else:
                continue  # déjà des valeurs
        if k >= len(src) or src[k] != ')':
            continue
        if not any(lx.interpole for lx in l1 + l2):
            continue
        noms = {}
        a, b = modele(l1, noms), modele(l2, noms)
        valeurs = ', '.join(f"'{v}': {e}" for e, v in noms.items())
        remplacements.append((m.start(), k + 1, f'tr({a}, {b}, {{{valeurs}}})'))

    # 2. cond ? 'A' : 'B'
    for m in re.finditer(r'(?<![\w.$])(' + CONDITIONS + r')\s*\?(?!\?|\.)\s*', src):
        if not en_code(m.start()):
            continue
        cond = m.group(1)
        avant = src[:m.start()].rstrip()
        ok_avant = (not avant or (avant[-1] in '(,[{:?' and not avant.endswith('??')) or avant.endswith('return')
                    or (avant[-1] == '=' and (len(avant) < 2 or avant[-2] not in '=!<>'))
                    or avant.endswith('=>'))
        l1, f1 = suite_de_litteraux(src, m.end(), par_debut)
        if not l1:
            continue
        if not ok_avant:
            refus.append((m.start(), 'expression englobante'))
            continue
        j = sauter(src, f1)
        if j >= len(src) or src[j] != ':':
            refus.append((m.start(), 'branche « alors » composée'))
            continue
        l2, f2 = suite_de_litteraux(src, j + 1, par_debut)
        if not l2:
            refus.append((m.start(), 'branche « sinon » non littérale'))
            continue
        k = sauter(src, f2)
        if k < len(src) and src[k] not in ',)];}:\n' and not src.startswith('..', k):
            refus.append((m.start(), f'expression prolongée par « {src[k]} »'))
            continue
        noms = {}
        a, b = modele(l1, noms), modele(l2, noms)
        valeurs = (', {' + ', '.join(f"'{v}': {e}" for e, v in noms.items()) + '}') if noms else ''
        if cond == 'Langue.estFr':
            nouveau = f'tr({a}, {b}{valeurs})'
        else:
            nouveau = f'trSi({cond}, {a}, {b}{valeurs})'
        remplacements.append((m.start(), f2, nouveau))

    # Appliquer sans chevauchement, de la fin vers le début ; un chevauchement attendra le
    # passage suivant.
    remplacements.sort(key=lambda r: r[0], reverse=True)
    appliques, borne = [], len(src) + 1
    for d, f, t in remplacements:
        if f <= borne:
            src = src[:d] + t + src[f:]
            borne = d
            appliques.append((d, f, t))
    return src, len(appliques), refus


def main():
    racine = Path(sys.argv[1])
    essai = '--essai' in sys.argv
    total, fichiers, tous_refus = 0, 0, []
    for p in sorted(racine.rglob('*.dart')):
        if '/l10n/' in str(p) or str(p).endswith('.g.dart') or p.name == 'langue.dart':
            continue
        src = p.read_text()
        nouveau, n = src, 0
        for _ in range(8):  # les conversions imbriquées se font en plusieurs passages
            nouveau, k, refus = convertir(nouveau)
            n += k
            if k == 0:
                break
        tous_refus += [(p, nouveau[:pos].count('\n') + 1, raison) for pos, raison in refus]
        if n:
            total += n
            fichiers += 1
            if not essai:
                if 'trSi(' in nouveau or 'tr(' in nouveau:
                    nouveau = ajouter_import(p, nouveau, racine)
                p.write_text(nouveau)
    print(f'{total} conversions dans {fichiers} fichiers')
    print(f'{len(tous_refus)} cas laissés tels quels :')
    for p, ligne, raison in tous_refus:
        print(f'  {p}:{ligne} — {raison}')


def ajouter_import(p, src, racine):
    if 'shared/utils/langue.dart' in src:
        return src
    rel = Path('shared/utils/langue.dart')
    profondeur = len(p.relative_to(racine).parts) - 1
    chemin = '../' * profondeur + str(rel)
    m = list(re.finditer(r"^import [^\n]+;\n", src, re.M))
    if not m:
        return f"import '{chemin}';\n" + src
    fin = m[-1].end()
    return src[:fin] + f"import '{chemin}';\n" + src[fin:]


if __name__ == '__main__':
    main()
