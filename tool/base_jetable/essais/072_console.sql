-- Essais de la migration 072 : le fil complet d'une personne, et la version proposée.
DO $$
DECLARE
  v_admin UUID := '00000000-0000-0000-0000-0000000000ad';
  v_caro  UUID := '00000000-0000-0000-0000-0000000c0072';
  v_fil   TEXT[];
  v_n     INT;
  v_p     RECORD;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_admin), (v_caro) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name, is_admin) VALUES (v_admin, 'Flavien', true), (v_caro, 'Caro', false)
  ON CONFLICT (id) DO UPDATE SET is_admin = EXCLUDED.is_admin, display_name = EXCLUDED.display_name;

  -- Le 17/10 de Caro : l'app ouverte, une alerte, deux vins cherchés par leur nom, et le bruit.
  INSERT INTO public.app_diagnostic_logs (user_id, tag, level, message, created_at, metadata, platform, app_version) VALUES
    (v_caro, 'SYSTEM', 'info', 'Chatmelier app launched and centralized logging initialized', now() - interval '60 seconds', '{}', 'iOS', '1.9.1+82'),
    (v_caro, 'NOTIF', 'info', 'Notification 424242 scheduled in 1782 minutes', now() - interval '59 seconds', '{}', 'iOS', '1.9.1+82'),
    (v_caro, 'ADMOB', 'info', 'RewardedAd failed to load', now() - interval '59 seconds', '{}', 'iOS', '1.9.1+82'),
    (v_caro, 'NEARBY_PLACES', 'warning', 'Overpass fetch error, trying Nominatim fallback', now() - interval '40 seconds', '{}', 'iOS', '1.9.1+82'),
    (v_caro, 'SCAN_AI', 'info', 'Analyzing wine from text: "domaine Mucyn"', now() - interval '20 seconds', '{}', 'iOS', '1.9.1+82'),
    (v_caro, 'AI_COST', 'info', 'Logged AI usage: gemini-3.8-flash (vin_depuis_texte)', now() - interval '19 seconds', '{}', 'iOS', '1.9.1+82'),
    (v_caro, 'SCAN_AI', 'info', 'Vin non reconnu depuis le texte : rien n''est inventé', now() - interval '18 seconds', '{}', 'iOS', '1.9.1+82');

  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  SELECT array_agg(genre || ' : ' || titre ORDER BY quand) INTO v_fil FROM public.admin_fil_personne(v_caro, 1);
  SELECT * INTO v_p FROM public.admin_personnes(30) WHERE user_id = v_caro;
  RESET ROLE;

  IF v_fil <> ARRAY[
      'ouverture : Ouvre l''app',
      'alerte : Overpass fetch error, trying Nominatim fallback',
      'recherche : Analyzing wine from text: "domaine Mucyn"',
      'recherche : Vin non reconnu depuis le texte : rien n''est inventé'] THEN
    RAISE EXCEPTION 'le fil de Caro devait montrer l''ouverture, l''alerte et les deux recherches, sans le bruit : %', v_fil;
  END IF;
  IF v_p.ouvertures <> 1 OR v_p.recherches <> 1 THEN
    RAISE EXCEPTION 'Caro : 1 ouverture et 1 vin cherché attendus, % et %', v_p.ouvertures, v_p.recherches;
  END IF;

  -- La version proposée se règle comme la version exigée.
  IF public.reglage_invalide('version_disponible',
       '{"build": 84, "lien": "https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier", "build_ios": 84, "lien_ios": "itms-beta://"}') IS NOT NULL THEN
    RAISE EXCEPTION 'une version disponible bien formée devait passer';
  END IF;
  IF public.reglage_invalide('version_disponible', '{"build": "84"}') IS NULL THEN
    RAISE EXCEPTION 'une version disponible mal formée devait être refusée';
  END IF;
  RAISE NOTICE '✓ 072 : le fil complet (ouverture, recherches, alertes, sans le bruit), les compteurs, la version proposée';
END $$;
