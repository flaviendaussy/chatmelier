# Handover — Antigravity → Claude

**Date d'ouverture :** 2026-09-14
**Version au moment du handover :** v1.3.4+67
**Commit de référence avant reprise :** `2949c91` (2026-09-11)

Ce document est le journal de passage de relais. Il sert à deux choses : savoir ce qui a été
fait et pourquoi, et pouvoir **repasser la main à Antigravity** sans rien perdre.

---

## 🔴 À FAIRE PAR FLAVIEN — incident de sécurité, prioritaire

Trois secrets sont dans l'historique git **public** (`github.com/flaviendaussy/chatmelier`,
visibilité PUBLIC, `origin/master` poussé). Les retirer du code ne les retire pas de
l'historique : **seule la rotation les neutralise.**

| Secret | Depuis | Commits | État |
|---|---|---|---|
| **JWT `service_role` Supabase** | 2026-08-30 → 2026-09-14 (15 j) | `54a3707`, `976f320` | ✅ **NEUTRALISÉ** le 2026-09-14 — clés legacy désactivées |
| **Clé API Gemini** (celle de `build_bundle.sh`) | plus ancien | `df650a5`, `5697356`, `61776d5` | ✅ **remplacée** le 2026-09-15 — secret Supabase mis à jour, fonction edge vérifiée HTTP 200 |
| Mot de passe keystore (`storePassword`) | — | `a9febdb` | ⏳ à changer (faible urgence : le `.jks` n'a jamais été committé) |
| **Compte de seed `flavien@chatmelier.app` / `Secret1234`** | depuis `007` | `007_seed_test_user.sql` | ✅ **supprimé le 2026-09-16** (vérifié : 0 ligne). Confirmé présent en production, non administrateur, dernière connexion le 2026-09-05. Migration neutralisée (`da92004`) |

**Neutralisation du `service_role` — ce qui a été fait et vérifié.**
Les clés legacy JWT (`anon` + `service_role`) ont été désactivées depuis
*Settings → API Keys → Disable legacy API keys*. Trois vérifications préalables :

- **Aucun client publié n'utilisait la legacy.** Les cinq artefacts v1.2.1+52 → v1.3.4+67 et le
  bundle web déployé n'embarquent que `sb_publishable_` (0 occurrence de JWT legacy).
- **Les fonctions edge ont survécu.** Six des sept construisent leur client Supabase à partir des
  variables injectées `SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY`. Test avant/après sur
  `chat` : réponse identique (`{"error":"Unauthorized"}`, HTTP 401 — émise par `chat/index.ts:24`,
  donc après un `createClient` et un `auth.getUser()` réussis). Supabase remappe bien les
  variables injectées vers le nouveau système de clés.
- **Le token fuité est mort.** `/auth/v1/admin/users` → HTTP 401, `/rest/v1/profiles` → HTTP 401.

Portée du `service_role` : contourne **toutes** les règles RLS sur **toutes** les tables, plus
l'API d'administration des comptes (adresses e-mail de tous les utilisateurs, suppression,
usurpation). Il était en outre servi en clair sur `chatmelier.github.io/admin_console/`
(HTTP 200 vérifié, token présent 7 fois dans la page).

Bonne nouvelle : **le fichier keystore `.jks` lui-même n'a jamais été committé** — personne ne
peut signer d'APK à votre place avec le seul mot de passe.

### Le compte de seed — clos le 2026-09-16

`007_seed_test_user.sql` créait `flavien@chatmelier.app` avec le mot de passe
`Secret1234` en clair, dans un dépôt public. Le compte **existait bien en production**.
Il n'était pas administrateur, et sa dernière connexion datait du 2026-09-05 — un jour
sans aucun commit, donc impossible de conclure s'il s'agissait d'un test interne ou non ;
les journaux de diagnostic ne contenaient aucune trace de ce compte.

Ses dépendances ont été vidées — nécessaire car les clés étrangères vers `profiles`
(`cellars.owner_id`, `bottles.added_by`, `tasting_log.user_id`, `chat_messages.user_id`)
n'ont **aucune clause `ON DELETE`** : la suppression échoue tant que caves et bouteilles
subsistent. `delete_user_account()` ne sert à rien ici, elle ne supprime que l'appelant
(`auth.uid()`). Compte supprimé ensuite, vérifié à 0 ligne.

Cette absence de `ON DELETE` est une dette à part entière : **supprimer un compte demande
aujourd'hui un script manuel**, alors que la suppression RGPD est censée être
automatique. `delete_user_account()` couvre le cas de l'utilisateur qui se supprime
lui-même, mais rien ne couvre une suppression administrative.

Le vrai piège de cette migration n'était pas la création du compte mais sa branche
`ELSE`, qui **réinitialisait le mot de passe** si le compte existait déjà : la rejouer
aurait réarmé la faille après toute correction manuelle. Corps mis hors service en
`da92004`.

`Secret1234` reste dans l'historique git public. Sans le compte, c'est sans objet — mais
ça compte dans la décision de réécrire l'historique, qui reste ouverte.

### Migrations à appliquer — dans cet ordre

`029`, `030`, `031` et **`032`** ont été appliquées. Reste :

| Migration | Ce qu'elle fait | Pourquoi maintenant |
|---|---|---|
| *(aucune)* | — | `032` appliquée le 2026-09-16. Vérifié : `rating` est passé en `NUMERIC(3,1)`, trois lignes marquées à l'échelle 5. Test de bout en bout sur appareil : une nouvelle dégustation s'écrit **8,5/10** au lieu de 4,25 |

**Aucune procédure manuelle n'est nécessaire** : le marquage de l'échelle est déterministe et
automatique. Coller le fichier dans le SQL Editor suffit. La migration affiche un `NOTICE`
indiquant combien de lignes ont été marquées.

Vérification après exécution (attendu : `3, 1`) :

```sql
SELECT numeric_precision, numeric_scale FROM information_schema.columns
WHERE table_name = 'tasting_log' AND column_name = 'rating';
```

**Réécriture d'historique ?** Possible (`git filter-repo` + force-push), mais elle ne récupère
pas ce qui a déjà été cloné ou indexé par les robots qui scannent les dépôts publics en continu.
La rotation reste la seule vraie remédiation. À décider séparément.

---

## Ce que Claude a fait dans cette session

### 1. Audit complet (lecture seule) — 4 documents

Produits comme artefacts, aucun fichier du dépôt modifié à ce stade :

1. **Dossier d'audit** — état technique et produit. Santé technique 45/100, potentiel produit
   68/100. 26 anomalies hiérarchisées P0→P3.
2. **Plan de recentrage** — fork des cocktails, parcage des badges et du scratchcard, suppression
   voice/changelog, et thèse : « la cave est le capteur, le restaurant est le moment ».
3. **Le palais révélé** — pourquoi le modèle de goût ne peut pas apprendre, et sa refonte.
4. **Apprendre à goûter** — critique par personas de l'expérience de dégustation, refonte en
   trois profondeurs.

### 2. Plan V2 « Au comptoir » — 6 semaines

Fichier : `~/.claude/plans/super-et-j-aime-aussi-transient-quokka.md`
Séquence : **S0** sécurité → **S1** élagage → **S2** données du goût → **S3** restaurant →
**S4** comptoir et moteur de frontière → **S5** mesure pub/coût IA.

### 3. Modifications appliquées au dépôt (ce commit)

| Fichier | Changement | Pourquoi |
|---|---|---|
| `.gitignore` | Ajout d'une section « Secrets » : `build_bundle.sh`, `setup_playstore_keystore.sh`, `admin_console/` | Le dépôt `origin` est **public** ; ces trois fichiers contiennent des clés et mots de passe en clair et étaient **non suivis** — un `git add -A` les aurait publiés |
| `admin_console/` | **Retiré du suivi git** (fichier conservé sur disque), 6 copies imbriquées supprimées | Le JWT `service_role` y est en dur. Les copies imbriquées venaient d'un `cp -r` vers une cible existante, qui ajoutait un niveau à chaque déploiement |
| `build_and_sync_web.sh` | Suppression des deux blocs qui copiaient `admin_console/` vers les sites GitHub Pages | Arrête la republication du token à chaque déploiement |
| `build_bundle.sh` | Clé Gemini en dur remplacée par `${GEMINI_API_KEY:-}` + note explicative | Un `--dart-define` n'est pas un secret : la valeur est compilée dans `libapp.so` et extractible de tout APK publié (vérifié par `strings`) |
| `HANDOVER.md` | Ce fichier | Traçabilité du passage de relais |
| `CLAUDE.md` | Mode mis à jour : audit lecture seule → exécution | La directive lecture seule a été levée explicitement par Flavien |

### 4. Ce qui n'a **pas** été committé, volontairement

- **78 Mo de badges PNG/WebP non suivis.** Les 124 PNG (43 Mo) ne sont référencés **nulle part**
  dans `lib/` — seuls les `.webp` le sont (119 références). Ils doivent être supprimés (S0), pas
  committés dans un dépôt public.
- **`build_bundle.sh` et `setup_playstore_keystore.sh`** — désormais ignorés, ils restent sur
  disque et fonctionnels.

---

## État du dépôt

- **Branche :** `master`, remote `origin` = `github.com/flaviendaussy/chatmelier` (**PUBLIC**)
- **Autres remotes :** `org` (chatmelier.github.io), `user-pages` (flaviendaussy.github.io)
- **Tests :** 478 verts, 4 ignorés (harnais de capture d'écran), 1 min 33
- **Analyse statique :** 0 erreur, 27 avertissements, 103 infos
- **Poids :** APK 177 Mo — dont 77 Mo d'assets, dont 43 Mo de PNG morts

---

## S0 — ✅ CLOS le 2026-09-15

| Item | État | Où |
|---|---|---|
| Purge des assets morts (−104 Mo) | ✅ fait | `18f111e` |
| Neutralisation des secrets dans le dépôt | ✅ fait | `18f111e` |
| Retrait du court-circuit d'auth `/admin` | ✅ fait | `6446350` |
| Rôle admin vérifié côté serveur | ✅ code fait | `6446350` |
| Neutralisation du `service_role` fuité | ✅ fait le 2026-09-14 | clés legacy désactivées + vérifié 401 |
| Migration 029 (rôle admin serveur) | ✅ appliquée le 2026-09-15 | vérifiée |
| Migration 030 (fuite des logs) | ✅ appliquée le 2026-09-15 | vérifiée : lecture anonyme refusée |
| Migration 031 (réconciliation schéma) | ✅ appliquée le 2026-09-15 | vérifiée : 5 colonnes + 2 fonctions |
| Rotation de la clé Gemini | ✅ fait le 2026-09-15 | secret Supabase + fonction edge vérifiée |
| **Prochain build mobile sans clé Gemini** | ⏳ à faire | `build_bundle.sh` ne l'exporte plus par défaut |

**Migration 029 — à appliquer.** Tant qu'elle ne l'est pas, `isAdminProvider` renvoie `false`
pour tout le monde (comportement voulu : fail-closed). Après application, s'accorder le rôle
depuis le SQL Editor Supabase — la requête est en commentaire à la fin du fichier de migration.
Aucune adresse e-mail n'est en dur : le dépôt est public.

## ⚠️ Piège rencontré lors de la rotation Gemini — à ne pas refaire

La première clé de remplacement avait été créée dans un **nouveau projet GCP**. Elle était
valide, mais `generativelanguage.googleapis.com` la refusait :

```
HTTP 401 — "Request had invalid authentication credentials. Expected OAuth 2 access token…"
reason: ACCESS_TOKEN_TYPE_UNSUPPORTED
```

Résultat : **panne totale du scan de carte**, web et mobile. Le web n'a aucune clé locale et
dépend entièrement de la fonction edge ; le mobile tentait Gemini en direct avec l'ancienne clé
révoquée puis se repliait sur la même fonction edge en panne.

**Leçon.** Les clés au format `AQ.…` créées dans un projet GCP neuf ne sont pas acceptées en
authentification par query param sur cette API. Créer la clé depuis **aistudio.google.com**, dans
le projet par défaut — on obtient une clé `AIza…` qui fonctionne.

**Test d'isolation à réutiliser**, qui sépare « la clé est mauvaise » de « le secret Supabase
n'est pas à jour » :

```bash
read -rsp "Clé : " K && echo && curl -s -o /dev/null -w 'HTTP %{http_code}\n' "https://generativelanguage.googleapis.com/v1beta/models?key=$K" && unset K
```

**Test de bout en bout de la fonction edge** (image 1×1, coût négligeable, doit renvoyer
`{"restaurant_name":null,"wines":[]}` en HTTP 200) : voir le corps de la commande dans
l'historique de session — `POST /functions/v1/scan-menu` avec un JPEG minimal en base64.

## 🔴 DÉRIVE DES MIGRATIONS — constat établi le 2026-09-15, correctif écrit

Établi par comparaison entre `information_schema` en production et les 30 migrations du
dossier. **Les 15 tables attendues existent et la RLS est active partout** — la dérive est plus
étroite que ce que j'avais d'abord écrit, mais chacun de ses trois points est silencieux.

> **Correction d'un constat erroné.** J'ai d'abord annoncé que `find_cached_wine`,
> `accept_invite` et `delete_user_account` étaient absentes, sur la foi de 404 renvoyés par des
> appels RPC. **Faux pour les deux premières** : PostgREST répond 404 quand aucune *signature*
> ne correspond, et je les appelais sans arguments. `find_cached_wine` et `accept_invite`
> existent bien — le cache de connaissances fonctionne donc, contrairement à ce que j'avais
> conclu. Seule `delete_user_account` était réellement absente.

| Manque réel | Migration | Conséquence |
|---|---|---|
| `tasting_log` : `co_tasters`, `is_external`, `location_name`, `bottle_owner_id`, `bottle_owner_name` | 015 | **Chaque dégustation perd silencieusement** avec qui elle a été faite, où, et si elle avait lieu hors de la cave. L'app attrape l'échec d'insertion et réinsère sans ces champs (`tasting_questionnaire_sheet.dart:562`), avec pour seule trace un `debugPrint` |
| `delete_user_account()` | 023 | **Suppression de compte RGPD cassée** (`auth_repository.dart:467`) |
| `cleanup_old_diagnostic_logs()` | 026 | Aucune purge — 20 229 lignes accumulées. RGPD art. 5(1)(e) |

**Pourquoi 023 n'est jamais passée**, et c'est instructif : elle fait `DELETE FROM bar_pantries`
(la table s'appelle `bar_pantry`) et `DELETE FROM user_overrides` (qui n'existe pas). La
migration échouait à l'exécution. Elle est réécrite corrigée dans la 031.

**Correctif : `031_reconcile_production_schema.sql`**, idempotente, à appliquer.

**Hors périmètre, à trancher :** `vineyard_knowledge_cache` et `user_cocktails` sont utilisées
par le code mais définies dans **aucune** migration. Leur absence est absorbée par des try/catch
(`PGRST205` récurrent dans les logs). `user_cocktails` part de toute façon avec le fork cocktails.

## 🔴 L'ÉCHELLE DES NOTES — cause racine trouvée le 2026-09-16

C'est le même défaut que la dérive ci-dessus, mais avec des conséquences qui vont bien plus
loin : **la migration 027 n'a jamais été appliquée en production.** Elle devait élargir
`tasting_log.rating` de `NUMERIC(2,1) CHECK (<= 5)` à `NUMERIC(3,1) CHECK (<= 10)`.

Or **toutes** les interfaces de saisie de l'app sont sur 10 (`Slider min:1 max:10 divisions:18`,
donc un pas de 0,5 — questionnaire, dégustation hors-cave, checkout, mode table). Chaque
enregistrement était donc rejeté par la contrainte, et le client retombait sur un dernier
recours qui **divise la note par deux** pour la faire passer.

**La preuve, sur les trois entrées réelles du journal :**

| Affiché en base | Curseur réel | Chaîne |
|---|---|---|
| 2,8 | **5,5/10** | rejet → 5,5 ÷ 2 = 2,75 → `NUMERIC(2,1)` arrondit → 2,8 |
| 3,5 | **7,0/10** | rejet → 3,5 |
| 5,0 | **10,0/10** | rejet → 5,0 |

`2,75` n'est pas une position possible du curseur : c'est la signature arithmétique de la
division. Les trois valeurs s'expliquent par des positions valides divisées par deux, et la
prédiction a été confirmée à l'écran après correction (5,6/10 et 7/10 sur l'émulateur).

