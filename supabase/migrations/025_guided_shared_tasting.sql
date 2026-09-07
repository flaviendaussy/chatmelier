-- ============================================================================
-- Migration 025: Guided Shared Tasting Synchronization across Friends
-- ============================================================================
-- Allows recording tasting logs and updating taste profiles for connected friends
-- when doing a guided co-tasting on Chatmelier.
-- ============================================================================

-- 1. Function to safely log tasting for a friend during a shared tasting
CREATE OR REPLACE FUNCTION record_shared_tasting_log(
  p_wine_id UUID,
  p_friend_user_id UUID,
  p_rating NUMERIC,
  p_bottle_id UUID DEFAULT NULL,
  p_cellar_id UUID DEFAULT NULL,
  p_notes TEXT DEFAULT NULL,
  p_food_paired TEXT DEFAULT NULL,
  p_occasion TEXT DEFAULT NULL,
  p_co_tasters JSONB DEFAULT '[]'::jsonb,
  p_bottle_owner_id UUID DEFAULT NULL,
  p_bottle_owner_name TEXT DEFAULT NULL,
  p_is_external BOOLEAN DEFAULT false,
  p_questionnaire_data JSONB DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_id UUID := gen_random_uuid();
  v_caller_id UUID := auth.uid();
  v_is_friend BOOLEAN := false;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  -- 1. Check if caller and friend are connected friends (or cellar sharing members)
  SELECT EXISTS (
    SELECT 1 FROM friendships
    WHERE ((user_id = v_caller_id AND friend_id = p_friend_user_id)
        OR (user_id = p_friend_user_id AND friend_id = v_caller_id))
      AND status = 'accepted'
  ) OR EXISTS (
    SELECT 1 FROM cellar_members cm1
    JOIN cellar_members cm2 ON cm1.cellar_id = cm2.cellar_id
    WHERE cm1.user_id = v_caller_id AND cm2.user_id = p_friend_user_id
  ) INTO v_is_friend;

  IF NOT v_is_friend AND v_caller_id != p_friend_user_id THEN
    RAISE EXCEPTION 'Not authorized to record tasting for non-friend user';
  END IF;

  -- 2. Insert tasting log for the friend
  INSERT INTO public.tasting_log (
    id,
    wine_id,
    bottle_id,
    cellar_id,
    user_id,
    rating,
    tasting_notes,
    food_paired,
    occasion,
    co_tasters,
    bottle_owner_id,
    bottle_owner_name,
    is_external,
    consumed_at
  ) VALUES (
    v_new_id,
    p_wine_id,
    p_bottle_id,
    p_cellar_id,
    p_friend_user_id,
    p_rating,
    p_notes,
    p_food_paired,
    COALESCE(p_occasion, 'Dégustation partagée'),
    p_co_tasters,
    p_bottle_owner_id,
    p_bottle_owner_name,
    p_is_external,
    now()
  );

  -- 3. If questionnaire data was provided, increment count in friend's profile
  IF p_questionnaire_data IS NOT NULL THEN
    UPDATE public.profiles
    SET taste_profile = jsonb_set(
      COALESCE(taste_profile, '{}'::jsonb),
      '{questionnaires_completed}',
      to_jsonb(COALESCE((taste_profile->>'questionnaires_completed')::int, 0) + 1),
      true
    )
    WHERE id = p_friend_user_id;
  END IF;

  RETURN v_new_id;
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION record_shared_tasting_log TO authenticated;
