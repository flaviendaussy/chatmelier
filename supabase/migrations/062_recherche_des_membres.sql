-- 062 — Chercher un membre sans télécharger l'annuaire (PROD_MIGRATION.md · RGPD, fait le 08/10)
--
-- `AuthRepository.searchUsers` lisait les 50 premiers profils et filtrait sur le
-- téléphone : tout compte connecté recevait prénoms et avatars de cinquante personnes à
-- chaque recherche, et au-delà de cinquante comptes la recherche ne trouvait plus
-- personne. La recherche se fait désormais en base, et ne rend que les correspondances
-- (vingt au plus), à un compte non anonyme (les anonymes ne peuvent déjà pas demander
-- d'amis, migration 039).
--
-- En production, `profiles` porte `display_name` et `avatar_url`, où le pseudo voyage sous
-- la forme `meta://?u=<pseudo>` (pas de colonne `username`) : on cherche dans les deux.
--
-- Reste à faire avant l'ouverture publique (non fait ici, car l'app lit `profiles` en
-- direct à plusieurs endroits — amis, convives, notifications) : restreindre la politique
-- « Public profiles are viewable by everyone ».
--
-- Rejouable. Aucune donnée n'est modifiée.

CREATE OR REPLACE FUNCTION public.pseudo_du_profil(p_avatar_url TEXT)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT nullif(lower(substring(coalesce(p_avatar_url, '') from '^meta://\?(?:.*&)?u=([^&]*)')), '');
$$;

CREATE OR REPLACE FUNCTION public.chercher_des_membres(p_texte TEXT)
RETURNS TABLE (id UUID, display_name TEXT, avatar_url TEXT)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_q    TEXT := lower(btrim(replace(coalesce(p_texte, ''), '@', '')));
  v_like TEXT;
BEGIN
  IF auth.uid() IS NULL OR public.est_anonyme() THEN
    RAISE EXCEPTION 'compte_requis';
  END IF;
  IF char_length(v_q) < 2 OR char_length(v_q) > 60 THEN
    RETURN;
  END IF;
  -- Les jokers tapés (%, _) sont des caractères, pas des jokers.
  v_like := '%' || replace(replace(replace(v_q, '\', '\\'), '%', '\%'), '_', '\_') || '%';
  RETURN QUERY
    SELECT p.id, p.display_name, p.avatar_url
    FROM public.profiles p
    WHERE p.id <> auth.uid()
      AND (lower(coalesce(p.display_name, '')) LIKE v_like
           OR coalesce(public.pseudo_du_profil(p.avatar_url), '') LIKE v_like)
    ORDER BY (public.pseudo_du_profil(p.avatar_url) = v_q) DESC NULLS LAST,
             (lower(p.display_name) = v_q) DESC NULLS LAST,
             p.display_name
    LIMIT 20;
END;
$$;

REVOKE ALL ON FUNCTION public.chercher_des_membres(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.chercher_des_membres(TEXT) TO authenticated;

-- Retour arrière :
--   DROP FUNCTION public.chercher_des_membres(TEXT), public.pseudo_du_profil(TEXT);

-- Vérification (SQL Editor) :
--   SELECT public.pseudo_du_profil('meta://?u=flavien');              → flavien
--   SELECT public.pseudo_du_profil('https://exemple.org/a.png');      → NULL
