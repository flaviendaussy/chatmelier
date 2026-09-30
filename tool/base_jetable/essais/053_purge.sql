-- Essais de la migration 053 : la purge épargne les codes de reprise, le ménage, la croissance.
\set ON_ERROR_STOP on

-- Ce que 049 et 050 fournissent en production, réduit au nécessaire.
CREATE TABLE IF NOT EXISTS public.codes_de_reprise (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  empreinte BYTEA NOT NULL DEFAULT extensions.gen_random_bytes(8),
  cree_le TIMESTAMPTZ NOT NULL DEFAULT now(),
  expire_le TIMESTAMPTZ NOT NULL,
  utilise_le TIMESTAMPTZ
);
CREATE TABLE IF NOT EXISTS public.tentatives_de_reprise (
  id BIGSERIAL PRIMARY KEY, user_id UUID NOT NULL, le TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE OR REPLACE FUNCTION public.purger_donnees_utilisateur(p_user_id UUID) RETURNS VOID
LANGUAGE sql AS $$ DELETE FROM auth.users WHERE id = p_user_id $$;

-- Quatre comptes : un anonyme oublié, un anonyme oublié qui a un code valide, un anonyme
-- récent, un ancien anonyme converti (e-mail).
INSERT INTO auth.users (id, is_anonymous, email, created_at, last_sign_in_at) VALUES
  ('00000000-0000-0000-0000-000000005300', true, NULL, now() - interval '40 days', now() - interval '40 days'),
  ('00000000-0000-0000-0000-000000005301', true, NULL, now() - interval '40 days', now() - interval '35 days'),
  ('00000000-0000-0000-0000-000000005302', true, NULL, now() - interval '3 days', now() - interval '1 day'),
  ('00000000-0000-0000-0000-000000005303', true, 'converti@exemple.fr', now() - interval '60 days', now() - interval '50 days');
INSERT INTO public.codes_de_reprise (user_id, expire_le) VALUES
  ('00000000-0000-0000-0000-000000005301', now() + interval '5 days');

DO $$
DECLARE n INTEGER;
BEGIN
  n := public.purge_comptes_anonymes(30);
  IF n <> 1 THEN RAISE EXCEPTION 'un seul compte devait être purgé, % l''ont été', n; END IF;
  IF EXISTS (SELECT 1 FROM auth.users WHERE id = '00000000-0000-0000-0000-000000005300') THEN
    RAISE EXCEPTION 'l''anonyme oublié est toujours là';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = '00000000-0000-0000-0000-000000005301') THEN
    RAISE EXCEPTION 'un compte au code de reprise valide a été purgé';
  END IF;
END $$;

-- Le ménage : un code expiré part, un code valide reste ; les vieux essais et quotas partent.
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-0000000053b0');
INSERT INTO public.codes_de_reprise (user_id, expire_le) VALUES
  ('00000000-0000-0000-0000-0000000053b0', now() - interval '3 days');
INSERT INTO public.tentatives_de_reprise (user_id, le) VALUES
  ('00000000-0000-0000-0000-0000000053b0', now() - interval '2 days'),
  ('00000000-0000-0000-0000-0000000053b0', now());
INSERT INTO public.quotas_ia (user_id, jour, fonction, n) VALUES
  ('00000000-0000-0000-0000-0000000053b0', current_date - 40, 'scan_carte', 3),
  ('00000000-0000-0000-0000-0000000053b0', current_date, 'scan_carte', 1);
DO $$
DECLARE r JSONB := public.menage_quotidien();
BEGIN
  IF (r ->> 'codes')::int <> 1 OR (r ->> 'essais')::int <> 1 OR (r ->> 'quotas')::int <> 1 THEN
    RAISE EXCEPTION 'ménage inattendu : %', r;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.codes_de_reprise WHERE user_id = '00000000-0000-0000-0000-000000005301') THEN
    RAISE EXCEPTION 'le code valide a disparu';
  END IF;
END $$;

-- La croissance : chacun n'écrit que ses propres événements ; seul l'admin lit le compte.
INSERT INTO public.profiles (id, display_name, is_admin) VALUES ('00000000-0000-0000-0000-000000005302', NULL, false)
ON CONFLICT DO NOTHING;
DO $$
DECLARE refuse BOOLEAN := false;
BEGIN
  PERFORM public.essai_session('00000000-0000-0000-0000-000000005302', true);
  SET LOCAL ROLE authenticated;
  INSERT INTO public.evenements_croissance (type, table_code, plateforme) VALUES ('invite_web_arrivee', 'KYZ3YZ', 'web');
  INSERT INTO public.evenements_croissance (type, source, plateforme) VALUES ('clic_installer', 'page_invite', 'web');
  BEGIN
    INSERT INTO public.evenements_croissance (user_id, type, plateforme)
    VALUES ('00000000-0000-0000-0000-000000005301', 'premiere_ouverture', 'android');
  EXCEPTION WHEN insufficient_privilege THEN refuse := true;
  END;
  RESET ROLE;
  IF NOT refuse THEN RAISE EXCEPTION 'un événement a été écrit au nom d''un autre'; END IF;
END $$;
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-0000000053ad') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, display_name, is_admin) VALUES ('00000000-0000-0000-0000-0000000053ad', 'Admin', true)
ON CONFLICT (id) DO UPDATE SET is_admin = true;
INSERT INTO public.evenements_croissance (user_id, type, source, plateforme) VALUES
  (NULL, 'premiere_ouverture', NULL, 'android'), (NULL, 'premiere_ouverture', 'page_invite', 'android');
DO $$
DECLARE r JSONB;
BEGIN
  PERFORM public.essai_session('00000000-0000-0000-0000-0000000053ad');
  r := public.admin_croissance(30);
  IF (r -> 'par_type' ->> 'invite_web_arrivee')::int <> 1 OR (r -> 'par_type' ->> 'premiere_ouverture')::int <> 2 THEN
    RAISE EXCEPTION 'croissance inattendue : %', r;
  END IF;
  IF (r -> 'installations_par_source' ->> 'page_invite')::int <> 1 THEN
    RAISE EXCEPTION 'la source d''installation manque : %', r;
  END IF;
END $$;

\echo 'essais 053 : ok'
