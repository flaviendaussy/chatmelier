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
  String get defaultCellarName => 'My Cellar';

  @override
  String get navCellar => 'Cellar';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'Tasting';

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
      'Hello! I am Chatmelier. Ask me for food pairings, drinking advice, or wine cellar recommendations based on what you currently have in stock.';

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

  @override
  String get navProfile => 'Profile';

  @override
  String get quickActions => 'QUICK ACTIONS';

  @override
  String get appSubtitle => 'Sommelier & Wine Cellar';

  @override
  String get profileTabPalate => 'Palate';

  @override
  String get profileTabSettings => 'Settings';

  @override
  String get profileTabTools => 'Tools';

  @override
  String get profileTabAccount => 'Account';

  @override
  String get profileTheme => 'Ambience / Theme';

  @override
  String get profileThemeLight => 'Light ☀️';

  @override
  String get profileThemeDark => 'Dark 🌙';

  @override
  String get profileThemeSystem => 'System ⚙️';

  @override
  String get profileFriends => 'Friends & Taste Maps 🍷';

  @override
  String get profileExport => 'Export Cellar & Valuation Report 📊';

  @override
  String get profileDeleteAccount => 'Permanently Delete My Account';

  @override
  String get profileDeleteConfirmTitle => 'Delete Permanently';

  @override
  String get profileDeleteConfirmMsg =>
      'This action is irreversible. All your data will be deleted.';

  @override
  String get badgesGalleryTitle => 'Trophy Gallery';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total unlocked • $pct% completed';
  }

  @override
  String get badgesFilterAll => 'All';

  @override
  String get badgesEmpty => 'No badges found in this category.';

  @override
  String get badgesUnlockedChip => 'Unlocked ✨';

  @override
  String get badgesStatusUnlocked => 'Badge Unlocked!';

  @override
  String get badgesStatusInProgress => 'In Progress';

  @override
  String get badgesObjectiveLabel => 'Objective:';

  @override
  String get badgesChatmelierLoreTitle => 'Chatmelier\'s Science & Lore';

  @override
  String get badgesCloseButton => 'Close';

  @override
  String get badgesTierLabel => 'Tier';

  @override
  String get badgesShowcaseTitle => 'Trophies & Badges';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked of $total unlocked';
  }

  @override
  String get badgesShowcaseGallery => 'Gallery';

  @override
  String get save => 'Save';

  @override
  String get continueAnyway => 'Continue anyway';

  @override
  String get cellarDetected => 'Cellar detected: ';

  @override
  String proximityWifi(String ssid) {
    return 'Connected to Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'GPS location detected at $distance';
  }

  @override
  String get proximitySwitch => 'Switch';

  @override
  String get proximityIgnore => 'Ignore';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Automatically switched to \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Distant cellar detected';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'You are currently connected to Wi-Fi \"$ssid\" associated with your other cellar \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'You are currently located approximately $distance from \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nDo you still want to add this bottle to the cellar \"$cellar\"?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nDo you still want to checkout this bottle from the cellar \"$cellar\"?';
  }

  @override
  String get ratingExceptional => '🏆 Exceptional';

  @override
  String get ratingRemarkable => '✨ Remarkable';

  @override
  String get ratingVeryGood => '🍷 Very good';

  @override
  String get ratingPleasant => '👍 Pleasant';

  @override
  String get ratingPassable => 'Fair';

  @override
  String get checkoutWhoTasted => 'Who tasted this wine with you?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'bottles',
      one: 'bottle',
    );
    return '$producer • In stock: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Add a guest';

  @override
  String get checkoutAddGuestHint => 'Add (Mom, Dad...)';

  @override
  String get checkoutCloseAndTaste => 'Close & Enjoy 🍷';

  @override
  String get checkoutSommelierThinking =>
      'The sommelier is preparing tasting stories...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Aeration timer active on your lock screen!';

  @override
  String get checkoutStartAerationTimer => 'Start timer ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Aeration Timer';

  @override
  String get checkoutDelayedTonight => 'Tonight at 10:00 PM';

  @override
  String get checkoutDelayedTonightSub =>
      'Ideal after the meal to savor the moment';

  @override
  String get checkoutDelayedTomorrow => 'Tomorrow morning at 11:00 AM';

  @override
  String get checkoutDelayedTomorrowSub =>
      'To recall your impressions in quiet';

  @override
  String get checkoutDelayedWeekend => 'This weekend (Saturday at 11:00 AM)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Take your time during your free moments';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'In 2 hours ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Quick reminder at the end of the tasting';

  @override
  String get checkoutDelayedCustom => 'Choose a custom date & time...';

  @override
  String get reviewPackagingDetected => 'Packaging Detected';

  @override
  String get reviewSingleBottleOnly => 'No, 1 bottle only';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Yes, $count bottles';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Stock updated successfully! ($count bottles in cellar)';
  }

  @override
  String get reviewVintageYear => 'Vintage / Year';

  @override
  String get reviewNonVintage => 'Skip / Non-vintage';

  @override
  String get reviewValidate => 'Confirm';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name added successfully to the cellar!';
  }

  @override
  String get reviewBottleAnalysis => 'Bottle Analysis';

  @override
  String get reviewDiscard => 'Discard';

  @override
  String get reviewDiscardConfirmTitle => 'Discard entry?';

  @override
  String get reviewContinueEditing => 'Continue editing';

  @override
  String get reviewDiscardWithoutSaving => 'Discard without saving';

  @override
  String get reviewBottleDetails => 'Bottle Details';

  @override
  String get reviewStockInCellar => 'Cellar stock';

  @override
  String get reviewStockAddition => 'Add';

  @override
  String get reviewStockNewTotal => 'New total';

  @override
  String get reviewQuantityToAdd => 'Quantity to add:';

  @override
  String get reviewSeparateEntry =>
      'Create a separate entry (different rack / price)';

  @override
  String get reviewRetryAi => 'Retry AI analysis';

  @override
  String get reviewEnlarge => 'Enlarge';

  @override
  String get reviewGeneralInfo => 'General Information';

  @override
  String get reviewOriginTerroir => 'Origin & Terroir';

  @override
  String get reviewQuantityPurchase => 'Quantity & Purchase';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi detected & linked: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Unable to detect Wi-Fi (enable location or enter manually)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS coordinates captured ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'GPS location unavailable. Check location permissions.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Cellar \"$cellar\" created successfully!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Error during creation: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 meters (very precise)';

  @override
  String get cellarRadiusRecommended => '300 meters (recommended)';

  @override
  String get cellarRadius500m => '500 meters';

  @override
  String get cellarRadius1km => '1 kilometer';

  @override
  String get cellarRadius3km => '3 kilometers';

  @override
  String get cellarCreateButton => 'Create cellar';

  @override
  String get cellarUseCurrentGps => 'Set with current GPS location';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Cellar settings for \"$cellar\" updated';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Error during update: $error';
  }

  @override
  String get wineTypeRed => 'Red 🍷';

  @override
  String get wineTypeWhite => 'White 🥂';

  @override
  String get wineTypeRose => 'Rosé 🌸';

  @override
  String get wineTypeSparkling => 'Sparkling 🍾';

  @override
  String get wineTypeDessert => 'Dessert / Sweet 🍯';

  @override
  String get wineTypeLiqueur => 'Liqueur 🍯';

  @override
  String get wineTypeSpirit => 'Spirits 🥃';

  @override
  String get wineTypeGrappa => 'Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Fruit Brandy 🍐';

  @override
  String get wineTypeWhisky => 'Whisky 🥃';

  @override
  String get wineTypeRum => 'Rum 🏴‍☠️';

  @override
  String get wineTypeGin => 'Gin 🍸';

  @override
  String get wineTypeVodka => 'Vodka 🧊';

  @override
  String get wineTypeTequila => 'Tequila 🌵';

  @override
  String get wineTypeCognac => 'Cognac 🍷';

  @override
  String get cellarCreateTitle => 'Create a new cellar';

  @override
  String get cellarManageTitle => 'Manage cellar';

  @override
  String get cellarNameLabel => 'Cellar name *';

  @override
  String get cellarNameHint => 'e.g., London Cellar, Vosges Cellar';

  @override
  String get cellarNameRequired => 'Please enter a name';

  @override
  String get cellarLocationLabel => 'Location / City (optional)';

  @override
  String get cellarLocationHint => 'e.g., London (UK), Beaune (FR)';

  @override
  String get cellarNicknameLabel => 'Nickname / Room (optional)';

  @override
  String get cellarNicknameHint => 'e.g., Basement, Main wine cooler';

  @override
  String get cellarDescriptionLabel => 'Description (optional)';

  @override
  String get cellarDescriptionHint =>
      'e.g., Cool underground cellar, 70% humidity';

  @override
  String get cellarWifiLabel => 'Associated Wi-Fi (optional)';

  @override
  String get cellarWifiHint => 'e.g., Home-Cellar-WiFi';

  @override
  String get cellarLinkCurrentWifi => 'Link to current Wi-Fi';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Capture current Wi-Fi';

  @override
  String get cellarRadiusLabel => 'GPS detection radius';

  @override
  String get cellarAutoDetectionHeader => 'Auto-Detection & Smart Transition';

  @override
  String get cellarAutoDetectionDesc =>
      'Link your Wi-Fi network or GPS coordinates to automatically switch to this cellar when you are there.';

  @override
  String get cellarLatitudeLabel => 'Latitude';

  @override
  String get cellarLongitudeLabel => 'Longitude';

  @override
  String get checkoutGuidedTasting => 'Guided Tasting';

  @override
  String get checkoutGuidedTastingShared =>
      'Share your impressions one by one or together';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analyze appearance, nose, palate & refine your profile';

  @override
  String get checkoutUncorkNowRateLater => 'Uncork now, rate later';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Instant checkout • Choose reminder time (tonight, tomorrow...)';

  @override
  String get checkoutUncorkAeration => 'Uncork & Aeration timer';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Instant checkout • $minutes min aeration recommended';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Instant checkout • Aeration / decanting timer';

  @override
  String get checkoutSommelierServiceAdvice => 'Sommelier Serving Advice';

  @override
  String get checkoutHistoryAnecdotes => 'Stories & Trivia';

  @override
  String get checkoutNoDecanting => 'No decanting';

  @override
  String get checkoutStoryTitle => 'The Story of this Bottle 📖';

  @override
  String get checkoutStorySubtitle =>
      'Captivating stories to share at the table';

  @override
  String get checkoutStoryTerroir => 'Terroir & Grapes';

  @override
  String get checkoutStoryVintage => 'The Vintage Story';

  @override
  String get checkoutStoryTastingSecret => 'Tasting Secret';

  @override
  String get checkoutStoryTableAnecdote => 'Table Anecdote';

  @override
  String get checkoutJournalArchivedNotice =>
      'Rest assured: this bottle will be carefully archived in your Tasting Journal with your photos and notes.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Bottle uncorked! Aeration timer ($minutes min) running on your lock screen.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'The bottle will be immediately uncorked and checked out. Confirm the aeration duration before tasting:';

  @override
  String get checkoutRateWine => 'Rate wine';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Timer ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Sommelier Tip: aerate for $minutes min. Lockscreen timer ready.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Reminder scheduled after tasting to record your impressions.';

  @override
  String get checkoutBottleRemovedSuccess => 'Bottle checked out from cellar!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Enjoy your tasting. Reminder scheduled $date to record your impressions.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'Each participant\'s taste profile will automatically be enriched.';

  @override
  String checkoutCellarOf(String name) {
    return '$name\'s Cellar';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Stock: $count btl.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Add a loved one or family member present at this tasting (e.g., Mom, Dad, Sophie...).';

  @override
  String get checkoutAddGuestNameLabel => 'First name / Name';

  @override
  String get checkoutDelayedSheetTitle => 'Uncork & Rate later';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'When would you like to receive a reminder for your impressions?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Tonight in 2 hours ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Tonight at 9:00 PM';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'tonight at $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'tomorrow at $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'on $date at $time';
  }

  @override
  String get add => 'Add';

  @override
  String get cellarWinesTab => '🍷 Wines';

  @override
  String get cellarSpiritsTab => '🥃 Spirits';

  @override
  String get cellarPairWithDish => 'Pair wine with dish';

  @override
  String get cellarCollapseAll => 'Collapse all';

  @override
  String get cellarExpandAll => 'Expand all';

  @override
  String get cellarSort => 'Sort';

  @override
  String get cellarCategories => 'Categories';

  @override
  String get cellarFavorites => 'Favorites';

  @override
  String get cellarGridView => 'Grid';

  @override
  String get cellarListView => 'List';

  @override
  String get cellarClearFilters => 'Clear filters';

  @override
  String get cellarNoBottlesCategory => 'No bottles in this category';

  @override
  String get cellarNoBottlesCriteria => 'No bottles match these criteria';

  @override
  String get feedbackSheetTitle => 'Tester Feedback & Annotation';

  @override
  String get feedbackStylus => 'Pen:';

  @override
  String get feedbackUndo => 'Undo last stroke';

  @override
  String get feedbackClear => 'Clear all';

  @override
  String get feedbackHint =>
      'Circle the area and describe your feedback or bug...';

  @override
  String get feedbackSubmit => 'Send report';

  @override
  String get feedbackSubmitting => 'Sending...';

  @override
  String get feedbackNoScreenshot => 'No screenshot available';

  @override
  String get feedbackEmptyError =>
      'Please add a comment or draw on the screenshot.';

  @override
  String get feedbackSuccess =>
      'Thank you for your feedback! 🍷 The report was sent.';

  @override
  String feedbackError(String error) {
    return 'Error sending feedback: $error';
  }

  @override
  String get checkoutFastExit => 'Quick exit without questionnaire';

  @override
  String get checkoutFastExitSubmitting => 'Processing checkout...';

  @override
  String get checkoutRatingSubtitle =>
      'Rate your overall impression after tasting';

  @override
  String get checkoutRecommendedBadge => 'Recommended';

  @override
  String get tastingWhoTastedTitle => '👥 Who tasted this wine?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Select the tasters. Taste profiles will be enriched automatically.';

  @override
  String get tastingHowToTaste => 'How to taste?';

  @override
  String get tastingEachTurn => 'Taking turns';

  @override
  String get tastingEachTurnDesc =>
      '📱 Pass the phone: each person answers separately at their own pace.';

  @override
  String get tastingTogether => 'Together';

  @override
  String get tastingTogetherDesc =>
      '🥂 A single questionnaire completed together for all guests.';

  @override
  String get tastingBlindMode => 'Blind Tasting Mode';

  @override
  String get tastingBlindModeDesc =>
      'Hides the wine name and launches an interactive table quiz with a grand reveal!';

  @override
  String get tastingPrimaryProfile => 'Primary profile';

  @override
  String get tastingAppInstalled => 'App installed 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questionnaires completed',
      one: '1 questionnaire completed',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '🍇 The Nose — Aromas';

  @override
  String get tastingStepNezSubtitle =>
      'Which aromas did you perceive? (Multiple choices possible)';

  @override
  String get tastingFaultTitle => 'Does the wine smell of any of these?';

  @override
  String get tastingFaultSubtitle =>
      'If so, the bottle is faulty — it\'s neither your palate nor the wine\'s style.';

  @override
  String get tastingFaultCorkLabel => '📦 Damp cardboard, musty cellar';

  @override
  String get tastingFaultCorkExplain =>
      'Cork taint (TCA). The wine is blameless and airing won\'t help — at a restaurant, you can ask for another bottle.';

  @override
  String get tastingFaultOxidationLabel => '🍎 Bruised apple, vinegar, sherry';

  @override
  String get tastingFaultOxidationExplain =>
      'Oxidation. The bottle has taken in air, often through a failing cork or too long in the cellar.';

  @override
  String get tastingFaultReductionLabel => '🥚 Struck match, egg, cabbage';

  @override
  String get tastingFaultReductionExplain =>
      'Reduction. Good news: it often blows off with air. Decant for twenty minutes and taste again before judging.';

  @override
  String get tastingFaultExcluded =>
      'This tasting won\'t count towards your taste profile.';

  @override
  String get tastingAromaIntensity => 'Aromatic intensity:';

  @override
  String get tastingAromaDiscreet => '🤫 Subtle';

  @override
  String get tastingAromaExplosive => '💥 Explosive';

  @override
  String get tastingStepBoucheTitle => '⚖️ The Palate — Balance';

  @override
  String get tastingStepBoucheSubtitle =>
      'Describe the texture and balance of the wine on the palate.';

  @override
  String get tastingAcidity => 'Acidity:';

  @override
  String get tastingAcidityFreshness => 'Acidity & Crispness:';

  @override
  String get tastingAcidityFlat => '🫠 Flabby / Flat';

  @override
  String get tastingAciditySharp => '⚡ Crisp / Sharp';

  @override
  String get tastingTannins => 'Tannins:';

  @override
  String get tastingTanninsSilky => '🧶 Silky / Soft';

  @override
  String get tastingTanninsGrippy => '💪 Grippy / Firm';

  @override
  String get tastingMinerality => 'Minerality & Freshness:';

  @override
  String get tastingMineralityRound => '🧈 Round / Buttery';

  @override
  String get tastingMineralityCrisp => '🪨 Mineral / Precise';

  @override
  String get tastingEffervescence => 'Effervescence:';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fine / Delicate';

  @override
  String get tastingEffervescenceVibrant => '🎆 Lively / Creamy';

  @override
  String get tastingBody => 'Body / Texture:';

  @override
  String get tastingBodyLight => '🍃 Light / Airy';

  @override
  String get tastingBodyFull => '🏋️ Full / Bold';

  @override
  String get tastingLength => 'Finish / Length:';

  @override
  String get tastingLengthShort => '⏱️ Short';

  @override
  String get tastingLengthLong => '♾️ Lingering';

  @override
  String get tastingStepVerdictTitle => '✅ Final Verdict';

  @override
  String get sipSectionTitle => '🍷 The sip';

  @override
  String get sipSectionSubtitle =>
      'Two taps, and this glass teaches your taste profile something.';

  @override
  String get tastingBuyAgain => 'Would you buy this bottle again?';

  @override
  String get tastingBuyAgainYes => '🤩 Absolutely!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Maybe';

  @override
  String get tastingBuyAgainNo => '👎 No thanks';

  @override
  String get tastingIdealMoment => 'Ideal occasion for this wine?';

  @override
  String get tastingMomentApero => '🥂 Aperitif';

  @override
  String get tastingMomentMeal => '🍽️ Casual dining';

  @override
  String get tastingMomentDinner => '🎩 Fine dining';

  @override
  String get tastingMomentRomantic => '🕯️ Romantic dinner';

  @override
  String get tastingMomentSolo => '🧘 Solo / Quiet moment';

  @override
  String get tastingWhatLiked => 'What you liked most:';

  @override
  String get tastingWhatDisliked => 'What you disliked most:';

  @override
  String get tastingOccasionLabel => 'Occasion / Shared memory (optional) ✨';

  @override
  String get tastingOccasionHint =>
      'e.g. Birthday, Candlelit dinner, Reunion...';

  @override
  String get tastingAddPhoto => 'Add a photo memory of the table 📸';

  @override
  String get tastingPhotoSaved => 'Photo memory saved 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Final Rating & Impression';

  @override
  String get tastingStepImpressionSubtitle =>
      'After savoring the nose and palate, assign your overall rating.';

  @override
  String get tastingOverallFeeling => 'Your overall impression:';

  @override
  String get tastingScoreOutOf10 => 'Rating out of 10:';

  @override
  String get tastingCompletedTitle => 'Tasting completed & recorded!';

  @override
  String get tastingCompletedSubtitle =>
      'Taste profiles have been successfully updated ✨';

  @override
  String get tastingBottleRemoved => 'Bottle uncorked & removed from cellar';

  @override
  String get tastingConsultDebrief =>
      'View Sommelier Debrief (Hidden nuances & Terroir)';

  @override
  String get tastingFinishButton => 'Finish ✨';

  @override
  String get tastingNextTaster => 'Validate → Next taster';

  @override
  String get tastingConfirmAndFinish => 'Validate & Finish ✨';

  @override
  String get tastingQuitTitle => 'Leave the questionnaire?';

  @override
  String get tastingQuitMessage => 'Your answers will not be saved.';

  @override
  String get tastingContinue => 'Continue';

  @override
  String get tastingQuit => 'Leave';

  @override
  String tastingStartCount(int count) {
    return 'Start ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Synced to $name\'s app ✨';
  }

  @override
  String get tastingProfileEnriched => 'Taste profile enriched';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Sensory acuity: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle => 'Origins of Flavors & Wine Secrets';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Discover where your wine\'s aromas, color, and structure come from';

  @override
  String get tastingBlindQuizTitle => 'Blind Tasting Table Quiz 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. What is the region of origin? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. What is the primary grape? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Estimated age / vintage? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Estimated price? 💶';

  @override
  String get tastingBlindRevealTitle => 'Mystery Bottle Grand Reveal 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Blind Quiz Score: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Enological & Molecular Debrief';

  @override
  String get tastingSensoryAcuity => 'SENSORY ACUITY';

  @override
  String tastingPrecision(int score) {
    return '$score% Accuracy';
  }

  @override
  String get tastingConcordanceTitle => '1. CONCORDANCE & CRU SIGNATURE';

  @override
  String get tastingWhatYouDetected => 'WHAT YOU DETECTED:';

  @override
  String get tastingArchetypeSignature => 'ARCHETYPAL SIGNATURE OF THE WINE:';

  @override
  String get tastingHiddenNuancesTitle =>
      'SUBTLE NUANCES TO SPOT IN YOUR NEXT GLASS:';

  @override
  String get tastingPillarsTitle => '2. ENOLOGICAL SCIENCE & MOLECULES';

  @override
  String get tastingPillarsSubtitle =>
      'Why does this wine have this structure, these aromas, and this color?';

  @override
  String get tastingChatWithSommelier =>
      'Deepen winemaking secrets with Chatmelier';

  @override
  String get aromaFruitsRouges => 'Red berries';

  @override
  String get aromaFruitsNoirs => 'Dark berries';

  @override
  String get aromaFruitsBlancs => 'Stone / Orchard fruit';

  @override
  String get aromaAgrumes => 'Citrus';

  @override
  String get aromaFloral => 'Floral';

  @override
  String get aromaVegetal => 'Herbal / Vegetal';

  @override
  String get aromaEpicesDouces => 'Sweet spices';

  @override
  String get aromaEpicesVives => 'Pungent spices / Pepper';

  @override
  String get aromaBoise => 'Oak / Vanilla';

  @override
  String get aromaBeurre => 'Butter / Brioche';

  @override
  String get aromaMineral => 'Mineral / Flint';

  @override
  String get aromaMiel => 'Honey / Jam';

  @override
  String get aromaChocolat => 'Chocolate / Coffee';

  @override
  String get aromaFumee => 'Smoke / Toasted';

  @override
  String get emojiDisliked => 'Disliked';

  @override
  String get emojiMeh => 'Meh';

  @override
  String get emojiDecent => 'Decent';

  @override
  String get emojiVeryGood => 'Very good';

  @override
  String get emojiLoved => 'Loved it';

  @override
  String get likedFreshness => 'Freshness';

  @override
  String get likedFruitiness => 'Fruitiness';

  @override
  String get likedComplexity => 'Complexity';

  @override
  String get likedElegance => 'Elegance';

  @override
  String get likedPower => 'Power & Body';

  @override
  String get likedSilky => 'Silky texture';

  @override
  String get likedOriginality => 'Originality';

  @override
  String get likedFoodPairing => 'Food pairing synergy';

  @override
  String get likedMinerality => 'Minerality';

  @override
  String get likedLength => 'Finish length';

  @override
  String get likedDisappointing => 'Nothing / Disappointing 😕';

  @override
  String get dislikedTooAcidic => 'Too acidic';

  @override
  String get dislikedTooTannic => 'Too tannic';

  @override
  String get dislikedTooOaked => 'Too oaked / vanilla';

  @override
  String get dislikedTooAlcoholic => 'Too alcoholic / hot';

  @override
  String get dislikedTooThin => 'Too light / watery';

  @override
  String get dislikedLacksFruit => 'Lacks fruit';

  @override
  String get dislikedTooSweet => 'Too sweet';

  @override
  String get dislikedTooExpensive => 'Too pricey for quality';

  @override
  String get dislikedNothing => 'Nothing, it was perfect!';

  @override
  String get tastingStepTasters => 'Tasters';

  @override
  String get tastingStepNezNav => 'The Nose';

  @override
  String get tastingStepBoucheNav => 'The Palate';

  @override
  String get tastingStepVerdictNav => 'Verdict';

  @override
  String get tastingStepRatingNav => 'Final Rating';

  @override
  String get tastingBack => 'Back';

  @override
  String get tastingNext => 'Next';

  @override
  String get tastingSaving => 'Saving...';

  @override
  String get tastingHeaderTitle => 'Tasting Questionnaire';

  @override
  String tastingAnswersOf(String name) {
    return 'Answers by $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Pass the phone to $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Your answers have been recorded.\nIt is now $name\'s turn.';
  }

  @override
  String get tastingDictateButton => 'Dictate table impressions 🎙️';

  @override
  String get tastingDictateHint =>
      'Speak or write naturally, Chatmelier AI will pre-fill your aromas and palate balance!';

  @override
  String get tastingDictateMicTip =>
      'Tip: enable the microphone on your keyboard to dictate aloud!';

  @override
  String get tastingTakePhoto => 'Take a table photo 📸';

  @override
  String get tastingChooseGallery => 'Choose from gallery 🖼️';

  @override
  String get tastingConclaveSummary => 'Conclave Summary';

  @override
  String get tastingCellarMaster => 'Cellar Master';

  @override
  String get tastingGuestTaster => 'Guest Taster';

  @override
  String tastingProfileTag(String type) {
    return 'Profile: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Freeform tasting recorded.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Appearance: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Structure: $structure ($caudalies caudalies)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Key molecules: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Key: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Grape varieties: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Tasting impressions applied by Chatmelier AI ✨';

  @override
  String get tastingBlindYourPredictions => 'Blind table predictions summary:';

  @override
  String get tastingBlindGuessCorrect => 'Correct! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Make your table predictions before the grand final reveal!';

  @override
  String tastingStartTaster(String name) {
    return 'Let\'s go, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Bravo!';

  @override
  String tastingQuizWas(String answer) {
    return '(It was: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'E.g.: Bernard loved it, 8.5/10 with undergrowth and blackcurrant notes. Caro gave 7/10 finding the wine slightly acidic...';

  @override
  String get tastingDictateAnalyzing => 'Analyzing...';

  @override
  String get tastingDictateAnalyzeAndApply => 'Analyze & Apply to Sheets ✨';

  @override
  String get tastingFormatExpress => 'Express Format (1 page) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Rating, key aromas and quick verdict in 30s';

  @override
  String get tastingFormatSommelier => 'Sommelier Format (Detailed) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'In-depth nose, palate balance, finish & terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'What is a caudalie? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalie = 1 second of lingering flavor after swallowing or spitting.\n• 1 to 4 caudalies: light, crisp wine\n• 5 to 7 caudalies: beautiful balance\n• 8 to 12+ caudalies: exceptional fine wine!';

  @override
  String get tastingAddCustomAroma => '+ Custom aroma';

  @override
  String get tastingCustomAromaDialogTitle => 'Add a precise aroma';

  @override
  String get tastingCustomAromaHint =>
      'e.g. Smoked flint, Wild blackberry, Dried rose...';

  @override
  String get tastingFoodSynergyTitle => 'Food pairing synergy 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Elevated';

  @override
  String get tastingSynergyHarmonious => '👍 Balanced';

  @override
  String get tastingSynergyNeutral => '😐 Neutral';

  @override
  String get tastingSynergyClashing => '⚡ Clashing';

  @override
  String get checkoutFastRatingTitle => '1-tap quick rating (optional):';

  @override
  String get checkoutActionTastingTitle => 'Taste this wine';

  @override
  String get checkoutActionTastingSubtitle =>
      'Express (1 page) or detailed sommelier format';

  @override
  String get checkoutActionDeferredRemind => 'Remind later 🌙';

  @override
  String get checkoutActionAerationTimer => 'Aeration timer ⏱️';
}
