#!/usr/bin/env python3
"""Traduire le catalogue par lots (V2.3 · H4).

    python3 tool/langues/lot.py es afficher 0 120        # le lot n° 0, 120 phrases
    python3 tool/langues/lot.py es appliquer traduction.json

Le fichier de traduction est un objet {"<numéro>": "<phrase traduite>"}. Chaque traduction
doit garder exactement les {marques} de la phrase française : sinon elle est refusée et
signalée, et la phrase reste à traduire.
"""
import json
import re
import sys
from pathlib import Path

DEPOT = Path(__file__).resolve().parents[2]
MARQUE = re.compile(r'\{(\w+)\}')


def charger(langue):
    chemin = DEPOT / 'app' / 'l10n_catalogues' / f'{langue}.json'
    return chemin, json.loads(chemin.read_text())


def main():
    langue, action = sys.argv[1], sys.argv[2]
    chemin, entrees = charger(langue)
    if action == 'afficher':
        n, taille = int(sys.argv[3]), int(sys.argv[4])
        for i in range(n * taille, min(len(entrees), (n + 1) * taille)):
            e = entrees[i]
            etat = '✓' if e.get(langue) else ' '
            print(f"{i}{etat}\t{json.dumps(e['fr'], ensure_ascii=False)}\t{json.dumps(e['en'], ensure_ascii=False)}\t{e['ou'].split('/')[-1]}")
        restantes = sum(1 for e in entrees if not e.get(langue))
        print(f'— {restantes} phrases restent à traduire sur {len(entrees)}')
    elif action == 'appliquer':
        traductions = json.loads(Path(sys.argv[3]).read_text())
        refus = 0
        for cle, texte in traductions.items():
            e = entrees[int(cle)]
            attendues = set(MARQUE.findall(e['fr']))
            if set(MARQUE.findall(texte)) != attendues:
                print(f'refusée {cle} : marques {sorted(set(MARQUE.findall(texte)))} au lieu de {sorted(attendues)} — {e["fr"][:60]}')
                refus += 1
                continue
            e[langue] = texte
        chemin.write_text(json.dumps(entrees, ensure_ascii=False, indent=1) + '\n')
        restantes = sum(1 for e in entrees if not e.get(langue))
        print(f'{len(traductions) - refus} traductions appliquées, {refus} refusées ; {restantes} restent à traduire')


if __name__ == '__main__':
    main()
