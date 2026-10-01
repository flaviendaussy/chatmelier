#!/usr/bin/env python3
"""Génère le catalogue Dart d'une langue depuis son fichier JSON (V2.3 · H4).

    python3 tool/langues/generer.py es     # app/l10n_catalogues/es.json → lib/shared/langues/catalogue_es.g.dart

Seules les phrases traduites entrent dans le catalogue ; les autres s'afficheront en anglais.
"""
import json
import sys
from pathlib import Path

DEPOT = Path(__file__).resolve().parents[2]


def dart(texte):
    """Une chaîne littérale Dart entre apostrophes, sans interpolation possible."""
    s = (texte.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$')
         .replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t'))
    return f"'{s}'"


def main():
    langue = sys.argv[1] if len(sys.argv) > 1 else 'es'
    entrees = json.loads((DEPOT / 'app' / 'l10n_catalogues' / f'{langue}.json').read_text())
    nom = 'catalogue' + langue.capitalize()
    lignes = [
        f'// Généré par tool/langues/generer.py depuis app/l10n_catalogues/{langue}.json — ne pas modifier.',
        '// ignore_for_file: lines_longer_than_80_chars',
        f'const Map<String, String> {nom} = {{',
    ]
    n = 0
    for e in entrees:
        if e.get(langue):
            lignes.append(f"  {dart(e['fr'])}: {dart(e[langue])},")
            n += 1
    lignes.append('};')
    sortie = DEPOT / 'app' / 'lib' / 'shared' / 'langues' / f'catalogue_{langue}.g.dart'
    sortie.write_text('\n'.join(lignes) + '\n')
    print(f'{n} phrases écrites dans {sortie.relative_to(DEPOT)}')


if __name__ == '__main__':
    main()
