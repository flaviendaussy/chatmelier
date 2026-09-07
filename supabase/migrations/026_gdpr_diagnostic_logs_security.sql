-- Migration 026: GDPR & Security hardening for App Diagnostic Logs
-- 1. Revoke public/anon read access to diagnostic logs
DROP POLICY IF EXISTS "Allow anon read diagnostic logs" ON public.app_diagnostic_logs;
DROP POLICY IF EXISTS "Allow read diagnostic logs" ON public.app_diagnostic_logs;

-- 2. Restrict SELECT to authenticated users for their own logs only (or service role)
CREATE POLICY "Users can only read own diagnostic logs"
ON public.app_diagnostic_logs
FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

-- 3. Automatic log retention policy (GDPR Storage Limitation - Article 5(1)(e))
-- Diagnostic logs older than 30 days are purged to comply with data minimization
CREATE OR REPLACE FUNCTION public.cleanup_old_diagnostic_logs(days_to_keep INT DEFAULT 30)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM public.app_diagnostic_logs
    WHERE created_at < NOW() - (days_to_keep || ' days')::INTERVAL;
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- Grant execution to service_role and postgres only
REVOKE EXECUTE ON FUNCTION public.cleanup_old_diagnostic_logs(INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cleanup_old_diagnostic_logs(INT) TO service_role;
