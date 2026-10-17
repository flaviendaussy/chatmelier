-- 073 · La provenance que personne n'a choisie (17/10).
--
-- En vérifiant le retour de Gandalf sur les cases pré-remplies : la fiche d'une bouteille
-- cochait « Acheté au domaine » d'office, et l'enregistrait pour toute bouteille modifiée
-- sans que personne l'ait dit. La bouteille affichait ensuite « Provenance : 🏰 Acheté au
-- domaine ». L'app ne coche plus rien (livraison 84).
--
-- Un vrai choix du domaine laissait toujours un détail : « Domaine », écrit au toucher de la
-- pastille, ou le lieu déjà tapé. Sans détail, c'est le défaut : la provenance redevient
-- « non dite » (la fiche montre alors le lieu d'achat, ou rien).
--
-- À APPLIQUER AVANT D'INSTALLER LA 84 : à partir d'elle, choisir le domaine n'écrit plus de
-- détail, et un vrai choix ne se distinguerait plus du défaut.
--
-- Avant, pour voir ce qui change :
--   SELECT count(*) FROM public.bottles WHERE source_type = 'estate' AND source_details IS NULL;

UPDATE public.bottles
   SET source_type = NULL
 WHERE source_type = 'estate'
   AND source_details IS NULL;

-- Vérification (0 attendu) :
--   SELECT count(*) FROM public.bottles WHERE source_type = 'estate' AND source_details IS NULL;
