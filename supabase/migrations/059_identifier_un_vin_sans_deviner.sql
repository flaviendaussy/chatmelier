-- 059 — Identifier un vin depuis un nom : Flash, sans deviner (V2.4 · R1)
--
-- Le 07/10, « S de Siroua », un vin marocain, est devenu un Côtes du Rhône : l'écran « Noter
-- un vin bu dehors » l'identifiait depuis son nom avec Flash-Lite, sans réflexion ni
-- recherche, et la consigne disait « France par défaut ». Les deux tâches qui identifient un
-- vin depuis un nom (vin_depuis_texte, fiche_texte) passent sur la famille Flash (le plus
-- récent modèle stable, résolu par les fonctions, V2.3 · K8), avec une réflexion basse.
-- 058 les avait fixées sur gemini-3.1-flash-lite : ce réglage l'emporte sur l'existant.
--
-- Rejouable.

INSERT INTO public.app_config (cle, valeur)
VALUES ('modeles_ia', '{
  "vin_depuis_texte": {"modele": "flash", "reflexion": "low"},
  "fiche_texte":      {"modele": "flash", "reflexion": "low"}
}'::jsonb)
ON CONFLICT (cle) DO UPDATE
  -- À droite, ces valeurs : elles l'emportent sur le réglage existant de ces deux tâches.
  SET valeur = public.app_config.valeur || EXCLUDED.valeur,
      maj_le = now();

-- Vérification (attendu : deux lignes, flash / low) :
SELECT t.key AS tache, t.value ->> 'modele' AS modele, t.value ->> 'reflexion' AS reflexion
  FROM public.app_config c, jsonb_each(c.valeur) AS t
 WHERE c.cle = 'modeles_ia' AND t.key IN ('vin_depuis_texte', 'fiche_texte')
 ORDER BY 1;
