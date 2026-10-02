-- 054 — La carte d'une table lue par son code, et la mesure qui arrive enfin (30/09)
--
-- 1. lire_carte_de_table : le QR d'une table ne porte plus que son code. La carte entière
--    dans l'URL débordait la capacité d'un QR dès qu'elle portait les commentaires du
--    sommelier (35 vins : 19 500 bits pour 18 672, le 30/09) : l'hôte voyait une zone vide
--    à la place du QR. L'invité lit désormais la carte sur le serveur avant de s'asseoir.
--    Le code tient lieu d'autorisation, comme pour join_table_session ; seule la carte et
--    le nom du restaurant sortent, jamais les convives.
--
-- 2. ai_cost_events et ad_impressions : AUCUNE ligne n'était jamais arrivée (0 et 0, relevé
--    le 30/09). Les téléphones envoient par `upsert … ON CONFLICT (event_id) DO NOTHING`
--    pour ne rien compter deux fois ; or PostgreSQL exige alors une règle de LECTURE sur la
--    table (vérifié sur base jetable : « new row violates row-level security policy »), et
--    047 n'en donnait qu'à la console. Chacun peut désormais relire ses propres lignes.
--    Les files en attente dans les téléphones (500 événements au plus) partiront au
--    prochain lancement, sans nouvelle version de l'app.

-- -----------------------------------------------------------------------------
-- 1. La carte d'une table, par son code
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.lire_carte_de_table(p_code TEXT)
RETURNS TABLE (restaurant_name TEXT, menu JSONB, expires_at TIMESTAMPTZ)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT s.restaurant_name, s.menu, s.expires_at
  FROM public.table_sessions s
  WHERE s.code = upper(trim(p_code)) AND s.expires_at > now();
$$;

REVOKE ALL ON FUNCTION public.lire_carte_de_table(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.lire_carte_de_table(TEXT) TO anon, authenticated;

-- -----------------------------------------------------------------------------
-- 2. Chacun relit ses propres lignes de mesure
-- -----------------------------------------------------------------------------
DO $$
BEGIN
  IF to_regclass('public.ai_cost_events') IS NOT NULL THEN
    DROP POLICY IF EXISTS ai_cost_events_relecture ON public.ai_cost_events;
    CREATE POLICY ai_cost_events_relecture ON public.ai_cost_events
      FOR SELECT TO authenticated USING (user_id = auth.uid());
    GRANT SELECT ON public.ai_cost_events TO authenticated;
  END IF;
  IF to_regclass('public.ad_impressions') IS NOT NULL THEN
    DROP POLICY IF EXISTS ad_impressions_relecture ON public.ad_impressions;
    CREATE POLICY ad_impressions_relecture ON public.ad_impressions
      FOR SELECT TO authenticated USING (user_id = auth.uid());
    GRANT SELECT ON public.ad_impressions TO authenticated;
  END IF;
END $$;

-- Vérification après application :
--   SELECT policyname, cmd FROM pg_policies
--    WHERE tablename IN ('ai_cost_events', 'ad_impressions') ORDER BY 1;
--   → six lignes : *_analyse et *_relecture (SELECT), *_insertion (INSERT), pour chacune
--     des deux tables (relevé en production le 02/10 : les quatre de 047 y sont déjà).
--   Puis, le lendemain : SELECT count(*) FROM public.ai_cost_events;  → plus de zéro.
