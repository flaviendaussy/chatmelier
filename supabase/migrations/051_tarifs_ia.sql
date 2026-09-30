-- 051 — Le coût de l'IA recalculé par le serveur, à partir des jetons (V2.3 · A2, 30/09)
--
-- Jusqu'au 29/09, l'app comptait 0,10 $ / 0,40 $ par million de jetons pour tous les modèles
-- Flash : le tarif d'un ancien 2.0 Flash. `gemini-3.8-flash` coûte 0,75 $ / 3,75 $ (tarifs
-- officiels relevés le 30/09/2026), et ce prix double le 1er janvier 2027. Les coûts envoyés
-- par les téléphones (`ai_cost_events.cost_eur`) étaient donc environ neuf fois trop bas.
--
-- Les jetons, eux, sont justes. Cette migration :
--   1. pose une table de tarifs datée, qu'on met à jour sans toucher au code ;
--   2. recalcule le coût de chaque appel depuis ses jetons, avec la franchise mensuelle de la
--      recherche Google (5 000 requêtes offertes par mois pour les modèles 3.x) ;
--   3. fait lire ce coût recalculé par l'onglet « Économie » (`admin_economie`). Le coût
--      estimé par l'app reste visible à côté (`cout_ia_eur_app`), pour comparaison.
--
-- Idempotente. Ne supprime rien.

-- -----------------------------------------------------------------------------
-- 1. Les tarifs, datés
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tarifs_ia (
  id          SERIAL PRIMARY KEY,
  -- Motif LIKE sur le nom du modèle en minuscules. Le premier motif qui correspond (par
  -- priorité croissante) donne le tarif.
  motif       TEXT NOT NULL,
  priorite    INTEGER NOT NULL,
  entree_usd  NUMERIC NOT NULL,   -- dollars par million de jetons d'entrée
  sortie_usd  NUMERIC NOT NULL,   -- dollars par million de jetons de sortie, réflexion comprise
  du          DATE NOT NULL DEFAULT DATE '2000-01-01',
  au          DATE,               -- exclu ; NULL = sans fin
  note        TEXT,
  UNIQUE (motif, du)
);

ALTER TABLE public.tarifs_ia ENABLE ROW LEVEL SECURITY;
-- Aucune politique : seules les fonctions SECURITY DEFINER ci-dessous la lisent.

INSERT INTO public.tarifs_ia (motif, priorite, entree_usd, sortie_usd, du, au, note) VALUES
  ('%2.0-flash-lite%', 10, 0.10, 0.40, DATE '2000-01-01', NULL, 'Gemini 2.0 Flash-Lite'),
  ('%2.5-flash-lite%', 11, 0.10, 0.40, DATE '2000-01-01', NULL, 'Gemini 2.5 Flash-Lite'),
  ('%3.1-flash-lite%', 12, 0.25, 1.50, DATE '2000-01-01', NULL, 'Gemini 3.1 Flash-Lite'),
  ('%lite%',           19, 0.30, 2.50, DATE '2000-01-01', NULL, '3.5 Flash-Lite et flash-lite-latest'),
  ('%2.0-flash%',      20, 0.10, 0.40, DATE '2000-01-01', NULL, 'Gemini 2.0 Flash'),
  ('%2.5-flash%',      21, 0.30, 2.50, DATE '2000-01-01', NULL, 'Gemini 2.5 Flash'),
  ('%3.5-flash%',      22, 1.50, 9.00, DATE '2000-01-01', NULL, 'Gemini 3.5 Flash, le plus cher des Flash'),
  ('%flash%',          29, 0.75, 3.75, DATE '2000-01-01', DATE '2027-01-01', '3.6 à 3.8 Flash et flash-latest'),
  ('%flash%',          29, 1.50, 7.50, DATE '2027-01-01', NULL, '3.6 à 3.8 Flash, après doublement'),
  ('%pro%',            30, 1.25, 5.00, DATE '2000-01-01', NULL, 'Pro (non utilisé)')
ON CONFLICT (motif, du) DO NOTHING;

