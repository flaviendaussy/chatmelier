-- 074 — Sécurité des accès et du partage (lot Q, revue du 18/10)
--
-- Revue complète lue en production (rôle en lecture seule) le 18/10. Cette migration ne
-- touche que le serveur et reste COMPATIBLE AVEC LES VERSIONS INSTALLÉES : elle referme des
-- failles sans retirer aucun chemin dont dépend une app déjà distribuée. Les écritures
-- directes encore ouvertes (amitiés, notifications) ne seront fermées qu'en 076, quand la 85
-- sera la version minimale et passera par les fonctions ajoutées ici.
--
-- Q1  (P0) — Accès aux caves.
--   • cellar_members : la règle d'insertion acceptait toute ligne où user_id = l'appelant,
--     quelles que soient la cave et le rôle (n'importe qui s'ajoutait admin de n'importe
--     quelle cave). Désormais : seuls le propriétaire qui s'inscrit à la création et les
--     admins de la cave insèrent ; rejoindre par invitation ou demande acceptée passe par
--     des fonctions SECURITY DEFINER qui vérifient le droit.
--   • La ligne du propriétaire est protégée : un admin non propriétaire ne peut plus la
--     retirer ni la rétrograder (politiques RLS + update_member_role).
--   • request_friend_cellar_access : exige une amitié acceptée, ne vise que les caves de la
--     cible, et ne renvoie plus l'identifiant de la cave.
--   • is_cellar_member / is_cellar_admin / is_cellar_editor_or_admin : SET search_path figé
--     (fonctions SECURITY DEFINER sans search_path = porte ouverte à une résolution détournée).
--   • Une requête d'audit (lecture) est en commentaire à la fin, à lancer par Flavien.
--
-- Q1b (P1) — Amitiés et notifications.
--   • friendships : une demande pouvait être acceptée par celui qui l'a faite. accepter_amitie
--     n'accepte que si l'appelant est le destinataire (friend_id). demander_amitie crée la
--     demande et sa notification côté serveur. (Fermeture des écritures directes : 076.)
--
-- Q1c (P2) — Journaux, stockage, profils.
--   • app_diagnostic_logs : trois politiques d'insertion « WITH CHECK (true) » se
--     superposaient (anon sans borne). Une seule règle, bornée en taille.
--   • Les règles de lecture des buckets `labels` et `avatars` laissaient LISTER tous les
--     fichiers ; l'affichage se fait par URL publique et n'en a pas besoin : retirées.
--   • handle_new_user : le nom affiché par défaut devient le PRÉNOM seul (le nom Google
--     complet n'atterrit plus dans `profiles`, lisible par tous). Profils existants intacts.
--
-- Q2  (P1) — Colonnes jamais créées en production, que l'app envoie déjà.
--   • wines.user_overrides (013), cellars.wifi_ssid et cellars.radius_meters (014).
--
-- Q3  (P1) — Lien d'invitation : la fonction « accepter par code » est absente en
--   production ; la (re)voici (SECURITY DEFINER, search_path figé).
--
-- Idempotente, rejouable. Aucune donnée n'est détruite.

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q2 — Colonnes manquantes                                                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
ALTER TABLE public.wines   ADD COLUMN IF NOT EXISTS user_overrides JSONB DEFAULT '[]'::jsonb;
ALTER TABLE public.cellars ADD COLUMN IF NOT EXISTS wifi_ssid     TEXT;
ALTER TABLE public.cellars ADD COLUMN IF NOT EXISTS radius_meters INT DEFAULT 300;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1 — search_path figé sur les gardiens d'accès aux caves                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
CREATE OR REPLACE FUNCTION public.is_cellar_member(p_cellar_id uuid, p_user_id uuid DEFAULT auth.uid())
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = p_user_id
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_cellar_admin(p_cellar_id uuid, p_user_id uuid DEFAULT auth.uid())
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = p_user_id AND role = 'admin'
  );
$function$;

CREATE OR REPLACE FUNCTION public.is_cellar_editor_or_admin(p_cellar_id uuid, p_user_id uuid DEFAULT auth.uid())
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM cellar_members
    WHERE cellar_id = p_cellar_id AND user_id = p_user_id AND role IN ('editor', 'admin')
  );
$function$;

-- Le propriétaire d'une cave, sans passer par les politiques (SECURITY DEFINER).
CREATE OR REPLACE FUNCTION public.est_proprietaire_cave(p_cellar_id uuid, p_user_id uuid DEFAULT auth.uid())
 RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $function$
  SELECT EXISTS (SELECT 1 FROM cellars WHERE id = p_cellar_id AND owner_id = p_user_id);
