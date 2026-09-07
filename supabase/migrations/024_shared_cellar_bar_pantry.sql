-- ============================================================================
-- Migration 024: Shared Cellar Bar Pantry Synchronization
-- ============================================================================
-- Allows syncing the bar pantry across users when a cellar with spirits
-- is shared with edit permissions (admin or editor).
-- ============================================================================

-- 1. Add cellar_id column to bar_pantry if it doesn't exist
ALTER TABLE bar_pantry ADD COLUMN IF NOT EXISTS cellar_id UUID REFERENCES cellars(id) ON DELETE CASCADE;

-- 2. Drop the single-column primary key on user_id to allow multiple cellar pantries or shared records
ALTER TABLE bar_pantry DROP CONSTRAINT IF EXISTS bar_pantry_pkey;
ALTER TABLE bar_pantry ADD COLUMN IF NOT EXISTS id UUID DEFAULT gen_random_uuid();
ALTER TABLE bar_pantry ADD PRIMARY KEY (id);

-- 3. Ensure unique constraint on cellar_id (one pantry per shared cellar)
CREATE UNIQUE INDEX IF NOT EXISTS bar_pantry_cellar_id_idx ON bar_pantry(cellar_id) WHERE cellar_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS bar_pantry_user_id_idx ON bar_pantry(user_id) WHERE cellar_id IS NULL;

-- 4. Update Row Level Security (RLS) policies
ALTER TABLE bar_pantry ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can manage own bar pantry" ON bar_pantry;
DROP POLICY IF EXISTS "Users and cellar members can view bar pantry" ON bar_pantry;
DROP POLICY IF EXISTS "Users and cellar editors can insert bar pantry" ON bar_pantry;
DROP POLICY IF EXISTS "Users and cellar editors can update bar pantry" ON bar_pantry;
DROP POLICY IF EXISTS "Users and cellar admins can delete bar pantry" ON bar_pantry;

-- Select: Owner can view, OR any member of the shared cellar can view
CREATE POLICY "Users and cellar members can view bar pantry"
  ON bar_pantry FOR SELECT
  USING (
    user_id = auth.uid()
    OR (
      cellar_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM cellar_members cm
        WHERE cm.cellar_id = bar_pantry.cellar_id
          AND cm.user_id = auth.uid()
      )
    )
  );

-- Insert: Owner can insert, OR any admin/editor of the cellar can insert
CREATE POLICY "Users and cellar editors can insert bar pantry"
  ON bar_pantry FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR (
      cellar_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM cellar_members cm
        WHERE cm.cellar_id = bar_pantry.cellar_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('admin', 'editor')
      )
    )
  );

-- Update: Owner can update, OR any admin/editor of the cellar can update
CREATE POLICY "Users and cellar editors can update bar pantry"
  ON bar_pantry FOR UPDATE
  USING (
    user_id = auth.uid()
    OR (
      cellar_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM cellar_members cm
        WHERE cm.cellar_id = bar_pantry.cellar_id
          AND cm.user_id = auth.uid()
          AND cm.role IN ('admin', 'editor')
      )
    )
  );

-- Delete: Owner can delete, OR admin of the cellar can delete
CREATE POLICY "Users and cellar admins can delete bar pantry"
  ON bar_pantry FOR DELETE
  USING (
    user_id = auth.uid()
    OR (
      cellar_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM cellar_members cm
        WHERE cm.cellar_id = bar_pantry.cellar_id
          AND cm.user_id = auth.uid()
          AND cm.role = 'admin'
      )
    )
  );
