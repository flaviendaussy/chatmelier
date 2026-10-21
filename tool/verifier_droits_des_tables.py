#!/usr/bin/env python3
"""Chaque table créée par une migration doit dire qui y a droit (Supabase, 30/10/2026).

À partir du 30 octobre 2026, Supabase n'accorde plus d'office l'accès de l'API (PostgREST,
supabase-js, donc l'app ET les fonctions edge en service_role) aux NOUVELLES tables du
schéma public. Une table créée sans GRANT répond « permission denied », même si ses règles
RLS sont justes. Les tables existantes gardent leurs droits.

    python3 tool/verifier_droits_des_tables.py          # migrations à venir (≥ 075) : échec si oubli
    python3 tool/verifier_droits_des_tables.py --tout   # aussi les anciennes, pour information

Une migration passe si, pour chaque `CREATE TABLE public.x`, le même fichier contient un
`GRANT … ON [TABLE] … public.x …`. La base jetable (`tool/base_jetable`) se comporte déjà
comme Supabase après le 30/10 : le socle n'accorde des droits qu'à ses propres tables.
"""
import pathlib
import re
import sys

PREMIERE_CONCERNEE = 75  # 074 et avant sont appliquées : leurs tables gardent leurs droits

racine = pathlib.Path(__file__).resolve().parent.parent / 'supabase' / 'migrations'
tout = '--tout' in sys.argv

creation = re.compile(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?(?:public\.)?"?(\w+)"?', re.I)
octroi = re.compile(r'GRANT\s+[^;]*?\s+ON\s+(?:TABLE\s+)?([^;]*?)\s+TO\s', re.I | re.S)


def sans_commentaires(sql: str) -> str:
    sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.S)
    return re.sub(r'--[^\n]*', '', sql)


oublis = 0
for f in sorted(racine.glob('[0-9][0-9][0-9]_*.sql')):
    numero = int(f.name[:3])
    if numero < PREMIERE_CONCERNEE and not tout:
        continue
    sql = sans_commentaires(f.read_text(encoding='utf-8'))
    tables = {t.lower() for t in creation.findall(sql)}
    if not tables:
        continue
    couvertes = set()
    for cible in octroi.findall(sql):
        if re.search(r'ALL\s+TABLES\s+IN\s+SCHEMA\s+public', cible, re.I):
            couvertes |= tables
        for nom in re.split(r'\s*,\s*', cible):
            couvertes.add(nom.strip().strip('"').lower().removeprefix('public.'))
    manquantes = sorted(tables - couvertes)
    if manquantes:
        a_venir = numero >= PREMIERE_CONCERNEE
        if a_venir:
            oublis += len(manquantes)
        print(f"{'❌' if a_venir else 'ℹ️ '} {f.name} : aucun GRANT pour {', '.join(manquantes)}")

if oublis:
    print(f'\n{oublis} table(s) sans droits : ajouter par exemple, après les règles RLS,\n'
          '  GRANT SELECT, INSERT, UPDATE, DELETE ON public.x TO authenticated;\n'
          '  GRANT ALL ON public.x TO service_role;\n'
          '(anon seulement si la table doit servir sans compte ; une colonne bigserial demande\n'
          ' aussi GRANT USAGE ON SEQUENCE public.x_id_seq TO … pour insérer.)')
    sys.exit(1)
print('✅ toutes les tables des migrations à venir disent qui y a droit'
      if not tout else '\n(les ℹ️ ne comptent que pour recréer un projet neuf depuis les migrations)')
