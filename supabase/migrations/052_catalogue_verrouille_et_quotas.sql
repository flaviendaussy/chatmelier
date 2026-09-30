-- 052 — Le catalogue n'est plus modifiable par n'importe qui, et l'IA a des quotas (V2.3 · B1, B2, B3)
--
-- 1. Jusqu'ici, la règle d'accès « Authenticated users can update wines. » laissait TOUTE
--    session (comptes anonymes compris) modifier TOUT vin du catalogue partagé. Depuis que le
--    scan d'étiquette sert le catalogue à tout le monde (P4), une seule session malveillante
--    ou un bug client pouvait réécrire ce que tous lisent. Désormais on ne modifie que ses
--    propres vins : ceux qu'on a créés, ceux des bouteilles d'une cave dont on est éditeur
--    ou administrateur, et ceux de ses dégustations. C'est exactement ce que font aujourd'hui
--    la fiche bouteille, la correction d'une fiche, l'enrichissement et les rattrapages
--    d'apogée : tous portent sur les vins de la personne.
-- 2. Les fiches décrites par le serveur (scan-label) sont marquées `decrite_par_serveur` :
--    seul le serveur les écrit, et `find_cached_wine` les sert en premier.
-- 3. Les valeurs de marché inventées (sans recherche, sans source, pas saisies par la
--    personne) sont effacées, comme 048 l'a fait pour les notes de critiques.
-- 4. Quotas d'IA par personne et par jour, tenus en base : `consommer_quota_ia(fonction)`.
--    Les fonctions edge l'appellent avec le jeton de l'appelant (aucun secret de plus). Les
--    limites vivent dans app_config.quotas_ia. Une session anonyme a ses propres limites.
--    Le scan de carte se compte en PAGES (l'app lit chaque page par un appel) : 45 par jour
--    pour un compte, 8 pour une session anonyme, soit environ 3 cartes sur le web (J5).
--
-- Idempotente.

-- -----------------------------------------------------------------------------
-- 1. Qui a créé un vin, et qui l'a décrit
-- -----------------------------------------------------------------------------
ALTER TABLE public.wines ADD COLUMN IF NOT EXISTS created_by UUID DEFAULT auth.uid();
ALTER TABLE public.wines ADD COLUMN IF NOT EXISTS decrite_par_serveur BOOLEAN NOT NULL DEFAULT false;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'wines_created_by_fkey') THEN
    ALTER TABLE public.wines
      ADD CONSTRAINT wines_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS wines_created_by ON public.wines (created_by);
CREATE INDEX IF NOT EXISTS wines_nom_millesime ON public.wines (lower(trim(name)), vintage);

-- -----------------------------------------------------------------------------
-- 2. Les règles d'accès
-- -----------------------------------------------------------------------------
DROP POLICY IF EXISTS "Authenticated users can update wines." ON public.wines;
DROP POLICY IF EXISTS wines_modification_par_les_siens ON public.wines;
CREATE POLICY wines_modification_par_les_siens ON public.wines
  FOR UPDATE TO authenticated
  USING (
    NOT decrite_par_serveur
    AND (
      created_by = auth.uid()
      OR EXISTS (SELECT 1 FROM public.bottles b
                  WHERE b.wine_id = wines.id
                    AND public.is_cellar_editor_or_admin(b.cellar_id, auth.uid()))
      OR EXISTS (SELECT 1 FROM public.tasting_log t
                  WHERE t.wine_id = wines.id AND t.user_id = auth.uid())
    )
  )
  WITH CHECK (NOT decrite_par_serveur);

DROP POLICY IF EXISTS "Authenticated users can create wines." ON public.wines;
DROP POLICY IF EXISTS wines_creation ON public.wines;
CREATE POLICY wines_creation ON public.wines
  FOR INSERT TO authenticated
  WITH CHECK (NOT decrite_par_serveur AND (created_by IS NULL OR created_by = auth.uid()));

-- Personne d'autre que le serveur ne change l'auteur d'une fiche ni sa marque « serveur ».
CREATE OR REPLACE FUNCTION public.wines_auteur_intouchable()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF current_user NOT IN ('service_role', 'postgres', 'supabase_admin') THEN
    NEW.created_by := OLD.created_by;
    NEW.decrite_par_serveur := OLD.decrite_par_serveur;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS wines_auteur_intouchable ON public.wines;
CREATE TRIGGER wines_auteur_intouchable BEFORE UPDATE ON public.wines
  FOR EACH ROW EXECUTE FUNCTION public.wines_auteur_intouchable();

-- -----------------------------------------------------------------------------
-- 3. Le catalogue sert d'abord les fiches du serveur, puis les plus complètes
-- -----------------------------------------------------------------------------
-- Même signature et même type de retour qu'en production (lus le 30/09) ; seuls l'ordre
-- et le search_path changent. Avant, LIMIT 1 sans ordre rendait une fiche au hasard.
CREATE OR REPLACE FUNCTION public.find_cached_wine(p_producer text, p_name text, p_vintage integer, p_cuvee text DEFAULT NULL::text)
RETURNS SETOF public.wines
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  RETURN QUERY
  SELECT w.*
  FROM public.wines w
  WHERE lower(trim(w.name)) = lower(trim(p_name))
    AND ((w.vintage IS NULL AND p_vintage IS NULL) OR (w.vintage = p_vintage))
    AND (p_producer IS NULL OR lower(trim(coalesce(w.producer, ''))) = lower(trim(p_producer)))
    AND (p_cuvee IS NULL OR lower(trim(coalesce(w.cuvee_parcel, ''))) = lower(trim(p_cuvee)))
  ORDER BY w.decrite_par_serveur DESC,
           (jsonb_typeof(w.grapes) = 'array' AND jsonb_array_length(w.grapes) > 0) DESC,
           length(coalesce(w.tasting_notes, '')) DESC,
           w.updated_at DESC
  LIMIT 1;
