-- Essais de la migration 051 : le coût recalculé depuis les jetons.
\set ON_ERROR_STOP on

INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-0000000000a1') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, display_name, is_admin)
VALUES ('00000000-0000-0000-0000-0000000000a1', 'Admin', true) ON CONFLICT DO NOTHING;

-- Le scan d'étiquette relevé le 29/09 : lecture puis description, sans recherche. L'app avait
-- envoyé ses coûts à l'ancien tarif (0,10 $ / 0,40 $).
INSERT INTO public.ai_cost_events
  (event_id, user_id, occurred_at, platform, build_mode, feature, model, prompt_tokens, output_tokens, grounded, cost_usd, cost_eur)
VALUES
  (gen_random_uuid(), '00000000-0000-0000-0000-0000000000a1', now() - interval '1 day', 'android', 'release',
   'scan_vision', 'gemini-3.8-flash', 1284, 663, false, 0.000394, 0.000362),
  (gen_random_uuid(), '00000000-0000-0000-0000-0000000000a1', now() - interval '1 day', 'android', 'release',
   'scan_enrichment', 'gemini-3.8-flash', 222, 1117, false, 0.000469, 0.000431);

DO $$
DECLARE
  r JSONB;
  attendu NUMERIC := (public.cout_ia_usd('gemini-3.8-flash', 1284, 663, now())
                    + public.cout_ia_usd('gemini-3.8-flash', 222, 1117, now())) * 0.92;
BEGIN
  PERFORM public.essai_session('00000000-0000-0000-0000-0000000000a1');
  r := public.admin_economie(30, true);
  IF abs((r ->> 'cout_ia_eur')::numeric - attendu) > 0.000001 THEN
    RAISE EXCEPTION 'coût recalculé % ≠ attendu %', r ->> 'cout_ia_eur', attendu;
  END IF;
  IF (r ->> 'cout_ia_eur')::numeric < 8 * (r ->> 'cout_ia_eur_app')::numeric THEN
    RAISE EXCEPTION 'le recalcul devrait être ~9 fois l''estimation de l''app : % contre %',
      r ->> 'cout_ia_eur', r ->> 'cout_ia_eur_app';
  END IF;
  RAISE NOTICE 'scan du 29/09 : % € recalculés, % € selon l''app', round((r ->> 'cout_ia_eur')::numeric, 5),
    round((r ->> 'cout_ia_eur_app')::numeric, 5);
END $$;

-- Tarifs datés et familles.
DO $$
BEGIN
  IF public.cout_ia_usd('gemini-3.8-flash', 1000000, 0, TIMESTAMPTZ '2026-12-31 12:00Z') <> 0.75 THEN RAISE EXCEPTION 'Flash 2026'; END IF;
  IF public.cout_ia_usd('gemini-3.8-flash', 1000000, 0, TIMESTAMPTZ '2027-01-02 12:00Z') <> 1.50 THEN RAISE EXCEPTION 'Flash 2027'; END IF;
  IF public.cout_ia_usd('gemini-3.5-flash', 0, 1000000, now()) <> 9.00 THEN RAISE EXCEPTION '3.5-flash'; END IF;
  IF public.cout_ia_usd('gemini-3.1-flash-lite', 1000000, 1000000, now()) <> 1.75 THEN RAISE EXCEPTION '3.1-lite'; END IF;
  IF public.cout_ia_usd('gemini-flash-lite-latest', 1000000, 0, now()) <> 0.30 THEN RAISE EXCEPTION 'alias lite'; END IF;
  IF public.cout_ia_usd('gemini-flash-latest', 1000000, 0, TIMESTAMPTZ '2026-10-01 12:00Z') <> 0.75 THEN RAISE EXCEPTION 'alias flash'; END IF;
  IF public.cout_ia_usd('modele-inconnu', 1000000, 0, now()) <> 0.75 THEN RAISE EXCEPTION 'inconnu'; END IF;
END $$;

-- La franchise de recherche : avec une franchise de 1, le premier appel groundé du mois est
-- offert, le second paie 0,014 $.
UPDATE public.app_config SET valeur = '{"prix_usd": 0.014, "franchise_mensuelle": 1, "usd_eur": 1}'::jsonb
 WHERE cle = 'recherche_ia';
DELETE FROM public.ai_cost_events;
INSERT INTO public.ai_cost_events
  (event_id, user_id, occurred_at, platform, build_mode, feature, model, prompt_tokens, output_tokens, grounded, cost_usd, cost_eur)
VALUES
  (gen_random_uuid(), '00000000-0000-0000-0000-0000000000a1', date_trunc('month', now()) + interval '1 hour', 'android', 'release',
   'scan_enrichment', 'gemini-3.8-flash', 0, 0, true, 0.035, 0.032),
  (gen_random_uuid(), '00000000-0000-0000-0000-0000000000a1', date_trunc('month', now()) + interval '2 hours', 'android', 'release',
   'scan_enrichment', 'gemini-3.8-flash', 0, 0, true, 0.035, 0.032);
DO $$
DECLARE r JSONB;
BEGIN
  PERFORM public.essai_session('00000000-0000-0000-0000-0000000000a1');
  r := public.admin_economie(40, true);
  IF (r ->> 'cout_ia_eur')::numeric <> 0.014 THEN
    RAISE EXCEPTION 'franchise : attendu 0,014 (un seul appel au-delà), obtenu %', r ->> 'cout_ia_eur';
  END IF;
END $$;

-- Un non-administrateur est refusé.
INSERT INTO auth.users (id) VALUES ('00000000-0000-0000-0000-0000000000b2') ON CONFLICT DO NOTHING;
INSERT INTO public.profiles (id, display_name) VALUES ('00000000-0000-0000-0000-0000000000b2', 'Caro') ON CONFLICT DO NOTHING;
DO $$
BEGIN
  PERFORM public.essai_session('00000000-0000-0000-0000-0000000000b2');
  BEGIN
    PERFORM public.admin_economie(30, true);
    RAISE EXCEPTION 'un non-administrateur a lu l''économie';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'reserve_admin' THEN RAISE; END IF;
  END;
END $$;

\echo 'essais 051 : ok'
