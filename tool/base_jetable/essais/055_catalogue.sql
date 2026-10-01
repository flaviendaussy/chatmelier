-- Essais de la migration 055, sur des fiches qui reproduisent celles de la production.
-- La migration a déjà tourné (sur un catalogue vide) : on insère les fiches fausses, on la
-- rejoue, et on vérifie qu'elle corrige sans écraser ce qui a été corrigé entre-temps.
INSERT INTO public.wines (id, name, producer, vintage, wine_type, appellation, elevage_type, elevage_months, is_verified_online,
                          ideal_drinking_start, ideal_drinking_end, peak_drinking_start, peak_drinking_end, grapes) VALUES
 ('d8c1f15e-aacb-48e7-a7ea-c697c0ed9029', 'Meursault Premier Cru Les Charmes', 'Domaine des Comtes Lafon', 2020, 'white', NULL, 'inox', 8, false, 2022, 2037, 2024, 2031, '[]'),
 ('0ee7fd41-9a7f-40ed-8128-2a1ee588ec9b', 'Gran Reserva 904', 'La Rioja Alta S.A.', 2016, 'red', 'Rioja DOCa', 'barrique', 12, false, 2024, 2045, 2026, 2038, '[]'),
 ('bbae9889-1eac-4619-8578-aa5fabfa0681', 'Clio', 'Bodegas El Nido', 2023, 'red', 'D.O. Jumilla', 'barrique', 18, true, 2026, 2041, 2029, 2037, '[]'),
 ('e53075b3-fabe-4c54-ad4e-e50e3bb4b825', 'Coste Brune Cuvée Prestige Bandol Rosé', 'Domaine Coste Brune', 2023, 'rosé', 'Bandol', 'inox', 6, false, 2024, 2037, 2026, 2032, '[]'),
 -- Une fiche déjà corrigée à la main : la migration ne doit pas y toucher.
 ('87f6eefd-9862-47f9-9aff-946bd2bbfca1', 'Sarget de Gruaud Larose', 'Château Gruaud Larose', 2019, 'red', 'Saint-Julien', 'barrique', 18, false, 2024, 2035, 2026, 2031, '[]'),
 ('a4ee879a-3031-4c0f-94fa-a44f57eed887', 'Cotswolds Dry Gin', 'Cotswolds Distillery', NULL, 'fortified', 'Gin', NULL, NULL, false, NULL, NULL, NULL, NULL, '[]');
\i supabase/migrations/055_catalogue_corrige.sql
DO $$
DECLARE r RECORD;
BEGIN
  SELECT * INTO r FROM public.wines WHERE id = 'd8c1f15e-aacb-48e7-a7ea-c697c0ed9029';
  IF r.elevage_type <> 'barrique' OR r.elevage_months <> 18 THEN RAISE EXCEPTION 'Meursault : élevage non corrigé'; END IF;
  SELECT * INTO r FROM public.wines WHERE id = '0ee7fd41-9a7f-40ed-8128-2a1ee588ec9b';
  IF r.elevage_months <> 48 THEN RAISE EXCEPTION '904 : durée non corrigée'; END IF;
  SELECT * INTO r FROM public.wines WHERE id = 'bbae9889-1eac-4619-8578-aa5fabfa0681';
  IF r.is_verified_online OR jsonb_array_length(r.grapes) <> 2 THEN RAISE EXCEPTION 'Clio : drapeau ou cépages'; END IF;
  SELECT * INTO r FROM public.wines WHERE id = 'e53075b3-fabe-4c54-ad4e-e50e3bb4b825';
  IF r.ideal_drinking_end <> 2028 THEN RAISE EXCEPTION 'rosé : apogée non corrigée'; END IF;
  SELECT * INTO r FROM public.wines WHERE id = '87f6eefd-9862-47f9-9aff-946bd2bbfca1';
  IF r.ideal_drinking_end <> 2035 THEN RAISE EXCEPTION 'Sarget : une correction manuelle a été écrasée'; END IF;
  SELECT * INTO r FROM public.wines WHERE id = 'a4ee879a-3031-4c0f-94fa-a44f57eed887';
  IF r.wine_type <> 'gin' THEN RAISE EXCEPTION 'gin : type non corrigé'; END IF;
  RAISE NOTICE '✓ les fiches fausses sont corrigées, les corrections manuelles respectées';
END $$;
