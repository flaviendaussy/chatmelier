-- ============================================================================
-- CHATMELLIER — COMPLETE DATABASE SCHEMA, RLS, FUNCTIONS & STORAGE
-- ============================================================================

-- Extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";

-- 1. PROFILES (Extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 2. CELLARS (A user can have multiple cellars with nicknames & locations)
CREATE TABLE IF NOT EXISTS cellars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT 'My Cellar',
  nickname TEXT,
  location_name TEXT,
  latitude NUMERIC(9,6),
  longitude NUMERIC(9,6),
  description TEXT,
  owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 3. CELLAR MEMBERS (Granular sharing: viewer = read-only, editor = read-write, admin = owner)
CREATE TABLE IF NOT EXISTS cellar_members (
  cellar_id UUID REFERENCES cellars(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'editor' CHECK (role IN ('viewer', 'editor', 'admin')),
  invited_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (cellar_id, user_id)
);

-- 4. CELLAR INVITES (Invitations by email or shareable link code)
CREATE TABLE IF NOT EXISTS cellar_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID NOT NULL REFERENCES cellars(id) ON DELETE CASCADE,
  invited_by UUID NOT NULL REFERENCES profiles(id),
  invited_user_id UUID REFERENCES profiles(id),
  invited_email TEXT,
  role TEXT NOT NULL DEFAULT 'viewer' CHECK (role IN ('viewer', 'editor')),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'revoked')),
  invite_code TEXT UNIQUE DEFAULT encode(gen_random_bytes(16), 'hex'),
  created_at TIMESTAMPTZ DEFAULT now(),
  responded_at TIMESTAMPTZ,
  CONSTRAINT invite_target CHECK (invited_user_id IS NOT NULL OR invited_email IS NOT NULL)
);

-- 5. WINES (Canonical wine encyclopedia with zero-hallucination web-verified enrichment)
CREATE TABLE IF NOT EXISTS wines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  producer TEXT,
  cuvee_parcel TEXT,
  vintage INT,
  wine_type TEXT CHECK (wine_type IN ('red', 'white', 'rosé', 'sparkling', 'dessert', 'fortified', 'orange')),
  country TEXT,
  region TEXT,
  sub_region TEXT,
  appellation TEXT,
  classification TEXT,
  alcohol_pct NUMERIC(4,2),
  grapes JSONB DEFAULT '[]'::jsonb,
  tasting_notes TEXT,
  ideal_drinking_start INT,
  ideal_drinking_end INT,
  peak_drinking_start INT,
  peak_drinking_end INT,
  ai_summary TEXT,
  ai_food_pairings JSONB DEFAULT '[]'::jsonb,
  external_links JSONB DEFAULT '{}'::jsonb,
  critic_scores JSONB DEFAULT '[]'::jsonb, -- Max 5 trusted sources
  estimated_market_value NUMERIC(10,2),
  estimated_value_currency TEXT DEFAULT 'EUR',
  last_valuation_date TIMESTAMPTZ DEFAULT now(),
  valuation_history JSONB DEFAULT '[]'::jsonb,
  sources_verified JSONB DEFAULT '[]'::jsonb,
  is_verified_online BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 6. BOTTLES (Physical inventory belonging to a cellar)
CREATE TABLE IF NOT EXISTS bottles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID NOT NULL REFERENCES cellars(id) ON DELETE CASCADE,
  wine_id UUID NOT NULL REFERENCES wines(id),
  added_by UUID NOT NULL REFERENCES profiles(id),
  owner_id UUID NOT NULL REFERENCES profiles(id),
  quantity INT NOT NULL DEFAULT 1,
  purchase_price NUMERIC(10,2),
  purchase_date DATE,
  purchase_location TEXT,
  notes TEXT,
  rack TEXT,
  shelf TEXT,
  "position" TEXT,
  status TEXT NOT NULL DEFAULT 'in_cellar' CHECK (status IN ('in_cellar', 'consumed', 'gifted', 'sold')),
  consumed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 7. BOTTLE PHOTOS (With pgvector embeddings for visual checkout)
