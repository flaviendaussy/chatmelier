-- =============================================================================
-- 042 — La colonne s'appelle `wine_type`, pas `type`
-- =============================================================================
--   ERROR: column w.type does not exist
--
-- `admin_repartitions` lisait `w.type` pour classer les bouteilles par couleur. Le modèle
-- Dart expose bien `type`, mais c'est un alias : en base, depuis le premier schéma, la
-- colonne s'appelle `wine_type`. J'ai écrit la requête d'après le modèle plutôt que
-- d'après la table.
--
-- Trouvé en ouvrant la console sur la vraie base — une migration qui s'applique sans
-- erreur ne prouve rien du contenu de ses fonctions : PL/pgSQL ne résout les noms de
-- colonnes qu'à l'exécution.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.admin_repartitions(p_jours INTEGER DEFAULT 30)
RETURNS TABLE (famille TEXT, libelle TEXT, valeur INTEGER)
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
             WHEN lower(coalesce(w.wine_type,'')) LIKE '%blanc%'
               OR lower(coalesce(w.wine_type,'')) LIKE '%white%'  THEN 'Blanc'
             WHEN lower(coalesce(w.wine_type,'')) LIKE '%ros%'    THEN 'Rosé'
             WHEN lower(coalesce(w.wine_type,'')) LIKE '%spark%'
               OR lower(coalesce(w.wine_type,'')) LIKE '%eff%'    THEN 'Effervescent'
             WHEN lower(coalesce(w.wine_type,'')) IN ('dessert','fortified') THEN 'Doux & mutés'
             WHEN coalesce(w.wine_type,'') = ''                   THEN 'Non précisé'
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

REVOKE ALL ON FUNCTION public.admin_repartitions(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_repartitions(INTEGER) TO authenticated;
