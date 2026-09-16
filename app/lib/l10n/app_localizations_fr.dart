// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'Ma Cave';

  @override
  String get navCellar => 'Cave';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'Degust.';

  @override
  String get navStats => 'Stats';

  @override
  String get actionMenuTitle => 'Actions Cave';

  @override
  String get actionAddBottle => 'Ajouter une bouteille';

  @override
  String get actionAddBottleSub => 'Scanner une étiquette ou saisie manuelle';

  @override
  String get actionCheckoutBottle => 'Déguster / Sortir une bouteille';

  @override
  String get actionCheckoutBottleSub =>
      'Enregistrer une dégustation et sortir du stock';

  @override
  String get actionLookupWine => 'Consulter / Identifier un vin';

  @override
  String get actionLookupWineSub =>
      'Découverte et analyse instantanée par l\'IA';

  @override
  String get searchWinePlaceholder =>
      'Rechercher un millésime, domaine, appellation...';

  @override
  String get emptyCellarTitle => 'Votre cave est vide';

  @override
  String get emptyCellarSub =>
      'Scannez votre première bouteille pour commencer votre collection';

  @override
  String get emptyCellarButton => 'Ajouter ma première bouteille';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bouteilles',
      one: '1 bouteille',
      zero: '0 bouteille',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Valeur totale';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterRed => 'Rouge';

  @override
  String get filterWhite => 'Blanc';

  @override
  String get filterRose => 'Rosé';

  @override
  String get filterSparkling => 'Bulles';

  @override
  String get filterSheetTitle => 'Filtres de Cave';

  @override
  String get filterReset => 'Réinitialiser';

  @override
  String get filterApply => 'Appliquer les filtres';

  @override
  String get filterMaturity => 'Statut de Maturité / Apogée';

  @override
  String get maturityAtPeak => 'À l\'apogée';

  @override
  String get maturityDrinkSoon => 'À boire vite';

  @override
  String get maturityAging => 'En garde';

  @override
  String get maturityTooYoung => 'Trop jeune';

  @override
  String get maturityPastPeak => 'Passé';

  @override
  String get filterContinents => 'Continents';

  @override
  String get filterCountries => 'Pays';

  @override
  String get filterGrapes => 'Cépages';

  @override
  String get filterAppellations => 'Régions & Appellations';

  @override
  String get bottleDetailInfo => 'Informations & Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Fenêtre de Dégustation';

  @override
  String get bottleDetailTerroirMap => 'Carte du Terroir & Origine';

  @override
  String get bottleDetailLabelPhoto => 'Photo originale de l\'étiquette';

  @override
  String get bottleDetailVintage => 'Millésime';

  @override
  String get bottleDetailProducer => 'Domaine / Producteur';

  @override
  String get bottleDetailRegion => 'Région';

  @override
  String get bottleDetailCountry => 'Pays';

  @override
  String get bottleDetailAppellation => 'Appellation';

  @override
  String get bottleDetailGrapes => 'Cépages';

  @override
  String get bottleDetailAlcohol => 'Alcool';

  @override
  String get bottleDetailStock => 'Stock';

  @override
  String get bottleDetailLocation => 'Emplacement en cave';

  @override
  String get bottleDetailRack => 'Rang';

  @override
  String get bottleDetailShelf => 'Tablette';

  @override
  String get bottleDetailPurchasePrice => 'Prix d\'achat';

  @override
  String get bottleDetailEstimatedValue => 'Valeur estimée';

  @override
  String get bottleDetailFoodPairings => 'Accords Mets & Vins conseillés';

  @override
  String get bottleDetailTastingNotes => 'Profil Sommelier';

  @override
  String get bottleDetailDrinkButton => 'Sortir cette bouteille';

  @override
  String get bottleDetailEdit => 'Modifier';

  @override
  String get bottleDetailDelete => 'Supprimer';

  @override
  String get bottleDetailDeleteConfirm =>
      'Êtes-vous sûr de vouloir supprimer cette bouteille de votre cave ?';

  @override
  String get deleteBottleTitle => 'Supprimer définitivement';

  @override
  String get deleteBottleExplanation =>
      'Attention : la suppression efface toute trace de cette bouteille de votre cave et de votre historique sans laisser de trace.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Sortir / Boire : archive la bouteille dans votre historique de dégustation, alimente vos statistiques et conserve vos notes.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Supprimer définitivement : supprime immédiatement la fiche sans laisser de trace (recommandé en cas d\'erreur de saisie, casse ou doublon).';

  @override
  String get deleteBottleActionConfirm => 'Supprimer définitivement';

  @override
  String get deleteBottleActionDrinkInstead => 'Sortir / Boire plutôt';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get checkoutTitle => 'Déguster & Sortir de la Cave';

  @override
  String get checkoutSelectPrompt =>
      'Toucher pour choisir une bouteille de votre cave...';

  @override
  String get checkoutQtyOpened => 'Nombre de bouteilles ouvertes';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'sur $total en cave';
  }

  @override
  String get checkoutRating => 'Note de dégustation';

  @override
  String get checkoutFoodPairing => 'Mets & Accords associés (optionnel)';

  @override
  String get checkoutFoodHint =>
      'Ex: Côte de bœuf grillée, risotto aux cèpes...';

  @override
  String get checkoutNotes => 'Impressions & Commentaires de dégustation';

  @override
  String get checkoutNotesHint => 'Arômes, équilibre, persistance, émotions...';

  @override
  String get checkoutSubmit => 'Valider la dégustation';

  @override
  String get checkoutSuccess => 'Dégustation enregistrée avec succès !';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Bonjour ! Je suis Chatmelier. Posez-moi vos questions sur les accords mets-vins, l\'apogée de vos bouteilles, ou demandez-moi des recommandations basées sur votre cave actuelle.';

  @override
  String get chatAnalyzing => 'Chatmelier analyse votre cave...';

  @override
  String get chatInputHint => 'Demander à Chatmelier...';

  @override
  String get chatChipTonight => '🍷 Que devrais-je boire ce soir ?';

  @override
  String get chatChipSteak => '🥩 Quel vin servir avec une viande rouge ?';

  @override
  String get chatChipSeafood => '🐟 Quel blanc ouvrir pour un poisson ?';

  @override
  String get chatChipPeak => '⏰ Quelles bouteilles sont à leur apogée ?';

  @override
  String get journalTitle => 'Journal de Dégustation';

  @override
  String get journalEmpty => 'Aucun souvenir de dégustation pour le moment';

  @override
  String get journalEmptySub =>
      'Dégustez et sortez une bouteille de votre cave pour commencer votre carnet';

  @override
  String journalTastedOn(String date) {
    return 'Dégusté le $date';
  }

  @override
  String get statsTitle => 'Statistiques de la Cave';

  @override
  String get statsTotalBottles => 'Bouteilles en Cave';

  @override
  String get statsTotalValue => 'Valeur Totale';

  @override
  String get statsBottlesEnjoyed => 'Bouteilles Dégustées';

  @override
  String get statsByColor => 'Répartition par Couleur';

  @override
  String get statsByMaturity => 'Répartition par Maturité';

  @override
  String get statsByRegion => 'Principales Régions';

  @override
  String get statsByCountry => 'Principaux Pays';

  @override
  String get profileTitle => 'Profil & Réglages';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileDisplayName => 'Nom d\'affichage';

  @override
  String get profileDefaultCurrency => 'Devise par défaut';

  @override
  String get profileLanguage => 'Langue de l\'application';

  @override
  String get profileLanguageSystem => 'Automatique (Système)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Devise par défaut mise à jour : $currency';
  }

  @override
  String get profileLanguageUpdated => 'Langue mise à jour';

  @override
  String get profileLogout => 'Se déconnecter';

  @override
  String get profileAbout => 'À propos de Chatmelier';

  @override
  String get scanTitle => 'Scanner une étiquette';

  @override
  String get scanTakePhoto => 'Prendre une photo';

  @override
  String get scanPickGallery => 'Choisir dans la galerie';

  @override
  String get scanAnalyzing => 'L\'IA Chatmelier analyse l\'étiquette...';

  @override
  String get scanIdentified => 'Vin identifié par Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Ajouter à ma cave';

  @override
  String get loginTitle => 'Connexion';

  @override
  String get loginTagline => 'Votre cave à vin intelligente et partagée';

  @override
  String get loginTabMagicLink => '✉️ Lien de connexion';

  @override
  String get loginTabPassword => '🔑 Mot de passe';

  @override
  String get loginEmailLabel => 'Adresse email';

  @override
  String get loginPasswordLabel => 'Mot de passe';

  @override
  String get loginSendMagicLink => 'Recevoir mon lien de connexion';

  @override
  String get loginSignInButton => 'Se connecter';

  @override
  String get loginOrDivider => 'OU';

  @override
  String get loginGoogleButton => 'Continuer avec Google';

  @override
  String get loginRegisterLink => 'Pas encore de compte ? Créer un compte';

  @override
  String get registerTitle => 'Créer un compte';

  @override
  String get registerNameLabel => 'Nom d\'affichage / Prénom';

  @override
  String get registerSubmitButton => 'Créer mon compte';

  @override
  String get registerFillAllFields => 'Veuillez remplir tous les champs';

  @override
  String get registerWelcome => '🎉 Bienvenue sur Chatmelier !';

  @override
  String get registerErrorGeneric => 'Erreur lors de l\'inscription';

  @override
  String get authWelcome => 'Bienvenue sur Chatmelier';

  @override
  String get authSubtitle => 'Votre cave connectée & sommelier intelligent';

  @override
  String get authGoogle => 'Continuer avec Google';

  @override
  String get authMagicLink => 'Se connecter avec un lien de connexion';

  @override
  String get authEmail => 'Adresse email';

  @override
  String get authNoAccount => 'Pas encore de compte ? S\'inscrire';

  @override
  String get authHaveAccount => 'Déjà un compte ? Se connecter';

  @override
  String get changelogTitle => 'Journal des Versions';

  @override
  String get changelogEmpty => 'Aucune note de version disponible.';

  @override
  String get scratchcardTitle => 'Carte à Gratter des Terroirs';

  @override
  String get profileChangelog => 'Journal des versions & Changelog';

  @override
  String get profileScratchcard => 'Carte à Gratter des Terroirs';

  @override
  String get navProfile => 'Profil';

  @override
  String get quickActions => 'ACTIONS RAPIDES';

  @override
  String get appSubtitle => 'Sommelier & Cave à Vin';

  @override
  String get profileTabPalate => 'Palais';

  @override
  String get profileTabSettings => 'Réglages';

  @override
  String get profileTabTools => 'Outils';

  @override
  String get profileTabAccount => 'Compte';

  @override
  String get profileTheme => 'Ambiance / Thème';

  @override
  String get profileThemeLight => 'Lumineux ☀️';

  @override
  String get profileThemeDark => 'Sombre 🌙';

  @override
  String get profileThemeSystem => 'Système ⚙️';

  @override
  String get profileFriends => 'Mes Amis & Cartes des Goûts 🍷';

  @override
  String get profileExport => 'Exporter ma Cave & Rapport d\'Expertise 📊';

  @override
  String get profileDeleteAccount => 'Supprimer définitivement mon compte';

  @override
  String get profileDeleteConfirmTitle => 'Supprimer définitivement';

  @override
  String get profileDeleteConfirmMsg =>
      'Cette action est irréversible. Toutes vos données seront effacées.';

  @override
  String get badgesGalleryTitle => 'Galerie des Trophées';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total débloqués • $pct% accomplis';
  }

  @override
  String get badgesFilterAll => 'Tous';

  @override
  String get badgesEmpty => 'Aucun badge trouvé dans cette catégorie.';

  @override
  String get badgesUnlockedChip => 'Débloqué ✨';

  @override
  String get badgesStatusUnlocked => 'Trophée débloqué !';

  @override
  String get badgesStatusInProgress => 'En cours d\'obtention';

  @override
  String get badgesObjectiveLabel => 'Objectif :';

  @override
  String get badgesChatmelierLoreTitle =>
      'La Science & l\'Histoire du Chatmelier';

  @override
  String get badgesCloseButton => 'Fermer';

  @override
  String get badgesTierLabel => 'Rang';

  @override
  String get badgesShowcaseTitle => 'Trophées & Badges';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked sur $total débloqués';
  }

  @override
  String get badgesShowcaseGallery => 'Galerie';

  @override
  String get save => 'Enregistrer';

  @override
  String get continueAnyway => 'Continuer quand même';

  @override
  String get cellarDetected => 'Cave détectée : ';

  @override
  String proximityWifi(String ssid) {
    return 'Connecté au Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'Position GPS détectée à $distance';
  }

  @override
  String get proximitySwitch => 'Basculer';

  @override
  String get proximityIgnore => 'Ignorer';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Basculé automatiquement vers \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Cave distante détectée';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Vous êtes actuellement connecté au Wi-Fi \"$ssid\" associé à votre autre cave \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Vous êtes actuellement situé à environ $distance de \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nSouhaitez-vous quand même enregistrer cette bouteille dans la cave \"$cellar\" ?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nSouhaitez-vous quand même enregistrer la sortie de cette bouteille depuis la cave \"$cellar\" ?';
  }

  @override
  String get ratingExceptional => '🏆 Exceptionnel';

  @override
  String get ratingRemarkable => '✨ Remarquable';

  @override
  String get ratingVeryGood => '🍷 Très bon';

  @override
  String get ratingPleasant => '👍 Agréable';

  @override
  String get ratingPassable => 'Passable';

  @override
  String get checkoutWhoTasted => 'Qui a dégusté ce vin avec vous ?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'bouteilles',
      one: 'bouteille',
    );
    return '$producer • En stock : $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Ajouter un convive';

  @override
  String get checkoutAddGuestHint => 'Ajouter (Papa, Maman...)';

  @override
  String get checkoutCloseAndTaste => 'Fermer & Déguster 🍷';

  @override
  String get checkoutSommelierThinking =>
      'Le sommelier prépare les anecdotes de dégustation...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Compte à rebours d\'aération actif sur votre écran de verrouillage !';

  @override
  String get checkoutStartAerationTimer => 'Lancer le minuteur ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Minuteur d\'aération';

  @override
  String get checkoutDelayedTonight => 'Ce soir à 22h00';

  @override
  String get checkoutDelayedTonightSub =>
      'Idéal après le repas pour savourer le moment';

  @override
  String get checkoutDelayedTomorrow => 'Demain matin à 11h00';

  @override
  String get checkoutDelayedTomorrowSub =>
      'Pour vous remémorer vos impressions au calme';

  @override
  String get checkoutDelayedWeekend => 'Ce week-end (Samedi à 11h00)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Prenez le temps pendant votre temps libre';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'Dans 2 heures ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Rappel rapide en fin de dégustation';

  @override
  String get checkoutDelayedCustom =>
      'Choisir une date & heure personnalisée...';

  @override
  String get reviewPackagingDetected => 'Conditionnement Détecté';

  @override
  String get reviewSingleBottleOnly => 'Non, 1 seule bouteille';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Oui, $count bouteilles';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Stock augmenté avec succès ! ($count bouteilles en cave)';
  }

  @override
  String get reviewVintageYear => 'Millésime / Année';

  @override
  String get reviewNonVintage => 'Passer / Non millésimé';

  @override
  String get reviewValidate => 'Valider';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name ajouté avec succès à la cave !';
  }

  @override
  String get reviewBottleAnalysis => 'Analyse de la bouteille';

  @override
  String get reviewDiscard => 'Abandonner';

  @override
  String get reviewDiscardConfirmTitle => 'Abandonner la saisie ?';

  @override
  String get reviewContinueEditing => 'Continuer la saisie';

  @override
  String get reviewDiscardWithoutSaving => 'Quitter sans enregistrer';

  @override
  String get reviewBottleDetails => 'Fiche de la Bouteille';

  @override
  String get reviewStockInCellar => 'Stock en cave';

  @override
  String get reviewStockAddition => 'Ajout';

  @override
  String get reviewStockNewTotal => 'Nouveau total';

  @override
  String get reviewQuantityToAdd => 'Quantité à ajouter :';

  @override
  String get reviewSeparateEntry =>
      'Créer une entrée distincte (autre casier / prix)';

  @override
  String get reviewRetryAi => 'Réessayer l\'analyse IA';

  @override
  String get reviewEnlarge => 'Agrandir';

  @override
  String get reviewGeneralInfo => 'Informations Générales';

  @override
  String get reviewOriginTerroir => 'Origine & Terroir';

  @override
  String get reviewQuantityPurchase => 'Quantité & Achat';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi détecté et associé : \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Impossible de détecter le Wi-Fi (activez la localisation ou saisissez le nom manuellement)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 Coordonnées GPS capturées ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'Position GPS inaccessible. Vérifiez les autorisations de localisation.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Cave \"$cellar\" créée avec succès !';
  }

  @override
  String cellarCreationError(String error) {
    return 'Erreur lors de la création : $error';
  }

  @override
  String get cellarRadiusPrecise => '100 mètres (très précis)';

  @override
  String get cellarRadiusRecommended => '300 mètres (recommandé)';

  @override
  String get cellarRadius500m => '500 mètres';

  @override
  String get cellarRadius1km => '1 kilomètre';

  @override
  String get cellarRadius3km => '3 kilomètres';

  @override
  String get cellarCreateButton => 'Créer la cave';

  @override
  String get cellarUseCurrentGps => 'Définir avec ma position GPS actuelle';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Paramètres de la cave \"$cellar\" mis à jour';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Erreur lors de la mise à jour : $error';
  }

  @override
  String get wineTypeRed => 'Rouge 🍷';

  @override
  String get wineTypeWhite => 'Blanc 🥂';

  @override
  String get wineTypeRose => 'Rosé 🌸';

  @override
  String get wineTypeSparkling => 'Bulles 🍾';

  @override
  String get wineTypeDessert => 'Moelleux / Liquoreux 🍯';

  @override
  String get bottleSizeCustom => 'Autre contenance…';

  @override
  String get bottleSizeCustomTitle => 'Contenance personnalisée';

  @override
  String get bottleSizeCustomLabel => 'Contenance en centilitres';

  @override
  String get bottleSizeCustomInvalid =>
      'Entrez une contenance entre 1 et 3000 cl.';

  @override
  String get wineTypeLiqueur => 'Liqueur 🍯';

  @override
  String get wineTypeSpirit => 'Spiritueux 🥃';

  @override
  String get wineTypeGrappa => 'Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Eau-de-vie 🍐';

  @override
  String get wineTypeWhisky => 'Whisky 🥃';

  @override
  String get wineTypeRum => 'Rhum 🏴‍☠️';

  @override
  String get wineTypeGin => 'Gin 🍸';

  @override
  String get wineTypeVodka => 'Vodka 🧊';

  @override
  String get wineTypeTequila => 'Tequila 🌵';

  @override
  String get wineTypeCognac => 'Cognac 🍷';

  @override
  String get cellarCreateTitle => 'Créer une nouvelle cave';

  @override
  String get cellarManageTitle => 'Gérer la cave';

  @override
  String get cellarNameLabel => 'Nom de la cave *';

  @override
  String get cellarNameHint => 'ex : Cave de Londres, Cave des Vosges';

  @override
  String get cellarNameRequired => 'Veuillez saisir un nom';

  @override
  String get cellarLocationLabel => 'Lieu / Ville (optionnel)';

  @override
  String get cellarLocationHint => 'ex : Londres (UK), Vosges (FR)';

  @override
  String get cellarNicknameLabel => 'Surnom / Pièce (optionnel)';

  @override
  String get cellarNicknameHint => 'ex : Sous-sol, Cave à vin principale';

  @override
  String get cellarDescriptionLabel => 'Description (optionnel)';

  @override
  String get cellarDescriptionHint =>
      'ex : Cave enterrée fraîche, hygrométrie 70%';

  @override
  String get cellarWifiLabel => 'Wi-Fi associé (optionnel)';

  @override
  String get cellarWifiHint => 'ex : Livebox-Cave';

  @override
  String get cellarLinkCurrentWifi => 'Associer au Wi-Fi actuel';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Capturer le Wi-Fi actuel';

  @override
  String get cellarRadiusLabel => 'Rayon de détection GPS';

  @override
  String get cellarAutoDetectionHeader => 'Détection & Transition Automatique';

  @override
  String get cellarAutoDetectionDesc =>
      'Associez votre réseau Wi-Fi ou vos coordonnées GPS pour que l\'application bascule automatiquement sur cette cave dès que vous y êtes.';

  @override
  String get cellarLatitudeLabel => 'Latitude';

  @override
  String get cellarLongitudeLabel => 'Longitude';

  @override
  String get checkoutGuidedTasting => 'Dégustation guidée';

  @override
  String get checkoutGuidedTastingShared =>
      'Partagez vos impressions chacun son tour ou ensemble';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analysez robe, nez, bouche & affinez votre profil';

  @override
  String get checkoutUncorkNowRateLater =>
      'Déboucher maintenant, noter plus tard';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Sortie immédiate • Choisir l\'heure du rappel (ce soir, demain...)';

  @override
  String get checkoutUncorkAeration => 'Déboucher & Minuteur d\'aération';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Sortie immédiate • $minutes min d\'aération conseillée';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Sortie immédiate • Minuteur d\'aération / carafage';

  @override
  String get checkoutSommelierServiceAdvice => 'Conseils Sommelier de Service';

  @override
  String get checkoutHistoryAnecdotes => 'Histoire & Anecdotes';

  @override
  String get checkoutNoDecanting => 'Pas de carafage';

  @override
  String get checkoutStoryTitle => 'L\'Histoire de cette Bouteille 📖';

  @override
  String get checkoutStorySubtitle =>
      'Anecdotes captivantes à raconter à table';

  @override
  String get checkoutStoryTerroir => 'Terroir & Cépages';

  @override
  String get checkoutStoryVintage => 'L\'Histoire du Millésime';

  @override
  String get checkoutStoryTastingSecret => 'Le Secret de Dégustation';

  @override
  String get checkoutStoryTableAnecdote => 'L\'Anecdote de Table';

  @override
  String get checkoutJournalArchivedNotice =>
      'Rassurez-vous : cette bouteille sera précieusement archivée dans votre Journal de Dégustation avec vos photos et notes.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Bouteille débouchée ! Minuteur d\'aération ($minutes min) lancé sur votre écran.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'La bouteille sera immédiatement débouchée et sortie de cave. Confirmez la durée d\'aération avant dégustation :';

  @override
  String get checkoutRateWine => 'Noter le vin';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Chrono ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Conseil Sommelier : carafer $minutes min. Chrono lockscreen prêt.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Rappel pour noter vos impressions prévu après dégustation.';

  @override
  String get checkoutBottleRemovedSuccess => 'Bouteille sortie de cave !';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Profitez de votre dégustation. Rappel prévu $date pour noter vos impressions.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'Les goûts de chaque participant seront automatiquement enrichis dans son profil.';

  @override
  String checkoutCellarOf(String name) {
    return 'Cave de $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Stock : $count bout.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Ajoutez un proche ou membre de la famille présent à cette dégustation (ex: Papa, Maman, Sophie...).';

  @override
  String get checkoutAddGuestNameLabel => 'Prénom / Nom';

  @override
  String get checkoutDelayedSheetTitle => 'Déboucher & Noter plus tard';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'Quand souhaitez-vous recevoir un rappel pour vos impressions ?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Ce soir dans 2 heures ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Ce soir à 21h00';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'ce soir à $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'demain à $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'le $date à $time';
  }

  @override
  String get add => 'Ajouter';

  @override
  String get cellarWinesTab => '🍷 Vins';

  @override
  String get cellarSpiritsTab => '🥃 Spiritueux';

  @override
  String get cellarPairWithDish => 'Quel vin pour mon plat ?';

  @override
  String get cellarCollapseAll => 'Tout replier';

  @override
  String get cellarExpandAll => 'Tout déplier';

  @override
  String get cellarSort => 'Trier';

  @override
  String get cellarCategories => 'Catégories';

  @override
  String get cellarFavorites => 'Favoris';

  @override
  String get cellarGridView => 'Grille';

  @override
  String get cellarListView => 'Liste';

  @override
  String get cellarClearFilters => 'Effacer les filtres';

  @override
  String get cellarNoBottlesCategory => 'Aucune bouteille dans cette catégorie';

  @override
  String get cellarNoBottlesCriteria =>
      'Aucune bouteille ne correspond à ces critères';

  @override
  String get feedbackSheetTitle => 'Retour Testeur & Annotation';

  @override
  String get feedbackStylus => 'Stylet :';

  @override
  String get feedbackUndo => 'Annuler le dernier trait';

  @override
  String get feedbackClear => 'Tout effacer';

  @override
  String get feedbackHint =>
      'Entourez la zone et décrivez votre retour ou bug...';

  @override
  String get feedbackSubmit => 'Envoyer le rapport';

  @override
  String get feedbackSubmitting => 'Envoi en cours...';

  @override
  String get feedbackNoScreenshot => 'Aucune capture d\'écran disponible';

  @override
  String get feedbackEmptyError =>
      'Veuillez ajouter un commentaire ou entourer un élément.';

  @override
  String get feedbackSuccess =>
      'Merci pour votre retour ! 🍷 Le rapport a été transmis.';

  @override
  String feedbackError(String error) {
    return 'Erreur lors de l\'envoi : $error';
  }

  @override
  String get checkoutFastExit => 'Sortie rapide sans questionnaire ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Sortie en cours...';

  @override
  String get checkoutRatingSubtitle =>
      'Attribuez votre note globale après dégustation';

  @override
  String get checkoutRecommendedBadge => 'Recommandé';

  @override
  String get tastingWhoTastedTitle => '👥 Qui a dégusté ce vin ?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Sélectionnez les dégustateurs. Les profils de goût seront enrichis automatiquement.';

  @override
  String get tastingHowToTaste => 'Comment déguster ?';

  @override
  String get tastingEachTurn => 'Chacun son tour';

  @override
  String get tastingEachTurnDesc =>
      '📱 En passant le téléphone : chacun répond séparément à son rythme.';

  @override
  String get tastingTogether => 'Ensemble';

  @override
  String get tastingTogetherDesc =>
      '🥂 Un seul questionnaire complété ensemble pour tous les convives.';

  @override
  String get tastingBlindMode => 'Mode Dégustation à l\'Aveugle';

  @override
  String get tastingBlindModeDesc =>
      'Masque le nom du vin et active un quiz de table interactif avec révélation finale !';

  @override
  String get tastingPrimaryProfile => 'Profil principal';

  @override
  String get tastingAppInstalled => 'App installée 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questionnaires complétés',
      one: '1 questionnaire complété',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '🍇 Le Nez — Arômes';

  @override
  String get tastingStepNezSubtitle =>
      'Quels arômes avez-vous perçus ? (Plusieurs choix possibles)';

  @override
  String get tastingFaultTitle => 'Le vin sent-il l\'une de ces choses ?';

  @override
  String get tastingFaultSubtitle =>
      'Si oui, la bouteille est défectueuse — ce n\'est ni votre palais, ni le style du vin.';

  @override
  String get tastingFaultCorkLabel => '📦 Carton mouillé, cave humide';

  @override
  String get tastingFaultCorkExplain =>
      'Goût de bouchon (TCA). Le vin n\'y est pour rien et ne s\'arrangera pas à l\'aération — au restaurant, on peut demander une autre bouteille.';

  @override
  String get tastingFaultOxidationLabel => '🍎 Pomme blette, vinaigre, xérès';

  @override
  String get tastingFaultOxidationExplain =>
      'Oxydation. La bouteille a pris l\'air, souvent par un bouchon défaillant ou une garde trop longue.';

  @override
  String get tastingFaultReductionLabel => '🥚 Allumette, œuf, chou';

  @override
  String get tastingFaultReductionExplain =>
      'Réduction. Bonne nouvelle : elle se dissipe souvent à l\'aération. Carafez vingt minutes et regoûtez avant de juger.';

  @override
  String get tastingFaultExcluded =>
      'Cette dégustation ne comptera pas dans votre profil de goût.';

  @override
  String get tastingAromaIntensity => 'Intensité aromatique :';

  @override
  String get tastingAromaDiscreet => '🤫 Discret';

  @override
  String get tastingAromaExplosive => '💥 Explosif';

  @override
  String get tastingStepBoucheTitle => '⚖️ La Bouche — Équilibre';

  @override
  String get tastingStepBoucheSubtitle =>
      'Décrivez la texture et l\'équilibre du vin en bouche.';

  @override
  String get tastingAcidity => 'Acidité :';

  @override
  String get tastingAcidityFreshness => 'Acidité & Vivacité :';

  @override
  String get tastingAcidityFlat => '🫠 Mou / Plat';

  @override
  String get tastingAciditySharp => '⚡ Vif / Tranchant';

  @override
  String get tastingTannins => 'Tanins :';

  @override
  String get tastingTanninsSilky => '🧶 Fondus / Soyeux';

  @override
  String get tastingTanninsGrippy => '💪 Puissants / Astringents';

  @override
  String get tastingMinerality => 'Minéralité & Fraîcheur :';

  @override
  String get tastingMineralityRound => '🧈 Rond / Beurré';

  @override
  String get tastingMineralityCrisp => '🪨 Minéral / Ciselé';

  @override
  String get tastingEffervescence => 'Effervescence :';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fine / Délicate';

  @override
  String get tastingEffervescenceVibrant => '🎆 Vive / Crémeuse';

  @override
  String get tastingBody => 'Corps / Volume :';

  @override
  String get tastingBodyLight => '🍃 Léger / Aérien';

  @override
  String get tastingBodyFull => '🏋️ Puissant / Charnu';

  @override
  String get tastingLength => 'Longueur en bouche :';

  @override
  String get tastingLengthShort => '⏱️ Courte';

  @override
  String get tastingLengthLong => '♾️ Interminable';

  @override
  String get tastingStepVerdictTitle => '✅ Verdict Final';

  @override
  String get sipSectionTitle => '🍷 La gorgée';

  @override
  String get tasteConfidenceUnknown =>
      'Je ne connais pas encore votre palais — le halo montre ce que je devine.';

  @override
  String get tasteEvidenceTitle => 'D\'où vient ce profil';

  @override
  String get tasteEvidenceEmpty =>
      'Aucune trace pour l\'instant. Votre profil se construira à mesure que vous dégusterez.';

  @override
  String get tasteEvidenceOpen => 'Voir d\'où vient ce profil';

  @override
  String tasteConfidenceKnown(String percent) {
    return 'Palais connu à $percent %. Le flou marque ce que je devine encore.';
  }

  @override
  String tasteConfidenceFrontier(String axis) {
    return 'Ce que j\'ignore le plus : $axis.';
  }

  @override
  String get sipSectionSubtitle =>
      'Deux touches, et ce verre apprend quelque chose à votre profil de goût.';

  @override
  String get tastingBuyAgain => 'Rachèteriez-vous cette bouteille ?';

  @override
  String get tastingBuyAgainYes => '🤩 Absolument !';

  @override
  String get tastingBuyAgainMaybe => '🤔 Peut-être';

  @override
  String get tastingBuyAgainNo => '👎 Non merci';

  @override
  String get tastingIdealMoment => 'Quel moment idéal pour ce vin ?';

  @override
  String get tastingMomentApero => '🥂 Apéro';

  @override
  String get tastingMomentMeal => '🍽️ Repas du quotidien';

  @override
  String get tastingMomentDinner => '🎩 Grand dîner';

  @override
  String get tastingMomentRomantic => '🕯️ Dîner romantique';

  @override
  String get tastingMomentSolo => '🧘 Solo / Méditation';

  @override
  String get tastingWhatLiked => 'Ce que vous avez le plus aimé :';

  @override
  String get tastingWhatDisliked => 'Ce qui vous a le moins plu :';

  @override
  String get tastingOccasionLabel =>
      'Occasion / Souvenir partagé (optionnel) ✨';

  @override
  String get tastingOccasionHint =>
      'Ex: 70 ans de Papa, Dîner aux chandelles, Retrouvailles...';

  @override
  String get tastingAddPhoto => 'Ajouter une photo souvenir de la table 📸';

  @override
  String get tastingPhotoSaved => 'Photo souvenir enregistrée 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Note Finale & Impression';

  @override
  String get tastingStepImpressionSubtitle =>
      'Après avoir apprécié le nez et la bouche, attribuez votre note globale.';

  @override
  String get tastingOverallFeeling => 'Votre ressenti global :';

  @override
  String get tastingScoreOutOf10 => 'Note sur 10 :';

  @override
  String get tastingCompletedTitle => 'Dégustation terminée & enregistrée !';

  @override
  String get tastingCompletedSubtitle =>
      'Les profils de dégustation ont été mis à jour avec succès ✨';

  @override
  String get tastingBottleRemoved => 'Bouteille sortie de la cave';

  @override
  String get tastingConsultDebrief =>
      'Consulter le Débrief du Sommelier (Nuances cachées & Terroir)';

  @override
  String get tastingFinishButton => 'Terminer ✨';

  @override
  String get tastingNextTaster => 'Valider → Dégustateur suivant';

  @override
  String get tastingConfirmAndFinish => 'Valider & Terminer ✨';

  @override
  String get tastingQuitTitle => 'Quitter le questionnaire ?';

  @override
  String get tastingQuitMessage => 'Vos réponses ne seront pas sauvegardées.';

  @override
  String get tastingContinue => 'Continuer';

  @override
  String get tastingQuit => 'Quitter';

  @override
  String tastingStartCount(int count) {
    return 'Commencer ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Synchronisé dans l\'application de $name ✨';
  }

  @override
  String get tastingProfileEnriched => 'Profil de goût enrichi';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Acuité sensorielle : $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle =>
      'Origine des Goûts & Secrets du Flacon';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Découvrez d\'où viennent les arômes, la couleur et la structure de votre vin';

  @override
  String get tastingBlindQuizTitle => 'Quiz de table aveugle 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. Quelle est la région d\'origine ? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. Quel est le cépage principal ? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Âge / Millésime estimé ? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Estimation de prix ? 💶';

  @override
  String get tastingBlindRevealTitle => 'Révélation de la Bouteille Mystère 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Score du Quiz Aveugle : $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Débriefing Œnologique & Moléculaire';

  @override
  String get tastingSensoryAcuity => 'ACUITÉ SENSORIELLE';

  @override
  String tastingPrecision(int score) {
    return '$score% Précision';
  }

  @override
  String get tastingConcordanceTitle => '1. CONCORDANCE & SIGNATURE DU CRU';

  @override
  String get tastingWhatYouDetected => 'CE QUE VOUS AVEZ DÉCELÉ :';

  @override
  String get tastingArchetypeSignature => 'SIGNATURE ARCHÉTYPALE DU FLACON :';

  @override
  String get tastingHiddenNuancesTitle =>
      'SUBTILITÉS & NUANCES À CHERCHER AU PROCHAIN VERRE :';

  @override
  String get tastingPillarsTitle => '2. SCIENCE ŒNOLOGIQUE & MOLÉCULES';

  @override
  String get tastingPillarsSubtitle =>
      'Pourquoi ce vin possède-t-il cette structure, ces arômes et cette couleur ?';

  @override
  String get tastingChatWithSommelier =>
      'Approfondir la vinification avec Chatmelier';

  @override
  String get aromaFruitsRouges => 'Fruits rouges';

  @override
  String get aromaFruitsNoirs => 'Fruits noirs';

  @override
  String get aromaFruitsBlancs => 'Fruits blancs/jaunes';

  @override
  String get aromaAgrumes => 'Agrumes';

  @override
  String get aromaFloral => 'Floral';

  @override
  String get aromaVegetal => 'Végétal / Herbes';

  @override
  String get aromaEpicesDouces => 'Épices douces';

  @override
  String get aromaEpicesVives => 'Épices vives / Poivre';

  @override
  String get aromaBoise => 'Boisé / Vanille';

  @override
  String get aromaBeurre => 'Beurré / Brioche';

  @override
  String get aromaMineral => 'Minéral / Pierre';

  @override
  String get aromaMiel => 'Miel / Confiture';

  @override
  String get aromaChocolat => 'Chocolat / Café';

  @override
  String get aromaFumee => 'Fumé / Grillé';

  @override
  String get emojiDisliked => 'Pas aimé';

  @override
  String get emojiMeh => 'Bof';

  @override
  String get emojiDecent => 'Correct';

  @override
  String get emojiVeryGood => 'Très bien';

  @override
  String get emojiLoved => 'Coup de cœur';

  @override
  String get likedFreshness => 'La fraîcheur';

  @override
  String get likedFruitiness => 'Le fruité';

  @override
  String get likedComplexity => 'La complexité';

  @override
  String get likedElegance => 'L\'élégance';

  @override
  String get likedPower => 'La puissance';

  @override
  String get likedSilky => 'Le côté soyeux';

  @override
  String get likedOriginality => 'L\'originalité';

  @override
  String get likedFoodPairing => 'L\'accord avec le plat';

  @override
  String get likedMinerality => 'La minéralité';

  @override
  String get likedLength => 'La longueur en bouche';

  @override
  String get likedDisappointing => 'Rien / Décevant 😕';

  @override
  String get dislikedTooAcidic => 'Trop acide';

  @override
  String get dislikedTooTannic => 'Trop tannique';

  @override
  String get dislikedTooOaked => 'Trop boisé / vanillé';

  @override
  String get dislikedTooAlcoholic => 'Trop alcoolisé / chaud';

  @override
  String get dislikedTooThin => 'Trop léger / dilué';

  @override
  String get dislikedLacksFruit => 'Manque de fruit';

  @override
  String get dislikedTooSweet => 'Trop sucré';

  @override
  String get dislikedTooExpensive => 'Trop cher pour la qualité';

  @override
  String get dislikedNothing => 'Rien, c\'était parfait !';

  @override
  String get tastingStepTasters => 'Dégustateurs';

  @override
  String get tastingStepNezNav => 'Le Nez';

  @override
  String get tastingStepBoucheNav => 'La Bouche';

  @override
  String get tastingStepVerdictNav => 'Verdict';

  @override
  String get tastingStepRatingNav => 'Note Finale';

  @override
  String get tastingBack => 'Retour';

  @override
  String get tastingNext => 'Suivant';

  @override
  String get tastingSaving => 'Enregistrement...';

  @override
  String get tastingHeaderTitle => 'Questionnaire Dégustation';

  @override
  String tastingAnswersOf(String name) {
    return 'Réponses de $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Passez le téléphone à $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Vos réponses ont bien été enregistrées.\nC\'est maintenant au tour de $name.';
  }

  @override
  String get tastingDictateButton => 'Dicter les impressions à table 🎙️';

  @override
  String get tastingDictateHint =>
      'Parlez ou écrivez naturellement, l\'IA Chatmelier pré-remplira vos arômes et équilibre en bouche !';

  @override
  String get tastingDictateMicTip =>
      'Astuce : activez le micro sur votre clavier pour dicter à voix haute !';

  @override
  String get tastingTakePhoto => 'Prendre une photo de la tablée 📸';

  @override
  String get tastingChooseGallery => 'Choisir dans la galerie 🖼️';

  @override
  String get tastingConclaveSummary => 'Synthèse du Conclave';

  @override
  String get tastingCellarMaster => 'Maître de Cave';

  @override
  String get tastingGuestTaster => 'Convive Dégustateur';

  @override
  String tastingProfileTag(String type) {
    return 'Profil : $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Dégustation libre enregistrée.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Robe : $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Structure : $structure ($caudalies caudalies)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Molécules clés : $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Origine clé : $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Cépages : $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Impressions de dégustation appliquées par l\'IA ✨';

  @override
  String get tastingBlindYourPredictions =>
      'Bilan des pronostics à l\'aveugle :';

  @override
  String get tastingBlindGuessCorrect => 'Trouvé ! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Faites vos pronostics avant la grande révélation finale !';

  @override
  String tastingStartTaster(String name) {
    return 'C\'est parti, $name ! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Bravo !';

  @override
  String tastingQuizWas(String answer) {
    return '(C\'était : $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'Ex : Bernard a adoré, 8.5/10 avec des notes de sous-bois et de cassis. Caro a mis 7/10 en trouvant le vin un peu acide...';

  @override
  String get tastingDictateAnalyzing => 'Analyse en cours...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Analyser & Appliquer aux fiches ✨';

  @override
  String get tastingFormatExpress => 'Format Express (1 page) ⚡';

  @override
  String get tastingFormatExpressDesc => 'Note, arômes clés et verdict en 30s';

  @override
  String get tastingFormatSommelier => 'Format Sommelier (Complet) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Analyse détaillée robe, nez, bouche & terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'Qu\'est-ce qu\'une caudalie ? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalie = 1 seconde où les arômes persistent en bouche après avoir avalé ou recraché.\n• 1 à 4 caudalies : vin léger de soif\n• 5 à 7 caudalies : bel équilibre aromatique\n• 8 à 12+ caudalies : grand vin d\'exception !';

  @override
  String get tastingAddCustomAroma => '+ Arôme sur-mesure';

  @override
  String get tastingCustomAromaDialogTitle => 'Ajouter un arôme précis';

  @override
  String get tastingCustomAromaHint =>
      'ex: Silex fumé, Mûre sauvage, Rose séchée...';

  @override
  String get tastingFoodSynergyTitle => 'Synergie avec le plat 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Sublimé';

  @override
  String get tastingSynergyHarmonious => '👍 Harmonieux';

  @override
  String get tastingSynergyNeutral => '😐 Neutre';

  @override
  String get tastingSynergyClashing => '⚡ Conflit';

  @override
  String get checkoutFastRatingTitle => 'Note rapide en 1 tap (optionnelle) :';

  @override
  String get checkoutActionTastingTitle => 'Déguster ce vin';

  @override
  String get checkoutActionTastingSubtitle =>
      'Format express (1 page) ou sommelier complet';

  @override
  String get checkoutActionDeferredRemind => 'Rappel plus tard 🌙';

  @override
  String get checkoutActionAerationTimer => 'Chrono aération ⏱️';

  @override
  String get externalTastingTitle => 'Dégustation Hors-Cave';

  @override
  String get externalTastingSubtitle =>
      'Restaurant, bar, chez des amis... sans modifier vos stocks';

  @override
  String get externalTastingWithWhom => 'Avec qui dégustez-vous ce vin ?';

  @override
  String get externalTastingWhere => 'Où dégustez-vous ce vin ?';

  @override
  String get externalTastingSearchingPlaces =>
      'Recherche des restaurants, bars & amis autour de vous...';

  @override
  String get externalTastingGpsActive => 'GPS actif';

  @override
  String externalTastingPlaceGuess(String place) {
    return 'Vous semblez être : $place';
  }

  @override
  String get externalTastingFavoritePlaceNote =>
      'Lieu favori mémorisé automatiquement par Chatmelier';

  @override
  String get externalTastingChangePlace => 'Changer de lieu';

  @override
  String get externalTastingOtherPlace => 'Chez un ami / Autre lieu...';

  @override
  String get externalTastingNoPlaceFound =>
      'Aucun restaurant détecté à proximité immédiate.';

  @override
  String get externalTastingPlaceLabel => 'Chez qui ou où êtes-vous ? *';

  @override
  String get externalTastingPlaceHint =>
      'Ex: Chez Dimitri, Chez mes parents, Maison de campagne...';

  @override
  String externalTastingRememberPlace(String place) {
    return 'Mémoriser \"$place\" à cette position GPS pour vos prochaines visites';
  }

  @override
  String get externalTastingDefaultPlace => 'Au restaurant';

  @override
  String get externalTastingAiIdentifyTitle =>
      'Identifier avec l\'IA (Bar, Restaurant, Ardoise)';

  @override
  String get externalTastingAiIdentifyDesc =>
      'Entrez quelques mots (ex: \"Saint-Joseph Coursodon 2021\" ou \"Bandol Terrebrune\") pour pré-remplir la fiche.';

  @override
  String get externalTastingAiIdentifyHint =>
      'Ex: Saint-Joseph 2021 Coursodon...';

  @override
  String get externalTastingDetect => 'Détecter';

  @override
  String get externalTastingAiScanningSub =>
      'Détection du domaine, millésime, cépages et notes...';

  @override
  String get externalTastingPhotoAdded => 'Photo de l\'étiquette ajoutée';

  @override
  String get externalTastingPhotoAddedSub =>
      'Visible dans votre journal de dégustation';

  @override
  String get externalTastingReplacePhoto => 'Remplacer';

  @override
  String get externalTastingDeletePhoto => 'Supprimer la photo';

  @override
  String get externalTastingScanLabelTitle =>
      'Photographier l\'étiquette (Scan IA)';

  @override
  String get externalTastingScanLabelSub =>
      'Reconnaissance automatique du vin et ajout au journal';

  @override
  String get externalTastingScanLabelButton => 'Scan IA';

  @override
  String get externalTastingTakePhotoSub =>
      'Photographier l\'étiquette avec l\'appareil photo';

  @override
  String get externalTastingPickGallerySub =>
      'Sélectionner une photo existante';

  @override
  String get externalTastingWineNameLabel => 'Nom du Vin *';

  @override
  String get externalTastingWineNameHint => 'Ex: Domaine de Terrebrune';

  @override
  String get externalTastingProducerHint => 'Ex: Famille Delon';

  @override
  String get externalTastingRegionLabel => 'Région / Appellation';

  @override
  String get externalTastingRegionHint => 'Ex: Bandol Rouge';

  @override
  String get externalTastingRatingLabel => 'Note de dégustation :';

  @override
  String get externalTastingFavorite => 'Coup de cœur';

  @override
  String get externalTastingFoodLabel => 'Accord Met & Vin';

  @override
  String get externalTastingNotesLabel => 'Impressions & Arômes ressentis';

  @override
  String get externalTastingNotesHint =>
      'Ex: Fruits noirs intenses, tanins soyeux, très belle longueur...';

  @override
  String get externalTastingSubmit => 'Enregistrer & Noter ✨';

  @override
  String get externalTastingNameRequired =>
      'Veuillez indiquer au moins le nom du vin.';

  @override
  String get externalTastingSaved =>
      'Dégustation hors cave enregistrée ! Le Chatmelier s\'en souviendra.';

  @override
  String externalTastingAiRecognized(String name) {
    return '✨ Bouteille reconnue par l\'IA : $name';
  }

  @override
  String externalTastingAiFilled(String name) {
    return '✨ Fiche complétée par l\'IA : $name';
  }

  @override
  String externalTastingAnalysisError(String error) {
    return 'Erreur d\'analyse : $error';
  }

  @override
  String externalTastingSaveError(String error) {
    return 'Erreur : $error';
  }
}
