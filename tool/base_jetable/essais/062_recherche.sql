-- Essais de la migration 062 : chercher un membre.
DO $$
BEGIN
  INSERT INTO auth.users (id) VALUES
    ('62000000-0000-0000-0000-000000000001'), ('62000000-0000-0000-0000-000000000002'),
    ('62000000-0000-0000-0000-000000000003'), ('62000000-0000-0000-0000-000000000004')
    ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name, avatar_url) VALUES
    ('62000000-0000-0000-0000-000000000001', 'Flavien', 'meta://?u=flavien'),
    ('62000000-0000-0000-0000-000000000002', 'Caroline', 'meta://?u=caro'),
    ('62000000-0000-0000-0000-000000000003', 'Dimitri', 'meta://?u=bandolero_dl'),
    ('62000000-0000-0000-0000-000000000004', '100% Camille', NULL)
    ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name, avatar_url = EXCLUDED.avatar_url;
END $$;

SET ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"62000000-0000-0000-0000-000000000001","role":"authenticated"}', false);
DO $$
DECLARE
  n INTEGER;
  premier TEXT;
BEGIN
  IF public.pseudo_du_profil('meta://?u=flavien') <> 'flavien' OR public.pseudo_du_profil('https://x/a.png') IS NOT NULL THEN
    RAISE EXCEPTION 'lecture du pseudo inattendue';
  END IF;
  -- Par le pseudo, par le prénom, jamais soi-même.
  SELECT count(*) INTO n FROM public.chercher_des_membres('@caro');
  IF n <> 1 THEN RAISE EXCEPTION 'caro : % résultats', n; END IF;
  SELECT count(*) INTO n FROM public.chercher_des_membres('dimi');
  IF n <> 1 THEN RAISE EXCEPTION 'dimi : % résultats', n; END IF;
  SELECT count(*) INTO n FROM public.chercher_des_membres('flavien');
  IF n <> 0 THEN RAISE EXCEPTION 'on ne se trouve pas soi-même'; END IF;
  -- Une lettre ne suffit pas ; un joker tapé n'en est pas un.
  SELECT count(*) INTO n FROM public.chercher_des_membres('a');
  IF n <> 0 THEN RAISE EXCEPTION 'une lettre ne doit rien rendre'; END IF;
  -- Sans échappement, « %% » trouverait tout le monde ; échappé, personne n'a « %% » dans son nom.
  SELECT count(*) INTO n FROM public.chercher_des_membres('%%');
  IF n <> 0 THEN RAISE EXCEPTION '« %%%% » ne doit trouver personne : %', n; END IF;
  SELECT count(*) INTO n FROM public.chercher_des_membres('0%');
  IF n <> 1 THEN RAISE EXCEPTION '« 0%% » ne doit trouver que « 100%% Camille » : %', n; END IF;
  SELECT display_name INTO premier FROM public.chercher_des_membres('ro') LIMIT 1;
  IF premier IS NULL THEN RAISE EXCEPTION 'ro devait trouver Caroline ou bandolero'; END IF;
END $$;

-- Un compte anonyme ne cherche pas.
SELECT set_config('request.jwt.claims', '{"sub":"62000000-0000-0000-0000-000000000002","role":"authenticated","is_anonymous":true}', false);
DO $$
BEGIN
  BEGIN
    PERFORM * FROM public.chercher_des_membres('flavien');
    RAISE EXCEPTION 'un anonyme ne devait pas chercher';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'compte_requis' THEN RAISE; END IF;
  END;
END $$;
RESET ROLE;
DO $$ BEGIN RAISE NOTICE '✓ 062 : recherche des membres'; END $$;
