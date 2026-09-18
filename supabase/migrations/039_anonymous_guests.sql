-- =============================================================================
-- 039 — Le convive anonyme : ce qu'il peut, ce qu'il ne peut pas, et sa purge
-- =============================================================================
-- Rejoindre une table ne doit demander aucun compte. Mais tout ce qui s'accumule ce
-- soir-là — les verres goûtés, le palais qui se dessine, la conversation avec le
-- sommelier — doit être écrit sous un vrai `user_id`, sinon la conversion demanderait
-- d'écrire un code de migration local → serveur, avec ses pertes et ses cas tordus.
--
-- D'où le compte anonyme de Supabase : un vrai utilisateur, sans formulaire. Ajouter une
-- adresse plus tard ne déplace rien — l'identifiant ne change pas.
--
-- PRÉALABLE MANUEL : « Allow anonymous sign-ins » doit être activé dans
-- Authentication → Providers. Il est désactivé par défaut. Sans lui, l'app continue de
-- fonctionner sans compte, comme avant.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Ce qu'un anonyme n'a pas à pouvoir faire
-- -----------------------------------------------------------------------------
-- `is_anonymous` est un claim du JWT, donc lisible en RLS. Un convive de passage n'a
-- aucune raison de créer une cave ou d'envoyer des demandes d'amitié : ce sont des gestes
-- de propriétaire, et les laisser ouverts offrirait un canal de spam gratuit.

CREATE OR REPLACE FUNCTION public.est_anonyme()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false);
$$;

COMMENT ON FUNCTION public.est_anonyme() IS
  'Vrai si la session courante est un compte anonyme (claim is_anonymous du JWT).';

DROP POLICY IF EXISTS "anon_cannot_create_cellars" ON public.cellars;
CREATE POLICY "anon_cannot_create_cellars"
  ON public.cellars AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (NOT public.est_anonyme());

DROP POLICY IF EXISTS "anon_cannot_request_friends" ON public.friendships;
CREATE POLICY "anon_cannot_request_friends"
  ON public.friendships AS RESTRICTIVE FOR INSERT TO authenticated
  WITH CHECK (NOT public.est_anonyme());

-- RESTRICTIVE et non PERMISSIVE : une politique permissive s'AJOUTE aux autres et
-- ouvrirait ce qu'elle prétend fermer. Une restrictive s'y superpose en ET — c'est la
-- seule forme qui interdit vraiment.

-- -----------------------------------------------------------------------------
-- 2. La purge
-- -----------------------------------------------------------------------------
-- Les comptes anonymes comptent dans les MAU, donc dans la facture. À l'échelle d'un bar
-- partenaire, un compte par convive et par soirée monte vite. Trente jours : la durée
-- qu'on annonce à la personne, et qu'on doit donc tenir — ni plus court, ce serait mentir,
-- ni indéfini, ce serait payer pour des comptes que personne ne réclamera.

-- La suppression des données d'un utilisateur existait déjà, dans `delete_user_account()`
-- (migration 023) : douze tables dans l'ordre exact où les clés étrangères le permettent.
-- En réécrire une seconde ici produirait deux routines qui divergeraient dès la première
-- table ajoutée — et celle qui se tromperait serait la moins relue. On extrait donc le
-- corps, et les deux appelants s'en servent.
CREATE OR REPLACE FUNCTION public.purger_donnees_utilisateur(p_user_id UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF p_user_id IS NULL THEN
    RAISE EXCEPTION 'purger_donnees_utilisateur: identifiant manquant';
  END IF;

  DELETE FROM app_diagnostic_logs WHERE user_id = p_user_id;
  DELETE FROM chat_messages       WHERE user_id = p_user_id;
  DELETE FROM tasting_log         WHERE user_id = p_user_id;
  DELETE FROM friendships         WHERE user_id = p_user_id OR friend_id = p_user_id;
  DELETE FROM bar_pantries        WHERE user_id = p_user_id;
  DELETE FROM user_overrides      WHERE user_id = p_user_id;
  DELETE FROM cellar_invites      WHERE invited_by = p_user_id OR invited_user_id = p_user_id;
  DELETE FROM bottles             WHERE owner_id = p_user_id OR added_by = p_user_id;
  DELETE FROM cellar_members      WHERE user_id = p_user_id;
  DELETE FROM cellars             WHERE owner_id = p_user_id;
  DELETE FROM profiles            WHERE id = p_user_id;
  DELETE FROM auth.users          WHERE id = p_user_id;
END;
$$;

REVOKE ALL ON FUNCTION public.purger_donnees_utilisateur(UUID) FROM PUBLIC;

-- La suppression de compte demandée par la personne elle-même passe désormais par là.
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Non authentifié. Impossible de supprimer le compte.';
  END IF;
  PERFORM public.purger_donnees_utilisateur(auth.uid());
END;
$$;

GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;

CREATE OR REPLACE FUNCTION public.purge_comptes_anonymes(p_jours INTEGER DEFAULT 30)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_n INTEGER := 0;
  v_id UUID;
BEGIN
  FOR v_id IN
    SELECT u.id
    FROM auth.users u
    WHERE u.is_anonymous IS TRUE
      AND u.email IS NULL                       -- jamais converti
      AND u.created_at < now() - (p_jours || ' days')::interval
      AND coalesce(u.last_sign_in_at, u.created_at)
            < now() - (p_jours || ' days')::interval
  LOOP
    PERFORM public.purger_donnees_utilisateur(v_id);
    v_n := v_n + 1;
  END LOOP;
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.purge_comptes_anonymes(INTEGER) FROM PUBLIC;

COMMENT ON FUNCTION public.purge_comptes_anonymes(INTEGER) IS
  'Supprime les comptes anonymes jamais convertis et inactifs depuis N jours. '
  'À planifier (pg_cron ou fonction edge quotidienne). Sans elle, la facture MAU croît '
  'indéfiniment pour des comptes que personne ne réclamera.';

-- Vérification :
--   SELECT est_anonyme();                     -- false depuis le SQL Editor
--   SELECT purge_comptes_anonymes(30);        -- renvoie le nombre supprimé
--   -- Depuis un client anonyme, l'INSERT suivant doit échouer :
--   --   INSERT INTO cellars (name, owner_id) VALUES ('Test', auth.uid());
