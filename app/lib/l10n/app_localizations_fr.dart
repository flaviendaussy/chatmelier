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
  String get navCellar => 'Ma Cave';

  @override
  String get navChat => 'Chatmelier';

  @override
  String get navJournal => 'Historique';

  @override
  String get navStats => 'Statistiques';

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
}
