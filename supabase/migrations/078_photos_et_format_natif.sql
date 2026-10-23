-- 078 · Deux corrections vues le 22/10 au soir (Vagabond, Caro et Flavien).
--
-- 1. LES PHOTOS. La 074 a retiré toute règle de lecture sur les buckets `labels` et
--    `avatars` (elles laissaient lister les fichiers de tout le monde). Or l'app dépose ses
--    photos en « upsert » : l'API de stockage fait INSERT … ON CONFLICT DO UPDATE, ce qui
--    demande de pouvoir LIRE son propre fichier. Depuis, chaque photo est refusée (« new row
--    violates row-level security policy », 14 fois les 21-22/10) : photos d'étiquette des
--    dégustations, des bouteilles ajoutées en cave, avatars. Une règle de lecture limitée à
--    SES fichiers rétablit le dépôt pour toutes les versions installées, sans rouvrir le
--    listage des fichiers des autres. Les photos restent affichées par leur URL publique.
--
-- 2. LE FORMAT NATIF. `ad_impressions` et `ad_revenus` n'acceptaient que rewarded, app_open,
--    interstitial et banner : la première carte « Annonce » (version 87) est refusée, et
--    bloque la file d'envoi des mesures de pub du téléphone (EnvoiParLots renvoie le lot
--    entier). Ajout de « native ».
--
-- Sans danger, à appliquer tout de suite. Vérification :
--   SELECT policyname FROM pg_policies WHERE schemaname = 'storage' AND policyname = 'photos_lecture_chez_soi';
--   SELECT pg_get_constraintdef(oid) FROM pg_constraint WHERE conname = 'ad_impressions_ad_format_check';

-- ─── 1. Lire ses propres photos ─────────────────────────────────────────────────────
DROP POLICY IF EXISTS photos_lecture_chez_soi ON storage.objects;
CREATE POLICY photos_lecture_chez_soi ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id IN ('labels', 'avatars') AND public.photo_a_moi(bucket_id, name));

-- ─── 2. Le format natif ─────────────────────────────────────────────────────────────
ALTER TABLE public.ad_impressions DROP CONSTRAINT IF EXISTS ad_impressions_ad_format_check;
ALTER TABLE public.ad_impressions ADD CONSTRAINT ad_impressions_ad_format_check
  CHECK (ad_format IN ('rewarded', 'app_open', 'interstitial', 'banner', 'native'));
ALTER TABLE public.ad_revenus DROP CONSTRAINT IF EXISTS ad_revenus_ad_format_check;
ALTER TABLE public.ad_revenus ADD CONSTRAINT ad_revenus_ad_format_check
  CHECK (ad_format IN ('rewarded', 'app_open', 'interstitial', 'banner', 'native'));