$function$;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1 — RLS de cellar_members : qui insère, qui modifie, qui retire                    ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
ALTER TABLE public.cellar_members ENABLE ROW LEVEL SECURITY;

-- On repart d'un jeu de politiques CONNU : retirer toutes celles en place (leurs noms ont
-- varié au fil des migrations) avant de poser les quatre bonnes. Sans ce balayage, une
-- ancienne règle d'insertion permissive restée sous un autre nom rouvrirait la faille — les
-- politiques permissives s'AJOUTENT en OR. (Même procédé que 030 sur les journaux.)
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = 'cellar_members'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.cellar_members', pol.policyname);
  END LOOP;
END $$;

-- Lecture inchangée : ses propres lignes, ou celles d'une cave dont on est membre.
CREATE POLICY "Users can view cellar members." ON public.cellar_members FOR SELECT USING (
  user_id = auth.uid() OR is_cellar_member(cellar_id, auth.uid())
);

-- Insertion : un admin de la cave, OU le propriétaire qui s'inscrit lui-même à la création.
-- Le reste (rejoindre par invitation ou demande acceptée) passe par les fonctions plus bas.
CREATE POLICY "Admins or owner can insert cellar members." ON public.cellar_members FOR INSERT WITH CHECK (
  is_cellar_admin(cellar_id, auth.uid())
  OR (user_id = auth.uid() AND est_proprietaire_cave(cellar_id, auth.uid()))
);

-- Modification : un admin, mais jamais la ligne du propriétaire s'il n'est pas lui-même.
CREATE POLICY "Admins can update cellar members." ON public.cellar_members FOR UPDATE USING (
  is_cellar_admin(cellar_id, auth.uid())
  AND (auth.uid() = user_id OR NOT est_proprietaire_cave(cellar_id, user_id))
) WITH CHECK (
  is_cellar_admin(cellar_id, auth.uid())
  AND (auth.uid() = user_id OR NOT est_proprietaire_cave(cellar_id, user_id))
);

-- Retrait : on peut toujours se retirer soi-même ; un admin retire les autres, mais jamais
-- le propriétaire.
CREATE POLICY "Members leave, admins remove non-owners." ON public.cellar_members FOR DELETE USING (
  (auth.uid() = user_id OR is_cellar_admin(cellar_id, auth.uid()))
  AND (auth.uid() = user_id OR NOT est_proprietaire_cave(cellar_id, user_id))
);

-- La fonction d'administration des rôles (004) ne protégeait pas le propriétaire d'une
-- rétrogradation par un autre admin. On la durcit (et on lui fige son search_path).
CREATE OR REPLACE FUNCTION public.update_member_role(p_cellar_id uuid, p_user_id uuid, p_new_role text)
 RETURNS json LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $function$
DECLARE v_caller_id UUID := auth.uid();
BEGIN
  IF NOT public.is_cellar_admin(p_cellar_id, v_caller_id) THEN
    RETURN json_build_object('error', 'Only admins can change roles');
  END IF;
  IF p_new_role NOT IN ('viewer', 'editor', 'admin') THEN
    RETURN json_build_object('error', 'Invalid role');
  END IF;
  -- Le rôle du propriétaire ne se change pas (sauf par lui-même, et il reste admin).
  IF public.est_proprietaire_cave(p_cellar_id, p_user_id) AND p_user_id <> v_caller_id THEN
    RETURN json_build_object('error', 'Cannot change the owner''s role');
  END IF;
  IF p_user_id = v_caller_id AND public.est_proprietaire_cave(p_cellar_id, v_caller_id) THEN
    RETURN json_build_object('error', 'Cannot change your own role');
  END IF;
  UPDATE cellar_members SET role = p_new_role WHERE cellar_id = p_cellar_id AND user_id = p_user_id;
  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Member not found');
  END IF;
  RETURN json_build_object('success', true);
END;
$function$;
GRANT EXECUTE ON FUNCTION public.update_member_role(uuid, uuid, text) TO authenticated;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1 — request_friend_cellar_access : entre amis, cave de la cible, sans id rendu     ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
CREATE OR REPLACE FUNCTION public.request_friend_cellar_access(
  p_target_owner_id UUID,
  p_requested_role  TEXT DEFAULT 'viewer',
  p_cellar_id       UUID DEFAULT NULL,
  p_message         TEXT DEFAULT NULL
)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_cellar_id      UUID;
  v_cellar_name    TEXT;
  v_request_id     UUID;
  v_requester_name TEXT;
  v_requester_id   UUID := auth.uid();
