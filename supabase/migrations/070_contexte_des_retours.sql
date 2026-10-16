-- 070 · Le contexte d'un retour dans la console (V2.5 · S3).
--
-- Le 16/10, un retour de Flavien est arrivé sans sa capture (pas de réseau) et sans rien
-- pour dire de quel écran il venait. Depuis la 83, chaque retour emporte dans `metadata`
-- son contexte : l'écran, les derniers pas (écrans, feuilles, dialogues), l'état du
-- réseau, la langue, la taille du texte, les derniers avertissements. Cette fonction le
-- rend à la console, avec les journaux de la même personne dans les trois minutes qui
-- précèdent le retour — ce qu'elle faisait, ce qui a échoué.
--
-- Réservée à l'administrateur, comme les autres fonctions `admin_*` (060).
--
-- Vérification :
--   SELECT has_function_privilege('authenticated', 'public.admin_contexte_du_retour(uuid)', 'execute');

CREATE OR REPLACE FUNCTION public.admin_contexte_du_retour(p_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_ligne public.app_diagnostic_logs%ROWTYPE;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces données demandent un compte administrateur.';
  END IF;

  SELECT * INTO v_ligne FROM public.app_diagnostic_logs WHERE id = p_id AND tag = 'USER_FEEDBACK';
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN jsonb_build_object(
    'contexte', coalesce(v_ligne.metadata -> 'contexte', '{}'::jsonb),
    'envoye_le', v_ligne.metadata ->> 'envoye_le',
    'capture', v_ligne.metadata ->> 'capture',
    -- Sans personne connue (retour d'un invité web), pas de journaux : ceux d'autres
    -- anonymes se mêleraient aux siens.
    'journaux', CASE WHEN v_ligne.user_id IS NULL THEN '[]'::jsonb ELSE coalesce((
      SELECT jsonb_agg(jsonb_build_object(
               'quand', public.instant_du_journal(l.created_at, l.metadata),
               'niveau', l.level,
               'tag', l.tag,
               'message', left(l.message, 200))
             ORDER BY l.created_at)
        FROM public.app_diagnostic_logs l
       WHERE l.user_id = v_ligne.user_id
         AND l.id <> v_ligne.id
         AND l.tag <> 'USER_FEEDBACK'
         AND l.created_at BETWEEN v_ligne.created_at - INTERVAL '3 minutes'
                              AND v_ligne.created_at + INTERVAL '30 seconds'), '[]'::jsonb) END
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_contexte_du_retour(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_contexte_du_retour(UUID) TO authenticated;
