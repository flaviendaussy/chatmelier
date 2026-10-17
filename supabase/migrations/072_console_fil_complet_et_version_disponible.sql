-- 072 · La console : tout ce que fait une personne, et « une nouvelle version est disponible ».
--
-- 1. Le fil d'une personne (admin_fil_personne) ne gardait des journaux que les erreurs, les
--    alertes, les retours et le début des scans. Le 17/10, Flavien : « J'ai l'impression que
--    "activité récente" dans la console ne me montre pas tout du tout. Par ex. Caro vient
--    d'avoir un bug de nearby places -> ça veut sûrement dire qu'elle a scanné quelque
--    chose, non ? » Non : elle avait ouvert l'app, puis « Noter un vin bu dehors », et tapé
--    « domaine Lucy », puis « domaine Mucyn » — rien de cela n'apparaissait, seule l'alerte.
--    Le fil montre désormais les ouvertures de l'app, les vins cherchés par leur nom, les
--    lieux, la connexion, et tout geste journalisé ; seuls restent dehors les journaux
--    techniques (notifications planifiées, cache, publicités, coûts) et ce que les tables
--    disent déjà (bouteilles ajoutées, questions au sommelier).
-- 2. La liste des personnes compte aussi les ouvertures de l'app et les vins cherchés par
--    leur nom : une personne qui ouvre l'app et cherche sans rien enregistrer n'avait aucun
--    geste.
-- 3. `version_disponible` (même forme que `version_minimale_test`) : la version que l'app
--    propose d'installer, sans bloquer, à partir de la 84. Lisible par tous (app_config),
--    réglable depuis la console.
--
-- Vérification :
--   SELECT * FROM public.admin_fil_personne('<id>', 1);   -- en administrateur
--   SELECT public.reglage_invalide('version_disponible', '{"build": 84, "lien": "https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier"}');  -- NULL

CREATE OR REPLACE FUNCTION public.admin_fil_personne(p_user_id uuid, p_jours integer DEFAULT 30)
 RETURNS TABLE(quand timestamp with time zone, genre text, titre text, detail text)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
