-- =============================================================================
-- 046 — Plus d'e-mail ni de téléphone dans l'annuaire public, ni dans les journaux
-- =============================================================================
-- CONSTAT (29/09). Faute de colonnes `username`/`phone_number`/`email` en production
-- (migration 017 jamais appliquée), la mise à jour de profil encodait pseudo, téléphone
-- et e-mail dans `profiles.avatar_url` (« meta://?u=…&p=…&e=… »). Or `profiles` est
-- lisible par TOUS, sans compte (politique « Public profiles are viewable by
-- everyone ») : 12 adresses e-mail étaient lisibles avec la seule clé publique.
-- Les journaux en portaient aussi : 8 082 lignes.
--
-- 1. On ne garde que le pseudo dans avatar_url (public par nature).
-- 2. Un déclencheur l'impose à chaque écriture : les versions déjà installées (≤ 70)
--    réécriraient sinon téléphone et e-mail à la prochaine modification de profil.
-- 3. Les journaux sont masqués (URI meta:// et adresses), sans suppression de lignes.
-- Expressions testées le 29/09 sur des chaînes fictives.
-- =============================================================================

CREATE OR REPLACE FUNCTION public.profiles_sans_coordonnees()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.avatar_url LIKE 'meta://%' THEN
    NEW.avatar_url := 'meta://?u=' || coalesce(substring(NEW.avatar_url from 'u=([^&]*)'), '');
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS profiles_sans_coordonnees ON public.profiles;
CREATE TRIGGER profiles_sans_coordonnees
  BEFORE INSERT OR UPDATE OF avatar_url ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.profiles_sans_coordonnees();

UPDATE public.profiles
   SET avatar_url = 'meta://?u=' || coalesce(substring(avatar_url from 'u=([^&]*)'), '')
 WHERE avatar_url LIKE 'meta://%';

UPDATE public.app_diagnostic_logs
   SET message = regexp_replace(
         regexp_replace(message, 'meta://[^[:space:]]*', 'meta://…', 'g'),
         '([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+\.[A-Za-z]{2,})', '\1…@\2', 'g'),
       error_details = regexp_replace(
         regexp_replace(error_details, 'meta://[^[:space:]]*', 'meta://…', 'g'),
         '([A-Za-z0-9._%+-])[A-Za-z0-9._%+-]*@([A-Za-z0-9.-]+\.[A-Za-z]{2,})', '\1…@\2', 'g')
 WHERE message LIKE '%meta://%' OR error_details LIKE '%meta://%'
    OR message ~ '@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' OR error_details ~ '@[A-Za-z0-9.-]+\.[A-Za-z]{2,}';

-- Vérification (les deux doivent rendre 0) :
--   SELECT count(*) FROM public.profiles WHERE avatar_url ~ '[&?](p|e)=';
--   SELECT count(*) FROM public.app_diagnostic_logs WHERE message LIKE '%meta://?%';
