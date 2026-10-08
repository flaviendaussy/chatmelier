-- Essais de la migration 068 : la voix des récits et les réglages de la console.
DO $$
DECLARE
  v_admin UUID := '00000000-0000-0000-0000-0000000000ad';
  v_json  JSONB;
BEGIN
  IF (SELECT valeur FROM public.app_config WHERE cle = 'voix_naturelle') <> 'false'::jsonb THEN
    RAISE EXCEPTION 'la voix naturelle doit être éteinte par défaut';
  END IF;
  IF public.reglage_invalide('voix_naturelle', 'true') IS NOT NULL
     OR public.reglage_invalide('voix_naturelle', '"oui"') IS NULL THEN
    RAISE EXCEPTION 'voix_naturelle : un booléen, rien d''autre';
  END IF;
  IF public.reglage_invalide('taux_de_change', '{"GBP": 1.17, "USD": 0.92}') IS NOT NULL
     OR public.reglage_invalide('taux_de_change', '{"gbp": 1.17}') IS NULL
     OR public.reglage_invalide('taux_de_change', '{"GBP": -1}') IS NULL THEN
    RAISE EXCEPTION 'taux_de_change : un taux positif par code de devise';
  END IF;
  -- Les réglages d'avant restent les mêmes.
  IF public.reglage_invalide('ecpm_eur_estime', '{"rewarded": 900}') IS NULL
     OR public.reglage_invalide('cle_inconnue', 'true') IS NULL THEN
    RAISE EXCEPTION 'les règles de la 060 doivent tenir';
  END IF;
  IF round(public.cout_ia_usd('gemini-2.5-flash-preview-tts', 100, 1000, now()), 5) <> 0.01005 THEN
    RAISE EXCEPTION 'la voix Flash : 0,50 $ en entrée et 10 $ en sortie par million : %',
      public.cout_ia_usd('gemini-2.5-flash-preview-tts', 100, 1000, now());
  END IF;
  IF round(public.cout_ia_usd('gemini-3.8-flash', 1000000, 0, DATE '2026-10-08'), 2) <> 0.75 THEN
    RAISE EXCEPTION 'un Flash texte ne doit pas être compté au tarif de la voix';
  END IF;
  INSERT INTO auth.users (id) VALUES (v_admin) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name, is_admin) VALUES (v_admin, 'Flavien', true)
  ON CONFLICT (id) DO UPDATE SET is_admin = true;
  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  v_json := public.admin_reglages();
  RESET ROLE;
  IF NOT (v_json -> 'reglages') ? 'voix_naturelle' THEN
    RAISE EXCEPTION 'la console doit voir voix_naturelle : %', v_json -> 'reglages';
  END IF;
  RAISE NOTICE '✓ 068 : la voix éteinte par défaut, son tarif, et deux réglages de plus dans la console';
END $$;
