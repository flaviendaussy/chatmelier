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

## S0 — état

| Item | État | Où |
|---|---|---|
| Purge des assets morts (−104 Mo) | ✅ fait | `18f111e` |
| Neutralisation des secrets dans le dépôt | ✅ fait | `18f111e` |
| Retrait du court-circuit d'auth `/admin` | ✅ fait | `6446350` |
| Rôle admin vérifié côté serveur | ✅ code fait | `6446350` |
| Neutralisation du `service_role` fuité | ✅ fait le 2026-09-14 | clés legacy désactivées + vérifié 401 |
| **Application de la migration 029** | ⏳ **à faire** | `supabase/migrations/029_…sql` |
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

## Dette d'hygiène repérée, non traitée

- **`mcp-server/node_modules/` est suivi par git** : 4 293 fichiers, 2,2 Mo. La règle
  `node_modules/` du `.gitignore` est arrivée après le commit initial, donc ils restent suivis.
  `git rm -r --cached mcp-server/node_modules` suffit à les détacher — reporté pour ne pas noyer
  les commits de S0 dans 4 000 suppressions.
- **`supabase/supabase/.temp/`** : artefacts de la CLI Supabase, détachés et ignorés dans `18f111e`.

## Suite prévue

**S1** — fork `chatmelier-cocktails`, parcage badges/scratchcard, suppression voice et changelog,
correction du bug de pub récompensée (`review_screen.dart:110-138`).

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
