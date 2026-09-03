-- ============================================================================
-- Migration 020: Private Chat Messages & Member Leave Security
-- ============================================================================

-- 1. Ensure chat messages are strictly private to the user who sent / received them.
-- Even in a shared cellar, AI sommelier conversations are 100% personal.
DROP POLICY IF EXISTS "Members can view chat messages." ON chat_messages;
DROP POLICY IF EXISTS "Users can only view their own chat messages." ON chat_messages;

CREATE POLICY "Users can only view their own chat messages."
  ON chat_messages FOR SELECT
  USING (user_id = auth.uid());

-- Ensure chat messages can only be inserted with own user_id
DROP POLICY IF EXISTS "Members can insert chat messages." ON chat_messages;
DROP POLICY IF EXISTS "Users can insert their own chat messages." ON chat_messages;

CREATE POLICY "Users can insert their own chat messages."
  ON chat_messages FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    AND (cellar_id IS NULL OR is_cellar_member(cellar_id, auth.uid()))
  );
