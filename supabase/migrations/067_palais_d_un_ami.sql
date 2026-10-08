-- =============================================================================
-- 067 — La carte de goût d'un ami (V2.4 · R5)
-- =============================================================================
--
-- Le palais de chacun vit dans `palais_utilisateur` (050), lisible par lui seul : la carte
-- de goût d'un ami se construisait sur d'anciens champs du profil, vides pour qui n'a fait
-- que noter des vins (« Caro's taste card seems empty », 04/10), et ses amis n'étaient pas
-- proposés dans le radar (« I want to have Caro suggested for the overlay »).
--
-- `palais_d_un_ami(ami)` rend le seul profil principal de cet ami — ni ses autres profils
-- (les proches qu'il a créés), ni le registre des preuves, ni l'historique, ni ses notes
-- libres —, et seulement entre amis dont l'amitié est acceptée.
--
-- Rejouable.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.palais_d_un_ami(p_ami UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_moi       UUID := auth.uid();
  v_profils   JSONB;
  v_principal JSONB;
BEGIN
  IF v_moi IS NULL THEN
    RAISE EXCEPTION 'session_requise';
  END IF;
  IF p_ami IS NULL OR p_ami = v_moi THEN
    RETURN NULL;
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.friendships f
        WHERE f.status = 'accepted'
          AND ((f.user_id = v_moi AND f.friend_id = p_ami) OR (f.user_id = p_ami AND f.friend_id = v_moi))) THEN
    RAISE EXCEPTION 'pas_ami';
  END IF;

  SELECT pu.profils INTO v_profils FROM public.palais_utilisateur pu WHERE pu.user_id = p_ami;
  IF v_profils IS NULL OR jsonb_typeof(v_profils) <> 'array' OR jsonb_array_length(v_profils) = 0 THEN
    RETURN NULL;
  END IF;
  SELECT p INTO v_principal
    FROM jsonb_array_elements(v_profils) p
   WHERE jsonb_typeof(p) = 'object' AND (p ->> 'is_primary') = 'true'
   LIMIT 1;
  v_principal := coalesce(v_principal, v_profils -> 0);
  IF jsonb_typeof(v_principal) <> 'object' THEN
    RETURN NULL;
  END IF;
  -- Ses notes libres restent à lui.
  RETURN v_principal - 'notes';
END;
$$;

REVOKE ALL ON FUNCTION public.palais_d_un_ami(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.palais_d_un_ami(UUID) TO authenticated;

-- Retour arrière :
--   DROP FUNCTION public.palais_d_un_ami(UUID);

-- Vérification (SQL Editor) :
--   SELECT proname FROM pg_proc WHERE proname = 'palais_d_un_ami';
