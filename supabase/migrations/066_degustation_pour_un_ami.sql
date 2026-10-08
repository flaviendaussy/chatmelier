-- =============================================================================
-- 066 — La dégustation faite pour un ami lui arrive « à accepter » (V2.4 · R4)
-- =============================================================================
--
-- Le 07/10, Caro a noté un vin sur son téléphone, pour elle et pour Flavien. L'app appelait
-- `record_shared_tasting_log` (025), qui aurait écrit directement dans le journal de
-- Flavien — et qui n'a jamais été appliquée : rien n'est arrivé. Flavien demande l'inverse
-- d'une écriture directe : « ça devrait m'afficher que je l'ai vu avec Caro, et me demander
-- si je suis ok que cette dégustation s'affiche ici, comme c'est pas depuis mon téléphone
-- qu'elle a été faite ». 025 n'est donc PAS à appliquer.
--
-- 1. `degustations_proposees` : la dégustation et un instantané du vin (le destinataire
--    n'a pas forcément accès à la cave de l'auteur), à accepter ou à refuser.
-- 2. `proposer_degustation(...)` : entre amis (amitié acceptée) ou membres d'une même
--    cave ; 30 propositions en attente au plus d'une personne à une autre ; une
--    notification « degustation_a_accepter », rédigée à l'affichage dans la langue du
--    destinataire (J8).
-- 3. `accepter_degustation(id)` : le destinataire seul. Sa propre fiche du vin, copiée de
--    l'instantané (la sienne et celle de l'auteur ne se bloquent jamais l'une l'autre : les
--    clés de tasting_log sont en NO ACTION), puis la ligne de son journal, l'auteur parmi
--    les convives (« vu avec Caro »). Rend les réponses, que l'app apprend au palais — sauf
--    bouteille défectueuse.
-- 4. `refuser_degustation(id)`.
-- 5. Les durées : une proposition décidée part après 30 jours, une proposition jamais
--    décidée après 180 (la purge nocturne de la 063, reprise de la 065).
--
-- Rejouable.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.degustations_proposees (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auteur_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pour_id          UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  vin              JSONB NOT NULL CHECK (jsonb_typeof(vin) = 'object'
                                         AND length(coalesce(vin ->> 'nom', '')) BETWEEN 1 AND 200
                                         AND length(vin::text) <= 4000),
  note             NUMERIC(3,1) CHECK (note IS NULL OR note BETWEEN 0 AND 10),
  questionnaire    JSONB CHECK (questionnaire IS NULL OR length(questionnaire::text) <= 20000),
  defaut           TEXT CHECK (defaut IS NULL OR length(defaut) <= 40),
  plat             TEXT CHECK (plat IS NULL OR length(plat) <= 200),
  lieu             TEXT CHECK (lieu IS NULL OR length(lieu) <= 200),
  convives         JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(convives) = 'array'
                                                             AND length(convives::text) <= 2000),
  proprietaire_nom TEXT CHECK (proprietaire_nom IS NULL OR length(proprietaire_nom) <= 120),
  degustee_le      TIMESTAMPTZ NOT NULL DEFAULT now(),
  statut           TEXT NOT NULL DEFAULT 'a_accepter' CHECK (statut IN ('a_accepter', 'acceptee', 'refusee')),
  tasting_log_id   UUID,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  decidee_le       TIMESTAMPTZ,
  CHECK (auteur_id <> pour_id)
);
CREATE INDEX IF NOT EXISTS degustations_proposees_pour ON public.degustations_proposees (pour_id, statut);
CREATE INDEX IF NOT EXISTS degustations_proposees_auteur ON public.degustations_proposees (auteur_id, pour_id, statut);

ALTER TABLE public.degustations_proposees ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS degustations_proposees_lecture ON public.degustations_proposees;
CREATE POLICY degustations_proposees_lecture ON public.degustations_proposees
  FOR SELECT TO authenticated USING (auth.uid() IN (auteur_id, pour_id));
GRANT SELECT ON public.degustations_proposees TO authenticated;
-- Aucune écriture directe : tout passe par les fonctions ci-dessous.

