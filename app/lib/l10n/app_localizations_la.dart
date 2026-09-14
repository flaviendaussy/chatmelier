// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Latin (`la`).
class AppLocalizationsLa extends AppLocalizations {
  AppLocalizationsLa([String locale = 'la']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'Cella Mea';

  @override
  String get navCellar => 'Cella';

  @override
  String get navChat => 'Colloquium';

  @override
  String get navJournal => 'Gustatio';

  @override
  String get navStats => 'Statistica';

  @override
  String get actionMenuTitle => 'Actiones Cellae';

  @override
  String get actionAddBottle => 'Ampullam adde';

  @override
  String get actionAddBottleSub => 'Pithema vel manu scribe';

  @override
  String get actionCheckoutBottle => 'Gusta / Aperias';

  @override
  String get actionCheckoutBottleSub => 'Adnota & copiam minue';

  @override
  String get actionLookupWine => 'Vinum consule';

  @override
  String get actionLookupWineSub => 'Revelatio vinaria per AI';

  @override
  String get searchWinePlaceholder => 'Quaere annatam, auctorem, regionem...';

  @override
  String get emptyCellarTitle => 'Cella tua vacua est';

  @override
  String get emptyCellarSub =>
      'Scan primam ampullam ut cellam digitalem aedifices';

  @override
  String get emptyCellarButton => 'Primam ampullam adde';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ampullae',
      one: '1 ampulla',
      zero: '0 ampullae',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Pretium totale';

  @override
  String get filterAll => 'Omnia';

  @override
  String get filterRed => 'Rubrum';

  @override
  String get filterWhite => 'Album';

  @override
  String get filterRose => 'Roseum';

  @override
  String get filterSparkling => 'Spumans';

  @override
  String get filterSheetTitle => 'Filtra Cellae';

  @override
  String get filterReset => 'Restitue';

  @override
  String get filterApply => 'Applicare filtra';

  @override
  String get filterMaturity => 'Maturitas / Tempus Bibendi';

  @override
  String get maturityAtPeak => 'In Fastigio';

  @override
  String get maturityDrinkSoon => 'Mox Bibendum';

  @override
  String get maturityAging => 'In Custodia';

  @override
  String get maturityTooYoung => 'Nimis Iuvenis';

  @override
  String get maturityPastPeak => 'Post Fastigium';

  @override
  String get filterContinents => 'Continentes';

  @override
  String get filterCountries => 'Terrae';

  @override
  String get filterGrapes => 'Uvae Varietates';

  @override
  String get filterAppellations => 'Regiones & Appellationes';

  @override
  String get bottleDetailInfo => 'Notitia & Tellus';

  @override
  String get bottleDetailDrinkingWindow => 'Tempus Bibendi';

  @override
  String get bottleDetailTerroirMap => 'Tabula Telluris & Originis';

  @override
  String get bottleDetailLabelPhoto => 'Pithema Scannatum';

  @override
  String get bottleDetailVintage => 'Annata';

  @override
  String get bottleDetailProducer => 'Vinitor';

  @override
  String get bottleDetailRegion => 'Regio';

  @override
  String get bottleDetailCountry => 'Terra';

  @override
  String get bottleDetailAppellation => 'Appellatio';

  @override
  String get bottleDetailGrapes => 'Uvae';

  @override
  String get bottleDetailAlcohol => 'Gradus alcoholicus';

  @override
  String get bottleDetailStock => 'Copia';

  @override
  String get bottleDetailLocation => 'Locus in Cella';

  @override
  String get bottleDetailRack => 'Pluteus';

  @override
  String get bottleDetailShelf => 'Tabula';

  @override
  String get bottleDetailPurchasePrice => 'Pretium Emptionis';

  @override
  String get bottleDetailEstimatedValue => 'Pretium Aestimatum';

  @override
  String get bottleDetailFoodPairings => 'Cibi Accommodati';

  @override
  String get bottleDetailTastingNotes => 'Dotes Sommelier';

  @override
  String get bottleDetailDrinkButton => 'Ampullam aperi';

  @override
  String get bottleDetailEdit => 'Recense';

  @override
  String get bottleDetailDelete => 'Dele';

  @override
  String get bottleDetailDeleteConfirm =>
      'Certusne es hanc ampullam omnino delere velle?';

  @override
  String get deleteBottleTitle => 'In Perpetuum Dele';

  @override
  String get deleteBottleExplanation =>
      'Monitio: deletio omnem memoriam huius ampullae exstinguet.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Aperi / Bibe: ampullam in historia gustandi servat.';

  @override
  String get deleteBottleDifferenceDelete =>
      'In perpetuum dele: sine vestigio delet.';

  @override
  String get deleteBottleActionConfirm => 'In Perpetuum Dele';

  @override
  String get deleteBottleActionDrinkInstead => 'Potius Bibe';

  @override
  String get cancel => 'Cancella';

  @override
  String get confirm => 'Confirma';

  @override
  String get checkoutTitle => 'Gustatio & Ex Cella Sumptio';

  @override
  String get checkoutSelectPrompt => 'Tange ad ampullam eligendam...';

  @override
  String get checkoutQtyOpened => 'Ampullae apertae';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'ex $total in cella';
  }