**Ce que ça corrige dans mon propre travail précédent.** L'heuristique de `displayRating` qui
doublait toute note ≤ 5 ne créait pas le problème : elle le **compensait**. L'avoir retirée sans
élargir la contrainte affichait tout deux fois trop bas. C'était visible à l'écran et c'est ce
qui a mis sur la piste.

**Deux autres conséquences, corrigées du même coup :**

- `sommelier_table_mode_sheet.dart` et `cellar_repository.dart` écrivent **sans repli** : leurs
  enregistrements au-dessus de 5/10 échouaient purement et simplement.
- Avec 031 appliquée mais pas 032, les trois étages d'insert du questionnaire échouaient en
  cascade (`rating_scale` inconnu → contrainte → `rating_scale` à nouveau) : **les dégustations
  guidées ne remontaient plus du tout au serveur**, elles restaient en cache local.

**Convention adoptée, et testée car contre-intuitive :** l'absence de la colonne `rating_scale`
n'est pas une information manquante, c'est la **preuve** que 032 n'a pas tourné, donc que la note
a été divisée. Le défaut de lecture est donc 5, et non 10. C'est ce qui rend l'affichage correct
**dès maintenant**, sans attendre la migration.

**Correctif : `032_rating_scale_and_tasting_signals.sql`.** La procédure manuelle qui figurait
en section 4 a disparu : il n'y a **plus de date à deviner**. Le critère de décision est le type
de la colonne, lu avant l'élargissement — `NUMERIC(2,1)` prouve que tout l'historique est sur 5.
Le marquage et l'élargissement sont dans un bloc atomique.