#variable_conflict use_column
DECLARE
  v_depuis    TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
  v_nominatif BOOLEAN := public.admin_nominatif();
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  RETURN QUERY
  SELECT * FROM (
      SELECT t.consumed_at, 'degustation'::text,
             coalesce(w.name, 'Vin') || coalesce(' ' || w.vintage::text, ''),
             concat_ws(' · ',
               CASE WHEN t.rating IS NULL THEN 'sans note'
                    ELSE 'note ' || t.rating::text || '/' || coalesce(t.rating_scale, 10)::text END,
               CASE WHEN t.is_external THEN 'hors cave' END,
               nullif(trim(coalesce(t.location_name, t.occasion, '')), ''))
        FROM public.tasting_log t LEFT JOIN public.wines w ON w.id = t.wine_id
       WHERE t.user_id = p_user_id AND t.consumed_at >= v_depuis
    UNION ALL
      SELECT b.created_at, 'bouteille',
             coalesce(w.name, 'Vin') || coalesce(' ' || w.vintage::text, ''),
             concat_ws(' · ', 'quantité ' || b.quantity::text, b.source_type,
                       CASE WHEN b.gifted_at IS NOT NULL THEN 'offerte' END)
        FROM public.bottles b LEFT JOIN public.wines w ON w.id = b.wine_id
       WHERE b.added_by = p_user_id AND b.created_at >= v_depuis
    UNION ALL
      SELECT m.created_at, 'question',
             CASE WHEN v_nominatif THEN left(m.content, 160) ELSE '(masqué)' END,
             'sommelier de la cave'
        FROM public.chat_messages m
       WHERE m.user_id = p_user_id AND m.role = 'user' AND m.created_at >= v_depuis
    UNION ALL
      SELECT s.created_at, 'table', 'Table ' || s.code || ' — ' || s.restaurant_name, 'hôte'
        FROM public.table_sessions s
       WHERE s.host_user_id = p_user_id AND s.created_at >= v_depuis
    UNION ALL
      SELECT g.created_at, 'table', 'Rejoint : ' || s.restaurant_name, 'sous le prénom ' || g.guest_name
        FROM public.table_session_guests g JOIN public.table_sessions s ON s.id = g.session_id
       WHERE g.user_id = p_user_id AND g.created_at >= v_depuis
    UNION ALL
      SELECT public.instant_du_journal(l.created_at, l.metadata),
             CASE
               WHEN l.tag = 'USER_FEEDBACK'                                         THEN 'retour'
               WHEN l.level = 'error'                                               THEN 'erreur'
               WHEN l.level = 'warning'                                             THEN 'alerte'
               WHEN l.tag = 'MENU_SCAN' AND l.message LIKE 'Starting multi-page%'   THEN 'scan_carte'
               WHEN l.tag = 'SCAN_AI' AND l.message LIKE 'Starting label analysis%' THEN 'scan_etiquette'
               WHEN l.tag IN ('SCAN_AI', 'SCAN_WEB', 'SCAN_CACHE')                  THEN 'recherche'
               WHEN l.tag = 'MENU_CHAT'                                             THEN 'chat_carte'
               WHEN l.tag = 'USAGE'                                                 THEN 'usage'
               WHEN l.tag = 'SYSTEM' AND l.message LIKE 'Chatmelier app launched%'  THEN 'ouverture'
               WHEN l.tag = 'AUTH'                                                  THEN 'connexion'
               WHEN l.tag IN ('LOCATION', 'NEARBY_PLACES', 'EXTERNAL_TASTING', 'CARTE_DU_LIEU') THEN 'lieu'
               WHEN l.tag = 'CONNECTIVITE'                                          THEN 'reseau'
               ELSE 'geste'
             END,
             CASE
               WHEN l.tag IN ('USER_FEEDBACK', 'MENU_CHAT') AND NOT v_nominatif THEN '(masqué)'
               WHEN l.tag = 'SYSTEM' AND l.message LIKE 'Chatmelier app launched%' THEN 'Ouvre l''app'
               -- Ce que la personne a tapé reste entre guillemets : masqué hors mode nominatif.
               WHEN NOT v_nominatif THEN left(regexp_replace(regexp_replace(l.message, '"[^"]*"', '"…"', 'g'), '\s+', ' ', 'g'), 200)
               ELSE left(regexp_replace(l.message, '\s+', ' ', 'g'), 200)
             END,
             concat_ws(' · ', l.tag, l.platform, l.app_version)
        FROM public.app_diagnostic_logs l
       WHERE l.user_id = p_user_id AND l.created_at >= v_depuis
         AND (l.level IN ('error', 'warning')
              -- Le bruit technique, et ce que les tables disent déjà, restent dehors.
              OR l.tag NOT IN ('NOTIF', 'OFFLINE_CACHE', 'ADMOB', 'LOGGER', 'AI_COST', 'IMAGE_OPT', 'FRIENDS',
                               'ELEVAGE_BACKFILL', 'APOGEE_BACKFILL', 'CHAT_AI', 'CELLAR_REPO')
                 AND NOT (l.tag = 'SYSTEM' AND l.message NOT LIKE 'Chatmelier app launched%')
                 AND NOT (l.tag = 'MENU_SCAN' AND l.message NOT LIKE 'Starting multi-page%'))
  ) fil
  ORDER BY 1 DESC
  LIMIT 500;
END;
$function$;

-- La liste des personnes : les ouvertures de l'app et les vins cherchés par leur nom en plus.
-- Le type rendu change : la fonction est recréée.
DROP FUNCTION IF EXISTS public.admin_personnes(integer);
CREATE FUNCTION public.admin_personnes(p_jours integer DEFAULT 30)
 RETURNS TABLE(user_id uuid, prenom text, anonyme boolean, arrive_le timestamp with time zone,
               derniere_activite timestamp with time zone, plateforme text, version text, degustations integer,
               bouteilles integer, scans_etiquette integer, scans_carte integer, messages integer, tables integer,
               erreurs integer, ouvertures integer, recherches integer)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
