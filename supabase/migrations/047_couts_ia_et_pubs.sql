-- =============================================================================
-- 047 — Ce que coûte l'IA, ce que rapporte la pub (plan V2, S5)
-- =============================================================================
-- La condition posée à la monétisation : rester illimité avec pubs TANT QU'ON MESURE
-- que la pub rapporte plus que l'IA ne coûte. Jusqu'ici ce n'était pas mesurable : le
-- coût de chaque appel IA restait dans le téléphone (SharedPreferences, 1 000
-- événements), et une pub affichée ne laissait qu'un horodatage anti-spam.
--
-- 1. `ai_cost_events` : un appel IA = une ligne (fonctionnalité, modèle, jetons,
--    grounding, coût). Écrite par l'app, pour son propre compte.
-- 2. `ad_impressions` : une pub affichée = une ligne (format, emplacement).
-- 3. `app_config.ecpm_eur_estime` : revenu pour mille impressions, PAR ESTIMATION, à
--    remplacer par les chiffres réels de la console AdMob.
-- 4. `admin_economie(jours, inclure_tests)` : coût, revenu estimé et ratio, par
--    fonctionnalité, par plateforme et par personne. Console seulement.
--
-- `build_mode` distingue le Play Store (release) des essais sur émulateur (profile,
-- debug), où AdMob ne sert que des pubs de test : la console les exclut par défaut.
--
-- `event_id` est l'identifiant créé par l'appareil : renvoyer un lot après une coupure
-- ne compte rien deux fois (ON CONFLICT DO NOTHING).
--
-- ⚠️  OUVERTURE DE PHASE DE TEST : lecture par le rôle d'analyse, détail par personne
--     (voir PROD_MIGRATION.md). Écriture ouverte à tout compte, anonyme compris : en
--     production, journaliser plutôt depuis les fonctions edge.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Les appels IA
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_cost_events (
  id             BIGSERIAL PRIMARY KEY,
  event_id       UUID NOT NULL UNIQUE,
  user_id        UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  occurred_at    TIMESTAMPTZ NOT NULL,
  received_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  platform       TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'other')),
  app_version    TEXT,
  build_mode     TEXT NOT NULL CHECK (build_mode IN ('release', 'profile', 'debug')),
  feature        TEXT NOT NULL CHECK (length(feature) BETWEEN 1 AND 60),
  model          TEXT NOT NULL CHECK (length(model) BETWEEN 1 AND 80),
  prompt_tokens  INTEGER NOT NULL DEFAULT 0 CHECK (prompt_tokens BETWEEN 0 AND 5000000),
  output_tokens  INTEGER NOT NULL DEFAULT 0 CHECK (output_tokens BETWEEN 0 AND 5000000),
  grounded       BOOLEAN NOT NULL DEFAULT false,
  -- Un appel ne coûte jamais 5 $ : au-delà, la ligne est fausse, pas chère.
  cost_usd       NUMERIC(12, 6) NOT NULL CHECK (cost_usd >= 0 AND cost_usd < 5),
  cost_eur       NUMERIC(12, 6) NOT NULL CHECK (cost_eur >= 0 AND cost_eur < 5)
);
CREATE INDEX IF NOT EXISTS ai_cost_events_occurred_at ON public.ai_cost_events (occurred_at);
CREATE INDEX IF NOT EXISTS ai_cost_events_user ON public.ai_cost_events (user_id, occurred_at);

ALTER TABLE public.ai_cost_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ai_cost_events_insertion ON public.ai_cost_events;
CREATE POLICY ai_cost_events_insertion ON public.ai_cost_events
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
GRANT INSERT ON public.ai_cost_events TO authenticated;
GRANT USAGE ON SEQUENCE public.ai_cost_events_id_seq TO authenticated;
-- Aucune lecture pour l'app : la console passe par admin_economie.

-- -----------------------------------------------------------------------------
-- 2. Les pubs affichées
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ad_impressions (
  id           BIGSERIAL PRIMARY KEY,
  event_id     UUID NOT NULL UNIQUE,
  user_id      UUID NOT NULL DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  occurred_at  TIMESTAMPTZ NOT NULL,
  received_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  platform     TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'other')),
  app_version  TEXT,
  build_mode   TEXT NOT NULL CHECK (build_mode IN ('release', 'profile', 'debug')),
  ad_format    TEXT NOT NULL CHECK (ad_format IN ('rewarded', 'app_open', 'interstitial', 'banner')),
  placement    TEXT NOT NULL CHECK (length(placement) BETWEEN 1 AND 60)
);
CREATE INDEX IF NOT EXISTS ad_impressions_occurred_at ON public.ad_impressions (occurred_at);
CREATE INDEX IF NOT EXISTS ad_impressions_user ON public.ad_impressions (user_id, occurred_at);

ALTER TABLE public.ad_impressions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ad_impressions_insertion ON public.ad_impressions;
CREATE POLICY ad_impressions_insertion ON public.ad_impressions
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
GRANT INSERT ON public.ad_impressions TO authenticated;
GRANT USAGE ON SEQUENCE public.ad_impressions_id_seq TO authenticated;

