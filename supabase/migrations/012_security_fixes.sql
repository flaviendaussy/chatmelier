-- Migration 012: Security Fixes

-- 1. Index on cellar_members(user_id)
CREATE INDEX IF NOT EXISTS cellar_members_user_id_idx ON cellar_members(user_id);

-- 2. Fix the diagnostic logs RLS
DROP POLICY IF EXISTS "Allow read diagnostic logs" ON public.app_diagnostic_logs;
DROP POLICY IF EXISTS "Allow anon read diagnostic logs" ON public.app_diagnostic_logs;

CREATE POLICY "Allow authenticated read own diagnostic logs"
ON public.app_diagnostic_logs
FOR SELECT
TO authenticated
USING (user_id = auth.uid());

-- 3. Restrict record_wine_valuation to only service_role
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
  IF auth.role() != 'service_role' THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

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
