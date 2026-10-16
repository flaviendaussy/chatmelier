-- Essais de la migration 070 : le contexte d'un retour dans la console.
DO $$
DECLARE
  v_admin UUID := '00000000-0000-0000-0000-0000000000ad';
  v_caro  UUID := '00000000-0000-0000-0000-0000000c0070';
  v_marc  UUID := '00000000-0000-0000-0000-0000000a0070';
  v_retour UUID;
  v_json  JSONB;
BEGIN
  INSERT INTO auth.users (id) VALUES (v_admin), (v_caro), (v_marc) ON CONFLICT DO NOTHING;
  INSERT INTO public.profiles (id, display_name, is_admin) VALUES (v_admin, 'Flavien', true), (v_caro, 'Caro', false), (v_marc, 'Marc', false)
  ON CONFLICT (id) DO UPDATE SET is_admin = EXCLUDED.is_admin, display_name = EXCLUDED.display_name;

  -- Caro, hors ligne, puis un retour envoyé plus tard avec son contexte.
  INSERT INTO public.app_diagnostic_logs (user_id, tag, level, message, created_at, metadata) VALUES
    (v_caro, 'FRIENDS', 'warning', 'Could not fetch notifications: Failed host lookup', '2026-10-16 18:11:03', '{"utc_offset_min": 60}'),
    (v_caro, 'CHAT_AI', 'info', 'Question au sommelier (9 caractères)', '2026-10-16 18:05:00', '{"utc_offset_min": 60}'),
    (v_marc, 'FRIENDS', 'warning', 'journal de Marc, au même instant', '2026-10-16 18:11:00', '{"utc_offset_min": 60}');
  INSERT INTO public.app_diagnostic_logs (user_id, tag, level, message, created_at, metadata) VALUES
    (v_caro, 'USER_FEEDBACK', 'info', 'Commentaire: ceci devrait être la belle animation | Capture: aucune | Annotations: oui',
     '2026-10-16 18:11:33',
     '{"utc_offset_min": 60, "envoye_le": "2026-10-16T18:20:00", "capture": "capture introuvable sur le téléphone",
       "contexte": {"ecran": "/chat", "reseau": "serveur injoignable : Failed host lookup", "fil": ["18:10:58 écran /chat"]}}')
  RETURNING id INTO v_retour;

  -- Pas pour Caro.
  PERFORM public.essai_session(v_caro);
  SET LOCAL ROLE authenticated;
  BEGIN
    PERFORM public.admin_contexte_du_retour(v_retour);
    RAISE EXCEPTION 'la console est réservée à l''administrateur';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'reserve_admin' THEN RAISE; END IF;
  END;
  RESET ROLE;

  PERFORM public.essai_session(v_admin);
  SET LOCAL ROLE authenticated;
  v_json := public.admin_contexte_du_retour(v_retour);
  RESET ROLE;
  IF v_json -> 'contexte' ->> 'ecran' <> '/chat' OR v_json ->> 'capture' <> 'capture introuvable sur le téléphone'
     OR v_json ->> 'envoye_le' IS NULL THEN
    RAISE EXCEPTION 'le contexte du retour devait revenir entier : %', v_json;
  END IF;
  IF jsonb_array_length(v_json -> 'journaux') <> 1
     OR v_json -> 'journaux' -> 0 ->> 'message' NOT LIKE 'Could not fetch notifications%' THEN
    RAISE EXCEPTION 'seul le journal de Caro dans les trois minutes devait revenir (pas celui de 18h05, ni celui de Marc) : %',
      v_json -> 'journaux';
  END IF;
  RAISE NOTICE '✓ 070 : le contexte d''un retour et les journaux de la même personne, pour l''administrateur seul';

  DELETE FROM public.app_diagnostic_logs WHERE user_id IN (v_caro, v_marc);
END $$;
