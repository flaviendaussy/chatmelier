-- Essais de la migration 060 : la console (réglages, retours suivis, courbes, détails).
DO $$
DECLARE
  v_admin UUID := '00000000-0000-0000-0000-0000000000ad';
  v_caro  UUID := '00000000-0000-0000-0000-00000000ca70';
  v_log   UUID;
  v_json  JSONB;
  v_n     INTEGER;
  v_txt   TEXT;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_admin), (v_caro) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name, is_admin) VALUES (v_admin, 'Flavien', true), (v_caro, 'Caro', false)
  ON CONFLICT (id) DO UPDATE SET is_admin = EXCLUDED.is_admin, display_name = EXCLUDED.display_name;

  -- La forme des réglages
  IF public.reglage_invalide('scan_etiquette_recherche', 'true') IS NOT NULL THEN RAISE EXCEPTION 'un booléen est un booléen'; END IF;
  IF public.reglage_invalide('scan_etiquette_recherche', '"oui"') IS NULL THEN RAISE EXCEPTION 'un texte n''est pas un booléen'; END IF;
  IF public.reglage_invalide('modeles_ia', '{"chat": {"modele": "flash", "reflexion": "low"}, "recit": {"modele": "gemini-3.8-flash", "reflexion": null}}') IS NOT NULL THEN
    RAISE EXCEPTION 'famille, nom exact et réflexion vide sont acceptés';
  END IF;
  IF public.reglage_invalide('modeles_ia', '{"chat": {"modele": "Flash; DROP", "reflexion": "low"}}') IS NULL
     OR public.reglage_invalide('modeles_ia', '{"chat": {"modele": "flash", "reflexion": "max"}}') IS NULL THEN
    RAISE EXCEPTION 'un modèle mal formé ou une réflexion inconnue sont refusés';
  END IF;
  IF public.reglage_invalide('quotas_ia', '{"chat": {"compte": -1, "anonyme": 5}}') IS NULL THEN RAISE EXCEPTION 'quota négatif refusé'; END IF;
  IF public.reglage_invalide('version_minimale_test', '{"build": 77, "lien": "https://play.google.com/x"}') IS NOT NULL
     OR public.reglage_invalide('version_minimale_test', '{"build": 77.5, "lien": "https://x"}') IS NULL
     OR public.reglage_invalide('version_minimale_test', '{"build": 77, "lien": "http://x"}') IS NULL THEN
    RAISE EXCEPTION 'version minimale : build entier et lien https';
  END IF;
  IF public.reglage_invalide('ecpm_eur_estime', '{"rewarded": 8.5}') IS NOT NULL
     OR public.reglage_invalide('ecpm_eur_estime', '{"rewarded": 900}') IS NULL THEN RAISE EXCEPTION 'eCPM borné'; END IF;
  IF public.reglage_invalide('cle_inconnue', 'true') IS NULL THEN RAISE EXCEPTION 'réglage hors liste refusé'; END IF;
  RAISE NOTICE '✓ un réglage n''est accepté que dans sa forme';

  -- Un non-admin n'entre pas
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.admin_reglages();
    RAISE EXCEPTION 'Caro ne doit pas lire les réglages';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'reserve_admin' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.admin_regler('scan_etiquette_recherche', 'true');
    RAISE EXCEPTION 'Caro ne doit pas régler';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'reserve_admin' THEN RAISE; END IF;
  END;
  RESET ROLE;
  RAISE NOTICE '✓ la console est fermée à qui n''est pas administrateur';

  -- L'admin règle, et c'est journalisé
  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  PERFORM public.admin_regler('scan_etiquette_recherche', 'true');
  PERFORM public.admin_regler('scan_etiquette_recherche', 'true');  -- même valeur : rien de plus au journal
  BEGIN
    PERFORM public.admin_regler('quotas_ia', '{"chat": {"compte": -3, "anonyme": 1}}');
    RAISE EXCEPTION 'un quota négatif devait être refusé';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'reglage_invalide%' THEN RAISE; END IF;
  END;
  v_json := public.admin_reglages();
  RESET ROLE;
  IF (SELECT valeur FROM public.app_config WHERE cle = 'scan_etiquette_recherche') <> 'true'::jsonb THEN
    RAISE EXCEPTION 'le réglage n''a pas été écrit';
  END IF;
  IF (SELECT count(*) FROM public.journal_des_reglages WHERE cle = 'scan_etiquette_recherche') <> 1 THEN
    RAISE EXCEPTION 'un changement, une ligne de journal';
  END IF;
  IF v_json -> 'reglages' -> 'scan_etiquette_recherche' ->> 'valeur' <> 'true'
     OR jsonb_array_length(v_json -> 'journal') < 1
     OR v_json -> 'journal' -> 0 ->> 'par' IS NULL THEN
    RAISE EXCEPTION 'admin_reglages rend les valeurs et le journal (qui, quand) : %', v_json;
  END IF;
  RAISE NOTICE '✓ un réglage changé depuis la console est écrit et journalisé (qui, avant, après)';

  -- Les retours suivis
  INSERT INTO public.app_diagnostic_logs (user_id, platform, app_version, tag, level, message, metadata, created_at)
  VALUES (v_caro, 'iOS', '1.6.0+76', 'USER_FEEDBACK', 'info',
          'Commentaire: préviens avant cet écran que c''est le tour de Caro | Capture: ' || v_caro || '/abc.png | Annotations: oui',
          '{"utc_offset_min": 120}', now() - interval '1 hour')
  RETURNING id INTO v_log;
  INSERT INTO public.app_diagnostic_logs (user_id, platform, app_version, tag, level, message, created_at)
  VALUES (v_caro, 'iOS', '1.6.0+76', 'USER_FEEDBACK', 'info', 'Commentaire: ajoute une option neutre | Capture: aucune | Annotations: non', now());

  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  SELECT r.commentaire INTO v_txt FROM public.admin_retours(30) r WHERE r.id = v_log;
  IF v_txt <> 'préviens avant cet écran que c''est le tour de Caro' THEN RAISE EXCEPTION 'commentaire mal découpé : %', v_txt; END IF;
  IF (SELECT r.capture FROM public.admin_retours(30) r WHERE r.id = v_log) <> v_caro || '/abc.png' THEN RAISE EXCEPTION 'capture mal lue'; END IF;
  IF (SELECT r.capture FROM public.admin_retours(30) r WHERE r.commentaire = 'ajoute une option neutre') IS NOT NULL THEN
    RAISE EXCEPTION '« aucune » capture se lit nulle';
  END IF;
  IF (SELECT r.statut FROM public.admin_retours(30) r WHERE r.id = v_log) <> 'a_traiter' THEN RAISE EXCEPTION 'un retour neuf est à traiter'; END IF;
  PERFORM public.admin_suivre_retour(v_log, 'en_cours', 'annonce du premier convive');
  PERFORM public.admin_suivre_retour(v_log, 'resolu');  -- sans note : la note reste
  IF (SELECT r.statut || ' / ' || r.note FROM public.admin_retours(30) r WHERE r.id = v_log) <> 'resolu / annonce du premier convive' THEN
    RAISE EXCEPTION 'statut et note mal suivis';
  END IF;
  PERFORM public.admin_suivre_retour(v_log, 'resolu', '');  -- vide : la note s'efface
  IF (SELECT r.note FROM public.admin_retours(30) r WHERE r.id = v_log) IS NOT NULL THEN RAISE EXCEPTION 'la note vide efface'; END IF;
  BEGIN
    PERFORM public.admin_suivre_retour(v_log, 'oublie');
    RAISE EXCEPTION 'un statut inconnu devait être refusé';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM NOT LIKE 'statut_inconnu%' THEN RAISE; END IF;
  END;
  RESET ROLE;
  RAISE NOTICE '✓ un retour se suit : à traiter, en cours, résolu, avec sa note';

  -- Erreurs jour par jour, occurrences, versions
  INSERT INTO public.app_diagnostic_logs (user_id, platform, app_version, tag, level, message, created_at) VALUES
    (v_caro, 'iOS', '1.6.0+76', 'MENU_SCAN', 'error', 'scan-menu HTTP 500 : erreur 123', now()),
    (v_caro, 'iOS', '1.6.0+76', 'MENU_SCAN', 'error', 'scan-menu HTTP 500 : erreur 456', now() - interval '1 day'),
    (v_admin, 'android', '1.6.0+74', 'NEARBY_PLACES', 'warning', 'Overpass fetch error', now()),
    (v_caro, 'web', 'dev', 'SYSTEM', 'info', 'lancement', now() - interval '3 days');
  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  SELECT sum(e.erreurs) INTO v_n FROM public.admin_erreurs_par_jour(7) e;
  IF v_n <> 2 THEN RAISE EXCEPTION 'deux erreurs sur la semaine, pas %', v_n; END IF;
  SELECT count(*) INTO v_n FROM public.admin_occurrences('MENU_SCAN', public.forme_du_message('scan-menu HTTP 500 : erreur 789'), 7);
  IF v_n <> 2 THEN RAISE EXCEPTION 'les deux occurrences de même forme, pas %', v_n; END IF;
  SELECT string_agg(v.plateforme || ' ' || v.version || ' ×' || v.personnes, ', ' ORDER BY v.plateforme, v.version) INTO v_txt
    FROM public.admin_versions(30) v;
  RESET ROLE;
  IF v_txt <> 'android 1.6.0+74 ×1, iOS 1.6.0+76 ×1, web dev ×1' THEN
    RAISE EXCEPTION 'la dernière version de chacun, par plateforme : %', v_txt;
  END IF;
  RAISE NOTICE '✓ erreurs jour par jour, occurrences d''une erreur, versions installées';

  -- L'économie, jour par jour et par modèle (d'autres essais ont déjà écrit des appels :
  -- on compte ce que les nôtres ajoutent).
  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  SELECT coalesce(sum((m ->> 'appels')::int), 0) INTO v_n
    FROM jsonb_array_elements(public.admin_economie_detail(7, false) -> 'par_modele') m;
  RESET ROLE;
  INSERT INTO public.ai_cost_events (event_id, user_id, occurred_at, platform, build_mode, feature, model, prompt_tokens, output_tokens, grounded, cost_usd, cost_eur) VALUES
    (gen_random_uuid(), v_caro, now(), 'ios', 'release', 'menu_scan_vision', 'gemini-3.5-flash-lite', 1600, 260, false, 0.001, 0.001),
    (gen_random_uuid(), v_caro, now(), 'ios', 'release', 'scan_vision', 'gemini-3.8-flash', 1442, 234, false, 0.002, 0.002),
    (gen_random_uuid(), v_caro, now(), 'ios', 'release', 'scan_enrichment', 'gemini-3.8-flash', 231, 379, false, 0.0015, 0.0015),
    (gen_random_uuid(), v_caro, now(), 'ios', 'debug', 'chat', 'gemini-3.8-flash', 2000, 200, false, 0.002, 0.002);
  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  v_json := public.admin_economie_detail(7, false);
  RESET ROLE;
  IF jsonb_array_length(v_json -> 'par_jour') < 7 THEN RAISE EXCEPTION 'un point par jour, même vide'; END IF;
  IF (SELECT sum((m ->> 'appels')::int) FROM jsonb_array_elements(v_json -> 'par_modele') m) <> v_n + 3 THEN
    RAISE EXCEPTION 'les essais en debug ne comptent pas : %', v_json -> 'par_modele';
  END IF;
  IF (SELECT (j ->> 'etiquette_moyen_eur') IS NULL FROM jsonb_array_elements(v_json -> 'par_jour') j WHERE (j ->> 'jour')::date = now()::date) THEN
    RAISE EXCEPTION 'le coût d''une étiquette (lecture et description) du jour';
  END IF;
  RAISE NOTICE '✓ l''économie jour par jour et par modèle, sans les essais';
END $$;