#variable_conflict use_column
DECLARE
  v_depuis TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  RETURN QUERY
  SELECT
    u.id,
    public.admin_nom(u.id, p.display_name),
    coalesce(u.is_anonymous, false),
    u.created_at,
    greatest(
      (SELECT max(public.instant_du_journal(l.created_at, l.metadata)) FROM public.app_diagnostic_logs l WHERE l.user_id = u.id),
      (SELECT max(t.consumed_at) FROM public.tasting_log t WHERE t.user_id = u.id),
      (SELECT max(b.created_at) FROM public.bottles b WHERE b.added_by = u.id),
      (SELECT max(m.created_at) FROM public.chat_messages m WHERE m.user_id = u.id)
    ),
    dernier.platform,
    dernier.app_version,
    (SELECT count(*)::int FROM public.tasting_log t WHERE t.user_id = u.id AND t.consumed_at >= v_depuis),
    (SELECT count(*)::int FROM public.bottles b WHERE b.added_by = u.id AND b.created_at >= v_depuis),
    (SELECT count(*)::int FROM public.app_diagnostic_logs l
      WHERE l.user_id = u.id AND l.created_at >= v_depuis
        AND l.tag = 'SCAN_AI' AND l.message LIKE 'Starting label analysis%'),
    (SELECT count(*)::int FROM public.app_diagnostic_logs l
      WHERE l.user_id = u.id AND l.created_at >= v_depuis
        AND l.tag = 'MENU_SCAN' AND l.message LIKE 'Starting multi-page%'),
    (SELECT count(*)::int FROM public.chat_messages m
      WHERE m.user_id = u.id AND m.role = 'user' AND m.created_at >= v_depuis),
    (SELECT count(*)::int FROM public.table_session_guests g WHERE g.user_id = u.id AND g.created_at >= v_depuis)
      + (SELECT count(*)::int FROM public.table_sessions s WHERE s.host_user_id = u.id AND s.created_at >= v_depuis),
    (SELECT count(*)::int FROM public.app_diagnostic_logs l
      WHERE l.user_id = u.id AND l.created_at >= v_depuis AND l.level = 'error'),
    (SELECT count(*)::int FROM public.app_diagnostic_logs l
      WHERE l.user_id = u.id AND l.created_at >= v_depuis
        AND l.tag = 'SYSTEM' AND l.message LIKE 'Chatmelier app launched%'),
    (SELECT count(*)::int FROM public.app_diagnostic_logs l
      WHERE l.user_id = u.id AND l.created_at >= v_depuis
        AND l.tag = 'SCAN_AI' AND l.message LIKE 'Analyzing wine from text%')
  FROM auth.users u
  LEFT JOIN public.profiles p ON p.id = u.id
  LEFT JOIN LATERAL (
    SELECT l.platform, l.app_version
      FROM public.app_diagnostic_logs l
     WHERE l.user_id = u.id
     ORDER BY public.instant_du_journal(l.created_at, l.metadata) DESC
     LIMIT 1
  ) dernier ON true
  ORDER BY 5 DESC NULLS LAST;
END;
$function$;

