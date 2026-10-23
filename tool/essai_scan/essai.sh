#!/usr/bin/env bash
# Essai de `scan-label` en deux temps (lecture, puis description) dans l'edge runtime local,
# contre de faux Supabase et Gemini — rien de payé, aucune vraie clé.
#
#   tool/essai_scan/essai.sh
set -euo pipefail
ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPOT="$(cd "$ICI/../.." && pwd)"
PORT_FAUX=9877
PORT_FONCTION=9124
NOM=essai-scan-label
trap 'docker rm -f "$NOM" >/dev/null 2>&1 || true; kill "${FAUX:-0}" 2>/dev/null || true' EXIT

python3 "$ICI/faux_serveurs.py" "$PORT_FAUX" &
FAUX=$!

docker rm -f "$NOM" >/dev/null 2>&1 || true
docker run -d --name "$NOM" --network host \
  -v "$DEPOT/supabase/functions:/home/deno/functions:ro" \
  -e SUPABASE_URL="http://127.0.0.1:$PORT_FAUX" \
  -e SUPABASE_ANON_KEY="cle-publique-de-test" \
  -e SUPABASE_SERVICE_ROLE_KEY="cle-service-de-test" \
  -e GEMINI_API_KEY="cle-gemini-de-test" \
  -e GEMINI_BASE_URL="http://127.0.0.1:$PORT_FAUX" \
  public.ecr.aws/supabase/edge-runtime:v1.74.3 start --main-service /home/deno/functions/scan-label --port $PORT_FONCTION >/dev/null

for _ in $(seq 1 90); do
  curl -s -o /dev/null -X OPTIONS "http://127.0.0.1:$PORT_FONCTION/" 2>/dev/null && break
  sleep 1
done

JWT='eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1LWZsYXZpZW4iLCJyb2xlIjoiYXV0aGVudGljYXRlZCJ9.c2lnbmF0dXJl'
appel() {
  curl -s -w '\n%{time_total}' -X POST "http://127.0.0.1:$PORT_FONCTION/" -H 'Content-Type: application/json' \
    -H "Authorization: Bearer $JWT" -d "$1"
}
IMAGE=$(printf 'etiquette' | base64)
IMAGE_CONNUE=$(printf 'CONNU' | base64)
TOUT=$(appel "{\"imageBase64\": \"$IMAGE\", \"languageCode\": \"fr\"}")
LECTURE=$(appel "{\"imageBase64\": \"$IMAGE\", \"languageCode\": \"fr\", \"etape\": \"lecture\"}")
SUITE=$(python3 -c "import json,sys; print(json.loads(sys.argv[1].rsplit(chr(10),1)[0]).get('suite',''))" "$LECTURE")
DESCRIPTION=$(appel "{\"etape\": \"description\", \"suite\": \"$SUITE\", \"languageCode\": \"fr\"}")
# Retoucher la signature à coup sûr : remplacer son dernier caractère par un autre.
DERNIER="${SUITE: -1}"
[ "$DERNIER" = "A" ] && AUTRE="B" || AUTRE="A"
FAUSSE=$(appel "{\"etape\": \"description\", \"suite\": \"${SUITE%?}$AUTRE\", \"languageCode\": \"fr\"}")
INVENTEE=$(appel '{"etape": "description", "suite": "eyJsdWUiOnsibmFtZSI6IlBldHJ1cyJ9LCJleHAiOjk5OTk5OTk5OTk5OTl9.AAAA"}')
CONNUE=$(appel "{\"imageBase64\": \"$IMAGE_CONNUE\", \"languageCode\": \"fr\", \"etape\": \"lecture\"}")
sleep 1
JOURNAL=$(curl -s "http://127.0.0.1:$PORT_FAUX/journal")

python3 - "$TOUT" "$LECTURE" "$DESCRIPTION" "$FAUSSE" "$INVENTEE" "$CONNUE" "$JOURNAL" <<'PY'
import json, sys
def lire(x):
    corps, duree = x.rsplit('\n', 1)
    return json.loads(corps), float(duree)
(tout, t_tout), (lecture, t_lecture), (description, t_desc), (fausse, _), (inventee, _), (connue, t_connue) = (lire(x) for x in sys.argv[1:7])
journal = json.loads(sys.argv[7])
def ok(cond, msg):
    if not cond:
        print('❌', msg)
        print(json.dumps({'tout': tout, 'lecture': lecture, 'description': description, 'fausse': fausse, 'connue': connue, 'journal': journal}, ensure_ascii=False, indent=1)[:4000])
        sys.exit(1)
    print('✅', msg)
