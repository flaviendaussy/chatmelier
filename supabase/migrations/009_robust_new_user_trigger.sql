-- ============================================================================
-- Migration 009: Robust handle_new_user with search_path and exception handling
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
DECLARE
  new_cellar_id UUID;
  user_name TEXT;
BEGIN
  user_name := COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    NEW.raw_user_meta_data->>'name',
    split_part(COALESCE(NEW.email, 'user'), '@', 1),
    'User'
  );

  -- 1. Create or update profile
  INSERT INTO public.profiles (id, display_name, default_currency)
  VALUES (NEW.id, user_name, 'EUR')
  ON CONFLICT (id) DO UPDATE 
    SET display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name);

  -- 2. Create default cellar
  INSERT INTO public.cellars (owner_id, name)
  VALUES (NEW.id, 'Ma Cave')
  RETURNING id INTO new_cellar_id;

  -- 3. Add cellar membership
  IF new_cellar_id IS NOT NULL THEN
    INSERT INTO public.cellar_members (cellar_id, user_id, role)
    VALUES (new_cellar_id, NEW.id, 'admin')
    ON CONFLICT (cellar_id, user_id) DO NOTHING;
  END IF;

  -- 4. Process pending cellar invites
  IF NEW.email IS NOT NULL THEN
    UPDATE public.cellar_invites
    SET invited_user_id = NEW.id
    WHERE LOWER(invited_email) = LOWER(NEW.email)
      AND status = 'pending'
      AND invited_user_id IS NULL;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user error: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- Ensure trigger is properly hooked
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
