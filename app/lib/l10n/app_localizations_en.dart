// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get navCellar => 'Cellar';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'History';

  @override
  String get navStats => 'Stats';

  @override
  String get actionMenuTitle => 'Cellar Actions';

  @override
  String get actionAddBottle => 'Add a bottle';

  @override
  String get actionAddBottleSub => 'Scan label or manual entry';

  @override
  String get actionCheckoutBottle => 'Taste / Checkout bottle';

  @override
  String get actionCheckoutBottleSub => 'Record tasting & decrement stock';

  @override
  String get actionLookupWine => 'Consult / Identify a wine';

  @override
  String get actionLookupWineSub => 'Instant AI wine discovery';

  @override
  String get searchWinePlaceholder =>
      'Search vintage, producer, appellation...';

  @override
  String get emptyCellarTitle => 'Your cellar is empty';

  @override
  String get emptyCellarSub =>
      'Scan your first bottle to start building your digital collection';

  @override
  String get emptyCellarButton => 'Add my first bottle';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bottles',
      one: '1 bottle',
      zero: '0 bottles',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Total value';

  @override
  String get filterAll => 'All';

  @override
  String get filterRed => 'Red';

  @override
  String get filterWhite => 'White';

  @override
  String get filterRose => 'Rosé';

  @override
  String get filterSparkling => 'Sparkling';

  @override
  String get filterSheetTitle => 'Cellar Filters';

  @override
  String get filterReset => 'Reset';

  @override
  String get filterApply => 'Apply filters';

  @override
  String get filterMaturity => 'Maturity / Drinking Window';

  @override
  String get maturityAtPeak => 'At Peak';

  @override
  String get maturityDrinkSoon => 'Drink Soon';

  @override
  String get maturityAging => 'Aging';

  @override
  String get maturityTooYoung => 'Too Young';

  @override
  String get maturityPastPeak => 'Past Peak';

  @override
  String get filterContinents => 'Continents';

  @override
  String get filterCountries => 'Countries';

  @override
  String get filterGrapes => 'Grape Varieties';

  @override
  String get filterAppellations => 'Regions & Appellations';

  @override
  String get bottleDetailInfo => 'Information & Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Drinking Window';

  @override
  String get bottleDetailTerroirMap => 'Terroir & Origin Map';

  @override
  String get bottleDetailLabelPhoto => 'Original Scanned Label';

  @override
  String get bottleDetailVintage => 'Vintage';

  @override
  String get bottleDetailProducer => 'Producer';

  @override
  String get bottleDetailRegion => 'Region';

  @override
  String get bottleDetailCountry => 'Country';

  @override
  String get bottleDetailAppellation => 'Appellation';

  @override
  String get bottleDetailGrapes => 'Grape Varieties';

  @override
  String get bottleDetailAlcohol => 'Alcohol';

  @override
  String get bottleDetailStock => 'Stock';

  @override
  String get bottleDetailLocation => 'Cellar Location';

  @override
  String get bottleDetailRack => 'Rack';

  @override
  String get bottleDetailShelf => 'Shelf';

  @override
  String get bottleDetailPurchasePrice => 'Purchase Price';

  @override
  String get bottleDetailEstimatedValue => 'Estimated Value';

  @override
  String get bottleDetailFoodPairings => 'Recommended Food Pairings';

  @override
  String get bottleDetailTastingNotes => 'Sommelier Profile';

  @override
  String get bottleDetailDrinkButton => 'Checkout this bottle';

  @override
  String get bottleDetailEdit => 'Edit';

  @override
  String get bottleDetailDelete => 'Delete';

  @override
  String get bottleDetailDeleteConfirm =>
      'Are you sure you want to permanently delete this bottle from your cellar?';

  @override
  String get deleteBottleTitle => 'Permanently Delete';

  @override
  String get deleteBottleExplanation =>
      'Warning: deleting permanently removes all traces of this bottle from your cellar and history.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Checkout / Drink: archives the bottle in your tasting history, updates your stats and preserves your notes.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Permanently delete: completely erases the record without keeping any trace (recommended for typos, broken bottles, or duplicates).';

  @override
  String get deleteBottleActionConfirm => 'Permanently Delete';

  @override
  String get deleteBottleActionDrinkInstead => 'Checkout / Drink instead';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get checkoutTitle => 'Taste & Checkout from Cellar';

  @override
  String get checkoutSelectPrompt =>
      'Tap to choose a bottle from your cellar...';

  @override
  String get checkoutQtyOpened => 'Number of bottles opened';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'out of $total in cellar';
  }

  @override
  String get checkoutRating => 'Tasting Rating';

  @override
  String get checkoutFoodPairing => 'Associated Food & Dishes (optional)';

  @override
  String get checkoutFoodHint =>
      'e.g., Grilled ribeye steak, mushroom risotto...';

  @override
  String get checkoutNotes => 'Tasting Impressions & Comments';

  @override
  String get checkoutNotesHint => 'Aromas, balance, length, emotions...';

  @override
  String get checkoutSubmit => 'Confirm tasting';

  @override
  String get checkoutSuccess => 'Tasting recorded successfully!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Bonjour ! I am Chatmelier. Ask me for food pairings, drinking advice, or wine cellar recommendations based on what you currently have in stock.';

  @override
  String get chatAnalyzing => 'Chatmelier is analyzing your cellar...';

  @override
  String get chatInputHint => 'Ask Chatmelier...';

  @override
  String get chatChipTonight => '🍷 What should I drink tonight?';

  @override
  String get chatChipSteak => '🥩 Pair a bottle with steak';

  @override
  String get chatChipSeafood => '🐟 Best white for seafood';

  @override
  String get chatChipPeak => '⏰ Which bottles are at their peak?';

  @override
  String get journalTitle => 'Tasting Journal';

  @override
  String get journalEmpty => 'No tastings recorded yet';

  @override
  String get journalEmptySub =>
      'Checkout and taste a bottle from your cellar to start your log';

  @override
  String journalTastedOn(String date) {
    return 'Tasted on $date';
  }

  @override
  String get statsTitle => 'Cellar Statistics';

  @override
  String get statsTotalBottles => 'Bottles in Cellar';

  @override
  String get statsTotalValue => 'Cellar Value';

  @override
  String get statsBottlesEnjoyed => 'Bottles Enjoyed';

  @override
  String get statsByColor => 'Distribution by Wine Color';

  @override
  String get statsByMaturity => 'Distribution by Maturity';

  @override
  String get statsByRegion => 'Top Regions';

  @override
  String get statsByCountry => 'Top Countries';

  @override
  String get profileTitle => 'Profile & Settings';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileDisplayName => 'Display Name';

  @override
  String get profileDefaultCurrency => 'Default Currency';

  @override
  String get profileLanguage => 'App Language';

  @override
  String get profileLanguageSystem => 'Automatic (System Default)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Default currency updated: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Language updated';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileAbout => 'About Chatmelier';

  @override
  String get scanTitle => 'Scan Wine Label';

  @override
  String get scanTakePhoto => 'Take photo';

  @override
  String get scanPickGallery => 'Choose from gallery';

  @override
  String get scanAnalyzing => 'Chatmelier AI is analyzing the label...';

  @override
  String get scanIdentified => 'Wine identified by Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Add to my cellar';

  @override
  String get loginTitle => 'Login';

  @override
  String get loginTagline => 'Your Shared AI-Powered Wine Cellar';

  @override
  String get loginTabMagicLink => '✉️ Sign-in Link';

  @override
  String get loginTabPassword => '🔑 Password';

  @override
  String get loginEmailLabel => 'Email address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSendMagicLink => 'Get Sign-in Link';

  @override
  String get loginSignInButton => 'Sign In';

  @override
  String get loginOrDivider => 'OR';

  @override
  String get loginGoogleButton => 'Continue with Google';

  @override
  String get loginRegisterLink => 'Don\'t have an account? Create one';

  @override
  String get registerTitle => 'Create Account';

  @override
  String get registerNameLabel => 'Display Name / First Name';

  @override
  String get registerSubmitButton => 'Create my account';

  @override
  String get registerFillAllFields => 'Please fill in all fields';

  @override
  String get registerWelcome => '🎉 Welcome to Chatmelier!';

  @override
  String get registerErrorGeneric => 'Registration error';

  @override
  String get authWelcome => 'Welcome to Chatmelier';

  @override
  String get authSubtitle => 'Your smart wine cellar manager & AI companion';

  @override
  String get authGoogle => 'Continue with Google';

  @override
  String get authMagicLink => 'Sign in with email link';

  @override
  String get authEmail => 'Email address';

  @override
  String get authNoAccount => 'Don\'t have an account? Sign up';

  @override
  String get authHaveAccount => 'Already have an account? Log in';

  @override
  String get changelogTitle => 'Changelog & Version Notes';

  @override
  String get changelogEmpty => 'No changelog entries available.';

  @override
  String get scratchcardTitle => 'World Terroirs Scratchcard';

  @override
  String get profileChangelog => 'Version History & Changelog';

  @override
  String get profileScratchcard => 'World Terroirs Scratchcard';
}