CREATE TABLE IF NOT EXISTS bottle_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bottle_id UUID REFERENCES bottles(id) ON DELETE CASCADE,
  wine_id UUID REFERENCES wines(id),
  storage_path TEXT NOT NULL,
  photo_type TEXT DEFAULT 'front' CHECK (photo_type IN ('front', 'back', 'neck', 'full')),
  embedding VECTOR(768),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 8. TASTING LOG (Journal of consumed bottles with ratings and pairings)
CREATE TABLE IF NOT EXISTS tasting_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bottle_id UUID REFERENCES bottles(id) ON DELETE SET NULL,
  wine_id UUID NOT NULL REFERENCES wines(id),
  user_id UUID NOT NULL REFERENCES profiles(id),
  cellar_id UUID REFERENCES cellars(id),
  rating NUMERIC(2,1) CHECK (rating >= 0 AND rating <= 5),
  occasion TEXT,
  food_paired TEXT,
  tasting_notes TEXT,
  photo_url TEXT,
  consumed_at TIMESTAMPTZ DEFAULT now()
);

-- 9. CHAT MESSAGES (AI Sommelier conversation history)
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID NOT NULL REFERENCES cellars(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  referenced_bottle_ids JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================================
-- INDEXES & FULL-TEXT SEARCH
-- ============================================================================

CREATE INDEX IF NOT EXISTS bottle_photos_embedding_idx ON bottle_photos USING hnsw (embedding vector_cosine_ops);
CREATE INDEX IF NOT EXISTS bottles_cellar_id_idx ON bottles(cellar_id);
CREATE INDEX IF NOT EXISTS bottles_wine_id_idx ON bottles(wine_id);
CREATE INDEX IF NOT EXISTS bottles_status_idx ON bottles(status);
CREATE INDEX IF NOT EXISTS bottles_owner_id_idx ON bottles(owner_id);
CREATE INDEX IF NOT EXISTS tasting_log_wine_id_idx ON tasting_log(wine_id);
CREATE INDEX IF NOT EXISTS tasting_log_user_id_idx ON tasting_log(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_cellar_id_idx ON chat_messages(cellar_id);
CREATE INDEX IF NOT EXISTS cellar_invites_user_idx ON cellar_invites(invited_user_id) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS cellar_invites_email_idx ON cellar_invites(invited_email) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS cellar_invites_code_idx ON cellar_invites(invite_code) WHERE status = 'pending';

-- Full text search column on wines
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'wines' AND column_name = 'fts'
  ) THEN
    ALTER TABLE wines ADD COLUMN fts TSVECTOR
      GENERATED ALWAYS AS (
        to_tsvector('english',
          coalesce(name,'') || ' ' ||
          coalesce(producer,'') || ' ' ||
          coalesce(region,'') || ' ' ||
          coalesce(sub_region,'') || ' ' ||
          coalesce(country,'') || ' ' ||
          coalesce(appellation,'')
        )
      ) STORED;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS wines_fts_idx ON wines USING gin(fts);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE cellars ENABLE ROW LEVEL SECURITY;
ALTER TABLE cellar_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE cellar_invites ENABLE ROW LEVEL SECURITY;
ALTER TABLE wines ENABLE ROW LEVEL SECURITY;
ALTER TABLE bottles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bottle_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasting_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "Public profiles are viewable by everyone." ON profiles;
CREATE POLICY "Public profiles are viewable by everyone." ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can insert their own profile." ON profiles;
CREATE POLICY "Users can insert their own profile." ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update own profile." ON profiles;
CREATE POLICY "Users can update own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- Cellars
DROP POLICY IF EXISTS "Users can view cellars they are members of." ON cellars;
CREATE POLICY "Users can view cellars they are members of." ON cellars FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = cellars.id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Users can create cellars." ON cellars;
CREATE POLICY "Users can create cellars." ON cellars FOR INSERT WITH CHECK (owner_id = auth.uid());
DROP POLICY IF EXISTS "Owners can update their cellars." ON cellars;
CREATE POLICY "Owners can update their cellars." ON cellars FOR UPDATE USING (owner_id = auth.uid());
DROP POLICY IF EXISTS "Owners can delete their cellars." ON cellars;
CREATE POLICY "Owners can delete their cellars." ON cellars FOR DELETE USING (owner_id = auth.uid());

-- Cellar Members
DROP POLICY IF EXISTS "Members can view cellar members." ON cellar_members;
CREATE POLICY "Members can view cellar members." ON cellar_members FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members cm WHERE cm.cellar_id = cellar_members.cellar_id AND cm.user_id = auth.uid())
);
DROP POLICY IF EXISTS "Admins can manage cellar members." ON cellar_members;
CREATE POLICY "Admins can manage cellar members." ON cellar_members FOR ALL USING (
  EXISTS (SELECT 1 FROM cellar_members cm WHERE cm.cellar_id = cellar_members.cellar_id AND cm.user_id = auth.uid() AND cm.role = 'admin')
);

