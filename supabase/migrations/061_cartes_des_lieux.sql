-- 061 — La carte d'un lieu, retrouvée sans rescanner (V2.3 · K6, fait le 08/10)
--
-- Décision de Flavien (03/10) : le lieu devient la clé de la carte. Après un scan, on dit
-- où l'on est (un restaurant proche, ou un nom tapé : le nom est obligatoire) ; au même
-- endroit, la personne suivante se voit proposer la carte récente de ce lieu, sans
-- rescanner. Rescanner reste possible : la nouvelle carte remplace l'ancienne.
--
--   - Une carte par lieu (`lieu_cle` : identifiant OpenStreetMap, ou nom normalisé et
--     position arrondie du lieu). Jamais la position de la personne : celle du lieu,
--     arrondie au millième de degré (≈ 100 m) quand le lieu est tapé à la main.
--   - Ce qui est partagé : la carte telle que le scan l'a lue (vins, prix, devise), sans
--     les photos, sans les scores ni les annotations de cave de celui qui l'a scannée.
--     Qui l'a déposée est gardé pour borner les dépôts, et n'est jamais rendu.
--   - Lecture par toute session (anonyme comprise) ; écriture par `deposer_carte` seule,
--     dans le quota du jour (`consommer_quota_ia('depot_carte')`, migration 052).
--   - Récente : moins de 30 jours ; une carte de plus de 180 jours est supprimée.
--
-- Rejouable. Aucune donnée existante n'est modifiée.

CREATE TABLE IF NOT EXISTS public.cartes_de_lieux (
  lieu_cle     TEXT PRIMARY KEY CHECK (char_length(lieu_cle) BETWEEN 3 AND 200),
  lieu_nom     TEXT NOT NULL CHECK (char_length(btrim(lieu_nom)) BETWEEN 1 AND 120),
  latitude     DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
  longitude    DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
  carte        JSONB NOT NULL,
  nb_vins      INTEGER NOT NULL CHECK (nb_vins BETWEEN 1 AND 400),
  devise       TEXT CHECK (devise IS NULL OR devise ~ '^[A-Z]{3}$'),
  langue       TEXT CHECK (langue IS NULL OR langue ~ '^[a-z]{2}$'),
  ardoise      BOOLEAN NOT NULL DEFAULT false,
  deposee_par  UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  deposee_le   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS cartes_de_lieux_position ON public.cartes_de_lieux (latitude, longitude);

ALTER TABLE public.cartes_de_lieux ENABLE ROW LEVEL SECURITY;
-- Aucune politique : on n'y accède que par les fonctions ci-dessous, qui ne rendent jamais
-- `deposee_par`.
REVOKE ALL ON public.cartes_de_lieux FROM anon, authenticated;

-- Distance en mètres entre deux points proches (approximation équirectangulaire : à
-- quelques centaines de mètres, l'écart avec la formule exacte est négligeable).
CREATE OR REPLACE FUNCTION public.distance_m(lat1 DOUBLE PRECISION, lon1 DOUBLE PRECISION,
                                            lat2 DOUBLE PRECISION, lon2 DOUBLE PRECISION)
RETURNS DOUBLE PRECISION
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT 6371000 * sqrt(power(radians(lat2 - lat1), 2)
                        + power(cos(radians((lat1 + lat2) / 2)) * radians(lon2 - lon1), 2));
$$;

-- -----------------------------------------------------------------------------
-- Les cartes récentes autour d'un point, sans leur contenu.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.cartes_proches(p_lat DOUBLE PRECISION, p_lon DOUBLE PRECISION,
                                                p_rayon_m INTEGER DEFAULT 200)
RETURNS TABLE (lieu_cle TEXT, lieu_nom TEXT, distance_m INTEGER, nb_vins INTEGER, devise TEXT,
               ardoise BOOLEAN, deposee_le TIMESTAMPTZ)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_rayon INTEGER := least(greatest(coalesce(p_rayon_m, 200), 20), 1000);
  v_dlat  DOUBLE PRECISION;
  v_dlon  DOUBLE PRECISION;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'sans_session';
  END IF;
  IF p_lat IS NULL OR p_lon IS NULL OR p_lat NOT BETWEEN -90 AND 90 OR p_lon NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'position_invalide';
  END IF;
  -- Un rectangle d'abord (l'index), le cercle ensuite.
  v_dlat := v_rayon / 111320.0;
  v_dlon := v_rayon / (111320.0 * greatest(cos(radians(p_lat)), 0.01));
  RETURN QUERY
    SELECT c.lieu_cle, c.lieu_nom,
           round(public.distance_m(p_lat, p_lon, c.latitude, c.longitude))::INTEGER,
           c.nb_vins, c.devise, c.ardoise, c.deposee_le
    FROM public.cartes_de_lieux c
    WHERE c.latitude BETWEEN p_lat - v_dlat AND p_lat + v_dlat
      AND c.longitude BETWEEN p_lon - v_dlon AND p_lon + v_dlon
      AND public.distance_m(p_lat, p_lon, c.latitude, c.longitude) <= v_rayon
      AND c.deposee_le > now() - INTERVAL '30 days'
    ORDER BY public.distance_m(p_lat, p_lon, c.latitude, c.longitude), c.deposee_le DESC
    LIMIT 10;