## 🔴 Fuite des logs de diagnostic — correctif écrit, à appliquer

`app_diagnostic_logs` était lisible en entier (20 229 lignes) avec la seule **clé publiable**,
celle compilée dans chaque bundle client. Chaque ligne porte `user_id`, `device_id`, `platform`,
`app_version` et un message libre.

**Migration `030_fix_diagnostic_logs_exposure.sql` — à appliquer.** Active RLS, purge toute
politique de lecture permissive, restreint la lecture à ses propres logs, garde l'insertion
ouverte (l'app journalise aussi avant connexion), et retire `SELECT` à `anon` au niveau des
privilèges de table.

Vérification après application — doit renvoyer **0 ligne** :

```bash
curl -s -H "apikey: sb_publishable_P3P36VFswbjyOXxplwniPg_D_NuGYNF" "https://fvnybncauhbpsnikzeeq.supabase.co/rest/v1/app_diagnostic_logs?select=id&limit=1"
```

À noter : `profiles` est aussi lisible anonymement (24 lignes) mais **seules** les colonnes
`id`, `display_name`, `avatar_url`, `created_at`, `default_currency`, `is_admin` sont exposées —
ni e-mail, ni téléphone, ni pseudo. Les grants par colonne font leur travail. Faible gravité,
mais à revoir.

## Bugs de production visibles dans les logs, non corrigés

- **`FRIENDS` : `TimeoutException after 0:00:03` en continu**, sur les demandes d'amis, les
  requêtes de cave et les notifications — et chaque appel part **en double**. Un délai de 3 s est
  très agressif en mobilité. C'est l'erreur la plus fréquente du journal.
- **`ADMOB` : `AppOpenAd` échoue régulièrement** (`AdShowError`), et `RewardedAd` remonte
  `No fill` — à garder en tête, le modèle économique repose sur ces publicités.
- **Toutes les entrées portent `app_version: 1.2.0`** alors que la version publiée est 1.3.4+67.
  Soit la version est figée dans le logger, soit le parc est très en retard — à trancher.

## Dette d'hygiène repérée, non traitée

- **`mcp-server/node_modules/` est suivi par git** : 4 293 fichiers, 2,2 Mo. La règle
  `node_modules/` du `.gitignore` est arrivée après le commit initial, donc ils restent suivis.
  `git rm -r --cached mcp-server/node_modules` suffit à les détacher — reporté pour ne pas noyer
  les commits de S0 dans 4 000 suppressions.
- **`supabase/supabase/.temp/`** : artefacts de la CLI Supabase, détachés et ignorés dans `18f111e`.

## S1 — ✅ CLOS le 2026-09-15

| Étape | Commit |
|---|---|
| S1.1 badges découplés des cocktails | `a56c823` |
| S1.2 Chatmelier cesse d'être mixologue | `e8d7f3f` |
| S1.5 bug de pub récompensée | `bc18cb9` |
| S1.4 parcage badges/scratchcard, suppression voice et changelog | `6e7ff00` |
| S1.3 sortie des cocktails | `b45e930` |

**Résultat :** 447 tests verts, 0 erreur d'analyse, assets embarqués **77,3 Mo → 14 Mo**,
**onglet n° 2 de la navigation libre** pour « Restaurant ».

**Pertes visibles à connaître :**
- L'écran statistiques **perd sa carte des terroirs** (`_buildScratchMapCard`, ~220 lignes,
  alimentée par le scratchcard parqué). Récupérable en extrayant le composant vers `cellar/`.