-- Cellar Invites
DROP POLICY IF EXISTS "Users can see their own invites." ON cellar_invites;
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
DROP POLICY IF EXISTS "Admins can create invites." ON cellar_invites;
CREATE POLICY "Admins can create invites." ON cellar_invites FOR INSERT WITH CHECK (
  invited_by = auth.uid()
  AND EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = cellar_invites.cellar_id
    AND user_id = auth.uid()
    AND role = 'admin'
  )
);
DROP POLICY IF EXISTS "Invited users can respond to invites." ON cellar_invites;
CREATE POLICY "Invited users can respond to invites." ON cellar_invites FOR UPDATE USING (
  invited_user_id = auth.uid()
  OR invited_email = (SELECT email FROM auth.users WHERE id = auth.uid())
);

-- Wines
DROP POLICY IF EXISTS "Wines are viewable by everyone." ON wines;
CREATE POLICY "Wines are viewable by everyone." ON wines FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can create wines." ON wines;
CREATE POLICY "Authenticated users can create wines." ON wines FOR INSERT WITH CHECK (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Authenticated users can update wines." ON wines;
CREATE POLICY "Authenticated users can update wines." ON wines FOR UPDATE USING (auth.role() = 'authenticated');

-- Bottles
DROP POLICY IF EXISTS "Members can view bottles in their cellars." ON bottles;
CREATE POLICY "Members can view bottles in their cellars." ON bottles FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Editors and admins can insert bottles." ON bottles;
CREATE POLICY "Editors and admins can insert bottles." ON bottles FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid() AND role IN ('editor', 'admin'))
);
DROP POLICY IF EXISTS "Editors and admins can update bottles." ON bottles;
CREATE POLICY "Editors and admins can update bottles." ON bottles FOR UPDATE USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid() AND role IN ('editor', 'admin'))
);
DROP POLICY IF EXISTS "Editors and admins can delete bottles." ON bottles;
CREATE POLICY "Editors and admins can delete bottles." ON bottles FOR DELETE USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = bottles.cellar_id AND user_id = auth.uid() AND role IN ('editor', 'admin'))
);

