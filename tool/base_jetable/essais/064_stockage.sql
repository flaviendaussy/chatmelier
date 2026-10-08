-- Essais de la migration 064 : les photos ne s'écrivent que chez soi.
INSERT INTO storage.objects (bucket_id, name, owner) VALUES
  ('labels', '64000000-0000-0000-0000-00000000000b/bouteille.jpg', '64000000-0000-0000-0000-00000000000b');

-- Sans compte : rien.
SET ROLE anon;
SELECT set_config('request.jwt.claims', '{}', false);
DO $$
BEGIN
  BEGIN
    INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', 'nimporte/quoi.html');
    RAISE EXCEPTION 'un dépôt sans compte devait être refusé';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  DELETE FROM storage.objects WHERE bucket_id = 'labels';
  IF NOT EXISTS (SELECT 1 FROM storage.objects WHERE name LIKE '64000000-0000-0000-0000-00000000000b/%') THEN
    RAISE EXCEPTION 'un visiteur sans compte a effacé une photo';
  END IF;
END $$;
RESET ROLE;

-- A, connecté : chez soi oui, chez B non.
SET ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"64000000-0000-0000-0000-00000000000a","role":"authenticated"}', false);
DO $$
DECLARE
  n INTEGER;
BEGIN
  INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', '64000000-0000-0000-0000-00000000000a/ma-bouteille.jpg');
  INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', 'avatars/avatar_64000000-0000-0000-0000-00000000000a_1.jpg');
  BEGIN
    INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', '64000000-0000-0000-0000-00000000000b/faux.jpg');
    RAISE EXCEPTION 'A ne devait pas déposer chez B';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  BEGIN
    INSERT INTO storage.objects (bucket_id, name) VALUES ('labels', 'avatars/avatar_64000000-0000-0000-0000-00000000000b_1.jpg');
    RAISE EXCEPTION 'A ne devait pas déposer l''avatar de B';
  EXCEPTION WHEN insufficient_privilege THEN NULL;
  END;
  DELETE FROM storage.objects WHERE name LIKE '64000000-0000-0000-0000-00000000000b/%';
  UPDATE storage.objects SET name = name || '.x' WHERE name LIKE '64000000-0000-0000-0000-00000000000b/%';
  SELECT count(*) INTO n FROM storage.objects WHERE name = '64000000-0000-0000-0000-00000000000b/bouteille.jpg';
  IF n <> 1 THEN RAISE EXCEPTION 'A a effacé ou renommé la photo de B'; END IF;
  DELETE FROM storage.objects WHERE name = '64000000-0000-0000-0000-00000000000a/ma-bouteille.jpg';
  SELECT count(*) INTO n FROM storage.objects WHERE name = '64000000-0000-0000-0000-00000000000a/ma-bouteille.jpg';
  IF n <> 0 THEN RAISE EXCEPTION 'A devait pouvoir effacer sa propre photo'; END IF;
END $$;
RESET ROLE;
DO $$ BEGIN RAISE NOTICE '✓ 064 : les photos ne s''écrivent que chez soi'; END $$;