END;
$$;

-- -----------------------------------------------------------------------------
-- La carte d'un lieu, pour l'ouvrir.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.carte_du_lieu(p_lieu_cle TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v RECORD;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'sans_session';
  END IF;
  SELECT c.lieu_cle, c.lieu_nom, c.carte, c.devise, c.ardoise, c.deposee_le INTO v
  FROM public.cartes_de_lieux c
  WHERE c.lieu_cle = p_lieu_cle AND c.deposee_le > now() - INTERVAL '30 days';
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  RETURN jsonb_build_object('lieu_cle', v.lieu_cle, 'lieu_nom', v.lieu_nom, 'carte', v.carte,
                            'devise', v.devise, 'ardoise', v.ardoise, 'deposee_le', v.deposee_le);
END;
$$;

-- -----------------------------------------------------------------------------
-- Déposer (ou remplacer) la carte d'un lieu.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.deposer_carte(p_lieu_cle TEXT, p_lieu_nom TEXT,
                                               p_lat DOUBLE PRECISION, p_lon DOUBLE PRECISION,
                                               p_carte JSONB, p_langue TEXT DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_uid    UUID := auth.uid();
  v_quota  JSONB;
  v_vins   JSONB;
  v_nb     INTEGER;
  v_devise TEXT;
  v_langue TEXT := lower(nullif(btrim(coalesce(p_langue, '')), ''));
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'sans_session';
  END IF;
  IF p_lieu_cle IS NULL OR char_length(p_lieu_cle) NOT BETWEEN 3 AND 200
     OR p_lieu_cle !~ '^(osm|nom):' THEN
    RAISE EXCEPTION 'lieu_invalide';
  END IF;
  IF p_lieu_nom IS NULL OR char_length(btrim(p_lieu_nom)) NOT BETWEEN 1 AND 120 THEN
    RAISE EXCEPTION 'nom_obligatoire';
  END IF;
  IF p_lat IS NULL OR p_lon IS NULL OR p_lat NOT BETWEEN -90 AND 90 OR p_lon NOT BETWEEN -180 AND 180 THEN
    RAISE EXCEPTION 'position_invalide';
  END IF;
  IF p_carte IS NULL OR jsonb_typeof(p_carte) <> 'object' OR pg_column_size(p_carte) > 400000 THEN
    RAISE EXCEPTION 'carte_invalide';
  END IF;
  v_vins := p_carte -> 'wines';
  IF v_vins IS NULL OR jsonb_typeof(v_vins) <> 'array' THEN
    RAISE EXCEPTION 'carte_invalide';
  END IF;
  v_nb := jsonb_array_length(v_vins);
  IF v_nb NOT BETWEEN 1 AND 400 THEN
    RAISE EXCEPTION 'carte_invalide';
  END IF;
  v_devise := upper(nullif(btrim(coalesce(p_carte ->> 'currency', '')), ''));
  IF v_devise IS NOT NULL AND v_devise !~ '^[A-Z]{3}$' THEN
    v_devise := NULL;
  END IF;
  IF v_langue IS NOT NULL AND v_langue !~ '^[a-z]{2}$' THEN
    v_langue := NULL;
  END IF;

  v_quota := public.consommer_quota_ia('depot_carte');
  IF NOT coalesce((v_quota ->> 'autorise')::BOOLEAN, false) THEN
    RAISE EXCEPTION 'quota_atteint';
  END IF;

  INSERT INTO public.cartes_de_lieux AS c
    (lieu_cle, lieu_nom, latitude, longitude, carte, nb_vins, devise, langue, ardoise, deposee_par, deposee_le)
  VALUES
    (p_lieu_cle, btrim(p_lieu_nom), p_lat, p_lon,
     -- Rien de personnel : ni photos, ni identifiant de la carte de l'appareil.
     p_carte - 'page_photo_paths' - 'id',
     v_nb, v_devise, v_langue, coalesce((p_carte ->> 'ardoise')::BOOLEAN, false), v_uid, now())
  ON CONFLICT (lieu_cle) DO UPDATE
    SET lieu_nom = EXCLUDED.lieu_nom, latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude,
        carte = EXCLUDED.carte, nb_vins = EXCLUDED.nb_vins, devise = EXCLUDED.devise,
        langue = EXCLUDED.langue, ardoise = EXCLUDED.ardoise, deposee_par = EXCLUDED.deposee_par,
        deposee_le = EXCLUDED.deposee_le;

  RETURN jsonb_build_object('lieu_cle', p_lieu_cle, 'nb_vins', v_nb);
END;
$$;

REVOKE ALL ON FUNCTION public.cartes_proches(DOUBLE PRECISION, DOUBLE PRECISION, INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.carte_du_lieu(TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.deposer_carte(TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, JSONB, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.cartes_proches(DOUBLE PRECISION, DOUBLE PRECISION, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.carte_du_lieu(TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.deposer_carte(TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, JSONB, TEXT) TO authenticated;

-- Le ménage : une carte de plus de 180 jours ne sert plus à personne (pg_cron, actif
-- depuis la 053). Sans pg_cron, rien n'est planifié et rien ne casse.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = 'cron') THEN
    PERFORM cron.unschedule(j.jobid) FROM cron.job j WHERE j.jobname = 'purge-cartes-de-lieux';
    PERFORM cron.schedule('purge-cartes-de-lieux', '23 4 * * *',
      $q$DELETE FROM public.cartes_de_lieux WHERE deposee_le < now() - INTERVAL '180 days'$q$);
  END IF;
END $$;

-- Retour arrière :
--   SELECT cron.unschedule('purge-cartes-de-lieux');   -- si pg_cron
--   DROP FUNCTION public.deposer_carte(TEXT, TEXT, DOUBLE PRECISION, DOUBLE PRECISION, JSONB, TEXT),
--     public.carte_du_lieu(TEXT), public.cartes_proches(DOUBLE PRECISION, DOUBLE PRECISION, INTEGER),
--     public.distance_m(DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION, DOUBLE PRECISION);
--   DROP TABLE public.cartes_de_lieux;

-- Vérification (SQL Editor) :
--   SELECT count(*) FROM public.cartes_de_lieux;                          → 0
--   SELECT jobname, schedule FROM cron.job WHERE jobname = 'purge-cartes-de-lieux';
--   SELECT round(public.distance_m(48.8566, 2.3522, 48.8576, 2.3522));    → ≈ 111
