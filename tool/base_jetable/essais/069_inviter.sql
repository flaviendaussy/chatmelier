-- Essais de la migration 069 : inviter un ami à noter, sur son téléphone, le vin goûté ensemble.
DO $$
DECLARE
  v_caro    UUID := '00000000-0000-0000-0000-0000000c0069';
  v_flavien UUID := '00000000-0000-0000-0000-0000000f0069';
  v_marc    UUID := '00000000-0000-0000-0000-0000000a0069';
  v_envoyee BOOLEAN;
  v_n       INTEGER;
  v_data    JSONB;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_caro), (v_flavien), (v_marc) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name) VALUES (v_caro, 'Caro'), (v_flavien, 'Flavien'), (v_marc, 'Marc')
  ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;
  INSERT INTO public.friendships (user_id, friend_id, status) VALUES (v_caro, v_flavien, 'accepted');

  -- Caro goûte un Bardos avec Flavien et lui demande de le noter sur son téléphone.
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  v_envoyee := public.inviter_a_noter(
    v_flavien,
    '{"nom": " Bardos Reserva ", "millesime": 2020, "producteur": "Bodegas Bardos", "couleur": "red",
      "region": "Ribera del Duero", "pays": "Espagne", "note": 9, "aromas": ["cerise"]}'::jsonb,
    'Chez Paul');
  IF NOT v_envoyee THEN RAISE EXCEPTION 'la première invitation devait partir'; END IF;
  -- Le même geste deux fois : un seul avertissement.
  IF public.inviter_a_noter(v_flavien, '{"nom": "Bardos Reserva"}'::jsonb) THEN
    RAISE EXCEPTION 'une invitation répétée dans le quart d''heure ne repart pas';
  END IF;
  -- Pas à un inconnu, pas à soi-même, pas sans vin.
  BEGIN
    PERFORM public.inviter_a_noter(v_marc, '{"nom": "X"}'::jsonb);
    RAISE EXCEPTION 'Marc n''est pas un ami de Caro';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'pas_ami' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.inviter_a_noter(v_caro, '{"nom": "X"}'::jsonb);
    RAISE EXCEPTION 'on ne s''invite pas soi-même';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'destinataire_invalide' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.inviter_a_noter(v_flavien, '{"nom": "  "}'::jsonb);
    RAISE EXCEPTION 'une invitation sans vin est refusée';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'vin_invalide' THEN RAISE; END IF;
  END;
  RESET ROLE;

  SELECT count(*) INTO v_n FROM public.user_notifications
   WHERE user_id = v_flavien AND actor_id = v_caro AND type = 'invitation_a_noter' AND NOT coalesce(is_read, false);
  IF v_n <> 1 THEN RAISE EXCEPTION 'Flavien devait recevoir une seule invitation, et non %', v_n; END IF;
  SELECT data INTO v_data FROM public.user_notifications
   WHERE user_id = v_flavien AND type = 'invitation_a_noter';
  IF v_data -> 'vin' ->> 'nom' <> 'Bardos Reserva' OR (v_data -> 'vin' ->> 'millesime')::int <> 2020
     OR v_data ->> 'lieu' <> 'Chez Paul' THEN
    RAISE EXCEPTION 'l''invitation devait porter le vin et le lieu : %', v_data;
  END IF;
  IF v_data -> 'vin' ? 'note' OR v_data -> 'vin' ? 'aromas' THEN
    RAISE EXCEPTION 'l''invitation ne porte que le vin, pas les réponses de Caro : %', v_data;
  END IF;
  SELECT count(*) INTO v_n FROM public.tasting_log WHERE user_id = v_flavien;
  IF v_n <> 0 THEN RAISE EXCEPTION 'rien n''entre au journal de Flavien tant qu''il n''a pas noté'; END IF;
  RAISE NOTICE '✓ 069 : une invitation, entre amis seulement, le vin seul, rien au journal';

  -- Trente par jour au plus.
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  FOR i IN 1..29 LOOP
    PERFORM public.inviter_a_noter(v_flavien, jsonb_build_object('nom', 'Vin ' || i));
  END LOOP;
  BEGIN
    PERFORM public.inviter_a_noter(v_flavien, '{"nom": "Le trente et unième"}'::jsonb);
    RAISE EXCEPTION 'la trente et unième invitation du jour est refusée';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'trop_d_invitations' THEN RAISE; END IF;
  END;
  RESET ROLE;

  DELETE FROM public.user_notifications WHERE actor_id = v_caro AND type = 'invitation_a_noter';
  RAISE NOTICE '✓ 069 : trente invitations par jour au plus';
END $$;
