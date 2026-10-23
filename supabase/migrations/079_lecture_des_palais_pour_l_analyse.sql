-- 079 · Le rôle d'analyse lit aussi les dégustations et les palais (22/10, À DÉCIDER).
--
-- Demande de Flavien (22/10) : « regarde leurs profils et comment ils ont évolué : c'est ce
-- qu'on attend ? Essaye de voir toutes leurs dégustations à chacun et la tête de leur
-- profil. » Le rôle `chatmelier_feedback_ro` (033, 043, 047 : lecture seule, utilisé par
-- `tool/feedback.sh`, mot de passe dans ~/.chatmelier/feedback.env, hors du dépôt) lit les
-- journaux, les coûts et les impressions ; pas les dégustations ni les palais. Sans eux,
-- impossible de juger si le palais apprend ce qu'il doit apprendre.
--
-- C'EST UN CHOIX DE CONFIDENTIALITÉ : les notes de dégustation des testeurs deviennent
-- lisibles par ce rôle (donc par Claude, qui s'en sert pour l'analyse, jamais pour autre
-- chose). Lecture seule ; rien n'est modifiable. Se retire d'une ligne (en bas).
--
-- Vérification (avec le rôle d'analyse) :
--   SELECT count(*) FROM public.tasting_log;  SELECT count(*) FROM public.palais_utilisateur;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chatmelier_feedback_ro') THEN
    RAISE NOTICE 'Pas de rôle chatmelier_feedback_ro ici : rien à faire.';
    RETURN;
  END IF;
  GRANT SELECT ON public.tasting_log, public.palais_utilisateur, public.wines TO chatmelier_feedback_ro;
  DROP POLICY IF EXISTS tasting_log_analyse ON public.tasting_log;
  CREATE POLICY tasting_log_analyse ON public.tasting_log FOR SELECT TO chatmelier_feedback_ro USING (true);
  DROP POLICY IF EXISTS palais_utilisateur_analyse ON public.palais_utilisateur;
  CREATE POLICY palais_utilisateur_analyse ON public.palais_utilisateur FOR SELECT TO chatmelier_feedback_ro USING (true);
  DROP POLICY IF EXISTS wines_analyse ON public.wines;
  CREATE POLICY wines_analyse ON public.wines FOR SELECT TO chatmelier_feedback_ro USING (true);
END $$;

-- Pour retirer :
--   REVOKE SELECT ON public.tasting_log, public.palais_utilisateur, public.wines FROM chatmelier_feedback_ro;
--   DROP POLICY tasting_log_analyse ON public.tasting_log;
--   DROP POLICY palais_utilisateur_analyse ON public.palais_utilisateur;
--   DROP POLICY wines_analyse ON public.wines;