- Le mode bureau perd l'entrée « Dictée vocale » de sa barre latérale — il y avait **trois**
  points d'entrée vocaux, pas deux.

**Reste à faire, non bloquant :** les 14 Mo d'assets restants sont les loaders, dont **11,5 Mo
de `.gif`** qui ne servent que de repli à un WebP animé (`chatmelier_loader.dart`). Supprimables
après vérification visuelle sur Android, iOS et web.

## Fork cocktails

`flaviendaussy/chatmelier-cocktails` — **privé**, un seul commit, sans historique.
C'est un **instantané complet et fonctionnel** de l'app, pas une app cocktails épurée : la cave,
le scan et le sommelier y sont encore. L'épuration se fera si le projet est repris. Identité
renommée (`com.chatmelier.cocktails`, paquet `chatmelier_cocktails`) pour éviter tout conflit
d'installation. Détail dans son README.

## Vérification en direct sur émulateur — 2026-09-15

AVD `chatmelier_pixel7` (Pixel 7, 1080×2400, android-36), build **profile**, GPU matériel.
Outillage : `./tool/devtest.sh`. Instantané `logged_in` figé — la session survit à toute
réinstallation, l'état est restaurable indéfiniment avec `./tool/devtest.sh restore`.

| Vérifié | Résultat |
|---|---|
| Navigation après retrait du Bar | ✅ 4 onglets mobile : Cellar · Chat · Tasting · Profile. La renumérotation 6 → 5 tient |
| Écran cave | ✅ 41 vins, 23 spiritueux, jauges d'apogée, `SpiritFillBar` intact sur le Porto |
| Profil, onglet Palais | ✅ Taste Radar préservé, **vitrine « Trophées & Badges » disparue** |
| Profil, onglet Outils | ✅ Scratchcard, Changelog et Console de diagnostic disparus |
| **Migration 029 de bout en bout** | ✅ « AI Cost Estimation », protégé par `isAdmin`, est visible → `isAdminProvider` lit bien `is_admin` côté serveur |
| Chat désintoxiqué | ✅ « Qu'est-ce que je peux préparer ce soir » → trois menus vin/plat avec de vraies bouteilles de la cave. Aucun cocktail, aucun jeton `[COCKTAIL_CARD]` |
| Parcours invité | ✅ Consensus, Wine List, Flights, Food Match — aucun plantage |
| Assets embarqués | ✅ 2,93 Mo mesurés par `unzip -l` (contre 77,3 Mo au départ) |

