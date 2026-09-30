-- 053 — La purge planifiée des comptes anonymes, et la mesure de la croissance (V2.3 · J1, J6)
--
-- 1. purge_comptes_anonymes (039) existait, mais rien ne la lançait : pg_cron n'était pas
--    installé (cron.job absent, vérifié le 30/09). Les comptes anonymes jamais convertis
--    s'accumulaient. Elle épargne désormais ceux qui ont un code de reprise encore valide :
--    sans cela, un code émis au 29e jour n'aurait servi à rien le lendemain.
-- 2. Un ménage quotidien : codes de reprise expirés ou servis, essais de reprise, quotas d'IA.
-- 3. Les trois travaux sont planifiés si pg_cron est disponible. Sinon : l'activer dans
--    Dashboard → Database → Extensions, puis rejouer cette migration (elle est idempotente).
-- 4. evenements_croissance : ce qui mène un invité web jusqu'à l'app, sans donnée
--    personnelle (type, source, table, plateforme, date). admin_croissance en fait le compte
--    et le rapporte au coût de l'IA sur le web.

-- -----------------------------------------------------------------------------
-- 1. La purge épargne les codes de reprise valides
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purge_comptes_anonymes(p_jours INTEGER DEFAULT 30)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_n INTEGER := 0;
  v_id UUID;
BEGIN
  FOR v_id IN
    SELECT u.id
    FROM auth.users u
    WHERE u.is_anonymous IS TRUE
      AND u.email IS NULL                       -- jamais converti
      AND u.created_at < now() - (p_jours || ' days')::interval
      AND coalesce(u.last_sign_in_at, u.created_at)
            < now() - (p_jours || ' days')::interval
      AND NOT EXISTS (                          -- un code de reprise encore valable
        SELECT 1 FROM public.codes_de_reprise c
         WHERE c.user_id = u.id AND c.utilise_le IS NULL AND c.expire_le > now())
  LOOP
    PERFORM public.purger_donnees_utilisateur(v_id);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.purge_comptes_anonymes(INTEGER) FROM PUBLIC;

-- -----------------------------------------------------------------------------
-- 2. Le ménage quotidien
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.menage_quotidien()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_codes INTEGER := 0;
  v_essais INTEGER := 0;
  v_quotas INTEGER := 0;
BEGIN
  DELETE FROM public.codes_de_reprise
   WHERE expire_le < now() - interval '1 day' OR utilise_le < now() - interval '1 day';
  GET DIAGNOSTICS v_codes = ROW_COUNT;
  DELETE FROM public.tentatives_de_reprise WHERE le < now() - interval '1 day';
  GET DIAGNOSTICS v_essais = ROW_COUNT;
  IF to_regclass('public.quotas_ia') IS NOT NULL THEN
    DELETE FROM public.quotas_ia WHERE jour < current_date - 30;
    GET DIAGNOSTICS v_quotas = ROW_COUNT;
  END IF;
  RETURN jsonb_build_object('codes', v_codes, 'essais', v_essais, 'quotas', v_quotas);
END;
$$;

REVOKE ALL ON FUNCTION public.menage_quotidien() FROM PUBLIC;

-- -----------------------------------------------------------------------------
-- 3. La planification
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron indisponible (%). L''activer dans Dashboard → Database → Extensions, puis rejouer 053.', SQLERRM;
  END;
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    EXECUTE $cron$
      SELECT cron.unschedule(jobid) FROM cron.job
       WHERE jobname IN ('chatmelier_purge_anonymes', 'chatmelier_purge_tables', 'chatmelier_menage')
    $cron$;
    EXECUTE $cron$ SELECT cron.schedule('chatmelier_purge_anonymes', '17 3 * * *', 'SELECT public.purge_comptes_anonymes(30)') $cron$;
    EXECUTE $cron$ SELECT cron.schedule('chatmelier_purge_tables', '7 * * * *', 'SELECT public.purge_expired_table_sessions()') $cron$;
    EXECUTE $cron$ SELECT cron.schedule('chatmelier_menage', '37 3 * * *', 'SELECT public.menage_quotidien()') $cron$;
  END IF;
