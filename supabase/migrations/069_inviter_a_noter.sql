-- 069 · Inviter un ami à noter, sur son propre téléphone, le vin qu'on goûte ensemble
-- (V2.4 · R4, retour #59).
--
-- Caro, 07/10 : « comme Flavien a l'app, ça pourrait lui envoyer une notif pour qu'il note
-- en même temps sur son tel ». Au lieu de répondre pour lui (066, « à accepter »), on lui
-- demande de noter lui-même : il reçoit une notification « invitation_a_noter », qui ouvre
-- « Noter un vin bu dehors » avec le vin et le convive. Rien n'entre dans son journal tant
-- qu'il n'a pas noté.
--
-- Entre amis ou membres d'une même cave seulement (comme 066) ; trente invitations par
-- jour au plus ; une seule par ami et par vin dans le quart d'heure (un double geste ne
-- l'avertit pas deux fois). L'invitation ne porte que le vin, et le lieu s'il est connu.
--
-- Vérification :
--   SELECT has_function_privilege('authenticated', 'public.inviter_a_noter(uuid, jsonb, text)', 'execute');

CREATE OR REPLACE FUNCTION public.inviter_a_noter(
  p_ami  UUID,
  p_vin  JSONB,
  p_lieu TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_moi UUID := auth.uid();
  v_vin JSONB;
BEGIN
  IF v_moi IS NULL THEN
    RAISE EXCEPTION 'session_requise';
  END IF;
  IF p_ami IS NULL OR p_ami = v_moi THEN
    RAISE EXCEPTION 'destinataire_invalide';
  END IF;
  IF jsonb_typeof(p_vin) IS DISTINCT FROM 'object'
     OR length(coalesce(btrim(p_vin ->> 'nom'), '')) NOT BETWEEN 1 AND 200
     OR length(p_vin::text) > 2000 THEN
    RAISE EXCEPTION 'vin_invalide';
  END IF;
  IF NOT EXISTS (
       SELECT 1 FROM public.friendships f
        WHERE f.status = 'accepted'
          AND ((f.user_id = v_moi AND f.friend_id = p_ami) OR (f.user_id = p_ami AND f.friend_id = v_moi)))
     AND NOT EXISTS (
       SELECT 1 FROM public.cellar_members a
         JOIN public.cellar_members b ON b.cellar_id = a.cellar_id
        WHERE a.user_id = v_moi AND b.user_id = p_ami) THEN
    RAISE EXCEPTION 'pas_ami';
  END IF;
  IF (SELECT count(*) FROM public.user_notifications n
       WHERE n.actor_id = v_moi AND n.type = 'invitation_a_noter'
         AND n.created_at > now() - INTERVAL '1 day') >= 30 THEN
    RAISE EXCEPTION 'trop_d_invitations';
  END IF;

  -- Seulement ce que l'invitation montre : le vin, débarrassé de tout le reste.
  v_vin := jsonb_strip_nulls(jsonb_build_object(
    'nom',        btrim(p_vin ->> 'nom'),
    'producteur', nullif(btrim(p_vin ->> 'producteur'), ''),
    'millesime',  CASE WHEN jsonb_typeof(p_vin -> 'millesime') = 'number' THEN p_vin -> 'millesime' END,
    'couleur',    nullif(btrim(p_vin ->> 'couleur'), ''),
    'region',     nullif(btrim(p_vin ->> 'region'), ''),
    'pays',       nullif(btrim(p_vin ->> 'pays'), '')
  ));

  IF EXISTS (
       SELECT 1 FROM public.user_notifications n
        WHERE n.actor_id = v_moi AND n.user_id = p_ami AND n.type = 'invitation_a_noter'
          AND n.data -> 'vin' ->> 'nom' = v_vin ->> 'nom'
          AND n.created_at > now() - INTERVAL '15 minutes') THEN
    RETURN false;
  END IF;

  -- Le titre et le texte rangés ne servent qu'aux versions qui ne connaissent pas ce type :
  -- l'app les rédige à l'affichage, dans la langue du destinataire, depuis `data`.
  INSERT INTO public.user_notifications (user_id, actor_id, type, title, body, data)
  VALUES (p_ami, v_moi, 'invitation_a_noter',
          'Un vin à noter',
          (v_vin ->> 'nom') || ' : notez-le dans Chatmelier.',
          jsonb_build_object('vin', v_vin, 'lieu', nullif(btrim(p_lieu), ''), 'date', now()));
  RETURN true;
END;
$$;

REVOKE ALL ON FUNCTION public.inviter_a_noter(UUID, JSONB, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.inviter_a_noter(UUID, JSONB, TEXT) TO authenticated;
