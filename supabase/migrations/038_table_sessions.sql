-- =============================================================================
-- 038 — Les tables de restaurant vivent côté serveur
-- =============================================================================
-- CONSTAT. Une « table » n'existait que dans une `static Map` en mémoire du téléphone
-- hôte (`MenuTableSessionManager._activeSessions`). Conséquences en chaîne :
--   · l'invité ne pouvait recevoir la carte QUE par l'URL du QR, d'où la compression et
--     ses seize vins maximum ;
--   · rien ne se partageait en retour : chacun votait dans son coin, et l'hôte ne voyait
--     jamais les préférences des autres ;
--   · fermer l'app perdait la table ;
--   · le « code de partage » affiché à l'écran ne correspondait à rien côté serveur.
--
-- Une table en base règle les quatre d'un coup, et rend le QR facultatif : un code de six
-- caractères tapé à la main suffit.
--
-- CE QUI N'EST PAS ICI, ET POURQUOI. Pas de politique de lecture directe pour `anon`, donc
-- pas de temps réel pour l'instant. Une politique RLS ne peut pas recevoir le code en
-- paramètre ; l'ouvrir à tous reviendrait à laisser n'importe qui lister les tables en
-- cours. La lecture passe donc par une fonction qui exige le code. Le temps réel viendra
-- avec les comptes anonymes (S3 bis) : c'est `auth.uid()` qui rend la politique
-- exprimable, pas l'inverse.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.table_sessions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Six caractères tapables sans se tromper : pas de 0/O, pas de 1/I/L.
  code            TEXT NOT NULL UNIQUE
                  CHECK (code ~ '^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$'),

  host_user_id    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  restaurant_name TEXT NOT NULL DEFAULT 'Restaurant',

  -- La carte entière, sans les seize vins du QR : ici la place ne coûte rien.
  menu            JSONB NOT NULL,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Quatre heures : la durée d'un repas, marges comprises. Au-delà, le code se recycle.
  expires_at      TIMESTAMPTZ NOT NULL DEFAULT now() + interval '4 hours'
);

CREATE INDEX IF NOT EXISTS table_sessions_expires_idx
  ON public.table_sessions(expires_at);

COMMENT ON COLUMN public.table_sessions.code IS
  'Code court à dire à voix haute. Alphabet sans 0/O ni 1/I/L : il sera lu de travers '
  'dans un restaurant mal éclairé.';