-- -----------------------------------------------------------------------------
-- Proposer
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.proposer_degustation(
  p_pour             UUID,
  p_vin              JSONB,
  p_note             NUMERIC DEFAULT NULL,
  p_questionnaire    JSONB DEFAULT NULL,
  p_defaut           TEXT DEFAULT NULL,
  p_plat             TEXT DEFAULT NULL,
  p_lieu             TEXT DEFAULT NULL,
  p_convives         JSONB DEFAULT '[]'::jsonb,
  p_proprietaire_nom TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_moi UUID := auth.uid();
  v_id  UUID;
BEGIN
  IF v_moi IS NULL THEN
    RAISE EXCEPTION 'session_requise';
  END IF;
  IF p_pour IS NULL OR p_pour = v_moi THEN
    RAISE EXCEPTION 'destinataire_invalide';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.friendships f
        WHERE f.status = 'accepted'
          AND ((f.user_id = v_moi AND f.friend_id = p_pour) OR (f.user_id = p_pour AND f.friend_id = v_moi)))
     AND NOT EXISTS (
       SELECT 1 FROM public.cellar_members a
         JOIN public.cellar_members b ON b.cellar_id = a.cellar_id
        WHERE a.user_id = v_moi AND b.user_id = p_pour) THEN
    RAISE EXCEPTION 'pas_ami';
  END IF;
  IF (SELECT count(*) FROM public.degustations_proposees d
       WHERE d.auteur_id = v_moi AND d.pour_id = p_pour AND d.statut = 'a_accepter') >= 30 THEN
    RAISE EXCEPTION 'trop_de_propositions';
  END IF;

  INSERT INTO public.degustations_proposees
    (auteur_id, pour_id, vin, note, questionnaire, defaut, plat, lieu, convives, proprietaire_nom)
  VALUES
    (v_moi, p_pour, p_vin, p_note, p_questionnaire, nullif(btrim(p_defaut), ''), nullif(btrim(p_plat), ''),
     nullif(btrim(p_lieu), ''), coalesce(p_convives, '[]'::jsonb), nullif(btrim(p_proprietaire_nom), ''))
  RETURNING id INTO v_id;

  -- Le titre et le texte rangés ne servent qu'aux versions qui ne connaissent pas ce type :
  -- l'app les rédige à l'affichage, dans la langue du destinataire, depuis `data`.
  INSERT INTO public.user_notifications (user_id, actor_id, type, title, body, data)
  VALUES (p_pour, v_moi, 'degustation_a_accepter',
          'Une dégustation à ajouter à votre journal',
          (p_vin ->> 'nom') || ' : à accepter dans Chatmelier.',
          jsonb_build_object('degustation_id', v_id, 'vin', p_vin ->> 'nom', 'millesime', p_vin -> 'millesime',
                             'note', p_note, 'date', now(), 'defaut', nullif(btrim(p_defaut), '')));
  RETURN v_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- Accepter
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.accepter_degustation(p_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_moi      UUID := auth.uid();
  d          public.degustations_proposees%ROWTYPE;
  v_vin      UUID := gen_random_uuid();
  v_log      UUID := gen_random_uuid();
  v_auteur   TEXT;
  v_moi_nom  TEXT;
  v_convives JSONB;
  v_cepages  JSONB;
BEGIN
  IF v_moi IS NULL THEN
    RAISE EXCEPTION 'session_requise';
  END IF;
  SELECT * INTO d FROM public.degustations_proposees WHERE id = p_id AND pour_id = v_moi FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'proposition_introuvable';
  END IF;
  IF d.statut <> 'a_accepter' THEN
    RAISE EXCEPTION 'deja_decidee';
  END IF;

  SELECT coalesce(nullif(btrim(p.display_name), ''), 'Chatmelier') INTO v_auteur FROM public.profiles p WHERE p.id = d.auteur_id;
  SELECT coalesce(btrim(p.display_name), '') INTO v_moi_nom FROM public.profiles p WHERE p.id = v_moi;
  -- « Vu avec Caro » : l'auteur parmi les convives, une fois, et sans le destinataire lui-même.
  SELECT coalesce(jsonb_agg(c ORDER BY c), '[]'::jsonb) INTO v_convives
    FROM (SELECT DISTINCT btrim(x) AS c
            FROM jsonb_array_elements_text(d.convives || to_jsonb(coalesce(v_auteur, 'Chatmelier'))) x
           WHERE btrim(x) <> '' AND btrim(x) <> coalesce(v_moi_nom, '')) t;
  v_cepages := CASE WHEN jsonb_typeof(d.vin -> 'cepages') = 'array'
                    THEN (SELECT coalesce(jsonb_agg(jsonb_build_object('name', g)), '[]'::jsonb)
                            FROM jsonb_array_elements_text(d.vin -> 'cepages') g)
                    ELSE '[]'::jsonb END;

  INSERT INTO public.wines (id, name, producer, vintage, wine_type, region, appellation, country, grapes, image_url,
                            created_by)
  VALUES (v_vin, d.vin ->> 'nom', nullif(d.vin ->> 'producteur', ''),
          CASE WHEN (d.vin ->> 'millesime') ~ '^[0-9]{4}$' THEN (d.vin ->> 'millesime')::int END,
          nullif(d.vin ->> 'couleur', ''), nullif(d.vin ->> 'region', ''), nullif(d.vin ->> 'appellation', ''),
          nullif(d.vin ->> 'pays', ''), v_cepages, nullif(d.vin ->> 'photo', ''), v_moi);

  INSERT INTO public.tasting_log (id, wine_id, user_id, rating, rating_scale, occasion, food_paired, photo_url,
                                  consumed_at, co_tasters, bottle_owner_name, location_name, is_external, fault)
  VALUES (v_log, v_vin, v_moi, d.note, 10, d.lieu, d.plat, nullif(d.vin ->> 'photo', ''), d.degustee_le, v_convives,
          d.proprietaire_nom, d.lieu, true, d.defaut);

  UPDATE public.degustations_proposees
     SET statut = 'acceptee', decidee_le = now(), tasting_log_id = v_log
   WHERE id = p_id;
  UPDATE public.user_notifications
     SET is_read = true
   WHERE user_id = v_moi AND type = 'degustation_a_accepter' AND data ->> 'degustation_id' = p_id::text;

  RETURN jsonb_build_object('tasting_log_id', v_log, 'wine_id', v_vin, 'questionnaire', d.questionnaire,
                            'defaut', d.defaut, 'vin', d.vin, 'auteur', v_auteur);
END;
$$;

-- -----------------------------------------------------------------------------
-- Refuser
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.refuser_degustation(p_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_moi UUID := auth.uid();
BEGIN
  IF v_moi IS NULL THEN
    RAISE EXCEPTION 'session_requise';
  END IF;
  UPDATE public.degustations_proposees
     SET statut = 'refusee', decidee_le = now()
   WHERE id = p_id AND pour_id = v_moi AND statut = 'a_accepter';
  IF NOT FOUND THEN
    RAISE EXCEPTION 'proposition_introuvable';
  END IF;
  UPDATE public.user_notifications
     SET is_read = true
   WHERE user_id = v_moi AND type = 'degustation_a_accepter' AND data ->> 'degustation_id' = p_id::text;
END;
$$;

REVOKE ALL ON FUNCTION public.proposer_degustation(UUID, JSONB, NUMERIC, JSONB, TEXT, TEXT, TEXT, JSONB, TEXT) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.accepter_degustation(UUID) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.refuser_degustation(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.proposer_degustation(UUID, JSONB, NUMERIC, JSONB, TEXT, TEXT, TEXT, JSONB, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.accepter_degustation(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.refuser_degustation(UUID) TO authenticated;

-- -----------------------------------------------------------------------------
-- Les durées (063, 065) : + les propositions.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.purger_selon_les_durees()
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_journaux     INTEGER := 0;
  v_retours      INTEGER := 0;
  v_couts        INTEGER := 0;
  v_pubs         INTEGER := 0;
  v_revenus      INTEGER := 0;
  v_propositions INTEGER := 0;
BEGIN
  DELETE FROM public.app_diagnostic_logs
   WHERE tag <> 'USER_FEEDBACK' AND created_at < now() - INTERVAL '180 days';
  GET DIAGNOSTICS v_journaux = ROW_COUNT;

  DELETE FROM public.app_diagnostic_logs
   WHERE tag = 'USER_FEEDBACK' AND created_at < now() - INTERVAL '365 days';
  GET DIAGNOSTICS v_retours = ROW_COUNT;

  IF to_regclass('public.ai_cost_events') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.ai_cost_events WHERE occurred_at < now() - INTERVAL ''400 days''';
    GET DIAGNOSTICS v_couts = ROW_COUNT;
  END IF;
  IF to_regclass('public.ad_impressions') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.ad_impressions WHERE occurred_at < now() - INTERVAL ''400 days''';
    GET DIAGNOSTICS v_pubs = ROW_COUNT;
  END IF;
  IF to_regclass('public.ad_revenus') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.ad_revenus WHERE occurred_at < now() - INTERVAL ''400 days''';
    GET DIAGNOSTICS v_revenus = ROW_COUNT;
  END IF;
  IF to_regclass('public.degustations_proposees') IS NOT NULL THEN
    EXECUTE 'DELETE FROM public.degustations_proposees
              WHERE (statut <> ''a_accepter'' AND decidee_le < now() - INTERVAL ''30 days'')
                 OR (statut = ''a_accepter'' AND created_at < now() - INTERVAL ''180 days'')';
    GET DIAGNOSTICS v_propositions = ROW_COUNT;
  END IF;

  RETURN jsonb_build_object('journaux', v_journaux, 'retours', v_retours, 'couts_ia', v_couts, 'pubs', v_pubs,
                            'revenus_pub', v_revenus, 'propositions', v_propositions);
END;
$$;

REVOKE ALL ON FUNCTION public.purger_selon_les_durees() FROM PUBLIC;

-- Retour arrière :
--   DROP FUNCTION public.proposer_degustation(UUID, JSONB, NUMERIC, JSONB, TEXT, TEXT, TEXT, JSONB, TEXT);
--   DROP FUNCTION public.accepter_degustation(UUID);
--   DROP FUNCTION public.refuser_degustation(UUID);
--   DROP TABLE public.degustations_proposees;
--   (puis rejouer 065 pour la purge sans les propositions)

-- Vérification (SQL Editor) :
--   SELECT proname FROM pg_proc WHERE proname IN ('proposer_degustation', 'accepter_degustation', 'refuser_degustation');
--   SELECT policyname, cmd FROM pg_policies WHERE tablename = 'degustations_proposees';
--     → degustations_proposees_lecture SELECT (et aucune autre : pas d'écriture directe)
