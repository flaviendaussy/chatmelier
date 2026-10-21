-- 075 · Les notifications push (lot N, version 86, 21/10).
--
-- Décision de Flavien (16/10) : « des notifications push réelles tout de suite », à
-- commencer par « Caro a ajouté des bouteilles à votre cave », au moment exact.
--
--   1. `appareils_push` : un téléphone qui accepte les notifications (jeton FCM, langue,
--      décalage horaire, préférences). Ni lecture ni écriture directe : l'app passe par
--      `enregistrer_appareil_push` et `oublier_appareil_push`, la fonction `envoyer-push`
--      par service_role.
--   2. `user_notifications` reçoit `par_le_serveur` et `pousse_le`. Une notification n'est
--      poussée que si un code SERVEUR l'a écrite (fonction SECURITY DEFINER, déclencheur,
--      service_role) : tant que la 076 n'a pas fermé les écritures directes, n'importe quel
--      compte peut écrire dans la boîte de n'importe qui (revue Q1b) — ces lignes restent
--      dans la boîte, jamais sur l'écran verrouillé d'un autre.
--   3. Activité d'une cave partagée : une bouteille ajoutée par un membre prévient les
--      autres. Une seule notification par personne, par cave et par demi-heure : les ajouts
--      suivants la complètent (« 6 bouteilles ») sans nouveau push.
--   4. Chaque notification du serveur appelle `envoyer-push` (pg_net, asynchrone : rien
--      n'attend, rien n'échoue si l'envoi échoue). Adresse dans `app_config.push`.
--
-- Changement Supabase du 30/10 : la table porte ses droits explicites (service_role seul).
--
-- À appliquer AVANT d'installer la 86 (l'app s'en passe si elle manque : pas de push).
-- Puis déployer la fonction `envoyer-push` en décochant « Enforce JWT verification »
-- (la base l'appelle sans jeton ; elle ne fait rien d'autre qu'envoyer, une fois, une
-- notification déjà écrite par le serveur).
--
-- Vérification :
--   SELECT extname FROM pg_extension WHERE extname = 'pg_net';                 -- pg_net
--   SELECT valeur FROM public.app_config WHERE cle = 'push';                   -- l'adresse
--   SELECT count(*) FROM pg_trigger WHERE tgname LIKE 'push_%' OR tgname LIKE 'activite_cave_%';  -- 4

-- ─── 0. pg_net (disponible sur Supabase ; absent de la base jetable des essais) ───────
DO $$
BEGIN
  CREATE EXTENSION IF NOT EXISTS pg_net;
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'pg_net indisponible ici (%) : les push ne partiront pas de cette base', SQLERRM;
END $$;

-- ─── 1. Les appareils ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.appareils_push (
  jeton        TEXT PRIMARY KEY CHECK (length(jeton) BETWEEN 20 AND 4096),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  plateforme   TEXT NOT NULL CHECK (plateforme IN ('android', 'ios')),
  langue       TEXT NOT NULL DEFAULT 'fr' CHECK (langue ~ '^[a-z]{2}$'),
  decalage_min INTEGER NOT NULL DEFAULT 0 CHECK (decalage_min BETWEEN -840 AND 840),
  preferences  JSONB NOT NULL DEFAULT '{}'::jsonb CHECK (pg_column_size(preferences) < 2048),
  version_app  TEXT CHECK (version_app IS NULL OR length(version_app) <= 60),
  maj_le       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS appareils_push_personne ON public.appareils_push (user_id);
ALTER TABLE public.appareils_push ENABLE ROW LEVEL SECURITY;
-- Aucune règle pour anon ni authenticated : tout passe par les deux fonctions ci-dessous.
REVOKE ALL ON public.appareils_push FROM anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.appareils_push TO service_role;

-- Un jeton désigne une installation de l'app : qui le présente en devient le titulaire
-- (déconnexion puis connexion d'un autre compte sur le même téléphone).
CREATE OR REPLACE FUNCTION public.enregistrer_appareil_push(
  p_jeton TEXT, p_plateforme TEXT, p_langue TEXT DEFAULT 'fr', p_decalage_min INTEGER DEFAULT 0,
  p_preferences JSONB DEFAULT '{}'::jsonb, p_version TEXT DEFAULT NULL)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_moi UUID := auth.uid();
BEGIN
  IF v_moi IS NULL THEN RAISE EXCEPTION 'session_requise'; END IF;
  INSERT INTO appareils_push (jeton, user_id, plateforme, langue, decalage_min, preferences, version_app, maj_le)
  VALUES (p_jeton, v_moi, p_plateforme, lower(coalesce(nullif(p_langue, ''), 'fr')),
          coalesce(p_decalage_min, 0), coalesce(p_preferences, '{}'::jsonb), p_version, now())
  ON CONFLICT (jeton) DO UPDATE
    SET user_id = EXCLUDED.user_id, plateforme = EXCLUDED.plateforme, langue = EXCLUDED.langue,
        decalage_min = EXCLUDED.decalage_min, preferences = EXCLUDED.preferences,
        version_app = EXCLUDED.version_app, maj_le = now();
END;
$$;
REVOKE ALL ON FUNCTION public.enregistrer_appareil_push(TEXT, TEXT, TEXT, INTEGER, JSONB, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.enregistrer_appareil_push(TEXT, TEXT, TEXT, INTEGER, JSONB, TEXT) TO authenticated;

-- À la déconnexion : ce téléphone ne reçoit plus rien pour ce compte.
CREATE OR REPLACE FUNCTION public.oublier_appareil_push(p_jeton TEXT)
RETURNS VOID LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  DELETE FROM appareils_push WHERE jeton = p_jeton AND user_id = auth.uid();
$$;
REVOKE ALL ON FUNCTION public.oublier_appareil_push(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.oublier_appareil_push(TEXT) TO authenticated;

-- ─── 2. Qui a écrit la notification, et quand elle est partie ───────────────────────
ALTER TABLE public.user_notifications
  ADD COLUMN IF NOT EXISTS par_le_serveur BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS pousse_le      TIMESTAMPTZ;

-- SECURITY INVOKER (par défaut) : current_user est le rôle de l'appelant — `authenticated`
-- ou `anon` pour un client, le propriétaire d'une fonction SECURITY DEFINER sinon. Un
-- client ne peut ni se dire « serveur », ni marquer une notification comme partie.
CREATE OR REPLACE FUNCTION public.notification_origine()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.par_le_serveur := current_user NOT IN ('authenticated', 'anon');
    NEW.pousse_le := NULL;
  ELSIF current_user IN ('authenticated', 'anon') THEN
    NEW.par_le_serveur := OLD.par_le_serveur;
    NEW.pousse_le := OLD.pousse_le;
  END IF;
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS push_origine ON public.user_notifications;
CREATE TRIGGER push_origine BEFORE INSERT OR UPDATE ON public.user_notifications
  FOR EACH ROW EXECUTE FUNCTION public.notification_origine();

-- ─── 3. L'envoi : la base appelle `envoyer-push` ────────────────────────────────────
INSERT INTO public.app_config (cle, valeur)
VALUES ('push', '{"url": "https://fvnybncauhbpsnikzeeq.supabase.co/functions/v1/envoyer-push", "actif": true}'::jsonb)
ON CONFLICT (cle) DO NOTHING;

CREATE OR REPLACE FUNCTION public.demander_le_push()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE v_reglage JSONB;
BEGIN
  SELECT valeur INTO v_reglage FROM app_config WHERE cle = 'push';
  IF v_reglage IS NULL OR coalesce((v_reglage ->> 'actif')::boolean, true) IS FALSE
     OR v_reglage ->> 'url' IS NULL OR to_regnamespace('net') IS NULL THEN
    RETURN NEW;
  END IF;
  -- Dynamique : la fonction se crée même là où pg_net n'existe pas.
  EXECUTE 'SELECT net.http_post(url := $1, body := $2, headers := $3)'
    USING v_reglage ->> 'url', jsonb_build_object('notification_id', NEW.id),
          '{"Content-Type": "application/json"}'::jsonb;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Jamais au prix de la notification : elle reste dans la boîte.
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS push_envoi ON public.user_notifications;
CREATE TRIGGER push_envoi AFTER INSERT ON public.user_notifications
  FOR EACH ROW WHEN (NEW.par_le_serveur) EXECUTE FUNCTION public.demander_le_push();

-- La fonction réserve une notification avant de l'envoyer : un second appel (rejeu, appel
-- extérieur) ne renvoie rien. Seul service_role l'appelle.
CREATE OR REPLACE FUNCTION public.reserver_le_push(p_notification UUID)
RETURNS SETOF public.user_notifications LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE user_notifications SET pousse_le = now()
   WHERE id = p_notification AND par_le_serveur AND pousse_le IS NULL
     AND created_at > now() - INTERVAL '1 day'
  RETURNING *;
$$;
REVOKE ALL ON FUNCTION public.reserver_le_push(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.reserver_le_push(UUID) TO service_role;

-- ─── 4. L'activité d'une cave partagée ──────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.signaler_ajout_en_cave()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_acteur  UUID := coalesce(auth.uid(), NEW.added_by);
  v_nombre  INTEGER;
  v_cave    TEXT;
  v_nom     TEXT;
  v_membre  UUID;
  v_existe  UUID;
BEGIN
  IF NEW.cellar_id IS NULL OR v_acteur IS NULL THEN RETURN NEW; END IF;
  v_nombre := CASE WHEN TG_OP = 'INSERT' THEN NEW.quantity
                   ELSE NEW.quantity - coalesce(OLD.quantity, 0) END;
  IF v_nombre IS NULL OR v_nombre <= 0 THEN RETURN NEW; END IF;

  SELECT coalesce(nullif(btrim(nickname), ''), name) INTO v_cave FROM cellars WHERE id = NEW.cellar_id;
  SELECT coalesce(nullif(btrim(display_name), ''), 'Un membre') INTO v_nom FROM profiles WHERE id = v_acteur;

  FOR v_membre IN
    SELECT m.user_id FROM cellar_members m WHERE m.cellar_id = NEW.cellar_id AND m.user_id <> v_acteur
    UNION
    SELECT c.owner_id FROM cellars c WHERE c.id = NEW.cellar_id AND c.owner_id IS NOT NULL AND c.owner_id <> v_acteur
  LOOP
    -- Une notification encore ouverte depuis moins d'une demi-heure : on la complète.
    SELECT n.id INTO v_existe FROM user_notifications n
     WHERE n.user_id = v_membre AND n.actor_id = v_acteur AND n.type = 'activite_cave'
       AND n.data ->> 'cellar_id' = NEW.cellar_id::text
       AND NOT coalesce(n.is_read, false)
       AND n.created_at > now() - INTERVAL '30 minutes'
     ORDER BY n.created_at DESC LIMIT 1;
    IF v_existe IS NOT NULL THEN
      UPDATE user_notifications
         SET data = jsonb_set(data, '{nombre}', to_jsonb(coalesce((data ->> 'nombre')::int, 0) + v_nombre)),
             body = v_nom || ' a ajouté ' || (coalesce((data ->> 'nombre')::int, 0) + v_nombre)
                    || ' bouteilles à « ' || coalesce(v_cave, 'votre cave') || ' ».'
       WHERE id = v_existe;
    ELSE
      INSERT INTO user_notifications (user_id, actor_id, type, title, body, data)
      VALUES (v_membre, v_acteur, 'activite_cave', 'Votre cave partagée',
              v_nom || ' a ajouté ' || v_nombre || CASE WHEN v_nombre > 1 THEN ' bouteilles' ELSE ' bouteille' END
                || ' à « ' || coalesce(v_cave, 'votre cave') || ' ».',
              jsonb_build_object('cellar_id', NEW.cellar_id, 'cellar_name', coalesce(v_cave, ''),
                                 'actor_name', v_nom, 'nombre', v_nombre, 'route', '/cellar'));
    END IF;
  END LOOP;
  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  -- Une bouteille s'enregistre toujours, même si l'avis ne part pas.
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS activite_cave_ajout ON public.bottles;
CREATE TRIGGER activite_cave_ajout AFTER INSERT ON public.bottles
  FOR EACH ROW EXECUTE FUNCTION public.signaler_ajout_en_cave();
DROP TRIGGER IF EXISTS activite_cave_quantite ON public.bottles;
CREATE TRIGGER activite_cave_quantite AFTER UPDATE OF quantity ON public.bottles
  FOR EACH ROW WHEN (NEW.quantity > OLD.quantity) EXECUTE FUNCTION public.signaler_ajout_en_cave();
