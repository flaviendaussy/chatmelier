-- ============================================================================
-- Migration 014: Cellar Wi-Fi SSID and Geofencing Proximity Settings
-- ============================================================================

ALTER TABLE cellars 
  ADD COLUMN IF NOT EXISTS wifi_ssid TEXT,
  ADD COLUMN IF NOT EXISTS radius_meters INT DEFAULT 300;
