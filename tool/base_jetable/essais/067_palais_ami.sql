-- Essais de la migration 067 : la carte de goût d'un ami.
DO $$
DECLARE
  v_caro    UUID := '00000000-0000-0000-0000-0000000c0067';
  v_flavien UUID := '00000000-0000-0000-0000-0000000f0067';
  v_marc    UUID := '00000000-0000-0000-0000-0000000a0067';
  v_json    JSONB;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_caro), (v_flavien), (v_marc) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name) VALUES (v_caro, 'Caro'), (v_flavien, 'Flavien'), (v_marc, 'Marc')
  ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;
  INSERT INTO public.friendships (user_id, friend_id, status) VALUES (v_flavien, v_caro, 'accepted');
  INSERT INTO public.palais_utilisateur (user_id, profils, preuves)
  VALUES (v_caro,
          '[{"id": "proche", "name": "Papa", "is_primary": false, "questionnaires_completed": 2},
            {"id": "moi", "name": "Caro", "is_primary": true, "questionnaires_completed": 7, "notes": "privé"}]',
          '[{"secret": true}]')
  ON CONFLICT (user_id) DO UPDATE SET profils = EXCLUDED.profils, preuves = EXCLUDED.preuves;

  PERFORM public.essai_session(v_flavien);
  SET LOCAL ROLE authenticated;
  v_json := public.palais_d_un_ami(v_caro);
  RESET ROLE;
  IF v_json ->> 'name' <> 'Caro' OR (v_json ->> 'questionnaires_completed')::int <> 7 THEN
    RAISE EXCEPTION 'Flavien devait lire le profil principal de Caro : %', v_json;
  END IF;
  IF v_json ? 'notes' OR v_json ? 'secret' THEN
    RAISE EXCEPTION 'ni ses notes ni ses preuves ne sortent : %', v_json;
  END IF;

  PERFORM public.essai_session(v_marc);
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.palais_d_un_ami(v_caro);
    RAISE EXCEPTION 'Marc n''est pas ami avec Caro';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'pas_ami' THEN RAISE; END IF;
  END;
  -- Le palais de Caro reste fermé en lecture directe.
  IF (SELECT count(*) FROM public.palais_utilisateur WHERE user_id = v_caro) <> 0 THEN
    RAISE EXCEPTION 'la table palais_utilisateur doit rester fermée aux autres';
  END IF;
  RESET ROLE;

  DELETE FROM public.palais_utilisateur WHERE user_id = v_caro;
  DELETE FROM public.friendships WHERE user_id = v_flavien AND friend_id = v_caro;
  RAISE NOTICE '✓ 067 : la carte de goût d''un ami, son seul profil principal, entre amis seulement';
END $$;
