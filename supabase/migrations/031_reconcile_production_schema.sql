-- Migration 031: réconciliation du schéma de production
--
-- Établi le 2026-09-15 par comparaison entre `information_schema` en production et les
-- 30 migrations du dossier. Les 15 tables attendues existent et la RLS est active partout,
-- mais trois choses manquent — toutes silencieuses, donc jamais remontées.
--
-- Idempotente : peut être rejouée sans risque.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. tasting_log : cinq colonnes manquantes (migration 015 jamais appliquée)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Le code écrit `co_tasters`, `is_external`, `location_name`, `bottle_owner_id` et
-- `bottle_owner_name` à chaque dégustation. L'insertion échoue, l'application l'attrape
-- (tasting_questionnaire_sheet.dart:562 — « retrying with core schema ») et réinsère sans
-- ces champs. Résultat : **chaque dégustation perd silencieusement avec qui elle a été
-- faite, où, et si elle avait lieu hors de la cave.** Seul un debugPrint en garde trace.
--
-- Définitions reprises telles quelles de 015_friends_system_and_taste_sharing.sql.

ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS co_tasters JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS bottle_owner_id UUID REFERENCES public.profiles(id),
  ADD COLUMN IF NOT EXISTS bottle_owner_name TEXT,
  ADD COLUMN IF NOT EXISTS location_name TEXT,
  ADD COLUMN IF NOT EXISTS is_external BOOLEAN DEFAULT FALSE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. delete_user_account() : suppression de compte RGPD (migration 023 corrigée)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Appelée par auth_repository.dart:467. Absente de la production — et on sait pourquoi :
-- la version de 023 référençait `bar_pantries` (la table s'appelle `bar_pantry`) et
-- `user_overrides` (qui n'existe pas). La migration échouait donc à l'exécution et n'a
-- jamais été appliquée. Toute demande de suppression de compte échoue depuis.
--
-- Version corrigée : noms de tables réels, nettoyage étendu aux tables oubliées
-- (notifications, demandes d'accès, photos), et tolérance aux tables absentes.

CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  calling_user_id UUID;
BEGIN
  calling_user_id := auth.uid();
  IF calling_user_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié. Impossible de supprimer le compte.';
  END IF;

  DELETE FROM app_diagnostic_logs     WHERE user_id = calling_user_id;
  DELETE FROM chat_messages           WHERE user_id = calling_user_id;
  DELETE FROM tasting_log             WHERE user_id = calling_user_id;
  DELETE FROM friendships             WHERE user_id = calling_user_id OR friend_id = calling_user_id;
  DELETE FROM user_notifications      WHERE user_id = calling_user_id OR actor_id = calling_user_id;
  DELETE FROM cellar_access_requests  WHERE requester_id = calling_user_id OR owner_id = calling_user_id;
  DELETE FROM bar_pantry              WHERE user_id = calling_user_id;
  DELETE FROM cellar_invites          WHERE invited_by = calling_user_id OR invited_user_id = calling_user_id;

  -- Photos rattachées aux bouteilles de l'utilisateur, avant suppression des bouteilles.
  DELETE FROM bottle_photos WHERE bottle_id IN (
    SELECT id FROM bottles WHERE owner_id = calling_user_id OR added_by = calling_user_id
  );

  DELETE FROM bottles        WHERE owner_id = calling_user_id OR added_by = calling_user_id;
  DELETE FROM cellar_members WHERE user_id = calling_user_id;
  DELETE FROM cellars        WHERE owner_id = calling_user_id;
  DELETE FROM profiles       WHERE id = calling_user_id;

  -- Tolérance : `user_overrides` figurait dans 023 mais n'existe pas en production.
  IF to_regclass('public.user_overrides') IS NOT NULL THEN
    EXECUTE format('DELETE FROM public.user_overrides WHERE user_id = %L', calling_user_id);
  END IF;

  DELETE FROM auth.users WHERE id = calling_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.delete_user_account() FROM public, anon;
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Rétention des logs de diagnostic (migration 026 jamais appliquée)
-- ─────────────────────────────────────────────────────────────────────────────
--
-- RGPD article 5(1)(e), limitation de la conservation. 20 229 lignes s'étaient accumulées
-- sans purge. La restriction de lecture est traitée par la migration 030.

CREATE OR REPLACE FUNCTION public.cleanup_old_diagnostic_logs(days_to_keep INT DEFAULT 30)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_count INT;
BEGIN
  DELETE FROM public.app_diagnostic_logs
  WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
  GET DIAGNOSTICS deleted_count = ROW_COUNT;
  RETURN deleted_count;
END;
$$;

REVOKE ALL ON FUNCTION public.cleanup_old_diagnostic_logs(INT) FROM public, anon, authenticated;

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Vérifications à exécuter après application
-- ─────────────────────────────────────────────────────────────────────────────
--
--   -- Les 5 colonnes doivent apparaître :
--   SELECT column_name FROM information_schema.columns
--   WHERE table_name = 'tasting_log'
--     AND column_name IN ('co_tasters','is_external','location_name',
--                         'bottle_owner_id','bottle_owner_name');
--
--   -- Les deux fonctions doivent apparaître :
--   SELECT proname FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
--   WHERE n.nspname = 'public'
--     AND proname IN ('delete_user_account','cleanup_old_diagnostic_logs');
--
--   -- Purge initiale des logs de plus de 30 jours :
--   SELECT public.cleanup_old_diagnostic_logs(30);

-- ─────────────────────────────────────────────────────────────────────────────
-- RESTE À TRAITER, hors périmètre de cette migration
-- ─────────────────────────────────────────────────────────────────────────────
--
-- `vineyard_knowledge_cache` et `user_cocktails` sont utilisées par le code mais définies
-- dans AUCUNE migration. Leur absence est absorbée par des try/catch (PGRST205 récurrent
-- dans les logs pour la première). Elles demandent une décision de schéma avant d'être
-- créées — et `user_cocktails` part de toute façon avec le fork cocktails.
