-- =============================================================================
-- 044 — La console d'administration, personne par personne
-- =============================================================================
-- ⚠️  OUVERTURE DE PHASE DE TEST — À REFERMER AVANT LA PRODUCTION
--     (voir PROD_MIGRATION.md, section « Ouvertures de test à refermer »).
--
-- La 041 ne rendait que des agrégats, par principe. Pendant la phase de test, les
-- testeurs ont accepté d'être visibles : la console montre qui fait quoi, le fil de
-- chacun, ses questions au sommelier et les réponses, ses erreurs.
--
-- UN INTERRUPTEUR. `app_config.admin_detail_nominatif` (vrai pendant les tests). À faux :
-- les prénoms deviennent « Personne a1b2c3 », les conversations et les textes des retours
-- ne sortent plus. Le passer à faux est la première ligne du retour arrière.
--
-- Toujours : fonctions SECURITY DEFINER gardées par `est_admin()` (041), aucune clé dans
-- l'app. `#variable_conflict use_column` partout : les colonnes d'un RETURNS TABLE sont
-- des variables PL/pgSQL, et la 040 a montré ce que coûte une ambiguïté.
--
-- Colonnes vérifiées le 28/09 dans le catalogue de la base de production (pg_attribute),
-- et non d'après les modèles Dart — la leçon de la 042.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. La configuration de l'app, lisible par tous, écrite depuis le SQL Editor seulement
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_config (
  cle     TEXT PRIMARY KEY,
  valeur  JSONB NOT NULL,
  maj_le  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Lecture ouverte : la configuration pilote l'app avant même la connexion (version
-- minimale en phase de test, point 4.3). Aucune politique d'écriture : seul le SQL
-- Editor (postgres) la modifie.
DROP POLICY IF EXISTS app_config_lecture ON public.app_config;
CREATE POLICY app_config_lecture ON public.app_config FOR SELECT TO anon, authenticated USING (true);
GRANT SELECT ON public.app_config TO anon, authenticated;

INSERT INTO public.app_config (cle, valeur)
VALUES ('admin_detail_nominatif', 'true'::jsonb)
ON CONFLICT (cle) DO NOTHING;

-- Faux par défaut : une clé absente ou illisible opacifie, elle n'ouvre pas.
CREATE OR REPLACE FUNCTION public.admin_nominatif()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(
    (SELECT CASE WHEN jsonb_typeof(c.valeur) = 'boolean' THEN (c.valeur)::text::boolean END
       FROM public.app_config c WHERE c.cle = 'admin_detail_nominatif'),
    false);
$$;

-- Le nom affiché d'une personne, selon l'interrupteur.
CREATE OR REPLACE FUNCTION public.admin_nom(p_id UUID, p_prenom TEXT)
RETURNS TEXT
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT CASE
    WHEN public.admin_nominatif()
      THEN coalesce(nullif(trim(p_prenom), ''), 'Anonyme ' || left(p_id::text, 4))
    ELSE 'Personne ' || left(md5(p_id::text), 6)
  END;
$$;

-- -----------------------------------------------------------------------------
-- 1. Les personnes : qui, depuis quand, sur quoi, et combien
-- -----------------------------------------------------------------------------
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
      (SELECT max(l.created_at) FROM public.app_diagnostic_logs l WHERE l.user_id = u.id),
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
     ORDER BY l.created_at DESC
     LIMIT 1
  ) dernier ON true
  ORDER BY 5 DESC NULLS LAST;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. Le fil d'une personne : tout ce qu'elle a fait, du plus récent au plus ancien
-- -----------------------------------------------------------------------------
-- Les heures des journaux sont celles de l'appareil ; celles des tables, du serveur (UTC).
-- Avec l'interrupteur à faux, les textes (questions, retours) sont masqués.
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
      SELECT l.created_at,
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

-- -----------------------------------------------------------------------------
-- 3. Les conversations avec le sommelier : questions ET réponses
-- -----------------------------------------------------------------------------
-- Les réponses du sommelier sont rangées par cave : on rend les échanges des caves où
-- la personne a posé au moins une question.
CREATE OR REPLACE FUNCTION public.admin_conversations(p_user_id UUID, p_jours INTEGER DEFAULT 90)
RETURNS TABLE (quand TIMESTAMPTZ, role TEXT, contenu TEXT, cave TEXT)
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
  IF NOT public.admin_nominatif() THEN
    RAISE EXCEPTION 'detail_masque' USING HINT = 'Les conversations ne sortent qu''en mode nominatif.';
  END IF;

  RETURN QUERY
  SELECT m.created_at, m.role, m.content, coalesce(c.nickname, c.name)
    FROM public.chat_messages m
    LEFT JOIN public.cellars c ON c.id = m.cellar_id
   WHERE m.created_at >= v_depuis
     AND m.cellar_id IN (SELECT DISTINCT q.cellar_id FROM public.chat_messages q
                          WHERE q.user_id = p_user_id AND q.role = 'user')
     AND (m.user_id = p_user_id OR m.role = 'assistant')
   ORDER BY m.created_at DESC
   LIMIT 300;
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. Le journal des erreurs : WARNING et ERROR, groupés, avec qui et quand
-- -----------------------------------------------------------------------------
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
    SELECT l.level, l.tag, l.created_at, l.app_version, l.user_id,
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

