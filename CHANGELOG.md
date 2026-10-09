# Journal des Modifications (CHANGELOG) — Chatmelier

Toutes les modifications notables apportées au projet Chatmelier sont consignées dans ce document selon la norme [SemVer](https://semver.org/lang/fr/) et les directives de `VERSIONING_AND_RELEASE_RULES.md`.

## [v1.9.0+81] — 2026-10-09

> Remplace la 1.8.0+79 (jamais publiée sur le Play Store) : tout ce qu'annonce la 79 y est, avec en plus ce qui suit. Le site web reste en 1.8.1+80 jusqu'à sa prochaine publication (le partage de connexion coupait l'envoi).

### 🍷 Ce qui change pour vous
- **Demander à un ami de noter lui-même** : dans « Qui déguste ? », un ami qui a l'app porte « Lui demander de noter sur son téléphone ». Il reçoit le vin à noter, et vous ne répondez plus à sa place ; chez lui, « Noter ce vin » ouvre la dégustation avec le vin et vous parmi les convives.
- **Le lien d'une table s'ouvre dans l'app** (Android), avec votre prénom et votre palais, au lieu du site.
- **Texte agrandi du téléphone** : la cave, la fiche d'une bouteille, le profil et « Noter un vin bu dehors » ne débordent plus ; les titres et les boutons passent à la ligne.
- **La valeur de votre cave dans votre devise** : plus de livres additionnées à des euros sous « € » ; les prix s'écrivent « 24,50 € » en français, en espagnol et en italien.
- **Vos amis vous trouvent par votre pseudo**, même avec une photo de profil ; choisir son pseudo n'efface plus la photo.
- **Le domaine dans le journal** : sous le nom du vin, son domaine (« Côtes du Rhône Blanc — Domaine Jamet ») ; la recherche du journal le trouve aussi.

### 🛠️ Notes Techniques (Développeurs)
- *Migration 069* : `inviter_a_noter` (entre amis ou membres d'une même cave, le vin seul, trente par jour, une par ami et par vin dans le quart d'heure), notification `invitation_a_noter`. Base jetable : 047 → 069 verts.
- *Liens* : route `/table?t=`, filtre Android vérifié pour `chatmelier.github.io/table` (l'ancien `chatmelier.app/invite` visait un domaine inexistant), `/.well-known/assetlinks.json` (clé d'envoi ; clé de signature Play à ajouter), copie de `.well-known` dans `build_and_sync_web.sh`. iPhone : capacité « Associated Domains » à venir.
- *Grandes tailles de texte* : vérifié à 150 % et 200 % ; `FittedBox`, `Wrap` et `Expanded` là où ça débordait ; hauteur des cartes de la grille selon le texte ; en-tête du profil sorti de la barre (sa hauteur fixe écrasait le titre).
- *Profil* : `AvatarEtPseudo` (`meta://?u=…&avatar=…`), un seul envoi vers `profiles` sans les colonnes absentes, `OwnerAvatar` qui lit l'image rangée avec le pseudo.
- *Cave* : `valeurDesBouteilles` (cote en euros, prix d'achat dans sa devise, vers la devise du compte) ; `CurrencyHelper.formatPrice` à virgule décimale hors anglais.
- *Fiche* : les puces « Service » et « Terroir » traduites.

## [v1.8.1+80] — 2026-10-09

> Site web seulement (la page invité) : l'app Android et iPhone reste en 1.8.0+79.

### 🍷 Ce qui change pour vous
- **Rejoindre une table depuis le site marche à nouveau** : un invité arrivé sur un navigateur neuf restait à la porte (« serveur indisponible », le « pas de réseau » de Gianpaolo le 05/10). Il rejoint la table, voit les bouteilles et note les verres au comptoir ; tant que les sessions anonymes restent coupées, ses notes restent sur son téléphone, et la page le dit au lieu de promettre un code de reprise.

### 🛠️ Notes Techniques (Développeurs)
- *Page invité* (`web/table/table.js`) : les connexions anonymes sont coupées en production (`/auth/v1/settings` : `anonymous_users: false` ; journaux : refusées depuis au moins le 29/09). Un refus 422 de `signup` devient `SansSession`, retenu six heures ; `rpc(…, { connecte: true })` passe alors par la clé publique, que `join_table_session` accepte (`user_id` nul) ; journal, code de reprise et mesure J6 se taisent, textes « sans compte » dans les quatre langues.

## [v1.8.0+79] — 2026-10-08

> La 1.7.0+78 n'a pas été publiée seule : la 79 la contient, avec en plus ce qui suit. Version affichée 1.8 (le récit du vin, la prise en main, la dégustation pour un ami et le plat à table sont des nouveautés à part entière).

### 🍷 Ce qui change pour vous
- **« À prix égal, je prendrais celui-ci »** (idée de Robin) : sur une carte, entre vins de même couleur au même prix, le sommelier désigne celui qui ira le mieux à vos goûts, s'il en devance vraiment un autre ; « % pour vous » remplace « % Match ».
- **Ce que vous mangez compte à table** : chacun choisit son plat (viande rouge, poisson, volaille, fromage, pâtes, dessert), sur la page invité comme dans l'app ; il pèse pour un tiers dans son vote, ses goûts restent l'essentiel. L'hôte dit le sien en touchant son nom.
- **L'histoire du vin, à la demande** : « Récit Audio » écrit le récit d'un vin quand vous le demandez, appuyé sur des pages que l'app cite (« Sources ») ; sans réseau, un récit simplifié qui ne dit que ce que la fiche et l'appellation garantissent. Lu par la voix du téléphone, dans la langue de l'app.
- **Une dégustation notée pour vous par un ami arrive « à accepter »** : une notification (« Caro a noté avec vous Bardos Reserva 2020 »), Refuser ou Ajouter à mon journal ; rien n'entre dans votre journal sans votre accord, et une bouteille défectueuse ne touche pas à votre palais.
- **Vos amis** : leur carte de goût montre enfin leur palais ; ils sont proposés dans la superposition du radar ; « Retirer » un proche de vos profils.
- **Prise en main** : un guide d'une minute au premier lancement, sur de fausses bouteilles (« Passer » à chaque étape), puis « Le saviez-vous ? » à l'ouverture, une fonction à la fois, coupable d'un geste (Profil → Réglages).
- **Chaque fiche dans votre langue** : une description ou des accords écrits dans une autre langue sont traduits, avec « Voir l'original ».
- **Vos retours, corrigés** : la bulle du sommelier se lit comme une conversation ; sur la carte d'une bouteille, les années au niveau de l'état et la jauge sur toute la largeur ; le pays affiché, dans votre langue ; les vins bus jusqu'à la dernière bouteille quittent l'étagère ; « Vue rayonnage » sur une ligne ; statistiques plus lisibles ; « Simulateur de vieillissement » ; « Non cotée » expliqué ; formats 70 cl et 1 L ; la secousse demande un geste franc ; « Noter un vin bu dehors » ne redemande plus ce que vous venez de dire.
- **À table** : plus de « vous en avez en cave » sous un vin d'un autre domaine du même producteur ; un échec pour rejoindre dit sa vraie cause (réseau, Wi-Fi d'hôtel, serveur).
- **Hors ligne** : les polices sont dans l'app (plus de texte de secours, plus d'appel à Google à chaque lancement).

### 🛠️ Notes Techniques (Développeurs)
- *Migrations 065 à 068* : `ad_revenus` et `admin_revenus_pub` (065, revenu réel `onPaidEvent`, remplace J7) ; `degustations_proposees`, `proposer_degustation`, `accepter_degustation`, `refuser_degustation` (066, remplace 025, à ne pas appliquer) ; `palais_d_un_ami` (067) ; `voix_naturelle` (éteinte), tarifs TTS dans `tarifs_ia`, `reglage_invalide` pour `voix_naturelle` et `taux_de_change` (068). Base jetable : 047 → 068 verts.
- *taches-ia* : `traduire_fiche` (Flash-Lite, quota « traduction »), `recit_source` (Flash, réflexion basse, recherche Google, `sources` dans la réponse, quota « recit »), `voix` (Gemini TTS, WAV, quota « voix », seulement si `voix_naturelle`). Aucun nom de modèle TTS écrit en dur (K8).
- *App* : `APrixEgal`, `GuestProfile.plat` et `FoodPairingEngine.scoreDeLAccord` (`MenuTableMatcherEngine.poidsDuPlat` = 0,3 ; un convive « juste mon prénom » qui dit son plat vote par son plat seul) ; `RecitDuVin`, `ServiceDuRecit`, `VoixDuRecit` (`audioplayers`) ; `SommelierStorytellerEngine` : mots entiers, prise de mousse et vendange tardive seulement quand l'appellation les impose, rien sur la vendange sans élevage sur la fiche, vins mutés et spiritueux sans actes 2 et 3, typicité du cépage principal ; `DegustationsPartagees` ; `PriseEnMainAuDemarrage`, `GuideDePriseEnMain`, `LeSaviezVous` ; `Pays` ; `MesureDesPubs.revenu`.
- *Console* : capture chargée pas à pas avec la vraie cause d'un échec ; « Revenu réel (AdMob) » ; interrupteur `voix_naturelle`, taux de change.
- *Page invité* (`web/table`) : le plat du convive (quatre langues), la cause d'un échec nommée et journalisée.
- *Polices* : Inter et Playfair Display embarquées (OFL), `allowRuntimeFetching = false`.

## [v1.7.0+78] — 2026-10-08

> La 1.6.0+77, construite le même jour, n'a pas été distribuée : la 1.7.0+78 la remplace, au contenu identique. La version affichée passe à 1.7 (l'italien, la carte du lieu, le compte obligatoire et l'export de vos données sont des nouveautés à part entière), le build à 78 (la 77 a déjà été envoyée chez Apple).

### 🍷 Ce qui change pour vous
- **En italien** : l'app parle désormais français, anglais, espagnol et italien (Profil → Réglages → Langue), jusqu'à la page invité, aux raisons de la table et aux réponses du sommelier.
- **La carte du restaurant, sans rescanner** : après un scan, l'app demande où vous êtes (le restaurant le plus proche, ou un nom tapé). La personne suivante, au même endroit, retrouve la carte récente du lieu sans la scanner ; « Ce soir » propose les trois dernières cartes et « les cartes autour de moi ».
- **Vos données** : « Télécharger mes données » (compte, caves, dégustations, palais, conversations, en un fichier) ; l'app vérifie à l'ouverture que vous avez l'âge légal ; la politique de confidentialité est réécrite, avec les durées de conservation réellement appliquées.
- **Le rapport qualité-prix** d'une bouteille, seulement face à une cote dont la source est connue.
- **Rien d'inventé, encore** : une note n'est plus doublée ni inventée sur la fiche d'une dégustation ; l'origine d'un vin n'est plus remplie à « France » ; la carte des terroirs ne place plus un vin inconnu à Pauillac ; « Quel vin pour mon plat ? » ne propose plus un rouge puissant pour un poulet rôti ou des gambas, et le bourguignon appelle un Bourgogne.
- **Correctifs** : supprimer ou quitter une cave rafraîchit bien la liste ; l'app n'affiche plus « Créer ma première cave » pendant le chargement ; les étiquettes des bouteilles ne se chevauchent plus ; la recherche des restaurants proches patiente davantage et dit quand elle ne trouve rien.
- **Plus jamais un vin inventé** : un vin que le sommelier ne reconnaît pas avec certitude reste « non reconnu », à compléter à la main. Une étiquette déjà lue n'est plus écrasée par une recherche sur le nom, et ni le pays, ni la région, ni la couleur, ni les cépages ne sont devinés.
- **Un compte dès la première ouverture de l'app** : l'app installée demande de créer son compte (lien par e-mail), et une invitation à une table reprend après la connexion. Le site web reste ouvert sans compte pour les invités.
- **Aller très vite** : « Enregistrer sans noter » dans le questionnaire ; plus rien de pré-rempli que vous n'avez pas choisi (la description du sommelier se reprend d'un geste) ; balayer une dégustation du journal la supprime, avec « Annuler » ; le clavier se ferme en touchant ailleurs.
- **Déguster à plusieurs sans rien perdre** : revenir en arrière ne fait plus tout recommencer ; l'app annonce à qui c'est le tour ; « Bouteille défectueuse » passe en bas de l'étape du nez, et une bouteille défectueuse ne touche à aucun palais ; une réponse neutre, « Rien de particulier ».
- **La bonne version** : « À propos » affiche la version installée.

