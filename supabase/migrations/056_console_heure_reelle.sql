-- 056 — La console dit « à l'instant » seulement quand c'est vrai (30/09)
--
-- Flavien voyait Camille « à l'instant » alors que ses derniers journaux dataient de plus
-- d'une heure. Les journaux portent l'heure MURALE du téléphone (c'est celle que citent
-- les testeurs, « 19h07 ») rangée comme si c'était de l'UTC : un journal écrit à 20 h à
-- Paris (UTC+2) est rangé à « 20 h UTC », deux heures dans le futur. La console, qui
-- compare des instants, affichait donc « à l'instant » pendant deux heures, et plaçait
-- les journaux deux heures trop tard dans le fil d'une personne.
--
-- Chaque journal porte son décalage (`metadata.utc_offset_min`, depuis la 1.4) : la
-- console retrouve l'instant réel en le retranchant. La convention de la table ne change
-- pas (tool/feedback.sh continue de chercher « 19:07 » tel quel). Un journal sans
-- décalage (versions plus anciennes) garde son heure telle quelle.

CREATE OR REPLACE FUNCTION public.instant_du_journal(p_cree TIMESTAMPTZ, p_metadata JSONB)
RETURNS TIMESTAMPTZ
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT p_cree - make_interval(mins => CASE
    WHEN jsonb_typeof(p_metadata -> 'utc_offset_min') = 'number'
      THEN (p_metadata ->> 'utc_offset_min')::numeric::int
    ELSE 0
  END);
$$;

CREATE OR REPLACE FUNCTION public.admin_personnes(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (
  user_id            UUID,
  prenom             TEXT,
  anonyme            BOOLEAN,
  arrive_le          TIMESTAMPTZ,
  derniere_activite  TIMESTAMPTZ,
  plateforme         TEXT,
  version            TEXT,
  degustations       INTEGER,
  bouteilles         INTEGER,
  scans_etiquette    INTEGER,
  scans_carte        INTEGER,
  messages           INTEGER,
  tables             INTEGER,
  erreurs            INTEGER
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
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
      WHERE l.user_id = u.id AND l.created_at >= v_depuis AND l.level = 'error')
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
$$;

CREATE OR REPLACE FUNCTION public.admin_fil_personne(p_user_id UUID, p_jours INTEGER DEFAULT 30)
RETURNS TABLE (quand TIMESTAMPTZ, genre TEXT, titre TEXT, detail TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
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
               WHEN l.tag = 'MENU_SCAN' AND l.message LIKE 'Starting multi-page%'   THEN 'scan_carte'
               WHEN l.tag = 'SCAN_AI' AND l.message LIKE 'Starting label analysis%' THEN 'scan_etiquette'
               WHEN l.tag = 'MENU_CHAT' AND l.level = 'info'                         THEN 'chat_carte'
               WHEN l.tag = 'USAGE'                                                 THEN 'usage'
               WHEN l.level = 'error'                                               THEN 'erreur'
               ELSE 'alerte'
             END,
             CASE
               WHEN l.tag IN ('USER_FEEDBACK', 'MENU_CHAT') AND NOT v_nominatif THEN '(masqué)'
               ELSE left(regexp_replace(l.message, '\s+', ' ', 'g'), 200)
             END,
             l.tag || coalesce(' · ' || l.app_version, '')
        FROM public.app_diagnostic_logs l
       WHERE l.user_id = p_user_id AND l.created_at >= v_depuis
         AND (l.level IN ('error', 'warning')
              OR l.tag IN ('USER_FEEDBACK', 'MENU_CHAT', 'USAGE')
              OR (l.tag = 'MENU_SCAN' AND l.message LIKE 'Starting multi-page%')
              OR (l.tag = 'SCAN_AI' AND l.message LIKE 'Starting label analysis%'))
  ) fil
  ORDER BY 1 DESC
  LIMIT 500;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_erreurs(p_jours INTEGER DEFAULT 7)
RETURNS TABLE (niveau TEXT, tag TEXT, forme TEXT, n INTEGER, qui TEXT, derniere TIMESTAMPTZ, versions TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
#variable_conflict use_column
DECLARE
  v_depuis TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  RETURN QUERY
  WITH l AS (
    SELECT l.level, l.tag, public.instant_du_journal(l.created_at, l.metadata) AS created_at, l.app_version, l.user_id,
           -- Les identifiants et les nombres varient d'une occurrence à l'autre : on les
           -- efface pour regrouper les messages de même forme.
           left(regexp_replace(regexp_replace(l.message,
                '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', '#', 'g'),
                '[0-9]+', '#', 'g'), 160) AS forme
      FROM public.app_diagnostic_logs l
     WHERE l.created_at >= v_depuis AND l.level IN ('warning', 'error')
  )
  SELECT l.level, l.tag, l.forme, count(*)::int,
         string_agg(DISTINCT public.admin_nom(l.user_id, p.display_name), ', ')
           FILTER (WHERE l.user_id IS NOT NULL),
         max(l.created_at),
         string_agg(DISTINCT coalesce(l.app_version, '?'), ', ')
    FROM l LEFT JOIN public.profiles p ON p.id = l.user_id
   GROUP BY l.level, l.tag, l.forme
   ORDER BY (l.level = 'error') DESC, count(*) DESC
   LIMIT 150;
END;
$$;

-- Vérification :
--   SELECT public.instant_du_journal('2026-09-30 20:00+00', '{"utc_offset_min": 120}');
--   → 2026-09-30 18:00:00+00
--   Puis, dans la console : une personne active il y a une heure ne s'affiche plus
--   « à l'instant ».