-- -----------------------------------------------------------------------------
-- 5. Qui utilise quoi : une ligne par jour, par fonctionnalité et par personne
-- -----------------------------------------------------------------------------
-- La console agrège elle-même (totaux, courbes, noms). Les fonctionnalités sans trace
-- en base (matchmaker, flights, accords mets-vins…) passent par le tag `USAGE` des
-- journaux, ajouté le 28/09.
CREATE OR REPLACE FUNCTION public.admin_usages(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (jour DATE, fonctionnalite TEXT, user_id UUID, prenom TEXT, usages INTEGER)
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
  WITH gestes AS (
      -- Heures serveur (UTC) ramenées au jour de Paris ; heures des journaux : celles de
      -- l'appareil, déjà locales.
      SELECT (t.consumed_at AT TIME ZONE 'Europe/Paris')::date AS j,
             CASE WHEN t.is_external THEN 'Dégustation hors cave' ELSE 'Dégustation' END AS f,
             t.user_id AS uid
        FROM public.tasting_log t WHERE t.consumed_at >= v_depuis
    UNION ALL
      SELECT (b.created_at AT TIME ZONE 'Europe/Paris')::date, 'Bouteille ajoutée', b.added_by
        FROM public.bottles b WHERE b.created_at >= v_depuis
    UNION ALL
      SELECT (b.gifted_at AT TIME ZONE 'Europe/Paris')::date, 'Bouteille offerte', b.added_by
        FROM public.bottles b WHERE b.gifted_at >= v_depuis
    UNION ALL
      SELECT (m.created_at AT TIME ZONE 'Europe/Paris')::date, 'Sommelier de la cave', m.user_id
        FROM public.chat_messages m WHERE m.role = 'user' AND m.created_at >= v_depuis
    UNION ALL
      SELECT (s.created_at AT TIME ZONE 'Europe/Paris')::date, 'Table ouverte', s.host_user_id
        FROM public.table_sessions s WHERE s.created_at >= v_depuis
    UNION ALL
      SELECT (g.created_at AT TIME ZONE 'Europe/Paris')::date, 'Table rejointe', g.user_id
        FROM public.table_session_guests g
        JOIN public.table_sessions s ON s.id = g.session_id
       WHERE g.created_at >= v_depuis AND g.user_id IS DISTINCT FROM s.host_user_id
    UNION ALL
      SELECT l.created_at::date,
             CASE
               WHEN l.tag = 'SCAN_AI'       THEN 'Scan d''étiquette'
               WHEN l.tag = 'MENU_SCAN'     THEN 'Scan de carte'
               WHEN l.tag = 'MENU_CHAT'     THEN 'Sommelier de la carte'
               WHEN l.tag = 'USER_FEEDBACK' THEN 'Retour envoyé'
               WHEN l.tag = 'USAGE'         THEN initcap(replace(l.message, '_', ' '))
             END,
             l.user_id
        FROM public.app_diagnostic_logs l
       WHERE l.created_at >= v_depuis
         AND ((l.tag = 'SCAN_AI' AND l.message LIKE 'Starting label analysis%')
           OR (l.tag = 'MENU_SCAN' AND l.message LIKE 'Starting multi-page%')
           OR (l.tag = 'MENU_CHAT' AND l.level = 'info' AND l.message LIKE 'menu-chat answered%')
           OR l.tag = 'USER_FEEDBACK'
           OR l.tag = 'USAGE')
  )
  SELECT g.j, g.f, g.uid, public.admin_nom(g.uid, p.display_name), count(*)::int
    FROM gestes g LEFT JOIN public.profiles p ON p.id = g.uid
   WHERE g.uid IS NOT NULL AND g.f IS NOT NULL
   GROUP BY g.j, g.f, g.uid, p.display_name
   ORDER BY g.j DESC, 5 DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_nominatif() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_nom(UUID, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_personnes(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_fil_personne(UUID, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_conversations(UUID, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_erreurs(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_usages(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_nominatif() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_personnes(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_fil_personne(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_conversations(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_erreurs(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_usages(INTEGER) TO authenticated;

-- Retour arrière (production) :
--   UPDATE public.app_config SET valeur = 'false'::jsonb, maj_le = now()
--    WHERE cle = 'admin_detail_nominatif';          -- opacifie tout, immédiatement
--   DROP FUNCTION public.admin_conversations(UUID, INTEGER);
--   DROP FUNCTION public.admin_fil_personne(UUID, INTEGER);
--   DROP FUNCTION public.admin_personnes(INTEGER);
--   DROP FUNCTION public.admin_usages(INTEGER);   -- ou la garder, sans prénoms
--
-- Vérification (SQL Editor, en tant que postgres — pas de JWT, donc pas d'admin) :
--   SELECT public.admin_nominatif();                -- true pendant la phase de test
--   SELECT * FROM public.admin_personnes(30);       -- doit lever reserve_admin
--   -- Depuis la console de l'app, connecté avec le compte administrateur : les cinq
--   -- onglets doivent se remplir.