BEGIN
  IF v_requester_id IS NULL THEN
    RAISE EXCEPTION 'session_requise';
  END IF;
  IF p_target_owner_id IS NULL OR v_requester_id = p_target_owner_id THEN
    RAISE EXCEPTION 'destinataire_invalide';
  END IF;
  IF p_requested_role NOT IN ('viewer', 'editor') THEN
    RAISE EXCEPTION 'role_invalide';
  END IF;

  -- Entre amis seulement : une amitié acceptée, dans un sens ou l'autre.
  IF NOT EXISTS (
    SELECT 1 FROM friendships f
    WHERE f.status = 'accepted'
      AND ((f.user_id = v_requester_id AND f.friend_id = p_target_owner_id)
        OR (f.user_id = p_target_owner_id AND f.friend_id = v_requester_id))
  ) THEN
    RAISE EXCEPTION 'pas_ami';
  END IF;

  -- La cave visée doit appartenir à la cible : jamais une cave tierce.
  IF p_cellar_id IS NOT NULL THEN
    SELECT id, name INTO v_cellar_id, v_cellar_name
    FROM cellars WHERE id = p_cellar_id AND owner_id = p_target_owner_id;
  END IF;
  IF v_cellar_id IS NULL THEN
    SELECT id, name INTO v_cellar_id, v_cellar_name
    FROM cellars WHERE owner_id = p_target_owner_id
    ORDER BY created_at ASC LIMIT 1;
  END IF;
  IF v_cellar_id IS NULL THEN
    RAISE EXCEPTION 'aucune_cave';
  END IF;

  v_request_id := gen_random_uuid();
  INSERT INTO cellar_access_requests (id, cellar_id, owner_id, requester_id, requested_role, status, message, created_at)
  VALUES (v_request_id, v_cellar_id, p_target_owner_id, v_requester_id, p_requested_role, 'pending', p_message, now())
  ON CONFLICT (cellar_id, requester_id)
  DO UPDATE SET requested_role = EXCLUDED.requested_role, status = 'pending', message = EXCLUDED.message, created_at = now()
  RETURNING id INTO v_request_id;

  SELECT display_name INTO v_requester_name FROM profiles WHERE id = v_requester_id;

  -- La notification va au PROPRIÉTAIRE (sa propre cave) : y mettre l'id est sans fuite.
  INSERT INTO user_notifications (user_id, actor_id, type, title, body, data, is_read, created_at)
  VALUES (
    p_target_owner_id, v_requester_id, 'cellar_request',
    'Demande d''accès à votre cave 🍷',
    COALESCE(v_requester_name, 'Un ami') || ' souhaite accéder à votre cave "' || COALESCE(v_cellar_name, 'Ma Cave')
      || '" en mode ' || CASE WHEN p_requested_role = 'editor' THEN 'Sommelier ✍️' ELSE 'Lecteur 👁️' END || '.',
    jsonb_build_object(
      'request_id', v_request_id,
      'cellar_id', v_cellar_id,
      'cellar_name', v_cellar_name,
      'requester_id', v_requester_id,
      'requester_name', COALESCE(v_requester_name, 'Un ami'),
      'requested_role', p_requested_role,
      'message', p_message
    ),
    false, now()
  );

  -- Au DEMANDEUR, rien qui révèle l'identifiant ni le nom de la cave de la cible.
  RETURN jsonb_build_object('success', true, 'request_id', v_request_id);
