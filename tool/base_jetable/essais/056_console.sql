-- Essais de la migration 056.
DO $$
BEGIN
  IF public.instant_du_journal('2026-09-30 20:00+00', '{"utc_offset_min": 120}') <> '2026-09-30 18:00+00'::timestamptz THEN
    RAISE EXCEPTION 'Paris (UTC+2) : 20 h murale doit donner 18 h UTC';
  END IF;
  IF public.instant_du_journal('2026-09-30 20:00+00', '{"utc_offset_min": 60}') <> '2026-09-30 19:00+00'::timestamptz THEN
    RAISE EXCEPTION 'Écosse (UTC+1)';
  END IF;
  IF public.instant_du_journal('2026-09-30 20:00+00', NULL) <> '2026-09-30 20:00+00'::timestamptz
     OR public.instant_du_journal('2026-09-30 20:00+00', '{"utc_offset_min": "x"}') <> '2026-09-30 20:00+00'::timestamptz THEN
    RAISE EXCEPTION 'sans décalage lisible, l''heure reste telle quelle';
  END IF;
  RAISE NOTICE '✓ l''instant réel d''un journal se retrouve par son décalage';
END $$;
