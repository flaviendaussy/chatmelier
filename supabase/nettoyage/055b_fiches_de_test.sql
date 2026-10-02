-- 055b — Les fiches de test et les produits qui ne sont pas du vin, dans le catalogue partagé
--
-- À LANCER À LA MAIN, APRÈS RELECTURE (SQL Editor). Ce n'est pas une migration : une
-- suppression ne se décide pas pour quelqu'un.
--
-- Relevé le 30/09 en relisant les 212 fiches du catalogue : des essais de développement
-- (« Château Grand Vin » de « Domaine Vigneron » en 2026, « Saisie Vocale », un « Chablis
-- Grand Cru » rouge de Bordeaux, quinze « Domaine Inconnu ») et deux produits qui ne sont
-- pas du vin, classés « vin blanc » (une huile d'olive, un condiment à la truffe). Le
-- catalogue sert à tous : ces fiches peuvent sortir en réponse au scan de quelqu'un d'autre.
--
-- Une fiche n'est supprimée que si AUCUNE bouteille, photo ou dégustation n'y renvoie.
-- Les autres restent, et l'étape 1 dit lesquelles et pourquoi. Vérifié en production le
-- 02/10 : ces trois tables sont les seules à pointer vers wines (clés en NO ACTION, aucune
-- cascade), et aucun déclencheur ne s'exécute à la suppression.

-- 1. Aperçu : ce qui partirait, et ce qui reste parce que quelqu'un s'en sert.
WITH cibles(id) AS (VALUES
  ('c24da511-93df-49bb-813f-a97daa5866fc'::uuid), ('20fa1406-554f-42b6-9158-d0d604d37a7a'),  -- Château Grand Vin / Domaine Vigneron 2026
  ('2cd7feac-c1cf-4c29-8b96-b1d909cb07c3'),  -- Chablis Grand Cru, rouge, Bordeaux
  ('07571146-9b48-455b-89eb-744fa8a2d7c9'), ('c0f0a272-890e-41de-87cc-e867ff5cccc1'),  -- producteur « Saisie Vocale »
  ('aa967c11-691a-4282-9242-3acb50a7790d'),  -- producteur « Appellation Chablis Grand Cru »
  ('08d97ce8-01a3-4d5b-98cb-28b69bcde875'),  -- « BordeauxFranceMargaux »
  ('57e1648c-79ce-43a5-9d11-5947f867ad61'),  -- Château Margaux 2015 vide (doublon)
  ('0e45e2b7-2e1e-4dea-993b-fbb7824b6c49'),  -- Brut Chardonnay / « Domaine inconnu »
  ('a5db63c5-3ca8-4f0c-a706-2bff072f8871'), ('68f22a4f-2d03-479b-a712-ccc3dafe7524'),
  ('cc2ed41a-3fb2-412c-8ea6-db031b408fe9'), ('1b28c03d-8ccc-461c-8bb9-5306e3de6f77'),
  ('d7534765-74b6-4aee-bfb5-f6fb53e65543'), ('b1b3a83f-134b-49e5-a3b2-5e8af32838e5'),
  ('2283ce68-86a0-4e28-a22e-b9ad30ca6d6f'), ('bd1759a4-df4d-4128-a267-c7e3bb1aba62'),
  ('02835995-8e5b-44bc-858c-7b156976975e'), ('e0c49364-bd00-4a10-aef3-0dec14929bfe'),
  ('a3968bf4-daf3-4d45-8879-6d45ed8e6f21'), ('10080554-9dda-4150-9a17-6948b0bf38a7'),
  ('7728de33-d6ca-4074-a738-3a05b9e1d313'), ('727e7626-b61a-4e6d-8d6a-b970ad24d77c'),
  ('e90286f3-1690-47da-8d8d-a2aea053d26a'),  -- quinze « Domaine Inconnu », Bordeaux 2007-2012
  ('6560778f-3958-4c04-9228-bfa277b4c094'),  -- « Lalande de pomerol » de « Lalande de pomerol »
  ('dd220c0e-47e5-4519-9cb0-ad1f88295548'), ('f4eccf15-a3fe-4aa2-81fd-94488942c1e5'),  -- condiment à la truffe
  ('c46ec8ef-3167-48a2-a771-c3ee5ded459d'), ('40040fc1-35e5-4059-bf62-7c5ac2dad80f')   -- huile d'olive
)
SELECT CASE WHEN bouteilles + photos + degustations = 0 THEN 'partira' ELSE 'reste (utilisée)' END AS sort,
       id, name, producer, vintage, bouteilles, photos, degustations
FROM (
  SELECT w.id, w.name, w.producer, w.vintage,
         (SELECT count(*) FROM public.bottles b WHERE b.wine_id = w.id)       AS bouteilles,
         (SELECT count(*) FROM public.bottle_photos p WHERE p.wine_id = w.id) AS photos,
         (SELECT count(*) FROM public.tasting_log t WHERE t.wine_id = w.id)   AS degustations
  FROM public.wines w JOIN cibles c ON c.id = w.id
) f
ORDER BY sort, name;

-- 2. La suppression : supabase/nettoyage/055b_suppression.sql, la même liste, à lancer
--    seule, après avoir lu cet aperçu. Elle ne supprime que les lignes « partira ».
