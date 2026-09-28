-- =============================================================================
-- 043 — Le rôle de dépouillement voit tous les journaux, et qui les a produits
-- =============================================================================
-- ⚠️  OUVERTURE DE PHASE DE TEST — À REFERMER AVANT LA PRODUCTION
--     (voir PROD_MIGRATION.md, section « Ouvertures de test à refermer »).
--
-- CONSTAT (28/09). Le rôle `chatmelier_feedback_ro` (migration 033) ne lisait que les
-- lignes `tag = 'USER_FEEDBACK'`, sans `user_id`. Aucun WARNING, aucune ERROR : les
-- incidents signalés par les testeurs — scans de carte ratés le 18/09 au soir, sommelier
-- injoignable le 23/09 à 19h07 — étaient impossibles à diagnostiquer.
--
-- Pendant la phase de test, les testeurs ont accepté d'être identifiables. Ce rôle voit
-- donc toutes les lignes de `app_diagnostic_logs`, avec `user_id`, et peut relier un
-- identifiant à un prénom via `profiles` (id, display_name, username — rien d'autre).
--
-- Ce qu'il ne voit toujours pas : les caves, les dégustations, les conversations, les
-- adresses e-mail. Et il reste en lecture seule.
-- =============================================================================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chatmelier_feedback_ro') THEN
    RAISE EXCEPTION 'Le rôle chatmelier_feedback_ro n''existe pas (voir migration 033).';
  END IF;
END $$;

-- 1. Toutes les colonnes des journaux.
GRANT SELECT (id, created_at, device_id, platform, app_version, tag, level, message,
              error_details, metadata, user_id)
  ON public.app_diagnostic_logs
  TO chatmelier_feedback_ro;

-- 2. Toutes les lignes, pas seulement les retours.
DROP POLICY IF EXISTS feedback_ro_select ON public.app_diagnostic_logs;
CREATE POLICY feedback_ro_select
  ON public.app_diagnostic_logs
  FOR SELECT
  TO chatmelier_feedback_ro
  USING (true);

-- 3. Qui est qui : trois colonnes de `profiles`, pas une de plus.
GRANT SELECT (id, display_name, username) ON public.profiles TO chatmelier_feedback_ro;

DROP POLICY IF EXISTS feedback_ro_profiles ON public.profiles;
CREATE POLICY feedback_ro_profiles
  ON public.profiles
  FOR SELECT
  TO chatmelier_feedback_ro
  USING (true);

-- Retour arrière (production) :
--   REVOKE SELECT (user_id, error_details, metadata) ON public.app_diagnostic_logs
--     FROM chatmelier_feedback_ro;
--   DROP POLICY feedback_ro_select ON public.app_diagnostic_logs;
--   CREATE POLICY feedback_ro_select ON public.app_diagnostic_logs
--     FOR SELECT TO chatmelier_feedback_ro USING (tag = 'USER_FEEDBACK');
--   REVOKE SELECT (id, display_name, username) ON public.profiles FROM chatmelier_feedback_ro;
--   DROP POLICY feedback_ro_profiles ON public.profiles;
--
-- Vérification (en tant que postgres, dans le SQL Editor) :
--   SET ROLE chatmelier_feedback_ro;
--   SELECT level, count(*) FROM public.app_diagnostic_logs
--    WHERE created_at > now() - interval '10 days' GROUP BY 1;   -- doit lister WARNING/ERROR
--   SELECT count(*) FROM public.tasting_log;                       -- doit échouer
--   RESET ROLE;
