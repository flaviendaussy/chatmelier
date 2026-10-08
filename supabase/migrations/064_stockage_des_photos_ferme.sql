-- 064 — Les photos ne s'écrivent que chez soi (sécurité, trouvé le 08/10)
--
-- Lu en production le 08/10 (catalogue, rôle en lecture seule) : le bucket public
-- `labels` (photos de bouteilles et d'étiquettes, avatars) avait la règle « Public Access
-- Labels » pour TOUTES les opérations et TOUS les rôles, y compris `anon`. Avec la seule
-- clé publique de l'app, n'importe qui pouvait déposer un fichier, remplacer ou effacer
-- les photos de tout le monde. Deux autres règles (« Authenticated Delete/Update Labels »)
-- donnaient la même chose à tout compte connecté, et le bucket `avatars` laissait tout
-- compte remplacer l'avatar d'un autre.
--
-- Désormais, chacun n'écrit, ne remplace et n'efface que dans son dossier :
--   - `labels/<son identifiant>/…`  (photos de bouteilles, scan et file hors ligne) ;
--   - `labels/avatars/avatar_<son identifiant>_…`  (son avatar) ;
--   - `avatars/<son identifiant>/…`.
-- La lecture ne change pas : les photos restent publiques, l'app les affiche par leur
-- adresse. Les fonctions serveur (clé de service) ne sont pas concernées.
--
-- Rejouable.

DROP POLICY IF EXISTS "Public Access Labels" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Delete Labels" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Update Labels" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload Labels" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload labels" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Update Avatars" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload Avatars" ON storage.objects;

-- Un fichier de `labels` est à quelqu'un par son chemin.
CREATE OR REPLACE FUNCTION public.photo_a_moi(p_bucket TEXT, p_nom TEXT)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
AS $$
  SELECT auth.uid() IS NOT NULL AND (
    (p_bucket IN ('labels', 'avatars') AND (storage.foldername(p_nom))[1] = auth.uid()::text)
    OR (p_bucket = 'labels' AND p_nom LIKE 'avatars/avatar\_' || auth.uid()::text || '\_%')
  );
$$;

DROP POLICY IF EXISTS photos_depot_chez_soi ON storage.objects;
CREATE POLICY photos_depot_chez_soi ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id IN ('labels', 'avatars') AND public.photo_a_moi(bucket_id, name));

DROP POLICY IF EXISTS photos_remplacement_chez_soi ON storage.objects;
CREATE POLICY photos_remplacement_chez_soi ON storage.objects
  FOR UPDATE TO authenticated
  USING (bucket_id IN ('labels', 'avatars') AND public.photo_a_moi(bucket_id, name))
  WITH CHECK (bucket_id IN ('labels', 'avatars') AND public.photo_a_moi(bucket_id, name));

DROP POLICY IF EXISTS photos_effacement_chez_soi ON storage.objects;
CREATE POLICY photos_effacement_chez_soi ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id IN ('labels', 'avatars') AND public.photo_a_moi(bucket_id, name));

-- Retour arrière (à ne faire que pour comprendre une panne : il rouvre la faille) :
--   DROP POLICY photos_depot_chez_soi, photos_remplacement_chez_soi, photos_effacement_chez_soi ON storage.objects;
--   CREATE POLICY "Authenticated users can upload labels" ON storage.objects
--     FOR INSERT TO authenticated WITH CHECK (bucket_id = 'labels');

-- Vérification (SQL Editor) :
--   SELECT polname, polcmd FROM pg_policy
--    WHERE polrelid = 'storage.objects'::regclass ORDER BY 1;
--   → plus de « Public Access Labels » ni de « Authenticated Delete/Update Labels » ;
--     photos_depot_chez_soi (a), photos_remplacement_chez_soi (w), photos_effacement_chez_soi (d).
-- Puis, dans l'app : scanner une étiquette (la photo s'enregistre), changer d'avatar.
