#!/usr/bin/env bash
# ==============================================================================
# Chatmelier — dépouillement des remontées « secouer pour commenter »
# ==============================================================================
#
#   ./tool/feedback.sh              les 50 dernières remontées
#   ./tool/feedback.sh 200          les 200 dernières
#   ./tool/feedback.sh --count      combien il y en a, par mois
#   ./tool/feedback.sh --sql "…"    une requête libre (lecture seule de toute façon)
#
# La chaîne de connexion vit dans ~/.chatmelier/feedback.env, HORS du dépôt, qui est
# public. Le rôle utilisé (`chatmelier_feedback_ro`, migration 033) ne peut lire que les
# lignes `tag = 'USER_FEEDBACK'`, et pas la colonne `user_id` : ni les caves, ni les
# dégustations, ni les adresses e-mail ne sont accessibles avec ces identifiants.
#
# LES CAPTURES. Depuis la migration 036, le champ « Capture: » n'est plus une URL mais un
# CHEMIN dans le bucket PRIVÉ `feedback` (`<user_id>/<uuid>.png`). C'est voulu : une
# capture d'écran montre tout ce que la personne avait sous les yeux, et un nom de fichier
# aléatoire dans un bucket public rendait l'URL indevinable, pas privée.
#   · à la main : Dashboard → Storage → bucket `feedback` → coller le chemin
#   · par programme : la fonction edge `sign-feedback-capture` signe une URL de 5 minutes
#     après avoir vérifié `profiles.is_admin` côté serveur.
# Les remontées antérieures portent encore une URL publique du bucket `labels` : elles
# restent ouvrables telles quelles.
#
# Mise en place :
#   1. sudo apt install postgresql-client
#   2. SQL Editor :  CREATE ROLE chatmelier_feedback_ro LOGIN PASSWORD '…';
#   3. appliquer supabase/migrations/033_feedback_readonly_role.sql
#   4. mkdir -p ~/.chatmelier && chmod 700 ~/.chatmelier
#      echo 'CHATMELIER_FEEDBACK_URL="postgresql://chatmelier_feedback_ro:…@….supabase.com:5432/postgres"' \
#        > ~/.chatmelier/feedback.env
#      chmod 600 ~/.chatmelier/feedback.env
# ==============================================================================
set -euo pipefail

ENV_FILE="${CHATMELIER_FEEDBACK_ENV:-$HOME/.chatmelier/feedback.env}"

if [ ! -r "$ENV_FILE" ]; then
  echo "❌ $ENV_FILE introuvable ou illisible." >&2
  echo "   Voir la procédure de mise en place en tête de ce script." >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$ENV_FILE"

if [ -z "${CHATMELIER_FEEDBACK_URL:-}" ]; then
  echo "❌ CHATMELIER_FEEDBACK_URL n'est pas défini dans $ENV_FILE." >&2
  exit 1
fi

if ! command -v psql > /dev/null 2>&1; then
  echo "❌ psql absent :  sudo apt install postgresql-client" >&2
  exit 1
fi

# `-v ON_ERROR_STOP=1` pour que le script échoue franchement plutôt qu'à moitié.
run() { psql "$CHATMELIER_FEEDBACK_URL" -v ON_ERROR_STOP=1 -X -q "$@"; }

case "${1:---last}" in
  --count)
    run -c "SELECT date_trunc('month', created_at)::date AS mois, count(*) AS remontees
            FROM public.app_diagnostic_logs
            GROUP BY 1 ORDER BY 1 DESC;"
    ;;

  --sql)
    [ $# -ge 2 ] || { echo "❌ --sql attend une requête" >&2; exit 1; }
    run -c "$2"
    ;;

  --help|-h)
    sed -n '3,33p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
    ;;

  *)
    limit="${1:-50}"
    [ "$limit" = "--last" ] && limit=50
    case "$limit" in
      ''|*[!0-9]*) echo "❌ « $limit » n'est pas un nombre" >&2; exit 1 ;;
    esac
    # Format étendu : les commentaires sont longs et tiennent mal en colonnes.
    run -x -c "SELECT created_at, platform, app_version, device_id, message
               FROM public.app_diagnostic_logs
               ORDER BY created_at DESC
               LIMIT $limit;"
    ;;
esac
