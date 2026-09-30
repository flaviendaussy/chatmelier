#!/usr/bin/env bash
# Une base Postgres jetable pour essayer les migrations avant la production.
#
#   tool/base_jetable/base_jetable.sh 047 051 052     # socle, puis ces migrations, puis les essais
#
# Utilise l'image pgvector/pgvector:pg15 déjà présente (aucun téléchargement), écoute sur
# 127.0.0.1:55432 seulement, sans mot de passe, et disparaît à la fin (`--rm`).
# Les essais sont les fichiers tool/base_jetable/essais/<numéro>_*.sql des migrations
# demandées : chacun lève une exception au premier écart, ce qui arrête tout.
set -euo pipefail

ICI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPOT="$(cd "$ICI/../.." && pwd)"
NOM=chatmelier_base_jetable
PORT=55432
IMAGE=pgvector/pgvector:pg15

docker rm -f "$NOM" >/dev/null 2>&1 || true
docker run -d --rm --name "$NOM" -p 127.0.0.1:$PORT:5432 \
  -e POSTGRES_HOST_AUTH_METHOD=trust "$IMAGE" >/dev/null
trap 'docker rm -f "$NOM" >/dev/null 2>&1 || true' EXIT

for _ in $(seq 1 60); do
  docker exec "$NOM" pg_isready -U postgres >/dev/null 2>&1 && break
  sleep 0.5
done
sleep 1

psql_() { PGOPTIONS="${PGOPTIONS:--c client_min_messages=warning}" psql "postgresql://postgres@127.0.0.1:$PORT/postgres" -X -q -v ON_ERROR_STOP=1 "$@"; }

echo "▸ socle"
psql_ -f "$ICI/socle.sql" >/dev/null

for n in "$@"; do
  f=$(ls "$DEPOT"/supabase/migrations/"$n"_*.sql)
  echo "▸ migration $(basename "$f")"
  psql_ -f "$f"
  echo "▸ rejouée (idempotence)"
  psql_ -f "$f" >/dev/null
done

for n in "$@"; do
  for e in "$ICI"/essais/"$n"_*.sql; do
    [ -f "$e" ] || continue
    echo "▸ essais $(basename "$e")"
    PGOPTIONS="-c client_min_messages=notice" psql_ -f "$e"
  done
done
echo "✅ tout est passé"
