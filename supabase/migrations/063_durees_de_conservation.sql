-- 063 — Les durées de conservation, écrites et appliquées (PROD_MIGRATION.md · RGPD, fait le 08/10)
--
-- La politique de confidentialité réécrite le 08/10 annonce des durées : cette migration
-- les applique, chaque nuit (pg_cron, actif depuis la 053).
--
--   - Journaux de diagnostic : 180 jours (ils servent à comprendre une panne récente).
--   - Retours « secouer pour commenter » : un an (le temps de les traiter ; la personne
--     peut les retirer elle-même avant, depuis « Mes retours envoyés »).
--   - Coûts d'IA et impressions publicitaires par compte : 400 jours (une année de
--     mesure économique, comparable d'un mois sur l'autre).
--
-- Ce qui a déjà sa durée : comptes anonymes non convertis (30 jours, 053), tables de
-- restaurant (4 h + 24 h, 038 et 053), codes de reprise (30 jours, 050), quotas (30 jours,
-- 053), cartes des lieux (180 jours, 061). Le reste vit autant que le compte.
--
-- Rejouable.

CREATE OR REPLACE FUNCTION public.purger_selon_les_durees()
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_journaux INTEGER := 0;
  v_retours  INTEGER := 0;
  v_couts    INTEGER := 0;
  v_pubs     INTEGER := 0;
BEGIN
  DELETE FROM public.app_diagnostic_logs
   WHERE tag <> 'USER_FEEDBACK' AND created_at < now() - INTERVAL '180 days';
  GET DIAGNOSTICS v_journaux = ROW_COUNT;

  DELETE FROM public.app_diagnostic_logs
   WHERE tag = 'USER_FEEDBACK' AND created_at < now() - INTERVAL '365 days';
  GET DIAGNOSTICS v_retours = ROW_COUNT;

  IF to_regclass('public.ai_cost_events') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.ai_cost_events WHERE occurred_at < now() - INTERVAL ''400 days''';
    GET DIAGNOSTICS v_couts = ROW_COUNT;
  END IF;
  IF to_regclass('public.ad_impressions') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.ad_impressions WHERE occurred_at < now() - INTERVAL ''400 days''';
    GET DIAGNOSTICS v_pubs = ROW_COUNT;
  END IF;

  RETURN jsonb_build_object('journaux', v_journaux, 'retours', v_retours, 'couts_ia', v_couts, 'pubs', v_pubs);
END;
$$;

REVOKE ALL ON FUNCTION public.purger_selon_les_durees() FROM PUBLIC;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    PERFORM cron.unschedule(j.jobid) FROM cron.job j WHERE j.jobname = 'chatmelier_durees';
    PERFORM cron.schedule('chatmelier_durees', '47 3 * * *', 'SELECT public.purger_selon_les_durees()');
  END IF;
END $$;

-- Retour arrière :
--   SELECT cron.unschedule('chatmelier_durees');
--   DROP FUNCTION public.purger_selon_les_durees();

-- Vérification (SQL Editor) :
--   SELECT jobname, schedule FROM cron.job WHERE jobname = 'chatmelier_durees';
--   SELECT public.purger_selon_les_durees();   → le nombre de lignes retirées par table