### Anomalies observées, non corrigées

- **Publicité plein écran au démarrage** (App Open Ad) : première chose que voit l'utilisateur à
  l'ouverture. À arbitrer, d'autant que le modèle économique repose sur la pub.
- **Mur de consentement à 210 partenaires** avant d'atteindre l'écran invité. Sur le parcours
  d'acquisition (QR au restaurant), c'est de la friction lourde avant toute démonstration de valeur.
- **Menu fictif reproduit en direct** : le code `TABLE-98931`, inexistant, affiche « Menu du
  Restaurant » avec Chablis Laroche 48 €, Janasse et Bel-Air Graves — les trois vins codés en dur,
  sans message d'erreur, les deux premiers à **79 % ex æquo**. Correction à l'audit : le champ de
  saisie de code **existe** (`login_screen.dart:290`), contrairement à ce qui y était écrit — ce
  qui aggrave le constat puisque l'interface invite à s'en servir.
- **Chevauchement de rendu** sur le Taste Radar : le sous-titre « Oenological footprint & flavor
  balance » passe sous le libellé d'axe « Tannins & Grip ».
- **ANR en GPU logiciel** (`Input dispatching timed out`, 315 images sautées). Disparus en GPU
  matériel — c'était l'émulateur, pas l'application.

## Suite prévue

