# Passage en production — ce qu'il faudra faire

La phase de test a ouvert des accès et des comportements qu'on n'acceptera pas en
production : des testeurs volontaires, qui connaissent l'équipe et ont accepté d'être
visibles, ne sont pas des utilisateurs anonymes du Play Store.

**Règle** : toute ouverture « phase de test » ajoute sa ligne ici, avec son retour
arrière, **dans le même commit** que l'ouverture. Ce document n'est complet que si cette
règle a été tenue.

État : **phase de test** (build 1.4.0, septembre 2026).

---

## 1. Ouvertures de test à refermer

| Quoi | Où | Retour arrière |
|---|---|---|
| Le rôle de dépouillement `chatmelier_feedback_ro` lit **tous** les journaux, avec `user_id`, et les prénoms de `profiles` | migration 043 | Bloc « Retour arrière » en fin de `043_readonly_all_logs.sql` : revenir à `tag = 'USER_FEEDBACK'`, révoquer `user_id`, `error_details`, `metadata` et `profiles`. |
| Console d'administration **nominative** : prénoms, fil d'activité par personne, conversations avec le sommelier (questions et réponses), erreurs par personne | migration 044, `lib/features/admin/` | D'abord `UPDATE app_config SET valeur = 'false' WHERE cle = 'admin_detail_nominatif'` : les prénoms deviennent « Personne a1b2c3 », conversations et textes des retours ne sortent plus. Puis supprimer `admin_conversations` et `admin_fil_personne` (bloc « Retour arrière » de la 044) ; ne garder que des agrégats (041). |
| **Questions au sommelier de la carte dans les journaux** : la question et le début de la réponse sont écrits dans `app_diagnostic_logs` (tag `MENU_CHAT`) pour le fil de la console | `menu_scan_service.dart`, `_demanderAuSommelierDistant` | Ne journaliser que la durée et le modèle ; purger les lignes `MENU_CHAT` existantes. |
| Traces d'usage (`USAGE` : matchmaker, flights, consensus…) rattachées à un compte | journaux applicatifs | Acceptable en production si la politique de confidentialité les mentionne ; sinon les journaliser sans `user_id`. |
| Mise à jour **obligatoire** au démarrage : `app_config.version_minimale_test` bloque tout build plus ancien | migration 045, `GardeDeVersion` (`lib/features/config/`, branchée dans `app.dart`) | Supprimer la clé (bloc « Retour arrière » de la 045) et retirer `GardeDeVersion` ; repasser à une simple invitation, refusable. Une app publique ne bloque pas ses utilisateurs pour une version mineure. |
| **Coûts IA et pubs par personne** : `ai_cost_events` et `ad_impressions` lisibles par le rôle `chatmelier_feedback_ro`, onglet « Économie » de la console avec détail par personne ; écriture ouverte à tout compte, anonyme compris | migration 047, `EnvoiParLots`, `MesureDesPubs`, `OngletEconomie` | Révoquer le `SELECT` et les politiques `*_analyse` du rôle d'analyse ; l'onglet suit déjà l'interrupteur `admin_detail_nominatif` (`admin_nom`). En production, journaliser les coûts depuis les fonctions edge (pas depuis l'app) et limiter le débit des insertions. |

## 2. RGPD

Le responsable de traitement doit pouvoir répondre à chacune de ces questions avant le
lancement public.

