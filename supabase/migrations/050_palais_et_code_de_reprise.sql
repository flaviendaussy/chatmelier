-- =============================================================================
-- 050 — Le palais côté serveur, et le code de reprise (P6, 29/09)
-- (après la 049, dont la purge sert à effacer l'ancien compte anonyme)
-- =============================================================================
-- Constat : le palais (profils de goût, registre des preuves, instantanés mensuels)
-- ne vivait que dans le téléphone. « Ajoutez votre adresse pour retrouver votre soirée
-- ailleurs » gardait le compte, pas le palais ; et un invité web qui vide son cache
-- perdait tout, compte compris.
--
-- 1. Le palais est désormais recopié côté serveur, sous le compte de la personne, lisible
--    par elle seule (il n'a rien à faire dans `profiles`, lisible par tous).
-- 2. Un compte anonyme peut demander un code de reprise : huit signes, valables trente
--    jours, à usage unique, qui rendent la soirée sur n'importe quel appareil.
--
-- SÉCURITÉ DU CODE
-- • Tiré par gen_random_bytes (aléa cryptographique), 32 signes sans 0/O/1/I : 32^8 ≈
--   1,1·10^12 combinaisons. 32 divise 256 : aucun biais de modulo.
-- • Jamais stocké en clair : seule son empreinte SHA-256 est gardée.
-- • Cinq essais manqués par heure et par compte, plus un coupe-circuit global (trois cents
--   échecs en dix minutes, tous comptes confondus, suspendent la reprise). Les échecs sont
--   RENDUS et non levés : une exception annulerait l'enregistrement de l'essai manqué, et
--   la limite ne compterait jamais rien.
-- • Même réponse pour un code inconnu, expiré ou déjà servi : aucun oracle.
-- • Aucune adresse e-mail en jeu : le code ne révèle rien de personne.
-- • La reprise ne fusionne pas deux histoires : elle vise un compte vierge, transfère la
--   soirée, puis efface l'ancien compte anonyme (sa session éventuelle n'écrira plus dans
--   un orphelin).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Le palais de chacun
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.palais_utilisateur (
  user_id    UUID PRIMARY KEY DEFAULT auth.uid() REFERENCES auth.users(id) ON DELETE CASCADE,
  -- Les trois mémoires du téléphone, telles quelles (JSON) : profils de goût, registre
  -- des preuves, instantanés mensuels.
  profils    JSONB NOT NULL DEFAULT '[]'::jsonb,
  preuves    JSONB NOT NULL DEFAULT '[]'::jsonb,
  historique JSONB NOT NULL DEFAULT '[]'::jsonb,
  maj_le     TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- Un compte anonyme s'ouvre sans formulaire : on borne ce qu'il peut entreposer.
  CONSTRAINT palais_taille_raisonnable
    CHECK (pg_column_size(profils) + pg_column_size(preuves) + pg_column_size(historique) < 2000000)
);

ALTER TABLE public.palais_utilisateur ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS palais_lecture ON public.palais_utilisateur;
CREATE POLICY palais_lecture ON public.palais_utilisateur
  FOR SELECT TO authenticated USING (user_id = auth.uid());
DROP POLICY IF EXISTS palais_ajout ON public.palais_utilisateur;
CREATE POLICY palais_ajout ON public.palais_utilisateur
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS palais_maj ON public.palais_utilisateur;
CREATE POLICY palais_maj ON public.palais_utilisateur
  FOR UPDATE TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

GRANT SELECT, INSERT, UPDATE ON public.palais_utilisateur TO authenticated;

-- -----------------------------------------------------------------------------
-- 2. Les codes de reprise
-- -----------------------------------------------------------------------------
-- Aucune politique : ces tables ne se lisent et ne s'écrivent que par les deux fonctions
-- ci-dessous.
CREATE TABLE IF NOT EXISTS public.codes_de_reprise (
  user_id    UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  empreinte  BYTEA NOT NULL UNIQUE,
  cree_le    TIMESTAMPTZ NOT NULL DEFAULT now(),
  expire_le  TIMESTAMPTZ NOT NULL,
  utilise_le TIMESTAMPTZ
);
ALTER TABLE public.codes_de_reprise ENABLE ROW LEVEL SECURITY;

CREATE TABLE IF NOT EXISTS public.tentatives_de_reprise (
  id      BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL,
  le      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS tentatives_de_reprise_compte ON public.tentatives_de_reprise (user_id, le);
CREATE INDEX IF NOT EXISTS tentatives_de_reprise_date ON public.tentatives_de_reprise (le);
ALTER TABLE public.tentatives_de_reprise ENABLE ROW LEVEL SECURITY;

-- Un compte anonyme demande son code. Le redemander remplace le précédent.
CREATE OR REPLACE FUNCTION public.creer_code_de_reprise()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_moi      UUID := auth.uid();
  v_alphabet CONSTANT TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_octets   BYTEA;
  v_code     TEXT := '';
BEGIN
  IF v_moi IS NULL THEN
    RAISE EXCEPTION 'non_connecte';
  END IF;
  -- Un compte nommé se retrouve par son adresse : le code ne sert qu'aux anonymes.
  IF NOT public.est_anonyme() THEN
    RAISE EXCEPTION 'compte_nomme';
  END IF;

  v_octets := extensions.gen_random_bytes(8);
  FOR i IN 0..7 LOOP
    v_code := v_code || substr(v_alphabet, 1 + (get_byte(v_octets, i) % 32), 1);
  END LOOP;

  INSERT INTO public.codes_de_reprise (user_id, empreinte, expire_le)
  VALUES (v_moi, extensions.digest(v_code, 'sha256'), now() + interval '30 days')
  ON CONFLICT (user_id) DO UPDATE
    SET empreinte = EXCLUDED.empreinte,
        cree_le = now(),
        expire_le = EXCLUDED.expire_le,
        utilise_le = NULL;

  RETURN substr(v_code, 1, 4) || '-' || substr(v_code, 5, 4);
END;
$$;
REVOKE ALL ON FUNCTION public.creer_code_de_reprise() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.creer_code_de_reprise() TO authenticated;

-- Le compte courant (vierge) reprend la soirée du code. Rend un objet JSON :
--   {"degustations": n, "messages": n, "tables": n, "palais": bool}  en cas de succès ;
--   {"erreur": "code_invalide" | "trop_de_tentatives" | "reprise_suspendue"
--              | "compte_deja_utilise" | "non_connecte"}                sinon ;
--   {"deja": true}  si le code est celui du compte courant.
CREATE OR REPLACE FUNCTION public.reprendre_avec_code(p_code TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_moi    UUID := auth.uid();
  v_code   TEXT := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  v_source UUID;
  v_deg    INTEGER := 0;
  v_msg    INTEGER := 0;
  v_tab    INTEGER := 0;
  v_palais BOOLEAN := false;
BEGIN
  IF v_moi IS NULL THEN
    RETURN jsonb_build_object('erreur', 'non_connecte');
  END IF;

  -- Le ménage des vieilles tentatives, au passage.
  DELETE FROM public.tentatives_de_reprise WHERE le < now() - interval '1 day';

  IF (SELECT count(*) FROM public.tentatives_de_reprise
      WHERE user_id = v_moi AND le > now() - interval '1 hour') >= 5 THEN
    RETURN jsonb_build_object('erreur', 'trop_de_tentatives');
  END IF;
  IF (SELECT count(*) FROM public.tentatives_de_reprise
      WHERE le > now() - interval '10 minutes') >= 300 THEN
    RETURN jsonb_build_object('erreur', 'reprise_suspendue');
  END IF;

  -- FOR UPDATE : deux reprises simultanées du même code se suivent au lieu de se partager
  -- la soirée.
  SELECT user_id INTO v_source
  FROM public.codes_de_reprise
  WHERE empreinte = extensions.digest(v_code, 'sha256')
    AND utilise_le IS NULL
    AND expire_le > now()
  FOR UPDATE;

  IF v_source IS NULL THEN
    INSERT INTO public.tentatives_de_reprise (user_id) VALUES (v_moi);
    RETURN jsonb_build_object('erreur', 'code_invalide');
  END IF;

  IF v_source = v_moi THEN
    RETURN jsonb_build_object('deja', true);
  END IF;

  -- Pas de fusion de deux histoires : le compte qui reprend doit être vierge.
  IF EXISTS (SELECT 1 FROM public.tasting_log WHERE user_id = v_moi)
     OR EXISTS (SELECT 1 FROM public.palais_utilisateur
                WHERE user_id = v_moi
                  AND jsonb_path_exists(profils, '$[*] ? (@.questionnaires_completed > 0)')) THEN
    RETURN jsonb_build_object('erreur', 'compte_deja_utilise');
  END IF;

  -- tasting_log et chat_messages référencent profiles : le compte d'arrivée doit y figurer.
  INSERT INTO public.profiles (id, display_name) VALUES (v_moi, 'Invité')
  ON CONFLICT (id) DO NOTHING;

  UPDATE public.tasting_log SET user_id = v_moi WHERE user_id = v_source;
  GET DIAGNOSTICS v_deg = ROW_COUNT;
  UPDATE public.chat_messages SET user_id = v_moi WHERE user_id = v_source;
  GET DIAGNOSTICS v_msg = ROW_COUNT;
  UPDATE public.table_session_guests SET user_id = v_moi WHERE user_id = v_source;
  GET DIAGNOSTICS v_tab = ROW_COUNT;
  -- Ce que la soirée a coûté et rapporté la suit (mesure P1) — si la migration 047 est
  -- passée : sinon ces tables n'existent pas encore.
  IF to_regclass('public.ai_cost_events') IS NOT NULL THEN
    EXECUTE 'UPDATE public.ai_cost_events SET user_id = $1 WHERE user_id = $2' USING v_moi, v_source;
  END IF;
  IF to_regclass('public.ad_impressions') IS NOT NULL THEN
    EXECUTE 'UPDATE public.ad_impressions SET user_id = $1 WHERE user_id = $2' USING v_moi, v_source;
  END IF;

  IF EXISTS (SELECT 1 FROM public.palais_utilisateur WHERE user_id = v_source) THEN
    DELETE FROM public.palais_utilisateur WHERE user_id = v_moi;
    UPDATE public.palais_utilisateur SET user_id = v_moi, maj_le = now() WHERE user_id = v_source;
    v_palais := true;
  END IF;

  -- L'ancien compte, vidé, disparaît (son code avec lui, par cascade).
  PERFORM public.purger_donnees_utilisateur(v_source);

  RETURN jsonb_build_object('degustations', v_deg, 'messages', v_msg, 'tables', v_tab, 'palais', v_palais);
END;
$$;
REVOKE ALL ON FUNCTION public.reprendre_avec_code(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reprendre_avec_code(TEXT) TO authenticated;

-- Vérification :
--   SELECT relname, relrowsecurity FROM pg_class
--   WHERE relname IN ('palais_utilisateur', 'codes_de_reprise', 'tentatives_de_reprise');
--     → trois lignes, relrowsecurity = true
--   SELECT policyname FROM pg_policies WHERE tablename = 'palais_utilisateur';
--     → palais_lecture, palais_ajout, palais_maj
--   SELECT count(*) FROM pg_policies WHERE tablename IN ('codes_de_reprise', 'tentatives_de_reprise');
--     → 0 (fonctions seulement)
