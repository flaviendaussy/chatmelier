-- =============================================================================
-- 037 — Sortir une bouteille pour l'offrir
-- =============================================================================
-- `status = 'gifted'` existait depuis le premier schéma, mais rien ne l'écrivait : offrir
-- une bouteille passait par le même écran que la boire, qui réclame une note. On notait
-- donc un vin qu'on n'avait pas goûté, et cette note partait nourrir le profil de goût.
--
-- Deux colonnes suffisent à rendre le geste possible sans mentir : à qui, et quand.
-- =============================================================================

ALTER TABLE public.bottles
  ADD COLUMN IF NOT EXISTS gifted_to TEXT,
  ADD COLUMN IF NOT EXISTS gifted_at TIMESTAMPTZ;

COMMENT ON COLUMN public.bottles.gifted_to IS
  'À qui la bouteille a été offerte. Texte libre : le destinataire n''a pas de compte, '
  'et en exiger un ferait de l''offrande une invitation.';

COMMENT ON COLUMN public.bottles.gifted_at IS
  'Quand elle a été offerte. Distinct de consumed_at : une bouteille offerte n''a pas été bue.';

-- Retrouver ce qu'on a offert, sans balayer toute la cave.
CREATE INDEX IF NOT EXISTS bottles_gifted_at_idx
  ON public.bottles(gifted_at) WHERE gifted_at IS NOT NULL;
