-- 055 — Le catalogue partagé, relu fiche par fiche (30/09)
--
-- Le 30/09, Flavien a vu son Clio (Bodegas El Nido, D.O. Jumilla) présenté comme un vin
-- « au cœur de France », avec un badge « Vérifié ». Ce texte ne venait pas du catalogue
-- (la fiche était juste) mais d'un gabarit de l'app, retiré dans la version 72. La relecture
-- des 212 fiches du catalogue a trouvé d'autres affirmations fausses écrites par l'IA,
-- corrigées ici quand la correction est sûre. Ce qui est douteux mais invérifiable est
-- laissé tel quel et listé en bas.
--
-- Chaque correction ne s'applique que si la fiche porte encore la valeur fausse : une fiche
-- corrigée depuis par quelqu'un n'est pas écrasée, et la migration peut être rejouée.
--
-- Les fiches de test et les produits qui ne sont pas du vin (huile d'olive, condiment) ne
-- sont PAS supprimés ici : voir supabase/nettoyage/055b_fiches_de_test.sql, à lancer à la
-- main après relecture.

-- -----------------------------------------------------------------------------
-- 1. « Vérifié en ligne » : l'app le posait après chaque enrichissement par l'IA, qui ne
--    vérifiait rien. Le drapeau n'est plus écrit par la version 72 ; on l'efface partout.
-- -----------------------------------------------------------------------------
UPDATE public.wines SET is_verified_online = false WHERE is_verified_online IS TRUE;

-- -----------------------------------------------------------------------------
-- 2. Des faits faux
-- -----------------------------------------------------------------------------
-- Meursault 1er Cru Les Charmes, Comtes Lafon 2020 : élevé en fûts de chêne, pas en cuve
-- inox (l'écran de dégustation disait « élevage en cuve inox, sans contact boisé »).
UPDATE public.wines SET elevage_type = 'barrique', elevage_months = 18, appellation = 'Meursault Premier Cru'
 WHERE id = 'd8c1f15e-aacb-48e7-a7ea-c697c0ed9029' AND elevage_type = 'inox';

-- La Rioja Alta Gran Reserva 904 : environ quatre ans en barriques de chêne américain,
-- pas douze mois.
UPDATE public.wines SET elevage_months = 48
 WHERE id = '0ee7fd41-9a7f-40ed-8128-2a1ee588ec9b' AND elevage_months = 12;

-- Cantine del Notaio La Firma : « foudre, 18 mois » n'a aucune source ; on retire l'affirmation.
UPDATE public.wines SET elevage_type = NULL, elevage_months = NULL
 WHERE id = '94cfd926-4da6-4986-aa91-58f66f04416e' AND elevage_type = 'foudre';

-- Velhotes 10 Anos : un tawny de dix ans (âge moyen des vins de l'assemblage), pas
-- « 24 mois de foudre ».
UPDATE public.wines SET elevage_type = NULL, elevage_months = NULL
 WHERE id = '08087038-4fa5-419d-b9e2-26da6506af4c' AND elevage_months = 24;

-- Un pastis et une vodka n'ont pas d'« élevage en cuve inox ».
UPDATE public.wines SET elevage_type = NULL, elevage_months = NULL
 WHERE id IN ('def00f55-acb6-46b3-8dfd-516c8c73c103', '4ea71bfb-4e2c-4dda-92d4-3fa4f1c1b2c0')
   AND elevage_type = 'inox';

-- Clio : les cépages manquaient (monastrell et cabernet-sauvignon).
UPDATE public.wines
   SET grapes = '[{"name":"Monastrell","pct":70},{"name":"Cabernet Sauvignon","pct":30}]'::jsonb
 WHERE id = 'bbae9889-1eac-4619-8578-aa5fabfa0681' AND (grapes IS NULL OR grapes = '[]'::jsonb);

-- Mouton Cadet 1961 : le nom et le producteur étaient inversés.
UPDATE public.wines SET name = 'Mouton Cadet', producer = 'Baron Philippe de Rothschild'
 WHERE id = 'cc2a0cd9-ca4d-48b5-97a5-50ef83afe85c' AND name = 'Baron Philippe de Rothschild';

-- -----------------------------------------------------------------------------
-- 3. Des apogées impossibles
-- -----------------------------------------------------------------------------
-- Des rosés « à garder » jusqu'en 2037-2038.
UPDATE public.wines SET ideal_drinking_start = 2024, ideal_drinking_end = 2028,
                        peak_drinking_start = 2024, peak_drinking_end = 2026
 WHERE id = 'e53075b3-fabe-4c54-ad4e-e50e3bb4b825' AND ideal_drinking_end = 2037;   -- Coste Brune, Bandol rosé 2023
UPDATE public.wines SET ideal_drinking_start = 2025, ideal_drinking_end = 2028,
                        peak_drinking_start = 2025, peak_drinking_end = 2027
 WHERE id = '3b0fe90d-2792-456b-9aa2-e68346005740' AND ideal_drinking_end = 2038;   -- Domaine de la Garenne, Bandol rosé 2024

-- So Sauternes 2022 : une cuvée conçue pour être bue jeune, pas jusqu'en 2072.
UPDATE public.wines SET ideal_drinking_start = 2024, ideal_drinking_end = 2032,
                        peak_drinking_start = 2025, peak_drinking_end = 2029,
                        elevage_type = NULL, elevage_months = NULL
 WHERE id = '4ca6c4b5-24ef-47d3-ab34-9dec19e5aae9' AND ideal_drinking_end = 2072;

-- Sarget de Gruaud Larose 2019 : le second vin, pas un premier cru de très longue garde.
UPDATE public.wines SET ideal_drinking_start = 2024, ideal_drinking_end = 2036,
                        peak_drinking_start = 2026, peak_drinking_end = 2032
 WHERE id = '87f6eefd-9862-47f9-9aff-946bd2bbfca1' AND ideal_drinking_end = 2072;

-- Des rouges de coopérative ou de village donnés pour vingt à trente ans.
UPDATE public.wines SET ideal_drinking_start = 2023, ideal_drinking_end = 2030,
                        peak_drinking_start = 2024, peak_drinking_end = 2028
 WHERE id = '8e4815da-6abf-4269-9c2a-6bf15dae8af4' AND ideal_drinking_end = 2051;   -- Réserve des Hospitaliers, Cairanne 2021
UPDATE public.wines SET ideal_drinking_start = 2023, ideal_drinking_end = 2030,
                        peak_drinking_start = 2024, peak_drinking_end = 2027
 WHERE id = '399609b8-d302-46a5-b4e3-a7abb0c7988c' AND ideal_drinking_end = 2046;   -- Cave de Tain Nobles Rives, Crozes-Hermitage 2021
UPDATE public.wines SET ideal_drinking_start = 2025, ideal_drinking_end = 2033,
                        peak_drinking_start = 2027, peak_drinking_end = 2031
 WHERE id = '6cb43936-b955-4515-a8f4-2071778e5639' AND ideal_drinking_end = 2043;   -- Rémy Lefèvre, Chorey-lès-Beaune 2023

-- Un Bandol rouge donné pour trente-quatre ans : la catégorie en tient une vingtaine.
UPDATE public.wines SET ideal_drinking_start = 2024, ideal_drinking_end = 2041,
                        peak_drinking_start = 2027, peak_drinking_end = 2035
 WHERE id = '1bb0d253-bb52-4812-8d78-c548c677ab1b' AND ideal_drinking_end = 2055;   -- Domaine du Paternel, Grande Réserve 2021 (Bandol)

-- Des blancs gardés trop longtemps.
UPDATE public.wines SET ideal_drinking_start = 2023, ideal_drinking_end = 2030,
                        peak_drinking_start = 2024, peak_drinking_end = 2027
 WHERE id = '586a1f9f-6e6e-4014-9268-407ec92546ee' AND ideal_drinking_end = 2042;   -- Château Crabitey, Graves blanc 2022
UPDATE public.wines SET ideal_drinking_start = 2024, ideal_drinking_end = 2030,
                        peak_drinking_start = 2025, peak_drinking_end = 2028
 WHERE id = '2555702d-07e0-42ac-a94e-26020d6e9368' AND ideal_drinking_end = 2039;   -- Cave de Turckheim, Gewurztraminer 2023

-- -----------------------------------------------------------------------------
-- 4. Des types faux : un gin, une liqueur, un pisco, une eau-de-vie ne sont pas des vins
--    mutés. Et un spiritueux n'a pas d'apogée.
-- -----------------------------------------------------------------------------
UPDATE public.wines SET wine_type = 'gin'     WHERE id = 'a4ee879a-3031-4c0f-94fa-a44f57eed887' AND wine_type = 'fortified';  -- Cotswolds Dry Gin
UPDATE public.wines SET wine_type = 'liqueur' WHERE id = '81d482c1-f054-4a12-ae03-fcbf9239f5e6' AND wine_type = 'fortified';  -- Fleur de Lavande
UPDATE public.wines SET wine_type = 'liqueur', ideal_drinking_start = NULL, ideal_drinking_end = NULL,
                        peak_drinking_start = NULL, peak_drinking_end = NULL
 WHERE id = 'fc233686-b03b-4b20-a0b7-2f0ec3bd4334' AND wine_type = 'fortified';                                              -- Italicus
UPDATE public.wines SET wine_type = 'spirit'  WHERE id = '473e180e-4341-4be6-995a-8cff393cfa2c' AND wine_type = 'fortified';  -- Pisco Bou Barroeta
UPDATE public.wines SET wine_type = 'spirit'  WHERE id = '865d5d42-b2f8-4dfc-824d-2751e7d7f87c' AND wine_type = 'fortified';  -- Eau-de-vie de mirabelle
UPDATE public.wines SET ideal_drinking_start = NULL, ideal_drinking_end = NULL
 WHERE id = '7462bc64-f704-469a-8f24-4f958aeb891f' AND ideal_drinking_end = 2040;                                          -- Medronho

-- -----------------------------------------------------------------------------
-- Laissé tel quel, douteux mais invérifiable sans source (à revoir quand la recherche
-- sourcée sera allumée) :
--   · Joël Poutet 2025 « Bordeaux », apogée 2030-2045 (l'autre fiche du même producteur,
--     2024, le place dans le Var avec une apogée 2025-2027) ;
--   · les élevages « inox 8 mois » des rouges de Bourgogne Hautes-Côtes de Nuits
--     (Moillard, Thévenot-Le Brun) ;
--   · Domaine Minjaud, Bandol 2023, apogée jusqu'en 2048 ;
--   · la plupart des fiches n'ont pas de cépages.
--
-- Vérification :
--   SELECT count(*) FROM public.wines WHERE is_verified_online;          → 0
--   SELECT name, elevage_type, elevage_months FROM public.wines
--    WHERE id IN ('d8c1f15e-aacb-48e7-a7ea-c697c0ed9029', '0ee7fd41-9a7f-40ed-8128-2a1ee588ec9b');
--   → Meursault … barrique 18 ; Gran Reserva 904 … barrique 48