REVOKE ALL ON FUNCTION public.admin_personnes(integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_personnes(integer) TO authenticated;
REVOKE ALL ON FUNCTION public.admin_fil_personne(uuid, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_fil_personne(uuid, integer) TO authenticated;

-- La version proposée se règle comme la version exigée, et se lit avec les autres réglages.
CREATE OR REPLACE FUNCTION public.reglage_invalide(p_cle text, p_valeur jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
BEGIN
  IF p_valeur IS NULL THEN
    RETURN 'valeur absente';
  END IF;
  CASE p_cle
    WHEN 'scan_etiquette_recherche', 'ia_session_obligatoire', 'admin_detail_nominatif', 'voix_naturelle' THEN
      IF jsonb_typeof(p_valeur) <> 'boolean' THEN
        RETURN 'oui ou non attendu';
      END IF;
    WHEN 'modeles_ia' THEN
      IF jsonb_typeof(p_valeur) <> 'object' THEN
        RETURN 'un réglage par tâche attendu';
      END IF;
      IF EXISTS (
        SELECT 1 FROM jsonb_each(p_valeur) t
         WHERE jsonb_typeof(t.value) <> 'object'
            OR coalesce(t.value ->> 'modele', '') !~ '^[a-z0-9][a-z0-9.-]{1,60}$'
            OR (t.value ? 'reflexion'
                AND jsonb_typeof(t.value -> 'reflexion') <> 'null'
                AND coalesce(t.value ->> 'reflexion', '') NOT IN ('minimal', 'low', 'medium', 'high'))
      ) THEN
        RETURN 'chaque tâche : un modèle (famille ou nom exact) et une réflexion minimal, low, medium, high ou vide';
      END IF;
    WHEN 'version_minimale_test', 'version_disponible' THEN
      IF jsonb_typeof(p_valeur) <> 'object'
         OR jsonb_typeof(p_valeur -> 'build') <> 'number'
         OR (p_valeur ->> 'build')::numeric < 0
         OR (p_valeur ->> 'build')::numeric <> trunc((p_valeur ->> 'build')::numeric)
         OR coalesce(p_valeur ->> 'lien', '') !~ '^https://' THEN
        RETURN 'un numéro de build entier (0 = aucune exigence) et un lien https';
      END IF;
      -- L'iPhone a sa propre exigence, facultative : sans elle, aucun iPhone n'est bloqué.
      IF p_valeur ? 'build_ios' AND (
           jsonb_typeof(p_valeur -> 'build_ios') <> 'number'
           OR (p_valeur ->> 'build_ios')::numeric < 0
           OR (p_valeur ->> 'build_ios')::numeric <> trunc((p_valeur ->> 'build_ios')::numeric)) THEN
        RETURN 'un build iPhone entier, ou rien';
      END IF;
      IF p_valeur ? 'lien_ios' AND coalesce(p_valeur ->> 'lien_ios', '') !~ '^(https|itms-beta)://' THEN
        RETURN 'un lien TestFlight (https:// ou itms-beta://)';
      END IF;
    WHEN 'ecpm_eur_estime' THEN
      IF jsonb_typeof(p_valeur) <> 'object' OR EXISTS (
        SELECT 1 FROM jsonb_each(p_valeur) t
         WHERE jsonb_typeof(t.value) <> 'number'
            OR (t.value #>> '{}')::numeric < 0 OR (t.value #>> '{}')::numeric > 200
      ) THEN
        RETURN 'un eCPM en euros par format, entre 0 et 200';
      END IF;
    WHEN 'quotas_ia' THEN
      IF jsonb_typeof(p_valeur) <> 'object' OR EXISTS (
        SELECT 1 FROM jsonb_each(p_valeur) t
         WHERE jsonb_typeof(t.value) <> 'object'
            OR jsonb_typeof(t.value -> 'compte') <> 'number'
            OR jsonb_typeof(t.value -> 'anonyme') <> 'number'
            OR (t.value ->> 'compte')::numeric NOT BETWEEN 0 AND 10000
            OR (t.value ->> 'anonyme')::numeric NOT BETWEEN 0 AND 10000
      ) THEN
        RETURN 'des limites par jour (compte, anonyme), entre 0 et 10 000';
      END IF;
    WHEN 'taux_de_change' THEN
      IF jsonb_typeof(p_valeur) <> 'object' OR EXISTS (
        SELECT 1 FROM jsonb_each(p_valeur) t
         WHERE t.key !~ '^[A-Z]{3}$'
            OR jsonb_typeof(t.value) <> 'number'
            OR (t.value #>> '{}')::numeric <= 0 OR (t.value #>> '{}')::numeric > 1000
      ) THEN
        RETURN 'un taux en euros par code de devise (GBP, USD…), positif';
      END IF;
    ELSE
      RETURN 'réglage non modifiable depuis la console';
  END CASE;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_reglages()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  RETURN jsonb_build_object(
    'reglages', coalesce((
      SELECT jsonb_object_agg(c.cle, jsonb_build_object('valeur', c.valeur, 'maj_le', c.maj_le))
        FROM public.app_config c
       WHERE c.cle IN ('modeles_ia', 'scan_etiquette_recherche', 'ia_session_obligatoire',
                       'admin_detail_nominatif', 'version_minimale_test', 'version_disponible', 'ecpm_eur_estime',
                       'quotas_ia', 'voix_naturelle', 'taux_de_change')
    ), '{}'::jsonb),
    -- Les modèles réellement servis sur trente jours : de quoi choisir sans rien taper.
    'modeles_servis', coalesce((
      SELECT jsonb_agg(jsonb_build_object('modele', s.model, 'appels', s.n) ORDER BY s.n DESC)
        FROM (SELECT e.model, count(*) AS n
                FROM public.ai_cost_events e
               WHERE e.occurred_at >= now() - interval '30 days'
               GROUP BY e.model) s
    ), '[]'::jsonb),
    'journal', coalesce((
      SELECT jsonb_agg(jsonb_build_object(
               'cle', j.cle, 'avant', j.avant, 'apres', j.apres, 'le', j.le,
               'par', public.admin_nom(j.par, p.display_name)) ORDER BY j.le DESC)
        FROM (SELECT * FROM public.journal_des_reglages ORDER BY le DESC LIMIT 40) j
        LEFT JOIN public.profiles p ON p.id = j.par
    ), '[]'::jsonb)
  );
END;
$function$;
