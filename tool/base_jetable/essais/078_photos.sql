-- Essais de la migration 078 : déposer ses photos en « upsert », sans voir celles des autres ;
-- le format natif accepté.
DO $$
DECLARE
  v_a UUID := '00000000-0000-0000-0000-0000000a0078';
  v_b UUID := '00000000-0000-0000-0000-0000000b0078';
  v_n INTEGER;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_a), (v_b) ON CONFLICT DO NOTHING;

  -- A dépose sa photo d'étiquette comme l'API de stockage le fait pour un upsert, deux fois.
  PERFORM public.essai_session(v_a);
  SET LOCAL ROLE authenticated;
  INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', v_a || '/vin_1.jpg')
  ON CONFLICT (bucket_id, name) DO UPDATE SET owner = EXCLUDED.owner;
  INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', v_a || '/vin_1.jpg')
  ON CONFLICT (bucket_id, name) DO UPDATE SET owner = EXCLUDED.owner;
  INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', 'avatars/avatar_' || v_a || '_1.jpg')
  ON CONFLICT (bucket_id, name) DO UPDATE SET owner = EXCLUDED.owner;
  SELECT count(*) INTO v_n FROM storage.objects;
  IF v_n <> 2 THEN RAISE EXCEPTION 'A voit ses deux fichiers, % vus', v_n; END IF;
  RESET ROLE;
  RAISE NOTICE '✅ 078 : une photo se dépose et se remplace en upsert (étiquette, avatar)';

  -- B ne voit rien des fichiers de A, et ne dépose pas chez A.
  PERFORM public.essai_session(v_b);
  SET LOCAL ROLE authenticated;
  SELECT count(*) INTO v_n FROM storage.objects;
  IF v_n <> 0 THEN RAISE EXCEPTION 'B ne liste pas les fichiers de A (% vus)', v_n; END IF;
  BEGIN
    INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', v_a || '/intrus.jpg');
    RAISE EXCEPTION 'B ne dépose pas chez A';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  RESET ROLE;
  RAISE NOTICE '✅ 078 : personne ne liste ni ne dépose chez les autres';

  -- Le format natif.
  INSERT INTO public.ad_impressions (event_id, occurred_at, platform, app_version, build_mode, ad_format, placement)
  VALUES (gen_random_uuid(), now(), 'android', '1.14.0+87', 'release', 'native', 'journal');
  RAISE NOTICE '✅ 078 : une impression « native » est acceptée';
END $$;
