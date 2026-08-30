-- ============================================================================
-- Migration 006: Fix RLS Infinite Recursion & Optimize Permissions
-- ============================================================================

-- 1. Create SECURITY DEFINER helper functions to bypass RLS in policy subqueries
CREATE OR REPLACE FUNCTION is_cellar_member(p_cellar_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = p_user_id
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_cellar_admin(p_cellar_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = p_user_id AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_cellar_editor_or_admin(p_cellar_id UUID, p_user_id UUID DEFAULT auth.uid())
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = p_user_id AND role IN ('editor', 'admin')
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 2. Drop and Recreate Cellar Members RLS Policies (eliminates infinite recursion)
DROP POLICY IF EXISTS "Members can view cellar members." ON cellar_members;
DROP POLICY IF EXISTS "Admins can manage cellar members." ON cellar_members;
DROP POLICY IF EXISTS "Users can view cellar members." ON cellar_members;
DROP POLICY IF EXISTS "Admins can insert cellar members." ON cellar_members;
DROP POLICY IF EXISTS "Admins can update cellar members." ON cellar_members;
DROP POLICY IF EXISTS "Admins or members themselves can delete membership." ON cellar_members;
DROP POLICY IF EXISTS "Admins or users can insert cellar members." ON cellar_members;
DROP POLICY IF EXISTS "Admins or members can delete cellar members." ON cellar_members;

CREATE POLICY "Users can view cellar members." ON cellar_members FOR SELECT USING (
  user_id = auth.uid() OR is_cellar_member(cellar_id, auth.uid())
);

CREATE POLICY "Admins or users can insert cellar members." ON cellar_members FOR INSERT WITH CHECK (
  is_cellar_admin(cellar_id, auth.uid()) OR user_id = auth.uid()
);

CREATE POLICY "Admins can update cellar members." ON cellar_members FOR UPDATE USING (
  is_cellar_admin(cellar_id, auth.uid())
);

CREATE POLICY "Admins or members can delete cellar members." ON cellar_members FOR DELETE USING (
  user_id = auth.uid() OR is_cellar_admin(cellar_id, auth.uid())
);

-- 3. Cellars RLS
DROP POLICY IF EXISTS "Users can view cellars they are members of." ON cellars;
DROP POLICY IF EXISTS "Users can create cellars." ON cellars;
DROP POLICY IF EXISTS "Owners can update their cellars." ON cellars;
DROP POLICY IF EXISTS "Owners can delete their cellars." ON cellars;

CREATE POLICY "Users can view cellars they are members of." ON cellars FOR SELECT USING (
  owner_id = auth.uid() OR is_cellar_member(id, auth.uid())
);
CREATE POLICY "Users can create cellars." ON cellars FOR INSERT WITH CHECK (owner_id = auth.uid());
CREATE POLICY "Owners can update their cellars." ON cellars FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "Owners can delete their cellars." ON cellars FOR DELETE USING (owner_id = auth.uid());

-- 4. Bottles RLS
DROP POLICY IF EXISTS "Members can view bottles in their cellars." ON bottles;
DROP POLICY IF EXISTS "Editors and admins can insert bottles." ON bottles;
DROP POLICY IF EXISTS "Editors and admins can update bottles." ON bottles;
DROP POLICY IF EXISTS "Editors and admins can delete bottles." ON bottles;

CREATE POLICY "Members can view bottles in their cellars." ON bottles FOR SELECT USING (
  is_cellar_member(cellar_id, auth.uid())
);
CREATE POLICY "Editors and admins can insert bottles." ON bottles FOR INSERT WITH CHECK (
  is_cellar_editor_or_admin(cellar_id, auth.uid())
);
CREATE POLICY "Editors and admins can update bottles." ON bottles FOR UPDATE USING (
  is_cellar_editor_or_admin(cellar_id, auth.uid())
);
CREATE POLICY "Editors and admins can delete bottles." ON bottles FOR DELETE USING (
  is_cellar_editor_or_admin(cellar_id, auth.uid())
);

-- 5. Bottle Photos RLS
DROP POLICY IF EXISTS "Members can view bottle photos." ON bottle_photos;
DROP POLICY IF EXISTS "Editors and admins can insert photos." ON bottle_photos;
DROP POLICY IF EXISTS "Editors and admins can update photos." ON bottle_photos;
DROP POLICY IF EXISTS "Editors and admins can delete photos." ON bottle_photos;

CREATE POLICY "Members can view bottle photos." ON bottle_photos FOR SELECT USING (
  EXISTS (SELECT 1 FROM bottles b WHERE b.id = bottle_photos.bottle_id AND is_cellar_member(b.cellar_id, auth.uid()))
);
CREATE POLICY "Editors and admins can insert photos." ON bottle_photos FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM bottles b WHERE b.id = bottle_photos.bottle_id AND is_cellar_editor_or_admin(b.cellar_id, auth.uid()))
);
CREATE POLICY "Editors and admins can update photos." ON bottle_photos FOR UPDATE USING (
  EXISTS (SELECT 1 FROM bottles b WHERE b.id = bottle_photos.bottle_id AND is_cellar_editor_or_admin(b.cellar_id, auth.uid()))
);
CREATE POLICY "Editors and admins can delete photos." ON bottle_photos FOR DELETE USING (
  EXISTS (SELECT 1 FROM bottles b WHERE b.id = bottle_photos.bottle_id AND is_cellar_editor_or_admin(b.cellar_id, auth.uid()))
);

