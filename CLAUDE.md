# Chatmelier — Règles pour Claude Code

## ✅ MODE EN COURS : EXÉCUTION (depuis le 2026-09-14)

La directive de lecture seule qui figurait ici a été **levée explicitement par Flavien** le
2026-09-14, au moment du handover Antigravity → Claude. Lire **`HANDOVER.md`** avant toute
chose : il contient le journal du passage de relais et un **incident de sécurité en cours**.

Le plan de travail de référence est le plan V2 « Au comptoir »
(`~/.claude/plans/super-et-j-aime-aussi-transient-quokka.md`) : S0 sécurité → S1 élagage →
S2 données du goût → S3 restaurant → S4 comptoir → S5 mesure.

### Garde-fous qui restent en vigueur

1. **`origin` est un dépôt PUBLIC** (`github.com/flaviendaussy/chatmelier`). Ne jamais committer
   de clé, de jeton ou de mot de passe. Les fichiers connus pour en contenir sont listés dans la
   section « Secrets » du `.gitignore` — ne pas les en retirer.
2. **Ne jamais manipuler de secrets réels** : rotation de clés, accès aux consoles Supabase /
   Google Cloud / Play Console relèvent de Flavien seul.
3. **Commit et push uniquement sur demande explicite.** Toujours vérifier `git status` et scanner
   les fichiers non suivis avant un `git add`.
4. **Ne pas casser la suite de tests** : 478 verts aujourd'hui, `flutter analyze` à 0 erreur.
   Vérifier les deux après chaque étape.

### Pour repasser en mode audit lecture seule

Remplacer cette section par l'ancienne directive (récupérable dans l'historique git de ce
fichier) et le signaler dans le journal de `HANDOVER.md`.

---

## 📐 Protocole d'audit (référence)

Ce qui suit est le protocole d'audit d'origine. Il reste utile comme grille de vérification et
comme définition des rôles, même en mode exécution.

---

## 🎯 PROTOCOLE D'INSPECTION & LIVE TESTING

### Étape 1 : Analyse Statique & Linting
- Se déplacer dans `app/` et exécuter `flutter analyze`.
- Noter les erreurs éventuelles, warnings, lints ou dépendances obsolètes.

### Étape 2 : Suite de Tests Automatisés en Console
- Exécuter la suite complète : `flutter test` dans `app/`.
- Exécuter et inspecter spécifiquement les tests critiques :
  * `flutter test test/features/menu_table_qr_persona_e2e_test.dart` (Flux sans compte, table consensus, scan QR).
  * `flutter test test/features/menu_flight_test.dart` (Moteur de parcours œnologiques / flights).
  * `flutter test test/features/scan_and_rewarded_ad_test.dart` (Cycle de scan et monétisation AdMob).
  * `flutter test test/features/menu_scan_test.dart` et `test/features/menu_matchmaker_test.dart`.
- Identifier les tests en échec ou les tests anormalement lents (> 5s).

---

### Étape 3 : 🎭 SIMULATION RÉELLE MULTI-PERSONAS & GROUPES CONVIVES EN CONSOLE

Tu dois te comporter comme de vrais utilisateurs avec des profils tranchés, et simuler des groupes réels utilisant simultanément l'application mobile et la webapp (via des commandes de tests unitaires, de widgets ou d'exécution en console Dart).

#### A. Incarne plusieurs Personas contrastés :
1. **Camille — L'Hostile aux Tanins (Mobile Web Safari, 0 compte)** :
   - Ne supporte aucune astringence, bois neuf ou tanins râpeux.
   - Rejoint la table via un QR code scanné au restaurant, saisit son prénom et sélectionne "Aversion aux tanins durs".
   - *Attendu* : Le système doit instantanément bannir ou fortement pénaliser les Madiran/Cahors/Bordeaux jeunes et lui recommander des Blancs tendus ou Rouges très soyeux (Fleurie, Pinot Noir).
2. **Maxime — Le Chasseur de Minéralité Tendu (Webapp Chrome Mobile)** :
   - Ne jure que par les Chablis, Sancerre, Muscadet ou Jura. Déteste les blancs boisés/beurrés.
   - Explore l'onglet *Carte des Vins* et les filtres de couleur.
3. **Arthur — Le Carnivore Puriste (App Android Native)** :
   - Commande une côte de bœuf saignante. Ne veut que des grands rouges puissants, corsés et structurés.
   - Utilise l'onglet *Accords Mets & Vins* avec la catégorie 🥩 Viande Rouge.
4. **Léa — La Novice Petit Budget (Mobile Web)** :
   - N'y connaît rien, cherche une bonne bouteille sous les 40 € sans se faire arnaquer.
   - Teste les filtres *⭐ Pépites & 🏷️ Bons Plans*.
