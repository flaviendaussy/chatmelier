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

| Secret | Depuis | Commits | Action |
|---|---|---|---|
| **JWT `service_role` Supabase** | **2026-08-30** (15 jours) | `54a3707`, `976f320` | **Faire tourner la clé** dans le dashboard Supabase, puis auditer les journaux d'accès sur la fenêtre |
| **Clé API Gemini** `AQ.Ab8RN6…` | plus ancien | `df650a5`, `5697356`, `61776d5` | **Révoquer** dans Google AI Studio et regénérer |
| Mot de passe keystore (`storePassword`) | — | `a9febdb` | Changer le mot de passe du keystore |

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

## Suite prévue

**S0 (reste à faire)** — rotation des clés *(Flavien)* ; suppression des 43 Mo de PNG morts et
des variantes non `_square` des loaders (10 Mo) ; retrait des routes `/admin` et du
court-circuit `router.dart:79` ; remplacement de `isAdmin` (aujourd'hui « l'e-mail contient
*flavien* », `profile_screen.dart:1420,1535`) par un rôle vérifié côté serveur.

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

| Date | Qui | Quoi |
|---|---|---|
| 2026-09-14 | Claude | Audit complet, plan V2, commit de handover et neutralisation des secrets dans le dépôt |