### 🛠️ Notes Techniques (Développeurs)
- *R1, serveur* : `taches-ia` — `vin_depuis_texte` sur Flash avec recherche Google, `fiche_texte` sur Flash (réflexion basse), consignes « ne jamais deviner » et sortie `{"reconnu": false}`, plus de « France par défaut » (migration 059) ; `scan-label` — pays et région `null` plutôt que devinés ; `scan-menu` — cépages vides et profil `null` pour un vin inconnu. *App* : `VinNonReconnu`, `FicheDepuisTexte.aEcrire` (une étiquette lue n'est jamais écrasée ; sans étiquette, ce qu'un texte précédent avait rempli est remplacé) ; relecture, import Excel et synchronisation sans « France » ni « Bordeaux » par défaut. *Banc* : « Identifier un vin depuis son nom », 19 vins hors de France dont 3 fictifs.
- *R2* : `GardeDesRoutes.redirection` — app installée : tout exige un compte non anonyme ; les parcours invités reprennent après la connexion (`/login?suite=`) ; web inchangé ; un compte anonyme se convertit en gardant son historique.
- *R3* : `TastingQuestionnaireSheet(dejaAuJournal)` ; reprise au premier convive incomplet ; `PopScope` ; journal en `Dismissible`, suppression différée jusqu'à la fermeture du bandeau (`persist: false`) ; `ClavierQuiSeFerme` à la racine ; `reponsesSansTrait` (« Rien de particulier », « Décevant » et « Rien, c'était parfait ! » ne sont plus comptés comme des goûts).
- *R9, console (migration 060)* : onglets Retours (statut, note, capture) et Réglages (interrupteurs, modèle et réflexion par tâche d'IA, version minimale, eCPM, quotas, journal des changements) ; Économie et Erreurs jour par jour, coût par modèle, occurrences d'une erreur, versions installées, « À surveiller ».
- *K10* : « À propos » lisait 1.2.1 écrit en dur ; le site construit par `deploy.yml` envoie sa version (suffixe `-pages`).
- *K6, la carte du lieu (migration 061)* : `cartes_de_lieux` (une carte par lieu, 30 jours), `cartes_proches`, `carte_du_lieu`, `deposer_carte` (lieu OpenStreetMap ou nom normalisé à la position arrondie, jamais celle de la personne ; ni photos ni identifiant d'appareil) ; `LieuDeLaCarte`, `CarteDuLieu`, `CartesDeLieuxService`, bloc « Où êtes-vous ? » de la capture, « Ce soir ».
- *Sécurité (migration 064)* : le bucket `labels` acceptait en écriture et effacement tout rôle, `anon` compris (« Public Access Labels ») ; chacun n'écrit plus que dans son dossier (`photo_a_moi`). La suppression de compte efface d'abord ses fichiers. Recherche des membres par une fonction serveur (062, `chercher_des_membres`) au lieu d'une lecture de toute la table des profils.
- *RGPD (migration 063)* : `purger_selon_les_durees`, chaque nuit : journaux de diagnostic 180 jours, retours un an, coûts d'IA et impressions publicitaires 400 jours ; `export_des_donnees.dart` ; `PorteDeLAge` ; `privacy.html` et `terms.html` réécrits (FR et EN).
- *Version minimale* : une exigence par plateforme (`build_ios`, `lien_ios` ; TestFlight sur iPhone, jamais le Play Store), réglable dans la console (060).
- *Langues* : catalogue italien complet (3 544 phrases, test de couverture), `app_it.arb` ; écrans à cinq langues codées à la main (catalan, latin) passés à `tr()` ; `FormesDuVerbe` en italien ; `deuxPoints()` ; fonctions `scan-label`, `scan-menu`, `menu-chat`, `chat`, `taches-ia` en italien ; page invité en italien.
- *Accords mets et vins* : mots reconnus en début de mot, mijotés et plats épicés avant la viande, veau espagnol, accents espagnols et italiens, conseil sans bouteille dans les quatre langues (test : chaque plat proposé, dans chaque langue, trouve un vin).
- *Consignes du modèle* : plus de « Type : Rouge », « Non millésimé », « Standard » par défaut (`taches-ia`, `scan-label`, `update-wine-values`).
- *Base jetable* (`tool/base_jetable/`) : les migrations 047 à 064 passent à la suite, rejouées deux fois, avec leurs essais.
- *Web* : plus d'artefacts de build suivis à la racine du dépôt ; `build_and_sync_web.sh` vérifie la présence de `privacy.html`, `terms.html` et `app-ads.txt`.

## [v1.6.0+76] — 2026-10-05

### 🍷 Ce qui change pour vous
- **Scan de carte plus solide** : une réponse illisible du sommelier est relue par un autre modèle, et un échec dit enfin sa vraie cause.

### 🛠️ Notes Techniques (Développeurs)
- *scan-menu* : JSON malformé → modèle suivant (`utilisable`) ; erreurs nommées `lecture_illisible` (502) et `erreur_serveur` (500). *Client* : `_causeServeur`, messages FR/EN/ES.

## [v1.6.0+75] — 2026-10-03

> iPhone seulement (Android reste en 74) : la première version iPhone pour les testeurs, avec AdMob.

### 🛠️ Notes Techniques (Développeurs)
- *AdMob iPhone* : identifiant d'application et bloc « Avec récompense » réels ; les 50 réseaux SKAdNetwork recommandés par Google.
- *Info.plist* : `NSLocationAlwaysAndWhenInUseUsageDescription`, exigée par Apple (ITMS-90683) ; sans effet pour l'utilisateur.

## [v1.6.0+74] — 2026-10-03

> La 74 reprend la 73, jamais envoyée, et c'est la première version pour iPhone. Les testeurs Android passent directement de la 71 à la 74 : tout ce que décrit la 73 les concerne aussi.

### 🍷 Ce qui change pour vous
- **Chatmelier sur iPhone** : la même app, le même compte et les mêmes caves. Sur iPhone, on se connecte par lien e-mail.
- **Un palais encore deviné le dit** : tant que l'app vous connaît peu, vos accords à table s'affichent « ≈ 73 % », une ligne dit à quel point votre palais est connu, et ne rien savoir ne gonfle plus les pourcentages.
- **Des pépites qui veulent dire quelque chose** : une ou deux par carte au plus, aucune sur une carte banale ; de même pour les bons plans.

### 🛠️ Notes Techniques (Développeurs)
- *Palais deviné (K5)* : `GuestProfile.ecartSurLAxe` / `ecartCarreSurLAxe` — un axe deviné compte pour un tiers son écart et pour le reste un écart d'ignorance de 2 points (`ecartDIgnorance`), au lieu de réduire l'écart seul ; `connaissance` (moyenne des huit axes) et `palaisDevine` (sous 0,35) ; `PalaisDevine.pourcentage`, `prefixe` (l'accord de toute la table) et `legende` (table, accord à la maison, page de secours) ; seul à table, un palais deviné lit « Sans doute dans vos goûts » ; le résultat publié porte `devine` et `connu`, la page invité les affiche (`table.js`).
- *iPhone* : icône et écran de lancement Chatmelier ; `Info.plist` — langues (fr, en, es), micro et position (« pendant l'utilisation » seulement) décrits au plus juste, `ITSAppUsesNonExemptEncryption` ; iPhone seulement (`TARGETED_DEVICE_FAMILY = 1`) ; rappels affichés app ouverte (`AppDelegate`) ; connexion Google masquée sur iOS tant que « Se connecter avec Apple » n'existe pas (règle 4.8 de l'App Store) ; construction et envoi sur TestFlight par GitHub Actions (`.github/workflows/ios.yml`).
- *Serveur, sans nouveau build (K9, sécurité des modèles)* : `scan-menu` note pépites et bons plans de 0 à 2 et n'en garde que les mieux notés (deux pépites, cinq au plus sur une carte exceptionnelle ; deux ou trois bons plans, jamais sans prix ni sans raison), et retire le millésime recopié à la fin du nom ; un modèle que Google ne connaît plus (404) est écarté six heures et signalé au journal des erreurs de la console (`IA_MODELE`).
- *Banc d'essai (K3b)* : références corrigées (cuvée et producteur séparés, pas d'appellation « Texas »), pépites jugées carte par carte (`pepites_au_plus`, `pepite_possible`), millésime recopié dans le nom ignoré, `--rejuger` (rejuge les réponses gardées, sans clé).

## [v1.6.0+73] — 2026-10-02

> La 73 reprend tout ce que contenait la 72, construite le même jour, avec en plus une note de table plus honnête, la source des installations et deux petits correctifs.

### 🍷 Ce qui change pour vous
- **L'onglet « Ce soir »** : le restaurant et le bar passent en tête de l'app. On y scanne une carte ou l'ardoise des vins au verre, on ouvre ou rejoint une table, on rouvre la dernière carte.
- **La table jusqu'au bout** : « Je ne bois pas ce soir », la carte « À deux bouteilles » quand un seul vin ne réunit pas la table, et en fin de soirée chacun note la bouteille choisie d'un geste.
- **Des invités sans application** : le QR ouvre une page légère où l'on rejoint la table, voit le choix et note le vin. Le QR ne porte plus que le code de la table : il s'affiche même pour une longue carte.
- **Le comptoir** : autour d'une ardoise, chacun note chaque verre sur son téléphone, et le comptoir dit qui a aimé quoi. Le parcours de dégustation peut choisir les verres qui vous apprennent quelque chose.
- **Votre palais, mieux connu** : les terroirs goûtés, ceux qui attendent en cave, le prochain à explorer, et ce qui manque à votre cave pour mieux vous connaître. Le sommelier du chat connaît votre palais.
- **En espagnol** : l'app en français, anglais et espagnol, et chacun lit ses notifications dans sa langue.
- **Rien d'affirmé sans preuve** : plus de valeur de marché sans source, plus de badge « vérifié », plus d'histoire de terroir inventée ; des apogées plausibles.
- **Moins de publicité** : plus de publicité au lancement, ni pendant vos premiers scans d'étiquette.
- **Une table qui sait ce qu'elle ignore** : vos goûts encore devinés comptent moins que ceux que vos dégustations ont montrés, la minéralité et le bois entrent dans l'accord, et votre étiquette à table reprend le style que vous avez déclaré tant que votre palais se dessine.
- **Correctifs** : l'import Excel, les notes de dégustation dictées et le récit d'un vin fonctionnent à nouveau ; la carte rouverte est bien la dernière ; le scan de carte survit à une coupure pendant la vidéo ; une sortie de cave hors ligne n'est plus perdue ni comptée deux fois ; une carte sans prix (salon, avion) ne montre plus « 0 € ».

### 🛠️ Notes Techniques (Développeurs)
- *Base (migrations 051 à 057)* : `tarifs_ia` et `cout_ia_usd`, `admin_economie` recalculé depuis les jetons (051) ; catalogue `wines` modifiable par les siens seulement, `decrite_par_serveur`, `quotas_ia` et `consommer_quota_ia`, valeurs de marché sans source effacées (052) ; `pg_cron` : purge des anonymes (épargne les codes de reprise valides), tables expirées, ménage quotidien, et `evenements_croissance` (053) ; `lire_carte_de_table`, relecture de `ai_cost_events` et `ad_impressions` (054) ; catalogue corrigé (055, nettoyage `supabase/nettoyage/055b_*`) ; `instant_du_journal` (056) ; `table_sessions.choix/resultat`, `choisir_vins_de_table`, `publier_resultat_table`, `lire_etat_table` (057).
- *Fonctions edge* : `scan-label`, `scan-menu` (mode `ardoise`, sortie compacte reconstruite côté serveur), `menu-chat`, `chat` (contexte du palais borné), `update-wine-values` (recherche et source obligatoires) ; nouvelle `taches-ia` (notes de dégustation, récit, synthèse de table, meuble, import de cave, fiches) ; `drinking-window-alerts` supprimée. Réflexion réglée (`thinkingConfig`), modèles lus dans `app_config.modeles_ia`, `couts` renvoyés, session et quotas (`garder`), mode strict par `app_config.ia_session_obligatoire`.
- *IA côté client* : plus aucun appel direct à Google (`fonctions_ia.dart`) ; `ai_cost_event.dart` aux tarifs réels datés.
- *Langues* : `shared/utils/langue.dart` (`Langue.code`, `tr`, `trSi`, `trDonnee`, `dansLaLangue`), catalogues `lib/l10n/catalogues/<langue>.json` générés par `tool/langues/` ; valeurs stockées affichées traduites (`valeurs_rangees.dart`) ; `supportedLocales` fr, en, es (les dix autres `.arb` dans `lib/l10n/plus_tard/`).
- *Table et bar* : onglet « Ce soir » (`adaptive_app_shell.dart`, `ce_soir_screen.dart`) ; `GuestProfile.neBoitPas`, `MenuTableMatcherEngine.meilleuresPaires`, `fin_de_soiree.dart`, `degustation_rapide.dart` ; page invité `app/web/table/` (HTML et JS, `config.js` écrit au build) ; `ScannedMenu.ardoise`, `MenuFlightEngine.buildFrontierFlight`, `comptoir.dart` et `comptoir_screen.dart`.
- *Palais* : `angle_mort_de_la_cave.dart`, `carte_des_terroirs.dart`, `taste_frontier_engine.dart` ; logique du questionnaire dans `questionnaire_de_degustation.dart`, minéralité apprise ; départage des accords à la maison par les fiches.
- *Fiabilité* : sondage des convives espacé (`SondageEspace`), rappels d'apogée locaux hebdomadaires, journaux dédoublonnés et sans contenu personnel, AdMob en debug ; `PolitiquePub` ; Blind Battle masqué ; fichiers morts supprimés.
- *Build* : le web reçoit `CHATMELIER_VERSION` comme l'app ; les scripts de la page invité portent la version dans leur adresse (fin du cache de dix minutes après publication).
- *Note de table (K1)* : `GuestProfile.confianceParAxe` et `poidsDeLAxe` (0,35 à 1), envoyés avec le profil ; minéralité pour les blancs, rosés et bulles, bois pour tous (`MenuTableMatcherEngine`) ; même pesée à la maison (`GuestMatcherEngine`) ; étiquettes « Amateur de Rouges / Blancs / Rosés / Bulles » pour un palais deviné.
- *Install Referrer (K2)* : `play_install_referrer` 0.5.0 ; `Croissance.lireLeReferrer` à la première ouverture Android ; console, onglet Économie : « Du web à l'app » et coût du web par installation obtenue.
- *Image (K4)* : une photo JPEG ni recadrée ni réduite part telle quelle quand le ré-encodage la grossirait.
- *Relevé sur l'émulateur, en production, avant envoi* : sur une ardoise, la frontière se borne au prix du verre (`MenuFlightEngine.prixPourApprendre`), comme le parcours ; un vin sans bois n'apprend plus rien du boisé, ni un vin peu minéral de la minéralité (`TasteFrontierEngine.nettete`) ; la page invité d'un comptoir parle du comptoir.

---

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
