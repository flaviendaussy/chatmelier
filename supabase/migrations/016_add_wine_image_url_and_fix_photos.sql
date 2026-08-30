-- Migration 016: Add explicit image_url column to wines table and support robust photo linking

-- 1. Add image_url to wines if not already present
ALTER TABLE wines ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE wines ADD COLUMN IF NOT EXISTS label_image_url TEXT;

-- 2. Allow bottle_photos bottle_id to be nullable or cascade cleanly
ALTER TABLE bottle_photos ALTER COLUMN bottle_id DROP NOT NULL;

-- 3. Create index for fast image lookups
CREATE INDEX IF NOT EXISTS idx_wines_image_url ON wines(image_url) WHERE image_url IS NOT NULL;
