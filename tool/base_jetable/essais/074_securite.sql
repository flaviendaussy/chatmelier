-- Essais de la migration 074 : la sécurité des accès et du partage (lot Q).
-- Personas dédiés (suffixe 074) pour ne croiser aucun autre essai.

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1 — cellar_members : insertion, protection du propriétaire ; Q1b ; Q2 ; Q3         ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
DO $$
DECLARE
  v_prop     UUID := '00000000-0000-0000-0000-0000000f0074';  -- propriétaire de la cave
  v_admin2   UUID := '00000000-0000-0000-0000-0000000a0074';  -- admin NON propriétaire
  v_membre   UUID := '00000000-0000-0000-0000-0000000e0074';  -- membre éditeur
  v_ami      UUID := '00000000-0000-0000-0000-0000000b0074';  -- ami du propriétaire
  v_etranger UUID := '00000000-0000-0000-0000-0000000c0074';  -- quelqu'un d'extérieur
  v_prop2    UUID := '00000000-0000-0000-0000-0000000d0074';  -- autre propriétaire
  v_cave     UUID;
  v_cave2    UUID;
  v_cave3    UUID;
  v_res      JSONB;
  v_json     JSON;
  v_n        INT;
  v_role     TEXT;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_prop), (v_admin2), (v_membre), (v_ami), (v_etranger), (v_prop2)
    ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name) VALUES
    (v_prop, 'Flavien'), (v_admin2, 'Adrien'), (v_membre, 'Manon'),
    (v_ami, 'Bastien'), (v_etranger, 'Inconnu'), (v_prop2, 'Diane')
    ON CONFLICT DO NOTHING;

  INSERT INTO public.cellars (owner_id, name) VALUES (v_prop, 'London')  RETURNING id INTO v_cave;
  INSERT INTO public.cellars (owner_id, name) VALUES (v_prop2, 'Paris')  RETURNING id INTO v_cave2;
  INSERT INTO public.cellar_members (cellar_id, user_id, role) VALUES
    (v_cave,  v_prop,   'admin'),   -- la ligne du propriétaire
    (v_cave,  v_admin2, 'admin'),   -- un admin qui n'est pas propriétaire
    (v_cave,  v_membre, 'editor'),
    (v_cave2, v_prop2,  'admin');

  -- (a) P0 : un étranger ne peut plus s'ajouter à une cave qui n'est pas la sienne.
  PERFORM public.essai_session(v_etranger);
  SET LOCAL ROLE authenticated;
  BEGIN
    INSERT INTO public.cellar_members (cellar_id, user_id, role) VALUES (v_cave, v_etranger, 'admin');
    RAISE EXCEPTION 'FAILLE P0 : un étranger a pu s''inscrire dans la cave d''autrui';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;

  -- (b) Le propriétaire s'inscrit lui-même à la création de SA cave : autorisé.
  INSERT INTO public.cellars (owner_id, name) VALUES (v_etranger, 'Sa cave') RETURNING id INTO v_cave3;
  PERFORM public.essai_session(v_etranger);
  SET LOCAL ROLE authenticated;
  INSERT INTO public.cellar_members (cellar_id, user_id, role) VALUES (v_cave3, v_etranger, 'admin');
  RESET ROLE;

  -- (c) Un admin de la cave ajoute un autre membre : autorisé.
  PERFORM public.essai_session(v_admin2);
  SET LOCAL ROLE authenticated;
  INSERT INTO public.cellar_members (cellar_id, user_id, role) VALUES (v_cave, v_prop2, 'viewer');
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_prop2;
  IF v_n <> 1 THEN RAISE EXCEPTION 'un admin devait pouvoir ajouter un membre'; END IF;

  -- (d) Un admin NON propriétaire ne peut pas retirer la ligne du propriétaire.
  PERFORM public.essai_session(v_admin2);
  SET LOCAL ROLE authenticated;
  DELETE FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_prop;
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_prop;
  IF v_n <> 1 THEN RAISE EXCEPTION 'la ligne du propriétaire a été retirée par un admin'; END IF;

  -- (e) ... ni la rétrograder (directement).
  PERFORM public.essai_session(v_admin2);
  SET LOCAL ROLE authenticated;
  UPDATE public.cellar_members SET role = 'viewer' WHERE cellar_id = v_cave AND user_id = v_prop;
  RESET ROLE;
  SELECT role INTO v_role FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_prop;
  IF v_role <> 'admin' THEN RAISE EXCEPTION 'le propriétaire a été rétrogradé en %', v_role; END IF;

  -- (f) ... ni via update_member_role.
  PERFORM public.essai_session(v_admin2);
  SET LOCAL ROLE authenticated;
  v_json := public.update_member_role(v_cave, v_prop, 'viewer');
  RESET ROLE;
  IF v_json ->> 'error' IS NULL THEN RAISE EXCEPTION 'update_member_role a laissé rétrograder le propriétaire : %', v_json; END IF;

  -- (g) Un membre peut se retirer lui-même.
  PERFORM public.essai_session(v_membre);
  SET LOCAL ROLE authenticated;
  DELETE FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_membre;
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_membre;
  IF v_n <> 0 THEN RAISE EXCEPTION 'un membre devait pouvoir quitter la cave'; END IF;

  -- (h) Un admin peut retirer un membre qui n'est pas le propriétaire.
  INSERT INTO public.cellar_members (cellar_id, user_id, role) VALUES (v_cave, v_membre, 'editor');
  PERFORM public.essai_session(v_admin2);
  SET LOCAL ROLE authenticated;
  DELETE FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_membre;
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_membre;
  IF v_n <> 0 THEN RAISE EXCEPTION 'un admin devait pouvoir retirer un membre non propriétaire'; END IF;

  RAISE NOTICE '✓ 074 Q1 : insertion réservée (propriétaire à la création, admins), ligne du propriétaire protégée';

  -- ── Q1 request_friend_cellar_access ──────────────────────────────────────────────
  -- Un non-ami est refusé.
  PERFORM public.essai_session(v_etranger);
  SET LOCAL ROLE authenticated;
  BEGIN
    v_res := public.request_friend_cellar_access(v_prop, 'viewer', NULL, NULL);
    RAISE EXCEPTION 'un non-ami a pu demander l''accès';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'pas_ami' THEN RAISE; END IF;
  END;
  RESET ROLE;

  -- Bastien est ami du propriétaire ; il demande l'accès en passant (exprès) l'id d'une
  -- cave TIERCE (celle de Diane). La fonction doit l'ignorer, viser la cave du propriétaire,
  -- et ne RIEN renvoyer qui révèle l'identifiant de cette cave.
  INSERT INTO public.friendships (user_id, friend_id, status) VALUES (v_prop, v_ami, 'accepted');
  PERFORM public.essai_session(v_ami);
  SET LOCAL ROLE authenticated;
  v_res := public.request_friend_cellar_access(v_prop, 'editor', v_cave2, 'coucou');
  RESET ROLE;
  IF (v_res ->> 'success') <> 'true' OR (v_res ? 'cellar_id') THEN
    RAISE EXCEPTION 'le retour ne doit pas porter cellar_id : %', v_res;
  END IF;
  SELECT cellar_id INTO v_cave3 FROM public.cellar_access_requests WHERE requester_id = v_ami;
  IF v_cave3 <> v_cave THEN
    RAISE EXCEPTION 'la demande a visé une cave tierce (%), pas celle de la cible (%)', v_cave3, v_cave;
  END IF;
  SELECT count(*) INTO v_n FROM public.user_notifications WHERE user_id = v_prop AND actor_id = v_ami AND type = 'cellar_request';
  IF v_n <> 1 THEN RAISE EXCEPTION 'le propriétaire devait recevoir une notification de demande'; END IF;
  RAISE NOTICE '✓ 074 Q1 : demande d''accès entre amis, cave de la cible seule, sans identifiant rendu';

  -- ── Q1b amitiés : le demandeur ne peut pas accepter sa propre demande ──────────────
  PERFORM public.essai_session(v_etranger);
  SET LOCAL ROLE authenticated;
  v_res := public.demander_amitie(v_membre);               -- Inconnu → Manon
  RESET ROLE;
  SELECT count(*) INTO v_n FROM public.friendships
   WHERE user_id = v_etranger AND friend_id = v_membre AND status = 'pending';
  IF v_n <> 1 THEN RAISE EXCEPTION 'la demande d''ami devait être créée en attente'; END IF;

  PERFORM public.essai_session(v_etranger);                -- le demandeur tente d'accepter
  SET LOCAL ROLE authenticated;
  BEGIN
    v_res := public.accepter_amitie(v_membre);
    RAISE EXCEPTION 'le demandeur a pu accepter sa propre demande';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'aucune_demande' THEN RAISE; END IF;
  END;
  RESET ROLE;

  PERFORM public.essai_session(v_membre);                  -- le destinataire accepte
  SET LOCAL ROLE authenticated;
  v_res := public.accepter_amitie(v_etranger);
  RESET ROLE;
  SELECT status INTO v_role FROM public.friendships WHERE user_id = v_etranger AND friend_id = v_membre;
  IF v_role <> 'accepted' THEN RAISE EXCEPTION 'le destinataire devait pouvoir accepter, statut = %', v_role; END IF;
  RAISE NOTICE '✓ 074 Q1b : demander/accepter une amitié ; seul le destinataire accepte';

  -- ── Q2 colonnes manquantes ────────────────────────────────────────────────────────
  INSERT INTO public.cellars (owner_id, name, wifi_ssid, radius_meters)
  VALUES (v_prop, 'Chez moi', 'Livebox-074', 150);
  SELECT radius_meters INTO v_n FROM public.cellars WHERE owner_id = v_prop AND name = 'Chez moi';
  IF v_n <> 150 THEN RAISE EXCEPTION 'cellars.radius_meters devait valoir 150'; END IF;
  INSERT INTO public.wines (name, user_overrides) VALUES ('Vin 074', '[{"champ":"region","valeur":"Jura"}]'::jsonb);
  SELECT count(*) INTO v_n FROM public.wines WHERE name = 'Vin 074' AND user_overrides @> '[{"champ":"region"}]'::jsonb;
  IF v_n <> 1 THEN RAISE EXCEPTION 'wines.user_overrides devait accepter la valeur'; END IF;
  RAISE NOTICE '✓ 074 Q2 : wines.user_overrides, cellars.wifi_ssid, cellars.radius_meters présentes';

  -- ── Q3 accepter une invitation par code ───────────────────────────────────────────
  INSERT INTO public.cellar_invites (cellar_id, invited_by, invited_email, role, status, invite_code)
  VALUES (v_cave, v_prop, 'link-invite@chatmelier.app', 'viewer', 'pending', 'code074abcdef');
  PERFORM public.essai_session(v_prop2);
  SET LOCAL ROLE authenticated;
  v_json := public.accept_invite_by_code('code074abcdef');
  RESET ROLE;
  IF v_json ->> 'success' IS NULL THEN RAISE EXCEPTION 'accept_invite_by_code a échoué : %', v_json; END IF;
  SELECT count(*) INTO v_n FROM public.cellar_members WHERE cellar_id = v_cave AND user_id = v_prop2;
  IF v_n <> 1 THEN RAISE EXCEPTION 'l''invité devait devenir membre'; END IF;
  SELECT count(*) INTO v_n FROM public.cellar_invites WHERE invite_code = 'code074abcdef' AND status = 'accepted';
  IF v_n <> 1 THEN RAISE EXCEPTION 'l''invitation devait passer à « accepted »'; END IF;
  -- Un code inconnu est refusé proprement (sans exception).
  PERFORM public.essai_session(v_prop2);
  SET LOCAL ROLE authenticated;
  v_json := public.accept_invite_by_code('inexistant');
  RESET ROLE;
  IF v_json ->> 'error' IS NULL THEN RAISE EXCEPTION 'un code inconnu devait renvoyer une erreur'; END IF;
  RAISE NOTICE '✓ 074 Q3 : accept_invite_by_code crée l''appartenance et marque l''invitation';