INSERT INTO public.app_config (cle, valeur)
VALUES ('recherche_ia', '{"prix_usd": 0.014, "franchise_mensuelle": 5000, "usd_eur": 0.92}'::jsonb)
ON CONFLICT (cle) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2. Le coût d'un appel, en dollars, hors recherche
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cout_ia_usd(p_modele TEXT, p_entree INTEGER, p_sortie INTEGER, p_le TIMESTAMPTZ)
RETURNS NUMERIC
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce(
    (SELECT (coalesce(p_entree, 0) * t.entree_usd + coalesce(p_sortie, 0) * t.sortie_usd) / 1000000.0
       FROM public.tarifs_ia t
      WHERE lower(coalesce(p_modele, '')) LIKE t.motif
        AND t.du <= p_le::date
        AND (t.au IS NULL OR p_le::date < t.au)
      ORDER BY t.priorite
      LIMIT 1),
    -- Modèle inconnu : compté au tarif Flash courant. Mieux vaut surestimer.
    (coalesce(p_entree, 0) * 0.75 + coalesce(p_sortie, 0) * 3.75) / 1000000.0
  );
$$;

REVOKE ALL ON FUNCTION public.cout_ia_usd(TEXT, INTEGER, INTEGER, TIMESTAMPTZ) FROM PUBLIC;

-- -----------------------------------------------------------------------------
-- 3. L'onglet « Économie » lit le coût recalculé
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
  v_rech   JSONB := coalesce(
    (SELECT c.valeur FROM public.app_config c WHERE c.cle = 'recherche_ia'),
    '{"prix_usd": 0.014, "franchise_mensuelle": 5000, "usd_eur": 0.92}'::jsonb);
  v_usd_eur NUMERIC := coalesce((v_rech ->> 'usd_eur')::numeric, 0.92);
  v_res    JSONB;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  WITH
    -- Rang de chaque appel groundé dans son mois, tous comptes confondus : la franchise est
    -- celle du projet, pas celle d'une personne.
    rangs AS (
      SELECT e.id,
             row_number() OVER (PARTITION BY date_trunc('month', e.occurred_at) ORDER BY e.occurred_at, e.id) AS rang
        FROM public.ai_cost_events e
       WHERE e.grounded
         AND e.occurred_at >= date_trunc('month', v_depuis)
    ),
    couts AS (
      SELECT e.user_id, e.platform, e.feature, e.grounded,
             e.cost_eur AS cout_app_eur,
             ( public.cout_ia_usd(e.model, e.prompt_tokens, e.output_tokens, e.occurred_at)
               + CASE WHEN e.grounded AND coalesce(r.rang, 0) > coalesce((v_rech ->> 'franchise_mensuelle')::int, 5000)
                      THEN coalesce((v_rech ->> 'prix_usd')::numeric, 0.014) ELSE 0 END
             ) * v_usd_eur AS cost_eur
        FROM public.ai_cost_events e
        LEFT JOIN rangs r ON r.id = e.id
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
    'cout_ia_eur_app', coalesce((SELECT sum(cout_app_eur) FROM couts), 0),
    'appels_ia', (SELECT count(*) FROM couts),
    'appels_groundes', (SELECT count(*) FROM couts WHERE grounded),
    'revenu_pub_eur_estime', coalesce((SELECT sum(revenu_eur) FROM pubs), 0),
    'impressions', (SELECT count(*) FROM pubs),
    'par_fonctionnalite', coalesce((
      SELECT jsonb_agg(jsonb_build_object('fonctionnalite', feature, 'appels', n, 'cout_eur', c, 'cout_moyen_eur', c / greatest(n, 1)) ORDER BY c DESC)
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

-- Vérification (attendu : 10 tarifs ; le scan du 29/09 recalculé ≈ 0,0078 $, soit ≈ 0,72 c€) :
SELECT
  (SELECT count(*) FROM public.tarifs_ia) AS tarifs,
  round(public.cout_ia_usd('gemini-3.8-flash', 1284, 663, TIMESTAMPTZ '2026-09-29')
      + public.cout_ia_usd('gemini-3.8-flash', 222, 1117, TIMESTAMPTZ '2026-09-29'), 5) AS scan_du_29_usd,
  round(public.cout_ia_usd('gemini-3.8-flash', 1000000, 0, TIMESTAMPTZ '2027-01-02'), 2) AS entree_flash_2027_usd;
