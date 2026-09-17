-- =============================================================================
-- 036 — Les captures de retour quittent le bucket public
-- =============================================================================
-- CONSTAT : les captures jointes aux rapports « secouer pour commenter » vivaient dans
-- `labels`, un bucket PUBLIC. Or une capture d'écran n'est pas une photo d'étiquette :
-- elle montre tout ce que la personne avait sous les yeux — sa cave, ses notes, parfois
-- un message. Un nom de fichier aléatoire rend l'URL indevinable, pas privée : qui l'a
-- une fois l'a pour toujours, et elle reste servie après la suppression de la ligne.
--
-- Les photos d'étiquette et les avatars restent dans `labels` : ils sont montrés aux
-- membres d'une cave et aux amis, donc publics par destination. Le problème n'était pas
-- le bucket, c'était d'y avoir mis autre chose.
--
-- CHEMIN : `<user_id>/<uuid>.png`. Dans un bucket public c'eût été une fuite — l'URL
-- aurait désigné son auteur et permis de regrouper ses envois (c'est pourquoi le chemin
-- avait justement été anonymisé). Dans un bucket privé, l'inverse est vrai : le préfixe
-- par propriétaire est ce qui permet à la RLS de dire « les siennes, et rien d'autre ».
-- =============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES ('feedback', 'feedback', FALSE, 10485760, ARRAY['image/png', 'image/jpeg'])
ON CONFLICT (id) DO UPDATE
  SET public = FALSE,
      file_size_limit = 10485760,
      allowed_mime_types = ARRAY['image/png', 'image/jpeg'];

-- Déposer : uniquement dans son propre dossier.
DROP POLICY IF EXISTS "feedback_insert_own" ON storage.objects;
CREATE POLICY "feedback_insert_own"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'feedback'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Relire : les siennes. C'est ce qui permet à l'app de signer une URL pour la vignette
-- de « Mes retours envoyés » sans qu'aucun secret ne quitte le serveur.
DROP POLICY IF EXISTS "feedback_select_own" ON storage.objects;
CREATE POLICY "feedback_select_own"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'feedback'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Retirer : les siennes. Sans cette politique, supprimer un retour laisserait la capture
-- derrière — un retrait qui ne retire pas ce qui compte le plus.
DROP POLICY IF EXISTS "feedback_delete_own" ON storage.objects;
CREATE POLICY "feedback_delete_own"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'feedback'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Le dépouillement passe par la fonction edge `sign-feedback-capture`, qui vérifie
-- `profiles.is_admin` (migration 029) avant de signer. Aucune politique administrateur
-- n'est posée ici : le service_role la contourne de toute façon, et en écrire une
-- donnerait l'illusion que le privilège est borné par la RLS alors qu'il l'est par la
-- fonction.

-- -----------------------------------------------------------------------------
-- Anciennes captures dans `labels`
-- -----------------------------------------------------------------------------
-- Elles y restent : les URL déjà transmises cesseraient de fonctionner et le
-- dépouillement en cours perdrait ses pièces jointes. Pour les retirer une fois
-- dépouillées, depuis le SQL Editor :
--
--   DELETE FROM storage.objects
--    WHERE bucket_id = 'labels' AND name LIKE 'feedback/%'
--      AND created_at < now() - interval '90 days';
