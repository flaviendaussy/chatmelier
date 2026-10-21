-- Essais de la migration 077 : plafonds, politique de la pub, réglages de la console.
DO $$
DECLARE
  v_quotas JSONB;
  v_pub    JSONB;
BEGIN
  SELECT valeur INTO v_quotas FROM public.app_config WHERE cle = 'quotas_ia';
  IF (v_quotas -> 'chat' ->> 'compte')::int <> 30 OR (v_quotas -> 'cote' ->> 'compte')::int <> 10
     OR (v_quotas -> 'scan_carte' ->> 'compte')::int <> 12 THEN
    RAISE EXCEPTION 'plafonds attendus : %', v_quotas;
  END IF;
  IF NOT v_quotas ? 'scan_etiquette' THEN
    RAISE EXCEPTION 'les autres plafonds restent : %', v_quotas;
  END IF;
  RAISE NOTICE '✅ 077 : plafonds baissés, les autres intacts, la cote a le sien';

  SELECT valeur INTO v_pub FROM public.app_config WHERE cle = 'politique_pub';
  IF (v_pub ->> 'chat_offerts')::int <> 5 OR (v_pub ->> 'videos')::boolean IS NOT TRUE
     OR v_pub -> 'unite_native_android' <> 'null'::jsonb THEN
    RAISE EXCEPTION 'politique attendue : %', v_pub;
  END IF;
  RAISE NOTICE '✅ 077 : politique de la pub posée, cartes « Annonce » éteintes sans identifiant';

  IF public.reglage_invalide('politique_pub', v_pub) IS NOT NULL THEN
    RAISE EXCEPTION 'la politique posée doit être valide : %', public.reglage_invalide('politique_pub', v_pub);
  END IF;
  IF public.reglage_invalide('politique_pub', '{"chat_offerts": -1}') IS NULL
     OR public.reglage_invalide('politique_pub', '{"chat_offerts": 2.5}') IS NULL
     OR public.reglage_invalide('politique_pub', '{"unite_native_ios": "n importe quoi"}') IS NULL
     OR public.reglage_invalide('politique_pub', '{"videos": "oui"}') IS NULL THEN
    RAISE EXCEPTION 'les valeurs fausses sont refusées';
  END IF;
  IF public.reglage_invalide('politique_pub', '{"unite_native_android": "ca-app-pub-6095914862192850/1234567890"}') IS NOT NULL THEN
    RAISE EXCEPTION 'un identifiant AdMob est accepté';
  END IF;
  IF public.reglage_invalide('push', '{"url": "https://exemple.supabase.co/functions/v1/envoyer-push", "actif": false}') IS NOT NULL
     OR public.reglage_invalide('push', '{"url": "http://x"}') IS NULL THEN
    RAISE EXCEPTION 'push : https et actif oui/non';
  END IF;
  -- Ce qui marchait avant marche encore.
  IF public.reglage_invalide('quotas_ia', v_quotas) IS NOT NULL
     OR public.reglage_invalide('voix_naturelle', 'true') IS NOT NULL
     OR public.reglage_invalide('inconnu', 'true') IS NULL THEN
    RAISE EXCEPTION 'les règles de la 072 sont gardées';
  END IF;
  RAISE NOTICE '✅ 077 : la console règle politique_pub et push, refuse le faux, garde la 072';

  -- Les essais de la console (060) réécrivent ce réglage avant celui-ci : on rejoue le geste
  -- de la 077 sur une valeur connue.
  UPDATE public.app_config SET valeur = '{"rewarded": 9.5}'::jsonb WHERE cle = 'ecpm_eur_estime';
  UPDATE public.app_config
     SET valeur = '{"native": 2.0}'::jsonb || valeur, maj_le = now()
   WHERE cle = 'ecpm_eur_estime' AND NOT valeur ? 'native';
  IF (SELECT valeur FROM public.app_config WHERE cle = 'ecpm_eur_estime') <> '{"native": 2.0, "rewarded": 9.5}'::jsonb THEN
    RAISE EXCEPTION 'eCPM natif ajouté sans toucher aux autres attendu';
  END IF;
  RAISE NOTICE '✅ 077 : eCPM estimé du format natif';
END $$;
