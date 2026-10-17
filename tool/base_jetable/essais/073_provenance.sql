-- Essais de la migration 073 : seule la provenance mise d'office redevient « non dite ».
-- La migration a déjà tourné sur une table vide : on remet les cas, puis on la rejoue.
DO $$
DECLARE
  v_cave UUID;
  v_n    INT;
BEGIN
  INSERT INTO public.cellars (name) VALUES ('London') RETURNING id INTO v_cave;
  INSERT INTO public.bottles (cellar_id, source_type, source_details) VALUES
    (v_cave, 'estate', NULL),       -- jamais choisie : le défaut
    (v_cave, 'estate', 'Domaine'),  -- la pastille touchée
    (v_cave, 'estate', 'Clos Rougeard'),
    (v_cave, 'merchant', NULL),
    (v_cave, 'gift', 'Caro'),
    (v_cave, NULL, NULL);
END $$;

\i supabase/migrations/073_provenance_jamais_choisie.sql

DO $$
DECLARE
  v_n INT;
BEGIN
  SELECT count(*) INTO v_n FROM public.bottles WHERE source_type = 'estate';
  IF v_n <> 2 THEN RAISE EXCEPTION 'deux choix du domaine devaient rester, il en reste %', v_n; END IF;
  SELECT count(*) INTO v_n FROM public.bottles WHERE source_type IS NULL;
  IF v_n <> 2 THEN RAISE EXCEPTION 'deux provenances non dites attendues, % trouvées', v_n; END IF;
  SELECT count(*) INTO v_n FROM public.bottles WHERE source_type IN ('merchant', 'gift');
  IF v_n <> 2 THEN RAISE EXCEPTION 'caviste et cadeau devaient rester, % trouvés', v_n; END IF;
  RAISE NOTICE '✓ 073 : seule la provenance mise d''office redevient « non dite »';
END $$;
