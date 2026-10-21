-- Essais de la migration 075 : les notifications push.
-- À lancer avec la 074 (demander_amitie) : tool/base_jetable/base_jetable.sh 074 075

-- pg_net n'existe pas ici : une doublure qui note les appels que la base aurait faits.
CREATE SCHEMA IF NOT EXISTS net;
CREATE TABLE IF NOT EXISTS net.appels (url TEXT, body JSONB, headers JSONB, le TIMESTAMPTZ DEFAULT clock_timestamp());
CREATE OR REPLACE FUNCTION net.http_post(url TEXT, body JSONB, headers JSONB)
RETURNS BIGINT LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO net.appels (url, body, headers) VALUES (url, body, headers);
  RETURN 1;
END $$;

DO $$
DECLARE
  v_flavien UUID := '00000000-0000-0000-0000-0000000f0075';
  v_caro    UUID := '00000000-0000-0000-0000-0000000c0075';
  v_marc    UUID := '00000000-0000-0000-0000-0000000a0075';
  v_cave    UUID := '00000000-0000-0000-0000-00000000ca75';
  v_vin     UUID;
  v_bouteille UUID;
  v_n       INTEGER;
  v_appels  INTEGER;
  v_notif   public.user_notifications;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_flavien), (v_caro), (v_marc) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name) VALUES (v_flavien, 'Flavien'), (v_caro, 'Caro'), (v_marc, 'Marc')
  ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;
  INSERT INTO public.cellars (id, name, owner_id) VALUES (v_cave, 'London', v_flavien);
  INSERT INTO public.cellar_members (cellar_id, user_id, role) VALUES (v_cave, v_flavien, 'owner'), (v_cave, v_caro, 'editor');
  INSERT INTO public.wines (name) VALUES ('Bandol') RETURNING id INTO v_vin;

  -- 1. Un client qui écrit dans la boîte d'un autre : la notification reste, aucun push.
  PERFORM public.essai_session(v_marc);
  SET LOCAL ROLE authenticated;
  INSERT INTO public.user_notifications (user_id, actor_id, type, title, body, par_le_serveur, pousse_le)
  VALUES (v_flavien, v_marc, 'friend_request', 'Faux', 'Hameçon', true, now());
  RESET ROLE;
  SELECT * INTO v_notif FROM public.user_notifications WHERE body = 'Hameçon';
  IF v_notif.par_le_serveur OR v_notif.pousse_le IS NOT NULL THEN
    RAISE EXCEPTION 'un client ne peut pas se dire serveur ni marquer un envoi';
  END IF;
  SELECT count(*) INTO v_appels FROM net.appels;
  IF v_appels <> 0 THEN RAISE EXCEPTION 'aucun push pour une notification écrite par un client (% appels)', v_appels; END IF;
  RAISE NOTICE '✅ une notification écrite par un client ne part pas en push';

  -- 2. Une demande d'ami par le serveur (074) : un push, avec l'identifiant de la notification.
  PERFORM public.essai_session(v_marc);
  SET LOCAL ROLE authenticated;
  PERFORM public.demander_amitie(v_flavien);
  RESET ROLE;
  SELECT * INTO v_notif FROM public.user_notifications WHERE user_id = v_flavien AND type = 'friend_request' AND par_le_serveur;
  IF v_notif.id IS NULL THEN RAISE EXCEPTION 'la demande d''ami du serveur doit être marquée « par le serveur »'; END IF;
  SELECT count(*) INTO v_appels FROM net.appels
   WHERE body ->> 'notification_id' = v_notif.id::text AND url LIKE '%/functions/v1/envoyer-push';
  IF v_appels <> 1 THEN RAISE EXCEPTION 'un appel à envoyer-push attendu, % vus', v_appels; END IF;
  RAISE NOTICE '✅ une notification du serveur appelle envoyer-push une fois';

  -- 3. Caro ajoute une bouteille à la cave de Flavien : Flavien est prévenu, pas Caro.
  DELETE FROM net.appels;
  PERFORM public.essai_session(v_caro);
  INSERT INTO public.bottles (cellar_id, wine_id, quantity, added_by) VALUES (v_cave, v_vin, 1, v_caro) RETURNING id INTO v_bouteille;
  SELECT * INTO v_notif FROM public.user_notifications WHERE user_id = v_flavien AND type = 'activite_cave';
  IF v_notif.id IS NULL OR v_notif.body <> 'Caro a ajouté 1 bouteille à « London ».' THEN
    RAISE EXCEPTION 'avis attendu pour Flavien, reçu : %', v_notif.body;
  END IF;
  IF (v_notif.data ->> 'route') <> '/cellar' OR (v_notif.data ->> 'cellar_id') <> v_cave::text THEN
    RAISE EXCEPTION 'l''avis doit mener à la cave : %', v_notif.data;
  END IF;
  SELECT count(*) INTO v_n FROM public.user_notifications WHERE user_id = v_caro AND type = 'activite_cave';
  IF v_n <> 0 THEN RAISE EXCEPTION 'Caro ne doit pas être prévenue de ses propres ajouts'; END IF;
  SELECT count(*) INTO v_appels FROM net.appels;
  IF v_appels <> 1 THEN RAISE EXCEPTION 'un push attendu pour le premier ajout, % vus', v_appels; END IF;

  -- Cinq de plus dans la demi-heure, puis deux par la quantité : le même avis, complété, sans nouveau push.
  INSERT INTO public.bottles (cellar_id, wine_id, quantity, added_by) VALUES (v_cave, v_vin, 5, v_caro);
  UPDATE public.bottles SET quantity = quantity + 2 WHERE id = v_bouteille;
  UPDATE public.bottles SET quantity = quantity - 1 WHERE id = v_bouteille;  -- boire n'est pas ajouter
  SELECT count(*) INTO v_n FROM public.user_notifications WHERE user_id = v_flavien AND type = 'activite_cave';
  SELECT * INTO v_notif FROM public.user_notifications WHERE user_id = v_flavien AND type = 'activite_cave';
  IF v_n <> 1 OR (v_notif.data ->> 'nombre')::int <> 8 OR v_notif.body <> 'Caro a ajouté 8 bouteilles à « London ».' THEN
    RAISE EXCEPTION 'un seul avis, complété à 8 bouteilles, attendu : % avis, « % »', v_n, v_notif.body;
  END IF;
  SELECT count(*) INTO v_appels FROM net.appels;
  IF v_appels <> 1 THEN RAISE EXCEPTION 'les ajouts suivants ne repoussent pas (% appels)', v_appels; END IF;
  RAISE NOTICE '✅ cave partagée : un avis par demi-heure, complété, un seul push';

  -- Lu : le prochain ajout fait un nouvel avis.
  UPDATE public.user_notifications SET is_read = true WHERE id = v_notif.id;
  INSERT INTO public.bottles (cellar_id, wine_id, quantity, added_by) VALUES (v_cave, v_vin, 1, v_caro);
  SELECT count(*) INTO v_n FROM public.user_notifications WHERE user_id = v_flavien AND type = 'activite_cave';
  IF v_n <> 2 THEN RAISE EXCEPTION 'après lecture, un nouvel ajout fait un nouvel avis (% avis)', v_n; END IF;
  RAISE NOTICE '✅ un avis lu n''est plus complété';

  -- Flavien a un téléphone en anglais : l'avis suivant est écrit en anglais (la boîte l'affiche tel quel).
  UPDATE public.user_notifications SET is_read = true WHERE user_id = v_flavien AND type = 'activite_cave';
  INSERT INTO public.appareils_push (jeton, user_id, plateforme, langue) VALUES ('jeton-langue-0123456789abcdef', v_flavien, 'ios', 'en');
  INSERT INTO public.bottles (cellar_id, wine_id, quantity, added_by) VALUES (v_cave, v_vin, 2, v_caro);
  SELECT * INTO v_notif FROM public.user_notifications
   WHERE user_id = v_flavien AND type = 'activite_cave' AND NOT is_read;
  IF v_notif.title <> 'Your shared cellar' OR v_notif.body <> 'Caro added 2 bottles to "London".' THEN
    RAISE EXCEPTION 'avis en anglais attendu : % / %', v_notif.title, v_notif.body;
  END IF;
  DELETE FROM public.appareils_push WHERE jeton = 'jeton-langue-0123456789abcdef';
  RAISE NOTICE '✅ l''avis de cave est écrit dans la langue du téléphone du destinataire';

  -- 4. La réservation : une seule fois, et seulement pour service_role.
  SET LOCAL ROLE service_role;
  SELECT count(*) INTO v_n FROM public.reserver_le_push(v_notif.id);
  IF v_n <> 1 THEN RAISE EXCEPTION 'la première réservation rend la notification'; END IF;
  SELECT count(*) INTO v_n FROM public.reserver_le_push(v_notif.id);
  IF v_n <> 0 THEN RAISE EXCEPTION 'une notification ne se pousse qu''une fois'; END IF;
  RESET ROLE;
  PERFORM public.essai_session(v_flavien);
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.reserver_le_push(v_notif.id);
    RAISE EXCEPTION 'un compte ne réserve pas un push';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  -- Marquer lu ne touche ni à l'origine ni à l'envoi.
  UPDATE public.user_notifications SET is_read = false, pousse_le = NULL, par_le_serveur = false WHERE id = v_notif.id;
  RESET ROLE;
  SELECT * INTO v_notif FROM public.user_notifications WHERE id = v_notif.id;
  IF v_notif.pousse_le IS NULL OR NOT v_notif.par_le_serveur THEN
    RAISE EXCEPTION 'un client ne défait pas un envoi ni une origine';
  END IF;
  RAISE NOTICE '✅ réservation unique, réservée au serveur';

  -- 5. Les appareils : par les fonctions seulement ; un jeton change de titulaire.
  PERFORM public.essai_session(v_flavien);
  SET LOCAL ROLE authenticated;
  PERFORM public.enregistrer_appareil_push('jeton-de-test-flavien-0123456789', 'android', 'FR', 60,
                                          '{"activite_cave": true}'::jsonb, '1.13.0+86');
  BEGIN
    PERFORM count(*) FROM public.appareils_push;
    RAISE EXCEPTION 'la table des appareils ne se lit pas directement';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.appareils_push WHERE user_id = v_flavien AND langue = 'fr' AND decalage_min = 60;
  IF v_n <> 1 THEN RAISE EXCEPTION 'appareil de Flavien attendu'; END IF;
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  PERFORM public.enregistrer_appareil_push('jeton-de-test-flavien-0123456789', 'android', 'en', 0, '{}'::jsonb, NULL);
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.appareils_push WHERE user_id = v_caro;
  IF v_n <> 1 THEN RAISE EXCEPTION 'le jeton passe à qui le présente'; END IF;
  -- Oublier : seulement son propre appareil.
  PERFORM public.essai_session(v_marc);
  SET LOCAL ROLE authenticated;
  PERFORM public.oublier_appareil_push('jeton-de-test-flavien-0123456789');
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.appareils_push;
  IF v_n <> 1 THEN RAISE EXCEPTION 'Marc n''efface pas l''appareil de Caro'; END IF;
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  PERFORM public.oublier_appareil_push('jeton-de-test-flavien-0123456789');
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.appareils_push;
  IF v_n <> 0 THEN RAISE EXCEPTION 'Caro oublie son appareil'; END IF;
  RAISE NOTICE '✅ appareils : par les fonctions, un jeton à un seul compte';

  -- 6. Coupé depuis la console : plus aucun appel.
  DELETE FROM net.appels;
  UPDATE public.app_config SET valeur = valeur || '{"actif": false}'::jsonb WHERE cle = 'push';
  PERFORM public.essai_session(v_marc);
  SET LOCAL ROLE authenticated;
  PERFORM public.demander_amitie(v_caro);
  RESET ROLE;
  SELECT count(*) INTO v_appels FROM net.appels;
  IF v_appels <> 0 THEN RAISE EXCEPTION 'push coupé : aucun appel'; END IF;
  UPDATE public.app_config SET valeur = valeur || '{"actif": true}'::jsonb WHERE cle = 'push';
  RAISE NOTICE '✅ l''interrupteur de la console coupe les push';
END $$;
