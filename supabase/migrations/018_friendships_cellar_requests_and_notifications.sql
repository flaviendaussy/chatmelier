-- ============================================================================
-- Migration 018: Friendships, Cellar Access Requests & User Notifications
-- ============================================================================

-- 1. Friendships Table
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  friend_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'blocked')),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(user_id, friend_id)
);

CREATE INDEX IF NOT EXISTS friendships_user_id_idx ON public.friendships(user_id);
CREATE INDEX IF NOT EXISTS friendships_friend_id_idx ON public.friendships(friend_id);
CREATE INDEX IF NOT EXISTS friendships_status_idx ON public.friendships(status);

ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  DROP POLICY IF EXISTS "friendships_access_policy" ON public.friendships;
  CREATE POLICY "friendships_access_policy" ON public.friendships
    FOR ALL
    USING (auth.uid() = user_id OR auth.uid() = friend_id)
    WITH CHECK (auth.uid() = user_id OR auth.uid() = friend_id);
END $$;


-- 2. Cellar Access Requests Table
CREATE TABLE IF NOT EXISTS public.cellar_access_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID NOT NULL REFERENCES public.cellars(id) ON DELETE CASCADE,
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  requester_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  requested_role TEXT NOT NULL DEFAULT 'viewer' CHECK (requested_role IN ('viewer', 'editor')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
  message TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  responded_at TIMESTAMPTZ,
  UNIQUE(cellar_id, requester_id)
);

CREATE INDEX IF NOT EXISTS cellar_access_requests_cellar_idx ON public.cellar_access_requests(cellar_id);
CREATE INDEX IF NOT EXISTS cellar_access_requests_owner_idx ON public.cellar_access_requests(owner_id);
CREATE INDEX IF NOT EXISTS cellar_access_requests_requester_idx ON public.cellar_access_requests(requester_id);
CREATE INDEX IF NOT EXISTS cellar_access_requests_status_idx ON public.cellar_access_requests(status);

ALTER TABLE public.cellar_access_requests ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  DROP POLICY IF EXISTS "cellar_access_requests_policy" ON public.cellar_access_requests;
  CREATE POLICY "cellar_access_requests_policy" ON public.cellar_access_requests
    FOR ALL
    USING (auth.uid() = owner_id OR auth.uid() = requester_id)
    WITH CHECK (auth.uid() = owner_id OR auth.uid() = requester_id);
END $$;


-- 3. User Notifications Table
CREATE TABLE IF NOT EXISTS public.user_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB DEFAULT '{}'::jsonb,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS user_notifications_user_idx ON public.user_notifications(user_id);
CREATE INDEX IF NOT EXISTS user_notifications_is_read_idx ON public.user_notifications(is_read);

ALTER TABLE public.user_notifications ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
  DROP POLICY IF EXISTS "user_notifications_policy" ON public.user_notifications;
  CREATE POLICY "user_notifications_policy" ON public.user_notifications
    FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id OR auth.uid() = actor_id);
END $$;
