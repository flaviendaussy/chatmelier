-- 058 — Les modèles d'IA se règlent dans app_config, plus dans le code (V2.3 · K8)
--
-- Les fonctions ne nomment plus aucune version de Gemini. Leur réglage par défaut est une
-- famille (« flash », « flash-lite »), résolue au plus récent modèle stable que Google
-- publie ; un modèle retiré cède la place au plus récent de sa famille ; un niveau de
-- réflexion refusé monte d'un cran. Gemini 3.9, 4.0… n'exigeront aucune modification du code.
--
-- Pour que rien ne change sans décision, cette migration fixe ici les modèles d'aujourd'hui,
-- tâche par tâche (le plus récent Flash-Lite, 3.5, coûte plus cher que le 3.1 en service).
-- Ensuite, le banc d'essai (tool/banc_ia/banc.py) essaie d'office les modèles récents et
-- écrit la ligne SQL qui adopte le meilleur. Un réglage déjà présent est gardé : la migration
-- ne fait que compléter.
--
-- Rejouable.

INSERT INTO public.app_config (cle, valeur)
VALUES ('modeles_ia', '{
  "scan_carte":                 {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "scan_etiquette_lecture":     {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "scan_etiquette_description": {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "question_carte":             {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "chat":                       {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "valeurs_marche":             {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "recit":                      {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "synthese_table":             {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "meuble":                     {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "enrichir_fiche":             {"modele": "gemini-3.8-flash",      "reflexion": "low"},
  "notes_degustation":          {"modele": "gemini-3.1-flash-lite", "reflexion": "minimal"},
  "import_cave":                {"modele": "gemini-3.1-flash-lite", "reflexion": "minimal"},
  "fiche_texte":                {"modele": "gemini-3.1-flash-lite", "reflexion": "minimal"},
  "vin_depuis_texte":           {"modele": "gemini-3.1-flash-lite", "reflexion": "minimal"}
}'::jsonb)
ON CONFLICT (cle) DO UPDATE
  -- À droite, le réglage existant : il l'emporte sur ces valeurs pour une même tâche.
  SET valeur = EXCLUDED.valeur || public.app_config.valeur,
      maj_le = now();

-- Vérification (attendu : quatorze tâches, chacune avec son modèle et sa réflexion) :
SELECT t.key AS tache, t.value ->> 'modele' AS modele, t.value ->> 'reflexion' AS reflexion
  FROM public.app_config c, jsonb_each(c.valeur) AS t
 WHERE c.cle = 'modeles_ia'
 ORDER BY 1;
