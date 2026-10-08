-- =============================================================================
-- 065 — Le revenu réel de chaque pub (livraison 79 ; remplace J7, les eCPM saisis à la main)
-- =============================================================================
--
-- Jusqu'ici, le revenu publicitaire de la console était une estimation : impressions ×
-- eCPM saisi à la main (`app_config.ecpm_eur_estime`). Le plugin AdMob rend, pour chaque
-- impression, ce que Google l'a payée (`onPaidEvent` : un montant en micro-unités, la
-- devise du compte AdMob, la précision du montant). Il faut pour cela activer, dans AdMob :
-- Paramètres → Compte → Contrôles du compte → « Revenus publicitaires au niveau des
-- impressions ».
--
-- 1. `ad_revenus` : une ligne par paiement, rattachée à son impression
--    (`ad_impressions.event_id`). Écriture par la personne elle-même, relecture de ses
--    propres lignes (054 : sans elle, l'envoi par lots n'aboutissait pas), 400 jours comme
--    les impressions (063).
-- 2. `admin_revenus_pub(jours, tests)` : revenu réel, eCPM réel par format face à l'eCPM
--    estimé, jour par jour, précision des montants. Console seulement (`est_admin()`).
--    Conversion en euros : 1 pour l'euro ; pour le dollar, `app_config.recherche_ia.usd_eur`
--    (le taux déjà utilisé pour les coûts d'IA) ; pour toute autre devise, le taux de
--    `app_config.taux_de_change` s'il existe — sinon le montant reste dans sa devise, montré
--    à part, et n'entre dans aucun total en euros (rien n'est converti au jugé).
--
-- Comme ad_impressions (047), l'écriture est ouverte à tout compte : ces lignes ne
-- contiennent que des montants publicitaires, rien de personnel au-delà du compte.
--
-- Rejouable.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.ad_revenus (
  id             BIGSERIAL PRIMARY KEY,
  event_id       UUID NOT NULL UNIQUE,
  impression_id  UUID,
  user_id        UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  occurred_at    TIMESTAMPTZ NOT NULL,
  received_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  platform       TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'other')),
  app_version    TEXT,
  build_mode     TEXT NOT NULL CHECK (build_mode IN ('release', 'profile', 'debug')),
  ad_format      TEXT NOT NULL CHECK (ad_format IN ('rewarded', 'app_open', 'interstitial', 'banner')),
  placement      TEXT NOT NULL CHECK (length(placement) BETWEEN 1 AND 60),
  -- Une impression rapporte des fractions de centime : au-delà de 100 unités, c'est une erreur.
  valeur_micros  BIGINT NOT NULL CHECK (valeur_micros >= 0 AND valeur_micros < 100000000),
  devise         TEXT NOT NULL CHECK (devise ~ '^[A-Z]{3}$'),
  precision_type TEXT NOT NULL CHECK (precision_type IN ('unknown', 'estimated', 'publisher_provided', 'precise'))
);
CREATE INDEX IF NOT EXISTS ad_revenus_occurred_at ON public.ad_revenus (occurred_at);
CREATE INDEX IF NOT EXISTS ad_revenus_user ON public.ad_revenus (user_id, occurred_at);

ALTER TABLE public.ad_revenus ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ad_revenus_insertion ON public.ad_revenus;
CREATE POLICY ad_revenus_insertion ON public.ad_revenus
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS ad_revenus_relecture ON public.ad_revenus;
CREATE POLICY ad_revenus_relecture ON public.ad_revenus
  FOR SELECT TO authenticated USING (user_id = auth.uid());
GRANT SELECT, INSERT ON public.ad_revenus TO authenticated;
GRANT USAGE ON SEQUENCE public.ad_revenus_id_seq TO authenticated;