ok(tout.get('name') == 'Ungrafted Cinsault' and tout.get('grapes') and tout.get('complete') is True,
   f"sans étape (versions d'avant la 88) : tout d'un coup, comme avant ({t_tout:.1f} s)")
ok(lecture.get('name') == 'Ungrafted Cinsault' and lecture.get('complete') is False and not lecture.get('tasting_notes'),
   f"lecture : le vin lu, sans la description ({t_lecture:.1f} s au lieu de {t_tout:.1f})")
ok(t_lecture < t_tout - 1.0, 'la lecture répond avant la description (1,5 s de moins ici)')
ok(isinstance(lecture.get('suite'), str) and '.' in lecture['suite'], 'une suite signée accompagne la lecture')
ok(len(lecture.get('couts', [])) == 1 and lecture['couts'][0]['fonction'] == 'scan_vision', 'la lecture ne compte que la lecture')
ok(description.get('tasting_notes') and description.get('grapes') == [{'name': 'Cinsault', 'pct': 100}] and description.get('complete') is True,
   f"description : notes, cépages, garde ({t_desc:.1f} s)")
ok(description.get('name') == 'Ungrafted Cinsault', 'la description reprend le vin lu, signé')
ok(len(description.get('couts', [])) == 1 and description['couts'][0]['fonction'] == 'scan_enrichment', 'la description compte la description')
ok(fausse.get('error') == 'suite_invalide', 'une suite retouchée est refusée')
ok(inventee.get('error') == 'suite_invalide', 'une suite inventée (un Petrus signé de rien) est refusée')
quotas = [j['quota'] for j in journal if 'quota' in j]
ok(quotas == ['scan_etiquette', 'scan_etiquette', 'scan_etiquette'], f"un quota par étiquette, pas par étape : {quotas}")
ok(connue.get('from_cache') is True and connue.get('complete') is True and connue.get('grapes'),
   f"un vin du catalogue : la fiche entière dès la lecture ({t_connue:.1f} s)")
ecrites = [j['fiche_ecrite'] for j in journal if 'fiche_ecrite' in j]
ok(ecrites.count('Ungrafted Cinsault') == 2, 'le catalogue apprend la description, des deux façons')
print('✅ scan-label en deux temps : tout est passé')
PY

# ─── taches-ia · cepages : le cache commun, le catalogue, puis le web ─────────────────
docker rm -f "$NOM" >/dev/null 2>&1 || true
docker run -d --name "$NOM" --network host \
  -v "$DEPOT/supabase/functions:/home/deno/functions:ro" \
  -e SUPABASE_URL="http://127.0.0.1:$PORT_FAUX" \
  -e SUPABASE_ANON_KEY="cle-publique-de-test" \
  -e SUPABASE_SERVICE_ROLE_KEY="cle-service-de-test" \
  -e GEMINI_API_KEY="cle-gemini-de-test" \
  -e GEMINI_BASE_URL="http://127.0.0.1:$PORT_FAUX" \
  public.ecr.aws/supabase/edge-runtime:v1.74.3 start --main-service /home/deno/functions/taches-ia --port $PORT_FONCTION >/dev/null
for _ in $(seq 1 90); do
  curl -s -o /dev/null -X OPTIONS "http://127.0.0.1:$PORT_FONCTION/" 2>/dev/null && break
  sleep 1
