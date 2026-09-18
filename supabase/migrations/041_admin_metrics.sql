-- =============================================================================
-- 041 — Les chiffres d'usage, pour l'administrateur seul
-- =============================================================================
-- Tout passe par des fonctions SECURITY DEFINER qui vérifient `profiles.is_admin`
-- (migration 029), une colonne que le client peut LIRE mais jamais ÉCRIRE.
--
-- CE QU'ON NE REFAIT PAS. La console précédente embarquait un JWT `service_role` en clair
-- dans une page web publique : quiconque ouvrait le code source avait la base entière.
-- Ici aucune clé n'est distribuée — l'app envoie la session de la personne, et c'est le
-- serveur qui décide. Une console volée ne donne rien de plus qu'un compte volé.
--
-- CE QUI NE SORT PAS D'ICI. Les fonctions renvoient des AGRÉGATS : des comptes par jour,
-- par plateforme, par type d'action. Aucun `user_id`, aucune adresse, aucun contenu de
-- message. Savoir combien de gens ont scanné une carte mardi ne demande pas de savoir qui.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.est_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT coalesce((SELECT p.is_admin FROM public.profiles p WHERE p.id = auth.uid()), false);
$$;

-- -----------------------------------------------------------------------------
-- 1. La courbe principale : un point par jour
-- -----------------------------------------------------------------------------
-- « Actif » = a produit quelque chose ce jour-là : une dégustation, une bouteille, un
-- message au sommelier, ou une trace applicative. Se connecter sans rien faire ne compte
-- pas — un chiffre d'activité qui grimpe parce que l'app s'ouvre au démarrage ne mesure
-- rien d'utile.
CREATE OR REPLACE FUNCTION public.admin_metriques_quotidiennes(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (
  jour              DATE,
  actifs            INTEGER,
  nouveaux          INTEGER,
  degustations      INTEGER,
  bouteilles        INTEGER,
  messages          INTEGER,
  vins_decouverts   INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_depuis TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces chiffres demandent un compte administrateur.';
  END IF;

  RETURN QUERY
  WITH calendrier AS (
    SELECT generate_series(v_depuis::date, now()::date, '1 day')::date AS j
  ),
  gestes AS (
    SELECT t.user_id AS uid, t.consumed_at AS quand, 'degustation' AS quoi
      FROM public.tasting_log t WHERE t.consumed_at >= v_depuis
    UNION ALL
    SELECT b.added_by, b.created_at, 'bouteille'
      FROM public.bottles b WHERE b.created_at >= v_depuis
    UNION ALL
    SELECT c.user_id, c.created_at, 'message'
      FROM public.chat_messages c WHERE c.created_at >= v_depuis
    UNION ALL
    SELECT l.user_id, l.created_at, 'trace'
      FROM public.app_diagnostic_logs l WHERE l.created_at >= v_depuis
  )
  SELECT
    cal.j,
    (SELECT count(DISTINCT g.uid)::int FROM gestes g
      WHERE g.quand::date = cal.j AND g.uid IS NOT NULL),
    (SELECT count(*)::int FROM auth.users u WHERE u.created_at::date = cal.j),
    (SELECT count(*)::int FROM gestes g WHERE g.quand::date = cal.j AND g.quoi = 'degustation'),
    (SELECT count(*)::int FROM gestes g WHERE g.quand::date = cal.j AND g.quoi = 'bouteille'),
    (SELECT count(*)::int FROM gestes g WHERE g.quand::date = cal.j AND g.quoi = 'message'),
    (SELECT count(*)::int FROM public.wines w WHERE w.created_at::date = cal.j)
  FROM calendrier cal
  ORDER BY cal.j;
END;
$$;

-- -----------------------------------------------------------------------------
-- 2. Le résumé : ce qu'on lit en premier
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_resume(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (
  utilisateurs_total   INTEGER,
  anonymes             INTEGER,
  actifs_periode       INTEGER,
  nouveaux_periode     INTEGER,
  degustations_periode INTEGER,
  bouteilles_total     INTEGER,
  caves_total          INTEGER,
  vins_total           INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_depuis TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces chiffres demandent un compte administrateur.';
  END IF;

  RETURN QUERY SELECT
    (SELECT count(*)::int FROM auth.users),
    (SELECT count(*)::int FROM auth.users WHERE is_anonymous IS TRUE),
    (SELECT count(DISTINCT uid)::int FROM (
        SELECT user_id AS uid FROM public.tasting_log WHERE consumed_at >= v_depuis
        UNION ALL SELECT added_by FROM public.bottles WHERE created_at >= v_depuis
        UNION ALL SELECT user_id FROM public.chat_messages WHERE created_at >= v_depuis
        UNION ALL SELECT user_id FROM public.app_diagnostic_logs WHERE created_at >= v_depuis
     ) x WHERE uid IS NOT NULL),
    (SELECT count(*)::int FROM auth.users WHERE created_at >= v_depuis),
    (SELECT count(*)::int FROM public.tasting_log WHERE consumed_at >= v_depuis),
    (SELECT count(*)::int FROM public.bottles),
    (SELECT count(*)::int FROM public.cellars),
    (SELECT count(*)::int FROM public.wines);
END;
$$;

-- -----------------------------------------------------------------------------
-- 3. Les répartitions : ce qui alimente les camemberts
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_repartitions(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (
  famille   TEXT,   -- 'plateforme', 'geste', 'couleur', 'pays'
  libelle   TEXT,
  valeur    INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_depuis TIMESTAMPTZ := now() - (greatest(p_jours, 1) || ' days')::interval;
BEGIN
  IF NOT public.est_admin() THEN
    RAISE EXCEPTION 'reserve_admin' USING HINT = 'Ces chiffres demandent un compte administrateur.';
  END IF;

  RETURN QUERY
    SELECT 'plateforme', coalesce(nullif(trim(l.platform), ''), 'inconnue'), count(*)::int
      FROM public.app_diagnostic_logs l
     WHERE l.created_at >= v_depuis
     GROUP BY 2
  UNION ALL
    SELECT 'geste', 'Dégustations', count(*)::int
      FROM public.tasting_log WHERE consumed_at >= v_depuis
  UNION ALL
    SELECT 'geste', 'Bouteilles ajoutées', count(*)::int
      FROM public.bottles WHERE created_at >= v_depuis
  UNION ALL
    SELECT 'geste', 'Messages sommelier', count(*)::int
      FROM public.chat_messages WHERE created_at >= v_depuis
  UNION ALL
    SELECT 'geste', 'Vins découverts', count(*)::int
      FROM public.wines WHERE created_at >= v_depuis
  UNION ALL
    SELECT 'couleur',
           CASE
             WHEN lower(coalesce(w.type,'')) LIKE '%blanc%' OR lower(coalesce(w.type,'')) LIKE '%white%' THEN 'Blanc'
             WHEN lower(coalesce(w.type,'')) LIKE '%ros%'                                                THEN 'Rosé'
             WHEN lower(coalesce(w.type,'')) LIKE '%spark%' OR lower(coalesce(w.type,'')) LIKE '%eff%'   THEN 'Effervescent'
             WHEN coalesce(w.type,'') = ''                                                               THEN 'Non précisé'
             ELSE 'Rouge'
           END,
           count(*)::int
      FROM public.bottles b JOIN public.wines w ON w.id = b.wine_id
     WHERE b.quantity > 0
     GROUP BY 2
  UNION ALL
    SELECT 'pays', coalesce(nullif(trim(w.country), ''), 'Inconnu'), count(*)::int
      FROM public.bottles b JOIN public.wines w ON w.id = b.wine_id
     WHERE b.quantity > 0
     GROUP BY 2;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_metriques_quotidiennes(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_resume(INTEGER) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_repartitions(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_metriques_quotidiennes(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_resume(INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_repartitions(INTEGER) TO authenticated;

-- Vérification :
--   SELECT est_admin();                            -- false depuis le SQL Editor (pas de JWT)
--   SELECT * FROM admin_resume(30);                -- doit lever reserve_admin
--   -- Depuis l'app, connecté avec un compte is_admin : les trois doivent répondre.