-- -----------------------------------------------------------------------------
-- La console
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_revenus_pub(p_jours INTEGER DEFAULT 30, p_inclure_tests BOOLEAN DEFAULT false)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_depuis  TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
  v_ecpm    JSONB := coalesce((SELECT c.valeur FROM public.app_config c WHERE c.cle = 'ecpm_eur_estime'), '{}'::jsonb);
  v_taux    JSONB := coalesce((SELECT c.valeur FROM public.app_config c WHERE c.cle = 'taux_de_change'), '{}'::jsonb);
  v_usd_eur NUMERIC := coalesce(
    ((SELECT c.valeur FROM public.app_config c WHERE c.cle = 'recherche_ia') ->> 'usd_eur')::numeric, 0.92);
  v_res     JSONB;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  WITH
    paiements AS (
      SELECT r.ad_format, r.placement, r.devise, r.precision_type,
             (r.occurred_at AT TIME ZONE 'Europe/Paris')::date AS jour,
             r.valeur_micros / 1000000.0 AS valeur,
             CASE r.devise
               WHEN 'EUR' THEN 1::numeric
               WHEN 'USD' THEN coalesce((v_taux ->> 'USD')::numeric, v_usd_eur)
               ELSE (v_taux ->> r.devise)::numeric
             END AS taux
        FROM public.ad_revenus r
       WHERE r.occurred_at >= v_depuis
         AND (p_inclure_tests OR r.build_mode = 'release')
    ),
    impressions AS (
      SELECT i.ad_format, count(*) AS n
        FROM public.ad_impressions i
       WHERE i.occurred_at >= v_depuis
         AND (p_inclure_tests OR i.build_mode = 'release')
       GROUP BY i.ad_format
    )
  SELECT jsonb_build_object(
    'jours', greatest(p_jours, 1),
    'inclut_tests', p_inclure_tests,
    'paiements', (SELECT count(*) FROM paiements),
    'impressions', coalesce((SELECT sum(n) FROM impressions), 0),
    'revenu_eur', (SELECT sum(valeur * taux) FROM paiements WHERE taux IS NOT NULL),
    'par_devise', coalesce((
      SELECT jsonb_agg(jsonb_build_object('devise', devise, 'total', t, 'paiements', n, 'converti', c) ORDER BY devise)
        FROM (SELECT devise, sum(valeur) AS t, count(*) AS n, bool_and(taux IS NOT NULL) AS c
                FROM paiements GROUP BY devise) d), '[]'::jsonb),
    'par_format', coalesce((
      SELECT jsonb_agg(jsonb_build_object(
               'format', f.ad_format,
               'impressions', coalesce(i.n, 0),
               'paiements', f.n,
               'revenu_eur', f.r,
               'ecpm_reel_eur', CASE WHEN f.n_converti > 0 THEN f.r / f.n_converti * 1000 END,
               'ecpm_estime_eur', (v_ecpm ->> f.ad_format)::numeric)
             ORDER BY f.ad_format)
        FROM (SELECT ad_format, count(*) AS n, count(*) FILTER (WHERE taux IS NOT NULL) AS n_converti,
                     sum(valeur * taux) AS r
                FROM paiements GROUP BY ad_format) f
        LEFT JOIN impressions i ON i.ad_format = f.ad_format), '[]'::jsonb),
    'par_jour', coalesce((
      SELECT jsonb_agg(jsonb_build_object('jour', jour, 'revenu_eur', r, 'paiements', n) ORDER BY jour)
        FROM (SELECT jour, sum(valeur * taux) AS r, count(*) AS n FROM paiements GROUP BY jour) j), '[]'::jsonb),
    'precision', coalesce((
      SELECT jsonb_object_agg(precision_type, n)
        FROM (SELECT precision_type, count(*) AS n FROM paiements GROUP BY precision_type) p), '{}'::jsonb)
  ) INTO v_res;

  RETURN v_res;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_revenus_pub(INTEGER, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_revenus_pub(INTEGER, BOOLEAN) TO authenticated;

-- -----------------------------------------------------------------------------
-- Les durées (063) : les paiements vivent autant que les impressions, 400 jours.
-- -----------------------------------------------------------------------------
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
  v_revenus  INTEGER := 0;
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
  IF to_regclass('public.ad_revenus') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.ad_revenus WHERE occurred_at < now() - INTERVAL ''400 days''';
    GET DIAGNOSTICS v_revenus = ROW_COUNT;
  END IF;

  RETURN jsonb_build_object('journaux', v_journaux, 'retours', v_retours, 'couts_ia', v_couts, 'pubs', v_pubs,
                            'revenus_pub', v_revenus);
END;
$$;

REVOKE ALL ON FUNCTION public.purger_selon_les_durees() FROM PUBLIC;

-- Retour arrière :
--   DROP FUNCTION public.admin_revenus_pub(INTEGER, BOOLEAN);
--   DROP TABLE public.ad_revenus;
--   (puis rejouer 063 pour la purge sans ad_revenus)

-- Vérification (SQL Editor) :
--   SELECT policyname, cmd FROM pg_policies WHERE tablename = 'ad_revenus' ORDER BY 1;
--     → ad_revenus_insertion INSERT, ad_revenus_relecture SELECT
--   SELECT public.admin_revenus_pub(30, true);   (depuis la console : un compte administrateur)
--   Une semaine après la 79 : SELECT count(*), sum(valeur_micros) / 1e6, devise FROM public.ad_revenus GROUP BY devise;
