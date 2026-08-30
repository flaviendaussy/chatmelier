-- ============================================================================
-- Migration 010: Auto Admin on Cellar Creation & Multi-Cellar Helpers
-- ============================================================================

-- 1. Trigger to automatically add the cellar creator as admin in cellar_members
CREATE OR REPLACE FUNCTION public.handle_new_cellar()
RETURNS TRIGGER 
LANGUAGE plpgsql 
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  INSERT INTO public.cellar_members (cellar_id, user_id, role)
  VALUES (NEW.id, NEW.owner_id, 'admin')
  ON CONFLICT (cellar_id, user_id) DO NOTHING;
  
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_cellar_created ON public.cellars;
CREATE TRIGGER on_cellar_created
  AFTER INSERT ON public.cellars
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_cellar();

-- 2. Helper function to create a new cellar safely and return cellar with membership
CREATE OR REPLACE FUNCTION create_new_cellar(
  p_name TEXT,
  p_nickname TEXT DEFAULT NULL,
  p_location_name TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_user_id UUID;
  v_cellar_id UUID;
  v_cellar_record RECORD;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  INSERT INTO public.cellars (name, nickname, location_name, description, owner_id)
  VALUES (p_name, p_nickname, p_location_name, p_description, v_user_id)
  RETURNING * INTO v_cellar_record;

  v_cellar_id := v_cellar_record.id;

  INSERT INTO public.cellar_members (cellar_id, user_id, role)
  VALUES (v_cellar_id, v_user_id, 'admin')
  ON CONFLICT (cellar_id, user_id) DO UPDATE SET role = 'admin';

  RETURN json_build_object(
    'id', v_cellar_record.id,
    'name', v_cellar_record.name,
    'nickname', v_cellar_record.nickname,
    'location_name', v_cellar_record.location_name,
    'description', v_cellar_record.description,
    'owner_id', v_cellar_record.owner_id,
    'created_at', v_cellar_record.created_at,
    'role', 'admin'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
