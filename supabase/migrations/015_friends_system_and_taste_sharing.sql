-- ============================================================================
-- Migration 015: Friends System, User Handles & Taste Profile Sharing
-- ============================================================================

-- 1. Extend profiles with username (mandatory unique handle), phone number and taste profile data
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS taste_profile JSONB DEFAULT '{}'::jsonb;

-- Index for fast user lookup by username, phone or email
CREATE INDEX IF NOT EXISTS profiles_username_idx ON profiles(username);
CREATE INDEX IF NOT EXISTS profiles_phone_number_idx ON profiles(phone_number);
CREATE INDEX IF NOT EXISTS profiles_email_idx ON profiles(email);

-- 2. Friendships table
CREATE TABLE IF NOT EXISTS friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'accepted' CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS friendships_user_id_idx ON friendships(user_id);
CREATE INDEX IF NOT EXISTS friendships_friend_id_idx ON friendships(friend_id);
CREATE INDEX IF NOT EXISTS friendships_status_idx ON friendships(status);

-- 3. Extend tasting_log with co-tasters, bottle owner and location details
ALTER TABLE tasting_log
  ADD COLUMN IF NOT EXISTS co_tasters JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS bottle_owner_id UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS bottle_owner_name TEXT,
  ADD COLUMN IF NOT EXISTS location_name TEXT,
  ADD COLUMN IF NOT EXISTS is_external BOOLEAN DEFAULT false;

-- 4. RLS for friendships
ALTER TABLE friendships ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies WHERE tablename = 'friendships' AND policyname = 'friendships_user_access'
  ) THEN
    CREATE POLICY "friendships_user_access" ON friendships
      FOR ALL
      USING (auth.uid() = user_id OR auth.uid() = friend_id);
  END IF;
END $$;
