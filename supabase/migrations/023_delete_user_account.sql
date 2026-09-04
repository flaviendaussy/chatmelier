-- ============================================================================
-- MIGRATION 023: DELETE USER ACCOUNT RPC
-- ============================================================================
-- Conforms to:
-- - Apple App Store Review Guideline 5.1.1(v) (In-app account & data deletion)
-- - Google Play Account Deletion Requirement (2024)
-- - European GDPR / RGPD Right to Erasure (Article 17)
-- ============================================================================

CREATE OR REPLACE FUNCTION delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  calling_user_id UUID;
BEGIN
  -- 1. Identifier l'utilisateur connecté
  calling_user_id := auth.uid();
  IF calling_user_id IS NULL THEN
    RAISE EXCEPTION 'Non authentifié. Impossible de supprimer le compte.';
  END IF;

  -- 2. Supprimer les journaux et diagnostics liés
  DELETE FROM app_diagnostic_logs WHERE user_id = calling_user_id;

  -- 3. Supprimer les messages de discussion IA
  DELETE FROM chat_messages WHERE user_id = calling_user_id;

  -- 4. Supprimer le journal de dégustation
  DELETE FROM tasting_log WHERE user_id = calling_user_id;

  -- 5. Supprimer les demandes d'amis et amitiés
  DELETE FROM friendships WHERE user_id = calling_user_id OR friend_id = calling_user_id;

  -- 6. Supprimer le bar / pantry et les surcharges utilisateur
  DELETE FROM bar_pantries WHERE user_id = calling_user_id;
  DELETE FROM user_overrides WHERE user_id = calling_user_id;

  -- 7. Supprimer les invitations de cave envoyées ou reçues
  DELETE FROM cellar_invites WHERE invited_by = calling_user_id OR invited_user_id = calling_user_id;

  -- 8. Supprimer les bouteilles physiques ajoutées ou détenues par l'utilisateur
  DELETE FROM bottles WHERE owner_id = calling_user_id OR added_by = calling_user_id;

  -- 9. Supprimer l'adhésion aux caves partagées
  DELETE FROM cellar_members WHERE user_id = calling_user_id;

  -- 10. Supprimer les caves créées par l'utilisateur (déclenche la suppression en cascade)
  DELETE FROM cellars WHERE owner_id = calling_user_id;

  -- 11. Supprimer le profil utilisateur public
  DELETE FROM profiles WHERE id = calling_user_id;

  -- 12. Supprimer le compte de la table d'authentification Supabase (auth.users)
  DELETE FROM auth.users WHERE id = calling_user_id;
END;
$$;

-- Accorder les droits d'exécution aux utilisateurs authentifiés
GRANT EXECUTE ON FUNCTION delete_user_account() TO authenticated;
