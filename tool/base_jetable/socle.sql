-- Socle d'une base jetable qui imite ce dont nos migrations dépendent chez Supabase.
--
-- Ce n'est PAS le schéma de production : seulement les rôles, le schéma `auth`, et les
-- tables et fonctions que les migrations récentes lisent ou modifient. Les définitions des
-- fonctions `find_cached_wine`, `is_cellar_editor_or_admin`, `est_admin`, `est_anonyme` et
-- `admin_nom` sont celles lues en production le 30/09 (pg_get_functiondef, rôle en lecture
-- seule). Les colonnes de `wines` sont celles que renvoie l'API publique.

-- Rôles de Supabase ------------------------------------------------------------
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN CREATE ROLE service_role NOLOGIN BYPASSRLS; END IF;
END $$;
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

CREATE SCHEMA IF NOT EXISTS extensions;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;
GRANT USAGE ON SCHEMA extensions TO anon, authenticated, service_role;

-- Le schéma auth, réduit à ce que lisent nos fonctions ---------------------------
CREATE SCHEMA IF NOT EXISTS auth;
GRANT USAGE ON SCHEMA auth TO anon, authenticated, service_role;
CREATE TABLE IF NOT EXISTS auth.users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           TEXT,
  is_anonymous    BOOLEAN NOT NULL DEFAULT false,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  last_sign_in_at TIMESTAMPTZ
);
-- Les claims du jeton, comme PostgREST les pose : SELECT set_config('request.jwt.claims', …).
CREATE OR REPLACE FUNCTION auth.jwt() RETURNS JSONB LANGUAGE sql STABLE AS $$
  SELECT coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb;
$$;
CREATE OR REPLACE FUNCTION auth.uid() RETURNS UUID LANGUAGE sql STABLE AS $$
  SELECT nullif(auth.jwt() ->> 'sub', '')::uuid;
$$;
CREATE OR REPLACE FUNCTION auth.role() RETURNS TEXT LANGUAGE sql STABLE AS $$
  SELECT coalesce(auth.jwt() ->> 'role', 'anon');
$$;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA auth TO anon, authenticated, service_role;

-- Tables publiques utiles ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
  id           UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  username     TEXT,
  avatar_url   TEXT,
  is_admin     BOOLEAN NOT NULL DEFAULT false
);

