-- Essais de la migration 057.
DO $$
BEGIN
  INSERT INTO auth.users (id) VALUES ('57000000-0000-0000-0000-000000000001'), ('57000000-0000-0000-0000-000000000002')
    ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id) VALUES ('57000000-0000-0000-0000-000000000001'), ('57000000-0000-0000-0000-000000000002')
    ON CONFLICT DO NOTHING;
  INSERT INTO public.table_sessions (code, host_user_id, restaurant_name, menu)
    VALUES ('FIN234', '57000000-0000-0000-0000-000000000001', 'The Kitchin', '{"wines":[{"name":"Morgon"}]}');
END $$;

-- 1. L'hôte choisit et publie ; un convive ne le peut pas.
SET ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"57000000-0000-0000-0000-000000000001","role":"authenticated"}', false);
SELECT public.choisir_vins_de_table(' fin234 ', '[{"cle":"morgon|lapierre|2022","nom":"Morgon"}]');
SELECT public.publier_resultat_table('FIN234', '{"top":[{"nom":"Morgon"}]}');

DO $$
BEGIN
  BEGIN
    PERFORM public.choisir_vins_de_table('FIN234', '[1,2,3,4]');
    RAISE EXCEPTION 'quatre vins devaient être refusés';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'choix_invalide' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.publier_resultat_table('FIN234', jsonb_build_object('x', repeat('a', 40000)));
    RAISE EXCEPTION 'un résultat démesuré devait être refusé';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'resultat_trop_long' THEN RAISE; END IF;
  END;
END $$;

SELECT set_config('request.jwt.claims', '{"sub":"57000000-0000-0000-0000-000000000002","role":"authenticated"}', false);
DO $$
BEGIN
  BEGIN
    PERFORM public.choisir_vins_de_table('FIN234', '[]');
    RAISE EXCEPTION 'un convive ne doit pas choisir à la place de l''hôte';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'pas_hote' THEN RAISE; END IF;
  END;
  RAISE NOTICE '✓ seul l''hôte choisit et publie, dans les limites';
END $$;
RESET ROLE;

-- 2. Un invité anonyme lit l'état de la table par le code.
SET ROLE anon;
DO $$
DECLARE v RECORD;
BEGIN
  SELECT * INTO v FROM public.lire_etat_table('fin234');
  IF v.choix->0->>'nom' <> 'Morgon' THEN RAISE EXCEPTION 'le choix devait se lire par le code'; END IF;
  IF v.resultat->'top'->0->>'nom' <> 'Morgon' OR v.resultat_publie_le IS NULL THEN
    RAISE EXCEPTION 'le résultat publié devait se lire, daté';
  END IF;
  RAISE NOTICE '✓ un invité lit le choix et le résultat par le code';
END $$;
RESET ROLE;

-- 3. Une liste vide efface le choix.
SET ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"57000000-0000-0000-0000-000000000001","role":"authenticated"}', false);
SELECT public.choisir_vins_de_table('FIN234', '[]');
DO $$
DECLARE v JSONB;
BEGIN
  SELECT choix INTO v FROM public.lire_etat_table('FIN234');
  IF v IS NOT NULL THEN RAISE EXCEPTION 'le choix devait être effacé'; END IF;
  RAISE NOTICE '✓ une liste vide efface le choix';
END $$;
RESET ROLE;