-- Bottle Photos
DROP POLICY IF EXISTS "Members can view bottle photos." ON bottle_photos;
CREATE POLICY "Members can view bottle photos." ON bottle_photos FOR SELECT USING (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid())
);
DROP POLICY IF EXISTS "Editors and admins can insert photos." ON bottle_photos;
CREATE POLICY "Editors and admins can insert photos." ON bottle_photos FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid() AND cm.role IN ('editor', 'admin'))
);
DROP POLICY IF EXISTS "Editors and admins can update photos." ON bottle_photos;
CREATE POLICY "Editors and admins can update photos." ON bottle_photos FOR UPDATE USING (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid() AND cm.role IN ('editor', 'admin'))
);
DROP POLICY IF EXISTS "Editors and admins can delete photos." ON bottle_photos;
CREATE POLICY "Editors and admins can delete photos." ON bottle_photos FOR DELETE USING (
  EXISTS (SELECT 1 FROM bottles b JOIN cellar_members cm ON b.cellar_id = cm.cellar_id WHERE b.id = bottle_photos.bottle_id AND cm.user_id = auth.uid() AND cm.role IN ('editor', 'admin'))
);

-- Tasting Log
DROP POLICY IF EXISTS "Members can view tasting logs." ON tasting_log;
CREATE POLICY "Members can view tasting logs." ON tasting_log FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = tasting_log.cellar_id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Users can create their own tasting logs." ON tasting_log;
CREATE POLICY "Users can create their own tasting logs." ON tasting_log FOR INSERT WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update their own tasting logs." ON tasting_log;
CREATE POLICY "Users can update their own tasting logs." ON tasting_log FOR UPDATE USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can delete their own tasting logs." ON tasting_log;
CREATE POLICY "Users can delete their own tasting logs." ON tasting_log FOR DELETE USING (user_id = auth.uid());

-- Chat Messages
DROP POLICY IF EXISTS "Members can view chat messages." ON chat_messages;
CREATE POLICY "Members can view chat messages." ON chat_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = chat_messages.cellar_id AND user_id = auth.uid())
);
DROP POLICY IF EXISTS "Members can insert chat messages." ON chat_messages;
CREATE POLICY "Members can insert chat messages." ON chat_messages FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM cellar_members WHERE cellar_id = chat_messages.cellar_id AND user_id = auth.uid())
);

-- ============================================================================
-- RPC FUNCTIONS & TRIGGERS
-- ============================================================================

