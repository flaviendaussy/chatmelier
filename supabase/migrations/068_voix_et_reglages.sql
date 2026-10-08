-- =============================================================================
-- 068 — La voix des récits, et deux réglages de plus dans la console (V2.4 · R8)
-- =============================================================================
--
-- 1. `app_config.voix_naturelle` (faux par défaut) : les récits des vins sont lus par
--    Gemini TTS au lieu de la voix du téléphone (« the voice must sound much more natural
--    than this horror », 04/10). Payant à chaque lecture : on l'allume depuis la console
--    une fois le coût mesuré (Économie, fonction « voix »).
-- 2. `tarifs_ia` : le prix de la voix. Flash TTS : 0,50 $ le million de jetons de texte en
--    entrée, 10 $ le million de jetons audio en sortie ; Pro TTS : le double. À vérifier
--    sur la page des tarifs de Google avant de l'allumer pour tous.
-- 3. La console sait régler `voix_naturelle` (oui ou non) et `taux_de_change` (065 : la
--    conversion en euros d'un compte AdMob dans une autre devise), avec leur forme vérifiée
--    et le journal des changements, comme les autres réglages (060).
--
-- Rejouable.
-- =============================================================================

INSERT INTO public.app_config (cle, valeur) VALUES ('voix_naturelle', 'false'::jsonb)
ON CONFLICT (cle) DO NOTHING;

INSERT INTO public.tarifs_ia (motif, priorite, entree_usd, sortie_usd, du, au, note) VALUES
  ('%pro%tts%',   1, 1.00, 20.00, DATE '2000-01-01', NULL, 'Gemini Pro TTS (voix des récits)'),
  ('%tts%',       2, 0.50, 10.00, DATE '2000-01-01', NULL, 'Gemini Flash TTS (voix des récits)')
ON CONFLICT (motif, du) DO NOTHING;

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
    WHEN 'scan_etiquette_recherche', 'ia_session_obligatoire', 'admin_detail_nominatif', 'voix_naturelle' THEN
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
    WHEN 'taux_de_change' THEN
      IF jsonb_typeof(p_valeur) <> 'object' OR EXISTS (
        SELECT 1 FROM jsonb_each(p_valeur) t
         WHERE t.key !~ '^[A-Z]{3}$'
            OR jsonb_typeof(t.value) <> 'number'
            OR (t.value #>> '{}')::numeric <= 0 OR (t.value #>> '{}')::numeric > 1000
      ) THEN
        RETURN 'un taux en euros par code de devise (GBP, USD…), positif';
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
                       'admin_detail_nominatif', 'version_minimale_test', 'ecpm_eur_estime', 'quotas_ia',
                       'voix_naturelle', 'taux_de_change')
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

REVOKE ALL ON FUNCTION public.admin_reglages() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_reglages() TO authenticated;

-- Retour arrière :
--   DELETE FROM public.app_config WHERE cle = 'voix_naturelle';
--   DELETE FROM public.tarifs_ia WHERE motif IN ('%pro%tts%', '%tts%');
--   (puis rejouer la 060 pour reglage_invalide et admin_reglages)

-- Vérification (SQL Editor) :
--   SELECT valeur FROM public.app_config WHERE cle = 'voix_naturelle';          → false
--   SELECT public.reglage_invalide('voix_naturelle', 'true');                   → NULL
--   SELECT public.reglage_invalide('taux_de_change', '{"GBP": 1.17}');          → NULL
--   SELECT public.cout_ia_usd('gemini-2.5-flash-preview-tts', 100, 1000, now()); → 0.01005
