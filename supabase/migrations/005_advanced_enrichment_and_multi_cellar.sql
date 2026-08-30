-- ============================================================================
-- Migration 005: Advanced Wine Enrichment, Critic Rankings, Multi-Cellar Locations & Price Tracking
-- ============================================================================

-- 1. Multi-Cellar Location & Nickname Support
ALTER TABLE cellars 
  ADD COLUMN IF NOT EXISTS nickname TEXT,
  ADD COLUMN IF NOT EXISTS location_name TEXT,
  ADD COLUMN IF NOT EXISTS latitude NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS longitude NUMERIC(9,6),
  ADD COLUMN IF NOT EXISTS description TEXT;

-- 2. Enhanced Wine Schema (Zero Hallucination internet enrichment, top 5 critic scores, cuvée/parcel distinction)
ALTER TABLE wines
  ADD COLUMN IF NOT EXISTS cuvee_parcel TEXT, -- e.g. "Les Clos", "Vieilles Vignes", "Cuvée Frédéric Emile"
  ADD COLUMN IF NOT EXISTS critic_scores JSONB DEFAULT '[]'::jsonb, -- Max 5 trusted sources (e.g. Parker, Spectator, Suckling, Robinson, Decanter)
  ADD COLUMN IF NOT EXISTS estimated_market_value NUMERIC(10,2), -- Current estimated price per bottle
  ADD COLUMN IF NOT EXISTS estimated_value_currency TEXT DEFAULT 'EUR',
  ADD COLUMN IF NOT EXISTS last_valuation_date TIMESTAMPTZ DEFAULT now(),
  ADD COLUMN IF NOT EXISTS valuation_history JSONB DEFAULT '[]'::jsonb, -- Historical valuation logs: [{date, value, currency, source}]
  ADD COLUMN IF NOT EXISTS sources_verified JSONB DEFAULT '[]'::jsonb, -- Internet citations & URLs used for enrichment
  ADD COLUMN IF NOT EXISTS is_verified_online BOOLEAN DEFAULT false;

-- Index on wine identification for fast deduplication cache hits
CREATE INDEX IF NOT EXISTS wines_dedup_idx ON wines (
  lower(trim(coalesce(producer, ''))), 
  lower(trim(name)), 
  vintage, 
  lower(trim(coalesce(cuvee_parcel, '')))
);

-- 3. Function: Find exact wine match in database cache (to prevent duplicate AI API billing)
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

-- 4. Function: Get wines needing 6-month market value refresh
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

-- 5. Function: Record updated valuation for a wine
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

-- 6. Updated Cellar Stats to include Estimated Total Value alongside Paid Price
CREATE OR REPLACE FUNCTION get_cellar_stats_v2(p_cellar_id UUID)
RETURNS JSON AS $$
DECLARE
  stats JSON;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cellar_members 
    WHERE cellar_id = p_cellar_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized access to cellar';
  END IF;

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
