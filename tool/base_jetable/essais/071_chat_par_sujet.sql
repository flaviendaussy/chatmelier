-- Essais de la migration 071 : un historique par sujet, et « Effacer » qui efface.
DO $$
DECLARE
  v_flavien UUID := '00000000-0000-0000-0000-0000000f0071';
  v_caro    UUID := '00000000-0000-0000-0000-0000000c0071';
  v_cave    UUID;
  v_n       INT;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_flavien), (v_caro) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name) VALUES (v_flavien, 'Flavien'), (v_caro, 'Caro') ON CONFLICT DO NOTHING;
  INSERT INTO public.cellars (owner_id, name) VALUES (v_flavien, 'London') RETURNING id INTO v_cave;
  INSERT INTO public.cellar_members (cellar_id, user_id, role) VALUES (v_cave, v_flavien, 'admin'), (v_cave, v_caro, 'editor');

  -- Flavien : le chat général, puis le crozes-hermitage. Caro : le chat général.
  PERFORM public.essai_session(v_flavien);
  SET LOCAL ROLE authenticated;
  INSERT INTO public.chat_messages (cellar_id, user_id, role, content) VALUES
    (v_cave, v_flavien, 'user', 'Que boire ce soir ?');
  INSERT INTO public.chat_messages (cellar_id, user_id, role, content, sujet) VALUES
    (v_cave, v_flavien, 'user', 'Faut-il le carafer ?', 'vin:5f0c2e1a-0d3b-4c2e-9f61-2b7d3c4e5a6b'),
    (v_cave, v_flavien, 'assistant', 'Une heure suffit.', 'vin:5f0c2e1a-0d3b-4c2e-9f61-2b7d3c4e5a6b');
  BEGIN
    INSERT INTO public.chat_messages (cellar_id, user_id, role, content, sujet) VALUES
      (v_cave, v_flavien, 'user', 'x', 'n''importe quoi');
    RAISE EXCEPTION 'un sujet mal formé devait être refusé';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  RESET ROLE;

  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  INSERT INTO public.chat_messages (cellar_id, user_id, role, content) VALUES (v_cave, v_caro, 'user', 'Et pour moi ?');
  -- Caro ne lit que ses messages, même dans la cave qu'elle partage avec Flavien.
  SELECT count(*) INTO v_n FROM public.chat_messages;
  IF v_n <> 1 THEN RAISE EXCEPTION 'Caro devait ne lire que son message, elle en lit %', v_n; END IF;
  -- Et ne supprime pas ceux de Flavien.
  DELETE FROM public.chat_messages WHERE user_id = v_flavien;
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.chat_messages WHERE user_id = v_flavien;
  IF v_n <> 3 THEN RAISE EXCEPTION 'les messages de Flavien devaient rester (3), il en reste %', v_n; END IF;

  -- Flavien lit l'historique du crozes seul, puis l'efface : le chat général reste.
  PERFORM public.essai_session(v_flavien);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO v_n FROM public.chat_messages
   WHERE cellar_id = v_cave AND sujet = 'vin:5f0c2e1a-0d3b-4c2e-9f61-2b7d3c4e5a6b';
  IF v_n <> 2 THEN RAISE EXCEPTION 'la conversation du crozes devait compter 2 messages, elle en a %', v_n; END IF;
  DELETE FROM public.chat_messages WHERE cellar_id = v_cave AND sujet = 'vin:5f0c2e1a-0d3b-4c2e-9f61-2b7d3c4e5a6b';
  SELECT count(*) INTO v_n FROM public.chat_messages WHERE cellar_id = v_cave;
  IF v_n <> 1 THEN RAISE EXCEPTION '« Effacer » devait supprimer le crozes et garder le chat général (1), il reste %', v_n; END IF;
  DELETE FROM public.chat_messages WHERE cellar_id = v_cave AND sujet IS NULL;
  SELECT count(*) INTO v_n FROM public.chat_messages;
  IF v_n <> 0 THEN RAISE EXCEPTION '« Effacer » le chat général devait tout supprimer, il reste %', v_n; END IF;
  RESET ROLE;

  RAISE NOTICE '✓ 071 : un historique par sujet ; chacun lit et efface les siens, et seulement les siens';
END $$;
