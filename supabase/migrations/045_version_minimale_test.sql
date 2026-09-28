-- =============================================================================
-- 045 — La version minimale, pendant la phase de test
-- =============================================================================
-- ⚠️  OUVERTURE DE PHASE DE TEST — À REFERMER AVANT LA PRODUCTION
--     (voir PROD_MIGRATION.md, section « Ouvertures de test à refermer »).
--
-- CONSTAT (28/09). jld est resté en 1.2.0 : chaque scan y fait d'abord dix-huit appels
-- refusés avec l'ancienne clé Gemini, et ses retours décrivent une app qui n'existe plus.
-- Pendant les tests, tout le monde doit tester la même version.
--
-- L'app lit `app_config.version_minimale_test` au démarrage (table créée par la 044,
-- lisible sans compte). Si son numéro de build est plus petit que `build`, un écran
-- bloquant renvoie vers le Play Store, en disant que c'est propre à la phase de test.
-- Hors ligne, ou sur le web (toujours à jour), rien n'est bloqué.
--
-- `build` vaut 0 : RIEN n'est exigé tant qu'on ne l'a pas relevé. Après publication d'une
-- version sur le Play Store :
--   UPDATE public.app_config
--      SET valeur = jsonb_set(valeur, '{build}', '71'), maj_le = now()
--    WHERE cle = 'version_minimale_test';
-- =============================================================================

INSERT INTO public.app_config (cle, valeur)
VALUES (
  'version_minimale_test',
  jsonb_build_object(
    'build', 0,
    'lien', 'https://play.google.com/store/apps/details?id=com.chatmelier.chatmelier',
    'message', 'Pendant la phase de test, tout le monde utilise la même version : '
               'installez la dernière depuis le Play Store.'
  )
)
ON CONFLICT (cle) DO NOTHING;

-- Retour arrière (production) : ne plus bloquer, simplement inviter.
--   DELETE FROM public.app_config WHERE cle = 'version_minimale_test';
--   -- et retirer GardeDeVersion de lib/app.dart.
--
-- Vérification :
--   SELECT valeur FROM public.app_config WHERE cle = 'version_minimale_test';
