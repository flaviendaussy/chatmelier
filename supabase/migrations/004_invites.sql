-- ============================================================================
-- Cellar Invites: a proper invite/accept/decline flow for sharing cellars
-- ============================================================================

-- Invite table: tracks pending, accepted, and declined invitations
CREATE TABLE cellar_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID NOT NULL REFERENCES cellars(id) ON DELETE CASCADE,
  invited_by UUID NOT NULL REFERENCES profiles(id),
  invited_user_id UUID REFERENCES profiles(id),        -- NULL if invited by email before signup
  invited_email TEXT,                                    -- used for email-based invites
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('viewer', 'editor')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'revoked')),
  invite_code TEXT UNIQUE DEFAULT encode(gen_random_bytes(16), 'hex'),  -- shareable code
  created_at TIMESTAMPTZ DEFAULT now(),
  responded_at TIMESTAMPTZ,
  CONSTRAINT invite_target CHECK (invited_user_id IS NOT NULL OR invited_email IS NOT NULL)
);

CREATE INDEX cellar_invites_user_idx ON cellar_invites(invited_user_id) WHERE status = 'pending';
CREATE INDEX cellar_invites_email_idx ON cellar_invites(invited_email) WHERE status = 'pending';
CREATE INDEX cellar_invites_code_idx ON cellar_invites(invite_code) WHERE status = 'pending';

-- RLS for invites
ALTER TABLE cellar_invites ENABLE ROW LEVEL SECURITY;

-- Invited users can see their own invites
CREATE POLICY "Users can see their own invites." ON cellar_invites FOR SELECT USING (
  invited_user_id = auth.uid()
  OR invited_email = (SELECT email FROM auth.users WHERE id = auth.uid())
  OR invited_by = auth.uid()
  OR EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = cellar_invites.cellar_id
    AND user_id = auth.uid()
    AND role = 'admin'
  )
);

-- Admins of the cellar can create invites
CREATE POLICY "Admins can create invites." ON cellar_invites FOR INSERT WITH CHECK (
  invited_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = cellar_invites.cellar_id
    AND user_id = auth.uid()
    AND role = 'admin'
  )
);

-- Invited users can update (accept/decline) their own invites
CREATE POLICY "Invited users can respond to invites." ON cellar_invites FOR UPDATE USING (
  invited_user_id = auth.uid()
  OR invited_email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

-- Admins can revoke invites
CREATE POLICY "Admins can revoke invites." ON cellar_invites FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = cellar_invites.cellar_id
    AND user_id = auth.uid()
    AND role = 'admin'
  )
);

-- ============================================================================
-- RPC: Accept an invite (creates cellar_members entry)
-- ============================================================================
CREATE OR REPLACE FUNCTION accept_invite(p_invite_id UUID)
RETURNS JSON AS $$
DECLARE
  v_invite RECORD;
  v_user_id UUID := auth.uid();
  v_user_email TEXT;
BEGIN
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;

  SELECT * INTO v_invite FROM cellar_invites
  WHERE id = p_invite_id
    AND status = 'pending'
    AND (invited_user_id = v_user_id OR invited_email = v_user_email);

  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Invite not found or already responded');
  END IF;

  -- Create membership
  INSERT INTO cellar_members (cellar_id, user_id, role)
  VALUES (v_invite.cellar_id, v_user_id, v_invite.role)
  ON CONFLICT (cellar_id, user_id) DO UPDATE SET role = EXCLUDED.role;

  -- Mark invite as accepted
  UPDATE cellar_invites SET
    status = 'accepted',
    invited_user_id = v_user_id,
    responded_at = now()
  WHERE id = p_invite_id;

  RETURN json_build_object(
    'success', true,
    'cellar_id', v_invite.cellar_id,
    'role', v_invite.role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RPC: Decline an invite
-- ============================================================================
CREATE OR REPLACE FUNCTION decline_invite(p_invite_id UUID)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_user_email TEXT;
BEGIN
  SELECT email INTO v_user_email FROM auth.users WHERE id = v_user_id;

  UPDATE cellar_invites SET
    status = 'declined',
    invited_user_id = v_user_id,
    responded_at = now()
  WHERE id = p_invite_id
    AND status = 'pending'
    AND (invited_user_id = v_user_id OR invited_email = v_user_email);

  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Invite not found or already responded');
  END IF;

  RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RPC: Accept invite by code (for link-based sharing)
-- ============================================================================
CREATE OR REPLACE FUNCTION accept_invite_by_code(p_code TEXT)
RETURNS JSON AS $$
DECLARE
  v_invite RECORD;
  v_user_id UUID := auth.uid();
BEGIN
  SELECT * INTO v_invite FROM cellar_invites
  WHERE invite_code = p_code AND status = 'pending';

  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Invalid or expired invite code');
  END IF;

  -- Create membership
  INSERT INTO cellar_members (cellar_id, user_id, role)
  VALUES (v_invite.cellar_id, v_user_id, v_invite.role)
  ON CONFLICT (cellar_id, user_id) DO UPDATE SET role = EXCLUDED.role;

  -- Mark invite as accepted
  UPDATE cellar_invites SET
    status = 'accepted',
    invited_user_id = v_user_id,
    responded_at = now()
  WHERE id = v_invite.id;

  RETURN json_build_object(
    'success', true,
    'cellar_id', v_invite.cellar_id,
    'role', v_invite.role
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RPC: Update a member's role (viewer <-> editor)
-- ============================================================================
CREATE OR REPLACE FUNCTION update_member_role(
  p_cellar_id UUID,
  p_user_id UUID,
  p_new_role TEXT
)
RETURNS JSON AS $$
DECLARE
  v_caller_id UUID := auth.uid();
BEGIN
  -- Verify caller is admin
  IF NOT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RETURN json_build_object('error', 'Only admins can change roles');
  END IF;

  -- Cannot change own role if you're the owner
  IF p_user_id = v_caller_id THEN
    RETURN json_build_object('error', 'Cannot change your own role');
  END IF;

  UPDATE cellar_members
  SET role = p_new_role
  WHERE cellar_id = p_cellar_id AND user_id = p_user_id;

  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Member not found');
  END IF;

  RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RPC: Remove a member from a cellar
-- ============================================================================
CREATE OR REPLACE FUNCTION remove_cellar_member(
  p_cellar_id UUID,
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_caller_id UUID := auth.uid();
BEGIN
  -- Either admin removing someone, or user leaving voluntarily
  IF v_caller_id != p_user_id AND NOT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RETURN json_build_object('error', 'Only admins can remove other members');
  END IF;

  -- Cannot remove the owner
  IF EXISTS (SELECT 1 FROM cellars WHERE id = p_cellar_id AND owner_id = p_user_id) THEN
    RETURN json_build_object('error', 'Cannot remove the cellar owner');
  END IF;

  DELETE FROM cellar_members
  WHERE cellar_id = p_cellar_id AND user_id = p_user_id;

  RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Auto-process pending email invites when a new user signs up
-- ============================================================================
CREATE OR REPLACE FUNCTION process_pending_invites()
RETURNS TRIGGER AS $$
BEGIN
  -- Update any pending invites for this email to point to the new user ID
  UPDATE cellar_invites
  SET invited_user_id = NEW.id
  WHERE invited_email = NEW.email
    AND status = 'pending'
    AND invited_user_id IS NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_user_created_process_invites
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION process_pending_invites();
