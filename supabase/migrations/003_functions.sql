-- Complex search function
CREATE OR REPLACE FUNCTION search_bottles(
  p_cellar_id UUID,
  p_query TEXT DEFAULT NULL,
  p_wine_type TEXT DEFAULT NULL,
  p_country TEXT DEFAULT NULL,
  p_region TEXT DEFAULT NULL,
  p_owner_id UUID DEFAULT NULL,
  p_status TEXT DEFAULT 'in_cellar',
  p_drinking_window_status TEXT DEFAULT NULL, -- 'ready', 'drink_soon', 'past_peak'
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
  IF NOT EXISTS (
    SELECT 1 FROM cellar_members 
    WHERE cellar_id = p_cellar_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized access to cellar';
  END IF;

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

-- Cellar stats
CREATE OR REPLACE FUNCTION get_cellar_stats(p_cellar_id UUID)
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
    'total_bottles', COALESCE(SUM(quantity) FILTER (WHERE status = 'in_cellar'), 0),
    'total_consumed', COALESCE(SUM(quantity) FILTER (WHERE status = 'consumed'), 0),
    'total_value', COALESCE(SUM(quantity * purchase_price) FILTER (WHERE status = 'in_cellar'), 0),
    'by_type', (
      SELECT json_object_agg(wine_type, count)
      FROM (
        SELECT w.wine_type, SUM(b.quantity) as count 
        FROM bottles b JOIN wines w ON b.wine_id = w.id 
        WHERE b.cellar_id = p_cellar_id AND b.status = 'in_cellar' 
        GROUP BY w.wine_type
      ) t
    ),
    'drink_soon_count', (
      SELECT COALESCE(SUM(b.quantity), 0)
      FROM bottles b JOIN wines w ON b.wine_id = w.id
      WHERE b.cellar_id = p_cellar_id AND b.status = 'in_cellar'
      AND EXTRACT(YEAR FROM now()) >= w.ideal_drinking_end - 1 
      AND EXTRACT(YEAR FROM now()) <= w.ideal_drinking_end
    ),
    'past_peak_count', (
      SELECT COALESCE(SUM(b.quantity), 0)
      FROM bottles b JOIN wines w ON b.wine_id = w.id
      WHERE b.cellar_id = p_cellar_id AND b.status = 'in_cellar'
      AND EXTRACT(YEAR FROM now()) > w.peak_drinking_end
    )
  ) INTO stats
  FROM bottles
  WHERE cellar_id = p_cellar_id;
  
  RETURN stats;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Visual match
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
  IF NOT EXISTS (
    SELECT 1 FROM cellar_members 
    WHERE cellar_id = p_cellar_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized access to cellar';
  END IF;

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

-- Drink soon
CREATE OR REPLACE FUNCTION get_drink_soon_bottles(p_cellar_id UUID, p_months_ahead INT DEFAULT 12)
RETURNS TABLE (
  bottle_id UUID,
  wine_name TEXT,
  vintage INT,
  ideal_drinking_end INT
) AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cellar_members 
    WHERE cellar_id = p_cellar_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized access to cellar';
  END IF;

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

-- Monthly consumption
CREATE OR REPLACE FUNCTION get_monthly_consumption(p_cellar_id UUID, p_months INT DEFAULT 12)
RETURNS TABLE (
  month DATE,
  count BIGINT
) AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM cellar_members 
    WHERE cellar_id = p_cellar_id AND user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Unauthorized access to cellar';
  END IF;

  RETURN QUERY
  SELECT 
    date_trunc('month', consumed_at)::date AS month,
    SUM(quantity)::BIGINT AS count
  FROM bottles
  WHERE cellar_id = p_cellar_id 
    AND status = 'consumed'
    AND consumed_at >= date_trunc('month', now()) - (p_months || ' months')::interval
  GROUP BY 1
  ORDER BY 1 DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;