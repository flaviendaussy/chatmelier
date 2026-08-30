import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Chatmelier'**
  String get appTitle;

  /// No description provided for @navCellar.
  ///
  /// In en, this message translates to:
  /// **'Cellar'**
  String get navCellar;

  /// No description provided for @navChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get navChat;

  /// No description provided for @navJournal.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get navJournal;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @actionMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Cellar Actions'**
  String get actionMenuTitle;

  /// No description provided for @actionAddBottle.
  ///
  /// In en, this message translates to:
  /// **'Add a bottle'**
  String get actionAddBottle;

  /// No description provided for @actionAddBottleSub.
  ///
  /// In en, this message translates to:
  /// **'Scan label or manual entry'**
  String get actionAddBottleSub;

  /// No description provided for @actionCheckoutBottle.
  ///
  /// In en, this message translates to:
  /// **'Taste / Checkout bottle'**
  String get actionCheckoutBottle;

  /// No description provided for @actionCheckoutBottleSub.
  ///
  /// In en, this message translates to:
  /// **'Record tasting & decrement stock'**
  String get actionCheckoutBottleSub;

  /// No description provided for @actionLookupWine.
  ///
  /// In en, this message translates to:
  /// **'Consult / Identify a wine'**
  String get actionLookupWine;

  /// No description provided for @actionLookupWineSub.
  ///
  /// In en, this message translates to:
  /// **'Instant AI wine discovery'**
  String get actionLookupWineSub;

  /// No description provided for @searchWinePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search vintage, producer, appellation...'**
  String get searchWinePlaceholder;

  /// No description provided for @emptyCellarTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cellar is empty'**
  String get emptyCellarTitle;

  /// No description provided for @emptyCellarSub.
  ///
  /// In en, this message translates to:
  /// **'Scan your first bottle to start building your digital collection'**
  String get emptyCellarSub;

  /// No description provided for @emptyCellarButton.
  ///
  /// In en, this message translates to:
  /// **'Add my first bottle'**
  String get emptyCellarButton;

  /// No description provided for @cellarBottlesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 bottles} =1{1 bottle} other{{count} bottles}}'**
  String cellarBottlesCount(int count);

  /// No description provided for @cellarTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Total value'**
  String get cellarTotalValue;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get filterRed;

  /// No description provided for @filterWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get filterWhite;

  /// No description provided for @filterRose.
  ///
  /// In en, this message translates to:
  /// **'Rosé'**
  String get filterRose;

  /// No description provided for @filterSparkling.
  ///
  /// In en, this message translates to:
  /// **'Sparkling'**
  String get filterSparkling;

  /// No description provided for @filterSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Cellar Filters'**
  String get filterSheetTitle;

  /// No description provided for @filterReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get filterReset;

  /// No description provided for @filterApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get filterApply;

  /// No description provided for @filterMaturity.
  ///
  /// In en, this message translates to:
  /// **'Maturity / Drinking Window'**
  String get filterMaturity;

  /// No description provided for @maturityAtPeak.
  ///
  /// In en, this message translates to:
  /// **'At Peak'**
  String get maturityAtPeak;

  /// No description provided for @maturityDrinkSoon.
  ///
  /// In en, this message translates to:
  /// **'Drink Soon'**
  String get maturityDrinkSoon;

  /// No description provided for @maturityAging.
  ///
  /// In en, this message translates to:
  /// **'Aging'**
  String get maturityAging;

  /// No description provided for @maturityTooYoung.
  ///
  /// In en, this message translates to:
  /// **'Too Young'**
  String get maturityTooYoung;

  /// No description provided for @maturityPastPeak.
  ///
  /// In en, this message translates to:
  /// **'Past Peak'**
  String get maturityPastPeak;

  /// No description provided for @filterContinents.
  ///
  /// In en, this message translates to:
  /// **'Continents'**
  String get filterContinents;

  /// No description provided for @filterCountries.
  ///
  /// In en, this message translates to:
  /// **'Countries'**
  String get filterCountries;

  /// No description provided for @filterGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grape Varieties'**
  String get filterGrapes;

  /// No description provided for @filterAppellations.
  ///
  /// In en, this message translates to:
  /// **'Regions & Appellations'**
  String get filterAppellations;

  /// No description provided for @bottleDetailInfo.
  ///
  /// In en, this message translates to:
  /// **'Information & Terroir'**
  String get bottleDetailInfo;

  /// No description provided for @bottleDetailDrinkingWindow.
  ///
  /// In en, this message translates to:
  /// **'Drinking Window'**
  String get bottleDetailDrinkingWindow;

  /// No description provided for @bottleDetailTerroirMap.
  ///
  /// In en, this message translates to:
  /// **'Terroir & Origin Map'**
  String get bottleDetailTerroirMap;

  /// No description provided for @bottleDetailLabelPhoto.
  ///
  /// In en, this message translates to:
  /// **'Original Scanned Label'**
  String get bottleDetailLabelPhoto;

  /// No description provided for @bottleDetailVintage.
  ///
  /// In en, this message translates to:
  /// **'Vintage'**
  String get bottleDetailVintage;

  /// No description provided for @bottleDetailProducer.
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get bottleDetailProducer;

  /// No description provided for @bottleDetailRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get bottleDetailRegion;

  /// No description provided for @bottleDetailCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get bottleDetailCountry;

  /// No description provided for @bottleDetailAppellation.
  ///
  /// In en, this message translates to:
  /// **'Appellation'**
  String get bottleDetailAppellation;

  /// No description provided for @bottleDetailGrapes.
  ///
  /// In en, this message translates to:
  /// **'Grape Varieties'**
  String get bottleDetailGrapes;

  /// No description provided for @bottleDetailAlcohol.
  ///
  /// In en, this message translates to:
  /// **'Alcohol'**
  String get bottleDetailAlcohol;

  /// No description provided for @bottleDetailStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get bottleDetailStock;

  /// No description provided for @bottleDetailLocation.
  ///
  /// In en, this message translates to:
  /// **'Cellar Location'**
  String get bottleDetailLocation;

  /// No description provided for @bottleDetailRack.
  ///
  /// In en, this message translates to:
  /// **'Rack'**
  String get bottleDetailRack;

  /// No description provided for @bottleDetailShelf.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get bottleDetailShelf;

  /// No description provided for @bottleDetailPurchasePrice.
  ///
  /// In en, this message translates to:
  /// **'Purchase Price'**
  String get bottleDetailPurchasePrice;

  /// No description provided for @bottleDetailEstimatedValue.
  ///
  /// In en, this message translates to:
  /// **'Estimated Value'**
  String get bottleDetailEstimatedValue;

  /// No description provided for @bottleDetailFoodPairings.
  ///
  /// In en, this message translates to:
  /// **'Recommended Food Pairings'**
  String get bottleDetailFoodPairings;

  /// No description provided for @bottleDetailTastingNotes.
  ///
  /// In en, this message translates to:
  /// **'Sommelier Profile'**
  String get bottleDetailTastingNotes;

  /// No description provided for @bottleDetailDrinkButton.
  ///
  /// In en, this message translates to:
  /// **'Checkout this bottle'**
  String get bottleDetailDrinkButton;

  /// No description provided for @bottleDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get bottleDetailEdit;

  /// No description provided for @bottleDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get bottleDetailDelete;

  /// No description provided for @bottleDetailDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this bottle from your cellar?'**
  String get bottleDetailDeleteConfirm;

  /// No description provided for @deleteBottleTitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get deleteBottleTitle;

  /// No description provided for @deleteBottleExplanation.
  ///
  /// In en, this message translates to:
  /// **'Warning: deleting permanently removes all traces of this bottle from your cellar and history.'**
  String get deleteBottleExplanation;

  /// No description provided for @deleteBottleDifferenceDrink.
  ///
  /// In en, this message translates to:
  /// **'Checkout / Drink: archives the bottle in your tasting history, updates your stats and preserves your notes.'**
  String get deleteBottleDifferenceDrink;

  /// No description provided for @deleteBottleDifferenceDelete.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete: completely erases the record without keeping any trace (recommended for typos, broken bottles, or duplicates).'**
  String get deleteBottleDifferenceDelete;

  /// No description provided for @deleteBottleActionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete'**
  String get deleteBottleActionConfirm;

  /// No description provided for @deleteBottleActionDrinkInstead.
  ///
  /// In en, this message translates to:
  /// **'Checkout / Drink instead'**
  String get deleteBottleActionDrinkInstead;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @checkoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Taste & Checkout from Cellar'**
  String get checkoutTitle;

  /// No description provided for @checkoutSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a bottle from your cellar...'**
  String get checkoutSelectPrompt;

  /// No description provided for @checkoutQtyOpened.
  ///
  /// In en, this message translates to:
  /// **'Number of bottles opened'**
  String get checkoutQtyOpened;

  /// No description provided for @checkoutQtyOfTotal.
  ///
  /// In en, this message translates to:
  /// **'out of {total} in cellar'**
  String checkoutQtyOfTotal(int total);

  /// No description provided for @checkoutRating.
  ///
  /// In en, this message translates to:
  /// **'Tasting Rating'**
  String get checkoutRating;

  /// No description provided for @checkoutFoodPairing.
  ///
  /// In en, this message translates to:
  /// **'Associated Food & Dishes (optional)'**
  String get checkoutFoodPairing;

  /// No description provided for @checkoutFoodHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Grilled ribeye steak, mushroom risotto...'**
  String get checkoutFoodHint;

  /// No description provided for @checkoutNotes.
  ///
  /// In en, this message translates to:
  /// **'Tasting Impressions & Comments'**
  String get checkoutNotes;

  /// No description provided for @checkoutNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Aromas, balance, length, emotions...'**
  String get checkoutNotesHint;

  /// No description provided for @checkoutSubmit.
  ///
  /// In en, this message translates to:
  /// **'Confirm tasting'**
  String get checkoutSubmit;

  /// No description provided for @checkoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Tasting recorded successfully!'**
  String get checkoutSuccess;

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Chatmelier'**
  String get chatTitle;

  /// No description provided for @chatGreeting.
  ///
  /// In en, this message translates to:
  /// **'Bonjour ! I am Chatmelier. Ask me for food pairings, drinking advice, or wine cellar recommendations based on what you currently have in stock.'**
  String get chatGreeting;

  /// No description provided for @chatAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Chatmelier is analyzing your cellar...'**
  String get chatAnalyzing;

  /// No description provided for @chatInputHint.
  ///
  /// In en, this message translates to:
  /// **'Ask Chatmelier...'**
  String get chatInputHint;

  /// No description provided for @chatChipTonight.
  ///
  /// In en, this message translates to:
  /// **'🍷 What should I drink tonight?'**
  String get chatChipTonight;

  /// No description provided for @chatChipSteak.
  ///
  /// In en, this message translates to:
  /// **'🥩 Pair a bottle with steak'**
  String get chatChipSteak;

  /// No description provided for @chatChipSeafood.
  ///
  /// In en, this message translates to:
  /// **'🐟 Best white for seafood'**
  String get chatChipSeafood;

  /// No description provided for @chatChipPeak.
  ///
  /// In en, this message translates to:
  /// **'⏰ Which bottles are at their peak?'**
  String get chatChipPeak;

  /// No description provided for @journalTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasting Journal'**
  String get journalTitle;

  /// No description provided for @journalEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tastings recorded yet'**
  String get journalEmpty;

  /// No description provided for @journalEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Checkout and taste a bottle from your cellar to start your log'**
  String get journalEmptySub;

  /// No description provided for @journalTastedOn.
  ///
  /// In en, this message translates to:
  /// **'Tasted on {date}'**
  String journalTastedOn(String date);

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Cellar Statistics'**
  String get statsTitle;

  /// No description provided for @statsTotalBottles.
  ///
  /// In en, this message translates to:
  /// **'Bottles in Cellar'**
  String get statsTotalBottles;

  /// No description provided for @statsTotalValue.
  ///
  /// In en, this message translates to:
  /// **'Cellar Value'**
  String get statsTotalValue;

  /// No description provided for @statsBottlesEnjoyed.
  ///
  /// In en, this message translates to:
  /// **'Bottles Enjoyed'**
  String get statsBottlesEnjoyed;

  /// No description provided for @statsByColor.
  ///
  /// In en, this message translates to:
  /// **'Distribution by Wine Color'**
  String get statsByColor;

  /// No description provided for @statsByMaturity.
  ///
  /// In en, this message translates to:
  /// **'Distribution by Maturity'**
  String get statsByMaturity;

  /// No description provided for @statsByRegion.
  ///
  /// In en, this message translates to:
  /// **'Top Regions'**
  String get statsByRegion;

  /// No description provided for @statsByCountry.
  ///
  /// In en, this message translates to:
  /// **'Top Countries'**
  String get statsByCountry;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileTitle;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get profileDisplayName;

  /// No description provided for @profileDefaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get profileDefaultCurrency;

  /// No description provided for @profileLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get profileLanguage;

  /// No description provided for @profileLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'Automatic (System Default)'**
  String get profileLanguageSystem;

  /// No description provided for @profileLanguageFr.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get profileLanguageFr;

  /// No description provided for @profileLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get profileLanguageEn;

  /// No description provided for @profileCurrencyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Default currency updated: {currency}'**
  String profileCurrencyUpdated(String currency);

  /// No description provided for @profileLanguageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated'**
  String get profileLanguageUpdated;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileAbout.
  ///
  /// In en, this message translates to:
  /// **'About Chatmelier'**
  String get profileAbout;

  /// No description provided for @scanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan Wine Label'**
  String get scanTitle;

  /// No description provided for @scanTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get scanTakePhoto;

  /// No description provided for @scanPickGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get scanPickGallery;

  /// No description provided for @scanAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Chatmelier AI is analyzing the label...'**
  String get scanAnalyzing;

  /// No description provided for @scanIdentified.
  ///
  /// In en, this message translates to:
  /// **'Wine identified by Chatmelier ✨'**
  String get scanIdentified;

  /// No description provided for @scanSaveToCellar.
  ///
  /// In en, this message translates to:
  /// **'Add to my cellar'**
  String get scanSaveToCellar;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginTitle;

  /// No description provided for @loginTagline.
  ///
  /// In en, this message translates to:
  /// **'Your Shared AI-Powered Wine Cellar'**
  String get loginTagline;

  /// No description provided for @loginTabMagicLink.
  ///
  /// In en, this message translates to:
  /// **'✉️ Sign-in Link'**
  String get loginTabMagicLink;

  /// No description provided for @loginTabPassword.
  ///
  /// In en, this message translates to:
  /// **'🔑 Password'**
  String get loginTabPassword;

  /// No description provided for @loginEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get loginEmailLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginSendMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Get Sign-in Link'**
  String get loginSendMagicLink;

  /// No description provided for @loginSignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get loginSignInButton;

  /// No description provided for @loginOrDivider.
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get loginOrDivider;

  /// No description provided for @loginGoogleButton.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogleButton;

  /// No description provided for @loginRegisterLink.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Create one'**
  String get loginRegisterLink;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerTitle;

  /// No description provided for @registerNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display Name / First Name'**
  String get registerNameLabel;

  /// No description provided for @registerSubmitButton.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get registerSubmitButton;

  /// No description provided for @registerFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get registerFillAllFields;

  /// No description provided for @registerWelcome.
  ///
  /// In en, this message translates to:
  /// **'🎉 Welcome to Chatmelier!'**
  String get registerWelcome;

  /// No description provided for @registerErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Registration error'**
  String get registerErrorGeneric;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Chatmelier'**
  String get authWelcome;

  /// No description provided for @authSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your smart wine cellar manager & AI companion'**
  String get authSubtitle;

  /// No description provided for @authGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authGoogle;

  /// No description provided for @authMagicLink.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email link'**
  String get authMagicLink;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get authEmail;

  /// No description provided for @authNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get authNoAccount;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get authHaveAccount;

  /// No description provided for @changelogTitle.
  ///
  /// In en, this message translates to:
  /// **'Changelog & Version Notes'**
  String get changelogTitle;

  /// No description provided for @changelogEmpty.
  ///
  /// In en, this message translates to:
  /// **'No changelog entries available.'**
  String get changelogEmpty;

  /// No description provided for @scratchcardTitle.
  ///
  /// In en, this message translates to:
  /// **'World Terroirs Scratchcard'**
  String get scratchcardTitle;

  /// No description provided for @profileChangelog.
  ///
  /// In en, this message translates to:
  /// **'Version History & Changelog'**
  String get profileChangelog;

  /// No description provided for @profileScratchcard.
  ///
  /// In en, this message translates to:
  /// **'World Terroirs Scratchcard'**
  String get profileScratchcard;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
