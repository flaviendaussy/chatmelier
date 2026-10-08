-- Essais de la migration 065 : le revenu réel de chaque pub.
DO $$
DECLARE
  v_admin UUID := '00000000-0000-0000-0000-0000000000ad';
  v_caro  UUID := '00000000-0000-0000-0000-00000000ca70';
  v_imp   UUID := '65000000-0000-0000-0000-000000000001';
  v_json  JSONB;
  v_n     INTEGER;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_admin), (v_caro) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name, is_admin) VALUES (v_admin, 'Flavien', true), (v_caro, 'Caro', false)
  ON CONFLICT (id) DO UPDATE SET is_admin = EXCLUDED.is_admin, display_name = EXCLUDED.display_name;
  INSERT INTO public.app_config (cle, valeur) VALUES ('ecpm_eur_estime', '{"rewarded": 8, "app_open": 5}')
  ON CONFLICT (cle) DO UPDATE SET valeur = EXCLUDED.valeur;
  DELETE FROM public.app_config WHERE cle = 'taux_de_change';

  -- Caro voit une vidéo : l'impression, puis son paiement (0,006 €), comme l'app les envoie.
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  INSERT INTO public.ad_impressions (event_id, occurred_at, platform, app_version, build_mode, ad_format, placement)
  VALUES (v_imp, now(), 'android', '1.8.0+79', 'release', 'rewarded', 'scan_carte');
  INSERT INTO public.ad_revenus (event_id, impression_id, occurred_at, platform, app_version, build_mode, ad_format,
                                 placement, valeur_micros, devise, precision_type)
  VALUES ('65000000-0000-0000-0000-000000000002', v_imp, now(), 'android', '1.8.0+79', 'release', 'rewarded',
          'scan_carte', 6000, 'EUR', 'precise')
  ON CONFLICT (event_id) DO NOTHING;
  -- Le même paiement renvoyé après une coupure ne compte pas deux fois.
  INSERT INTO public.ad_revenus (event_id, impression_id, occurred_at, platform, build_mode, ad_format, placement,
                                 valeur_micros, devise, precision_type)
  VALUES ('65000000-0000-0000-0000-000000000002', v_imp, now(), 'android', 'release', 'rewarded', 'scan_carte',
          6000, 'EUR', 'precise')
  ON CONFLICT (event_id) DO NOTHING;
  -- Elle relit ses lignes (l'envoi par lots en a besoin), pas celles des autres.
  SELECT count(*) INTO v_n FROM public.ad_revenus;
  IF v_n <> 1 THEN RAISE EXCEPTION 'Caro devait relire son seul paiement, pas %', v_n; END IF;
  -- Personne n'écrit au nom d'un autre.
  BEGIN
    INSERT INTO public.ad_revenus (event_id, user_id, occurred_at, platform, build_mode, ad_format, placement,
                                   valeur_micros, devise, precision_type)
    VALUES (gen_random_uuid(), v_admin, now(), 'android', 'release', 'rewarded', 'x', 1, 'EUR', 'precise');
    RAISE EXCEPTION 'Caro ne doit pas écrire un paiement au nom de Flavien';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  -- Un montant absurde ou une devise mal écrite sont refusés.
  BEGIN
    INSERT INTO public.ad_revenus (event_id, occurred_at, platform, build_mode, ad_format, placement, valeur_micros,
                                   devise, precision_type)
    VALUES (gen_random_uuid(), now(), 'android', 'release', 'rewarded', 'x', 500000000, 'EUR', 'precise');
    RAISE EXCEPTION 'un paiement de 500 € par impression devait être refusé';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  BEGIN
    INSERT INTO public.ad_revenus (event_id, occurred_at, platform, build_mode, ad_format, placement, valeur_micros,
                                   devise, precision_type)
    VALUES (gen_random_uuid(), now(), 'android', 'release', 'rewarded', 'x', 10, 'euro', 'precise');
    RAISE EXCEPTION 'une devise mal écrite devait être refusée';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
  -- La console lui est fermée.
  BEGIN
    PERFORM public.admin_revenus_pub(30, false);
    RAISE EXCEPTION 'Caro ne doit pas lire les revenus';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'reserve_admin' THEN RAISE; END IF;
  END;
  RESET ROLE;
  RAISE NOTICE '✓ 065 : chacun écrit et relit ses paiements, rien d''absurde, la console fermée';

  -- Un paiement en livres, sans taux connu : montré à part, hors du total en euros.
  INSERT INTO public.ad_revenus (event_id, user_id, occurred_at, platform, build_mode, ad_format, placement,
                                 valeur_micros, devise, precision_type)
  VALUES ('65000000-0000-0000-0000-000000000003', v_caro, now(), 'android', 'release', 'app_open', 'ouverture',
          3000, 'GBP', 'estimated');
  -- Et un essai sur émulateur, exclu par défaut.
  INSERT INTO public.ad_revenus (event_id, user_id, occurred_at, platform, build_mode, ad_format, placement,
                                 valeur_micros, devise, precision_type)
  VALUES ('65000000-0000-0000-0000-000000000004', v_caro, now(), 'android', 'debug', 'rewarded', 'scan_carte',
          9000, 'EUR', 'precise');

  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  v_json := public.admin_revenus_pub(30, false);
  RESET ROLE;
  IF (v_json ->> 'paiements')::int <> 2 THEN RAISE EXCEPTION 'deux paiements en release attendus : %', v_json; END IF;
  IF (v_json ->> 'revenu_eur')::numeric <> 0.006 THEN
    RAISE EXCEPTION 'revenu en euros : 0,006 attendu (les livres sans taux restent à part) : %', v_json ->> 'revenu_eur';
  END IF;
  IF NOT (v_json -> 'par_devise') @> '[{"devise": "GBP", "converti": false}]'::jsonb THEN
    RAISE EXCEPTION 'les livres doivent apparaître à part, non converties : %', v_json -> 'par_devise';
  END IF;
  -- (d'autres essais ont laissé des impressions : on ne compte que les paiements)
  IF NOT (v_json -> 'par_format') @> '[{"format": "rewarded", "paiements": 1, "ecpm_reel_eur": 6.0, "ecpm_estime_eur": 8}]'::jsonb THEN
    RAISE EXCEPTION 'eCPM réel du rewarded : 6 € attendus, face aux 8 estimés : %', v_json -> 'par_format';
  END IF;

  -- Avec un taux pour la livre, elle entre dans le total.
  INSERT INTO public.app_config (cle, valeur) VALUES ('taux_de_change', '{"GBP": 1.2}');
  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  v_json := public.admin_revenus_pub(30, false);
  RESET ROLE;
  IF (v_json ->> 'revenu_eur')::numeric <> 0.0096 THEN
    RAISE EXCEPTION 'avec 1 £ = 1,2 € : 0,0096 € attendus : %', v_json ->> 'revenu_eur';
  END IF;
  DELETE FROM public.app_config WHERE cle = 'taux_de_change';

  -- Les durées : un paiement de plus de 400 jours part avec la purge.
  INSERT INTO public.ad_revenus (event_id, user_id, occurred_at, platform, build_mode, ad_format, placement,
                                 valeur_micros, devise, precision_type)
  VALUES ('65000000-0000-0000-0000-000000000005', v_caro, now() - INTERVAL '401 days', 'android', 'release',
          'rewarded', 'scan_carte', 5000, 'EUR', 'precise');
  v_json := public.purger_selon_les_durees();
  IF (v_json ->> 'revenus_pub')::int <> 1 THEN RAISE EXCEPTION 'la purge devait retirer le vieux paiement : %', v_json; END IF;

  DELETE FROM public.ad_revenus WHERE event_id::text LIKE '65000000-%';
  DELETE FROM public.ad_impressions WHERE event_id = v_imp;
  RAISE NOTICE '✓ 065 : revenu réel, eCPM face à l''estimé, devises sans taux à part, purge à 400 jours';
END $$;