-- Function: Search bottles with filters
CREATE OR REPLACE FUNCTION search_bottles(
  p_cellar_id UUID,
  p_query TEXT DEFAULT NULL,
  p_wine_type TEXT DEFAULT NULL,
  p_country TEXT DEFAULT NULL,
  p_region TEXT DEFAULT NULL,
  p_owner_id UUID DEFAULT NULL,
  p_status TEXT DEFAULT 'in_cellar',
  p_drinking_window_status TEXT DEFAULT NULL,
  p_vintage_min INT DEFAULT NULL,
  p_vintage_max INT DEFAULT NULL,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  bottle_id UUID,
  quantity INT,
  status TEXT,
  notes TEXT,
  rack TEXT,
  shelf TEXT,
  "position" TEXT,
  wine_id UUID,
  name TEXT,
  vintage INT,
  wine_type TEXT,
  producer TEXT,
  country TEXT,
  region TEXT,
  ideal_drinking_start INT,
  ideal_drinking_end INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.id, b.quantity, b.status, b.notes, b.rack, b.shelf, b."position",
    w.id, w.name, w.vintage, w.wine_type, w.producer, w.country, w.region, w.ideal_drinking_start, w.ideal_drinking_end
  FROM bottles b
  JOIN wines w ON b.wine_id = w.id
  WHERE b.cellar_id = p_cellar_id
    AND (p_status IS NULL OR b.status = p_status)
    AND (p_owner_id IS NULL OR b.owner_id = p_owner_id)
    AND (p_wine_type IS NULL OR w.wine_type = p_wine_type)
    AND (p_country IS NULL OR w.country = p_country)
    AND (p_region IS NULL OR w.region = p_region)
    AND (p_vintage_min IS NULL OR w.vintage >= p_vintage_min)
    AND (p_vintage_max IS NULL OR w.vintage <= p_vintage_max)
    AND (p_query IS NULL OR w.fts @@ to_tsquery('english', p_query))
    AND (
      p_drinking_window_status IS NULL 
      OR (p_drinking_window_status = 'ready' AND EXTRACT(YEAR FROM now()) >= w.ideal_drinking_start AND EXTRACT(YEAR FROM now()) <= w.ideal_drinking_end)
      OR (p_drinking_window_status = 'drink_soon' AND EXTRACT(YEAR FROM now()) >= w.ideal_drinking_end - 1 AND EXTRACT(YEAR FROM now()) <= w.ideal_drinking_end)
      OR (p_drinking_window_status = 'past_peak' AND EXTRACT(YEAR FROM now()) > w.peak_drinking_end)
    )
  ORDER BY w.name ASC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Cellar Stats (Total count, consumed count, paid value, market value)
CREATE OR REPLACE FUNCTION get_cellar_stats(p_cellar_id UUID)
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  SELECT json_build_object(
    'total_bottles', COALESCE(SUM(b.quantity) FILTER (WHERE b.status = 'in_cellar'), 0),
    'total_consumed', COALESCE(SUM(b.quantity) FILTER (WHERE b.status = 'consumed'), 0),
    'total_paid_value', COALESCE(SUM(b.quantity * b.purchase_price) FILTER (WHERE b.status = 'in_cellar' AND b.purchase_price IS NOT NULL), 0),
    'total_estimated_market_value', COALESCE(SUM(b.quantity * COALESCE(w.estimated_market_value, b.purchase_price, 0)) FILTER (WHERE b.status = 'in_cellar'), 0),
    'by_type', (
      SELECT json_object_agg(w2.wine_type, count)
      FROM (
        SELECT w_sub.wine_type, SUM(b_sub.quantity) as count 
        FROM bottles b_sub JOIN wines w_sub ON b_sub.wine_id = w_sub.id 
        WHERE b_sub.cellar_id = p_cellar_id AND b_sub.status = 'in_cellar' 
        GROUP BY w_sub.wine_type
      ) w2
    ),
    'drink_soon_count', (
      SELECT COALESCE(SUM(b_ds.quantity), 0)
      FROM bottles b_ds JOIN wines w_ds ON b_ds.wine_id = w_ds.id
      WHERE b_ds.cellar_id = p_cellar_id AND b_ds.status = 'in_cellar'
      AND EXTRACT(YEAR FROM now()) >= w_ds.ideal_drinking_end - 1 
      AND EXTRACT(YEAR FROM now()) <= w_ds.ideal_drinking_end
    ),
    'past_peak_count', (
      SELECT COALESCE(SUM(b_pp.quantity), 0)
      FROM bottles b_pp JOIN wines w_pp ON b_pp.wine_id = w_pp.id
      WHERE b_pp.cellar_id = p_cellar_id AND b_pp.status = 'in_cellar'
      AND EXTRACT(YEAR FROM now()) > w_pp.peak_drinking_end
    )
  ) INTO stats
  FROM bottles b
  LEFT JOIN wines w ON b.wine_id = w.id
  WHERE b.cellar_id = p_cellar_id;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Visual Match Search using pgvector
CREATE OR REPLACE FUNCTION find_similar_photos(
  p_embedding VECTOR(768), 
  p_cellar_id UUID, 
  p_threshold FLOAT, 
  p_limit INT DEFAULT 5
)
RETURNS TABLE (
  photo_id UUID,
  bottle_id UUID,
  wine_id UUID,
  wine_name TEXT,
  vintage INT,
  similarity FLOAT,
  storage_path TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    bp.id, bp.bottle_id, bp.wine_id, 
    w.name, w.vintage,
    1 - (bp.embedding <=> p_embedding) AS similarity,
    bp.storage_path
  FROM bottle_photos bp
  JOIN bottles b ON bp.bottle_id = b.id
  JOIN wines w ON b.wine_id = w.id
  WHERE b.cellar_id = p_cellar_id 
    AND 1 - (bp.embedding <=> p_embedding) > p_threshold
  ORDER BY similarity DESC
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get Drink Soon Bottles
CREATE OR REPLACE FUNCTION get_drink_soon_bottles(p_cellar_id UUID, p_months_ahead INT DEFAULT 12)
RETURNS TABLE (
  bottle_id UUID,
  wine_name TEXT,
  vintage INT,
  ideal_drinking_end INT
) AS $$
BEGIN
  RETURN QUERY
  SELECT b.id, w.name, w.vintage, w.ideal_drinking_end
  FROM bottles b
  JOIN wines w ON b.wine_id = w.id
  WHERE b.cellar_id = p_cellar_id 
    AND b.status = 'in_cellar'
    AND w.ideal_drinking_end IS NOT NULL
    AND w.ideal_drinking_end <= EXTRACT(YEAR FROM (now() + (p_months_ahead || ' months')::interval));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Find cached wine to prevent duplicate AI API billing
CREATE OR REPLACE FUNCTION find_cached_wine(
  p_producer TEXT,
  p_name TEXT,
  p_vintage INT,
  p_cuvee TEXT DEFAULT NULL
)
RETURNS SETOF wines AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM wines w
  WHERE lower(trim(w.name)) = lower(trim(p_name))
    AND (
      (w.vintage IS NULL AND p_vintage IS NULL)
      OR (w.vintage = p_vintage)
    )
    AND (
      p_producer IS NULL 
      OR lower(trim(coalesce(w.producer, ''))) = lower(trim(p_producer))
    )
    AND (
      p_cuvee IS NULL 
      OR lower(trim(coalesce(w.cuvee_parcel, ''))) = lower(trim(p_cuvee))
    )
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get wines needing 6-month valuation update
CREATE OR REPLACE FUNCTION get_wines_needing_revaluation(p_months_interval INT DEFAULT 6)
RETURNS TABLE (
  wine_id UUID,
  wine_name TEXT,
  producer TEXT,
  vintage INT,
  cuvee_parcel TEXT,
  estimated_market_value NUMERIC(10,2),
  last_valuation_date TIMESTAMPTZ,
  active_bottle_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    w.id,
    w.name,
    w.producer,
    w.vintage,
    w.cuvee_parcel,
    w.estimated_market_value,
    w.last_valuation_date,
    COUNT(b.id) AS active_bottle_count
  FROM wines w
  JOIN bottles b ON b.wine_id = w.id
  WHERE b.status = 'in_cellar'
    AND (
      w.last_valuation_date IS NULL 
      OR w.last_valuation_date <= now() - (p_months_interval || ' months')::interval
    )
  GROUP BY w.id, w.name, w.producer, w.vintage, w.cuvee_parcel, w.estimated_market_value, w.last_valuation_date
  ORDER BY w.last_valuation_date ASC NULLS FIRST;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Record wine valuation update
CREATE OR REPLACE FUNCTION record_wine_valuation(
  p_wine_id UUID,
  p_new_value NUMERIC(10,2),
  p_currency TEXT DEFAULT 'EUR',
  p_source TEXT DEFAULT 'Internet Aggregator'
)
RETURNS JSON AS $$
DECLARE
  v_new_entry JSONB;
BEGIN
  v_new_entry := jsonb_build_object(
    'date', to_char(now(), 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'value', p_new_value,
    'currency', p_currency,
    'source', p_source
  );

  UPDATE wines
  SET 
    estimated_market_value = p_new_value,
    estimated_value_currency = p_currency,
    last_valuation_date = now(),
    valuation_history = COALESCE(valuation_history, '[]'::jsonb) || v_new_entry,
    updated_at = now()
  WHERE id = p_wine_id;

  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Wine not found');
  END IF;

  RETURN json_build_object('success', true, 'wine_id', p_wine_id, 'new_value', p_new_value);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Accept Cellar Invite
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

  INSERT INTO cellar_members (cellar_id, user_id, role)
  VALUES (v_invite.cellar_id, v_user_id, v_invite.role)
  ON CONFLICT (cellar_id, user_id) DO UPDATE SET role = EXCLUDED.role;

  UPDATE cellar_invites SET
    status = 'accepted',
    invited_user_id = v_user_id,
    responded_at = now()
  WHERE id = p_invite_id;

  RETURN json_build_object('success', true, 'cellar_id', v_invite.cellar_id, 'role', v_invite.role);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Decline Cellar Invite
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

-- Function: Update Member Role
CREATE OR REPLACE FUNCTION update_member_role(
  p_cellar_id UUID,
  p_user_id UUID,
  p_new_role TEXT
)
RETURNS JSON AS $$
DECLARE
  v_caller_id UUID := auth.uid();
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RETURN json_build_object('error', 'Only admins can change roles');
  END IF;

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

-- Function: Remove Cellar Member
CREATE OR REPLACE FUNCTION remove_cellar_member(
  p_cellar_id UUID,
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_caller_id UUID := auth.uid();
BEGIN
  IF v_caller_id != p_user_id AND NOT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = v_caller_id AND role = 'admin'
  ) THEN
    RETURN json_build_object('error', 'Only admins can remove other members');
  END IF;

  IF EXISTS (SELECT 1 FROM cellars WHERE id = p_cellar_id AND owner_id = p_user_id) THEN
    RETURN json_build_object('error', 'Cannot remove the cellar owner');
  END IF;

  DELETE FROM cellar_members
  WHERE cellar_id = p_cellar_id AND user_id = p_user_id;

  RETURN json_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Auto-create Profile & Default Cellar on Sign Up
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  new_cellar_id UUID;
BEGIN
  INSERT INTO profiles (id, display_name)
  VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)))
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO cellars (owner_id, name)
  VALUES (NEW.id, 'My Cellar')
  RETURNING id INTO new_cellar_id;

  INSERT INTO cellar_members (cellar_id, user_id, role)
  VALUES (new_cellar_id, NEW.id, 'admin');

  -- Process any pending email invites for this user
  UPDATE cellar_invites
  SET invited_user_id = NEW.id
  WHERE invited_email = NEW.email
    AND status = 'pending'
    AND invited_user_id IS NULL;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Trigger: Update updated_at on Wines
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS wines_updated_at ON wines;
CREATE TRIGGER wines_updated_at
  BEFORE UPDATE ON wines
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- STORAGE BUCKETS & STORAGE POLICIES
-- ============================================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('labels', 'labels', true), ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Public Access for Labels' AND tablename = 'objects') THEN
    CREATE POLICY "Public Access for Labels" ON storage.objects FOR SELECT USING (bucket_id = 'labels');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated Upload Labels' AND tablename = 'objects') THEN
    CREATE POLICY "Authenticated Upload Labels" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'labels' AND auth.role() = 'authenticated');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated Update Labels' AND tablename = 'objects') THEN
    CREATE POLICY "Authenticated Update Labels" ON storage.objects FOR UPDATE USING (bucket_id = 'labels' AND auth.role() = 'authenticated');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated Delete Labels' AND tablename = 'objects') THEN
    CREATE POLICY "Authenticated Delete Labels" ON storage.objects FOR DELETE USING (bucket_id = 'labels' AND auth.role() = 'authenticated');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Public Access for Avatars' AND tablename = 'objects') THEN
    CREATE POLICY "Public Access for Avatars" ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated Upload Avatars' AND tablename = 'objects') THEN
    CREATE POLICY "Authenticated Upload Avatars" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Authenticated Update Avatars' AND tablename = 'objects') THEN
    CREATE POLICY "Authenticated Update Avatars" ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');
  END IF;
END $$;
