#!/usr/bin/env bash
# Lance une fonction edge dans l'edge runtime local (image déjà présente), contre le faux
# Gemini + faux Supabase de faux_serveur.py, et envoie une requête.
#
#   tool/banc_ia/essai_local.sh scan-label inconnu '{"imageBase64":"AAAA"}'
#
# Sortie : la réponse de la fonction, puis le journal des requêtes qu'elle a émises
# (dans $JOURNAL, par défaut /tmp/essai_local_journal.jsonl).
set -euo pipefail
FONCTION=$1
MODE=$2
CORPS=${3:-'{"imageBase64":"AAAA"}'}
ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPOT="$(cd "$ICI/../.." && pwd)"
JOURNAL=${JOURNAL:-/tmp/essai_local_journal.jsonl}
: > "$JOURNAL"

python3 "$ICI/faux_serveur.py" "$MODE" "$JOURNAL" & FAUX=$!
docker rm -f edge-essai >/dev/null 2>&1 || true
docker run -d --name edge-essai --network host \
  -v "$DEPOT/supabase/functions:/home/deno/functions:ro" \
  -e SUPABASE_URL=http://127.0.0.1:8765 -e SUPABASE_ANON_KEY=cle-publique-factice \
  -e SUPABASE_SERVICE_ROLE_KEY=cle-serveur-factice -e GEMINI_API_KEY=cle-gemini-factice \
  -e GEMINI_BASE_URL=http://127.0.0.1:8765 \
  public.ecr.aws/supabase/edge-runtime:v1.74.3 start --main-service "/home/deno/functions/$FONCTION" --port 9123 >/dev/null
trap 'docker rm -f edge-essai >/dev/null 2>&1 || true; kill $FAUX 2>/dev/null || true' EXIT

for _ in $(seq 1 60); do
  curl -s -o /dev/null http://127.0.0.1:9123/ -X OPTIONS && break
  sleep 0.5
done
curl -s -m 60 -X POST http://127.0.0.1:9123/ -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer jeton-factice' -d "$CORPS"
echo
echo "--- journal"
cat "$JOURNAL"
