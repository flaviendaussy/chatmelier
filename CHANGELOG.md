# Journal des Modifications (CHANGELOG) — Chatmelier

Toutes les modifications notables apportées au projet Chatmelier sont consignées dans ce document selon la norme [SemVer](https://semver.org/lang/fr/) et les directives de `VERSIONING_AND_RELEASE_RULES.md`.

## [v1.3.2+65] — 2026-09-13

### 🍷 Ce qui change pour vous / What's New for You
- **🎬 Cérémonie Vidéo du Chatmelier & Révélation des Badges** :
  - Intégration cinématographique du Chatmelier dévoilant ses médailles brodées sous son gilet de sommelier en velours bordeaux.
  - Lecteur vidéo immersif avec halo or champagne, commandes de lecture/pause, sourdine et boucle continue.
  - Accessible directement depuis la célébration de déblocage ou depuis chaque fiche de badge de la galerie.
- **🏆 Expérience Gamifiée & Pop-up de Célébration Sommelière** :
  - Nouvelle célébration animée haute définition lors du déblocage d'un badge : halo tournant or sommelier, rayons d'effervescence champagne et retours haptiques subtils.
  - Possibilité de rejouer la célébration à tout moment depuis la galerie des badges.
- **🍾 Moteur de Flacons Contributeurs (Zéro-Bloat)** :
  - Découvrez exactement quelles bouteilles ou dégustations ont débloqué chaque badge.
  - Volet coulissant avec recherche instantanée et pagination optimisée, conçu pour rester ultra-fluide même avec 500+ flacons.
- **⚙️ Contrôle Total des Animations** :
  - Option *"Ne plus afficher ces animations"* directement accessible sur la pop-up de célébration.
  - Interrupteur dédié dans les Réglages du Profil pour activer ou désactiver les célébrations à volonté.

### 🛠️ Notes Techniques (Développeurs)
- *Vidéo & Multimédia (`chatmelier_badge_video_dialog.dart`, `video_player`)* : Ajout du package `video_player: ^2.9.2`, configuration du contrôleur d'assets vidéo `assets/videos/chatmelier_badge_reveal.mp4` avec boucle, mute, gestion d'erreurs et aspect ratio dynamique.
- *Célébration (`badge_unlock_celebration_dialog.dart`, `badge_unlock_tracker.dart`)* : Moteur de suivi persistant dans `SharedPreferences` (`chatmelier_badge_celebration_animations_enabled`), détection sélective des nouveaux déblocages, prévention des alertes multiples lors de la première installation.
- *Flacons contributeurs (`badge_evaluator.dart`)* : Récolte et conservation des `contributingItems` (titre du vin, millésime, appellation, catégorie) lors de l'évaluation des badges.
- *Réglages (`profile_screen.dart`)* : Synchronisation de l'état d'animation des badges avec persistance locale instantanée.

---

## [v1.3.1+64] — 2026-09-13

### 🍷 Ce qui change pour vous / What's New for You
- **🏅 Catalogue Complet des 119 Badges Sommelier** :
  - Intégration à 100% des médaillons 3D sculptés en bas-relief générés par Gemini en WebP haute définition.
  - Nouveaux badges d'élite : *Dolce Vita Amaretto*, *Flight Découverte*, *Le Dernier Trait* (niveau bouteille $\le 25\%$), *Maître de Table* (consensus de groupe), *Alchimiste du Chenin*, *L'Exotisme Épicé* (Gewurztraminer), *Collectionneur de Grands Crus*, et *Cave Patrimoniale* (500+ flacons).
- **🧪 Évaluateurs Métier Connectés** :
  - Détection automatique des marques emblématiques (Disaronno pour l'Amaretto, spiritueux rares, accords mets-vins).

---

## [v1.2.2+62] — 2026-09-13

### 🍷 Ce qui change pour vous / What's New for You
- **Protection de la Vie Privée & Sélecteur de Photos Système Android** :
  - Suppression intégrale des demandes d'accès à l'ensemble de votre galerie (`READ_MEDIA_IMAGES` / `READ_EXTERNAL_STORAGE`).
  - L'importation d'étiquettes de bouteilles et de menus s'effectue exclusivement via le Sélecteur de Photos sécurisé natif d'Android (aucun accès persistant à vos photos privées).

### 🛠️ Notes Techniques (Développeurs)
- *Manifest Android (`AndroidManifest.xml`)* : Suppression de `READ_MEDIA_IMAGES` et `READ_EXTERNAL_STORAGE`. Conformité totale avec le règlement Google Play Console relatif aux autorisations de photos et vidéos (utilisation du système Photo Picker d'Android via `image_picker`).

---

## [v1.2.2+61] — 2026-09-13

### 🍷 Ce qui change pour vous / What's New for You
- **Radar de Goûts Personnalisé à 8 Axes Orthogonaux** :
  - Décomposition haute précision de votre profil œnologique (Structure tannique, Densité, Boisé/Élevage, Fruit solaire, Épices/Sauvage, Fruit croquant, Minéralité, Tension/Vivacité).
  - Élimination des profils jumeaux : les amateurs de vins denses et épicés (ex: Cornas, Bandol) et de vins vifs et minéraux (ex: Chablis, Sancerre) ont désormais des radars géométriquement très distincts.
- **⚡ Dégustation Express en 3 Micro-Taps (< 5s)** :
  - Qualification instantanée sans interrompre le repas : Toucher de bouche (Soyeux, Vif, Dense) et Éclat du fruit (Croquant, Profond, Épicé).
  - Profilage implicite passif : vos ajouts en cave et en liste d'envies calibrent automatiquement votre palais sans questionnaire redondant.
- **🌐 Expérience Multilingue Authentique (13 Langues à 100%)** :
  - Complétude absolue (551 clés par langue) sur les 13 langues officielles avec terminologie sommelière certifiée (J.S.A., AIS, etc.).
  - Zéro terme anglais résiduel dans les écritures non-latines (japonais, chinois, coréen).
- **🎨 Identité Webapp & Écran de Chargement** :
  - Remplacement du verre de vin par le logo officiel Chatmelier avec pulsation dorée élégante dès le premier affichage.

### 🛠️ Notes Techniques (Développeurs)
- *Localisation (`app_*.arb`)* : Synchronisation de 551 clés sur les 13 locales, validation par la suite `translation_proximity_and_l10n_test.dart` avec hachage inter-familles linguistiques et intégrité ICU.
- *Profil & Radar (`wine_taste_radar_metrics.dart`, `taste_profile_service.dart`)* : Implémentation du radar à 8 axes, distance euclidienne normalisée, tests de non-gémellité Flavien vs Caro.
- *Webapp (`index.html`, `404.html`)* : Intégration de `logo_transparent.png`, balise `preload` et styling CSS optimisé.

---

## [v1.2.2+56] — 2026-09-11

### 🍷 Ce qui change pour vous / What's New for You
- **Sortie de Cave Épurée & Décisionnelle (Zero Clutter)** :
  - Fin des cartes empilées : l'écran de sortie de cave propose désormais 2 blocs de décision clairs et lisibles (Dégustation immédiate vs Outils de sortie rapide).
- **Expérience de Dégustation Multi-Personas** :
  - **⚡ Format Express (30 secondes chrono)** : Formulaire fluide sur une seule page scrollable pour noter un vin sans interrompre la fête ou l'apéro.
  - **🎓 Format Sommelier (5 étapes guidées)** : Analyse sensorielle complète (œil, nez, bouche, persistance, verdict).
  - **🧐 Arômes sur-mesure pour palais pointilleux** : Possibilité d'ajouter des descripteurs précis libres (`Sous-bois`, `Garrigue`, `Pivoine`...) récompensés par le moteur d'acuité.
  - **ℹ️ Démystification des Caudalies** : Infobulle explicative simple au niveau du curseur de longueur (1 caudalie = 1 seconde de plaisir en bouche).
  - **🍽️ Accord & Synergie Mets-Vin** : Évaluation directe de l'alchimie du vin avec le repas (`Sublimé`, `Harmonieux`, `Neutre`, `Conflit`).
- **Nouveaux Badges Régionaux Illustrés par IA** :
  - ⚔️ **Chevalier du Rhône** : Médaillon d'argent, armure médiévale et coteaux escarpés du Rhône.
  - 🌿 **Poète du Val de Loire** : Château Renaissance, pierre de tuffeau et Chenin doré.

### 🛠️ Notes Techniques (Développeurs)
- *Checkout (`checkout_screen.dart`)* : Réduction de la complexité visuelle à 2 blocs primaires, routage direct vers le mode Express ou Sommelier.
- *Questionnaire (`tasting_questionnaire_sheet.dart`, `tasting_questionnaire_result.dart`)* : Support du mode `isExpressMode`, champs `customAromas` et `foodPairingSynergy`, constructeur `fromJson` avec rétrocompatibilité totale.
- *Moteur d'acuité (`tasting_pedagogy_engine.dart`)* : Détection et valorisation des arômes libres dans le calcul du score sensoriel.
- *Catalogue de badges (`badge_catalog.dart`)* : Intégration des assets 512x512 WebP & PNG pour `region_rhone` et `region_loire`.

---

## [v1.2.1+50] — 2026-09-11

### 🍷 Ce qui change pour vous / What's New for You
- **Finalisation de la Localisation Anglaise Complète (Complete English Experience)** :
  - **Bar & Cocktails** : Traduction intégrale de la fiche détaillée des cocktails (verrerie, méthode, glaçons, portions, dosages cuisine maison, shaker vs bocal hermétique, conseils du mixologue, garnitures), du dialogue de personnalisation de recettes, et du garde-manger du bar (tous les ingrédients et unités de mesure).
  - **Statistiques & Valorisation** : Traduction des sélecteurs de périmètre (« All my cellars (Overall) »), graphiques de répartition par couleur/région/millésime, barres de progression de maturité (« Aging & Young », « At Peak », « Drink Soon », « Past Peak »), conseils et insights du sommelier, tranches de valorisation, et carte interactive des terroirs.
  - **Navigation & Barre d'Actions Web/Desktop** : Actions rapides (« Furniture & Shelves », « Voice Sommelier », « Taste / Checkout wine », « Taste Out of Cellar », « World Terroirs Map »), sélecteur de cave (« My Wine Cellars »), gestion des accès (« Owner », « Read & Write », « Read-only »), menus d'options et boîtes de confirmation.
  - **File d'attente hors-ligne & Synchronisation** : Écran « Pending actions » entièrement bilingue (types d'actions, statut de synchronisation, messages d'erreurs et purge).
- **Sécurisation Maximale de l'API Gemini** :
  - Éradication absolue de toute clé API codée en dur dans le code source client et les fonctions Cloud.
  - Toutes les requêtes AI passent exclusivement par les variables d'environnement / secrets Supabase sans fuite sur le bundle public JavaScript.

### 🛠️ Notes Techniques (Développeurs)
- *Localisation (`cocktail_detail_sheet.dart`, `save_cocktail_dialog.dart`, `bar_cocktails_hub_screen.dart`, `stats_screen.dart`, `adaptive_app_shell.dart`, `cellar_switcher_sheet.dart`, `pending_actions_sheet.dart`)* :
  - Conditionnement dynamique précis basé sur `isFr = Localizations.localeOf(context).languageCode == 'fr'`.
  - Passage en `Wrap` adaptatif sur l'en-tête cocktail pour éliminer tout débordement de mise en page.
- *Résilience & Parsing Hors-Ligne (`tasting_ai_assistant_service.dart`)* :
  - Extraction automatique par expression régulière des notes dictées (ex: « 8.5 sur 10 ») en mode hors-ligne sans dépendance à l'API externe.
- *Sécurité API (`constants.dart`, `gemini_model_registry.dart`, `scan-label/index.ts`)* :
  - Purge des clés compromises et bascule sur des valeurs par défaut vides.

---

## [v1.2.1+49] — 2026-09-07

### 🍷 Ce qui change pour vous / What's New for You
- **Localisation Intégrale en Anglais (Full English Localization)** : Lorsque vous choisissez l'anglais dans les réglages (ou sur un appareil configuré en anglais), l'ensemble de l'application est désormais traduit dans un anglais œnologique authentique et naturel.
- **Toutes les sections traduites** :
  - **Cave / Cellar** : Tri (« Vintage », « Estimated Value », etc.), groupements (« Type / Color », « Maturity / Peak », etc.), filtres (« Furniture & Shelves », « Pair wine with dish », « Favorites », etc.), puces d'étagères, menus d'actions, et bannière de valorisation.
  - **Fiche Bouteille / Bottle Details** : Carte d'évaluation, fenêtre de garde et d'apogée, accords mets & vins, conseils de service et carafage, notes techniques de vinification, terroirs et histoire, gestion des stocks et mouvements.
  - **Bar & Cocktails** : Ingrédients du bar (Glaçons, Agrumes, Herbes, Mixers, Sirops, etc.), filtres du bar et du catalogue, tri et recherche, équipement du barman et alternatives maison (Shaker, Jigger, Passoire, Pilon, Cuillère).
  - **Carnet de Dégustation / Journal** : Cartes et filtres de dégustation (« My Cellar », « Out-of-Cellar », « Favorites », « Top Rated »), badges œnologiques et progression, options de dégustation rapide et raccourcis.
  - **Profil Utilisateur / Profile** : Onglets (« Palate », « Settings », « Tools », « Account »), radar de profil gustatif, export de cave CSV/PDF, gestion des amis et préférences.
- **Traductions dynamiques instantanées** : Le basculement de langue met à jour instantanément tous les écrans, boîtes de dialogue et fiches sans nécessiter de redémarrage.

### 🛠️ Notes Techniques (Développeurs)
- *Localisation dynamique (`cellar_screen.dart`, `bottle_detail_screen.dart`, `bar_cocktails_hub_screen.dart`, `journal_screen.dart`, `profile_screen.dart`)* :
  - Support systématique de `isFr = Localizations.localeOf(context).languageCode != 'en'` sur toutes les vues de présentation.
  - Découplage des clés de filtres internes (`all`, `ready`, `almost`, `custom`, `gin`, `rhum`, etc.) des libellés affichés.
- *Modèles de domaine localisés (`bottle.dart`, `cellar_sort_by.dart`, `cellar_group_by.dart`, `cellar_furniture.dart`, `bar_pantry_item.dart`)* :
  - Ajout des méthodes `localizedLabel(bool isFr)`, `getLocationSummary(bool isFr)`, `getProvenanceDisplay([bool isFr])`, `describeSlotCode(code, [bool isFr])`, et `label([bool isFr])`.
- *Validation et Tests (`multi_language_dynamic_switching_test.dart`)* :
  - Couverture complète des 12 langues supportées, des enums de tri et groupement, et des descriptions d'emplacements.

---

## [v1.2.1+48] — 2026-09-07

### 🍷 Ce qui change pour vous
- **Accès direct « Meubles & Rayonnages » sur Ordinateur & Mobile** : Un bouton dédié « Meubles & Rayonnages » est désormais directement accessible dans la barre latérale sur grand écran (ordinateur) et dans la barre de filtres principale de la cave. Plus besoin de chercher dans les sous-menus de l'en-tête !
- **Synchronisation automatique des deux domaines Web** : Les deux adresses web officielles (`chatmelier.github.io` et `flaviendaussy.github.io`) sont désormais rigoureusement synchronisées à la même version, évitant tout décalage d'affichage selon le lien utilisé.
- **Purge automatique du cache navigateur** : L'application web invalide et recharge automatiquement ses composants (scripts principaux et cache de service) pour garantir que vous ayez toujours la dernière version sans manipulation manuelle de l'historique du navigateur.

### 🛠️ Notes Techniques (Développeurs)
- *Ergonomie Desktop & Cave (`adaptive_app_shell.dart`, `cellar_screen.dart`)* :
  - Ajout de `_SidebarActionItem` avec `Icons.shelves` dans les « ACTIONS RAPIDES » du shell Bureau / Desktop.
  - Ajout d'une `ActionChip` dorée « Meubles & Rayonnages » dans `_buildFilterRow` de `CellarScreen`.
- *PWA & Cache-Busting (`app/web/index.html`, `build_and_sync_web.sh`)* :
  - Désenregistrement automatique des anciens Service Workers et purge des caches `CacheStorage` dans l'en-tête HTML.
  - Injection dynamique d'un suffixe d'invalidation d'URL `main.dart.js?v=${VERSION}-${BUILD_TIME}` dans `flutter_bootstrap.js`.
- *Déploiement Dual-Domain (`build_and_sync_web.sh`)* :
  - Déploiement automatique vers `chatmelier.github.io` (`Chatmelier/chatmelier.github.io.git`) et vers `flaviendaussy.github.io` (`user-pages`) à chaque build.

---

## [v1.2.1+47] — 2026-09-07

### 🍷 Ce qui change pour vous
- **Affichage instantané des meubles & emplacements sur la Web App** : Résolution du délai d'affichage et du cache navigateur mobile : lorsque vous rangez une bouteille dans un meuble ou une étagère, l'emplacement apparaît immédiatement et ne reste plus bloqué sur "Ranger dans un meuble".
- **Libellés naturels « Étagère 1, 2... » pour les placards** : Les étagères libres ne sont plus affichées sous la forme de coordonnées matricielles (A1, A2...) mais avec un libellé clair et naturel (« Étagère 1 », « Étagère 2 »).
- **Puces d'emplacements dans la cave** : Les filtres et résumés d'emplacements dans la cave prennent désormais en compte les meubles et leurs étagères au lieu de classer les bouteilles en « Non classé ».
- **Cache-Busting Web PWA** : Chargement systématique de la dernière version de l'application web sans rétention de vieux fichiers par le cache du navigateur mobile.

### 🛠️ Notes Techniques (Développeurs)
- *Synchronisation Offline & Cache (`cellar_repository.dart`, `offline_storage_service.dart`, `bottle_detail_screen.dart`)* :
  - `applyOfflineUpdateBottle` intègre désormais `furniture_id` et `furniture_slot`.
  - `assignBottleToSlot` et `getBottleById` synchronisent instantanément les modifications dans le cache local hors-ligne.
  - `_loadBottleDetails` met à jour le cache local dès réception de la réponse Supabase.
- *Web PWA Cache-Busting (`app/web/index.html`, `index.html`, `404.html`)* :
  - Chargement dynamique de `flutter_bootstrap.js` avec paramètre d'invalidation de cache `?v=`.
- *Résumé d'emplacements (`cellar_screen.dart`)* :
  - `_buildLocationSummaryChips` intègre désormais les identifiants et libellés de meubles et étagères.

---

## [v1.2.1+46] — 2026-09-07

### 🍷 Ce qui change pour vous
- **Placard & Étagères libres sans largeur ni contrainte** : Le mode « Placard / Rangement libre » n'impose plus aucune largeur ni nombre de colonnes ni de min/max de bouteilles. Vous choisissez uniquement votre nombre d'étagères/niveaux, et chaque niveau accueille vos bouteilles en toute liberté et sans limite de quantité.
- **Aperçu visuel épuré du placard** : L'éditeur de meuble affiche directement des étagères ouvertes en bois sans alvéoles rigides, illustrant parfaitement le rangement en vrac de style placard de cuisine.
- **Emplacement visible en vue liste** : Dans la liste de vos bouteilles, l'emplacement en meuble ou étagère s'affiche désormais instantanément avec l'icône de repère géographique.
- **Synchronisation & Déploiement Web App** : Recompilation complète de la Web App et synchronisation directe des fichiers de déploiement en ligne.

### 🛠️ Notes Techniques (Développeurs)
- *Éditeur de Meuble (`furniture_editor_dialog.dart`)* :
  - Masquage intégral des contrôles de largeur/colonnes pour le type `cupboard`. Colonne fixée à 1 et étagères configurables de 1 à 14.
  - Suppression de l'affichage de capacité par case ; affichage de la mention « Capacité libre & indéfinie ».
  - Rendu d'aperçu spécifique en étagères horizontales ouvertes sans colonnes A/B/C ni grilles de cases.
- *Vue Liste Bouteille (`bottle_list_item.dart`)* :
  - Utilisation de `bottle.hasLocation` et de `bottle.locationSummary` pour garantir la visibilité des rangements meubles et étagères au même titre que les coordonnées manuelles.

---

## [v1.2.1+45] — 2026-09-07

### 🍷 Ce qui change pour vous
- **Correction de l'import Excel / CSV** : Résolution de l'erreur SQL `invalid input syntax for type uuid: "import-excel"` qui empêchait l'accès à l'outil d'importation.
- **Affichage fiable de l'emplacement et du meuble** : Vos bouteilles rangées affichent immédiatement et sans délai leur meuble, leur étagère ou case ainsi que le schéma visuel dès l'attribution.
- **Bouton « Retirer du meuble » & « Déplacer » fluides** : Possibilité de retirer une bouteille d'un meuble en un clic pour la remettre en stockage libre, ou de la déplacer instantanément vers un autre meuble.
- **Repères de cave dans la liste de vos vins** : Vos cartes de vins dans la vue principale indiquent désormais aussi l'étagère ou l'alvéole de chaque bouteille.

### 🛠️ Notes Techniques (Développeurs)
- *Routing (`router.dart`)* :
  - Déplacement de la route `/cellar/import-excel` avant `/cellar/:id` pour éviter la capture erronée du chemin littéral par le paramètre d'URL dynamique. Ajout de l'alias direct `/cellar-import-excel`.
- *Fiche Bouteille (`bottle_detail_screen.dart`)* :
  - Injection des attributs `furnitureId`, `furnitureSlot`, `purchaseLocation`, `sourceType`, `sourceDetails`, `bottleSize`, etc., lors de la reconstruction de `bottleObj` et dans le repli hors-ligne.
  - Rafraîchissement automatique de la vue via `await _loadBottleDetails()` dès la fermeture de `ShelfGridViewSheet`.
  - Intégration du bouton et dialogue de désassignation (`onUnassignRequested`).
- *Composants UI (`furniture_graphic_card.dart`, `bottle_card.dart`)* :
  - `FurnitureGraphicCard` gère élégamment le cas où le meuble est en cours de chargement avec un repli textuel enrichi.
  - `BottleCard` affiche la localisation (étagère ou slot) sur chaque carte de la grille de cave.

---

## [v1.2.1+44] — 2026-09-07

### 🍷 Ce qui change pour vous
- **Nouveau meuble « Placard / Rangement libre »** : Vous pouvez désormais créer des meubles sans alvéoles strictes (comme un placard de cuisine ou une étagère verticale) où les bouteilles se déplacent librement et coexistent sur chaque niveau sans conflit de place ni alerte de collision.
- **Graphique visuel du meuble dans la fiche vin** : Chaque fiche de vin affiche désormais un rendu graphique immersif de son meuble (armoire avec étagères en bois ou casier matriciel avec halo doré sur l'emplacement) accompagné du détail sommelier textuel clair.
- **Correction d'affichage de l'emplacement** : Finie l'invitation permanente *"Ranger dans un meuble"* qui s'affichait même lorsque votre bouteille avait déjà un emplacement défini.

### 🛠️ Notes Techniques (Développeurs)
- *Cellar Furniture & Domain (`cellar_furniture.dart`, `bottle.dart`)* :
  - Ajout du type de forme `shapeCupboard = 'cupboard'` et du getter `isCupboard`.
  - Prise en charge des codes d'étagères sans collision et description sommelier des rangements libres.
  - Ajout des getters unifiés `hasLocation` et `locationSummary` sur `Bottle`.
- *UI (`furniture_graphic_card.dart`, `bottle_detail_screen.dart`, `shelf_grid_view_sheet.dart`)* :
  - Création du widget dédié `FurnitureGraphicCard` avec visualisation adaptative (étagères de placard avec capsules colorées ou grille 2D avec alvéole pulsante).
  - Conditionnement de l'état vide dans `BottleDetailScreen` par `bottleObj.hasLocation`.
  - Vue `_buildCupboardView` avec dépôt direct par étagère sans modale de Swap.

---

## [v1.2.0+43] — 2026-09-06

### 🍷 Ce qui change pour vous
- **Médailles & Badges Chatmelier illustrés** : 31 de vos plus beaux badges arborent désormais leur illustration exclusive réalisée sur-mesure dans l'univers visuel du Chatmelier (médaillons ciselés de pampres de vigne, tenue de sommelier et verres de dégustation dédiés).
- **Attribution des badges 100% fidèle à votre cave** : Fini les faux déblocages ! Le calcul des badges distingue désormais rigoureusement vos vins authentiques de vos spiritueux et liqueurs, élimine les doublons de comptage et valide avec une précision œnologique chaque région, cépage et palier d'apogée.
- **Historique et dégustations harmonisés** : Vos notes de dégustation alimentent désormais avec une parfaite justesse votre profil œnologique et vos succès de dégustateur.

### 🛠️ Notes Techniques (Développeurs)
- *Badges System (`badge_evaluator.dart`, `badge_catalog.dart`)* :
  - Implémentation du discriminateur strict `_isWine` éliminant les faux positifs sur les spiritueux et liqueurs (e.g. Gin, Vodka, Pisco, Liqueurs de plantes, Crèmes de fruits enregistrées en vin fortifié).
  - Déduplication rigoureuse des bouteilles et dégustations par `matchedWineIds` et `matchedWineNames` pour éviter tout double-comptage.
  - Remplacement des recherches par sous-chaîne (`cot` pour Malbec, `voile` pour l'élevage sous voile, `nature` pour Pasteur) par des expressions complètes et rigoureuses.
  - Intégration de 31 illustrations haute résolution WebP 512x512 dans `assets/badges/` et enregistrement dans `BadgeCatalog`.
- *Qualité & Tests* :
  - 353 tests unitaires et d'intégration validés avec succès (`flutter test`).

---

## [v1.2.0+42] — 2026-09-05

### 🍷 Ce qui change pour vous
- **Journal de Dégustation fidèle** : Vos dégustations enregistrées (comme votre dernière bouteille dégustée hier soir) s'affichent désormais immédiatement dans votre historique, avec leur note exacte sur 10/10 (fini le 5/10 par erreur pour un 10/10 mérité !).
- **Interface de Cave épurée et aérée** : L'accès "Quel vin pour mon plat ?" est désormais direct en haut de cave. Les boutons redondants ont été retirés pour laisser tout l'espace nécessaire au nom de vos caves (comme "Londres" visible en entier).
- **Onglet "Degust." et recherche optimisée** : L'onglet de l'historique s'appelle désormais "Degust." et la loupe de recherche se place idéalement à gauche des sélecteurs pour les vins, spiritueux et cocktails.
- **Fluidité des annonces** : L'annonce d'ouverture s'affiche désormais proprement au lancement de l'application et ne vous interrompt plus lorsque vous déverrouillez simplement votre téléphone.

### 🛠️ Notes Techniques (Développeurs)
- *Monetization (`admob_service.dart`, `app.dart`)* :
  - `preloadAppOpenAd` retourne désormais un `Future<bool>` piloté par un `Completer<bool>` pour permettre un `await` sécurisé.
  - Implémentation de `showAppOpenAdOnLaunch(timeout: 2.5s)` évitant l'échec de la vérification initiale de 50ms sur démarrage à froid.
  - Ajout des écouteurs `onPause` et `onHide` avec enregistrement de `_lastPausedTime`. Conditionnement de `onResume` à une absence en arrière-plan d'au moins 30 secondes pour bloquer l'affichage au simple verrouillage/déverrouillage d'écran.
- *Journal & Tasting (`tasting_entry.dart`, `journal_screen.dart`, `sync_service.dart`)* :
  - Normalisation unifiée de la note via les getters `displayRating` (remise à l'échelle 0..10 si <= 5.0) et `formattedRating`.
  - Intégration de la lecture de secours des colonnes plates (`wine_name`, `vintage`, `region`, etc.) dans `TastingEntry.fromJson` pour le parsing direct de la file hors-ligne.
  - Fallback automatique dans `_resilientInsertTastingLog` en cas d'erreur de schéma `PGRST204` sur les colonnes étendues (`bottle_owner_id`), avec sauvegarde immédiate dans le cache local `addCachedTasting`.
- *UI & Navigation (`cellar_screen.dart`, `cocktails_screen.dart`, `main_screen.dart`)* :
  - Suppression de l'AppBar supérieure de cave : retrait de l'icône profil, des 3 points et du bouton de statistiques redondant avec la barre inférieure.
  - Sélecteur de cave agrandi en largeur dynamique sans contrainte de troncature.
  - Bouton "Quel vin pour mon plat ?" placé en bannière d'accès direct en haut de cave.
  - Raccourci recherche positionné à gauche du toggle "Vins / Spiritueux" et ajusté dans le module cocktails.
  - Renommage de l'onglet de navigation en "Degust.".
- *Tests & Qualité* :
  - 353 tests unitaires et widgets validés sans aucune régression (`flutter test`).

---

## [v1.2.0+41] — 2026-09-05
- Refonte des filtres de cave, ajout du système de badges de dégustation, support de l'export d'accords mets-vins et intégration initiale AdMob UMP.
