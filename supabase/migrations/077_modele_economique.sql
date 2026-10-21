-- 077 · Le modèle économique : moins d'IA offerte sans contrepartie, la pub réglable (21/10).
--
-- Étude du 21/10 (« vivre de la publicité, sans version payante ») : aujourd'hui chaque
-- personne active coûte plus d'IA qu'elle ne rapporte de pub, et un compte peut coûter près
-- de 1 € par jour aux quotas actuels. Ce que fait cette migration :
--
--   1. `quotas_ia` : des plafonds par jour plus bas, qui restent des garde-fous contre l'abus
--      (la vraie limite d'usage est désormais dans l'app : quelques questions offertes, puis
--      une vidéo) ; la cote d'un vin (recherche Google payante) reçoit enfin son quota.
--   2. `politique_pub` : ce que l'app offre chaque jour, ce qu'une vidéo débloque, les cartes
--      « Annonce » (désactivées tant que les identifiants de blocs natifs AdMob sont vides).
--      Lu par l'app 1.14.0+87 ; sans lui, elle prend les mêmes valeurs par défaut.
--   3. `ecpm_eur_estime` : un eCPM estimé pour le format natif, pour l'onglet Économie.
--   4. La console sait régler `politique_pub` et `push` (075).
--
-- Sans risque pour les versions installées : elles ne lisent pas `politique_pub`, et les
-- plafonds baissés restent largement au-dessus d'un usage normal.
--
-- Vérification :
--   SELECT valeur -> 'chat', valeur -> 'cote' FROM public.app_config WHERE cle = 'quotas_ia';
--   SELECT valeur FROM public.app_config WHERE cle = 'politique_pub';
--   SELECT public.reglage_invalide('politique_pub', '{"chat_offerts": 5}');   -- NULL (valide)

-- ─── 1. Les plafonds par jour ────────────────────────────────────────────────────────
-- Fusion : seules ces entrées changent, les autres restent comme Flavien les a réglées.
UPDATE public.app_config
   SET valeur = valeur || '{
         "scan_carte":     {"compte": 12, "anonyme": 3},
         "question_carte": {"compte": 40, "anonyme": 10},
         "chat":           {"compte": 30, "anonyme": 5},
         "cote":           {"compte": 10, "anonyme": 0}
       }'::jsonb,
       maj_le = now()
 WHERE cle = 'quotas_ia';

-- ─── 2. La politique de la pub ───────────────────────────────────────────────────────
INSERT INTO public.app_config (cle, valeur) VALUES ('politique_pub', '{
  "videos": true,
  "chat_offerts": 5,
  "chat_par_video": 8,
  "questions_carte_offertes": 3,
  "soiree_heures": 4,
  "cote_offertes": 3,
  "annonce_tous_les": 12,
  "unite_native_android": null,
  "unite_native_ios": null
}'::jsonb)
ON CONFLICT (cle) DO NOTHING;

-- ─── 3. Le format natif dans les estimations ─────────────────────────────────────────
UPDATE public.app_config
   SET valeur = '{"native": 2.0}'::jsonb || valeur, maj_le = now()
 WHERE cle = 'ecpm_eur_estime' AND NOT valeur ? 'native';

-- ─── 4. La console : deux réglages de plus (fonctions de la 072, complétées) ───────────
CREATE OR REPLACE FUNCTION public.reglage_invalide(p_cle text, p_valeur jsonb)
 RETURNS text
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
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
    WHEN 'version_minimale_test', 'version_disponible' THEN
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
    WHEN 'politique_pub' THEN
      -- Le modèle économique (077) : ce que l'IA offre chaque jour, ce qu'une vidéo débloque,
      -- les cartes « Annonce ». Des entiers raisonnables, des identifiants AdMob ou rien.
      IF jsonb_typeof(p_valeur) <> 'object' THEN
        RETURN 'un objet de réglages attendu';
      END IF;
      IF EXISTS (
        SELECT 1 FROM jsonb_each(p_valeur) t
         WHERE t.key IN ('chat_offerts', 'chat_par_video', 'questions_carte_offertes', 'soiree_heures',
                         'cote_offertes', 'annonce_tous_les')
           AND (jsonb_typeof(t.value) <> 'number' OR (t.value #>> '{}')::numeric NOT BETWEEN 0 AND 1000
                OR (t.value #>> '{}')::numeric <> trunc((t.value #>> '{}')::numeric))
      ) THEN
        RETURN 'des nombres entiers entre 0 et 1 000';
      END IF;
      IF EXISTS (
        SELECT 1 FROM jsonb_each(p_valeur) t
         WHERE t.key IN ('unite_native_android', 'unite_native_ios')
           AND jsonb_typeof(t.value) <> 'null'
           AND coalesce(t.value #>> '{}', '') !~ '^ca-app-pub-[0-9]{10,20}/[0-9]{6,12}$'
      ) THEN
        RETURN 'un identifiant de bloc AdMob (ca-app-pub-…/…) ou rien';
      END IF;
      IF p_valeur ? 'videos' AND jsonb_typeof(p_valeur -> 'videos') <> 'boolean' THEN
        RETURN '« videos » : oui ou non';
      END IF;
    WHEN 'push' THEN
      IF jsonb_typeof(p_valeur) <> 'object' OR coalesce(p_valeur ->> 'url', '') !~ '^https://'
         OR (p_valeur ? 'actif' AND jsonb_typeof(p_valeur -> 'actif') <> 'boolean') THEN
        RETURN 'une adresse https et « actif » oui ou non';
      END IF;
    ELSE
      RETURN 'réglage non modifiable depuis la console';
  END CASE;
  RETURN NULL;
END;
$function$;

CREATE OR REPLACE FUNCTION public.admin_reglages()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'auth'
AS $function$
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;
  RETURN jsonb_build_object(
    'reglages', coalesce((
      SELECT jsonb_object_agg(c.cle, jsonb_build_object('valeur', c.valeur, 'maj_le', c.maj_le))
        FROM public.app_config c
       WHERE c.cle IN ('modeles_ia', 'scan_etiquette_recherche', 'ia_session_obligatoire',
                       'admin_detail_nominatif', 'version_minimale_test', 'version_disponible', 'ecpm_eur_estime',
                       'quotas_ia', 'voix_naturelle', 'taux_de_change', 'politique_pub', 'push')
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
$function$;
