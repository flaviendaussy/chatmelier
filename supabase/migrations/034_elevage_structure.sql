-- Migration 034 : l'élevage, sous forme exploitable
--
-- CONTEXTE
-- `Wine` portait déjà `barrelAging`, écrit en `barrel_aging` — mais en TEXTE LIBRE
-- (« 18 à 24 mois en barriques »), donc inexploitable pour raisonner. Et vérifié sur
-- 79 vins réels d'un utilisateur : le champ est renseigné ZÉRO fois. Deux raisons qui se
-- cumulent — aucune migration ne crée la colonne, et l'enrichissement ne la remplit pas.
--
-- On ajoute donc les deux colonnes structurées, plus `barrel_aging` lui-même s'il
-- manque : le client l'écrit depuis longtemps, autant que l'écriture aboutisse.

ALTER TABLE public.wines
  ADD COLUMN IF NOT EXISTS barrel_aging TEXT,
  ADD COLUMN IF NOT EXISTS elevage_type TEXT
    CHECK (elevage_type IS NULL OR elevage_type IN
      ('inox', 'beton', 'barrique', 'foudre', 'amphore', 'oeuf', 'bouteille')),
  ADD COLUMN IF NOT EXISTS elevage_months SMALLINT
    CHECK (elevage_months IS NULL OR (elevage_months >= 0 AND elevage_months <= 600));

COMMENT ON COLUMN public.wines.elevage_type IS
  'Contenant d''élevage. Le matériau change le vin plus que la durée : douze mois en '
  'barrique neuve marquent davantage que vingt-quatre en foudre.';

COMMENT ON COLUMN public.wines.elevage_months IS
  'Durée d''élevage en mois. Quand l''appellation impose un minimum (Barolo 18, Brunello '
  '24, Rioja Crianza 12), c''est ce minimum qui est renseigné par défaut : c''est un fait '
  'du cahier des charges, pas une estimation.';

-- ─────────────────────────────────────────────────────────────────────────────
-- Pas de remplissage ici, et c'est délibéré
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Les valeurs par défaut viennent d'une table de 90 régions écrite en Dart. La porter en
-- SQL créerait une seconde implémentation qui divergerait dès la première correction —
-- la même dette qu'on vient de retirer en unifiant les calculs d'apogée.
--
-- Le remplissage est donc fait par l'app au chargement de la cave, avec le vrai code
-- (`ElevageBackfill`). `wines` étant un catalogue partagé, une fiche complétée pour une
-- personne l'est pour toutes celles qui scanneront le même vin.

CREATE INDEX IF NOT EXISTS idx_wines_elevage ON public.wines (elevage_type)
  WHERE elevage_type IS NOT NULL;
