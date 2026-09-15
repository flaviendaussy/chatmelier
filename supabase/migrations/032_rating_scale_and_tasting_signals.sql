-- Migration 032: échelle de notation explicite et signaux de dégustation
--
-- ═══════════════════════════════════════════════════════════════════════════════
-- CE QUE CETTE MIGRATION CORRIGE, ET POURQUOI C'EST PLUS GRAVE QUE PRÉVU
-- ═══════════════════════════════════════════════════════════════════════════════
--
-- La migration 027 devait élargir `rating` de NUMERIC(2,1) CHECK (<= 5) à
-- NUMERIC(3,1) CHECK (<= 10). Elle n'a JAMAIS été appliquée en production — comme 023
-- et comme les cinq colonnes que 031 a dû rattraper. La contrainte ≤ 5 tient donc
-- toujours, et toutes les interfaces de saisie de l'app sont sur 10
-- (Slider min:1 max:10 divisions:18, pas de 0,5 — questionnaire, dégustation externe,
-- checkout, mode table).
--
-- Conséquence : à chaque enregistrement, l'insert est rejeté par la contrainte, et le
-- client retombe sur un dernier recours qui DIVISE LA NOTE PAR DEUX pour la faire
-- passer. Toutes les notes en base sont donc à l'échelle /5, silencieusement.
--
-- Vérifié sur les données réelles du journal (3 entrées) :
--
--     curseur 5,5/10 → rejet → 5,5÷2 = 2,75 → NUMERIC(2,1) arrondit → 2,8 en base
--     curseur 7,0/10 → rejet → 3,5
--     curseur 10,0/10 → rejet → 5,0
--
--   2,75 n'est PAS une position possible du curseur (pas de 0,5) : c'est la signature
--   arithmétique de la division. Les trois valeurs s'expliquent exactement par des
--   positions de curseur valides divisées par deux.
--
-- L'heuristique du client (`tasting_entry.dart`, qui doublait toute note ≤ 5) ne créait
-- donc pas le problème : elle le COMPENSAIT. La retirer sans élargir la contrainte
-- afficherait toutes les notes deux fois trop basses. D'où l'ordre imposé ici :
-- on marque l'échelle des lignes existantes, PUIS on élargit la contrainte.
--
-- Deux autres conséquences de la contrainte non élargie, corrigées du même coup :
--   • `sommelier_table_mode_sheet.dart` et `cellar_repository.dart` écrivent sans repli :
--     leurs enregistrements au-dessus de 5/10 échouaient purement et simplement.
--   • Le modèle de goût ne pouvait apprendre aucun dégoût, toute la moitié basse de
--     l'échelle étant repliée sur la moitié haute.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. L'échelle devient explicite plutôt que devinée
-- ─────────────────────────────────────────────────────────────────────────────

ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS rating_scale SMALLINT NOT NULL DEFAULT 10
    CHECK (rating_scale IN (5, 10));

COMMENT ON COLUMN public.tasting_log.rating_scale IS
  'Échelle sur laquelle `rating` a été saisi. 10 pour tout ce qui est écrit après cette '
  'migration. 5 pour les lignes antérieures, que la contrainte ≤ 5 avait fait diviser '
  'par deux à l''écriture — voir la section 4.';

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
-- WineServiceAdvisor calcule déjà la recommandation ; on n'enregistrait jamais le réel.
ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS served_temp TEXT
    CHECK (served_temp IS NULL OR served_temp IN ('cold', 'right', 'warm')),
  ADD COLUMN IF NOT EXISTS was_decanted BOOLEAN;

CREATE INDEX IF NOT EXISTS idx_tasting_log_user_consumed
  ON public.tasting_log (user_id, consumed_at DESC);

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Marquage de l'échelle, puis élargissement de la contrainte
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Aucune date à deviner, aucune inspection manuelle : le test est le TYPE de la colonne.
-- NUMERIC(2,1) ⇒ 027 n'a jamais tourné ⇒ la contrainte ≤ 5 a toujours tenu ⇒ AUCUNE ligne
-- n'a jamais pu contenir une note sur 10, donc toutes sont sur 5. C'est déduit du schéma,
-- pas estimé à partir des données.
--
-- L'ordre compte : on marque AVANT d'élargir, sinon le critère de décision disparaît.
-- Le bloc est atomique — si quoi que ce soit échoue, rien n'est marqué ni élargi.

DO $$
DECLARE
  v_precision  INTEGER;
  v_marquees   BIGINT := 0;
BEGIN
  SELECT numeric_precision INTO v_precision
  FROM information_schema.columns
  WHERE table_schema = 'public'
    AND table_name   = 'tasting_log'
    AND column_name  = 'rating';

  IF v_precision = 2 THEN
    -- La contrainte ≤ 5 tenait encore : tout l'historique est à l'échelle /5.
    UPDATE public.tasting_log
    SET rating_scale = 5
    WHERE rating IS NOT NULL;
    GET DIAGNOSTICS v_marquees = ROW_COUNT;

    RAISE NOTICE 'Migration 027 jamais appliquée (rating était NUMERIC(2,1)). % ligne(s) marquée(s) à l''échelle /5.', v_marquees;
  ELSE
    RAISE NOTICE 'rating est déjà NUMERIC(%,1) : 027 avait été appliquée, aucune ligne marquée.', v_precision;
  END IF;

  -- Élargissement (idempotent) : c'est ce que 027 aurait dû faire.
  ALTER TABLE public.tasting_log DROP CONSTRAINT IF EXISTS tasting_log_rating_check;
  ALTER TABLE public.tasting_log ALTER COLUMN rating TYPE NUMERIC(3,1);
  ALTER TABLE public.tasting_log ADD CONSTRAINT tasting_log_rating_check
    CHECK (rating >= 0 AND rating <= 10);
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Vérification — à lire après exécution
-- ─────────────────────────────────────────────────────────────────────────────
--
-- Aucune ligne en échelle /5 ne doit dépasser 5, et le type doit être NUMERIC(3,1) :
--
--   SELECT rating_scale, count(*), min(rating), max(rating)
--   FROM public.tasting_log WHERE rating IS NOT NULL GROUP BY 1;
--
--   SELECT numeric_precision, numeric_scale FROM information_schema.columns
--   WHERE table_name = 'tasting_log' AND column_name = 'rating';   -- attendu : 3, 1
--
-- Limite assumée : les lignes écrites par la dégustation externe avec « coup de cœur »
-- valaient `rating = 5.0` par convention, indistinguables d'un vrai 10/10 divisé. Elles
-- se reliront donc 10/10. C'est le sens voulu dans les deux cas ; `is_favorite` empêche
-- l'ambiguïté de se reproduire.
