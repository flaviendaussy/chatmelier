-- ============================================================================
-- Migration 007: Test user setup
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

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
