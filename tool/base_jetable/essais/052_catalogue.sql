-- Essais de la migration 052 : qui modifie quel vin, ce que sert le catalogue, les quotas.
\set ON_ERROR_STOP on

-- Personnages : Alice possède une cave avec une bouteille ; Bruno est un autre compte ;
-- Camille est une session anonyme ; Admin est administrateur.
INSERT INTO auth.users (id, is_anonymous) VALUES
  ('00000000-0000-0000-0000-00000000a11c', false),
  ('00000000-0000-0000-0000-00000000b2b0', false),
  ('00000000-0000-0000-0000-00000000ca31', true),
  ('00000000-0000-0000-0000-0000000000ad', false)
ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, display_name, is_admin) VALUES
  ('00000000-0000-0000-0000-00000000a11c', 'Alice', false),
  ('00000000-0000-0000-0000-00000000b2b0', 'Bruno', false),
  ('00000000-0000-0000-0000-00000000ca31', NULL, false),
  ('00000000-0000-0000-0000-0000000000ad', 'Admin', true)
ON CONFLICT DO NOTHING;
INSERT INTO public.cellars (id, owner_id) VALUES ('c0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000a11c');
INSERT INTO public.cellar_members VALUES ('c0000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-00000000a11c', 'admin');

-- Des vins existants, créés avant la migration (created_by NULL) :
--   w1 : dans la cave d'Alice ; w2 : dans aucune cave, dégusté par Bruno ;
--   ws : fiche du serveur, que la bouteille d'Alice référencerait par erreur.
INSERT INTO public.wines (id, name, vintage, created_by, estimated_market_value, external_links) VALUES
  ('e0000000-0000-0000-0000-000000000001', 'Bandol Rouge', 2019, NULL, 45, '{}'),
  ('e0000000-0000-0000-0000-000000000002', 'Sancerre', 2022, NULL, 25, '{"user_overrides": ["estimated_market_value"]}'),
  ('e0000000-0000-0000-0000-000000000003', 'Chablis', 2021, NULL, 30, '{"valeur_source": "https://exemple.fr/chablis"}');
INSERT INTO public.wines (id, name, vintage, created_by, decrite_par_serveur, grapes, tasting_notes)
VALUES ('e0000000-0000-0000-0000-0000000000f5', 'Bandol Rouge', 2019, NULL, true,
        '[{"name": "Mourvèdre", "pct": 85}]', 'Cuir, garrigue, fruits noirs, tanins serrés et droits.');
INSERT INTO public.bottles (cellar_id, wine_id) VALUES
  ('c0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-000000000001'),
  ('c0000000-0000-0000-0000-000000000001', 'e0000000-0000-0000-0000-0000000000f5');
INSERT INTO public.tasting_log (user_id, wine_id) VALUES ('00000000-0000-0000-0000-00000000b2b0', 'e0000000-0000-0000-0000-000000000002');

-- Le nettoyage des valeurs a tourné avant ces insertions : on le rejoue ici, comme la migration.
UPDATE public.wines SET estimated_market_value = NULL, last_valuation_date = NULL
 WHERE estimated_market_value IS NOT NULL
   AND coalesce(external_links ->> 'valeur_source', '') = ''
   AND NOT (coalesce(external_links -> 'user_overrides', '[]'::jsonb) ? 'estimated_market_value');
DO $$
BEGIN
  IF (SELECT estimated_market_value FROM wines WHERE id = 'e0000000-0000-0000-0000-000000000001') IS NOT NULL THEN
    RAISE EXCEPTION 'la valeur inventée du Bandol devait disparaître';
  END IF;
  IF (SELECT estimated_market_value FROM wines WHERE id = 'e0000000-0000-0000-0000-000000000002') <> 25 THEN
    RAISE EXCEPTION 'la valeur saisie par Bruno devait rester';
  END IF;
  IF (SELECT estimated_market_value FROM wines WHERE id = 'e0000000-0000-0000-0000-000000000003') <> 30 THEN
    RAISE EXCEPTION 'la valeur sourcée devait rester';
  END IF;
END $$;

-- Une fonction d'essai : combien de lignes une modification touche-t-elle pour cette personne ?
CREATE OR REPLACE FUNCTION pg_temp.modifie(p_uid UUID, p_anonyme BOOLEAN, p_vin UUID) RETURNS INTEGER
LANGUAGE plpgsql AS $$
DECLARE n INTEGER;
BEGIN
  PERFORM public.essai_session(p_uid, p_anonyme);
  EXECUTE 'SET LOCAL ROLE authenticated';
  UPDATE public.wines SET tasting_notes = 'modifié' WHERE id = p_vin;
  GET DIAGNOSTICS n = ROW_COUNT;
  EXECUTE 'RESET ROLE';
  RETURN n;
END $$;

