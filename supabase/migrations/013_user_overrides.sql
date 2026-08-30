-- Migration 013: User Overrides on Wine Fields
-- Tracks which fields have been manually entered or edited by the user,
-- preventing automated AI enrichment from silently overwriting them.

ALTER TABLE wines
  ADD COLUMN IF NOT EXISTS user_overrides JSONB DEFAULT '[]'::jsonb;
