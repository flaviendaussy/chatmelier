-- Migration 030: ferme l'exposition publique des logs de diagnostic
--
-- CONSTAT (2026-09-15) : 20 229 lignes de `app_diagnostic_logs` étaient lisibles avec la
-- seule clé publiable — celle qui est compilée dans chaque bundle client et donc publique
-- par construction. Chaque ligne porte `user_id`, `device_id`, `platform`, `app_version`
-- et un message libre contenant parfois des chemins de fichiers.
--
-- La migration 026 avait été écrite précisément pour ça, mais n'a jamais été appliquée en
-- production (sa fonction `cleanup_old_diagnostic_logs` est absente). Cette migration est
-- idempotente et peut être rejouée sans risque, y compris après 026.

-- 1. RLS active. Sans ça, toutes les politiques sont ignorées.
ALTER TABLE public.app_diagnostic_logs ENABLE ROW LEVEL SECURITY;

-- 2. Supprimer toute politique de lecture permissive, quel qu'en soit le nom.
--    On balaye dynamiquement : les noms exacts ont varié au fil des migrations.
DO $$
DECLARE pol RECORD;
BEGIN
  FOR pol IN
    SELECT policyname FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'app_diagnostic_logs'
      AND cmd IN ('SELECT', 'ALL')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS %I ON public.app_diagnostic_logs', pol.policyname);
  END LOOP;
END;
$$;

-- 3. Lecture : uniquement ses propres logs, et uniquement connecté.
CREATE POLICY "read_own_diagnostic_logs"
  ON public.app_diagnostic_logs
  FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

-- 4. Écriture : laissée ouverte à anon ET authenticated.
--    L'application journalise aussi avant connexion (démarrage, erreurs d'auth) ;
--    fermer l'insertion aveuglerait le diagnostic exactement là où il sert le plus.
DROP POLICY IF EXISTS "insert_diagnostic_logs" ON public.app_diagnostic_logs;
CREATE POLICY "insert_diagnostic_logs"
  ON public.app_diagnostic_logs
  FOR INSERT
  TO anon, authenticated
  WITH CHECK (true);

-- 5. Ceinture et bretelles : retirer le SELECT au niveau des privilèges de table,
--    pour que même une politique accidentelle ne puisse pas rouvrir la lecture à anon.
REVOKE SELECT ON public.app_diagnostic_logs FROM anon;
GRANT INSERT ON public.app_diagnostic_logs TO anon, authenticated;
GRANT SELECT ON public.app_diagnostic_logs TO authenticated;

-- 6. Vérification à exécuter juste après, depuis un contexte anonyme :
--    la requête ci-dessous doit renvoyer 0 ligne (et non 20 000).
--
--    curl -s -H "apikey: <clé publiable>" \
--      "https://<ref>.supabase.co/rest/v1/app_diagnostic_logs?select=id&limit=1"