END $$;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1c — journaux (une règle bornée), stockage (plus de lecture-liste), search_path    ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
DO $$
DECLARE v_n INT;
BEGIN
  -- Une seule politique d'insertion sur les journaux.
  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname = 'public' AND tablename = 'app_diagnostic_logs' AND cmd = 'INSERT';
  IF v_n <> 1 THEN RAISE EXCEPTION 'app_diagnostic_logs devait n''avoir qu''UNE règle d''insertion, il en a %', v_n; END IF;

  -- Un journal normal passe ; un message démesuré est refusé par la borne.
  SET LOCAL ROLE anon;
  INSERT INTO public.app_diagnostic_logs (tag, level, message) VALUES ('STARTUP', 'info', 'démarrage');
  BEGIN
    INSERT INTO public.app_diagnostic_logs (tag, level, message) VALUES ('ABUS', 'info', repeat('x', 8001));
    RAISE EXCEPTION 'un message hors borne aurait dû être refusé';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;

  -- Plus aucune règle de lecture/listage sur labels ou avatars.
  SELECT count(*) INTO v_n FROM pg_policies
   WHERE schemaname = 'storage' AND tablename = 'objects' AND cmd IN ('SELECT', 'ALL')
     AND (coalesce(qual, '') ILIKE '%labels%' OR coalesce(qual, '') ILIKE '%avatars%');
  IF v_n <> 0 THEN RAISE EXCEPTION 'il reste % règle(s) de lecture sur labels/avatars', v_n; END IF;

  -- Les gardiens d'accès ont bien un search_path figé.
  SELECT count(*) INTO v_n FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public'
     AND p.proname IN ('is_cellar_member', 'is_cellar_admin', 'is_cellar_editor_or_admin', 'est_proprietaire_cave')
     AND EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig, '{}')) c WHERE c LIKE 'search_path=%');
  IF v_n <> 4 THEN RAISE EXCEPTION 'les 4 gardiens devaient avoir un search_path figé, % l''ont', v_n; END IF;

  RAISE NOTICE '✓ 074 Q1c : journaux bornés (une règle), lecture-liste retirée, search_path figé';