  @override
  String get checkoutRating => 'Aestimatio Gustationis';

  @override
  String get checkoutFoodPairing => 'Cibi coniuncti (optivum)';

  @override
  String get checkoutFoodHint => 'e.g., Caro bubula, oryza cum fungis...';

  @override
  String get checkoutNotes => 'Sensus & Notae';

  @override
  String get checkoutNotesHint => 'Aromata, aequilibrium, longitudo...';

  @override
  String get checkoutSubmit => 'Confirmare gustationem';

  @override
  String get checkoutSuccess => 'Gustatio prospere conscripta!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Salve! Ego sum Chatmelier. Roga me de ciborum vinique concordia, de consiliis bibendi, vel de cella tua.';

  @override
  String get chatAnalyzing => 'Chatmelier cellam tuam perscrutatur...';

  @override
  String get chatInputHint => 'Interroga Chatmelier...';

  @override
  String get chatChipTonight => '🍷 Quid hac nocte bibam?';

  @override
  String get chatChipSteak => '🥩 Vinum pro carne bubula';

  @override
  String get chatChipSeafood => '🐟 Album vinum pro piscibus';

  @override
  String get chatChipPeak => '⏰ Quae ampullae in fastigio sunt?';

  @override
  String get journalTitle => 'Ephemeris Gustationum';

  @override
  String get journalEmpty => 'Nullae gustationes conscriptae';

  @override
  String get journalEmptySub =>
      'Aperi et gusta ampullam ad ephemeridem inchoandam';

  @override
  String journalTastedOn(String date) {
    return 'Gustatum die $date';
  }

  @override
  String get statsTitle => 'Statistica Cellae';

  @override
  String get statsTotalBottles => 'Ampullae in Cella';

  @override
  String get statsTotalValue => 'Pretium Cellae';

  @override
  String get statsBottlesEnjoyed => 'Ampullae Gustatae';

  @override
  String get statsByColor => 'Distributio secundum Colorem';

  @override
  String get statsByMaturity => 'Distributio secundum Maturitatem';

  @override
  String get statsByRegion => 'Praecipuae Regiones';

  @override
  String get statsByCountry => 'Praecipuae Terrae';

  @override
  String get profileTitle => 'Profili & Praecepta';

  @override
  String get profileEmail => 'Cursus Electronicus';

  @override
  String get profileDisplayName => 'Nomen Praeferendum';

  @override
  String get profileDefaultCurrency => 'Moneta Ordinaria';

  @override
  String get profileLanguage => 'Lingua Appositi';

  @override
  String get profileLanguageSystem => 'Automatica (Systema)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Moneta mutata: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Lingua mutata est';

  @override
  String get profileLogout => 'Egredi';

  @override
  String get profileAbout => 'De Chatmelier';

  @override
  String get scanTitle => 'Pithema Vini Scanna';

  @override
  String get scanTakePhoto => 'Imaginem cape';

  @override
  String get scanPickGallery => 'Elige ex pinacotheca';

  @override
  String get scanAnalyzing => 'Chatmelier AI pithema perscrutatur...';

  @override
  String get scanIdentified => 'Vinum agnitum a Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Adde in cellam meam';

  @override
  String get loginTitle => 'Ingressus';

  @override
  String get loginTagline => 'Cella Tua Vinaria cum Intelligentia Artificiali';

  @override
  String get loginTabMagicLink => '✉️ Vinculum Ingressus';

  @override
  String get loginTabPassword => '🔑 Tessera';

  @override
  String get loginEmailLabel => 'Inscriptio electronica';

  @override
  String get loginPasswordLabel => 'Tessera';

  @override
  String get loginSendMagicLink => 'Mitte Vinculum';

  @override
  String get loginSignInButton => 'Ingredere';

  @override
  String get loginOrDivider => 'VEL';

  @override
  String get loginGoogleButton => 'Perge cum Google';

  @override
  String get loginRegisterLink => 'Nonne rationem habes? Crea novam';

  @override
  String get registerTitle => 'Creare Rationem';

  @override
  String get registerNameLabel => 'Nomen / Praenomen';

  @override
  String get registerSubmitButton => 'Creare rationem meam';

  @override
  String get registerFillAllFields => 'Omnes campos exple quaeso';

  @override
  String get registerWelcome => '🎉 Bene venisti ad Chatmelier!';

  @override
  String get registerErrorGeneric => 'Error in ratione creando';

  @override
  String get authWelcome => 'Bene venisti ad Chatmelier';

  @override
  String get authSubtitle => 'Curator cellae tuae & socius AI';

  @override
  String get authGoogle => 'Perge cum Google';

  @override
  String get authMagicLink => 'Ingredere per vinculum electronicum';

  @override
  String get authEmail => 'Inscriptio electronica';

