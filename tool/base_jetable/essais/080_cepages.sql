-- Essais de la migration 080 : les cépages trouvés se gardent pour tous, mais seule la
-- fonction (rôle de service) les lit et les écrit.
DO $$
DECLARE
  v_a UUID := '00000000-0000-0000-0000-0000000a0080';
  v_n INTEGER;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_a) ON CONFLICT DO NOTHING;

  -- Le rôle de service garde un vin trouvé, et un vin cherché en vain.
  SET LOCAL ROLE service_role;
  INSERT INTO public.cepages_des_vins (cle, producteur, nom, cepages, methode, source)
  VALUES ('de martino|ungrafted cinsault', 'De Martino', 'Ungrafted Cinsault', '[{"name": "Cinsault", "pct": 100}]',
          'recherche', 'https://demartino.cl/');
  INSERT INTO public.cepages_des_vins (cle, nom, methode) VALUES ('|vin introuvable', 'Vin introuvable', 'inconnu');
  UPDATE public.cepages_des_vins SET trouve_le = now() WHERE cle = '|vin introuvable';
  RESET ROLE;
  RAISE NOTICE '✅ 080 : la fonction garde ce qu''elle trouve, et ce qu''elle n''a pas trouvé';

  -- Un compte ne lit pas la table en direct, et n'y glisse rien.
  PERFORM public.essai_session(v_a);
  SET LOCAL ROLE authenticated;
  BEGIN
    SELECT count(*) INTO v_n FROM public.cepages_des_vins;
    RAISE EXCEPTION 'un compte lit le cache en direct (% lignes)', v_n;
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    INSERT INTO public.cepages_des_vins (cle, nom, cepages, methode)
    VALUES ('chateau petrus|petrus', 'Petrus', '[{"name": "Cabernet Sauvignon", "pct": 100}]', 'recherche');
    RAISE EXCEPTION 'un compte écrit de faux cépages dans le cache commun';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;
  RAISE NOTICE '✅ 080 : un compte ne lit ni n''écrit le cache directement';

  -- Des cépages qui ne sont pas une liste, une méthode inconnue : refusés.
  BEGIN
    INSERT INTO public.cepages_des_vins (cle, nom, cepages, methode) VALUES ('x|y', 'Y', '{"name": "Syrah"}', 'recherche');
    RAISE EXCEPTION 'des cépages qui ne sont pas une liste sont acceptés';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.cepages_des_vins (cle, nom, methode) VALUES ('x|z', 'Z', 'devine');
    RAISE EXCEPTION 'une méthode inconnue est acceptée';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RAISE NOTICE '✅ 080 : la forme des cépages et la méthode sont vérifiées';

  -- Le plafond du jour, ajouté sans toucher aux autres.
  IF (SELECT valeur -> 'cepages' ->> 'compte' FROM public.app_config WHERE cle = 'quotas_ia')::int <> 40 THEN
    RAISE EXCEPTION 'le plafond des cépages manque';
  END IF;
  IF (SELECT valeur -> 'chat' FROM public.app_config WHERE cle = 'quotas_ia') IS NULL THEN
    RAISE EXCEPTION 'les autres plafonds ont été écrasés';
  END IF;
  RAISE NOTICE '✅ 080 : le plafond du jour, à côté des autres';
END $$;