END $$;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1c — handle_new_user : le prénom seul comme nom par défaut                         ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
-- Le déclencheur n'est pas dans le socle (il ferait doublon avec les essais qui posent
-- caves et appartenances à la main) ; on l'installe juste le temps de cet essai.
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

DO $$
DECLARE
  v_google UUID := '00000000-0000-0000-0000-0000009e0074';
  v_sansnom UUID := '00000000-0000-0000-0000-0000009f0074';
  v_nom    TEXT;
BEGIN
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES (v_google, 'flavien.daussy@gmail.com', '{"name": "Flavien Daussy"}'::jsonb);
  SELECT display_name INTO v_nom FROM public.profiles WHERE id = v_google;
  IF v_nom <> 'Flavien' THEN
    RAISE EXCEPTION 'le nom par défaut devait être le prénom seul « Flavien », pas « % »', v_nom;
  END IF;

  -- Sans nom Google : la partie locale de l'e-mail, jamais « User ».
  INSERT INTO auth.users (id, email, raw_user_meta_data)
  VALUES (v_sansnom, 'belephebe@hotmail.com', '{}'::jsonb);
  SELECT display_name INTO v_nom FROM public.profiles WHERE id = v_sansnom;
  IF v_nom = 'User' THEN RAISE EXCEPTION 'le nom par défaut ne doit jamais être « User »'; END IF;

  RAISE NOTICE '✓ 074 Q1c : nom affiché par défaut = le prénom seul (nom Google complet écarté)';

  -- Ménage (les caves référencent profiles sans ON DELETE).
  DELETE FROM public.cellars WHERE owner_id IN (v_google, v_sansnom);
  DELETE FROM public.profiles WHERE id IN (v_google, v_sansnom);
  DELETE FROM auth.users WHERE id IN (v_google, v_sansnom);
END $$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
