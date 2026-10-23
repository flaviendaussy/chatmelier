-- 080 · Les cépages cherchés sur le web, gardés pour tout le monde (23/10).
--
-- Demande de Flavien (23/10) : « it would actually be good to go check the grapes when you
-- don't know them and when you can find them on internet! And then cache them in the
-- database for the next user ». Le 22/10 au Vagabond, les vins bus dehors arrivaient sans
-- cépages : le palais lisait un « Ungrafted Cinsault » de la Maipo comme un cabernet
-- (tanins 0,83), un Tannat comme un vin souple.
--
-- La fonction `taches-ia` (tâche `cepages`) cherche d'abord ici, puis dans le catalogue
-- (`wines`, les fiches qui ont déjà leurs cépages), et seulement ensuite sur le web. Ce
-- qu'elle trouve est gardé ici : le suivant qui boit ce vin ne coûte rien. Un vin qu'on n'a
-- pas trouvé est gardé aussi (sans cépages), pour ne pas le rechercher à chaque verre ; il
-- se recherche après trente jours.
--
-- Seule la fonction (rôle de service) lit et écrit : un compte ne peut ni lire la table
-- en direct, ni y glisser de faux cépages que d'autres recevraient. Le rôle d'analyse la
-- lit, comme les fiches (079).
--
-- Vérification :
--   SELECT count(*) FROM public.cepages_des_vins;                        -- 0 au départ
--   SELECT valeur -> 'cepages' FROM public.app_config WHERE cle = 'quotas_ia';
--   SELECT has_table_privilege('authenticated', 'public.cepages_des_vins', 'select');  -- f

CREATE TABLE IF NOT EXISTS public.cepages_des_vins (
  -- « domaine|vin », en minuscules, sans accents ni ponctuation : la même clé que la
  -- fonction calcule.
  cle         TEXT PRIMARY KEY CHECK (length(cle) BETWEEN 2 AND 300),
  producteur  TEXT,
  nom         TEXT NOT NULL,
  -- [{"name": "Cinsault", "pct": 100}] ; vide : cherché, pas trouvé.
  cepages     JSONB NOT NULL DEFAULT '[]'::jsonb CHECK (jsonb_typeof(cepages) = 'array'),
  -- 'catalogue' (une fiche le disait), 'recherche' (trouvé sur le web), 'connaissance'
  -- (le modèle le savait sans chercher), 'inconnu'.
  methode     TEXT NOT NULL CHECK (methode IN ('catalogue', 'recherche', 'connaissance', 'inconnu')),
  -- La page où la recherche l'a lu, quand il y en a une.
  source      TEXT,
  -- Une recherche Google a-t-elle vraiment eu lieu ? Le modèle décide seul de chercher, et
  -- souvent ne cherche pas (essai du 23/10 : 0 sur 5 en réflexion « low ») : un « inconnu »
  -- sans recherche se retente au bout de trois jours, pas de trente.
  recherche_faite BOOLEAN NOT NULL DEFAULT false,
  trouve_le   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Une table déjà créée par une première version de cette migration reçoit la colonne.
ALTER TABLE public.cepages_des_vins ADD COLUMN IF NOT EXISTS recherche_faite BOOLEAN NOT NULL DEFAULT false;

ALTER TABLE public.cepages_des_vins ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.cepages_des_vins FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.cepages_des_vins TO service_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'chatmelier_feedback_ro') THEN
    GRANT SELECT ON public.cepages_des_vins TO chatmelier_feedback_ro;
    DROP POLICY IF EXISTS cepages_des_vins_analyse ON public.cepages_des_vins;
    CREATE POLICY cepages_des_vins_analyse ON public.cepages_des_vins FOR SELECT TO chatmelier_feedback_ro USING (true);
  END IF;
END $$;

-- Le plafond du jour : une recherche par vin inconnu, le cache servant le reste. Fusion :
-- les autres entrées restent comme elles sont.
UPDATE public.app_config
   SET valeur = valeur || '{"cepages": {"compte": 40, "anonyme": 10}}'::jsonb,
       maj_le = now()
 WHERE cle = 'quotas_ia';
