-- ============================================================================
-- Migration 021: Spirits Support & Dynamic Bar Pantry
-- ============================================================================

-- 1. Remove rigid wine_type check constraint on wines table to allow spirits
-- (whisky, gin, rum, vodka, tequila, mezcal, cognac, armagnac, liqueur, vermouth, aperitif, bitter, etc.)
ALTER TABLE wines DROP CONSTRAINT IF EXISTS wines_wine_type_check;

-- 2. Bar Pantry table for syncing fresh ingredients and mixers across user devices
CREATE TABLE IF NOT EXISTS bar_pantry (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  items JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable RLS
ALTER TABLE bar_pantry ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own bar pantry" ON bar_pantry;

CREATE POLICY "Users can manage own bar pantry"
  ON bar_pantry FOR ALL
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
