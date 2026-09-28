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
| Console d'administration **nominative** : noms, fil d'activité par personne, conversations avec le sommelier | migration 044 (à venir), `lib/features/admin/` | Passer `app_config.admin_detail_nominatif` à faux ; pseudonymiser (identifiant court au lieu du nom) ; **retirer la lecture des conversations** ; ne garder que des agrégats (déjà servis par la 041). |
| Mise à jour **obligatoire** au démarrage | point 4.3 du plan (à venir), table `app_config` | Repasser en simple invitation, refusable. Une app publique ne bloque pas ses utilisateurs pour une version mineure. |

## 2. RGPD

Le responsable de traitement doit pouvoir répondre à chacune de ces questions avant le
lancement public.

- **Politique de confidentialité à réécrire** (`privacy.html`), en mentionnant
  explicitement :
  - les **comptes anonymes** ouverts sans formulaire en rejoignant une table, et leur
    **purge à 30 jours** s'ils ne sont pas convertis ;
  - le **partage du profil de goût avec les autres convives** d'une table (les huit axes
    et le prénom, rien d'autre — `GuestProfile.toJson`) ;
  - les **captures d'écran** jointes aux retours (bucket privé `feedback`, migration 036) ;
  - le traitement par **Google Gemini** (photos d'étiquettes et de cartes, conversations
    avec le sommelier) : sous-traitant, finalité, localisation ;
  - les journaux de diagnostic et leur durée de conservation.
- **Registre des traitements** : un traitement par finalité (cave, dégustations, profil de
  goût, tables de restaurant, retours, diagnostic, publicité).
- **Durées de conservation**, par table, écrites et appliquées : `app_diagnostic_logs`,
  `chat_messages`, `table_sessions` (4 h + 24 h, déjà purgées par fonction), comptes
  anonymes (30 jours).
- **Droit d'accès et de portabilité — MANQUANT.** La suppression de compte existe
  (`delete_user_account`, migrations 023 puis 039) ; **aucun export des données
  personnelles n'existe**. À construire : un export JSON (cave, dégustations, profil,
  conversations) depuis Profil → Compte.
- **Sous-traitants** : accord de traitement (DPA) avec Supabase et Google ; vérifier la
  région d'hébergement du projet Supabase.
- **Consentement** : UMP (AdMob) est en place sur mobile ; sur le web, informer sur le
  `localStorage` (session, préférences) et l'absence de publicité.
- **Mineurs** : voir section 3 — la vérification d'âge sert aussi ici.

## 3. Alcool

- **Vérification d'âge** (18 ans) à la première ouverture, sur mobile et sur le web.
- **Loi Évin** : la publicité dans une application consacrée au vin est encadrée en France ;
  faire valider le format des publicités affichées (AdMob) et le ton des contenus.
- **Politiques des stores** : catégorie « alcool » du Play Store (déclaration de contenu,
  classification d'âge) et de l'App Store (17+ minimum).

## 4. Exploitation

- **Planifier les purges** (pg_cron ou fonction edge quotidienne) :
  `purge_comptes_anonymes(30)` (migration 039) et `purge_expired_table_sessions()`
  (migration 038). Aujourd'hui elles existent mais ne tournent pas.
- **Anciennes captures publiques** : supprimer `labels/feedback/*` une fois dépouillées
  (requête en fin de migration 036).
- **SMTP personnalisé** — indispensable : le SMTP par défaut de Supabase plafonne à
  quelques e-mails par heure, et l'inscription passe désormais par lien de connexion. Au
  premier afflux, les liens n'arriveraient plus.
- **Sauvegardes** : activer le PITR (Point-In-Time Recovery) du projet Supabase.
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
- Mesure revenu pub ÷ coût IA (étape S5 du plan V2) avant de fixer le modèle économique.

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