5. **Julien — Le Sommelier Curieux / Geek (App iOS)** :
   - Veut découvrir un accord original et déguster un vol de plusieurs verres.
   - Teste l'onglet *Parcours Dégustation (Flights)* en format 3 verres et 5 verres.

#### B. Simule des Tables & Groupes Simultanés :
- **Scénario "La Table des Avis Divergents"** :
  * Réunis Arthur (Amateur de tanins puissants) et Camille (Aversion totale aux tanins).
  * Vérifie le comportement mathématique de `MenuTableMatcherEngine` : comment l'algorithme gère-t-il la variance et la pénalité d'aversion ? Trouve-t-il le vin de réconciliation idéal ?
- **Scénario "Interaction App Mobile Hôte + Webapp Invités"** :
  * L'hôte scanne un menu avec 15 vins sur l'app native et génère un QR code avec payload compressé (Base64Url + Gzip).
  * Deux invités ouvrent le lien simultanément sur la webapp sans compte.
  * Vérifie que le décodage dans `MenuTableSessionManager` résiste aux caractères tronqués, espaces dans l'URL ou absence de session serveur (fallback 100% autonome).

---

### Étape 4 : Audit d'Architecture, IA & Zéro-Compte
- Inspecter `app/lib/features/menu_scan/` et `app/lib/features/scan/`.
- Vérifier la gestion des erreurs réseau (timeouts, 429 rate-limit, fallback hors-ligne).
- Inspecter `app/lib/config/router.dart` : s'assurer que les routes publiques (`/table-consensus`, `/scan/menu`) ne déclenchent aucune redirection inattendue vers `/login`.
- Vérifier la disposition correcte de tous les contrôleurs dans `dispose()` pour prévenir les fuites mémoire.

---

### Étape 5 : 💡 AUDIT PRODUIT, MARKET-FIT & VALUE PROPOSITION ("Est-ce une bonne idée ?")

Prends du recul par rapport au code et analyse Chatmelier comme un **Lead Product Manager & Stratège Tech** :

1. **L'App est-elle une bonne idée face au marché ?**
   - Compare la proposition de valeur de Chatmelier face aux géants établis (Vivino, CellarTracker, Raisin, InVintory, Delectable).
   - Quel est son « super-pouvoir » différenciant ? (ex: Sommelier IA conversationnel temps réel, consensus de table multi-palais sans compte, scan de cartes de restaurant complètes avec vision multimodale).
   - Est-ce que le positionnement répond à une vraie douleur (ex: la panique devant une carte des vins complexe au restaurant ou l'oubli de bouteilles en cave qui meurent passées leur apogée) ?

2. **Ce qui ne sert à rien / Complexité inutile (Feature Bloat & Dette d'usage) :**
   - Identifie dans le code les fonctionnalités qui semblent superflues, trop complexes, gadget ou qui alourdissent l'expérience sans apporter de valeur prouvée.
   - Quelles sont les fonctionnalités que 95% des utilisateurs n'utiliseront jamais et qui mériteraient d'être élaguées ou masquées ?

3. **Ce qui manque cruellement / Ce qui pourrait être ajouté (High Impact & Viralité) :**
   - Quelles sont les fonctionnalités à fort effet "Whaou" ou à fort potentiel viral qui manquent encore ?
   - Exemples d'axes de réflexion :
     * Viralité sociale (partage de fiches de dégustation élégantes façon Spotify Wrapped / Instagram story).
     * Partenariats restaurant & QR codes permanents sur les tables.
     * Gestion d'estimation de valeur marchande de cave (cote iDealwine / Wine-Searcher).
     * Gamification & défis de dégustation à l'aveugle plus poussés.
     * Notifications d'apogée intelligentes et proactives.

---

### Étape 6 : 📋 LIVRABLE ATTENDU (RAPPORT D'AUDIT & STRATÉGIE PRODUIT COMPLET)

Rédige un rapport clair et exhaustif contenant :
1. **Score Global de Santé Technique (sur 100)** et **Score de Potentiel Produit / Marché (sur 100)**.
2. **Critique Produit & Stratégie Marché** :
   - Forces et différenciateurs majeurs.
   - Ce qui est gadget ou inutile (à supprimer ou simplifier).
   - Ce qui manque pour décoller (les 3 à 5 fonctionnalités killer recommandées).
3. **Bilan des Simulations Réelles (Personas & Groupes à table)** :
   - Retours d'expérience vécus par chaque profil (Camille, Maxime, Arthur, Léa, Julien).
   - Évaluation de la pertinence des recommandations sommeliers.
4. **Tableau des Vulnérabilités & Anomalies Techniques** :
   - `[P0 - Bloquant]`, `[P1 - Majeur]`, `[P2 - Mineur]`, `[P3 - Suggestion/Dette technique]`.
   - Fichier et ligne exacte concernée, impact utilisateur.
5. **Plan d'Action Priorisé & Propositions Techniques** (décrites pas à pas, sans les appliquer toi-même).
