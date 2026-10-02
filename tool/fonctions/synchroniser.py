#!/usr/bin/env python3
"""Recopie le bloc commun des modèles Gemini dans chaque fonction (V2.3 · K8).

Le déploiement par le Dashboard Supabase demande un fichier unique par fonction : le bloc
de tool/fonctions/bloc_modeles_gemini.ts est donc recopié entre ses marqueurs dans
chaque supabase/functions/<nom>/index.ts. Un test de l'app vérifie que les copies sont à
jour (test/outils/blocs_des_fonctions_test.dart).

    python3 tool/fonctions/synchroniser.py            # recopie
    python3 tool/fonctions/synchroniser.py --verifier # échoue si une copie diffère
"""
import sys
from pathlib import Path

DEPOT = Path(__file__).resolve().parents[2]
SOURCE = DEPOT / 'tool' / 'fonctions' / 'bloc_modeles_gemini.ts'
FONCTIONS = ['chat', 'menu-chat', 'scan-label', 'scan-menu', 'taches-ia', 'update-wine-values']
DEBUT = '// >>> Modèles Gemini'
FIN = '// <<< Modèles Gemini <<<'


def bloc():
    return SOURCE.read_text().strip('\n')


def remplacer(texte, nouveau, nom):
    debut, fin = texte.find(DEBUT), texte.find(FIN)
    if debut < 0 or fin < 0:
        raise SystemExit(f'{nom} : marqueurs du bloc des modèles introuvables')
    return texte[:debut] + nouveau + texte[fin + len(FIN):]


def main():
    verifier = '--verifier' in sys.argv
    nouveau = bloc()
    ecarts = []
    for nom in FONCTIONS:
        chemin = DEPOT / 'supabase' / 'functions' / nom / 'index.ts'
        texte = chemin.read_text()
        a_jour = remplacer(texte, nouveau, nom)
        if a_jour != texte:
            ecarts.append(nom)
            if not verifier:
                chemin.write_text(a_jour)
    if verifier and ecarts:
        raise SystemExit('copies à mettre à jour : ' + ', '.join(ecarts))
    print('à jour' if not ecarts else ('recopié dans : ' + ', '.join(ecarts)))


if __name__ == '__main__':
    main()
