-- ============================================================================
-- Migration 017: Profile Uniqueness Constraints & Metadata Synchronization
-- ============================================================================

-- 1. Ensure username, phone_number, email and taste_profile exist on profiles table
ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS username TEXT,
  ADD COLUMN IF NOT EXISTS phone_number TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS taste_profile JSONB DEFAULT '{}'::jsonb;

-- 2. Strict case-insensitive unique indexes to guarantee exclusivity across all accounts
CREATE UNIQUE INDEX IF NOT EXISTS profiles_lower_username_idx 
  ON profiles (LOWER(TRIM(username))) 
  WHERE username IS NOT NULL AND TRIM(username) <> '';

CREATE UNIQUE INDEX IF NOT EXISTS profiles_lower_email_idx 
  ON profiles (LOWER(TRIM(email))) 
  WHERE email IS NOT NULL AND TRIM(email) <> '';

CREATE UNIQUE INDEX IF NOT EXISTS profiles_normalized_phone_idx 
  ON profiles (phone_number) 
  WHERE phone_number IS NOT NULL AND TRIM(phone_number) <> '';

-- 3. Automatic synchronization from auth.users user_metadata into public.profiles
CREATE OR REPLACE FUNCTION public.sync_profile_from_user_meta()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  v_username TEXT;
  v_phone TEXT;
  v_email TEXT;
  v_name TEXT;
BEGIN
  v_username := LOWER(TRIM(COALESCE(NEW.raw_user_meta_data->>'username', '')));
  v_phone := TRIM(COALESCE(NEW.raw_user_meta_data->>'phone_number', ''));
  v_email := LOWER(TRIM(COALESCE(NEW.email, NEW.raw_user_meta_data->>'email', '')));
  v_name := COALESCE(NEW.raw_user_meta_data->>'display_name', NEW.raw_user_meta_data->>'name', split_part(COALESCE(NEW.email, 'user'), '@', 1));

  INSERT INTO public.profiles (id, display_name, username, phone_number, email, default_currency)
  VALUES (
    NEW.id,
    v_name,
    NULLIF(v_username, ''),
    NULLIF(v_phone, ''),
    NULLIF(v_email, ''),
    'EUR'
  )
  ON CONFLICT (id) DO UPDATE
    SET display_name = COALESCE(NULLIF(EXCLUDED.display_name, ''), public.profiles.display_name),
        username = COALESCE(NULLIF(EXCLUDED.username, ''), public.profiles.username),
        phone_number = COALESCE(NULLIF(EXCLUDED.phone_number, ''), public.profiles.phone_number),
        email = COALESCE(NULLIF(EXCLUDED.email, ''), public.profiles.email);

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'sync_profile_from_user_meta error: %', SQLERRM;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_updated_sync_profile ON auth.users;
CREATE TRIGGER on_auth_user_updated_sync_profile
  AFTER INSERT OR UPDATE OF raw_user_meta_data, email ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.sync_profile_from_user_meta();
