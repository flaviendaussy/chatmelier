-- Migration 033: rôle de lecture seule pour dépouiller les remontées utilisateurs
--
-- OBJECTIF
-- Permettre de lire les rapports « secouer pour commenter » sans donner accès au reste
-- de la base. Aujourd'hui la seule façon de les consulter est la console Supabase, ce qui
-- oblige Flavien à faire l'aller-retour à chaque fois.
--
-- PRINCIPE : le moindre privilège, appliqué deux fois
--   1. Au niveau des LIGNES  : la politique RLS ne laisse voir que `tag = 'USER_FEEDBACK'`.
--   2. Au niveau des COLONNES : `user_id` n'est pas accordé. Les remontées sont du contenu
--      utilisateur ; les lire ne devrait pas dire QUI les a écrites. `device_id` reste
--      accessible, pseudonyme, pour regrouper plusieurs rapports d'une même personne.
--
-- Si ces identifiants fuitaient, l'exposition se limiterait à des commentaires déjà
-- destinés à l'équipe — pas aux caves, aux dégustations ni aux adresses e-mail.
--
-- ⚠️  ÉTAPE 1 — À FAIRE À LA MAIN AVANT CETTE MIGRATION
-- Le mot de passe ne doit apparaître nulle part dans ce dépôt, qui est PUBLIC. Créez le
-- rôle depuis le SQL Editor, avec un mot de passe que vous générez vous-même :
--
--     CREATE ROLE chatmelier_feedback_ro LOGIN PASSWORD 'celui-que-vous-générez';
--
-- Puis exécutez cette migration, qui ne contient que des droits.

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chatmelier_feedback_ro') THEN
    RAISE EXCEPTION
      'Le rôle chatmelier_feedback_ro n''existe pas. Créez-le d''abord (voir l''en-tête).';
  END IF;
END $$;

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Accès minimal : se connecter, voir le schéma, rien de plus
-- ─────────────────────────────────────────────────────────────────────────────

GRANT CONNECT ON DATABASE postgres TO chatmelier_feedback_ro;
GRANT USAGE   ON SCHEMA public     TO chatmelier_feedback_ro;

-- Aucun droit par défaut sur les futures tables : ce rôle ne doit jamais gagner
-- d'accès en silence quand une table est ajoutée.
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE ALL ON TABLES FROM chatmelier_feedback_ro;

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Lecture, colonne par colonne
-- ─────────────────────────────────────────────────────────────────────────────
--
-- `user_id`, `error_details` et `metadata` sont délibérément absents : le premier
-- identifie l'auteur, les deux autres peuvent contenir de l'état applicatif arbitraire.

GRANT SELECT (id, created_at, device_id, platform, app_version, tag, level, message)
  ON public.app_diagnostic_logs
  TO chatmelier_feedback_ro;

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Et ligne par ligne
-- ─────────────────────────────────────────────────────────────────────────────
--
-- La RLS est active sur cette table depuis la migration 030. Les politiques s'appliquent
-- par rôle : celle-ci est la seule qui concerne `chatmelier_feedback_ro`, il ne verra
-- donc que ce qu'elle autorise — pas les 20 000 lignes de journal technique.

DROP POLICY IF EXISTS feedback_ro_select ON public.app_diagnostic_logs;
CREATE POLICY feedback_ro_select
  ON public.app_diagnostic_logs
  FOR SELECT
  TO chatmelier_feedback_ro
  USING (tag = 'USER_FEEDBACK');

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Vérification
-- ─────────────────────────────────────────────────────────────────────────────
--
--   SET ROLE chatmelier_feedback_ro;
--   SELECT count(*) FROM public.app_diagnostic_logs;              -- que les remontées
--   SELECT count(*) FROM public.bottles;                          -- doit ÉCHOUER
--   SELECT user_id FROM public.app_diagnostic_logs LIMIT 1;       -- doit ÉCHOUER
--   RESET ROLE;
--
-- Pour révoquer l'accès plus tard, une seule commande suffit :
--   DROP ROLE chatmelier_feedback_ro;
