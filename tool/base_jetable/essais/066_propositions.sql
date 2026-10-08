-- Essais de la migration 066 : la dégustation faite pour un ami, à accepter.
DO $$
DECLARE
  v_caro    UUID := '00000000-0000-0000-0000-0000000c0066';
  v_flavien UUID := '00000000-0000-0000-0000-0000000f0066';
  v_marc    UUID := '00000000-0000-0000-0000-0000000a0066';
  v_id      UUID;
  v_id2     UUID;
  v_json    JSONB;
  v_n       INTEGER;
  v_ligne   RECORD;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_caro), (v_flavien), (v_marc) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name) VALUES (v_caro, 'Caro'), (v_flavien, 'Flavien'), (v_marc, 'Marc')
  ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;
  INSERT INTO public.friendships (user_id, friend_id, status) VALUES (v_caro, v_flavien, 'accepted');

  -- Caro note un Bardos avec Flavien, sur son téléphone, et le lui propose.
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  v_id := public.proposer_degustation(
    v_flavien,
    '{"nom": "Bardos Reserva", "millesime": 2020, "producteur": "Bodegas Bardos", "couleur": "red",
      "region": "Castilla y León", "appellation": "Ribera del Duero", "pays": "Espagne",
      "cepages": ["Tempranillo"]}'::jsonb,
    8,
    '{"note": 8, "aromas": ["cerise", "cedre"], "profile_id": "flavien", "profile_name": "Flavien"}'::jsonb,
    NULL, 'Agneau de lait', 'Chez Paul', '["Caro", "Flavien"]'::jsonb, 'Flavien');
  -- Pas à un inconnu, pas à soi-même.
  BEGIN
    PERFORM public.proposer_degustation(v_marc, '{"nom": "X"}'::jsonb);
    RAISE EXCEPTION 'Marc n''est pas un ami de Caro';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'pas_ami' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.proposer_degustation(v_caro, '{"nom": "X"}'::jsonb);
    RAISE EXCEPTION 'on ne se propose pas une dégustation à soi-même';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'destinataire_invalide' THEN RAISE; END IF;
  END;
  -- Aucune écriture directe dans la table.
  BEGIN
    INSERT INTO public.degustations_proposees (auteur_id, pour_id, vin) VALUES (v_caro, v_flavien, '{"nom": "X"}');
    RAISE EXCEPTION 'la table ne s''écrit que par les fonctions';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;

  SELECT count(*) INTO v_n FROM public.user_notifications
   WHERE user_id = v_flavien AND type = 'degustation_a_accepter' AND data ->> 'degustation_id' = v_id::text
     AND NOT is_read;
  IF v_n <> 1 THEN RAISE EXCEPTION 'Flavien devait recevoir une notification à accepter'; END IF;
  SELECT count(*) INTO v_n FROM public.tasting_log WHERE user_id = v_flavien;
  IF v_n <> 0 THEN RAISE EXCEPTION 'rien ne doit entrer dans le journal de Flavien avant qu''il accepte'; END IF;

  -- Marc ne voit pas la proposition, et ne peut pas l'accepter.
  PERFORM public.essai_session(v_marc);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO v_n FROM public.degustations_proposees;
  IF v_n <> 0 THEN RAISE EXCEPTION 'Marc ne doit voir aucune proposition'; END IF;
  BEGIN
    PERFORM public.accepter_degustation(v_id);
    RAISE EXCEPTION 'Marc ne doit pas accepter à la place de Flavien';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'proposition_introuvable' THEN RAISE; END IF;
  END;
  RESET ROLE;
  RAISE NOTICE '✓ 066 : une proposition, entre amis seulement, rien au journal avant l''accord';

  -- Flavien accepte : sa propre fiche, la ligne de son journal, « vu avec Caro ».
  PERFORM public.essai_session(v_flavien);
  SET LOCAL ROLE authenticated;
  v_json := public.accepter_degustation(v_id);
  BEGIN
    PERFORM public.accepter_degustation(v_id);
    RAISE EXCEPTION 'une proposition ne s''accepte qu''une fois';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'deja_decidee' THEN RAISE; END IF;
  END;
  RESET ROLE;
  IF v_json -> 'questionnaire' ->> 'note' <> '8' OR v_json ->> 'defaut' IS NOT NULL THEN
    RAISE EXCEPTION 'l''app doit recevoir les réponses à apprendre : %', v_json;
  END IF;
  SELECT t.rating, t.co_tasters, t.food_paired, t.location_name, t.is_external, w.name, w.vintage, w.country,
         w.grapes, w.created_by
    INTO v_ligne
    FROM public.tasting_log t JOIN public.wines w ON w.id = t.wine_id
   WHERE t.id = (v_json ->> 'tasting_log_id')::uuid;
  IF v_ligne.rating <> 8 OR v_ligne.name <> 'Bardos Reserva' OR v_ligne.vintage <> 2020 OR v_ligne.country <> 'Espagne'
     OR v_ligne.created_by <> v_flavien OR v_ligne.grapes <> '[{"name": "Tempranillo"}]'::jsonb
     OR v_ligne.food_paired <> 'Agneau de lait' OR v_ligne.location_name <> 'Chez Paul' THEN
    RAISE EXCEPTION 'la ligne du journal de Flavien est fausse : %', v_ligne;
  END IF;
  IF v_ligne.co_tasters <> '["Caro"]'::jsonb THEN
    RAISE EXCEPTION 'convives : Caro seulement (pas Flavien lui-même), et non %', v_ligne.co_tasters;
  END IF;
  SELECT count(*) INTO v_n FROM public.user_notifications
   WHERE user_id = v_flavien AND type = 'degustation_a_accepter' AND NOT is_read;
  IF v_n <> 0 THEN RAISE EXCEPTION 'la notification devait passer en lue'; END IF;
  RAISE NOTICE '✓ 066 : acceptée, elle entre au journal de Flavien, avec Caro, sur sa propre fiche';

  -- Une bouteille bouchonnée, refusée.
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  v_id2 := public.proposer_degustation(v_flavien, '{"nom": "Morgon"}'::jsonb, 3, NULL, 'bouchonne');
  RESET ROLE;
  PERFORM public.essai_session(v_flavien);
  SET LOCAL ROLE authenticated;
  PERFORM public.refuser_degustation(v_id2);
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.degustations_proposees WHERE id = v_id2 AND statut = 'refusee';
  IF v_n <> 1 THEN RAISE EXCEPTION 'la proposition refusée devait le rester'; END IF;
  SELECT count(*) INTO v_n FROM public.tasting_log t JOIN public.wines w ON w.id = t.wine_id
   WHERE t.user_id = v_flavien AND w.name = 'Morgon';
  IF v_n <> 0 THEN RAISE EXCEPTION 'une dégustation refusée n''entre pas au journal'; END IF;

  -- Les durées : décidée il y a plus de 30 jours, elle part.
  UPDATE public.degustations_proposees SET decidee_le = now() - INTERVAL '31 days' WHERE id = v_id2;
  v_json := public.purger_selon_les_durees();
  IF (v_json ->> 'propositions')::int < 1 THEN RAISE EXCEPTION 'la vieille proposition devait partir : %', v_json; END IF;

  DELETE FROM public.degustations_proposees WHERE auteur_id = v_caro;
  RAISE NOTICE '✓ 066 : refusée, rien au journal ; purge des propositions décidées';
END $$;