END $$;

-- -----------------------------------------------------------------------------
-- 4. La croissance
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.evenements_croissance (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE SET NULL,
  type        TEXT NOT NULL CHECK (type IN (
                'invite_web_arrivee',    -- un invité ouvre une table sur le web
                'invite_web_note',       -- il note la bouteille bue en fin de soirée
                'clic_installer',        -- il touche « Installer l'app »
                'premiere_ouverture',    -- l'app installée s'ouvre pour la première fois
                'soiree_gardee')),       -- un invité garde sa soirée (e-mail ou code)
  source      TEXT CHECK (source IS NULL OR length(source) <= 40),
  table_code  TEXT CHECK (table_code IS NULL OR length(table_code) <= 12),
  plateforme  TEXT NOT NULL CHECK (plateforme IN ('android', 'ios', 'web', 'other')),
  app_version TEXT CHECK (app_version IS NULL OR length(app_version) <= 30),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS evenements_croissance_type ON public.evenements_croissance (type, occurred_at);

ALTER TABLE public.evenements_croissance ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS evenements_croissance_insertion ON public.evenements_croissance;
CREATE POLICY evenements_croissance_insertion ON public.evenements_croissance
  FOR INSERT TO authenticated WITH CHECK (user_id IS NULL OR user_id = auth.uid());
GRANT INSERT ON public.evenements_croissance TO authenticated;
GRANT USAGE ON SEQUENCE public.evenements_croissance_id_seq TO authenticated;
-- Aucune lecture pour l'app : la console passe par admin_croissance.

CREATE OR REPLACE FUNCTION public.admin_croissance(p_jours INTEGER DEFAULT 30)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_depuis TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
  v_cout_web NUMERIC := 0;
  v_res JSONB;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  IF to_regclass('public.ai_cost_events') IS NOT NULL AND to_regproc('public.cout_ia_usd') IS NOT NULL THEN
    SELECT coalesce(sum(public.cout_ia_usd(e.model, e.prompt_tokens, e.output_tokens, e.occurred_at)), 0) * 0.92
      INTO v_cout_web
      FROM public.ai_cost_events e
     WHERE e.platform = 'web' AND e.occurred_at >= v_depuis;
  END IF;
  SELECT jsonb_build_object(
    'jours', greatest(p_jours, 1),
    'par_type', coalesce((SELECT jsonb_object_agg(type, n) FROM (
        SELECT type, count(*) AS n FROM public.evenements_croissance
         WHERE occurred_at >= v_depuis GROUP BY type) t), '{}'::jsonb),
    'installations_par_source', coalesce((SELECT jsonb_object_agg(coalesce(source, 'inconnue'), n) FROM (
        SELECT source, count(*) AS n FROM public.evenements_croissance
         WHERE type = 'premiere_ouverture' AND occurred_at >= v_depuis GROUP BY source) s), '{}'::jsonb),
    'cout_ia_web_eur', v_cout_web,
    'cout_web_par_installation_eur', CASE
        WHEN (SELECT count(*) FROM public.evenements_croissance
               WHERE type = 'premiere_ouverture' AND occurred_at >= v_depuis) = 0 THEN NULL
        ELSE v_cout_web / (SELECT count(*) FROM public.evenements_croissance
                            WHERE type = 'premiere_ouverture' AND occurred_at >= v_depuis)
      END
  ) INTO v_res;
  RETURN v_res;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_croissance(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_croissance(INTEGER) TO authenticated;

-- Vérification (attendu : les trois travaux planifiés si pg_cron est actif ; la table de
-- croissance présente) :
SELECT
  (SELECT count(*) FROM pg_extension WHERE extname = 'pg_cron') AS pg_cron_actif,
  (SELECT count(*) FROM pg_class WHERE relname = 'evenements_croissance') AS table_croissance,
  (SELECT count(*) FROM pg_proc WHERE proname IN ('menage_quotidien', 'admin_croissance')) AS fonctions;
-- Puis, si pg_cron est actif : SELECT jobname, schedule FROM cron.job WHERE jobname LIKE 'chatmelier_%';