- ✅ **Politique de confidentialité réécrite le 08/10** (`app/web/privacy.html`, français et
  anglais ; résumé dans l'app, Profil → Compte). Reste à Flavien : **nommer le responsable
  du traitement** (nom ou société, adresse : exigé par le RGPD, la page dit « l'éditeur »).
  Ce qu'elle devait mentionner, et mentionne :
  - les **comptes anonymes** ouverts sans formulaire en rejoignant une table, et leur
    **purge à 30 jours** s'ils ne sont pas convertis ;
  - le **partage du profil de goût avec les autres convives** d'une table (les huit axes
    et le prénom, rien d'autre — `GuestProfile.toJson`) ;
  - les **captures d'écran** jointes aux retours (bucket privé `feedback`, migration 036) ;
  - le traitement par **Google Gemini** (photos d'étiquettes et de cartes, conversations
    avec le sommelier) : sous-traitant, finalité, localisation ;
  - les journaux de diagnostic et leur durée de conservation ;
  - le **palais conservé côté serveur** (profils de goût, registre des preuves, instantanés
    mensuels — table `palais_utilisateur`, migration 050), lisible par la seule personne,
    supprimé avec le compte ; et le **code de reprise** (empreinte SHA-256 seulement,
    30 jours, usage unique).
- **Registre des traitements** : un traitement par finalité (cave, dégustations, profil de
  goût, tables de restaurant, retours, diagnostic, publicité).
- ✅ **Durées de conservation écrites et appliquées (migration 063, 08/10)** : journaux
  180 jours, retours un an, coûts d'IA et impressions 400 jours, cartes des lieux 180 jours
  (061), en plus des purges de la 053. Historique : `app_diagnostic_logs`,
  `chat_messages`, `table_sessions` (4 h + 24 h, déjà purgées par fonction), comptes
  anonymes (30 jours).
- ✅ **Droit d'accès et de portabilité — fait le 08/10** : Profil → Compte → « Télécharger
  mes données » (JSON : compte, caves, bouteilles, dégustations, palais, conversations, amis,
  journaux). La suppression de compte efface aussi les fichiers (photos, avatar, captures),
  que la base n'emportait pas. Historique : la suppression de compte existe
  (`delete_user_account`, migrations 023, 031, puis 039 — **cassée par la 039, réparée par
  la 049** : vérifier en production qu'un compte de test se supprime) ; **aucun export des
  données personnelles n'existe**. À construire : un export JSON (cave, dégustations, profil,
  conversations) depuis Profil → Compte.
- **Sous-traitants** : accord de traitement (DPA) avec Supabase et Google ; vérifier la
  région d'hébergement du projet Supabase.
- 🟡 **Recherche d'amis — en base depuis la migration 062 (08/10)** : seules les
  correspondances reviennent (vingt au plus), à un compte non anonyme. **Reste** : restreindre
  la politique « Public profiles are viewable by everyone » (l'app lit `profiles` en direct
  pour les amis, les convives et les notifications : à revoir écran par écran). Historique : `AuthRepository.searchUsers` télécharge les
  50 premiers profils et filtre sur l'appareil : tout compte connecté peut lister les
  prénoms et avatars de tous les utilisateurs (en production, `profiles` ne porte ni
  e-mail ni téléphone — vérifié le 28/09 dans le catalogue). Et au-delà de 50 comptes,
  la recherche ne trouve plus personne. À remplacer par une fonction serveur qui cherche
  en base, ne renvoie que les correspondances, et restreindre la lecture de `profiles`.
- **Consentement** : UMP (AdMob) est en place sur mobile ; sur le web, informer sur le
  `localStorage` (session, préférences) et l'absence de publicité.
- **Mineurs** : voir section 3 — la vérification d'âge sert aussi ici.

## 3. Alcool

- ✅ **Vérification d'âge** à la première ouverture, sur mobile et sur le web Flutter
  (`PorteDeLAge`, 08/10). La page invité légère (`/table/`) n'en a pas : à décider.
- **Loi Évin** : la publicité dans une application consacrée au vin est encadrée en France ;
  faire valider le format des publicités affichées (AdMob) et le ton des contenus.
- **Politiques des stores** : catégorie « alcool » du Play Store (déclaration de contenu,
  classification d'âge) et de l'App Store (17+ minimum).

## 3 bis. Sécurité du stockage (trouvé le 08/10)

- ✅ **Migration 064** : le bucket public `labels` acceptait dépôt, remplacement et
  effacement par n'importe qui (règle « Public Access Labels » pour toutes les opérations et
  tous les rôles, y compris sans compte). Chacun n'écrit plus que dans son dossier.
  **À appliquer en priorité.**
- À vérifier par Flavien : **le projet Google de la clé Gemini est facturé** (les données
  envoyées à un projet gratuit peuvent servir à Google), et les **accords de sous-traitance**
  (DPA) de Supabase et de Google sont acceptés.

## 4. Exploitation

- **Planifier les purges** (pg_cron ou fonction edge quotidienne) :
  `purge_comptes_anonymes(30)` (migration 039, qui ne pouvait pas aboutir avant la 049) et
  `purge_expired_table_sessions()` (migration 038). Aujourd'hui elles existent mais ne
  tournent pas. La table `tentatives_de_reprise` se vide d'elle-même (un jour).
- **Recherche Google du scan d'étiquette** : interrupteur `app_config.scan_etiquette_recherche`
  (migration 048), éteint ; ≈ 3 c€ par vin inconnu, une seule fois. À décider au vu de
  l'onglet « Économie ».
- **Anciennes captures publiques** : supprimer `labels/feedback/*` une fois dépouillées
  (requête en fin de migration 036).
- **SMTP personnalisé** — indispensable : le SMTP par défaut de Supabase plafonne à
  quelques e-mails par heure, et l'inscription passe désormais par lien de connexion. Au
  premier afflux, les liens n'arriveraient plus.
- **Sauvegardes** : activer le PITR (Point-In-Time Recovery) du projet Supabase.
- **Fonctions de la carte ouvertes** : `scan-menu` et `menu-chat` (28/09) acceptent tout
  appelant, avec une limite de débit en mémoire qui repart à zéro à chaque démarrage à
  froid. Chaque appel coûte des jetons Gemini. Avant l'ouverture publique : quota par
  compte (anonyme compris) tenu en base.
- **Alertes** : une alerte quand le taux d'ERROR dépasse un seuil (la console
  d'administration les montre, mais personne ne la regarde à 3 h du matin).
- **Connexion de dépouillement** : `tool/feedback.sh` passe par le Session pooler (IPv4) ;
  en production, restreindre le rôle (section 1) et changer son mot de passe.

## 5. Publicité et revenus

- **iOS** : `app/ios/Runner/Info.plist` porte l'**ID d'application de démonstration** de
  Google (`ca-app-pub-3940256099942544~1458002511`) et `productionIosRewardedUnitId` /
  `productionIosAppOpenUnitId` valent `null` dans `admob_config.dart` → publicités de test,
  zéro revenu. Remplacer par les identifiants réels.
- Retirer tout mode test AdMob restant et vérifier les identifiants Android.
- Mesure revenu pub ÷ coût IA : en place (migration 047, onglet « Économie »). Les eCPM de
  `app_config.ecpm_eur_estime` sont des **estimations** : les remplacer par les eCPM réels de la
  console AdMob avant de décider du modèle économique.

## 6. Nettoyage

- **Données de test sur des comptes réels** : la dégustation « ZZZ-TEST-REGION » (saisie
  le 16/09 pendant une campagne de test, sur le compte de Flavien), les tables de test
  (codes `KYZ3YZ` et suivants), le convive « Paul » de vérification, le compte de test
  seedé s'il en reste.
- **Artefacts web suivis à la racine du dépôt** : `main.dart.js` (10 Mo), `assets/`,
  `flutter_bootstrap.js`, `version.json` — déversés par `build_and_sync_web.sh`
  (`cp -r build/web/* "$DIR/"`) alors que le site est servi depuis un autre dépôt. Retirer
  la copie et les fichiers.
- **Mot de passe du keystore** Android à changer.
- **`app_version`** : vérifier que chaque build de production passe
  `--dart-define=CHATMELIER_VERSION` (les scripts le font ; un build manuel l'oublierait).