-- Les convives et ce qu'ils déclarent aimer.
CREATE TABLE IF NOT EXISTS public.table_session_guests (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.table_sessions(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

  -- Le nom donné à table. Pas de compte exigé : demander une inscription au moment où
  -- l'on tend son téléphone à un ami tuerait la seule boucle virale du produit.
  guest_name TEXT NOT NULL,

  -- Profil de goût déclaré ou importé, tel que le moteur de consensus l'attend.
  profile    JSONB NOT NULL DEFAULT '{}'::jsonb,

  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (session_id, guest_name)
);

CREATE INDEX IF NOT EXISTS table_session_guests_session_idx
  ON public.table_session_guests(session_id);

ALTER TABLE public.table_sessions       ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.table_session_guests ENABLE ROW LEVEL SECURITY;

-- L'hôte connecté voit et gère ses propres tables.
DROP POLICY IF EXISTS "host_reads_own_sessions" ON public.table_sessions;
CREATE POLICY "host_reads_own_sessions"
  ON public.table_sessions FOR SELECT TO authenticated
  USING (host_user_id = auth.uid());

DROP POLICY IF EXISTS "host_creates_sessions" ON public.table_sessions;
CREATE POLICY "host_creates_sessions"
  ON public.table_sessions FOR INSERT TO authenticated
  WITH CHECK (host_user_id = auth.uid());

DROP POLICY IF EXISTS "host_deletes_own_sessions" ON public.table_sessions;
CREATE POLICY "host_deletes_own_sessions"
  ON public.table_sessions FOR DELETE TO authenticated
  USING (host_user_id = auth.uid());

-- Tout le reste — rejoindre, lire la carte, voir qui est là — passe par les fonctions
-- ci-dessous, qui exigent le code.

-- =============================================================================
-- Rejoindre une table
-- =============================================================================
CREATE OR REPLACE FUNCTION public.join_table_session(
  p_code       TEXT,
  p_guest_name TEXT,
  p_profile    JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE (
  session_id      UUID,
  restaurant_name TEXT,
  menu            JSONB,
  expires_at      TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_session public.table_sessions%ROWTYPE;
BEGIN
  SELECT * INTO v_session
  FROM public.table_sessions s
  WHERE s.code = upper(trim(p_code)) AND s.expires_at > now();

  IF NOT FOUND THEN
    -- Un message et non un silence : « aucune table » et « table expirée » demandent
    -- deux gestes différents de la part de la personne.
    RAISE EXCEPTION 'table_introuvable'
      USING HINT = 'Code inconnu ou table expirée.';
  END IF;

  IF coalesce(trim(p_guest_name), '') = '' THEN
    RAISE EXCEPTION 'nom_requis' USING HINT = 'Un nom est nécessaire pour rejoindre.';
  END IF;

  INSERT INTO public.table_session_guests (session_id, user_id, guest_name, profile)
  VALUES (v_session.id, auth.uid(), trim(p_guest_name), coalesce(p_profile, '{}'::jsonb))
  ON CONFLICT (session_id, guest_name)
    DO UPDATE SET profile = EXCLUDED.profile;

  RETURN QUERY SELECT v_session.id, v_session.restaurant_name,
                      v_session.menu, v_session.expires_at;
END;
$$;

-- =============================================================================
-- Voir qui est à table
-- =============================================================================
-- Exige le code à chaque appel : c'est lui qui tient lieu d'autorisation, et le
-- redemander évite qu'un identifiant de session capté ailleurs suffise.
CREATE OR REPLACE FUNCTION public.read_table_session_guests(p_code TEXT)
RETURNS TABLE (guest_name TEXT, profile JSONB, created_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  SELECT s.id INTO v_id
  FROM public.table_sessions s
  WHERE s.code = upper(trim(p_code)) AND s.expires_at > now();

  IF NOT FOUND THEN
    RAISE EXCEPTION 'table_introuvable' USING HINT = 'Code inconnu ou table expirée.';
  END IF;

  RETURN QUERY
    SELECT g.guest_name, g.profile, g.created_at
    FROM public.table_session_guests g
    WHERE g.session_id = v_id
    ORDER BY g.created_at;
END;
$$;

-- =============================================================================
-- Ouvrir une table
-- =============================================================================
-- Le code est tiré ici et non côté client : deux téléphones qui ouvrent une table à la
-- même seconde ne doivent pas pouvoir tomber sur le même.
CREATE OR REPLACE FUNCTION public.open_table_session(
  p_restaurant_name TEXT,
  p_menu            JSONB
)
RETURNS TABLE (session_id UUID, code TEXT, expires_at TIMESTAMPTZ)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_alphabet CONSTANT TEXT := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_code     TEXT;
  v_row      public.table_sessions%ROWTYPE;
  v_essai    INT := 0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'connexion_requise'
      USING HINT = 'Ouvrir une table demande un compte ; la rejoindre, non.';
  END IF;

  LOOP
    v_essai := v_essai + 1;
    v_code := '';
    FOR i IN 1..6 LOOP
      v_code := v_code || substr(v_alphabet, 1 + floor(random() * length(v_alphabet))::int, 1);
    END LOOP;

    BEGIN
      INSERT INTO public.table_sessions (code, host_user_id, restaurant_name, menu)
      VALUES (v_code, auth.uid(),
              coalesce(nullif(trim(p_restaurant_name), ''), 'Restaurant'),
              coalesce(p_menu, '{}'::jsonb))
      RETURNING * INTO v_row;
      EXIT;
    EXCEPTION WHEN unique_violation THEN
      -- Collision : on retire. Trente et un caractères puissance six laissent de la
      -- marge, mais les codes expirés ne libèrent leur place qu'au ménage.
      IF v_essai >= 8 THEN
        RAISE EXCEPTION 'code_indisponible'
          USING HINT = 'Réessayez dans un instant.';
      END IF;
    END;
  END LOOP;

  RETURN QUERY SELECT v_row.id, v_row.code, v_row.expires_at;
END;
$$;

-- =============================================================================
-- Ménage
-- =============================================================================
-- Sans lui, les codes expirés occupent l'espace de noms indéfiniment et finissent par
-- faire échouer l'ouverture de table. À brancher sur pg_cron, ou à appeler depuis la
-- fonction edge qui tourne déjà quotidiennement.
CREATE OR REPLACE FUNCTION public.purge_expired_table_sessions()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_n INTEGER;
BEGIN
  DELETE FROM public.table_sessions WHERE expires_at < now() - interval '24 hours';
  GET DIAGNOSTICS v_n = ROW_COUNT;
  RETURN v_n;
END;
$$;

REVOKE ALL ON FUNCTION public.open_table_session(TEXT, JSONB) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.open_table_session(TEXT, JSONB) TO authenticated;

GRANT EXECUTE ON FUNCTION public.join_table_session(TEXT, TEXT, JSONB) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.read_table_session_guests(TEXT) TO anon, authenticated;

REVOKE ALL ON FUNCTION public.purge_expired_table_sessions() FROM PUBLIC;

-- Vérification :
--   SELECT * FROM open_table_session('Le Comptoir', '{"wines":[]}'::jsonb);
--   SELECT * FROM join_table_session('<code>', 'Paul');
--   SELECT * FROM read_table_session_guests('<code>');
--   SELECT * FROM join_table_session('ZZZZZZ', 'Paul');  -- doit lever table_introuvable
