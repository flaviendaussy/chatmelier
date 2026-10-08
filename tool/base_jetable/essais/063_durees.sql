-- Essais de la migration 063 : les durées de conservation.
DO $$
DECLARE
  r JSONB;
  n INTEGER;
BEGIN
  INSERT INTO public.app_diagnostic_logs (tag, level, message, created_at) VALUES
    ('MENU_SCAN', 'error', 'vieux', now() - INTERVAL '181 days'),
    ('MENU_SCAN', 'error', 'récent', now() - INTERVAL '10 days'),
    ('USER_FEEDBACK', 'info', 'Commentaire: vieux retour', now() - INTERVAL '200 days'),
    ('USER_FEEDBACK', 'info', 'Commentaire: très vieux retour', now() - INTERVAL '366 days');
  r := public.purger_selon_les_durees();
  IF (r ->> 'journaux')::int < 1 OR (r ->> 'retours')::int < 1 THEN
    RAISE EXCEPTION 'purge inattendue : %', r;
  END IF;
  SELECT count(*) INTO n FROM public.app_diagnostic_logs WHERE message IN ('récent', 'Commentaire: vieux retour');
  IF n <> 2 THEN RAISE EXCEPTION 'un journal récent ou un retour de moins d''un an a disparu'; END IF;
  SELECT count(*) INTO n FROM public.app_diagnostic_logs WHERE message IN ('vieux', 'Commentaire: très vieux retour');
  IF n <> 0 THEN RAISE EXCEPTION 'les vieilles lignes devaient partir'; END IF;
  RAISE NOTICE '✓ 063 : durées de conservation';
END $$;
