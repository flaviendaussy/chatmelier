-- ============================================================================
-- Migration 008: Add currency support for bottles and user profiles
-- ============================================================================

ALTER TABLE bottles 
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'EUR';

ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS default_currency TEXT NOT NULL DEFAULT 'EUR';

CREATE INDEX IF NOT EXISTS idx_bottles_currency ON bottles(currency);
