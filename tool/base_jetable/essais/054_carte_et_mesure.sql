-- Essais de la migration 054.
DO $$
DECLARE
  v_n INTEGER;
  v_menu JSONB;
BEGIN
  INSERT INTO auth.users (id) VALUES ('54000000-0000-0000-0000-000000000001') ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id) VALUES ('54000000-0000-0000-0000-000000000001') ON CONFLICT DO NOTHING;
  INSERT INTO public.table_sessions (code, restaurant_name, menu)
    VALUES ('KYZ3YZ', 'Chez Paul', '{"restaurant_name":"Chez Paul","wines":[{"name":"Bandol"}]}');
  INSERT INTO public.table_sessions (code, restaurant_name, menu, expires_at)
    VALUES ('ABC234', 'Fermé', '{"wines":[{"name":"X"}]}', now() - interval '1 minute');
END $$;

-- 1. Un invité anonyme lit la carte par le code, en minuscules et avec des espaces.
SET ROLE anon;
DO $$
DECLARE v_menu JSONB; v_n INTEGER;
BEGIN
  SELECT menu INTO v_menu FROM public.lire_carte_de_table('  kyz3yz ');
  IF v_menu IS NULL OR v_menu->'wines'->0->>'name' <> 'Bandol' THEN
    RAISE EXCEPTION 'la carte de KYZ3YZ devait se lire par son code';
  END IF;
  SELECT count(*) INTO v_n FROM public.lire_carte_de_table('ABC234');
  IF v_n <> 0 THEN RAISE EXCEPTION 'une table expirée ne doit rien rendre'; END IF;
  SELECT count(*) INTO v_n FROM public.lire_carte_de_table('ZZZZZZ');
  IF v_n <> 0 THEN RAISE EXCEPTION 'un code inconnu ne doit rien rendre'; END IF;
  RAISE NOTICE '✓ la carte se lit par le code, jamais une table expirée ou inconnue';
END $$;
RESET ROLE;

-- 2. La mesure : l'upsert des téléphones passe, et chacun ne voit que ses lignes.
INSERT INTO auth.users (id) VALUES ('54000000-0000-0000-0000-000000000002') ON CONFLICT DO NOTHING;
GRANT INSERT ON public.ai_cost_events, public.ad_impressions TO authenticated;
SET ROLE authenticated;
SELECT set_config('request.jwt.claims', '{"sub":"54000000-0000-0000-0000-000000000001","role":"authenticated"}', false);
INSERT INTO public.ai_cost_events (event_id, occurred_at, platform, build_mode, feature, model, prompt_tokens, output_tokens, grounded, cost_usd, cost_eur)
  VALUES ('e0000000-0000-0000-0000-000000000001', now(), 'android', 'release', 'scan', 'gemini-3.8-flash', 10, 20, false, 0.001, 0.001)
  ON CONFLICT (event_id) DO NOTHING;
INSERT INTO public.ai_cost_events (event_id, occurred_at, platform, build_mode, feature, model, prompt_tokens, output_tokens, grounded, cost_usd, cost_eur)
  VALUES ('e0000000-0000-0000-0000-000000000001', now(), 'android', 'release', 'scan', 'gemini-3.8-flash', 10, 20, false, 0.001, 0.001)
  ON CONFLICT (event_id) DO NOTHING;
INSERT INTO public.ad_impressions (event_id, occurred_at, platform, build_mode, ad_format, placement)
  VALUES ('e0000000-0000-0000-0000-000000000002', now(), 'android', 'release', 'rewarded', 'scan_carte')
  ON CONFLICT (event_id) DO NOTHING;
SELECT set_config('request.jwt.claims', '{"sub":"54000000-0000-0000-0000-000000000002","role":"authenticated"}', false);
DO $$
DECLARE v_n INTEGER;
BEGIN
  SELECT count(*) INTO v_n FROM public.ai_cost_events;
  IF v_n <> 0 THEN RAISE EXCEPTION 'un autre compte ne doit pas voir ces coûts (%)', v_n; END IF;
END $$;
SELECT set_config('request.jwt.claims', '{"sub":"54000000-0000-0000-0000-000000000001","role":"authenticated"}', false);
DO $$
DECLARE v_n INTEGER;
BEGIN
  SELECT count(*) INTO v_n FROM public.ai_cost_events;
  IF v_n <> 1 THEN RAISE EXCEPTION 'le doublon devait être ignoré et la ligne relue (%)', v_n; END IF;
  SELECT count(*) INTO v_n FROM public.ad_impressions;
  IF v_n <> 1 THEN RAISE EXCEPTION 'l''impression devait arriver (%)', v_n; END IF;
  RAISE NOTICE '✓ l''upsert des téléphones passe, sans doublon, et chacun ne relit que ses lignes';
END $$;
RESET ROLE;
