-- =============================================================================
-- 035 — Retirer un retour qu'on a envoyé
-- =============================================================================
-- « Dans l'app, tout doit être supprimable si l'utilisateur le veut. »
--
-- Un rapport de bug part d'un geste impulsif : on secoue son téléphone, on écrit vite,
-- on joint une capture d'écran de ce qu'on avait sous les yeux. Il est normal de vouloir
-- le retirer ensuite — parce qu'on s'est trompé, ou parce que la capture montre plus que
-- prévu.
--
-- PORTÉE : uniquement `tag = 'USER_FEEDBACK'`, c'est-à-dire ce que la personne a
-- délibérément écrit et envoyé. Les journaux techniques (erreurs, démarrages) ne sont pas
-- concernés ici : ils ne sont pas un propos, et les effacer un par un retirerait la preuve
-- d'une panne sans que personne ne l'ait demandé. Pour « effacer tout ce qui me concerne »,
-- le chemin reste la suppression de compte (migration 023), qui les emporte déjà.
-- =============================================================================

DROP POLICY IF EXISTS "delete_own_feedback" ON public.app_diagnostic_logs;
CREATE POLICY "delete_own_feedback"
  ON public.app_diagnostic_logs
  FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id AND tag = 'USER_FEEDBACK');

GRANT DELETE ON public.app_diagnostic_logs TO authenticated;

-- Vérification, connecté :
--   DELETE FROM app_diagnostic_logs WHERE tag = 'ERROR';       -- doit ne rien supprimer
--   DELETE FROM app_diagnostic_logs WHERE tag = 'USER_FEEDBACK'; -- doit supprimer les siens
