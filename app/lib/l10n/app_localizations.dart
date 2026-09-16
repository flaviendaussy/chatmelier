import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ca.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_la.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_zh.dart';

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
    Locale('ca'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('la'),
    Locale('nl'),
    Locale('pt'),
    Locale('sv'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Chatmelier'**
  String get appTitle;

  /// No description provided for @defaultCellarName.
  ///
  /// In en, this message translates to:
  /// **'My Cellar'**
  String get defaultCellarName;

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
  /// **'Tasting'**
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
  /// **'Hello! I am Chatmelier. Ask me for food pairings, drinking advice, or wine cellar recommendations based on what you currently have in stock.'**
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

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'QUICK ACTIONS'**
  String get quickActions;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sommelier & Wine Cellar'**
  String get appSubtitle;

  /// No description provided for @profileTabPalate.
  ///
  /// In en, this message translates to:
  /// **'Palate'**
  String get profileTabPalate;

  /// No description provided for @profileTabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get profileTabSettings;

  /// No description provided for @profileTabTools.
  ///
  /// In en, this message translates to:
  /// **'Tools'**
  String get profileTabTools;

  /// No description provided for @profileTabAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileTabAccount;

  /// No description provided for @profileTheme.
  ///
  /// In en, this message translates to:
  /// **'Ambience / Theme'**
  String get profileTheme;

  /// No description provided for @profileThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light ☀️'**
  String get profileThemeLight;

  /// No description provided for @profileThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark 🌙'**
  String get profileThemeDark;

  /// No description provided for @profileThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System ⚙️'**
  String get profileThemeSystem;

  /// No description provided for @profileFriends.
  ///
  /// In en, this message translates to:
  /// **'Friends & Taste Maps 🍷'**
  String get profileFriends;

  /// No description provided for @profileExport.
  ///
  /// In en, this message translates to:
  /// **'Export Cellar & Valuation Report 📊'**
  String get profileExport;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently Delete My Account'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get profileDeleteConfirmTitle;

  /// No description provided for @profileDeleteConfirmMsg.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. All your data will be deleted.'**
  String get profileDeleteConfirmMsg;

  /// No description provided for @badgesGalleryTitle.
  ///
  /// In en, this message translates to:
  /// **'Trophy Gallery'**
  String get badgesGalleryTitle;

  /// No description provided for @badgesGallerySubtitle.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} unlocked • {pct}% completed'**
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked);

  /// No description provided for @badgesFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get badgesFilterAll;

  /// No description provided for @badgesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No badges found in this category.'**
  String get badgesEmpty;

  /// No description provided for @badgesUnlockedChip.
  ///
  /// In en, this message translates to:
  /// **'Unlocked ✨'**
  String get badgesUnlockedChip;

  /// No description provided for @badgesStatusUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Badge Unlocked!'**
  String get badgesStatusUnlocked;

  /// No description provided for @badgesStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get badgesStatusInProgress;

  /// No description provided for @badgesObjectiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Objective:'**
  String get badgesObjectiveLabel;

  /// No description provided for @badgesChatmelierLoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Chatmelier\'s Science & Lore'**
  String get badgesChatmelierLoreTitle;

  /// No description provided for @badgesCloseButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get badgesCloseButton;

  /// No description provided for @badgesTierLabel.
  ///
  /// In en, this message translates to:
  /// **'Tier'**
  String get badgesTierLabel;

  /// No description provided for @badgesShowcaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Trophies & Badges'**
  String get badgesShowcaseTitle;

  /// No description provided for @badgesShowcaseCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} of {total} unlocked'**
  String badgesShowcaseCount(Object total, Object unlocked);

  /// No description provided for @badgesShowcaseGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get badgesShowcaseGallery;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueAnyway.
  ///
  /// In en, this message translates to:
  /// **'Continue anyway'**
  String get continueAnyway;

  /// No description provided for @cellarDetected.
  ///
  /// In en, this message translates to:
  /// **'Cellar detected: '**
  String get cellarDetected;

  /// No description provided for @proximityWifi.
  ///
  /// In en, this message translates to:
  /// **'Connected to Wi-Fi \"{ssid}\"'**
  String proximityWifi(String ssid);

  /// No description provided for @proximityGps.
  ///
  /// In en, this message translates to:
  /// **'GPS location detected at {distance}'**
  String proximityGps(String distance);

  /// No description provided for @proximitySwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get proximitySwitch;

  /// No description provided for @proximityIgnore.
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get proximityIgnore;

  /// No description provided for @proximitySwitchedSnack.
  ///
  /// In en, this message translates to:
  /// **'📍 Automatically switched to \"{cellar}\"'**
  String proximitySwitchedSnack(String cellar);

  /// No description provided for @distantCellarTitle.
  ///
  /// In en, this message translates to:
  /// **'Distant cellar detected'**
  String get distantCellarTitle;

  /// No description provided for @distantCellarWifiWarning.
  ///
  /// In en, this message translates to:
  /// **'You are currently connected to Wi-Fi \"{ssid}\" associated with your other cellar \"{cellar}\".'**
  String distantCellarWifiWarning(String ssid, String cellar);

  /// No description provided for @distantCellarGpsWarning.
  ///
  /// In en, this message translates to:
  /// **'You are currently located approximately {distance} from \"{cellar}\".'**
  String distantCellarGpsWarning(String distance, String cellar);

  /// No description provided for @distantCellarAddConfirm.
  ///
  /// In en, this message translates to:
  /// **'{warning}\n\nDo you still want to add this bottle to the cellar \"{cellar}\"?'**
  String distantCellarAddConfirm(String warning, String cellar);

  /// No description provided for @distantCellarCheckoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'{warning}\n\nDo you still want to checkout this bottle from the cellar \"{cellar}\"?'**
  String distantCellarCheckoutConfirm(String warning, String cellar);

  /// No description provided for @ratingExceptional.
  ///
  /// In en, this message translates to:
  /// **'🏆 Exceptional'**
  String get ratingExceptional;

  /// No description provided for @ratingRemarkable.
  ///
  /// In en, this message translates to:
  /// **'✨ Remarkable'**
  String get ratingRemarkable;

  /// No description provided for @ratingVeryGood.
  ///
  /// In en, this message translates to:
  /// **'🍷 Very good'**
  String get ratingVeryGood;

  /// No description provided for @ratingPleasant.
  ///
  /// In en, this message translates to:
  /// **'👍 Pleasant'**
  String get ratingPleasant;

  /// No description provided for @ratingPassable.
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get ratingPassable;

  /// No description provided for @checkoutWhoTasted.
  ///
  /// In en, this message translates to:
  /// **'Who tasted this wine with you?'**
  String get checkoutWhoTasted;

  /// No description provided for @checkoutStockRemaining.
  ///
  /// In en, this message translates to:
  /// **'{producer} • In stock: {qty} {qty, plural, =1{bottle} other{bottles}}'**
  String checkoutStockRemaining(String producer, int qty);

  /// No description provided for @checkoutAddGuest.
  ///
  /// In en, this message translates to:
  /// **'Add a guest'**
  String get checkoutAddGuest;

  /// No description provided for @checkoutAddGuestHint.
  ///
  /// In en, this message translates to:
  /// **'Add (Mom, Dad...)'**
  String get checkoutAddGuestHint;

  /// No description provided for @checkoutCloseAndTaste.
  ///
  /// In en, this message translates to:
  /// **'Close & Enjoy 🍷'**
  String get checkoutCloseAndTaste;

  /// No description provided for @checkoutSommelierThinking.
  ///
  /// In en, this message translates to:
  /// **'The sommelier is preparing tasting stories...'**
  String get checkoutSommelierThinking;

  /// No description provided for @checkoutAerationTimerActive.
  ///
  /// In en, this message translates to:
  /// **'⏱️ Aeration timer active on your lock screen!'**
  String get checkoutAerationTimerActive;

  /// No description provided for @checkoutStartAerationTimer.
  ///
  /// In en, this message translates to:
  /// **'Start timer ⏱️'**
  String get checkoutStartAerationTimer;

  /// No description provided for @checkoutAerationTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Aeration Timer'**
  String get checkoutAerationTimerTitle;

  /// No description provided for @checkoutDelayedTonight.
  ///
  /// In en, this message translates to:
  /// **'Tonight at 10:00 PM'**
  String get checkoutDelayedTonight;

  /// No description provided for @checkoutDelayedTonightSub.
  ///
  /// In en, this message translates to:
  /// **'Ideal after the meal to savor the moment'**
  String get checkoutDelayedTonightSub;

  /// No description provided for @checkoutDelayedTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow morning at 11:00 AM'**
  String get checkoutDelayedTomorrow;

  /// No description provided for @checkoutDelayedTomorrowSub.
  ///
  /// In en, this message translates to:
  /// **'To recall your impressions in quiet'**
  String get checkoutDelayedTomorrowSub;

  /// No description provided for @checkoutDelayedWeekend.
  ///
  /// In en, this message translates to:
  /// **'This weekend (Saturday at 11:00 AM)'**
  String get checkoutDelayedWeekend;

  /// No description provided for @checkoutDelayedWeekendSub.
  ///
  /// In en, this message translates to:
  /// **'Take your time during your free moments'**
  String get checkoutDelayedWeekendSub;

  /// No description provided for @checkoutDelayedInTwoHours.
  ///
  /// In en, this message translates to:
  /// **'In 2 hours ({time})'**
  String checkoutDelayedInTwoHours(String time);

  /// No description provided for @checkoutDelayedInTwoHoursSub.
  ///
  /// In en, this message translates to:
  /// **'Quick reminder at the end of the tasting'**
  String get checkoutDelayedInTwoHoursSub;

  /// No description provided for @checkoutDelayedCustom.
  ///
  /// In en, this message translates to:
  /// **'Choose a custom date & time...'**
  String get checkoutDelayedCustom;

  /// No description provided for @reviewPackagingDetected.
  ///
  /// In en, this message translates to:
  /// **'Packaging Detected'**
  String get reviewPackagingDetected;

  /// No description provided for @reviewSingleBottleOnly.
  ///
  /// In en, this message translates to:
  /// **'No, 1 bottle only'**
  String get reviewSingleBottleOnly;

  /// No description provided for @reviewMultipleBottlesConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes, {count} bottles'**
  String reviewMultipleBottlesConfirm(int count);

  /// No description provided for @reviewStockUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'🍾 Stock updated successfully! ({count} bottles in cellar)'**
  String reviewStockUpdatedSuccess(int count);

  /// No description provided for @reviewVintageYear.
  ///
  /// In en, this message translates to:
  /// **'Vintage / Year'**
  String get reviewVintageYear;

  /// No description provided for @reviewNonVintage.
  ///
  /// In en, this message translates to:
  /// **'Skip / Non-vintage'**
  String get reviewNonVintage;

  /// No description provided for @reviewValidate.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get reviewValidate;

  /// No description provided for @reviewBottleAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'🍾 {name} added successfully to the cellar!'**
  String reviewBottleAddedSuccess(String name);

  /// No description provided for @reviewBottleAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Bottle Analysis'**
  String get reviewBottleAnalysis;

  /// No description provided for @reviewDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get reviewDiscard;

  /// No description provided for @reviewDiscardConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard entry?'**
  String get reviewDiscardConfirmTitle;

  /// No description provided for @reviewContinueEditing.
  ///
  /// In en, this message translates to:
  /// **'Continue editing'**
  String get reviewContinueEditing;

  /// No description provided for @reviewDiscardWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Discard without saving'**
  String get reviewDiscardWithoutSaving;

  /// No description provided for @reviewBottleDetails.
  ///
  /// In en, this message translates to:
  /// **'Bottle Details'**
  String get reviewBottleDetails;

  /// No description provided for @reviewStockInCellar.
  ///
  /// In en, this message translates to:
  /// **'Cellar stock'**
  String get reviewStockInCellar;

  /// No description provided for @reviewStockAddition.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get reviewStockAddition;

  /// No description provided for @reviewStockNewTotal.
  ///
  /// In en, this message translates to:
  /// **'New total'**
  String get reviewStockNewTotal;

  /// No description provided for @reviewQuantityToAdd.
  ///
  /// In en, this message translates to:
  /// **'Quantity to add:'**
  String get reviewQuantityToAdd;

  /// No description provided for @reviewSeparateEntry.
  ///
  /// In en, this message translates to:
  /// **'Create a separate entry (different rack / price)'**
  String get reviewSeparateEntry;

  /// No description provided for @reviewRetryAi.
  ///
  /// In en, this message translates to:
  /// **'Retry AI analysis'**
  String get reviewRetryAi;

  /// No description provided for @reviewEnlarge.
  ///
  /// In en, this message translates to:
  /// **'Enlarge'**
  String get reviewEnlarge;

  /// No description provided for @reviewGeneralInfo.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get reviewGeneralInfo;

  /// No description provided for @reviewOriginTerroir.
  ///
  /// In en, this message translates to:
  /// **'Origin & Terroir'**
  String get reviewOriginTerroir;

  /// No description provided for @reviewQuantityPurchase.
  ///
  /// In en, this message translates to:
  /// **'Quantity & Purchase'**
  String get reviewQuantityPurchase;

  /// No description provided for @cellarWifiDetectedSuccess.
  ///
  /// In en, this message translates to:
  /// **'📡 Wi-Fi detected & linked: \"{ssid}\"'**
  String cellarWifiDetectedSuccess(String ssid);

  /// No description provided for @cellarWifiDetectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to detect Wi-Fi (enable location or enter manually)'**
  String get cellarWifiDetectionFailed;

  /// No description provided for @cellarGpsCoordsCaptured.
  ///
  /// In en, this message translates to:
  /// **'📍 GPS coordinates captured ({lat}, {lon})'**
  String cellarGpsCoordsCaptured(String lat, String lon);

  /// No description provided for @cellarGpsInaccessible.
  ///
  /// In en, this message translates to:
  /// **'GPS location unavailable. Check location permissions.'**
  String get cellarGpsInaccessible;

  /// No description provided for @cellarCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✨ Cellar \"{cellar}\" created successfully!'**
  String cellarCreatedSuccess(String cellar);

  /// No description provided for @cellarCreationError.
  ///
  /// In en, this message translates to:
  /// **'Error during creation: {error}'**
  String cellarCreationError(String error);

  /// No description provided for @cellarRadiusPrecise.
  ///
  /// In en, this message translates to:
  /// **'100 meters (very precise)'**
  String get cellarRadiusPrecise;

  /// No description provided for @cellarRadiusRecommended.
  ///
  /// In en, this message translates to:
  /// **'300 meters (recommended)'**
  String get cellarRadiusRecommended;

  /// No description provided for @cellarRadius500m.
  ///
  /// In en, this message translates to:
  /// **'500 meters'**
  String get cellarRadius500m;

  /// No description provided for @cellarRadius1km.
  ///
  /// In en, this message translates to:
  /// **'1 kilometer'**
  String get cellarRadius1km;

  /// No description provided for @cellarRadius3km.
  ///
  /// In en, this message translates to:
  /// **'3 kilometers'**
  String get cellarRadius3km;

  /// No description provided for @cellarCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create cellar'**
  String get cellarCreateButton;

  /// No description provided for @cellarUseCurrentGps.
  ///
  /// In en, this message translates to:
  /// **'Set with current GPS location'**
  String get cellarUseCurrentGps;

  /// No description provided for @cellarUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'✅ Cellar settings for \"{cellar}\" updated'**
  String cellarUpdatedSuccess(String cellar);

  /// No description provided for @cellarUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error during update: {error}'**
  String cellarUpdateError(String error);

  /// No description provided for @wineTypeRed.
  ///
  /// In en, this message translates to:
  /// **'Red 🍷'**
  String get wineTypeRed;

  /// No description provided for @wineTypeWhite.
  ///
  /// In en, this message translates to:
  /// **'White 🥂'**
  String get wineTypeWhite;

  /// No description provided for @wineTypeRose.
  ///
  /// In en, this message translates to:
  /// **'Rosé 🌸'**
  String get wineTypeRose;

  /// No description provided for @wineTypeSparkling.
  ///
  /// In en, this message translates to:
  /// **'Sparkling 🍾'**
  String get wineTypeSparkling;

  /// No description provided for @wineTypeDessert.
  ///
  /// In en, this message translates to:
  /// **'Dessert / Sweet 🍯'**
  String get wineTypeDessert;

  /// No description provided for @wineTypeLiqueur.
  ///
  /// In en, this message translates to:
  /// **'Liqueur 🍯'**
  String get wineTypeLiqueur;

  /// No description provided for @wineTypeSpirit.
  ///
  /// In en, this message translates to:
  /// **'Spirits 🥃'**
  String get wineTypeSpirit;

  /// No description provided for @wineTypeGrappa.
  ///
  /// In en, this message translates to:
  /// **'Grappa 🍇'**
  String get wineTypeGrappa;

  /// No description provided for @wineTypeEauDeVie.
  ///
  /// In en, this message translates to:
  /// **'Fruit Brandy 🍐'**
  String get wineTypeEauDeVie;

  /// No description provided for @wineTypeWhisky.
  ///
  /// In en, this message translates to:
  /// **'Whisky 🥃'**
  String get wineTypeWhisky;

  /// No description provided for @wineTypeRum.
  ///
  /// In en, this message translates to:
  /// **'Rum 🏴‍☠️'**
  String get wineTypeRum;

  /// No description provided for @wineTypeGin.
  ///
  /// In en, this message translates to:
  /// **'Gin 🍸'**
  String get wineTypeGin;

  /// No description provided for @wineTypeVodka.
  ///
  /// In en, this message translates to:
  /// **'Vodka 🧊'**
  String get wineTypeVodka;

  /// No description provided for @wineTypeTequila.
  ///
  /// In en, this message translates to:
  /// **'Tequila 🌵'**
  String get wineTypeTequila;

  /// No description provided for @wineTypeCognac.
  ///
  /// In en, this message translates to:
  /// **'Cognac 🍷'**
  String get wineTypeCognac;

  /// No description provided for @cellarCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create a new cellar'**
  String get cellarCreateTitle;

  /// No description provided for @cellarManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage cellar'**
  String get cellarManageTitle;

  /// No description provided for @cellarNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Cellar name *'**
  String get cellarNameLabel;

  /// No description provided for @cellarNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., London Cellar, Vosges Cellar'**
  String get cellarNameHint;

  /// No description provided for @cellarNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get cellarNameRequired;

  /// No description provided for @cellarLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location / City (optional)'**
  String get cellarLocationLabel;

  /// No description provided for @cellarLocationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., London (UK), Beaune (FR)'**
  String get cellarLocationHint;

  /// No description provided for @cellarNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname / Room (optional)'**
  String get cellarNicknameLabel;

  /// No description provided for @cellarNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Basement, Main wine cooler'**
  String get cellarNicknameHint;

  /// No description provided for @cellarDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get cellarDescriptionLabel;

  /// No description provided for @cellarDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Cool underground cellar, 70% humidity'**
  String get cellarDescriptionHint;

  /// No description provided for @cellarWifiLabel.
  ///
  /// In en, this message translates to:
  /// **'Associated Wi-Fi (optional)'**
  String get cellarWifiLabel;

  /// No description provided for @cellarWifiHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Home-Cellar-WiFi'**
  String get cellarWifiHint;

  /// No description provided for @cellarLinkCurrentWifi.
  ///
  /// In en, this message translates to:
  /// **'Link to current Wi-Fi'**
  String get cellarLinkCurrentWifi;

  /// No description provided for @cellarCaptureCurrentWifiTooltip.
  ///
  /// In en, this message translates to:
  /// **'Capture current Wi-Fi'**
  String get cellarCaptureCurrentWifiTooltip;

  /// No description provided for @cellarRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'GPS detection radius'**
  String get cellarRadiusLabel;

  /// No description provided for @cellarAutoDetectionHeader.
  ///
  /// In en, this message translates to:
  /// **'Auto-Detection & Smart Transition'**
  String get cellarAutoDetectionHeader;

  /// No description provided for @cellarAutoDetectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Link your Wi-Fi network or GPS coordinates to automatically switch to this cellar when you are there.'**
  String get cellarAutoDetectionDesc;

  /// No description provided for @cellarLatitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get cellarLatitudeLabel;

  /// No description provided for @cellarLongitudeLabel.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get cellarLongitudeLabel;

  /// No description provided for @checkoutGuidedTasting.
  ///
  /// In en, this message translates to:
  /// **'Guided Tasting'**
  String get checkoutGuidedTasting;

  /// No description provided for @checkoutGuidedTastingShared.
  ///
  /// In en, this message translates to:
  /// **'Share your impressions one by one or together'**
  String get checkoutGuidedTastingShared;

  /// No description provided for @checkoutGuidedTastingSolo.
  ///
  /// In en, this message translates to:
  /// **'Analyze appearance, nose, palate & refine your profile'**
  String get checkoutGuidedTastingSolo;

  /// No description provided for @checkoutUncorkNowRateLater.
  ///
  /// In en, this message translates to:
  /// **'Uncork now, rate later'**
  String get checkoutUncorkNowRateLater;

  /// No description provided for @checkoutUncorkNowRateLaterSub.
  ///
  /// In en, this message translates to:
  /// **'Instant checkout • Choose reminder time (tonight, tomorrow...)'**
  String get checkoutUncorkNowRateLaterSub;

  /// No description provided for @checkoutUncorkAeration.
  ///
  /// In en, this message translates to:
  /// **'Uncork & Aeration timer'**
  String get checkoutUncorkAeration;

  /// No description provided for @checkoutUncorkAerationAdvised.
  ///
  /// In en, this message translates to:
  /// **'Instant checkout • {minutes} min aeration recommended'**
  String checkoutUncorkAerationAdvised(int minutes);

  /// No description provided for @checkoutUncorkAerationSub.
  ///
  /// In en, this message translates to:
  /// **'Instant checkout • Aeration / decanting timer'**
  String get checkoutUncorkAerationSub;

  /// No description provided for @checkoutSommelierServiceAdvice.
  ///
  /// In en, this message translates to:
  /// **'Sommelier Serving Advice'**
  String get checkoutSommelierServiceAdvice;

  /// No description provided for @checkoutHistoryAnecdotes.
  ///
  /// In en, this message translates to:
  /// **'Stories & Trivia'**
  String get checkoutHistoryAnecdotes;

  /// No description provided for @checkoutNoDecanting.
  ///
  /// In en, this message translates to:
  /// **'No decanting'**
  String get checkoutNoDecanting;

  /// No description provided for @checkoutStoryTitle.
  ///
  /// In en, this message translates to:
  /// **'The Story of this Bottle 📖'**
  String get checkoutStoryTitle;

  /// No description provided for @checkoutStorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Captivating stories to share at the table'**
  String get checkoutStorySubtitle;

  /// No description provided for @checkoutStoryTerroir.
  ///
  /// In en, this message translates to:
  /// **'Terroir & Grapes'**
  String get checkoutStoryTerroir;

  /// No description provided for @checkoutStoryVintage.
  ///
  /// In en, this message translates to:
  /// **'The Vintage Story'**
  String get checkoutStoryVintage;

  /// No description provided for @checkoutStoryTastingSecret.
  ///
  /// In en, this message translates to:
  /// **'Tasting Secret'**
  String get checkoutStoryTastingSecret;

  /// No description provided for @checkoutStoryTableAnecdote.
  ///
  /// In en, this message translates to:
  /// **'Table Anecdote'**
  String get checkoutStoryTableAnecdote;

  /// No description provided for @checkoutJournalArchivedNotice.
  ///
  /// In en, this message translates to:
  /// **'Rest assured: this bottle will be carefully archived in your Tasting Journal with your photos and notes.'**
  String get checkoutJournalArchivedNotice;

  /// No description provided for @checkoutBottleUncorkedAerationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bottle uncorked! Aeration timer ({minutes} min) running on your lock screen.'**
  String checkoutBottleUncorkedAerationSuccess(int minutes);

  /// No description provided for @checkoutAerationDialogPrompt.
  ///
  /// In en, this message translates to:
  /// **'The bottle will be immediately uncorked and checked out. Confirm the aeration duration before tasting:'**
  String get checkoutAerationDialogPrompt;

  /// No description provided for @checkoutRateWine.
  ///
  /// In en, this message translates to:
  /// **'Rate wine'**
  String get checkoutRateWine;

  /// No description provided for @checkoutStartTimerAction.
  ///
  /// In en, this message translates to:
  /// **'Timer {minutes}m ⏱️'**
  String checkoutStartTimerAction(int minutes);

  /// No description provided for @checkoutAdviceAerationSnack.
  ///
  /// In en, this message translates to:
  /// **'Sommelier Tip: aerate for {minutes} min. Lockscreen timer ready.'**
  String checkoutAdviceAerationSnack(int minutes);

  /// No description provided for @checkoutAdviceReminderSnack.
  ///
  /// In en, this message translates to:
  /// **'Reminder scheduled after tasting to record your impressions.'**
  String get checkoutAdviceReminderSnack;

  /// No description provided for @checkoutBottleRemovedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Bottle checked out from cellar!'**
  String get checkoutBottleRemovedSuccess;

  /// No description provided for @checkoutBottleRemovedReminder.
  ///
  /// In en, this message translates to:
  /// **'Enjoy your tasting. Reminder scheduled {date} to record your impressions.'**
  String checkoutBottleRemovedReminder(String date);

  /// No description provided for @checkoutWhoTastedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Each participant\'s taste profile will automatically be enriched.'**
  String get checkoutWhoTastedSubtitle;

  /// No description provided for @checkoutCellarOf.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Cellar'**
  String checkoutCellarOf(String name);

  /// No description provided for @checkoutStockBout.
  ///
  /// In en, this message translates to:
  /// **'Stock: {count} btl.'**
  String checkoutStockBout(int count);

  /// No description provided for @checkoutAddGuestDialogDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a loved one or family member present at this tasting (e.g., Mom, Dad, Sophie...).'**
  String get checkoutAddGuestDialogDesc;

  /// No description provided for @checkoutAddGuestNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name / Name'**
  String get checkoutAddGuestNameLabel;

  /// No description provided for @checkoutDelayedSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Uncork & Rate later'**
  String get checkoutDelayedSheetTitle;

  /// No description provided for @checkoutDelayedSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'When would you like to receive a reminder for your impressions?'**
  String get checkoutDelayedSheetSubtitle;

  /// No description provided for @checkoutDelayedTonightTime.
  ///
  /// In en, this message translates to:
  /// **'Tonight in 2 hours ({time})'**
  String checkoutDelayedTonightTime(String time);

  /// No description provided for @checkoutDelayedTonightFixed.
  ///
  /// In en, this message translates to:
  /// **'Tonight at 9:00 PM'**
  String get checkoutDelayedTonightFixed;

  /// No description provided for @checkoutDateTonightLabel.
  ///
  /// In en, this message translates to:
  /// **'tonight at {time}'**
  String checkoutDateTonightLabel(String time);

  /// No description provided for @checkoutDateTomorrowLabel.
  ///
  /// In en, this message translates to:
  /// **'tomorrow at {time}'**
  String checkoutDateTomorrowLabel(String time);

  /// No description provided for @checkoutDateCustomLabel.
  ///
  /// In en, this message translates to:
  /// **'on {date} at {time}'**
  String checkoutDateCustomLabel(String date, String time);

  /// Generic Add button label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @cellarWinesTab.
  ///
  /// In en, this message translates to:
  /// **'🍷 Wines'**
  String get cellarWinesTab;

  /// No description provided for @cellarSpiritsTab.
  ///
  /// In en, this message translates to:
  /// **'🥃 Spirits'**
  String get cellarSpiritsTab;

  /// No description provided for @cellarPairWithDish.
  ///
  /// In en, this message translates to:
  /// **'Pair wine with dish'**
  String get cellarPairWithDish;

  /// No description provided for @cellarCollapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse all'**
  String get cellarCollapseAll;

  /// No description provided for @cellarExpandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand all'**
  String get cellarExpandAll;

  /// No description provided for @cellarSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get cellarSort;

  /// No description provided for @cellarCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get cellarCategories;

  /// No description provided for @cellarFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get cellarFavorites;

  /// No description provided for @cellarGridView.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get cellarGridView;

  /// No description provided for @cellarListView.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get cellarListView;

  /// No description provided for @cellarClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get cellarClearFilters;

  /// No description provided for @cellarNoBottlesCategory.
  ///
  /// In en, this message translates to:
  /// **'No bottles in this category'**
  String get cellarNoBottlesCategory;

  /// No description provided for @cellarNoBottlesCriteria.
  ///
  /// In en, this message translates to:
  /// **'No bottles match these criteria'**
  String get cellarNoBottlesCriteria;

  /// No description provided for @feedbackSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Tester Feedback & Annotation'**
  String get feedbackSheetTitle;

  /// No description provided for @feedbackStylus.
  ///
  /// In en, this message translates to:
  /// **'Pen:'**
  String get feedbackStylus;

  /// No description provided for @feedbackUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo last stroke'**
  String get feedbackUndo;

  /// No description provided for @feedbackClear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get feedbackClear;

  /// No description provided for @feedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Circle the area and describe your feedback or bug...'**
  String get feedbackHint;

  /// No description provided for @feedbackSubmit.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get feedbackSubmit;

  /// No description provided for @feedbackSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get feedbackSubmitting;

  /// No description provided for @feedbackNoScreenshot.
  ///
  /// In en, this message translates to:
  /// **'No screenshot available'**
  String get feedbackNoScreenshot;

  /// No description provided for @feedbackEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please add a comment or draw on the screenshot.'**
  String get feedbackEmptyError;

  /// No description provided for @feedbackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your feedback! 🍷 The report was sent.'**
  String get feedbackSuccess;

  /// No description provided for @feedbackError.
  ///
  /// In en, this message translates to:
  /// **'Error sending feedback: {error}'**
  String feedbackError(String error);

  /// No description provided for @checkoutFastExit.
  ///
  /// In en, this message translates to:
  /// **'Quick exit without questionnaire'**
  String get checkoutFastExit;

  /// No description provided for @checkoutFastExitSubmitting.
  ///
  /// In en, this message translates to:
  /// **'Processing checkout...'**
  String get checkoutFastExitSubmitting;

  /// No description provided for @checkoutRatingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Rate your overall impression after tasting'**
  String get checkoutRatingSubtitle;

  /// No description provided for @checkoutRecommendedBadge.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get checkoutRecommendedBadge;

  /// No description provided for @tastingWhoTastedTitle.
  ///
  /// In en, this message translates to:
  /// **'👥 Who tasted this wine?'**
  String get tastingWhoTastedTitle;

  /// No description provided for @tastingWhoTastedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select the tasters. Taste profiles will be enriched automatically.'**
  String get tastingWhoTastedSubtitle;

  /// No description provided for @tastingHowToTaste.
  ///
  /// In en, this message translates to:
  /// **'How to taste?'**
  String get tastingHowToTaste;

  /// No description provided for @tastingEachTurn.
  ///
  /// In en, this message translates to:
  /// **'Taking turns'**
  String get tastingEachTurn;

  /// No description provided for @tastingEachTurnDesc.
  ///
  /// In en, this message translates to:
  /// **'📱 Pass the phone: each person answers separately at their own pace.'**
  String get tastingEachTurnDesc;

  /// No description provided for @tastingTogether.
  ///
  /// In en, this message translates to:
  /// **'Together'**
  String get tastingTogether;

  /// No description provided for @tastingTogetherDesc.
  ///
  /// In en, this message translates to:
  /// **'🥂 A single questionnaire completed together for all guests.'**
  String get tastingTogetherDesc;

  /// No description provided for @tastingBlindMode.
  ///
  /// In en, this message translates to:
  /// **'Blind Tasting Mode'**
  String get tastingBlindMode;

  /// No description provided for @tastingBlindModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Hides the wine name and launches an interactive table quiz with a grand reveal!'**
  String get tastingBlindModeDesc;

  /// No description provided for @tastingPrimaryProfile.
  ///
  /// In en, this message translates to:
  /// **'Primary profile'**
  String get tastingPrimaryProfile;

  /// No description provided for @tastingAppInstalled.
  ///
  /// In en, this message translates to:
  /// **'App installed 📱'**
  String get tastingAppInstalled;

  /// No description provided for @tastingQuestionnairesCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 questionnaire completed} other{{count} questionnaires completed}}'**
  String tastingQuestionnairesCompletedCount(int count);

  /// No description provided for @tastingStepNezTitle.
  ///
  /// In en, this message translates to:
  /// **'🍇 The Nose — Aromas'**
  String get tastingStepNezTitle;

  /// No description provided for @tastingStepNezSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Which aromas did you perceive? (Multiple choices possible)'**
  String get tastingStepNezSubtitle;

  /// No description provided for @tastingFaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Does the wine smell of any of these?'**
  String get tastingFaultTitle;

  /// No description provided for @tastingFaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'If so, the bottle is faulty — it\'s neither your palate nor the wine\'s style.'**
  String get tastingFaultSubtitle;

  /// No description provided for @tastingFaultCorkLabel.
  ///
  /// In en, this message translates to:
  /// **'📦 Damp cardboard, musty cellar'**
  String get tastingFaultCorkLabel;

  /// No description provided for @tastingFaultCorkExplain.
  ///
  /// In en, this message translates to:
  /// **'Cork taint (TCA). The wine is blameless and airing won\'t help — at a restaurant, you can ask for another bottle.'**
  String get tastingFaultCorkExplain;

  /// No description provided for @tastingFaultOxidationLabel.
  ///
  /// In en, this message translates to:
  /// **'🍎 Bruised apple, vinegar, sherry'**
  String get tastingFaultOxidationLabel;

  /// No description provided for @tastingFaultOxidationExplain.
  ///
  /// In en, this message translates to:
  /// **'Oxidation. The bottle has taken in air, often through a failing cork or too long in the cellar.'**
  String get tastingFaultOxidationExplain;

  /// No description provided for @tastingFaultReductionLabel.
  ///
  /// In en, this message translates to:
  /// **'🥚 Struck match, egg, cabbage'**
  String get tastingFaultReductionLabel;

  /// No description provided for @tastingFaultReductionExplain.
  ///
  /// In en, this message translates to:
  /// **'Reduction. Good news: it often blows off with air. Decant for twenty minutes and taste again before judging.'**
  String get tastingFaultReductionExplain;

  /// No description provided for @tastingFaultExcluded.
  ///
  /// In en, this message translates to:
  /// **'This tasting won\'t count towards your taste profile.'**
  String get tastingFaultExcluded;

  /// No description provided for @tastingAromaIntensity.
  ///
  /// In en, this message translates to:
  /// **'Aromatic intensity:'**
  String get tastingAromaIntensity;

  /// No description provided for @tastingAromaDiscreet.
  ///
  /// In en, this message translates to:
  /// **'🤫 Subtle'**
  String get tastingAromaDiscreet;

  /// No description provided for @tastingAromaExplosive.
  ///
  /// In en, this message translates to:
  /// **'💥 Explosive'**
  String get tastingAromaExplosive;

  /// No description provided for @tastingStepBoucheTitle.
  ///
  /// In en, this message translates to:
  /// **'⚖️ The Palate — Balance'**
  String get tastingStepBoucheTitle;

  /// No description provided for @tastingStepBoucheSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Describe the texture and balance of the wine on the palate.'**
  String get tastingStepBoucheSubtitle;

  /// No description provided for @tastingAcidity.
  ///
  /// In en, this message translates to:
  /// **'Acidity:'**
  String get tastingAcidity;

  /// No description provided for @tastingAcidityFreshness.
  ///
  /// In en, this message translates to:
  /// **'Acidity & Crispness:'**
  String get tastingAcidityFreshness;

  /// No description provided for @tastingAcidityFlat.
  ///
  /// In en, this message translates to:
  /// **'🫠 Flabby / Flat'**
  String get tastingAcidityFlat;

  /// No description provided for @tastingAciditySharp.
  ///
  /// In en, this message translates to:
  /// **'⚡ Crisp / Sharp'**
  String get tastingAciditySharp;

  /// No description provided for @tastingTannins.
  ///
  /// In en, this message translates to:
  /// **'Tannins:'**
  String get tastingTannins;

  /// No description provided for @tastingTanninsSilky.
  ///
  /// In en, this message translates to:
  /// **'🧶 Silky / Soft'**
  String get tastingTanninsSilky;

  /// No description provided for @tastingTanninsGrippy.
  ///
  /// In en, this message translates to:
  /// **'💪 Grippy / Firm'**
  String get tastingTanninsGrippy;

  /// No description provided for @tastingMinerality.
  ///
  /// In en, this message translates to:
  /// **'Minerality & Freshness:'**
  String get tastingMinerality;

  /// No description provided for @tastingMineralityRound.
  ///
  /// In en, this message translates to:
  /// **'🧈 Round / Buttery'**
  String get tastingMineralityRound;

  /// No description provided for @tastingMineralityCrisp.
  ///
  /// In en, this message translates to:
  /// **'🪨 Mineral / Precise'**
  String get tastingMineralityCrisp;

  /// No description provided for @tastingEffervescence.
  ///
  /// In en, this message translates to:
  /// **'Effervescence:'**
  String get tastingEffervescence;

  /// No description provided for @tastingEffervescenceDelicate.
  ///
  /// In en, this message translates to:
  /// **'🫧 Fine / Delicate'**
  String get tastingEffervescenceDelicate;

  /// No description provided for @tastingEffervescenceVibrant.
  ///
  /// In en, this message translates to:
  /// **'🎆 Lively / Creamy'**
  String get tastingEffervescenceVibrant;

  /// No description provided for @tastingBody.
  ///
  /// In en, this message translates to:
  /// **'Body / Texture:'**
  String get tastingBody;

  /// No description provided for @tastingBodyLight.
  ///
  /// In en, this message translates to:
  /// **'🍃 Light / Airy'**
  String get tastingBodyLight;

  /// No description provided for @tastingBodyFull.
  ///
  /// In en, this message translates to:
  /// **'🏋️ Full / Bold'**
  String get tastingBodyFull;

  /// No description provided for @tastingLength.
  ///
  /// In en, this message translates to:
  /// **'Finish / Length:'**
  String get tastingLength;

  /// No description provided for @tastingLengthShort.
  ///
  /// In en, this message translates to:
  /// **'⏱️ Short'**
  String get tastingLengthShort;

  /// No description provided for @tastingLengthLong.
  ///
  /// In en, this message translates to:
  /// **'♾️ Lingering'**
  String get tastingLengthLong;

  /// No description provided for @tastingStepVerdictTitle.
  ///
  /// In en, this message translates to:
  /// **'✅ Final Verdict'**
  String get tastingStepVerdictTitle;

  /// No description provided for @sipSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'🍷 The sip'**
  String get sipSectionTitle;

  /// No description provided for @tasteConfidenceUnknown.
  ///
  /// In en, this message translates to:
  /// **'I don\'t know your palate yet — the halo shows what I\'m guessing.'**
  String get tasteConfidenceUnknown;

  /// No description provided for @tasteConfidenceKnown.
  ///
  /// In en, this message translates to:
  /// **'Palate known at {percent}%. The blur marks what I\'m still guessing.'**
  String tasteConfidenceKnown(String percent);

  /// No description provided for @tasteConfidenceFrontier.
  ///
  /// In en, this message translates to:
  /// **'What I know least: {axis}.'**
  String tasteConfidenceFrontier(String axis);

  /// No description provided for @sipSectionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two taps, and this glass teaches your taste profile something.'**
  String get sipSectionSubtitle;

  /// No description provided for @tastingBuyAgain.
  ///
  /// In en, this message translates to:
  /// **'Would you buy this bottle again?'**
  String get tastingBuyAgain;

  /// No description provided for @tastingBuyAgainYes.
  ///
  /// In en, this message translates to:
  /// **'🤩 Absolutely!'**
  String get tastingBuyAgainYes;

  /// No description provided for @tastingBuyAgainMaybe.
  ///
  /// In en, this message translates to:
  /// **'🤔 Maybe'**
  String get tastingBuyAgainMaybe;

  /// No description provided for @tastingBuyAgainNo.
  ///
  /// In en, this message translates to:
  /// **'👎 No thanks'**
  String get tastingBuyAgainNo;

  /// No description provided for @tastingIdealMoment.
  ///
  /// In en, this message translates to:
  /// **'Ideal occasion for this wine?'**
  String get tastingIdealMoment;

  /// No description provided for @tastingMomentApero.
  ///
  /// In en, this message translates to:
  /// **'🥂 Aperitif'**
  String get tastingMomentApero;

  /// No description provided for @tastingMomentMeal.
  ///
  /// In en, this message translates to:
  /// **'🍽️ Casual dining'**
  String get tastingMomentMeal;

  /// No description provided for @tastingMomentDinner.
  ///
  /// In en, this message translates to:
  /// **'🎩 Fine dining'**
  String get tastingMomentDinner;

  /// No description provided for @tastingMomentRomantic.
  ///
  /// In en, this message translates to:
  /// **'🕯️ Romantic dinner'**
  String get tastingMomentRomantic;

  /// No description provided for @tastingMomentSolo.
  ///
  /// In en, this message translates to:
  /// **'🧘 Solo / Quiet moment'**
  String get tastingMomentSolo;

  /// No description provided for @tastingWhatLiked.
  ///
  /// In en, this message translates to:
  /// **'What you liked most:'**
  String get tastingWhatLiked;

  /// No description provided for @tastingWhatDisliked.
  ///
  /// In en, this message translates to:
  /// **'What you disliked most:'**
  String get tastingWhatDisliked;

  /// No description provided for @tastingOccasionLabel.
  ///
  /// In en, this message translates to:
  /// **'Occasion / Shared memory (optional) ✨'**
  String get tastingOccasionLabel;

  /// No description provided for @tastingOccasionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Birthday, Candlelit dinner, Reunion...'**
  String get tastingOccasionHint;

  /// No description provided for @tastingAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add a photo memory of the table 📸'**
  String get tastingAddPhoto;

  /// No description provided for @tastingPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo memory saved 📸'**
  String get tastingPhotoSaved;

  /// No description provided for @tastingStepImpressionTitle.
  ///
  /// In en, this message translates to:
  /// **'🎯 Final Rating & Impression'**
  String get tastingStepImpressionTitle;

  /// No description provided for @tastingStepImpressionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'After savoring the nose and palate, assign your overall rating.'**
  String get tastingStepImpressionSubtitle;

  /// No description provided for @tastingOverallFeeling.
  ///
  /// In en, this message translates to:
  /// **'Your overall impression:'**
  String get tastingOverallFeeling;

  /// No description provided for @tastingScoreOutOf10.
  ///
  /// In en, this message translates to:
  /// **'Rating out of 10:'**
  String get tastingScoreOutOf10;

  /// No description provided for @tastingCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasting completed & recorded!'**
  String get tastingCompletedTitle;

  /// No description provided for @tastingCompletedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Taste profiles have been successfully updated ✨'**
  String get tastingCompletedSubtitle;

  /// No description provided for @tastingBottleRemoved.
  ///
  /// In en, this message translates to:
  /// **'Bottle uncorked & removed from cellar'**
  String get tastingBottleRemoved;

  /// No description provided for @tastingConsultDebrief.
  ///
  /// In en, this message translates to:
  /// **'View Sommelier Debrief (Hidden nuances & Terroir)'**
  String get tastingConsultDebrief;

  /// No description provided for @tastingFinishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish ✨'**
  String get tastingFinishButton;

  /// No description provided for @tastingNextTaster.
  ///
  /// In en, this message translates to:
  /// **'Validate → Next taster'**
  String get tastingNextTaster;

  /// No description provided for @tastingConfirmAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Validate & Finish ✨'**
  String get tastingConfirmAndFinish;

  /// No description provided for @tastingQuitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave the questionnaire?'**
  String get tastingQuitTitle;

  /// No description provided for @tastingQuitMessage.
  ///
  /// In en, this message translates to:
  /// **'Your answers will not be saved.'**
  String get tastingQuitMessage;

  /// No description provided for @tastingContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get tastingContinue;

  /// No description provided for @tastingQuit.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get tastingQuit;

  /// No description provided for @tastingStartCount.
  ///
  /// In en, this message translates to:
  /// **'Start ({count})'**
  String tastingStartCount(int count);

  /// No description provided for @tastingProfileSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced to {name}\'s app ✨'**
  String tastingProfileSynced(String name);

  /// No description provided for @tastingProfileEnriched.
  ///
  /// In en, this message translates to:
  /// **'Taste profile enriched'**
  String get tastingProfileEnriched;

  /// No description provided for @tastingAcuityScoreSummary.
  ///
  /// In en, this message translates to:
  /// **'Sensory acuity: {score}% • {praise}'**
  String tastingAcuityScoreSummary(int score, String praise);

  /// No description provided for @tastingFlavorOriginsTitle.
  ///
  /// In en, this message translates to:
  /// **'Origins of Flavors & Wine Secrets'**
  String get tastingFlavorOriginsTitle;

  /// No description provided for @tastingFlavorOriginsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Discover where your wine\'s aromas, color, and structure come from'**
  String get tastingFlavorOriginsSubtitle;

  /// No description provided for @tastingBlindQuizTitle.
  ///
  /// In en, this message translates to:
  /// **'Blind Tasting Table Quiz 🙈'**
  String get tastingBlindQuizTitle;

  /// No description provided for @tastingBlindQuizQ1.
  ///
  /// In en, this message translates to:
  /// **'1. What is the region of origin? 🌍'**
  String get tastingBlindQuizQ1;

  /// No description provided for @tastingBlindQuizQ2.
  ///
  /// In en, this message translates to:
  /// **'2. What is the primary grape? 🍇'**
  String get tastingBlindQuizQ2;

  /// No description provided for @tastingBlindQuizQ3.
  ///
  /// In en, this message translates to:
  /// **'3. Estimated age / vintage? 📅'**
  String get tastingBlindQuizQ3;

  /// No description provided for @tastingBlindQuizQ4.
  ///
  /// In en, this message translates to:
  /// **'4. Estimated price? 💶'**
  String get tastingBlindQuizQ4;

  /// No description provided for @tastingBlindRevealTitle.
  ///
  /// In en, this message translates to:
  /// **'Mystery Bottle Grand Reveal 🍾'**
  String get tastingBlindRevealTitle;

  /// No description provided for @tastingBlindQuizScore.
  ///
  /// In en, this message translates to:
  /// **'Blind Quiz Score: {score}/4 🎯'**
  String tastingBlindQuizScore(int score);

  /// No description provided for @tastingDebriefTitle.
  ///
  /// In en, this message translates to:
  /// **'Enological & Molecular Debrief'**
  String get tastingDebriefTitle;

  /// No description provided for @tastingSensoryAcuity.
  ///
  /// In en, this message translates to:
  /// **'SENSORY ACUITY'**
  String get tastingSensoryAcuity;

  /// No description provided for @tastingPrecision.
  ///
  /// In en, this message translates to:
  /// **'{score}% Accuracy'**
  String tastingPrecision(int score);

  /// No description provided for @tastingConcordanceTitle.
  ///
  /// In en, this message translates to:
  /// **'1. CONCORDANCE & CRU SIGNATURE'**
  String get tastingConcordanceTitle;

  /// No description provided for @tastingWhatYouDetected.
  ///
  /// In en, this message translates to:
  /// **'WHAT YOU DETECTED:'**
  String get tastingWhatYouDetected;

  /// No description provided for @tastingArchetypeSignature.
  ///
  /// In en, this message translates to:
  /// **'ARCHETYPAL SIGNATURE OF THE WINE:'**
  String get tastingArchetypeSignature;

  /// No description provided for @tastingHiddenNuancesTitle.
  ///
  /// In en, this message translates to:
  /// **'SUBTLE NUANCES TO SPOT IN YOUR NEXT GLASS:'**
  String get tastingHiddenNuancesTitle;

  /// No description provided for @tastingPillarsTitle.
  ///
  /// In en, this message translates to:
  /// **'2. ENOLOGICAL SCIENCE & MOLECULES'**
  String get tastingPillarsTitle;

  /// No description provided for @tastingPillarsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Why does this wine have this structure, these aromas, and this color?'**
  String get tastingPillarsSubtitle;

  /// No description provided for @tastingChatWithSommelier.
  ///
  /// In en, this message translates to:
  /// **'Deepen winemaking secrets with Chatmelier'**
  String get tastingChatWithSommelier;

  /// No description provided for @aromaFruitsRouges.
  ///
  /// In en, this message translates to:
  /// **'Red berries'**
  String get aromaFruitsRouges;

  /// No description provided for @aromaFruitsNoirs.
  ///
  /// In en, this message translates to:
  /// **'Dark berries'**
  String get aromaFruitsNoirs;

  /// No description provided for @aromaFruitsBlancs.
  ///
  /// In en, this message translates to:
  /// **'Stone / Orchard fruit'**
  String get aromaFruitsBlancs;

  /// No description provided for @aromaAgrumes.
  ///
  /// In en, this message translates to:
  /// **'Citrus'**
  String get aromaAgrumes;

  /// No description provided for @aromaFloral.
  ///
  /// In en, this message translates to:
  /// **'Floral'**
  String get aromaFloral;

  /// No description provided for @aromaVegetal.
  ///
  /// In en, this message translates to:
  /// **'Herbal / Vegetal'**
  String get aromaVegetal;

  /// No description provided for @aromaEpicesDouces.
  ///
  /// In en, this message translates to:
  /// **'Sweet spices'**
  String get aromaEpicesDouces;

  /// No description provided for @aromaEpicesVives.
  ///
  /// In en, this message translates to:
  /// **'Pungent spices / Pepper'**
  String get aromaEpicesVives;

  /// No description provided for @aromaBoise.
  ///
  /// In en, this message translates to:
  /// **'Oak / Vanilla'**
  String get aromaBoise;

  /// No description provided for @aromaBeurre.
  ///
  /// In en, this message translates to:
  /// **'Butter / Brioche'**
  String get aromaBeurre;

  /// No description provided for @aromaMineral.
  ///
  /// In en, this message translates to:
  /// **'Mineral / Flint'**
  String get aromaMineral;

  /// No description provided for @aromaMiel.
  ///
  /// In en, this message translates to:
  /// **'Honey / Jam'**
  String get aromaMiel;

  /// No description provided for @aromaChocolat.
  ///
  /// In en, this message translates to:
  /// **'Chocolate / Coffee'**
  String get aromaChocolat;

  /// No description provided for @aromaFumee.
  ///
  /// In en, this message translates to:
  /// **'Smoke / Toasted'**
  String get aromaFumee;

  /// No description provided for @emojiDisliked.
  ///
  /// In en, this message translates to:
  /// **'Disliked'**
  String get emojiDisliked;

  /// No description provided for @emojiMeh.
  ///
  /// In en, this message translates to:
  /// **'Meh'**
  String get emojiMeh;

  /// No description provided for @emojiDecent.
  ///
  /// In en, this message translates to:
  /// **'Decent'**
  String get emojiDecent;

  /// No description provided for @emojiVeryGood.
  ///
  /// In en, this message translates to:
  /// **'Very good'**
  String get emojiVeryGood;

  /// No description provided for @emojiLoved.
  ///
  /// In en, this message translates to:
  /// **'Loved it'**
  String get emojiLoved;

  /// No description provided for @likedFreshness.
  ///
  /// In en, this message translates to:
  /// **'Freshness'**
  String get likedFreshness;

  /// No description provided for @likedFruitiness.
  ///
  /// In en, this message translates to:
  /// **'Fruitiness'**
  String get likedFruitiness;

  /// No description provided for @likedComplexity.
  ///
  /// In en, this message translates to:
  /// **'Complexity'**
  String get likedComplexity;

  /// No description provided for @likedElegance.
  ///
  /// In en, this message translates to:
  /// **'Elegance'**
  String get likedElegance;

  /// No description provided for @likedPower.
  ///
  /// In en, this message translates to:
  /// **'Power & Body'**
  String get likedPower;

  /// No description provided for @likedSilky.
  ///
  /// In en, this message translates to:
  /// **'Silky texture'**
  String get likedSilky;

  /// No description provided for @likedOriginality.
  ///
  /// In en, this message translates to:
  /// **'Originality'**
  String get likedOriginality;

  /// No description provided for @likedFoodPairing.
  ///
  /// In en, this message translates to:
  /// **'Food pairing synergy'**
  String get likedFoodPairing;

  /// No description provided for @likedMinerality.
  ///
  /// In en, this message translates to:
  /// **'Minerality'**
  String get likedMinerality;

  /// No description provided for @likedLength.
  ///
  /// In en, this message translates to:
  /// **'Finish length'**
  String get likedLength;

  /// No description provided for @likedDisappointing.
  ///
  /// In en, this message translates to:
  /// **'Nothing / Disappointing 😕'**
  String get likedDisappointing;

  /// No description provided for @dislikedTooAcidic.
  ///
  /// In en, this message translates to:
  /// **'Too acidic'**
  String get dislikedTooAcidic;

  /// No description provided for @dislikedTooTannic.
  ///
  /// In en, this message translates to:
  /// **'Too tannic'**
  String get dislikedTooTannic;

  /// No description provided for @dislikedTooOaked.
  ///
  /// In en, this message translates to:
  /// **'Too oaked / vanilla'**
  String get dislikedTooOaked;

  /// No description provided for @dislikedTooAlcoholic.
  ///
  /// In en, this message translates to:
  /// **'Too alcoholic / hot'**
  String get dislikedTooAlcoholic;

  /// No description provided for @dislikedTooThin.
  ///
  /// In en, this message translates to:
  /// **'Too light / watery'**
  String get dislikedTooThin;

  /// No description provided for @dislikedLacksFruit.
  ///
  /// In en, this message translates to:
  /// **'Lacks fruit'**
  String get dislikedLacksFruit;

  /// No description provided for @dislikedTooSweet.
  ///
  /// In en, this message translates to:
  /// **'Too sweet'**
  String get dislikedTooSweet;

  /// No description provided for @dislikedTooExpensive.
  ///
  /// In en, this message translates to:
  /// **'Too pricey for quality'**
  String get dislikedTooExpensive;

  /// No description provided for @dislikedNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing, it was perfect!'**
  String get dislikedNothing;

  /// No description provided for @tastingStepTasters.
  ///
  /// In en, this message translates to:
  /// **'Tasters'**
  String get tastingStepTasters;

  /// No description provided for @tastingStepNezNav.
  ///
  /// In en, this message translates to:
  /// **'The Nose'**
  String get tastingStepNezNav;

  /// No description provided for @tastingStepBoucheNav.
  ///
  /// In en, this message translates to:
  /// **'The Palate'**
  String get tastingStepBoucheNav;

  /// No description provided for @tastingStepVerdictNav.
  ///
  /// In en, this message translates to:
  /// **'Verdict'**
  String get tastingStepVerdictNav;

  /// No description provided for @tastingStepRatingNav.
  ///
  /// In en, this message translates to:
  /// **'Final Rating'**
  String get tastingStepRatingNav;

  /// No description provided for @tastingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tastingBack;

  /// No description provided for @tastingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tastingNext;

  /// No description provided for @tastingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get tastingSaving;

  /// No description provided for @tastingHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasting Questionnaire'**
  String get tastingHeaderTitle;

  /// No description provided for @tastingAnswersOf.
  ///
  /// In en, this message translates to:
  /// **'Answers by {name}'**
  String tastingAnswersOf(String name);

  /// No description provided for @tastingPassPhoneTo.
  ///
  /// In en, this message translates to:
  /// **'Pass the phone to {name} 📱'**
  String tastingPassPhoneTo(String name);

  /// No description provided for @tastingAnswersSavedTurn.
  ///
  /// In en, this message translates to:
  /// **'Your answers have been recorded.\nIt is now {name}\'s turn.'**
  String tastingAnswersSavedTurn(String name);

  /// No description provided for @tastingDictateButton.
  ///
  /// In en, this message translates to:
  /// **'Dictate table impressions 🎙️'**
  String get tastingDictateButton;

  /// No description provided for @tastingDictateHint.
  ///
  /// In en, this message translates to:
  /// **'Speak or write naturally, Chatmelier AI will pre-fill your aromas and palate balance!'**
  String get tastingDictateHint;

  /// No description provided for @tastingDictateMicTip.
  ///
  /// In en, this message translates to:
  /// **'Tip: enable the microphone on your keyboard to dictate aloud!'**
  String get tastingDictateMicTip;

  /// No description provided for @tastingTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a table photo 📸'**
  String get tastingTakePhoto;

  /// No description provided for @tastingChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery 🖼️'**
  String get tastingChooseGallery;

  /// No description provided for @tastingConclaveSummary.
  ///
  /// In en, this message translates to:
  /// **'Conclave Summary'**
  String get tastingConclaveSummary;

  /// No description provided for @tastingCellarMaster.
  ///
  /// In en, this message translates to:
  /// **'Cellar Master'**
  String get tastingCellarMaster;

  /// No description provided for @tastingGuestTaster.
  ///
  /// In en, this message translates to:
  /// **'Guest Taster'**
  String get tastingGuestTaster;

  /// No description provided for @tastingProfileTag.
  ///
  /// In en, this message translates to:
  /// **'Profile: {type}'**
  String tastingProfileTag(String type);

  /// No description provided for @tastingFreeTastingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Freeform tasting recorded.'**
  String get tastingFreeTastingRecorded;

  /// No description provided for @tastingAppearanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Appearance: {appearance}'**
  String tastingAppearanceLabel(String appearance);

  /// No description provided for @tastingStructureLabel.
  ///
  /// In en, this message translates to:
  /// **'Structure: {structure} ({caudalies} caudalies)'**
  String tastingStructureLabel(String structure, int caudalies);

  /// No description provided for @tastingKeyMolecules.
  ///
  /// In en, this message translates to:
  /// **'Key molecules: {molecules}'**
  String tastingKeyMolecules(String molecules);

  /// No description provided for @tastingKeyOrigin.
  ///
  /// In en, this message translates to:
  /// **'Key: {key}'**
  String tastingKeyOrigin(String key);

  /// No description provided for @tastingGrapesLabel.
  ///
  /// In en, this message translates to:
  /// **'Grape varieties: {grapes}'**
  String tastingGrapesLabel(String grapes);

  /// No description provided for @tastingAromaAppliedByAI.
  ///
  /// In en, this message translates to:
  /// **'Tasting impressions applied by Chatmelier AI ✨'**
  String get tastingAromaAppliedByAI;

  /// No description provided for @tastingBlindYourPredictions.
  ///
  /// In en, this message translates to:
  /// **'Blind table predictions summary:'**
  String get tastingBlindYourPredictions;

  /// No description provided for @tastingBlindGuessCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct! 🎯'**
  String get tastingBlindGuessCorrect;

  /// No description provided for @tastingBlindMakePredictionsPrompt.
  ///
  /// In en, this message translates to:
  /// **'Make your table predictions before the grand final reveal!'**
  String get tastingBlindMakePredictionsPrompt;

  /// No description provided for @tastingStartTaster.
  ///
  /// In en, this message translates to:
  /// **'Let\'s go, {name}! 🍷'**
  String tastingStartTaster(String name);

  /// No description provided for @tastingQuizBravo.
  ///
  /// In en, this message translates to:
  /// **'🎯 Bravo!'**
  String get tastingQuizBravo;

  /// No description provided for @tastingQuizWas.
  ///
  /// In en, this message translates to:
  /// **'(It was: {answer})'**
  String tastingQuizWas(String answer);

  /// No description provided for @tastingDictateInputHint.
  ///
  /// In en, this message translates to:
  /// **'E.g.: Bernard loved it, 8.5/10 with undergrowth and blackcurrant notes. Caro gave 7/10 finding the wine slightly acidic...'**
  String get tastingDictateInputHint;

  /// No description provided for @tastingDictateAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get tastingDictateAnalyzing;

  /// No description provided for @tastingDictateAnalyzeAndApply.
  ///
  /// In en, this message translates to:
  /// **'Analyze & Apply to Sheets ✨'**
  String get tastingDictateAnalyzeAndApply;

  /// No description provided for @tastingFormatExpress.
  ///
  /// In en, this message translates to:
  /// **'Express Format (1 page) ⚡'**
  String get tastingFormatExpress;

  /// No description provided for @tastingFormatExpressDesc.
  ///
  /// In en, this message translates to:
  /// **'Rating, key aromas and quick verdict in 30s'**
  String get tastingFormatExpressDesc;

  /// No description provided for @tastingFormatSommelier.
  ///
  /// In en, this message translates to:
  /// **'Sommelier Format (Detailed) 🎓'**
  String get tastingFormatSommelier;

  /// No description provided for @tastingFormatSommelierDesc.
  ///
  /// In en, this message translates to:
  /// **'In-depth nose, palate balance, finish & terroir'**
  String get tastingFormatSommelierDesc;

  /// No description provided for @tastingCaudalieTooltipTitle.
  ///
  /// In en, this message translates to:
  /// **'What is a caudalie? ⏱️'**
  String get tastingCaudalieTooltipTitle;

  /// No description provided for @tastingCaudalieTooltipBody.
  ///
  /// In en, this message translates to:
  /// **'1 caudalie = 1 second of lingering flavor after swallowing or spitting.\n• 1 to 4 caudalies: light, crisp wine\n• 5 to 7 caudalies: beautiful balance\n• 8 to 12+ caudalies: exceptional fine wine!'**
  String get tastingCaudalieTooltipBody;

  /// No description provided for @tastingAddCustomAroma.
  ///
  /// In en, this message translates to:
  /// **'+ Custom aroma'**
  String get tastingAddCustomAroma;

  /// No description provided for @tastingCustomAromaDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a precise aroma'**
  String get tastingCustomAromaDialogTitle;

  /// No description provided for @tastingCustomAromaHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Smoked flint, Wild blackberry, Dried rose...'**
  String get tastingCustomAromaHint;

  /// No description provided for @tastingFoodSynergyTitle.
  ///
  /// In en, this message translates to:
  /// **'Food pairing synergy 🍽️'**
  String get tastingFoodSynergyTitle;

  /// No description provided for @tastingSynergySublime.
  ///
  /// In en, this message translates to:
  /// **'🤩 Elevated'**
  String get tastingSynergySublime;

  /// No description provided for @tastingSynergyHarmonious.
  ///
  /// In en, this message translates to:
  /// **'👍 Balanced'**
  String get tastingSynergyHarmonious;

  /// No description provided for @tastingSynergyNeutral.
  ///
  /// In en, this message translates to:
  /// **'😐 Neutral'**
  String get tastingSynergyNeutral;

  /// No description provided for @tastingSynergyClashing.
  ///
  /// In en, this message translates to:
  /// **'⚡ Clashing'**
  String get tastingSynergyClashing;

  /// No description provided for @checkoutFastRatingTitle.
  ///
  /// In en, this message translates to:
  /// **'1-tap quick rating (optional):'**
  String get checkoutFastRatingTitle;

  /// No description provided for @checkoutActionTastingTitle.
  ///
  /// In en, this message translates to:
  /// **'Taste this wine'**
  String get checkoutActionTastingTitle;

  /// No description provided for @checkoutActionTastingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Express (1 page) or detailed sommelier format'**
  String get checkoutActionTastingSubtitle;

  /// No description provided for @checkoutActionDeferredRemind.
  ///
  /// In en, this message translates to:
  /// **'Remind later 🌙'**
  String get checkoutActionDeferredRemind;

  /// No description provided for @checkoutActionAerationTimer.
  ///
  /// In en, this message translates to:
  /// **'Aeration timer ⏱️'**
  String get checkoutActionAerationTimer;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ca',
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'ko',
        'la',
        'nl',
        'pt',
        'sv',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ca':
      return AppLocalizationsCa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'la':
      return AppLocalizationsLa();
    case 'nl':
      return AppLocalizationsNl();
    case 'pt':
      return AppLocalizationsPt();
    case 'sv':
      return AppLocalizationsSv();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