  @override
  String get authNoAccount => 'Nonne rationem habes? Inscribe te';

  @override
  String get authHaveAccount => 'Iam rationem habes? Ingredere';

  @override
  String get changelogTitle => 'Historia Mutationum';

  @override
  String get changelogEmpty => 'Nullae mutationes notatae.';

  @override
  String get scratchcardTitle => 'Tabula Mundi Terroir';

  @override
  String get profileChangelog => 'Historia & Versio';

  @override
  String get profileScratchcard => 'Tabula Terroir';

  @override
  String get navBar => 'Taberna';

  @override
  String get navProfile => 'Profili';

  @override
  String get quickActions => 'ACTIONES RAPIDAE';

  @override
  String get appSubtitle => 'Sommelier & Cella Vinaria';

  @override
  String get profileTabPalate => 'Palatum';

  @override
  String get profileTabSettings => 'Praecepta';

  @override
  String get profileTabTools => 'Instrumenta';

  @override
  String get profileTabAccount => 'Ratio';

  @override
  String get profileTheme => 'Modus / Thema';

  @override
  String get profileThemeLight => 'Clarus ☀️';

  @override
  String get profileThemeDark => 'Obscurus 🌙';

  @override
  String get profileThemeSystem => 'Systema ⚙️';

  @override
  String get profileFriends => 'Amici & Tabulae Palati 🍷';

  @override
  String get profileExport => 'Exportare Cellam & Aestimationem 📊';

  @override
  String get profileDeleteAccount => 'In Perpetuum Dele Rationem Meam';

  @override
  String get profileDeleteConfirmTitle => 'Dele Rationem';

  @override
  String get profileDeleteConfirmMsg =>
      'Hoc revocari non potest. Omnia data tua delebuntur.';

