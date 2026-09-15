-- Migration 032: échelle de notation explicite et signaux de dégustation
--
-- ⚠️  CETTE MIGRATION NE MODIFIE AUCUNE NOTE EXISTANTE. Elle ajoute la colonne qui
--     permettra de le faire, et la procédure de remplissage est en section 4, à exécuter
--     manuellement APRÈS avoir regardé les données. Voir la raison ci-dessous.
--
-- CONTEXTE
-- La migration 027 a élargi la contrainte de `rating` de ≤5 à ≤10 sans migrer les valeurs.
-- La table contient donc un mélange : les lignes antérieures sont sur 5, les suivantes sur 10.
-- Le client compensait par une heuristique (`tasting_entry.dart:66-70`) qui double toute note
-- ≤ 5 — correcte pour les anciennes lignes, fausse pour les nouvelles :
--
--     saisi 3,5/10 « décevant »   → lu 7,0/10, devient un vin aimé
--     saisi 5,0/10 « quelconque » → lu 10,0/10
--
-- Résultat : toute la moitié basse de l'échelle est repliée sur la moitié haute, et le modèle
-- de goût ne peut apprendre aucun dégoût. C'est le verrou de tout le reste.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. L'échelle devient explicite plutôt que devinée
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS rating_scale SMALLINT NOT NULL DEFAULT 10
    CHECK (rating_scale IN (5, 10));

COMMENT ON COLUMN public.tasting_log.rating_scale IS
  'Échelle sur laquelle `rating` a été saisi. 10 pour tout ce qui est écrit par le client '
  'actuel. 5 pour les lignes antérieures à la migration 027, à corriger via la section 4.';

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Le coup de cœur cesse d'être encodé par une valeur de note
-- ─────────────────────────────────────────────────────────────────────────────
--
-- `external_tasting_dialog.dart:413` écrivait `rating = 5.0` pour signifier « coup de cœur »,
-- indistinguable d'un 5/10 tiède. Deux informations différentes dans le même champ.

ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN NOT NULL DEFAULT FALSE;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Signaux de dégustation qui manquaient au modèle
-- ─────────────────────────────────────────────────────────────────────────────

-- Une dégustation à l'aveugle est la seule note non contaminée par l'étiquette, le prix ou
-- la réputation. Le mode existe dans le questionnaire mais l'information était jetée.
ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS is_blind BOOLEAN NOT NULL DEFAULT FALSE;

-- Défauts du vin. Une bouteille bouchonnée doit être EXCLUE du modèle de goût : sinon
-- l'utilisateur apprend à tort qu'il n'aime pas une région. Aucune notion de défaut
-- n'existait nulle part dans le code.
ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS fault TEXT
    CHECK (fault IS NULL OR fault IN ('cork', 'oxidation', 'reduction', 'other'));

COMMENT ON COLUMN public.tasting_log.fault IS
  'Défaut identifié. Non nul ⇒ la ligne est exclue de l''apprentissage du profil de goût.';

-- Conditions de service : la même bouteille ne donne pas la même chose à 16 °C et à 22 °C.
-- WineServiceAdvisor calcule déjà la recommandation ; on n''enregistrait jamais le réel.
ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS served_temp TEXT
    CHECK (served_temp IS NULL OR served_temp IN ('cold', 'right', 'warm')),
  ADD COLUMN IF NOT EXISTS was_decanted BOOLEAN;

CREATE INDEX IF NOT EXISTS idx_tasting_log_user_consumed
  ON public.tasting_log (user_id, consumed_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. ⚠️  REMPLISSAGE DE L'ÉCHELLE — À FAIRE MANUELLEMENT, APRÈS INSPECTION
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Je ne peux pas deviner à partir de quelle date les notes sont passées sur 10, et me
-- tromper corromprait des données réelles de façon irréversible. La procédure :
--
-- ÉTAPE A — Regarder la distribution, pour repérer la bascule :
--
--   SELECT date_trunc('month', consumed_at) AS mois,
--          count(*)                          AS n,
--          min(rating), max(rating), round(avg(rating), 2) AS moyenne,
--          count(*) FILTER (WHERE rating > 5) AS notes_sup_5
--   FROM public.tasting_log
--   WHERE rating IS NOT NULL
--   GROUP BY 1 ORDER BY 1;
--
-- Le premier mois où `notes_sup_5` devient non nul marque le passage à l'échelle /10.
--
-- ÉTAPE B — Marquer les lignes antérieures, en remplaçant la date :
--
--   UPDATE public.tasting_log
--   SET rating_scale = 5
--   WHERE consumed_at < 'AAAA-MM-JJ'::timestamptz
--     AND rating IS NOT NULL;
--
-- ÉTAPE C — Vérifier avant de considérer l'opération terminée :
--
--   SELECT rating_scale, count(*), min(rating), max(rating)
--   FROM public.tasting_log WHERE rating IS NOT NULL GROUP BY 1;
--
-- Aucune ligne en `rating_scale = 5` ne devrait avoir `rating > 5`.
--
-- Tant que l'étape B n'est pas faite, toutes les lignes sont traitées comme /10 : les
-- anciennes notes sur 5 seront lues deux fois trop basses. C'est un défaut assumé et
-- visible, préférable au défaut inverse — qui, lui, fabrique silencieusement des vins aimés.
