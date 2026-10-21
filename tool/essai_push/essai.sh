#!/usr/bin/env bash
# Essai de la fonction `envoyer-push` dans l'edge runtime local, sans rien envoyer pour de vrai.
#
#   tool/essai_push/essai.sh
#
# Une clé RSA jetable sert de « compte de service » ; faux_serveurs.py joue Supabase, Google
# (qui vérifie la signature du jeton) et Firebase. Image edge-runtime déjà présente.
set -euo pipefail
ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPOT="$(cd "$ICI/../.." && pwd)"
TMP="$(mktemp -d)"
PORT_FAUX=9876
PORT_FONCTION=9123
NOM=essai-envoyer-push
trap 'docker rm -f "$NOM" >/dev/null 2>&1 || true; kill "${FAUX:-0}" 2>/dev/null || true; rm -rf "$TMP"' EXIT

openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out "$TMP/cle.pem" 2>/dev/null
openssl pkey -in "$TMP/cle.pem" -pubout -out "$TMP/publique.pem"
COMPTE=$(python3 - "$TMP/cle.pem" "$PORT_FAUX" <<'EOF'
import json, sys
print(json.dumps({"project_id": "projet-essai", "client_email": "essai@projet-essai.iam.gserviceaccount.com",
                  "private_key": open(sys.argv[1]).read(), "token_uri": f"http://127.0.0.1:{sys.argv[2]}/token"}))
EOF
)

python3 "$ICI/faux_serveurs.py" "$PORT_FAUX" "$TMP/publique.pem" &
FAUX=$!

docker rm -f "$NOM" >/dev/null 2>&1 || true
docker run -d --name "$NOM" --network host \
  -v "$DEPOT/supabase/functions:/home/deno/functions:ro" \
  -e SUPABASE_URL="http://127.0.0.1:$PORT_FAUX" \
  -e SUPABASE_SERVICE_ROLE_KEY="cle-service-de-test" \
  -e FCM_BASE_URL="http://127.0.0.1:$PORT_FAUX" \
  -e FCM_SERVICE_ACCOUNT="$COMPTE" \
  public.ecr.aws/supabase/edge-runtime:v1.74.3 start --main-service /home/deno/functions/envoyer-push --port $PORT_FONCTION >/dev/null

for _ in $(seq 1 60); do
  curl -s -o /dev/null "http://127.0.0.1:$PORT_FONCTION/" 2>/dev/null && break
  sleep 1
done

appel() { curl -s -X POST "http://127.0.0.1:$PORT_FONCTION/" -H 'Content-Type: application/json' -d "$1"; }
R1=$(appel '{"notification_id": "11111111-2222-3333-4444-555555555555"}')
R2=$(appel '{"notification_id": "11111111-2222-3333-4444-555555555555"}')
R3=$(appel '{"autre": 1}')
JOURNAL=$(curl -s "http://127.0.0.1:$PORT_FAUX/journal")

python3 - "$R1" "$R2" "$R3" "$JOURNAL" <<'EOF'
import json, sys
r1, r2, r3, journal = (json.loads(x) for x in sys.argv[1:5])
def ok(cond, msg):
    if not cond:
        print('❌', msg); print(json.dumps({'r1': r1, 'r2': r2, 'r3': r3, 'journal': journal}, ensure_ascii=False, indent=1)); sys.exit(1)
    print('✅', msg)
ok(r1.get('envoyes') == 2, f"deux push partis (fr android, en iPhone) — {r1}")
ok(r1.get('calmes') == 1, 'rien à 23 h chez le destinataire')
ok(r1.get('coupes') == 1, "rien pour qui a coupé l'activité de cave")
ok(r1.get('oublies') == 1, 'le jeton mort est oublié')
ok(r2.get('envoye') is False and r2.get('raison') == 'deja_envoyee_ou_inconnue', 'une notification ne part qu\'une fois')
ok('error' in r3, 'un appel sans identifiant est refusé')
messages = [j['message'] for j in journal if 'message' in j]
fr = next(m for m in messages if m['token'].startswith('jeton-android-fr'))
en = next(m for m in messages if m['token'].startswith('jeton-ios-en'))
ok(fr['notification']['body'] == 'Caro a ajouté 3 bouteilles à « London ».', f"texte français : {fr['notification']}")
ok(en['notification']['body'] == 'Caro added 3 bottles to "London".', f"texte anglais : {en['notification']}")
ok(fr['data'] == {'notification_id': '11111111-2222-3333-4444-555555555555', 'type': 'activite_cave', 'ouvrir': '/cellar', 'cellar_id': 'c1'}, 'le toucher ouvre la cave concernée')
ok(en['apns']['payload']['aps']['badge'] == 5, 'la pastille iPhone compte les non lues')
ok(fr['android']['notification']['channel_id'] == 'chatmelier_shared_cellar', 'le canal Android de la cave partagée')
jg = [j['jeton_google'] for j in journal if 'jeton_google' in j]
ok(len(jg) == 1 and jg[0]['scope'] == 'https://www.googleapis.com/auth/firebase.messaging', 'un seul jeton Google, signé, à la bonne portée')
ok(any('efface' in j and 'jeton-mort' in str(j['requete']) for j in journal), 'effacement du jeton mort demandé à la base')
print('✅ envoyer-push : tout est passé')
EOF
