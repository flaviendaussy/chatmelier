-- Migration 029: Rôle administrateur vérifié côté serveur
--
-- Contexte : le client déterminait le statut admin par
--   `kDebugMode || user.email.contains('flavien')`
-- (profile_screen.dart, rewarded_video_ad_sheet.dart). N'importe qui pouvait donc
-- obtenir les privilèges admin en s'inscrivant avec une adresse contenant « flavien »
-- (ex. flavien@mailinator.com), ou en lançant un build debug.
--
-- Cette migration déplace la décision côté serveur, avec un drapeau que
-- l'utilisateur peut LIRE mais jamais ÉCRIRE.

-- 1. La colonne, fermée par défaut
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.profiles.is_admin IS
  'Privilège administrateur. Modifiable uniquement par le service_role (console Supabase). '
  'Jamais écrit par le client : voir le trigger protect_is_admin ci-dessous.';

-- 2. Empêcher toute élévation de privilège par le client.
--    Les politiques RLS d'UPDATE sur `profiles` autorisent l'utilisateur à modifier sa
--    propre ligne ; sans ce garde-fou il pourrait y écrire is_admin = true.
CREATE OR REPLACE FUNCTION public.protect_is_admin()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Le service_role (console d'admin, tâches serveur) passe sans contrainte.
  IF auth.role() = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Pour tout le reste, is_admin est figé sur sa valeur précédente.
  IF NEW.is_admin IS DISTINCT FROM OLD.is_admin THEN
    NEW.is_admin := OLD.is_admin;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_is_admin ON public.profiles;
CREATE TRIGGER trg_protect_is_admin
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_is_admin();

-- Même protection à l'insertion : un nouveau profil ne peut pas naître admin.
CREATE OR REPLACE FUNCTION public.protect_is_admin_on_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.role() <> 'service_role' THEN
    NEW.is_admin := FALSE;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_is_admin_insert ON public.profiles;
CREATE TRIGGER trg_protect_is_admin_insert
  BEFORE INSERT ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_is_admin_on_insert();

-- 3. Helper lisible depuis les politiques RLS d'autres tables si besoin.
CREATE OR REPLACE FUNCTION public.is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT is_admin FROM public.profiles WHERE id = auth.uid()),
    FALSE
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_current_user_admin() TO authenticated;

-- 4. À FAIRE MANUELLEMENT après application, depuis la console Supabase (SQL Editor),
--    en remplaçant l'adresse par la vôtre. Volontairement non automatisé : aucune
--    adresse en dur dans un dépôt public.
--
--    UPDATE public.profiles SET is_admin = TRUE
--    WHERE id = (SELECT id FROM auth.users WHERE email = 'votre@adresse.tld');