-- -----------------------------------------------------------------------------
-- 3. Le revenu pour mille impressions — une ESTIMATION, à remplacer
-- -----------------------------------------------------------------------------
-- Ordres de grandeur d'une app française (septembre 2026). Les vrais chiffres sont dans
-- la console AdMob, rubrique « eCPM » par bloc d'annonces : les recopier ici.
INSERT INTO public.app_config (cle, valeur)
VALUES ('ecpm_eur_estime', '{"rewarded": 8.0, "app_open": 3.0, "interstitial": 5.0, "banner": 0.5}'::jsonb)
ON CONFLICT (cle) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 4. La lecture, pour la console
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_economie(p_jours INTEGER DEFAULT 30, p_inclure_tests BOOLEAN DEFAULT false)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
#variable_conflict use_column
DECLARE
  v_depuis TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
  v_ecpm   JSONB := coalesce(
    (SELECT c.valeur FROM public.app_config c WHERE c.cle = 'ecpm_eur_estime'),
    '{}'::jsonb);
  v_res    JSONB;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  WITH couts AS (
      SELECT e.user_id, e.platform, e.feature, e.grounded, e.cost_eur
        FROM public.ai_cost_events e
       WHERE e.occurred_at >= v_depuis
         AND (p_inclure_tests OR e.build_mode = 'release')
    ),
    pubs AS (
      SELECT i.user_id, i.platform, i.ad_format, i.placement,
             coalesce((v_ecpm ->> i.ad_format)::numeric, 0) / 1000.0 AS revenu_eur
        FROM public.ad_impressions i
       WHERE i.occurred_at >= v_depuis
         AND (p_inclure_tests OR i.build_mode = 'release')
    ),
    personnes AS (
      SELECT uid,
             sum(cout) AS cout_eur, sum(appels)::int AS appels,
             sum(revenu) AS revenu_eur, sum(impressions)::int AS impressions
        FROM (
          SELECT c.user_id AS uid, c.cost_eur AS cout, 1 AS appels, 0::numeric AS revenu, 0 AS impressions FROM couts c
          UNION ALL
          SELECT p.user_id, 0, 0, p.revenu_eur, 1 FROM pubs p
        ) t
       GROUP BY uid
    )
  SELECT jsonb_build_object(
    'jours', greatest(p_jours, 1),
    'inclut_tests', p_inclure_tests,
    'ecpm_eur_estime', v_ecpm,
    'cout_ia_eur', coalesce((SELECT sum(cost_eur) FROM couts), 0),
    'appels_ia', (SELECT count(*) FROM couts),
    'appels_groundes', (SELECT count(*) FROM couts WHERE grounded),
    'revenu_pub_eur_estime', coalesce((SELECT sum(revenu_eur) FROM pubs), 0),
    'impressions', (SELECT count(*) FROM pubs),
    'par_fonctionnalite', coalesce((
      SELECT jsonb_agg(jsonb_build_object('fonctionnalite', feature, 'appels', n, 'cout_eur', c) ORDER BY c DESC)
        FROM (SELECT feature, count(*) AS n, sum(cost_eur) AS c FROM couts GROUP BY feature) f), '[]'::jsonb),
    'par_emplacement', coalesce((
      SELECT jsonb_agg(jsonb_build_object('format', ad_format, 'emplacement', placement, 'impressions', n, 'revenu_eur', r) ORDER BY n DESC)
        FROM (SELECT ad_format, placement, count(*) AS n, sum(revenu_eur) AS r FROM pubs GROUP BY ad_format, placement) e), '[]'::jsonb),
    'par_plateforme', coalesce((
      SELECT jsonb_agg(jsonb_build_object('plateforme', plat, 'cout_eur', c, 'revenu_eur', r) ORDER BY plat)
        FROM (
          SELECT plat, sum(c) AS c, sum(r) AS r FROM (
            SELECT platform AS plat, cost_eur AS c, 0::numeric AS r FROM couts
            UNION ALL
            SELECT platform, 0, revenu_eur FROM pubs
          ) u GROUP BY plat
        ) pl), '[]'::jsonb),
    'par_personne', coalesce((
      SELECT jsonb_agg(jsonb_build_object(
               'user_id', pe.uid,
               'prenom', public.admin_nom(pe.uid, pr.display_name),
               'cout_eur', pe.cout_eur, 'appels', pe.appels,
               'revenu_eur', pe.revenu_eur, 'impressions', pe.impressions)
             ORDER BY pe.cout_eur DESC)
        FROM personnes pe LEFT JOIN public.profiles pr ON pr.id = pe.uid), '[]'::jsonb)
  ) INTO v_res;

  RETURN v_res;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_economie(INTEGER, BOOLEAN) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_economie(INTEGER, BOOLEAN) TO authenticated;

-- -----------------------------------------------------------------------------
-- 5. Le rôle d'analyse (phase de test) lit les deux tables
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chatmelier_feedback_ro') THEN
    GRANT SELECT ON public.ai_cost_events, public.ad_impressions TO chatmelier_feedback_ro;
    DROP POLICY IF EXISTS ai_cost_events_analyse ON public.ai_cost_events;
    CREATE POLICY ai_cost_events_analyse ON public.ai_cost_events
      FOR SELECT TO chatmelier_feedback_ro USING (true);
    DROP POLICY IF EXISTS ad_impressions_analyse ON public.ad_impressions;
    CREATE POLICY ad_impressions_analyse ON public.ad_impressions
      FOR SELECT TO chatmelier_feedback_ro USING (true);
  END IF;
END $$;

-- Vérification (après un scan de carte avec pub sur un téléphone en 71) :
--   SELECT feature, model, cost_eur, build_mode FROM public.ai_cost_events ORDER BY id DESC LIMIT 5;
--   SELECT ad_format, placement, build_mode FROM public.ad_impressions ORDER BY id DESC LIMIT 5;
--   SELECT public.admin_economie(30, true);   -- depuis la console (compte admin)