END;
$$;
GRANT EXECUTE ON FUNCTION public.request_friend_cellar_access(UUID, TEXT, UUID, TEXT) TO authenticated;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1b — Amitiés : demander et accepter côté serveur                                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
-- Une demande va de l'appelant (user_id) vers p_ami (friend_id).
CREATE OR REPLACE FUNCTION public.demander_amitie(p_ami UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_moi UUID := auth.uid(); v_nom TEXT; v_id UUID;
BEGIN
  IF v_moi IS NULL THEN RAISE EXCEPTION 'session_requise'; END IF;
  IF public.est_anonyme() THEN RAISE EXCEPTION 'anonyme_interdit'; END IF;
  IF p_ami IS NULL OR p_ami = v_moi THEN RAISE EXCEPTION 'destinataire_invalide'; END IF;

  -- Déjà liés, ou une demande déjà en cours dans un sens ou l'autre : ne rien dupliquer.
  IF EXISTS (
    SELECT 1 FROM friendships f
    WHERE ((f.user_id = v_moi AND f.friend_id = p_ami) OR (f.user_id = p_ami AND f.friend_id = v_moi))
      AND f.status IN ('pending', 'accepted')
  ) THEN
    RETURN jsonb_build_object('success', true, 'deja', true);
  END IF;

  INSERT INTO friendships (user_id, friend_id, status) VALUES (v_moi, p_ami, 'pending')
  ON CONFLICT (user_id, friend_id) DO UPDATE SET status = 'pending', updated_at = now()
  RETURNING id INTO v_id;

  SELECT display_name INTO v_nom FROM profiles WHERE id = v_moi;
  INSERT INTO user_notifications (user_id, actor_id, type, title, body, data)
  VALUES (p_ami, v_moi, 'friend_request', 'Nouvelle demande d''ami',
          COALESCE(v_nom, 'Quelqu''un') || ' souhaite vous ajouter en ami.',
          jsonb_build_object('friendship_id', v_id, 'requester_id', v_moi, 'requester_name', COALESCE(v_nom, '')));
  RETURN jsonb_build_object('success', true, 'friendship_id', v_id);
END;
$$;
REVOKE ALL ON FUNCTION public.demander_amitie(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.demander_amitie(UUID) TO authenticated;

-- Seul le destinataire d'une demande peut l'accepter (friend_id = l'appelant).
CREATE OR REPLACE FUNCTION public.accepter_amitie(p_demandeur UUID)
RETURNS JSONB LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE v_moi UUID := auth.uid(); v_nom TEXT; v_maj INT;
BEGIN
  IF v_moi IS NULL THEN RAISE EXCEPTION 'session_requise'; END IF;
  IF p_demandeur IS NULL OR p_demandeur = v_moi THEN RAISE EXCEPTION 'destinataire_invalide'; END IF;

  UPDATE friendships SET status = 'accepted', updated_at = now()
   WHERE user_id = p_demandeur AND friend_id = v_moi AND status = 'pending';
  GET DIAGNOSTICS v_maj = ROW_COUNT;
  IF v_maj = 0 THEN
    RAISE EXCEPTION 'aucune_demande';
  END IF;

  SELECT display_name INTO v_nom FROM profiles WHERE id = v_moi;
  INSERT INTO user_notifications (user_id, actor_id, type, title, body, data)
  VALUES (p_demandeur, v_moi, 'friend_accepted', 'Demande d''ami acceptée',
          COALESCE(v_nom, 'Votre ami') || ' a accepté votre demande.',
          jsonb_build_object('friend_id', v_moi, 'friend_name', COALESCE(v_nom, '')));
  RETURN jsonb_build_object('success', true);
END;
$$;
REVOKE ALL ON FUNCTION public.accepter_amitie(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.accepter_amitie(UUID) TO authenticated;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1c — Journaux : une seule politique d'insertion, bornée                            ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
ALTER TABLE public.app_diagnostic_logs ENABLE ROW LEVEL SECURITY;
-- Balayer TOUTE politique d'insertion (les trois doublons, et toute autre) pour n'en laisser
-- qu'une, bornée.
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'app_diagnostic_logs' AND cmd = 'INSERT'
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.app_diagnostic_logs', pol.policyname);
  END LOOP;
END $$;
CREATE POLICY "insert_diagnostic_logs" ON public.app_diagnostic_logs
  FOR INSERT TO anon, authenticated
  WITH CHECK (
    length(coalesce(tag, ''))   BETWEEN 1 AND 120
    AND length(coalesce(level, '')) BETWEEN 1 AND 20
    AND length(coalesce(message, '')) <= 8000
    AND (error_details IS NULL OR length(error_details) <= 20000)
    AND (platform     IS NULL OR length(platform)     <= 60)
    AND (app_version  IS NULL OR length(app_version)  <= 60)
    AND (device_id    IS NULL OR length(device_id)    <= 256)
    AND (metadata     IS NULL OR length(metadata::text) <= 20000)
  );
-- La lecture (ses propres journaux, et pas pour anon) reste telle que 030 l'a posée.

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1c — Stockage : retirer les règles de lecture qui laissent LISTER labels/avatars   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
-- Les photos restent publiques par leur URL ; une règle SELECT sur storage.objects ne sert
-- qu'à l'API de listage, qui n'a pas à énumérer les fichiers de tout le monde.
DROP POLICY IF EXISTS "Anyone can read labels" ON storage.objects;
DROP POLICY IF EXISTS "Public Access Labels" ON storage.objects;
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND cmd IN ('SELECT', 'ALL')
      AND (coalesce(qual, '') ILIKE '%labels%' OR coalesce(qual, '') ILIKE '%avatars%')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON storage.objects', pol.policyname);
  END LOOP;
END $$;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1c — Profils : le nom affiché par défaut = le PRÉNOM seul                          ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
-- `profiles` est lisible par tous ; le nom Google complet n'a pas à y atterrir. Les profils
-- déjà créés ne sont pas modifiés — c'est le défaut des prochaines inscriptions qui change.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth, extensions
AS $$
DECLARE
  new_cellar_id UUID;
  user_name TEXT;
BEGIN
  -- Un nom choisi explicitement est respecté ; sinon on ne garde que le premier mot du nom
  -- (Google renvoie le nom complet), sinon la partie locale de l'e-mail. Jamais « User ».
  user_name := NULLIF(btrim(COALESCE(
    NEW.raw_user_meta_data->>'display_name',
    split_part(btrim(COALESCE(NEW.raw_user_meta_data->>'name', NEW.raw_user_meta_data->>'full_name', '')), ' ', 1),
    split_part(COALESCE(NEW.email, ''), '@', 1)
  )), '');

  INSERT INTO public.profiles (id, display_name, default_currency)
  VALUES (NEW.id, user_name, 'EUR')
  ON CONFLICT (id) DO UPDATE
    SET display_name = COALESCE(EXCLUDED.display_name, public.profiles.display_name);

  INSERT INTO public.cellars (owner_id, name)
  VALUES (NEW.id, 'Ma Cave')
  RETURNING id INTO new_cellar_id;

  IF new_cellar_id IS NOT NULL THEN
    INSERT INTO public.cellar_members (cellar_id, user_id, role)
    VALUES (new_cellar_id, NEW.id, 'admin')
    ON CONFLICT (cellar_id, user_id) DO NOTHING;
  END IF;

  IF NEW.email IS NOT NULL THEN
    UPDATE public.cellar_invites
    SET invited_user_id = NEW.id
    WHERE LOWER(invited_email) = LOWER(NEW.email)
      AND status = 'pending'
      AND invited_user_id IS NULL;
  END IF;

  RETURN NEW;
EXCEPTION WHEN OTHERS THEN
  RAISE WARNING 'handle_new_user error: %', SQLERRM;
  RETURN NEW;
END;
$$;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q3 — Accepter une invitation de cave par son code                                   ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
CREATE OR REPLACE FUNCTION public.accept_invite_by_code(p_code TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_invite  RECORD;
  v_user_id UUID := auth.uid();
BEGIN
  IF v_user_id IS NULL THEN
    RETURN json_build_object('error', 'session_requise');
  END IF;
  IF p_code IS NULL OR btrim(p_code) = '' THEN
    RETURN json_build_object('error', 'code_invalide');
  END IF;

  SELECT * INTO v_invite FROM cellar_invites
  WHERE invite_code = btrim(p_code) AND status = 'pending';
  IF NOT FOUND THEN
    RETURN json_build_object('error', 'Invalid or expired invite code');
  END IF;

  INSERT INTO cellar_members (cellar_id, user_id, role)
  VALUES (v_invite.cellar_id, v_user_id, v_invite.role)
  ON CONFLICT (cellar_id, user_id) DO UPDATE SET role = EXCLUDED.role;

  UPDATE cellar_invites
  SET status = 'accepted', invited_user_id = v_user_id, responded_at = now()
  WHERE id = v_invite.id;

  RETURN json_build_object('success', true, 'cellar_id', v_invite.cellar_id, 'role', v_invite.role);
END;
$$;
GRANT EXECUTE ON FUNCTION public.accept_invite_by_code(TEXT) TO authenticated;

-- ╔═══════════════════════════════════════════════════════════════════════════════════╗
-- ║ Q1 — Requête d'audit (à lancer par Flavien, en lecture)                             ║
-- ╚═══════════════════════════════════════════════════════════════════════════════════╝
-- Les appartenances qui ne s'expliquent NI par la propriété de la cave, NI par une
-- invitation acceptée, NI par une demande d'accès acceptée. Idéalement : 0 ligne.
--
--   SELECT cm.cellar_id, cm.user_id, cm.role, c.owner_id, p.display_name
--     FROM public.cellar_members cm
--     JOIN public.cellars  c ON c.id = cm.cellar_id
--     LEFT JOIN public.profiles p ON p.id = cm.user_id
--    WHERE cm.user_id <> c.owner_id
--      AND NOT EXISTS (
--            SELECT 1 FROM public.cellar_invites i
--             WHERE i.cellar_id = cm.cellar_id AND i.invited_user_id = cm.user_id AND i.status = 'accepted')
--      AND NOT EXISTS (
--            SELECT 1 FROM public.cellar_access_requests r
--             WHERE r.cellar_id = cm.cellar_id AND r.requester_id = cm.user_id AND r.status = 'accepted')
--    ORDER BY cm.cellar_id, cm.user_id;