done
# Une tâche en « low » d'abord, sur le même modèle : elle ne doit pas imposer son niveau à
# la recherche des cépages (le 23/10, le niveau retenu l'était par modèle seul).
appel '{"tache": "recit_source", "nom": "Château Musar", "producteur": "Château Musar", "millesime": 2016}' >/dev/null
AVANT=$(curl -s "http://127.0.0.1:$PORT_FAUX/journal" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")
C1=$(appel '{"tache": "cepages", "nom": "Ungrafted Cinsault", "producteur": "De Martino", "region": "Itata", "pays": "Chile", "couleur": "red"}')
C2=$(appel '{"tache": "cepages", "nom": "Ungrafted  Cinsault", "producteur": "DE MARTINO"}')
C3=$(appel '{"tache": "cepages", "nom": "Clos Connu", "producteur": "Domaine Témoin"}')
C4=$(appel '{"tache": "cepages", "nom": "Vin Introuvable", "producteur": "Personne"}')
C5=$(appel '{"tache": "cepages", "nom": "Vin Introuvable", "producteur": "Personne"}')
C6=$(appel '{"tache": "cepages", "nom": "Vinhas Velhas Reserva Tinto", "producteur": "Terrenus", "region": "Alentejo"}')
C7=$(appel '{"tache": "cepages", "nom": "El Bernate Rioja Blanco", "producteur": "Exopto"}')
C8=$(appel '{"tache": "cepages", "nom": "Finca Notables Tannat", "producteur": "El Esteco"}')
JOURNAL=$(curl -s "http://127.0.0.1:$PORT_FAUX/journal")
python3 - "$C1" "$C2" "$C3" "$C4" "$C5" "$JOURNAL" "$AVANT" "$C6" "$C7" "$C8" <<'PY'
import json, sys
def lire(x):
    corps, duree = x.rsplit('\n', 1)
    return json.loads(corps), float(duree)
(c1, t1), (c2, t2), (c3, t3), (c4, _), (c5, _) = (lire(x) for x in sys.argv[1:6])
journal = json.loads(sys.argv[6])[int(sys.argv[7]):]
def ok(cond, msg):
    if not cond:
        print('❌', msg); print(json.dumps({'c1': c1, 'c2': c2, 'c3': c3, 'c4': c4, 'c5': c5, 'journal': journal}, ensure_ascii=False, indent=1)[:4000]); sys.exit(1)
    print('✅', msg)
r1 = c1['resultat']
ok(r1['cepages'] == [{'name': 'Cinsault', 'pct': 100}] and r1['methode'] == 'recherche' and r1['source'].startswith('https://'),
   f"un vin inconnu : cherché sur le web, avec sa source ({t1:.1f} s)")
ok(c1['couts'] and c1['couts'][0]['recherche'] is True, 'la recherche se compte, et se dit')
ok(c2['resultat']['cepages'] == r1['cepages'] and c2['resultat']['methode'] == 'cache',
   f"le suivant (même vin, autre casse, autres espaces) : le cache, sans rien payer ({t2:.1f} s)")
ok(c2['couts'] == [], 'rien de payé pour le suivant')
ok(c3['resultat']['methode'] == 'catalogue' and c3['resultat']['cepages'] == [{'name': 'Syrah', 'pct': 100}],
   'un vin que le catalogue décrit déjà : ses cépages, sans recherche')
ok(c4['resultat']['cepages'] == [] and c4['resultat']['methode'] == 'inconnu', "pas trouvé : on ne devine pas les cépages de la région")
ok(c5['resultat']['methode'] == 'cache' and c5['resultat']['cepages'] == [], 'pas trouvé hier : pas recherché de nouveau aujourd\'hui')
(c6, _), (c7, _), (c8, _) = (lire(x) for x in sys.argv[8:11])
ok(c6['resultat']['cepages'] == [] and c6['resultat']['methode'] == 'inconnu',
   "sans recherche, les cépages de la région (du Baga dans un Alentejo) ne sont pas gardés")
ok(len(c6['couts']) == 2 and c6['couts'][1]['recherche'] is False, 'une seconde demande, plus nette, quand la première n\'a pas cherché')
ok(c7['resultat']['methode'] == 'recherche' and [g['name'] for g in c7['resultat']['cepages']] == ['Viura', 'Malvasía Riojana'],
   'la seconde demande a cherché : ses cépages, avec leur source')
ok(c8['resultat']['methode'] == 'connaissance' and c8['resultat']['cepages'] == [{'name': 'Tannat', 'pct': 100}],
   'sans recherche, le cépage écrit dans le nom reste (« Finca Notables Tannat »)')
geminis = [j for j in journal if j.get('gemini') == 'cepages']
ok(all(g['recherche'] for g in geminis) and all(g['reflexion'] == 'medium' for g in geminis),
   f"l'outil de recherche toujours joint, réflexion « medium » même après une tâche en « low » : {[g['reflexion'] for g in geminis]}")
ok([g['insiste'] for g in geminis] == [False, False, False, True, False, True, False, True],
   f"on n'insiste qu'après une réponse sans recherche : {[g['insiste'] for g in geminis]}")
quotas = [j['quota'] for j in journal if 'quota' in j]
ok(quotas == ['cepages'] * 5, f"le quota compte une recherche par vin, insistance comprise : {quotas}")
ecrits = {j['cache_ecrit']: (j['methode'], j['recherche_faite']) for j in journal if 'cache_ecrit' in j}
ok(ecrits == {'de martino|ungrafted cinsault': ('recherche', True), 'domaine temoin|clos connu': ('catalogue', False),
              'personne|vin introuvable': ('inconnu', True), 'terrenus|vinhas velhas reserva tinto': ('inconnu', False),
              'exopto|el bernate rioja blanco': ('recherche', True), 'el esteco|finca notables tannat': ('connaissance', False)},
   f"gardé pour le suivant, avec la recherche faite ou non : {ecrits}")
print('✅ taches-ia · cepages : tout est passé')
PY
