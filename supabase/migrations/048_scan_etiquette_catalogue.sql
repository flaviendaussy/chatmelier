-- 048 — Scan d'étiquette : le catalogue d'abord, la recherche Google sur interrupteur (P4, 29/09)
--
-- La fonction scan-label (à redéployer avec cette migration) lit l'étiquette, puis
-- consulte le catalogue partagé (find_cached_wine) : un vin déjà bien décrit n'est plus
-- redécrit par l'IA. Pour un vin inconnu, elle peut chercher sur le web — environ 3 c€
-- par vin, une seule fois, puisque sa fiche rejoint ensuite le catalogue.
--
-- 1. L'interrupteur, éteint par défaut : à allumer après lecture de l'onglet « Économie ».
INSERT INTO public.app_config (cle, valeur)
VALUES ('scan_etiquette_recherche', 'false'::jsonb)
ON CONFLICT (cle) DO NOTHING;

-- Pour l'allumer :
--   UPDATE public.app_config SET valeur = 'true'::jsonb, maj_le = now()
--   WHERE cle = 'scan_etiquette_recherche';

-- 2. Les notes de critiques et les « sources vérifiées » déjà au catalogue viennent toutes
--    de l'ancienne étape d'enrichissement de scan-label, qui n'avait AUCUN outil de
--    recherche : le modèle les inventait, et la fiche était marquée vérifiée. Aucune n'est
--    affichée aujourd'hui, mais elles ne doivent pas circuler d'un utilisateur à l'autre.
UPDATE public.wines
SET critic_scores = '[]'::jsonb,
    sources_verified = '[]'::jsonb,
    is_verified_online = false
WHERE is_verified_online
   OR coalesce(critic_scores, '[]'::jsonb) <> '[]'::jsonb
   OR coalesce(sources_verified, '[]'::jsonb) <> '[]'::jsonb;

-- Vérification (attendu : l'interrupteur à false, et 0 fiche « vérifiée ») :
--   SELECT cle, valeur FROM public.app_config WHERE cle = 'scan_etiquette_recherche';
--   SELECT count(*) FILTER (WHERE is_verified_online) AS verifiees,
--          count(*) FILTER (WHERE coalesce(critic_scores, '[]'::jsonb) <> '[]'::jsonb) AS avec_critiques
--   FROM public.wines;
