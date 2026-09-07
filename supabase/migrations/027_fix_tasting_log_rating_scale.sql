-- Migration 027: Update tasting_log rating constraint to allow 0 to 10 scale
-- Previous constraint checked rating <= 5, whereas the app uses a 0 to 10 scale.

ALTER TABLE tasting_log DROP CONSTRAINT IF EXISTS tasting_log_rating_check;
ALTER TABLE tasting_log ALTER COLUMN rating TYPE NUMERIC(3,1);
ALTER TABLE tasting_log ADD CONSTRAINT tasting_log_rating_check CHECK (rating >= 0 AND rating <= 10);
