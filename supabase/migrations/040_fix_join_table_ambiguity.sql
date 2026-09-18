-- =============================================================================
-- 040 — Rejoindre une table ne fonctionnait pas
-- =============================================================================
-- CONSTAT, trouvé en ouvrant une vraie table depuis l'app puis en la rejoignant :
--
--   ERROR: column reference "session_id" is ambiguous
--
-- `join_table_session` déclare `RETURNS TABLE (session_id UUID, …)`. En PL/pgSQL, les
-- colonnes de sortie d'un RETURNS TABLE sont des VARIABLES. Dans la clause
-- `ON CONFLICT (session_id, guest_name)` de l'INSERT, le nom `session_id` désigne donc à
-- la fois cette variable et la colonne de `table_session_guests` — et PostgreSQL refuse
-- de choisir.
--
-- POURQUOI PERSONNE NE L'AVAIT VU. Le test en direct n'avait exercé que le chemin
-- d'erreur : un code inconnu lève `table_introuvable` AVANT d'atteindre l'INSERT. Le
-- refus fonctionnait parfaitement, l'acceptation n'avait jamais tourné. Les tests Dart,
-- eux, ne peuvent pas atteindre une fonction SQL.
--
-- `#variable_conflict use_column` fait trancher en faveur de la colonne partout où
-- l'ambiguïté se pose — ce qui est le sens voulu dans cet INSERT. Les autres références
-- sont qualifiées (`v_session.id`, `s.code`) et ne changent pas de sens.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.join_table_session(
  p_code       TEXT,
  p_guest_name TEXT,
  p_profile    JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE (
  session_id      UUID,
  restaurant_name TEXT,
  menu            JSONB,
  expires_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
#variable_conflict use_column
DECLARE
  v_session public.table_sessions%ROWTYPE;
BEGIN
  SELECT * INTO v_session
  FROM public.table_sessions s
  WHERE s.code = upper(trim(p_code)) AND s.expires_at > now();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'table_introuvable'
      USING HINT = 'Code inconnu ou table expirée.';
  END IF;

  IF coalesce(trim(p_guest_name), '') = '' THEN
    RAISE EXCEPTION 'nom_requis' USING HINT = 'Un nom est nécessaire pour rejoindre.';
  END IF;

  INSERT INTO public.table_session_guests AS g (session_id, user_id, guest_name, profile)
  VALUES (v_session.id, auth.uid(), trim(p_guest_name), coalesce(p_profile, '{}'::jsonb))
  ON CONFLICT (session_id, guest_name)
    DO UPDATE SET profile = EXCLUDED.profile;

  RETURN QUERY SELECT v_session.id, v_session.restaurant_name,
                      v_session.menu, v_session.expires_at;
END;
$$;

GRANT EXECUTE ON FUNCTION public.join_table_session(TEXT, TEXT, JSONB) TO anon, authenticated;

-- Vérification, avec un code de table réellement ouverte :
--   SELECT * FROM join_table_session('<CODE>', 'Paul');       -- doit renvoyer la carte
--   SELECT * FROM read_table_session_guests('<CODE>');        -- doit lister Paul
--   SELECT * FROM join_table_session('ZZZZZZ', 'Paul');       -- doit lever table_introuvable
