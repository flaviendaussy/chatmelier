-- ============================================================================
-- Migration 028: Bottle Sizes and Mode Shelves (Meubles de Cave)
-- ============================================================================

-- 1. Add bottle_size to bottles with 75cl default
ALTER TABLE bottles ADD COLUMN IF NOT EXISTS bottle_size TEXT DEFAULT '75cl';

-- 2. Add furniture_id and furniture_slot (e.g. 'A7') to bottles
ALTER TABLE bottles ADD COLUMN IF NOT EXISTS furniture_id UUID;
ALTER TABLE bottles ADD COLUMN IF NOT EXISTS furniture_slot TEXT;

-- 3. Retroactively set all existing bottles without a size to 75cl
UPDATE bottles SET bottle_size = '75cl' WHERE bottle_size IS NULL OR bottle_size = '';

-- 4. Create cellar_furniture table
CREATE TABLE IF NOT EXISTS cellar_furniture (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID NOT NULL REFERENCES cellars(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  shape_type TEXT NOT NULL DEFAULT 'rectangle', -- 'rectangle', 'triangle', 'staggered_4_2', 'custom'
  columns INT NOT NULL DEFAULT 6,
  rows INT NOT NULL DEFAULT 6,
  slots_matrix JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Foreign key for bottles.furniture_id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'bottles_furniture_id_fkey'
  ) THEN
    ALTER TABLE bottles 
      ADD CONSTRAINT bottles_furniture_id_fkey 
      FOREIGN KEY (furniture_id) REFERENCES cellar_furniture(id) ON DELETE SET NULL;
  END IF;
END $$;

-- Enable RLS
ALTER TABLE cellar_furniture ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view cellar furniture." ON cellar_furniture;
DROP POLICY IF EXISTS "Editors and admins can insert cellar furniture." ON cellar_furniture;
DROP POLICY IF EXISTS "Editors and admins can update cellar furniture." ON cellar_furniture;
DROP POLICY IF EXISTS "Editors and admins can delete cellar furniture." ON cellar_furniture;

CREATE POLICY "Members can view cellar furniture." ON cellar_furniture FOR SELECT USING (
  is_cellar_member(cellar_id, auth.uid())
);
CREATE POLICY "Editors and admins can insert cellar furniture." ON cellar_furniture FOR INSERT WITH CHECK (
  is_cellar_editor_or_admin(cellar_id, auth.uid())
);
CREATE POLICY "Editors and admins can update cellar furniture." ON cellar_furniture FOR UPDATE USING (
  is_cellar_editor_or_admin(cellar_id, auth.uid())
);
CREATE POLICY "Editors and admins can delete cellar furniture." ON cellar_furniture FOR DELETE USING (
  is_cellar_editor_or_admin(cellar_id, auth.uid())
);

CREATE INDEX IF NOT EXISTS idx_cellar_furniture_cellar_id ON cellar_furniture(cellar_id);
CREATE INDEX IF NOT EXISTS idx_bottles_furniture_id ON bottles(furniture_id);