  @override
  String get badgesGalleryTitle => 'Pinacotheca Praemiorum';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total reserata • $pct% perfectum';
  }

  @override
  String get badgesFilterAll => 'Omnia';

  @override
  String get badgesEmpty => 'Nulla insignia inventa.';

  @override
  String get badgesUnlockedChip => 'Reseratum ✨';

  @override
  String get badgesStatusUnlocked => 'Insigne Reseratum!';

  @override
  String get badgesStatusInProgress => 'In Cursu';

  @override
  String get badgesObjectiveLabel => 'Propositum:';

  @override
  String get badgesChatmelierLoreTitle => 'Doctrina & Scientia Chatmelier';

  @override
  String get badgesCloseButton => 'Claudere';

  @override
  String get badgesTierLabel => 'Gradus';

  @override
  String get badgesShowcaseTitle => 'Praemia & Insignia';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked ex $total reserata';
  }

  @override
  String get badgesShowcaseGallery => 'Pinacotheca';

  @override
  String get cocktailsTitle => 'Taberna & Mixturae';

  @override
  String get cocktailsReadyToShake => 'Paratus ad Agitandum';

  @override
  String get cocktailsMissingOne => '1 deest';

  @override
  String get cocktailsManagePantry => 'Cura Promptuarium';

  @override
  String get cocktailsResetPantry => 'Restitue Promptuarium';

  @override
  String get save => 'Servare';

  @override
  String get continueAnyway => 'Nihilominus pergere';

  @override
  String get cellarDetected => 'Cella vinaria inventa: ';

  @override
  String proximityWifi(String ssid) {
    return 'Connexum ad Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'Locus GPS inventus ad $distance';
  }

  @override
  String get proximitySwitch => 'Commutare';

  @override
  String get proximityIgnore => 'Neglegere';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Automatice commutatum ad \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Cella distans inventa';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Nunc connectaris ad Wi-Fi \"$ssid\" coniunctum cum altera cella tua \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Circiter $distance distas a cella tua \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nVisne hanc lagunculam cellae \"$cellar\" addere?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nVisne hanc lagunculam e cella \"$cellar\" depromere?';
  }

  @override
  String get ratingExceptional => '🏆 Egregium';

  @override
  String get ratingRemarkable => '✨ Insigne';

  @override
  String get ratingVeryGood => '🍷 Valde bonum';

  @override
  String get ratingPleasant => '👍 Iucundum';

  @override
  String get ratingPassable => 'Tolerabile';

  @override
  String get checkoutWhoTasted => 'Quicum hoc vinum degustavisti?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'lagunculae',
      one: 'laguncula',
    );
    return '$producer • In promptu: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Convivam addere';

  @override
  String get checkoutAddGuestHint => 'Nomen adde (Mater, Pater...)';

  @override
  String get checkoutCloseAndTaste => 'Claudere & Frui 🍷';

  @override
  String get checkoutSommelierThinking => 'Sommeliers fabulas parat...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Aerationis mensura in tegmine operatur!';

  @override
  String get checkoutStartAerationTimer => 'Incipere mensuram ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Aerationis Mensura';

  @override
  String get checkoutDelayedTonight => 'Hac nocte hora 22:00';

  @override
  String get checkoutDelayedTonightSub =>
      'Post cenam optime convenit ad memoriam reficiendam';

  @override
  String get checkoutDelayedTomorrow => 'Cras mane hora 11:00';

  @override
  String get checkoutDelayedTomorrowSub => 'In quiete ad sensus annotandos';

  @override
  String get checkoutDelayedWeekend =>
      'Hoc fine hebdomadis (Sabbato hora 11:00)';

  @override
  String get checkoutDelayedWeekendSub => 'Tempus sume in otio tuo';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'Post 2 horas ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Brevis admonitio post degustationem';

  @override
  String get checkoutDelayedCustom => 'Diem & horam eligere...';

  @override
  String get reviewPackagingDetected => 'Forma involucri inventa';

  @override
  String get reviewSingleBottleOnly => 'Non, 1 tantum laguncula';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Ita, $count lagunculae';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Promptuarium feliciter renovatum! ($count lagunculae in cella)';
  }

  @override
  String get reviewVintageYear => 'Vindemia / Annus';

  @override
  String get reviewNonVintage => 'Omittere / Sine anno (NV)';

  @override
  String get reviewValidate => 'Confirmare';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name feliciter cellae addita est!';
  }

  @override
  String get reviewBottleAnalysis => 'Inspectio lagunculae';

  @override
  String get reviewDiscard => 'Abicere';

  @override
  String get reviewDiscardConfirmTitle => 'Abicere inceptum?';

  @override
  String get reviewContinueEditing => 'Pergere scribere';

  @override
  String get reviewDiscardWithoutSaving => 'Exire sine servando';

  @override
  String get reviewBottleDetails => 'Indicia lagunculae';

  @override
  String get reviewStockInCellar => 'Cellae promptuarium';

  @override
  String get reviewStockAddition => 'Addere';

  @override
  String get reviewStockNewTotal => 'Novus numerus';

  @override
  String get reviewQuantityToAdd => 'Numerus addendus:';

  @override
  String get reviewSeparateEntry => 'Novam partitionem creare';

  @override
  String get reviewRetryAi => 'Iterum temptare IA';

  @override
  String get reviewEnlarge => 'Amplificare';

  @override
  String get reviewGeneralInfo => 'Communia indicia';

  @override
  String get reviewOriginTerroir => 'Origo & Solum';

  @override
  String get reviewQuantityPurchase => 'Numerus & Pretium';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi inventum & iunctum: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed => 'Wi-Fi non inventum est';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS coordinata capta ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible => 'GPS locus non patet.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Cella \"$cellar\" feliciter creata est!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Error in creando: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 metra (curatissimum)';

  @override
  String get cellarRadiusRecommended => '300 metra (suasum)';

  @override
  String get cellarRadius500m => '500 metra';

  @override
  String get cellarRadius1km => '1 chiliometrum';

  @override
  String get cellarRadius3km => '3 chiliometra';

  @override
  String get cellarCreateButton => 'Cellam creare';

  @override
  String get cellarUseCurrentGps => 'GPS praesentem locum ponere';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Cellae \"$cellar\" ordines renovati sunt';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Error in renovando: $error';
  }

  @override
  String get wineTypeRed => 'Vinum Rubrum 🍷';

  @override
  String get wineTypeWhite => 'Vinum Album 🥂';

  @override
  String get wineTypeRose => 'Vinum Roseum 🌸';

  @override
  String get wineTypeSparkling => 'Vinum Spumans 🍾';

  @override
  String get wineTypeDessert => 'Vinum Dulce 🍯';

  @override
  String get wineTypeLiqueur => 'Liquor 🍯';

  @override
  String get wineTypeSpirit => 'Spiritus 🥃';

  @override
  String get wineTypeGrappa => 'Vinacea / Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Aqua Vitae Pomorum 🍐';

  @override
  String get wineTypeWhisky => 'Vischium 🥃';

  @override
  String get wineTypeRum => 'Rhomium 🏴‍☠️';

  @override
  String get wineTypeGin => 'Iuniperatum 🍸';

  @override
  String get wineTypeVodka => 'Vodca 🧊';

  @override
  String get wineTypeTequila => 'Tequila 🌵';

  @override
  String get wineTypeCognac => 'Coniacum 🍷';

  @override
  String get cellarCreateTitle => 'Novam cellam creare';

  @override
  String get cellarManageTitle => 'Cellam curare';

  @override
  String get cellarNameLabel => 'Nomen cellae *';

  @override
  String get cellarNameHint => 'v.gr. Cella Domus, Armarium Palatii';

  @override
  String get cellarNameRequired => 'Nomen quaesumus scribe';

  @override
  String get cellarLocationLabel => 'Locus / Urbs (liberum)';

  @override
  String get cellarLocationHint => 'v.gr. Roma, Burdigala';

  @override
  String get cellarNicknameLabel => 'Cognomen / Conclave (liberum)';

  @override
  String get cellarNicknameHint => 'v.gr. Hypogeum, Tablinum';

  @override
  String get cellarDescriptionLabel => 'Descriptio (liberum)';

  @override
  String get cellarDescriptionHint => 'v.gr. Cella frigida sub terra, umor 70%';

  @override
  String get cellarWifiLabel => 'Wi-Fi iunctum (liberum)';

  @override
  String get cellarWifiHint => 'v.gr. Cella-WiFi';

  @override
  String get cellarLinkCurrentWifi => 'Wi-Fi praesenti iungere';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Wi-Fi capere';

  @override
  String get cellarRadiusLabel => 'GPS spatium';

  @override
  String get cellarAutoDetectionHeader => 'Automatica Inventio';

  @override
  String get cellarAutoDetectionDesc =>
      'Wi-Fi vel GPS coordinata iunge ut automatice haec cella aperiatur.';

  @override
  String get cellarLatitudeLabel => 'Latitudo';

  @override
  String get cellarLongitudeLabel => 'Longitudo';

  @override
  String get checkoutGuidedTasting => 'Ducta degustatio';

  @override
  String get checkoutGuidedTastingShared =>
      'Sensus ordine vel simul communicare';

  @override
  String get checkoutGuidedTastingSolo => 'Aspectum, odorem, saporem perquire';

  @override
  String get checkoutUncorkNowRateLater => 'Nunc aperire, postea iudicare';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Statim depromere • Admonitionis tempus selige';

  @override
  String get checkoutUncorkAeration => 'Aperire & Aeratio';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Statim depromere • $minutes min aeratio suadetur';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Statim depromere • Aerationis mensura';

  @override
  String get checkoutSommelierServiceAdvice => 'Sommelieris consilia';

  @override
  String get checkoutHistoryAnecdotes => 'Historiae & Fabulae';

  @override
  String get checkoutNoDecanting => 'Non opus est diffundere';

  @override
  String get checkoutStoryTitle => 'Huius lagunculae historia 📖';

  @override
  String get checkoutStorySubtitle => 'Iucundae fabulae ad convivium';

  @override
  String get checkoutStoryTerroir => 'Solum & Uvae';

  @override
  String get checkoutStoryVintage => 'Vindemiae memoria';

  @override
  String get checkoutStoryTastingSecret => 'Gustus arcanum';

  @override
  String get checkoutStoryTableAnecdote => 'Mensa fabula';

  @override
  String get checkoutJournalArchivedNotice =>
      'Haec laguncula in Ephemeride tua cum imaginibus servabitur.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Laguncula aperta! Aeratio ($minutes min) currit.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'Laguncula statim deprometur. Aerationis tempus confirma:';

  @override
  String get checkoutRateWine => 'Vinum aestimare';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Mensura ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Consilium: aeratio per $minutes min parata est.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Admonitio parata est post gustandum.';

  @override
  String get checkoutBottleRemovedSuccess => 'Laguncula e cella prompta est!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Fruaris vino. Admonitio ad diem $date parata est.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'Gustus forma uniuscuiusque augebitur.';

  @override
  String checkoutCellarOf(String name) {
    return 'Cella $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Promptuarium: $count lag.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Adde amicum qui tecum degustat (v.gr. Mater, Pater, Marcus...).';

  @override
  String get checkoutAddGuestNameLabel => 'Nomen';

  @override
  String get checkoutDelayedSheetTitle => 'Aperire et postea aestimare';

  @override
  String get checkoutDelayedSheetSubtitle => 'Quando admoneri vis?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Hac nocte post 2 horas ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Hac nocte hora 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'hac nocte hora $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'cras hora $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'die $date hora $time';
  }

  @override
  String get add => 'Addere';

  @override
  String get cellarWinesTab => '🍷 Vina';

  @override
  String get cellarSpiritsTab => '🥃 Spiritus';

  @override
  String get cellarPairWithDish => 'Quod vinum huic cibo?';

  @override
  String get cellarCollapseAll => 'Omnia complica';

  @override
  String get cellarExpandAll => 'Omnia explica';

  @override
  String get cellarSort => 'Ordina';

  @override
  String get cellarCategories => 'Categoriae';

  @override
  String get cellarFavorites => 'Dilecta';

  @override
  String get cellarGridView => 'Cancellata';

  @override
  String get cellarListView => 'Index';

  @override
  String get cellarClearFilters => 'Filtra dele';

  @override
  String get cellarNoBottlesCategory => 'Nulla ampulla in hac categoria';

  @override
  String get cellarNoBottlesCriteria => 'Nulla ampulla his regulis convenit';

  @override
  String get feedbackSheetTitle => 'Refert Inspectoris & Adnotatio';

  @override
  String get feedbackStylus => 'Stilus :';

  @override
  String get feedbackUndo => 'Priorem lineam dele';

  @override
  String get feedbackClear => 'Omnia dele';

  @override
  String get feedbackHint =>
      'Circumda spatium et describe mendum vel sententiam...';

  @override
  String get feedbackSubmit => 'Mitte rationem';

  @override
  String get feedbackSubmitting => 'Mittens...';

  @override
  String get feedbackNoScreenshot => 'Nulla scaenae imago adest';

  @override
  String get feedbackEmptyError => 'Quaeso adde notam aut lineam in imagine.';

  @override
  String get feedbackSuccess => 'Gratias agimus! 🍷 Renuntiatio missa est.';

  @override
  String feedbackError(String error) {
    return 'Error in mittendo: $error';
  }

  @override
  String get checkoutFastExit => 'Celeris depromptio sine quaestionario ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Depromitur...';

  @override
  String get checkoutRatingSubtitle => 'Iudicium generale post degustationem';

  @override
  String get checkoutRecommendedBadge => 'Suasum';

  @override
  String get tastingWhoTastedTitle => '👥 Quis hoc vinum gustavit?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Selige convivas. Gustus proprietates adaptabuntur.';

  @override
  String get tastingHowToTaste => 'Quomodo degustare?';

  @override
  String get tastingEachTurn => 'Singuli per vices';

  @override
  String get tastingEachTurnDesc =>
      '📱 Telephono tradito: quisque suo gradu respondet.';

  @override
  String get tastingTogether => 'Omnes una';

  @override
  String get tastingTogetherDesc =>
      '🥂 Una quaestio pro omnibus convivis solvitur.';

  @override
  String get tastingBlindMode => 'Caeca Degustatio';

  @override
  String get tastingBlindModeDesc =>
      'Nomen vini occultat et ludum mensae incipit!';

  @override
  String get tastingPrimaryProfile => 'Primum profilum';

  @override
  String get tastingAppInstalled => 'App paratum 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quaestiones solutae',
      one: '1 quaestio soluta',
      zero: '0 quaestiones solutae',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 Olfactus — Odorum Expressio';

  @override
  String get tastingStepNezSubtitle =>
      'Calicem circumage et odores exhalantes percipe.';

  @override
  String get tastingAromaIntensity => 'Odoris vis:';

  @override
  String get tastingAromaDiscreet => '🤫 Tenuis / Subtilis';

  @override
  String get tastingAromaExplosive => '💥 Effusa / Vehemens';

  @override
  String get tastingStepBoucheTitle => '⚖️ Gustatus — Aequilibrium';

  @override
  String get tastingStepBoucheSubtitle =>
      'Texturam, aciditatem et concordiam in palato describe.';

  @override
  String get tastingAcidity => 'Aciditas:';

  @override
  String get tastingAcidityFreshness => 'Aciditas & Vigor:';

  @override
  String get tastingAcidityFlat => '🫠 Lenta / Iacens';

  @override
  String get tastingAciditySharp => '⚡ Acris / Vivida';

  @override
  String get tastingTannins => 'Tannina:';

  @override
  String get tastingTanninsSilky => '🧶 Sericea / Lenia';

  @override
  String get tastingTanninsGrippy => '💪 Firma / Firmatum';

  @override
  String get tastingMinerality => 'Minerale & Sal:';

  @override
  String get tastingMineralityRound => '🧈 Rotundum / Pinguis';

  @override
  String get tastingMineralityCrisp => '🪨 Silex / Limpidum';

  @override
  String get tastingEffervescence => 'Spuma (Spumans):';

  @override
  String get tastingEffervescenceDelicate => '🫧 Tenuis / Delicata';

  @override
  String get tastingEffervescenceVibrant => '🎆 Vivida / Cremosa';

  @override
  String get tastingBody => 'Corpus / Pondus:';

  @override
  String get tastingBodyLight => '🍃 Leve / Agile';

  @override
  String get tastingBodyFull => '🏋️ Plenum / Robustum';

  @override
  String get tastingLength => 'Diuturnitas / Finis:';

  @override
  String get tastingLengthShort => '⏱️ Brevis';

  @override
  String get tastingLengthLong => '♾️ Diuturna';

  @override
  String get tastingStepVerdictTitle => '✅ Decretum';

  @override
  String get tastingBuyAgain => 'Visne iterum hoc emere?';

  @override
  String get tastingBuyAgainYes => '🤩 Certe!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Forsitan';

  @override
  String get tastingBuyAgainNo => '👎 Minime';

  @override
  String get tastingIdealMoment => 'Opportunitas optima huic vino?';

  @override
  String get tastingMomentApero => '🥂 Ante cenam';

  @override
  String get tastingMomentMeal => '🍽️ Cotidiana cena';

  @override
  String get tastingMomentDinner => '🎩 Solemnis cena';

  @override
  String get tastingMomentRomantic => '🕯️ Amantium cena';

  @override
  String get tastingMomentSolo => '🧘 Solitudo et quies';

  @override
  String get tastingWhatLiked => 'Quod maxime placuit:';

  @override
  String get tastingWhatDisliked => 'Quod displicuit:';

  @override
  String get tastingOccasionLabel => 'Occasio / Memoria (liberum) ✨';

  @override
  String get tastingOccasionHint => 'v.gr. Natalis, Amor, Convivium...';

  @override
  String get tastingAddPhoto => 'Mensae imaginem addere 📸';

  @override
  String get tastingPhotoSaved => 'Imago servata est 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Iudicium & Notatio';

  @override
  String get tastingStepImpressionSubtitle =>
      'Post odores et sapores, generalem notam impone.';

  @override
  String get tastingOverallFeeling => 'Tua generalis sententia:';

  @override
  String get tastingScoreOutOf10 => 'Nota ex 10:';

  @override
  String get tastingCompletedTitle => 'Degustatio perfecta & servata est!';

  @override
  String get tastingCompletedSubtitle => 'Gustus proprietates renovatae sunt ✨';

  @override
  String get tastingBottleRemoved => 'Laguncula aperta et e cella prompta';

  @override
  String get tastingConsultDebrief => 'Sommelieris conspectum inspicere';

  @override
  String get tastingFinishButton => 'Finire ✨';

  @override
  String get tastingNextTaster => 'Confirmare → Proximus';

  @override
  String get tastingConfirmAndFinish => 'Confirmare & Concludere ✨';

  @override
  String get tastingQuitTitle => 'Relinquere quaestionarium?';

  @override
  String get tastingQuitMessage => 'Responsa tua non servabuntur.';

  @override
  String get tastingContinue => 'Pergere';

  @override
  String get tastingQuit => 'Exire';

  @override
  String tastingStartCount(int count) {
    return 'Incipere ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Cum $name app iunctum ✨';
  }

  @override
  String get tastingProfileEnriched => 'Gustus ditatus est';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Acutio: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle => 'Saporum origo & Vini arcana';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Unde odores, color et corpus proveniant cognosce';

  @override
  String get tastingBlindQuizTitle => 'Mensae caecus ludus 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. Quae est origo agri? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. Quae est praecipua uva? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Aetas aut vindemia aestimata? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Aestimatum pretium? 💶';

  @override
  String get tastingBlindRevealTitle => 'Mysterii lagunculae patefactio 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Caeci ludi puncta: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Oenologica & molecularis inspectio';

  @override
  String get tastingSensoryAcuity => 'ACUTIO SENSORIA';

  @override
  String tastingPrecision(int score) {
    return 'Veritas $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. CONCORDIA ET NOTA';

  @override
  String get tastingWhatYouDetected => 'QUOD PERCEPISTI:';

  @override
  String get tastingArchetypeSignature => 'PROPRIA VINI NOTA:';

  @override
  String get tastingHiddenNuancesTitle => 'SUBTILES NOTAE IN PROXIMUM CALICEM:';

  @override
  String get tastingPillarsTitle => '2. OENOLOGICA SCIENTIA';

  @override
  String get tastingPillarsSubtitle =>
      'Cur hoc vinum hoc corpus, hos odores et hunc colorem habeat?';

  @override
  String get tastingChatWithSommelier => 'Cum Chatmelier arcana altius scruta';

  @override
  String get aromaFruitsRouges => 'Baccae rubrae (fraga, cerasa)';

  @override
  String get aromaFruitsNoirs => 'Baccae nigrae (mora, cassis)';

  @override
  String get aromaFruitsBlancs => 'Poma alba (persica, pira, mala)';

  @override
  String get aromaAgrumes => 'Citri fructus (limones)';

  @override
  String get aromaFloral => 'Florale (violae, rosae)';

  @override
  String get aromaVegetal => 'Herbeum et viride (silva)';

  @override
  String get aromaEpicesDouces => 'Aromata dulcia (cinnamum)';

  @override
  String get aromaEpicesVives => 'Aromata acria (piper nigrum)';

  @override
  String get aromaBoise => 'Quercus & Vanilla (dolium)';

  @override
  String get aromaBeurre => 'Butyrum & Panis dulcis';

  @override
  String get aromaMineral => 'Minerale (silex, creta)';

  @override
  String get aromaMiel => 'Mel & Conditura';

  @override
  String get aromaChocolat => 'Socolata & Caffa';

  @override
  String get aromaFumee => 'Fumidum & Torrefactum';

  @override
  String get emojiDisliked => 'Displicuit';

  @override
  String get emojiMeh => 'Mediocre';

  @override
  String get emojiDecent => 'Decens';

  @override
  String get emojiVeryGood => 'Valde bonum';

  @override
  String get emojiLoved => 'Admirabile!';

  @override
  String get likedFreshness => 'Vigor et aciditas';

  @override
  String get likedFruitiness => 'Fructus iucunditas';

  @override
  String get likedComplexity => 'Saporum varietas';

  @override
  String get likedElegance => 'Elegantia';

  @override
  String get likedPower => 'Corpus et robur';

  @override
  String get likedSilky => 'Tanninum sericeum';

  @override
  String get likedOriginality => 'Natura singularis';

  @override
  String get likedFoodPairing => 'Concordia cum cibo';

  @override
  String get likedMinerality => 'Salinitas terrae';

  @override
  String get likedLength => 'Saporis diuturnitas';

  @override
  String get likedDisappointing => 'Nihil / Falsum 😕';

  @override
  String get dislikedTooAcidic => 'Nimis acidum';

  @override
  String get dislikedTooTannic => 'Nimis adstringens';

  @override
  String get dislikedTooOaked => 'Nimis quercinum';

  @override
  String get dislikedTooAlcoholic => 'Nimis fervens';

  @override
  String get dislikedTooThin => 'Nimis dilutum';

  @override
  String get dislikedLacksFruit => 'Fructu carens';

  @override
  String get dislikedTooSweet => 'Nimis dulce';

  @override
  String get dislikedTooExpensive => 'Nimis carum';

  @override
  String get dislikedNothing => 'Nihil, erat omnino perfectum!';

  @override
  String get tastingStepTasters => 'Convivae';

  @override
  String get tastingStepNezNav => 'Nasus';

  @override
  String get tastingStepBoucheNav => 'Palatum';

  @override
  String get tastingStepVerdictNav => 'Decretum';

  @override
  String get tastingStepRatingNav => 'Nota';

  @override
  String get tastingBack => 'Retro';

  @override
  String get tastingNext => 'Ultra';

  @override
  String get tastingSaving => 'Servatur...';

  @override
  String get tastingHeaderTitle => 'Degustationis charta';

  @override
  String tastingAnswersOf(String name) {
    return 'Responsa $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Telephonum trade ad $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Responsa tua servata sunt.\nNunc $name aggreditur.';
  }

  @override
  String get tastingDictateButton => 'Voce sensus mandare 🎙️';

  @override
  String get tastingDictateHint =>
      'Libere loquere: Chatmelier IA odores et gustum implebit!';

  @override
  String get tastingDictateMicTip =>
      'Consilium: vocis signum in claviatura tange!';

  @override
  String get tastingTakePhoto => 'Mensa imaginem cape 📸';

  @override
  String get tastingChooseGallery => 'Ex pinacotheca selige 🖼️';

  @override
  String get tastingConclaveSummary => 'Conclavis compendium';

  @override
  String get tastingCellarMaster => 'Magister Cellae';

  @override
  String get tastingGuestTaster => 'Conviva Gustator';

  @override
  String tastingProfileTag(String type) {
    return 'Forma: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Libera annotatio servata est.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Species: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Structura: $structure ($caudalies caudaliae)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Moleculae praecipuae: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Causa princeps: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Uvae: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'A Chatmelier IA sensus applicati sunt ✨';

  @override
  String get tastingBlindYourPredictions => 'Mensae praedictiones:';

  @override
  String get tastingBlindGuessCorrect => 'Optime compertum! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Praedicite antequam vinum patescat!';

  @override
  String tastingStartTaster(String name) {
    return 'Age, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Euge!';

  @override
  String tastingQuizWas(String answer) {
    return '(Responsum erat: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'v.gr. Petrus valde laetatus est 8.5/10 dans, cum notis silvae et cassis...';

  @override
  String get tastingDictateAnalyzing => 'Investigatur...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Investigare & chartis applicare ✨';

  @override
  String get tastingFormatExpress => 'Brevis forma (1 pagina) ⚡';

  @override
  String get tastingFormatExpressDesc => 'Nota, odores et iudicium intra 30s';

  @override
  String get tastingFormatSommelier => 'Sommelieris forma (Curata) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Olfactus, gustus, diuturnitas et solum penitus perquisita';

  @override
  String get tastingCaudalieTooltipTitle => 'Quid est caudalia? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalia = 1 secundum persistendi saporis post haustum vel exspuitionem.\n• 1 ad 4 caudaliae: vinum lene et agile\n• 5 ad 7 caudaliae: aequilibrium nobile\n• 8 ad 12+ caudaliae: vinum vere insigne!';

  @override
  String get tastingAddCustomAroma => '+ Singularis odor';

  @override
  String get tastingCustomAromaDialogTitle => 'Aromatis nomen adde';

  @override
  String get tastingCustomAromaHint =>
      'v.gr. Silex fumidus, Rubus, Rosa sicca...';

  @override
  String get tastingFoodSynergyTitle => 'Concordia cum cibo 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Sublime';

  @override
  String get tastingSynergyHarmonious => '👍 Maxime concors';

  @override
  String get tastingSynergyNeutral => '😐 Aequum';

  @override
  String get tastingSynergyClashing => '⚡ Discors';

  @override
  String get checkoutFastRatingTitle => 'Celeris nota (liberum):';

  @override
  String get checkoutActionTastingTitle => 'Hoc vinum degustare';

  @override
  String get checkoutActionTastingSubtitle =>
      'Forma brevis aut accurata sommelieris';

  @override
  String get checkoutActionDeferredRemind => 'Postea admonere 🌙';

  @override
  String get checkoutActionAerationTimer => 'Aerationis mensura ⏱️';
}
