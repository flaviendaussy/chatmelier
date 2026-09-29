-- =============================================================================
-- 049 — La suppression de compte, réparée (29/09) — À APPLIQUER EN PRIORITÉ
-- =============================================================================
-- Depuis la migration 039, delete_user_account() échoue en production : personne ne
-- peut plus supprimer son compte (obligation RGPD, Google Play et App Store), et la purge
-- des comptes anonymes échoue de même. Détail ci-dessous.
-- =============================================================================

-- La 039 a remplacé la version corrigée par la 031 : elle visait `bar_pantries` (la table
-- s'appelle `bar_pantry`) et `user_overrides` (absente en production), et oubliait les
-- notifications, les demandes d'accès et les photos. Depuis, delete_user_account()
-- échouait sur « relation does not exist » : plus personne ne pouvait supprimer son
-- compte, et purge_comptes_anonymes() non plus.
--
-- Et même la version de la 031 butait sur deux clés relevées dans le catalogue de
-- production (29/09), en NO ACTION : tasting_log.cellar_id et tasting_log.bottle_owner_id.
-- Une seule dégustation d'un ami dans votre cave suffisait à bloquer la suppression. Les
-- dégustations des autres restent ; elles perdent seulement le lien vers ce qui disparaît.
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

  -- Ce qui est à la personne.
  DELETE FROM app_diagnostic_logs    WHERE user_id = p_user_id;
  DELETE FROM chat_messages          WHERE user_id = p_user_id;
  DELETE FROM tasting_log            WHERE user_id = p_user_id;

  -- Ce que les autres ont écrit et qui la désignait : on garde, on détache.
  UPDATE tasting_log SET bottle_owner_id = NULL WHERE bottle_owner_id = p_user_id;
  UPDATE tasting_log SET cellar_id = NULL
    WHERE cellar_id IN (SELECT id FROM cellars WHERE owner_id = p_user_id);

  DELETE FROM friendships            WHERE user_id = p_user_id OR friend_id = p_user_id;
  DELETE FROM user_notifications     WHERE user_id = p_user_id OR actor_id = p_user_id;
  DELETE FROM cellar_access_requests WHERE requester_id = p_user_id OR owner_id = p_user_id;
  DELETE FROM bar_pantry             WHERE user_id = p_user_id;
  DELETE FROM cellar_invites         WHERE invited_by = p_user_id OR invited_user_id = p_user_id;

  -- Les bouteilles qu'elle a rangées dans la cave d'un autre restent à leur propriétaire.
  UPDATE bottles SET added_by = owner_id WHERE added_by = p_user_id AND owner_id <> p_user_id;
  DELETE FROM bottles WHERE owner_id = p_user_id;          -- photos : en cascade

  -- Ses caves (bouteilles, membres, invitations, meubles, demandes : en cascade).
  DELETE FROM cellar_members WHERE user_id = p_user_id;
  DELETE FROM cellars        WHERE owner_id = p_user_id;
  DELETE FROM profiles       WHERE id = p_user_id;

  IF to_regclass('public.user_overrides') IS NOT NULL THEN
    EXECUTE format('DELETE FROM public.user_overrides WHERE user_id = %L', p_user_id);
  END IF;

  -- Palais, codes de reprise, coûts, impressions : en cascade depuis auth.users.
  DELETE FROM auth.users WHERE id = p_user_id;
END;
$$;
REVOKE ALL ON FUNCTION public.purger_donnees_utilisateur(UUID) FROM PUBLIC;

-- Vérification :
--   SELECT prosrc LIKE '%bar_pantries%' AS encore_casse FROM pg_proc
--   WHERE proname = 'purger_donnees_utilisateur';
--     → false
-- Puis, depuis l'app, supprimer un compte de test : l'écran doit confirmer, et
--   SELECT count(*) FROM auth.users WHERE id = '<id du compte de test>';  → 0
