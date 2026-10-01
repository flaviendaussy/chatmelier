-- 057 — La fin de soirée : la bouteille choisie, et le résultat de la table publié
--        (V2.3 · E2, F1)
--
-- La table s'arrêtait au podium : personne ne disait quelle bouteille avait été
-- commandée, et personne ne la notait. Le palais n'apprenait rien de la soirée, alors
-- que c'est au restaurant qu'il se décrit le mieux. La boucle se referme ici :
--
--   · l'hôte indique la ou les bouteilles choisies (`choix`, trois au plus) ;
--   · chaque convive voit ce choix sur son téléphone et note le vin d'un geste ;
--   · l'hôte publie le résultat de la table (`resultat` : podium, raisons, paire), que la
--     page invité légère (F2) affiche sans rien recalculer.
--
-- Lecture par le code, comme la carte (054) ; écriture par l'hôte seul.
-- Rejouable.

ALTER TABLE public.table_sessions ADD COLUMN IF NOT EXISTS choix JSONB;
ALTER TABLE public.table_sessions ADD COLUMN IF NOT EXISTS resultat JSONB;
ALTER TABLE public.table_sessions ADD COLUMN IF NOT EXISTS resultat_publie_le TIMESTAMPTZ;

COMMENT ON COLUMN public.table_sessions.choix IS
  'Les vins commandés par la table, indiqués par l''hôte : [{cle, nom, producteur, millesime, couleur}].';
COMMENT ON COLUMN public.table_sessions.resultat IS
  'Le résultat de la table calculé chez l''hôte (podium, raisons, paire), pour la page invité.';

-- -----------------------------------------------------------------------------
-- L'hôte indique ce que la table a choisi. Une liste vide efface le choix.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.choisir_vins_de_table(p_code TEXT, p_choix JSONB)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_choix IS NOT NULL AND (jsonb_typeof(p_choix) <> 'array' OR jsonb_array_length(p_choix) > 3) THEN
    RAISE EXCEPTION 'choix_invalide' USING HINT = 'Une liste de trois vins au plus.';
  END IF;

  UPDATE public.table_sessions s
     SET choix = CASE WHEN p_choix IS NULL OR jsonb_array_length(p_choix) = 0 THEN NULL ELSE p_choix END
   WHERE s.code = upper(trim(p_code))
     AND s.expires_at > now()
     AND s.host_user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pas_hote' USING HINT = 'Seul l''hôte d''une table en cours choisit ses vins.';
  END IF;
END;
$$;

-- -----------------------------------------------------------------------------
-- L'hôte publie le résultat de sa table.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.publier_resultat_table(p_code TEXT, p_resultat JSONB)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Trois vins, leurs raisons et une paire tiennent en quelques kilo-octets : au-delà,
  -- ce n'est plus un résultat de table.
  IF p_resultat IS NOT NULL AND octet_length(p_resultat::text) > 32768 THEN
    RAISE EXCEPTION 'resultat_trop_long';
  END IF;

  UPDATE public.table_sessions s
     SET resultat = p_resultat,
         resultat_publie_le = now()
   WHERE s.code = upper(trim(p_code))
     AND s.expires_at > now()
     AND s.host_user_id = auth.uid();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'pas_hote' USING HINT = 'Seul l''hôte d''une table en cours publie son résultat.';
  END IF;
END;
$$;

-- -----------------------------------------------------------------------------
-- Ce que la table a choisi et publié, pour qui a le code.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.lire_etat_table(p_code TEXT)
RETURNS TABLE (
  restaurant_name    TEXT,
  choix              JSONB,
  resultat           JSONB,
  resultat_publie_le TIMESTAMPTZ,
  expires_at         TIMESTAMPTZ
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT s.restaurant_name, s.choix, s.resultat, s.resultat_publie_le, s.expires_at
  FROM public.table_sessions s
  WHERE s.code = upper(trim(p_code)) AND s.expires_at > now();
$$;

REVOKE ALL ON FUNCTION public.choisir_vins_de_table(TEXT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.publier_resultat_table(TEXT, JSONB) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.lire_etat_table(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.choisir_vins_de_table(TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.publier_resultat_table(TEXT, JSONB) TO authenticated;
GRANT EXECUTE ON FUNCTION public.lire_etat_table(TEXT) TO anon, authenticated;

-- Vérification :
--   SELECT column_name FROM information_schema.columns
--    WHERE table_name = 'table_sessions' AND column_name IN ('choix', 'resultat', 'resultat_publie_le');
--   → trois lignes
--   SELECT proname FROM pg_proc
--    WHERE proname IN ('choisir_vins_de_table', 'publier_resultat_table', 'lire_etat_table');
--   → trois lignes
