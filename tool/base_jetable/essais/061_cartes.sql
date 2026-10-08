-- Essais de la migration 061 : la carte d'un lieu.
DO $$
BEGIN
  INSERT INTO auth.users (id) VALUES ('61000000-0000-0000-0000-00000000000a'), ('61000000-0000-0000-0000-00000000000b')
    ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id) VALUES ('61000000-0000-0000-0000-00000000000a'), ('61000000-0000-0000-0000-00000000000b')
    ON CONFLICT DO NOTHING;
END $$;

-- 1. Sans session : rien.
SET ROLE authenticated;
SELECT set_config('request.jwt.claims', '{}', false);
DO $$
BEGIN
  BEGIN
    PERFORM * FROM public.cartes_proches(48.8566, 2.3522, 200);
    RAISE EXCEPTION 'une lecture sans session devait être refusée';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'sans_session' THEN RAISE; END IF;
  END;
END $$;

-- 2. A dépose la carte du Petit Zinc, avec ses photos et son identifiant d'appareil.
SELECT set_config('request.jwt.claims', '{"sub":"61000000-0000-0000-0000-00000000000a","role":"authenticated"}', false);
SELECT public.deposer_carte('osm:node/1', ' Le Petit Zinc ', 48.8566, 2.3522,
  '{"id":"local-1","restaurant_name":"Le Petit Zinc","page_photo_paths":["/data/user/0/p1.jpg"],
    "currency":"eur","wines":[{"name":"Morgon","bottle_price":42},{"name":"Chablis","bottle_price":38}]}', 'fr');

-- Refus : lieu sans préfixe, nom vide, carte sans vins.
DO $$
BEGIN
  BEGIN
    PERFORM public.deposer_carte('xyz', 'Bar', 48.85, 2.35, '{"wines":[{"name":"A"}]}');
    RAISE EXCEPTION 'un lieu mal formé devait être refusé';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'lieu_invalide' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.deposer_carte('nom:bar@48.850,2.350', '   ', 48.85, 2.35, '{"wines":[{"name":"A"}]}');
    RAISE EXCEPTION 'un nom vide devait être refusé';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'nom_obligatoire' THEN RAISE; END IF;
  END;
  BEGIN
    PERFORM public.deposer_carte('nom:bar@48.850,2.350', 'Bar', 48.85, 2.35, '{"wines":[]}');
    RAISE EXCEPTION 'une carte sans vin devait être refusée';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'carte_invalide' THEN RAISE; END IF;
  END;
END $$;

-- 3. B, à 13 m : la carte est proposée, sans dire qui l'a déposée.
SELECT set_config('request.jwt.claims', '{"sub":"61000000-0000-0000-0000-00000000000b","role":"authenticated"}', false);
DO $$
DECLARE
  v RECORD;
  n INTEGER;
  c JSONB;
BEGIN
  SELECT count(*) INTO n FROM public.cartes_proches(48.8567, 2.3523, 200);
  IF n <> 1 THEN RAISE EXCEPTION 'une carte attendue à 13 m, % trouvées', n; END IF;
  SELECT * INTO v FROM public.cartes_proches(48.8567, 2.3523, 200);
  IF v.lieu_nom <> 'Le Petit Zinc' OR v.nb_vins <> 2 OR v.devise <> 'EUR' OR v.distance_m NOT BETWEEN 5 AND 30 THEN
    RAISE EXCEPTION 'carte proche inattendue : % % % %', v.lieu_nom, v.nb_vins, v.devise, v.distance_m;
  END IF;
  -- À 1 km, rien dans un rayon de 200 m.
  SELECT count(*) INTO n FROM public.cartes_proches(48.8656, 2.3522, 200);
  IF n <> 0 THEN RAISE EXCEPTION 'aucune carte attendue à 1 km'; END IF;

  c := public.carte_du_lieu('osm:node/1');
  IF c IS NULL OR c -> 'carte' ? 'page_photo_paths' OR c -> 'carte' ? 'id' THEN
    RAISE EXCEPTION 'la carte partagée ne doit porter ni photos ni identifiant d''appareil : %', c;
  END IF;
  IF jsonb_array_length(c -> 'carte' -> 'wines') <> 2 OR c ? 'deposee_par' THEN
    RAISE EXCEPTION 'carte ouverte inattendue : %', c;
  END IF;
END $$;

-- La table elle-même reste fermée.
DO $$
BEGIN
  BEGIN
    PERFORM 1 FROM public.cartes_de_lieux;
    RAISE EXCEPTION 'la table devait être fermée';
  EXCEPTION WHEN insufficient_privilege THEN
    NULL;
  END;
END $$;

-- 4. B rescanne : sa carte remplace l'ancienne, une seule par lieu.
SELECT public.deposer_carte('osm:node/1', 'Le Petit Zinc', 48.8566, 2.3522,
  '{"wines":[{"name":"Morgon"},{"name":"Chablis"},{"name":"Sancerre"}]}', 'en');
DO $$
DECLARE
  v RECORD;
BEGIN
  SELECT * INTO v FROM public.cartes_proches(48.8566, 2.3522, 200);
  IF v.nb_vins <> 3 OR v.devise IS NOT NULL THEN
    RAISE EXCEPTION 'le rescan devait remplacer la carte : % vins, devise %', v.nb_vins, v.devise;
  END IF;
END $$;

-- 5. Une carte de plus de 30 jours n'est plus proposée.
RESET ROLE;
UPDATE public.cartes_de_lieux SET deposee_le = now() - INTERVAL '31 days' WHERE lieu_cle = 'osm:node/1';
SET ROLE authenticated;
DO $$
DECLARE
  n INTEGER;
BEGIN
  SELECT count(*) INTO n FROM public.cartes_proches(48.8566, 2.3522, 200);
  IF n <> 0 OR public.carte_du_lieu('osm:node/1') IS NOT NULL THEN
    RAISE EXCEPTION 'une carte de 31 jours ne doit plus être proposée';
  END IF;
END $$;
RESET ROLE;

DO $$ BEGIN RAISE NOTICE '✓ 061 : cartes des lieux'; END $$;
