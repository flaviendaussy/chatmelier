-- Migration 022: Add fill_level & source_details to bottles, alcohol_pct & image_url to wines

-- 1. Bottles: Add fill_level (percentage 0-100), source_type and source_details
ALTER TABLE bottles ADD COLUMN IF NOT EXISTS fill_level INT DEFAULT 100;
ALTER TABLE bottles ADD COLUMN IF NOT EXISTS source_type TEXT;
ALTER TABLE bottles ADD COLUMN IF NOT EXISTS source_details TEXT;

-- 2. Wines: Ensure alcohol_pct and image_url exist
ALTER TABLE wines ADD COLUMN IF NOT EXISTS alcohol_pct NUMERIC(4,2);
ALTER TABLE wines ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE wines ADD COLUMN IF NOT EXISTS label_image_url TEXT;

-- 3. Comments for documentation
COMMENT ON COLUMN bottles.fill_level IS 'Remaining liquid level in spirits bottle (0-100 percent)';
COMMENT ON COLUMN wines.alcohol_pct IS 'Alcohol by volume percentage (ABV / % vol)';