DO $$
BEGIN
  IF pg_temp.modifie('00000000-0000-0000-0000-00000000a11c', false, 'e0000000-0000-0000-0000-000000000001') <> 1 THEN
    RAISE EXCEPTION 'Alice doit pouvoir modifier le vin de sa cave';
  END IF;
  IF pg_temp.modifie('00000000-0000-0000-0000-00000000b2b0', false, 'e0000000-0000-0000-0000-000000000001') <> 0 THEN
    RAISE EXCEPTION 'Bruno a modifié le vin de la cave d''Alice';
  END IF;
  IF pg_temp.modifie('00000000-0000-0000-0000-00000000ca31', true, 'e0000000-0000-0000-0000-000000000001') <> 0 THEN
    RAISE EXCEPTION 'une session anonyme a modifié le catalogue';
  END IF;
  IF pg_temp.modifie('00000000-0000-0000-0000-00000000b2b0', false, 'e0000000-0000-0000-0000-000000000002') <> 1 THEN
    RAISE EXCEPTION 'Bruno doit pouvoir modifier le vin de sa dégustation';
  END IF;
  IF pg_temp.modifie('00000000-0000-0000-0000-00000000a11c', false, 'e0000000-0000-0000-0000-0000000000f5') <> 0 THEN
    RAISE EXCEPTION 'une fiche du serveur a été modifiée par un utilisateur';
  END IF;
END $$;

-- Un vin qu'on crée soi-même est modifiable par soi, et seulement par soi ; on ne peut ni
-- se faire passer pour le serveur, ni changer l'auteur.
DO $$
DECLARE refuse BOOLEAN := false;
BEGIN
  PERFORM public.essai_session('00000000-0000-0000-0000-00000000b2b0');
  SET LOCAL ROLE authenticated;
  INSERT INTO public.wines (id, name) VALUES ('e0000000-0000-0000-0000-0000000000b1', 'Vin de Bruno');
  UPDATE public.wines SET created_by = '00000000-0000-0000-0000-00000000a11c', name = 'Vin de Bruno bis'
   WHERE id = 'e0000000-0000-0000-0000-0000000000b1';
  BEGIN
    INSERT INTO public.wines (name, decrite_par_serveur) VALUES ('Faux serveur', true);
  EXCEPTION WHEN insufficient_privilege OR check_violation THEN refuse := true;
  END;
  RESET ROLE;
  IF NOT refuse THEN RAISE EXCEPTION 'un utilisateur a créé une fiche « serveur »'; END IF;
  IF (SELECT created_by FROM wines WHERE id = 'e0000000-0000-0000-0000-0000000000b1') <> '00000000-0000-0000-0000-00000000b2b0' THEN
    RAISE EXCEPTION 'l''auteur d''une fiche a changé';
  END IF;
  IF (SELECT name FROM wines WHERE id = 'e0000000-0000-0000-0000-0000000000b1') <> 'Vin de Bruno bis' THEN
    RAISE EXCEPTION 'Bruno n''a pas pu modifier son propre vin';
  END IF;
END $$;

-- Le catalogue sert la fiche du serveur avant celle d'Alice.
DO $$
BEGIN
  IF (SELECT id FROM public.find_cached_wine(NULL, 'bandol rouge', 2019)) <> 'e0000000-0000-0000-0000-0000000000f5' THEN
    RAISE EXCEPTION 'find_cached_wine doit servir la fiche du serveur en premier';
  END IF;
END $$;

-- Quotas : Camille (anonyme) a 3 scans de carte par jour ; Alice 15 ; l'admin est illimité ;
-- sans session, refus.
DO $$
DECLARE r JSONB; i INTEGER;
BEGIN
  PERFORM public.essai_session('00000000-0000-0000-0000-00000000ca31', true);
  FOR i IN 1..3 LOOP
    r := public.consommer_quota_ia('scan_carte');
    IF NOT (r ->> 'autorise')::boolean THEN RAISE EXCEPTION 'scan % refusé trop tôt : %', i, r; END IF;
  END LOOP;
  r := public.consommer_quota_ia('scan_carte');
  IF (r ->> 'autorise')::boolean OR r ->> 'raison' <> 'limite' THEN RAISE EXCEPTION 'le 4e scan anonyme devait être refusé : %', r; END IF;

  PERFORM public.essai_session('00000000-0000-0000-0000-00000000a11c');
  r := public.consommer_quota_ia('scan_carte');
  IF (r ->> 'restant')::int <> 14 THEN RAISE EXCEPTION 'Alice : restant attendu 14, obtenu %', r; END IF;
  r := public.consommer_quota_ia('fonction_inconnue');
  IF (r ->> 'limite')::int <> 30 THEN RAISE EXCEPTION 'limite par défaut attendue 30 : %', r; END IF;

  PERFORM public.essai_session('00000000-0000-0000-0000-0000000000ad');
  FOR i IN 1..40 LOOP r := public.consommer_quota_ia('scan_carte'); END LOOP;
  IF NOT (r ->> 'autorise')::boolean THEN RAISE EXCEPTION 'l''admin ne doit pas être limité'; END IF;

  PERFORM set_config('request.jwt.claims', '{}', false);
  r := public.consommer_quota_ia('scan_carte');
  IF r ->> 'raison' <> 'sans_session' THEN RAISE EXCEPTION 'sans session : %', r; END IF;
END $$;

\echo 'essais 052 : ok'
