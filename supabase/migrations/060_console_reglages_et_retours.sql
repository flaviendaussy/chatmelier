-- 060 — La console : réglages, retours suivis, courbes et détails (V2.4 · R9)
--
-- Demandé par Flavien le 07/10 : plus de détails, de graphes et de contrôles dans la
-- console, réservée à son compte administrateur (est_admin).
--
--   1. Les réglages d'app_config qu'il changeait au SQL Editor (modèles d'IA, recherche au
--      scan d'étiquette, session obligatoire, version minimale, eCPM, quotas, mode
--      opacifié) se règlent depuis la console. Chaque changement est vérifié (forme et
--      bornes) et journalisé : qui, quand, avant, après.
--   2. Les retours « secouer pour commenter » ont un statut (à traiter, en cours, résolu,
--      écarté) et une note. Le rôle en lecture seule du dépouillement lit les statuts.
--   3. L'économie jour par jour et par modèle, les erreurs jour par jour, les occurrences
--      d'une erreur, les versions installées.
--
-- Rejouable. Aucune donnée existante n'est modifiée.

-- -----------------------------------------------------------------------------
-- 1. Les réglages
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.journal_des_reglages (
  id     BIGSERIAL PRIMARY KEY,
  cle    TEXT NOT NULL,
  avant  JSONB,
  apres  JSONB NOT NULL,
  par    UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  le     TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.journal_des_reglages ENABLE ROW LEVEL SECURITY;
-- Aucune politique : le journal ne se lit que par admin_reglages().
REVOKE ALL ON public.journal_des_reglages FROM anon, authenticated;

-- Ce qu'un réglage doit être pour être accepté : nul si la valeur convient, sinon la raison.
CREATE OR REPLACE FUNCTION public.reglage_invalide(p_cle TEXT, p_valeur JSONB)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  IF p_valeur IS NULL THEN
    RETURN 'valeur absente';
  END IF;
  CASE p_cle
    WHEN 'scan_etiquette_recherche', 'ia_session_obligatoire', 'admin_detail_nominatif' THEN
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
    WHEN 'version_minimale_test' THEN
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
    ELSE
      RETURN 'réglage non modifiable depuis la console';
  END CASE;
  RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_reglages()
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  RETURN jsonb_build_object(
    'reglages', coalesce((
      SELECT jsonb_object_agg(c.cle, jsonb_build_object('valeur', c.valeur, 'maj_le', c.maj_le))
        FROM public.app_config c
       WHERE c.cle IN ('modeles_ia', 'scan_etiquette_recherche', 'ia_session_obligatoire',
                       'admin_detail_nominatif', 'version_minimale_test', 'ecpm_eur_estime', 'quotas_ia')
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
$$;

CREATE OR REPLACE FUNCTION public.admin_regler(p_cle TEXT, p_valeur JSONB)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_raison TEXT;
  v_avant  JSONB;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  v_raison := public.reglage_invalide(p_cle, p_valeur);
  IF v_raison IS NOT NULL THEN
    RAISE EXCEPTION 'reglage_invalide : %', v_raison;
  END IF;
  SELECT c.valeur INTO v_avant FROM public.app_config c WHERE c.cle = p_cle;
  IF v_avant IS NOT DISTINCT FROM p_valeur THEN
    RETURN p_valeur;
  END IF;
  INSERT INTO public.app_config (cle, valeur, maj_le) VALUES (p_cle, p_valeur, now())
  ON CONFLICT (cle) DO UPDATE SET valeur = EXCLUDED.valeur, maj_le = now();
  INSERT INTO public.journal_des_reglages (cle, avant, apres, par) VALUES (p_cle, v_avant, p_valeur, auth.uid());
  RETURN p_valeur;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. Les retours suivis
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.retours_suivis (
  log_id   UUID PRIMARY KEY REFERENCES public.app_diagnostic_logs(id) ON DELETE CASCADE,
  statut   TEXT NOT NULL DEFAULT 'a_traiter'
             CHECK (statut IN ('a_traiter', 'en_cours', 'resolu', 'ecarte')),
  note     TEXT CHECK (note IS NULL OR char_length(note) <= 2000),
  maj_le   TIMESTAMPTZ NOT NULL DEFAULT now(),
  maj_par  UUID REFERENCES auth.users(id) ON DELETE SET NULL
);
ALTER TABLE public.retours_suivis ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.retours_suivis FROM anon, authenticated;

-- Le dépouillement (tool/feedback.sh, rôle en lecture seule de la 033) lit les statuts :
-- un rapport des retours « non résolus » se fait sans demander lesquels le sont.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chatmelier_feedback_ro') THEN
    GRANT SELECT ON public.retours_suivis TO chatmelier_feedback_ro;
    DROP POLICY IF EXISTS retours_suivis_lecture_ro ON public.retours_suivis;
    CREATE POLICY retours_suivis_lecture_ro ON public.retours_suivis
      FOR SELECT TO chatmelier_feedback_ro USING (true);
  END IF;
END $$;

-- Les retours de la période, du plus récent au plus ancien, découpés comme les écrit l'app :
-- « Commentaire: … | Capture: … | Annotations: … » (feedback_annotation_sheet).
CREATE OR REPLACE FUNCTION public.admin_retours(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (id UUID, quand TIMESTAMPTZ, qui TEXT, plateforme TEXT, version TEXT,
               commentaire TEXT, capture TEXT, annotations BOOLEAN,
               statut TEXT, note TEXT, maj_le TIMESTAMPTZ)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
#variable_conflict use_column
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  RETURN QUERY
  SELECT l.id,
         public.instant_du_journal(l.created_at, l.metadata),
         public.admin_nom(l.user_id, p.display_name),
         l.platform,
         l.app_version,
         coalesce(substring(l.message FROM 'Commentaire: (.*?) \| Capture:'), l.message),
         nullif(substring(l.message FROM '\| Capture: ([^ |]+)'), 'aucune'),
         coalesce(substring(l.message FROM 'Annotations: ([a-z]+)'), 'non') = 'oui',
         coalesce(s.statut, 'a_traiter'),
         s.note,
         s.maj_le
    FROM public.app_diagnostic_logs l
    LEFT JOIN public.profiles p ON p.id = l.user_id
    LEFT JOIN public.retours_suivis s ON s.log_id = l.id
   WHERE l.tag = 'USER_FEEDBACK'
     AND l.created_at >= now() - (greatest(p_jours, 1) || ' days')::interval
   ORDER BY l.created_at DESC
   LIMIT 500;
END;
$$;

-- Le statut d'un retour, et sa note (nulle : la note reste ; vide : elle s'efface).
CREATE OR REPLACE FUNCTION public.admin_suivre_retour(p_id UUID, p_statut TEXT, p_note TEXT DEFAULT NULL)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  IF p_statut NOT IN ('a_traiter', 'en_cours', 'resolu', 'ecarte') THEN
    RAISE EXCEPTION 'statut_inconnu : %', p_statut;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.app_diagnostic_logs l WHERE l.id = p_id AND l.tag = 'USER_FEEDBACK') THEN
    RAISE EXCEPTION 'retour_inconnu';
  END IF;
  INSERT INTO public.retours_suivis AS s (log_id, statut, note, maj_le, maj_par)
  VALUES (p_id, p_statut, nullif(btrim(p_note), ''), now(), auth.uid())
  ON CONFLICT (log_id) DO UPDATE
    SET statut  = EXCLUDED.statut,
        note    = CASE WHEN p_note IS NULL THEN s.note ELSE EXCLUDED.note END,
        maj_le  = now(),
        maj_par = auth.uid();
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. L'économie, jour par jour et par modèle
-- -----------------------------------------------------------------------------
-- Même calcul que admin_economie (051) : le coût recalculé depuis les jetons et les tarifs
-- datés, la recherche au-delà de la franchise mensuelle du projet.
CREATE OR REPLACE FUNCTION public.admin_economie_detail(p_jours INTEGER DEFAULT 30, p_inclure_tests BOOLEAN DEFAULT false)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_depuis  TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
  v_ecpm    JSONB := coalesce((SELECT c.valeur FROM public.app_config c WHERE c.cle = 'ecpm_eur_estime'), '{}'::jsonb);
  v_rech    JSONB := coalesce((SELECT c.valeur FROM public.app_config c WHERE c.cle = 'recherche_ia'),
                              '{"prix_usd": 0.014, "franchise_mensuelle": 5000, "usd_eur": 0.92}'::jsonb);
  v_usd_eur NUMERIC := coalesce((v_rech ->> 'usd_eur')::numeric, 0.92);
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  RETURN (
    WITH
      rangs AS (
        SELECT e.id,
               row_number() OVER (PARTITION BY date_trunc('month', e.occurred_at) ORDER BY e.occurred_at, e.id) AS rang
          FROM public.ai_cost_events e
         WHERE e.grounded AND e.occurred_at >= date_trunc('month', v_depuis)
      ),
      couts AS (
        SELECT e.occurred_at::date AS jour, e.feature, e.model, e.prompt_tokens, e.output_tokens,
               ( public.cout_ia_usd(e.model, e.prompt_tokens, e.output_tokens, e.occurred_at)
                 + CASE WHEN e.grounded AND coalesce(r.rang, 0) > coalesce((v_rech ->> 'franchise_mensuelle')::int, 5000)
                        THEN coalesce((v_rech ->> 'prix_usd')::numeric, 0.014) ELSE 0 END
               ) * v_usd_eur AS cout_eur
          FROM public.ai_cost_events e
          LEFT JOIN rangs r ON r.id = e.id
         WHERE e.occurred_at >= v_depuis
           AND (p_inclure_tests OR e.build_mode = 'release')
      ),
      pubs AS (
        SELECT i.occurred_at::date AS jour,
               coalesce((v_ecpm ->> i.ad_format)::numeric, 0) / 1000.0 AS revenu_eur
          FROM public.ad_impressions i
         WHERE i.occurred_at >= v_depuis
           AND (p_inclure_tests OR i.build_mode = 'release')
      ),
      jours AS (
        SELECT d::date AS jour FROM generate_series(v_depuis::date, now()::date, interval '1 day') d
      )
    SELECT jsonb_build_object(
      'par_jour', (
        SELECT jsonb_agg(jsonb_build_object(
                 'jour', j.jour,
                 'cout_eur', coalesce((SELECT sum(c.cout_eur) FROM couts c WHERE c.jour = j.jour), 0),
                 'appels', (SELECT count(*) FROM couts c WHERE c.jour = j.jour),
                 'revenu_eur', coalesce((SELECT sum(p.revenu_eur) FROM pubs p WHERE p.jour = j.jour), 0),
                 'impressions', (SELECT count(*) FROM pubs p WHERE p.jour = j.jour),
                 -- Une page de carte, une étiquette (lecture et description) : le coût moyen
                 -- du jour, à comparer à l'objectif de 0,8 c€ par page.
                 'carte_moyen_eur', (SELECT avg(c.cout_eur) FROM couts c WHERE c.jour = j.jour AND c.feature = 'menu_scan_vision'),
                 'etiquette_moyen_eur', (
                   SELECT sum(c.cout_eur) / nullif(count(*) FILTER (WHERE c.feature = 'scan_vision'), 0)
                     FROM couts c WHERE c.jour = j.jour AND c.feature IN ('scan_vision', 'scan_enrichment'))
               ) ORDER BY j.jour)
          FROM jours j),
      'par_modele', coalesce((
        SELECT jsonb_agg(jsonb_build_object(
                 'modele', m.model, 'appels', m.n, 'cout_eur', m.c, 'cout_moyen_eur', m.c / greatest(m.n, 1),
                 'entree_moyenne', m.entree, 'sortie_moyenne', m.sortie) ORDER BY m.c DESC)
          FROM (SELECT c.model, count(*) AS n, sum(c.cout_eur) AS c,
                       round(avg(c.prompt_tokens)) AS entree, round(avg(c.output_tokens)) AS sortie
                  FROM couts c GROUP BY c.model) m), '[]'::jsonb),
      'recherches_du_mois', (SELECT count(*) FROM public.ai_cost_events e
                              WHERE e.grounded AND e.occurred_at >= date_trunc('month', now())),
      'franchise_mensuelle', coalesce((v_rech ->> 'franchise_mensuelle')::int, 5000)
    )
  );
END;
$$;

-- -----------------------------------------------------------------------------
-- 4. Les erreurs, jour par jour, et les occurrences d'une erreur
-- -----------------------------------------------------------------------------
-- La forme d'un message, comme admin_erreurs la calcule (056) : identifiants et nombres
-- effacés, 160 caractères.
CREATE OR REPLACE FUNCTION public.forme_du_message(p_message TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT left(regexp_replace(regexp_replace(p_message,
           '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', '#', 'g'),
           '[0-9]+', '#', 'g'), 160);
$$;

CREATE OR REPLACE FUNCTION public.admin_erreurs_par_jour(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (jour DATE, erreurs INTEGER, alertes INTEGER)
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
  SELECT d::date,
         (SELECT count(*)::int FROM public.app_diagnostic_logs l
           WHERE l.level = 'error' AND l.created_at >= d AND l.created_at < d + interval '1 day'),
         (SELECT count(*)::int FROM public.app_diagnostic_logs l
           WHERE l.level = 'warning' AND l.created_at >= d AND l.created_at < d + interval '1 day')
    FROM generate_series(date_trunc('day', v_depuis), date_trunc('day', now()), interval '1 day') d
   ORDER BY 1;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_occurrences(p_tag TEXT, p_forme TEXT, p_jours INTEGER DEFAULT 30)
RETURNS TABLE (quand TIMESTAMPTZ, qui TEXT, plateforme TEXT, version TEXT, message TEXT, details TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
#variable_conflict use_column
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  RETURN QUERY
  SELECT public.instant_du_journal(l.created_at, l.metadata),
         public.admin_nom(l.user_id, p.display_name),
         l.platform,
         l.app_version,
         left(l.message, 1000),
         left(l.error_details, 2000)
    FROM public.app_diagnostic_logs l
    LEFT JOIN public.profiles p ON p.id = l.user_id
   WHERE l.tag = p_tag
     AND l.level IN ('warning', 'error')
     AND l.created_at >= now() - (greatest(p_jours, 1) || ' days')::interval
     AND public.forme_du_message(l.message) = p_forme
   ORDER BY l.created_at DESC
   LIMIT 100;
END;
$$;

-- -----------------------------------------------------------------------------
-- 5. Les versions installées
-- -----------------------------------------------------------------------------
-- La dernière version vue de chaque personne, par plateforme, sur la période : qui reste sur
-- une ancienne, avant de relever version_minimale_test.
CREATE OR REPLACE FUNCTION public.admin_versions(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (plateforme TEXT, version TEXT, personnes INTEGER, derniere TIMESTAMPTZ, qui TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
#variable_conflict use_column
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  RETURN QUERY
  WITH derniers AS (
    SELECT DISTINCT ON (l.user_id, l.platform)
           l.user_id, l.platform, coalesce(l.app_version, '?') AS version,
           public.instant_du_journal(l.created_at, l.metadata) AS quand
      FROM public.app_diagnostic_logs l
     WHERE l.user_id IS NOT NULL
       AND l.created_at >= now() - (greatest(p_jours, 1) || ' days')::interval
     ORDER BY l.user_id, l.platform, l.created_at DESC
  )
  SELECT d.platform, d.version, count(*)::int, max(d.quand),
         string_agg(public.admin_nom(d.user_id, p.display_name), ', ' ORDER BY d.quand DESC)
    FROM derniers d LEFT JOIN public.profiles p ON p.id = d.user_id
   GROUP BY d.platform, d.version
   ORDER BY d.platform, max(d.quand) DESC;
END;
$$;

-- -----------------------------------------------------------------------------
-- Droits : l'appel est ouvert aux comptes, la porte est est_admin() à l'intérieur.
-- -----------------------------------------------------------------------------
REVOKE ALL ON FUNCTION public.admin_reglages() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_regler(TEXT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_retours(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_suivre_retour(UUID, TEXT, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_economie_detail(INTEGER, BOOLEAN) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_erreurs_par_jour(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_occurrences(TEXT, TEXT, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_versions(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_reglages() TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_regler(TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_retours(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_suivre_retour(UUID, TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_economie_detail(INTEGER, BOOLEAN) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_erreurs_par_jour(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_occurrences(TEXT, TEXT, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_versions(INTEGER) TO authenticated;

-- Retour arrière :
--   DROP FUNCTION public.admin_reglages(), public.admin_regler(TEXT, JSONB),
--     public.admin_retours(INTEGER), public.admin_suivre_retour(UUID, TEXT, TEXT),
--     public.admin_economie_detail(INTEGER, BOOLEAN), public.admin_erreurs_par_jour(INTEGER),
--     public.admin_occurrences(TEXT, TEXT, INTEGER), public.admin_versions(INTEGER),
--     public.reglage_invalide(TEXT, JSONB), public.forme_du_message(TEXT);
--   DROP TABLE public.retours_suivis, public.journal_des_reglages;

-- Vérification (SQL Editor, en postgres — pas de JWT, donc pas d'admin : refus attendu) :
--   SELECT public.reglage_invalide('scan_etiquette_recherche', 'true');      → NULL
--   SELECT public.reglage_invalide('quotas_ia', '{"chat": {"compte": -1}}');  → la raison
--   SELECT count(*) FROM public.retours_suivis;                              → 0