END;
$function$;

-- -----------------------------------------------------------------------------
-- 4. Plus de valeur de marché inventée
-- -----------------------------------------------------------------------------
-- Gardées : celles que la personne a saisies (marquées dans external_links.user_overrides)
-- et celles qui ont une source. Effacées : toutes les autres, venues d'un modèle sans
-- recherche.
UPDATE public.wines
   SET estimated_market_value = NULL,
       last_valuation_date = NULL
 WHERE estimated_market_value IS NOT NULL
   AND coalesce(external_links ->> 'valeur_source', '') = ''
   AND NOT (coalesce(external_links -> 'user_overrides', '[]'::jsonb) ? 'estimated_market_value');

-- -----------------------------------------------------------------------------
-- 5. Quotas d'IA
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quotas_ia (
  user_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  jour     DATE NOT NULL DEFAULT current_date,
  fonction TEXT NOT NULL CHECK (length(fonction) BETWEEN 1 AND 40),
  n        INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, jour, fonction)
);
ALTER TABLE public.quotas_ia ENABLE ROW LEVEL SECURITY;
-- Aucune politique : on n'y accède que par consommer_quota_ia.

INSERT INTO public.app_config (cle, valeur)
VALUES ('quotas_ia', '{
  "scan_etiquette": {"compte": 80, "anonyme": 10},
  "scan_carte":     {"compte": 45, "anonyme": 8},
  "question_carte": {"compte": 60, "anonyme": 20},
  "chat":           {"compte": 60, "anonyme": 10},
  "taches":         {"compte": 40, "anonyme": 5},
  "import_cave":    {"compte": 100, "anonyme": 0},
  "defaut":         {"compte": 30, "anonyme": 5}
}'::jsonb)
ON CONFLICT (cle) DO NOTHING;

CREATE OR REPLACE FUNCTION public.consommer_quota_ia(p_fonction TEXT)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_uid     UUID := auth.uid();
  v_anonyme BOOLEAN := public.est_anonyme();
  v_config  JSONB;
  v_limite  INTEGER;
  v_n       INTEGER;
BEGIN
  IF v_uid IS NULL THEN
    RETURN jsonb_build_object('autorise', false, 'raison', 'sans_session');
  END IF;
  IF p_fonction IS NULL OR length(p_fonction) NOT BETWEEN 1 AND 40 THEN
    RETURN jsonb_build_object('autorise', false, 'raison', 'fonction_invalide');
  END IF;
  -- Les administrateurs ne sont pas limités (bancs d'essai, démonstrations).
  IF public.est_admin() THEN
    RETURN jsonb_build_object('autorise', true, 'restant', NULL);
  END IF;

  SELECT c.valeur INTO v_config FROM public.app_config c WHERE c.cle = 'quotas_ia';
  v_limite := coalesce(
    (v_config -> p_fonction ->> CASE WHEN v_anonyme THEN 'anonyme' ELSE 'compte' END)::int,
    (v_config -> 'defaut' ->> CASE WHEN v_anonyme THEN 'anonyme' ELSE 'compte' END)::int,
    CASE WHEN v_anonyme THEN 5 ELSE 30 END);

  INSERT INTO public.quotas_ia AS q (user_id, jour, fonction, n)
  VALUES (v_uid, current_date, p_fonction, 1)
  ON CONFLICT (user_id, jour, fonction) DO UPDATE SET n = q.n + 1
  RETURNING q.n INTO v_n;

  IF v_n > v_limite THEN
    RETURN jsonb_build_object('autorise', false, 'raison', 'limite', 'limite', v_limite,
                              'anonyme', v_anonyme, 'restant', 0);
  END IF;
  RETURN jsonb_build_object('autorise', true, 'limite', v_limite, 'anonyme', v_anonyme,
                            'restant', v_limite - v_n);
END;
$$;

REVOKE ALL ON FUNCTION public.consommer_quota_ia(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.consommer_quota_ia(TEXT) TO authenticated;

-- Vérification (attendu : une seule règle UPDATE, wines_modification_par_les_siens ; aucune
-- valeur de marché sans source ni saisie ; la fonction de quota présente) :
SELECT
  (SELECT string_agg(policyname, ', ') FROM pg_policies WHERE tablename = 'wines' AND cmd = 'UPDATE') AS regle_modification,
  (SELECT count(*) FROM public.wines
    WHERE estimated_market_value IS NOT NULL
      AND coalesce(external_links ->> 'valeur_source', '') = ''
      AND NOT (coalesce(external_links -> 'user_overrides', '[]'::jsonb) ? 'estimated_market_value')) AS valeurs_inventees,
  (SELECT count(*) FROM pg_proc WHERE proname = 'consommer_quota_ia') AS fonction_quota;