-- Le journal de l'app (011), réduit aux colonnes que lisent les fonctions de la console.
CREATE TABLE IF NOT EXISTS public.app_diagnostic_logs (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  device_id     TEXT,
  platform      TEXT,
  app_version   TEXT,
  tag           TEXT NOT NULL,
  level         TEXT NOT NULL,
  message       TEXT NOT NULL,
  error_details TEXT,
  metadata      JSONB,
  created_at    TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.cellars (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID REFERENCES public.profiles(id),
  name     TEXT NOT NULL DEFAULT 'Ma cave'
);
CREATE TABLE IF NOT EXISTS public.cellar_members (
  cellar_id UUID REFERENCES public.cellars(id) ON DELETE CASCADE,
  user_id   UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  role      TEXT NOT NULL DEFAULT 'viewer',
  PRIMARY KEY (cellar_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.wines (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name                   TEXT NOT NULL,
  producer               TEXT,
  cuvee_parcel           TEXT,
  vintage                INTEGER,
  wine_type              TEXT,
  country                TEXT,
  region                 TEXT,
  sub_region             TEXT,
  appellation            TEXT,
  classification         TEXT,
  alcohol_pct            NUMERIC,
  grapes                 JSONB NOT NULL DEFAULT '[]'::jsonb,
  tasting_notes          TEXT,
  ideal_drinking_start   INTEGER,
  ideal_drinking_end     INTEGER,
  peak_drinking_start    INTEGER,
  peak_drinking_end      INTEGER,
  ai_summary             TEXT,
  ai_food_pairings       JSONB NOT NULL DEFAULT '[]'::jsonb,
  external_links         JSONB NOT NULL DEFAULT '{}'::jsonb,
  critic_scores          JSONB NOT NULL DEFAULT '[]'::jsonb,
  estimated_market_value NUMERIC,
  estimated_value_currency TEXT DEFAULT 'EUR',
  last_valuation_date    TIMESTAMPTZ,
  valuation_history      JSONB NOT NULL DEFAULT '[]'::jsonb,
  sources_verified       JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_verified_online     BOOLEAN NOT NULL DEFAULT false,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
  image_url              TEXT,
  label_image_url        TEXT,
  barrel_aging           TEXT,
  elevage_type           TEXT,
  elevage_months         INTEGER
);
ALTER TABLE public.wines ENABLE ROW LEVEL SECURITY;
-- Les politiques de production (lues dans pg_policies le 30/09).
DROP POLICY IF EXISTS "Wines are viewable by everyone." ON public.wines;
CREATE POLICY "Wines are viewable by everyone." ON public.wines FOR SELECT USING (true);
DROP POLICY IF EXISTS "Authenticated users can create wines." ON public.wines;
CREATE POLICY "Authenticated users can create wines." ON public.wines FOR INSERT WITH CHECK (auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Authenticated users can update wines." ON public.wines;
CREATE POLICY "Authenticated users can update wines." ON public.wines FOR UPDATE USING (auth.role() = 'authenticated');

CREATE TABLE IF NOT EXISTS public.bottles (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  cellar_id UUID REFERENCES public.cellars(id) ON DELETE CASCADE,
  wine_id   UUID REFERENCES public.wines(id),
  quantity  INTEGER NOT NULL DEFAULT 1,
  status    TEXT NOT NULL DEFAULT 'in_cellar'
);
CREATE TABLE IF NOT EXISTS public.tasting_log (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id   UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  wine_id   UUID REFERENCES public.wines(id),
  rating    NUMERIC,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- Les colonnes de production (pg_attribute, 08/10), pour les fonctions qui écrivent au journal.
ALTER TABLE public.tasting_log
  ADD COLUMN IF NOT EXISTS bottle_id         UUID,
  ADD COLUMN IF NOT EXISTS cellar_id         UUID,
  ADD COLUMN IF NOT EXISTS occasion          TEXT,
  ADD COLUMN IF NOT EXISTS food_paired       TEXT,
  ADD COLUMN IF NOT EXISTS tasting_notes     TEXT,
  ADD COLUMN IF NOT EXISTS photo_url         TEXT,
  ADD COLUMN IF NOT EXISTS consumed_at       TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS co_tasters        JSONB,
  ADD COLUMN IF NOT EXISTS bottle_owner_id   UUID,
  ADD COLUMN IF NOT EXISTS bottle_owner_name TEXT,
  ADD COLUMN IF NOT EXISTS location_name     TEXT,
  ADD COLUMN IF NOT EXISTS is_external       BOOLEAN,
  ADD COLUMN IF NOT EXISTS rating_scale      SMALLINT NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS is_favorite       BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_blind          BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS fault             TEXT;

-- Amitiés et notifications (018).
CREATE TABLE IF NOT EXISTS public.friendships (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  friend_id  UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  status     TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS public.user_notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  actor_id   UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  type       TEXT NOT NULL,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  data       JSONB DEFAULT '{}'::jsonb,
  is_read    BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated, service_role;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;

-- app_config (044) ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.app_config (
  cle    TEXT PRIMARY KEY,
  valeur JSONB NOT NULL,
  maj_le TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS app_config_lecture ON public.app_config;
CREATE POLICY app_config_lecture ON public.app_config FOR SELECT USING (true);

-- Fonctions de production ------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_nominatif() RETURNS BOOLEAN LANGUAGE sql STABLE AS $$ SELECT true $$;

CREATE OR REPLACE FUNCTION public.admin_nom(p_id uuid, p_prenom text)
 RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
  SELECT CASE
    WHEN public.admin_nominatif()
      THEN coalesce(nullif(trim(p_prenom), ''), 'Anonyme ' || left(p_id::text, 4))
    ELSE 'Personne ' || left(md5(p_id::text), 6)
  END;
$function$;

CREATE OR REPLACE FUNCTION public.est_admin()
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO 'public'
AS $function$
  SELECT coalesce((SELECT p.is_admin FROM public.profiles p WHERE p.id = auth.uid()), false);
$function$;

CREATE OR REPLACE FUNCTION public.est_anonyme()
 RETURNS boolean LANGUAGE sql STABLE
AS $function$
  SELECT coalesce((auth.jwt() ->> 'is_anonymous')::boolean, false);
$function$;

CREATE OR REPLACE FUNCTION public.find_cached_wine(p_producer text, p_name text, p_vintage integer, p_cuvee text DEFAULT NULL::text)
 RETURNS SETOF wines LANGUAGE plpgsql SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT *
  FROM wines w
  WHERE lower(trim(w.name)) = lower(trim(p_name))
    AND ((w.vintage IS NULL AND p_vintage IS NULL) OR (w.vintage = p_vintage))
    AND (p_producer IS NULL OR lower(trim(coalesce(w.producer, ''))) = lower(trim(p_producer)))
    AND (p_cuvee IS NULL OR lower(trim(coalesce(w.cuvee_parcel, ''))) = lower(trim(p_cuvee)))
  LIMIT 1;
END;
$function$;

CREATE OR REPLACE FUNCTION public.is_cellar_editor_or_admin(p_cellar_id uuid, p_user_id uuid DEFAULT auth.uid())
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = p_user_id AND role IN ('editor', 'admin')
  );
$function$;

-- Outils des essais -------------------------------------------------------------------
-- Se mettre dans la peau de quelqu'un : SELECT essai_session('<uuid>'); SET ROLE authenticated;
CREATE OR REPLACE FUNCTION public.essai_session(p_uid UUID, p_anonyme BOOLEAN DEFAULT false)
RETURNS VOID LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claims',
    jsonb_build_object('sub', p_uid, 'role', 'authenticated', 'is_anonymous', p_anonyme)::text, false);
$$;
GRANT EXECUTE ON FUNCTION public.essai_session(UUID, BOOLEAN) TO authenticated, anon;

-- Les tables de restaurant (038), réduites à ce que les essais utilisent.
CREATE TABLE IF NOT EXISTS public.table_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code            TEXT NOT NULL UNIQUE,
  host_user_id    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  restaurant_name TEXT NOT NULL DEFAULT 'Restaurant',
  menu            JSONB NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT now() + interval '4 hours'
);
ALTER TABLE public.table_sessions ENABLE ROW LEVEL SECURITY;

-- Le stockage de Supabase, réduit à ce que lisent les règles (064) : `storage.objects`
-- et `storage.foldername`, tels que Supabase les définit.
CREATE SCHEMA IF NOT EXISTS storage;
CREATE TABLE IF NOT EXISTS storage.objects (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  bucket_id TEXT NOT NULL,
  name      TEXT NOT NULL,
  owner     UUID DEFAULT auth.uid()
);
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
CREATE OR REPLACE FUNCTION storage.foldername(name TEXT) RETURNS TEXT[] LANGUAGE plpgsql IMMUTABLE AS $$
DECLARE _parts TEXT[];
BEGIN
  SELECT string_to_array(name, '/') INTO _parts;
  RETURN _parts[1:array_length(_parts, 1) - 1];
END $$;
GRANT USAGE ON SCHEMA storage TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON storage.objects TO anon, authenticated;
GRANT EXECUTE ON FUNCTION storage.foldername(TEXT) TO anon, authenticated;
-- Les règles trouvées en production le 08/10 (lecture du catalogue), que 064 remplace.
DROP POLICY IF EXISTS "Public Access Labels" ON storage.objects;
CREATE POLICY "Public Access Labels" ON storage.objects USING (bucket_id = 'labels') WITH CHECK (bucket_id = 'labels');
DROP POLICY IF EXISTS "Authenticated Delete Labels" ON storage.objects;
CREATE POLICY "Authenticated Delete Labels" ON storage.objects FOR DELETE USING (bucket_id = 'labels' AND auth.role() = 'authenticated');
DROP POLICY IF EXISTS "Anyone can read labels" ON storage.objects;
CREATE POLICY "Anyone can read labels" ON storage.objects FOR SELECT USING (bucket_id = 'labels');
