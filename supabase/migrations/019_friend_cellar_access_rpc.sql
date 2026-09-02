-- ============================================================================
-- Migration 019: Robust Friend Cellar Access RPC & Notification Policies
-- ============================================================================

-- 1. Create SECURITY DEFINER function to allow friends to request cellar access
-- without being blocked by cellar SELECT RLS.
CREATE OR REPLACE FUNCTION public.request_friend_cellar_access(
  p_target_owner_id UUID,
  p_requested_role TEXT DEFAULT 'viewer',
  p_cellar_id UUID DEFAULT NULL,
  p_message TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_cellar_id UUID;
  v_cellar_name TEXT;
  v_request_id UUID;
  v_requester_name TEXT;
  v_requester_id UUID;
BEGIN
  v_requester_id := auth.uid();
  IF v_requester_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié';
  END IF;

  IF v_requester_id = p_target_owner_id THEN
    RAISE EXCEPTION 'Vous êtes déjà propriétaire de cette cave.';
  END IF;

  -- 1. Determine target cellar ID
  IF p_cellar_id IS NOT NULL THEN
    SELECT id, name INTO v_cellar_id, v_cellar_name
    FROM cellars
    WHERE id = p_cellar_id;
  END IF;

  IF v_cellar_id IS NULL THEN
    -- Fallback to first cellar owned by target user
    SELECT id, name INTO v_cellar_id, v_cellar_name
    FROM cellars
    WHERE owner_id = p_target_owner_id
    ORDER BY created_at ASC
    LIMIT 1;
  END IF;

  IF v_cellar_id IS NULL THEN
    -- Fallback to cellar where target user is admin
    SELECT c.id, c.name INTO v_cellar_id, v_cellar_name
    FROM cellars c
    JOIN cellar_members cm ON cm.cellar_id = c.id
    WHERE cm.user_id = p_target_owner_id AND cm.role = 'admin'
    LIMIT 1;
  END IF;

  IF v_cellar_id IS NULL THEN
    RAISE EXCEPTION 'Aucune cave trouvée pour cet utilisateur.';
  END IF;

  -- 2. Upsert into cellar_access_requests
  v_request_id := gen_random_uuid();
  INSERT INTO cellar_access_requests (
    id, cellar_id, owner_id, requester_id, requested_role, status, message, created_at
  )
  VALUES (
    v_request_id, v_cellar_id, p_target_owner_id, v_requester_id, p_requested_role, 'pending', p_message, now()
  )
  ON CONFLICT (cellar_id, requester_id)
  DO UPDATE SET
    requested_role = EXCLUDED.requested_role,
    status = 'pending',
    message = EXCLUDED.message,
    created_at = now()
  RETURNING id INTO v_request_id;

  -- 3. Get requester display name
  SELECT display_name INTO v_requester_name FROM profiles WHERE id = v_requester_id;

  -- 4. Insert notification for cellar owner
  INSERT INTO user_notifications (user_id, actor_id, type, title, body, data, is_read, created_at)
  VALUES (
    p_target_owner_id,
    v_requester_id,
    'cellar_request',
    'Demande d''accès à votre Cave 🍷',
    COALESCE(v_requester_name, 'Un ami') || ' souhaite accéder à votre cave "' || COALESCE(v_cellar_name, 'Ma Cave') || '" en mode ' || CASE WHEN p_requested_role = 'editor' THEN 'Sommelier ✍️' ELSE 'Lecteur 👁️' END || '.',
    jsonb_build_object(
      'request_id', v_request_id,
      'cellar_id', v_cellar_id,
      'cellar_name', v_cellar_name,
      'requester_id', v_requester_id,
      'requester_name', COALESCE(v_requester_name, 'Un ami'),
      'requested_role', p_requested_role,
      'message', p_message
    ),
    false,
    now()
  );

  RETURN jsonb_build_object(
    'success', true,
    'request_id', v_request_id,
    'cellar_id', v_cellar_id,
    'cellar_name', v_cellar_name
  );
END;
$$;

-- 2. Grant permissions
GRANT EXECUTE ON FUNCTION public.request_friend_cellar_access(UUID, TEXT, UUID, TEXT) TO authenticated;

-- 3. Ensure user_notifications can be deleted/dismissed by the recipient
DROP POLICY IF EXISTS "user_notifications_delete_policy" ON public.user_notifications;
CREATE POLICY "user_notifications_delete_policy" ON public.user_notifications
  FOR DELETE
  USING (auth.uid() = user_id);