-- 6. Tasting Log RLS
DROP POLICY IF EXISTS "Members can view tasting logs." ON tasting_log;
DROP POLICY IF EXISTS "Users can create their own tasting logs." ON tasting_log;
DROP POLICY IF EXISTS "Users can update their own tasting logs." ON tasting_log;
DROP POLICY IF EXISTS "Users can delete their own tasting logs." ON tasting_log;

CREATE POLICY "Members can view tasting logs." ON tasting_log FOR SELECT USING (
  user_id = auth.uid() OR (cellar_id IS NOT NULL AND is_cellar_member(cellar_id, auth.uid()))
);
CREATE POLICY "Users can create their own tasting logs." ON tasting_log FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "Users can update their own tasting logs." ON tasting_log FOR UPDATE USING (user_id = auth.uid());
CREATE POLICY "Users can delete their own tasting logs." ON tasting_log FOR DELETE USING (user_id = auth.uid());

-- 7. Chat Messages RLS
DROP POLICY IF EXISTS "Members can view chat messages." ON chat_messages;
DROP POLICY IF EXISTS "Members can insert chat messages." ON chat_messages;

CREATE POLICY "Members can view chat messages." ON chat_messages FOR SELECT USING (
  user_id = auth.uid() OR is_cellar_member(cellar_id, auth.uid())
);
CREATE POLICY "Members can insert chat messages." ON chat_messages FOR INSERT WITH CHECK (
  user_id = auth.uid() AND is_cellar_member(cellar_id, auth.uid())
);

-- 8. Cellar Invites RLS
DROP POLICY IF EXISTS "Users can see their own invites." ON cellar_invites;
DROP POLICY IF EXISTS "Admins can create invites." ON cellar_invites;
DROP POLICY IF EXISTS "Invited users can respond to invites." ON cellar_invites;
DROP POLICY IF EXISTS "Admins can revoke invites." ON cellar_invites;
DROP POLICY IF EXISTS "Admins can delete invites." ON cellar_invites;

CREATE POLICY "Users can see their own invites." ON cellar_invites FOR SELECT USING (
  invited_user_id = auth.uid()
  OR invited_email = (SELECT email FROM auth.users WHERE id = auth.uid())
  OR invited_by = auth.uid()
  OR is_cellar_admin(cellar_id, auth.uid())
);
CREATE POLICY "Admins can create invites." ON cellar_invites FOR INSERT WITH CHECK (
  invited_by = auth.uid()
  AND is_cellar_admin(cellar_id, auth.uid())
);
CREATE POLICY "Invited users can respond to invites." ON cellar_invites FOR UPDATE USING (
  invited_user_id = auth.uid()
  OR invited_email = (SELECT email FROM auth.users WHERE id = auth.uid())
  OR is_cellar_admin(cellar_id, auth.uid())
);
CREATE POLICY "Admins can delete invites." ON cellar_invites FOR DELETE USING (
  is_cellar_admin(cellar_id, auth.uid())
);
