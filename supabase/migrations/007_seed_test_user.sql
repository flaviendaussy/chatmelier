-- ⚠️  MIGRATION NEUTRALISÉE LE 2026-09-16 — NE PAS REJOUER
--
-- Cette migration créait un compte `flavien@chatmelier.app` avec le mot de passe
-- `Secret1234` écrit en clair. Le dépôt `origin` étant PUBLIC, cet identifiant est
-- lisible par quiconque clone le projet, et il le reste dans l'historique git même
-- après ce commit.
--
-- Le compte a été confirmé présent en production le 2026-09-16 (dernière connexion :
-- 2026-09-05). Il n'était pas administrateur.
--
-- Pire que la création : la branche `ELSE` **réinitialisait le mot de passe** si le
-- compte existait déjà. Rejouer cette migration réarmait donc la faille, même après
-- l'avoir corrigée à la main. C'est pour cela que le corps est mis hors service ici
-- plutôt que simplement commenté en tête.
--
-- Pour recréer un compte de test : le faire depuis la console Supabase, avec un mot de
-- passe qui n'est écrit nulle part dans le dépôt.

-- ============================================================================
-- Migration 007: Test user setup
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

/* NEUTRALISÉ — voir l'en-tête
DO $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_email TEXT := 'flavien@chatmelier.app';
  v_pw TEXT := extensions.crypt('Secret1234', extensions.gen_salt('bf'));
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE email = v_email) THEN
    INSERT INTO auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at, confirmation_token, email_change, email_change_token_new, recovery_token
    ) VALUES (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      v_pw,
      now(),
      '{"provider":"email","providers":["email"]}',
      '{"display_name":"Flavien"}',
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  ELSE
    UPDATE auth.users 
    SET encrypted_password = v_pw,
        email_confirmed_at = now()
    WHERE email = v_email;
  END IF;
END $$;
*/