**S2 — fait :** échelle de notation (cause racine comprise et corrigée), apprentissage
symétrique sur les deux chemins, moyenne exponentielle, confiance par axe (sa sérialisation
manquait, elle aussi), défauts du vin traduits dans les 13 locales, suppression du mode
« Ensemble », niveau « Gorgée » sur la dégustation hors-cave, inventaire de cave branché avec
exclusion de `source_type ∈ {gift, supermarket}`, et **le radar qui admet ce qu'il ignore**
(halo d'incertitude + phrase de confiance).

**S2 — reste :** le rachat et le délai `created_at → consumed_at` (la quantité et l'exclusion
des cadeaux sont faites), l'ancrage des curseurs dans l'historique, et les deux tables
`taste_evidence` / `taste_profile_history`.

### Un motif qui s'est répété trois fois, à surveiller

Trois fonctionnalités de ce dépôt étaient **complètes et inertes** : du code correct, testé pour
deux d'entre elles, mais qui n'atteignait jamais l'utilisateur.

| Fonctionnalité | Pourquoi elle ne servait à rien |
|---|---|
| Confiance par axe | `toJson` l'écrivait, `fromJson` ne la relisait pas — perdue à chaque rechargement |
| Confiance par axe (suite) | Une fois persistée, elle n'était **affichée nulle part** |
| `syncCellarGrapes` | Aucun appelant, alors que le radar pondérait son résultat jusqu'à 3,3 points |

Aucun test unitaire ne pouvait les attraper : ils vérifiaient le calcul, pas le chemin jusqu'à
l'écran. C'est le test en direct sur émulateur qui les a révélées. À garder comme réflexe :
**après avoir écrit une fonctionnalité, vérifier qu'on la voit.**

### S3 — à faire EN PREMIER, avant le reste

Décidé par Flavien le 2026-09-17, avant toute autre chose dans S3.

**1. Tout doit être supprimable.** Aujourd'hui on ne peut pas supprimer une dégustation
depuis l'app — aucun `delete` sur `tasting_log` nulle part dans `lib/`. Une dégustation
saisie par erreur est donc définitive, sur tous les appareils, quoi qu'on fasse en base.
Le principe posé est général : **si l'utilisateur veut supprimer quelque chose, il doit
pouvoir le faire.** À passer en revue sur tous les objets — dégustations, bouteilles,
caves, profils de goût, remontées, photos.

**2. Le bucket des captures reste public.** L'identifiant utilisateur a été retiré des URL
et des messages (`ae932c3`), mais n'importe qui avec le lien accède encore aux captures.
Le rendre privé demande une fonction de signature d'URL, sans quoi le dépouillement des
remontées devient impossible.

### Deux demandes produit, même date

**Réordonner la fiche d'un vin.** Aujourd'hui la valeur marchande arrive avant tout le
reste. L'ordre voulu : d'abord les **actions** — service et conseils de dégustation —
puis la **description**, puis l'**apogée** et le **terroir**. Ce qu'on fait avec la
bouteille avant ce qu'elle vaut.

**Sortir une bouteille pour l'offrir.** Un troisième motif de sortie, à côté de
« consommée » et « perdue » :

- au moment d'offrir, choisir entre **sauter toute la dégustation** ou la **reporter**,
  au cas où la personne l'ouvre en notre présence ;
- si elle est offerte, proposer d'**enregistrer à qui**.

C'est aussi ce qui manque pour que `source_type = 'gift'` ait un pendant en sortie : on
sait recevoir un cadeau, on ne sait pas en faire un.

---

Puis le reste de **S3** (QR cassé, `table_sessions`, onglet Restaurant, pont cave ↔ restaurant),
**S3 bis** (conversion du compte anonyme), **S4** (comptoir, moteur de frontière, empreinte de
palais), **S5** (ratio revenu pub ÷ coût IA).

Le détail de chaque étape est dans le plan.

---

## Repasser la main à Antigravity

1. Lire ce fichier de haut en bas — la section sécurité en premier.
2. Le `CLAUDE.md` du dépôt indique le mode en cours. Le remettre en lecture seule si l'on
   souhaite repasser en audit.
3. Les commits de Claude sont signés `Co-Authored-By: Claude Opus 5`. `git log --author` ou un
   filtre sur ce trailer permet d'isoler exactement ce qui a été fait ici.
4. Rien n'a été fait en dehors du dépôt : aucune clé n'a été tournée, aucun service tiers touché,
   aucun secret manipulé. Ces actions sont restées et restent à Flavien.

---

## Journal

| Date | Qui | Quoi | Commit |
|---|---|---|---|
| 2026-09-14 | Claude | Audit complet (4 documents) et plan V2 « Au comptoir » | — |
| 2026-09-14 | Claude | Checkpoint du travail Antigravity, neutralisation des secrets, purge de 104 Mo d'assets morts | `18f111e` + tag `v1.3.4+67` |
| 2026-09-14 | Claude | S0 : retrait du contournement d'auth `/admin`, rôle admin vérifié côté serveur, migration 029 | `6446350` |
| 2026-09-14 | Flavien | Désactivation des clés legacy Supabase — token `service_role` fuité neutralisé (vérifié 401) | — |
| 2026-09-15 | Flavien + Claude | Rotation de la clé Gemini. Première tentative en panne (clé `AQ.` d'un projet GCP neuf refusée par Google) ; résolue avec une clé `AIza` d'AI Studio. Fonction edge vérifiée HTTP 200 | — |
| 2026-09-15 | Claude | Correction du deadlock d'authentification signalé par une utilisatrice (dialogue de pseudo inéchappable + OAuth sans `select_account`) | `cbc89ac` |
| 2026-09-15 | Claude | Découverte de la dérive des migrations et de la fuite des logs de diagnostic ; migration 030 écrite | ce commit |
| 2026-09-15 | Claude | S2 : apprentissage symétrique, moyenne exponentielle, confiance par axe | `799b35b`, `280034c`, `670356e` |
| 2026-09-16 | Claude | **Cause racine de l'échelle des notes** : 027 jamais appliquée, toutes les notes divisées par deux à l'écriture. Migration 032 réécrite (plus de procédure manuelle) | `5ae7856` |
| 2026-09-16 | Claude | Niveau « Gorgée » hors-cave, défauts traduits dans les 13 locales, sérialisation de la confiance par axe réparée | `a103edd` |
| 2026-09-16 | Claude | Inventaire de cave branché (cadeaux et supermarché exclus) ; débordement des libellés du radar corrigé | `a692927`, `0fe16da` |
| 2026-09-16 | Claude | **Le radar admet ce qu'il ignore** : halo d'incertitude + phrase de confiance, traduits dans les 13 locales | `d847ed7` |
| 2026-09-16 | Claude | Déduction d'échelle affinée pour ne pas doubler les dégustations restées en cache local | `46a8972` |
