-- Migration 011: App Diagnostic Logs Table for centralized debugging
CREATE TABLE IF NOT EXISTS public.app_diagnostic_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    device_id TEXT,
    platform TEXT,
    app_version TEXT,
    tag TEXT NOT NULL,
    level TEXT NOT NULL,
    message TEXT NOT NULL,
    error_details TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Indices for rapid querying
CREATE INDEX IF NOT EXISTS idx_logs_tag ON public.app_diagnostic_logs(tag);
CREATE INDEX IF NOT EXISTS idx_logs_level ON public.app_diagnostic_logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_user_id ON public.app_diagnostic_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON public.app_diagnostic_logs(created_at DESC);

-- Enable RLS
ALTER TABLE public.app_diagnostic_logs ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to insert logs
CREATE POLICY "Allow authenticated insert to diagnostic logs"
ON public.app_diagnostic_logs
FOR INSERT
TO authenticated
WITH CHECK (true);

-- Allow anon to insert logs (e.g. auth failures, guest mode)
CREATE POLICY "Allow anon insert to diagnostic logs"
ON public.app_diagnostic_logs
FOR INSERT
TO anon
WITH CHECK (true);

-- Allow authenticated users to read logs
CREATE POLICY "Allow read diagnostic logs"
ON public.app_diagnostic_logs
FOR SELECT
TO authenticated
USING (true);

-- Allow anon to read diagnostic logs if needed
CREATE POLICY "Allow anon read diagnostic logs"
ON public.app_diagnostic_logs
FOR SELECT
TO anon
USING (true);
