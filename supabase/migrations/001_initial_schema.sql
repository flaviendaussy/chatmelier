-- profiles (extends auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- cellars (owned by a user)
CREATE TABLE cellars (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL DEFAULT 'My Cellar',
  owner_id UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- cellar_members (sharing)
CREATE TABLE cellar_members (
  cellar_id UUID REFERENCES cellars(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'editor' CHECK (role IN ('viewer', 'editor', 'admin')),
  invited_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (cellar_id, user_id)
);

-- wines (canonical wine reference)
CREATE TABLE wines (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  vintage INT,
  wine_type TEXT CHECK (wine_type IN ('red', 'white', 'rosé', 'sparkling', 'dessert', 'fortified', 'orange')),
  country TEXT,
  region TEXT,
  sub_region TEXT,
  appellation TEXT,
  classification TEXT,
  producer TEXT,
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
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- bottles (physical bottles in a cellar)
CREATE TABLE bottles (
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

-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- bottle_photos
CREATE TABLE bottle_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bottle_id UUID REFERENCES bottles(id) ON DELETE CASCADE,
  wine_id UUID REFERENCES wines(id),
  storage_path TEXT NOT NULL,
  photo_type TEXT DEFAULT 'front' CHECK (photo_type IN ('front', 'back', 'neck', 'full')),
  embedding VECTOR(768),
  created_at TIMESTAMPTZ DEFAULT now()
);

-- tasting_log
CREATE TABLE tasting_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bottle_id UUID REFERENCES bottles(id),
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

-- chat_messages (for AI sommelier chat history)
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID NOT NULL REFERENCES cellars(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
  content TEXT NOT NULL,
  referenced_bottle_ids JSONB DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Indexes
CREATE INDEX bottle_photos_embedding_idx ON bottle_photos USING hnsw (embedding vector_cosine_ops);
CREATE INDEX bottles_cellar_id_idx ON bottles(cellar_id);
CREATE INDEX bottles_wine_id_idx ON bottles(wine_id);
CREATE INDEX bottles_status_idx ON bottles(status);
CREATE INDEX bottles_owner_id_idx ON bottles(owner_id);
CREATE INDEX tasting_log_wine_id_idx ON tasting_log(wine_id);
CREATE INDEX tasting_log_user_id_idx ON tasting_log(user_id);
CREATE INDEX chat_messages_cellar_id_idx ON chat_messages(cellar_id);

-- Full-text search on wines
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

CREATE INDEX wines_fts_idx ON wines USING gin(fts);

-- Trigger to auto-create profile and cellar on user signup
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

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER wines_updated_at
  BEFORE UPDATE ON wines
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();