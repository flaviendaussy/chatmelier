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
#   Depuis la migration 043 (phase de test) — tous les niveaux, et qui :
#   ./tool/feedback.sh --errors [jours]              WARNING + ERROR groupés (défaut 10 j)
#   ./tool/feedback.sh --user <prénom|pseudo> [j]    fil chronologique d'une personne
#   ./tool/feedback.sh --around "2026-09-23 19:07" [minutes] [prénom]
#                                                    tout ce qui s'est passé autour d'un instant
#
# ⚠️  HEURES : `created_at` est l'heure MURALE de l'appareil (AppLogger l'envoie sans
#     fuseau, et la base la range comme de l'UTC). Chercher « 19:07 » en Écosse, c'est
#     donc chercher 19:07 tel quel, sans conversion.
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
#   4. URI du **Session pooler** (Dashboard → Connect), pas la connexion directe : celle-ci
#      n'est plus joignable qu'en IPv6, et un réseau sans IPv6 échoue avec « réseau non
#      accessible ». Utilisateur : chatmelier_feedback_ro.<ref du projet>.
#      mkdir -p ~/.chatmelier && chmod 700 ~/.chatmelier
#      echo 'CHATMELIER_FEEDBACK_URL="postgresql://chatmelier_feedback_ro.fvnybncauhbpsnikzeeq:…@aws-….pooler.supabase.com:5432/postgres"' \
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
            WHERE tag = 'USER_FEEDBACK'
            GROUP BY 1 ORDER BY 1 DESC;"
    ;;

  --sql)
    [ $# -ge 2 ] || { echo "❌ --sql attend une requête" >&2; exit 1; }
    run -c "$2"
    ;;

  --errors)
    jours="${2:-10}"
    case "$jours" in ''|*[!0-9]*) echo "❌ « $jours » n'est pas un nombre de jours" >&2; exit 1 ;; esac
    # Un message par forme : identifiants et nombres remplacés par « # », sinon chaque
    # occurrence d'une même panne serait sa propre ligne.
    run -P pager=off -c "
      WITH l AS (
        SELECT l.level, l.tag, l.created_at, l.app_version,
               coalesce(p.display_name, p.username, left(l.user_id::text, 8), '—') AS qui,
               left(regexp_replace(l.message,
                 '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[0-9]+', '#', 'g'), 150) AS forme
        FROM public.app_diagnostic_logs l
        LEFT JOIN public.profiles p ON p.id = l.user_id
        WHERE l.level IN ('warning', 'error', 'WARNING', 'ERROR')
          AND l.created_at >= now() - interval '$jours days')
      SELECT level, tag, count(*) AS n,
             string_agg(DISTINCT qui, ', ') AS qui,
             to_char(max(created_at), 'DD/MM HH24:MI') AS derniere,
             string_agg(DISTINCT app_version, ',') AS versions,
             forme
      FROM l GROUP BY level, tag, forme
      ORDER BY level DESC, n DESC
      LIMIT 80;"
    ;;

  --user)
    [ $# -ge 2 ] || { echo "❌ --user attend un prénom ou un pseudo" >&2; exit 1; }
    nom="${2//\'/\'\'}"; jours="${3:-10}"
    case "$jours" in ''|*[!0-9]*) echo "❌ « $jours » n'est pas un nombre de jours" >&2; exit 1 ;; esac
    run -P pager=off -c "
      SELECT to_char(l.created_at, 'DD/MM HH24:MI:SS') AS quand, l.level, l.tag,
             l.platform, l.app_version, left(l.message, 170) AS message
      FROM public.app_diagnostic_logs l
      JOIN public.profiles p ON p.id = l.user_id
      WHERE (p.display_name ILIKE '%$nom%' OR p.username ILIKE '%$nom%')
        AND l.created_at >= now() - interval '$jours days'
      ORDER BY l.created_at
      LIMIT 400;"
    ;;

  --around)
    [ $# -ge 2 ] || { echo "❌ --around attend un instant : \"2026-09-23 19:07\"" >&2; exit 1; }
    instant="${2//\'/}"; minutes="${3:-15}"; nom="${4//\'/\'\'}"
    case "$minutes" in ''|*[!0-9]*) echo "❌ « $minutes » n'est pas un nombre de minutes" >&2; exit 1 ;; esac
    filtre=""
    [ -n "$nom" ] && filtre="AND (p.display_name ILIKE '%$nom%' OR p.username ILIKE '%$nom%')"
    run -P pager=off -c "
      SELECT to_char(l.created_at, 'DD/MM HH24:MI:SS') AS quand,
             coalesce(p.display_name, p.username, left(l.user_id::text, 8), '—') AS qui,
             l.level, l.tag, left(l.message, 150) AS message,
             left(coalesce(l.error_details, ''), 120) AS detail
      FROM public.app_diagnostic_logs l
      LEFT JOIN public.profiles p ON p.id = l.user_id
      WHERE l.created_at BETWEEN timestamptz '$instant' - interval '$minutes minutes'
                             AND timestamptz '$instant' + interval '$minutes minutes'
        $filtre
      ORDER BY l.created_at
      LIMIT 400;"
    ;;

  --help|-h)
    sed -n '3,45p' "${BASH_SOURCE[0]}" | sed 's/^# \?//'
    ;;

  *)
    limit="${1:-50}"
    [ "$limit" = "--last" ] && limit=50
    case "$limit" in
      ''|*[!0-9]*) echo "❌ « $limit » n'est pas un nombre" >&2; exit 1 ;;
    esac
    # Format étendu : les commentaires sont longs et tiennent mal en colonnes.
    # Les retours seulement : depuis 043 le rôle voit tout, et le mode par défaut doit
    # rester ce qu'il a toujours été.
    run -x -c "SELECT created_at, platform, app_version, device_id, message
               FROM public.app_diagnostic_logs
               WHERE tag = 'USER_FEEDBACK'
               ORDER BY created_at DESC
               LIMIT $limit;"
    ;;
esac
