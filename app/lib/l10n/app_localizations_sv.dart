// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'Min Vinkällare';

  @override
  String get navCellar => 'Vinkällare';

  @override
  String get navChat => 'Chatt';

  @override
  String get navJournal => 'Historik';

  @override
  String get navStats => 'Statistik';

  @override
  String get actionMenuTitle => 'Källaråtgärder';

  @override
  String get actionAddBottle => 'Lägg till en flaska';

  @override
  String get actionAddBottleSub => 'Skanna etikett eller manuell inmatning';

  @override
  String get actionCheckoutBottle => 'Kork upp / Provsmaka flaska';

  @override
  String get actionCheckoutBottleSub =>
      'Registrera provning och dra av från lagret';

  @override
  String get actionLookupWine => 'Slå upp / Identifiera vin';

  @override
  String get actionLookupWineSub => 'Omedelbar AI-igenkänning och vinguide';

  @override
  String get searchWinePlaceholder => 'Sök årgång, producent, appellation...';

  @override
  String get emptyCellarTitle => 'Din vinkällare är tom';

  @override
  String get emptyCellarSub =>
      'Skanna din första flaska för att bygga din digitala samling';

  @override
  String get emptyCellarButton => 'Lägg till min första flaska';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flaskor',
      one: '1 flaska',
      zero: '0 flaskor',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Totalt värde';

  @override
  String get filterAll => 'Alla';

  @override
  String get filterRed => 'Rött';

  @override
  String get filterWhite => 'Vitt';

  @override
  String get filterRose => 'Rosé';

  @override
  String get filterSparkling => 'Mousserande';

  @override
  String get filterSheetTitle => 'Källarfilter';

  @override
  String get filterReset => 'Återställ';

  @override
  String get filterApply => 'Tillämpa filter';

  @override
  String get filterMaturity => 'Mognadsstatus / Drickfönster';

  @override
  String get maturityAtPeak => 'På topp (drickfärdigt)';

  @override
  String get maturityDrinkSoon => 'Drick snart';

  @override
  String get maturityAging => 'För lagring';

  @override
  String get maturityTooYoung => 'För ungt';

  @override
  String get maturityPastPeak => 'Förbi toppen';

  @override
  String get filterContinents => 'Kontinenter';

  @override
  String get filterCountries => 'Länder';

  @override
  String get filterGrapes => 'Druvsorter';

  @override
  String get filterAppellations => 'Regioner & Appellationer';

  @override
  String get bottleDetailInfo => 'Information & Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Drickfönster';

  @override
  String get bottleDetailTerroirMap => 'Terroir- och Ursprungskarta';

  @override
  String get bottleDetailLabelPhoto => 'Originalfoto av etikett';

  @override
  String get bottleDetailVintage => 'Årgång';

  @override
  String get bottleDetailProducer => 'Producent / Vingård';

  @override
  String get bottleDetailRegion => 'Region';

  @override
  String get bottleDetailCountry => 'Land';

  @override
  String get bottleDetailAppellation => 'Appellation';

  @override
  String get bottleDetailGrapes => 'Druvsorter';

  @override
  String get bottleDetailAlcohol => 'Alkoholhalt';

  @override
  String get bottleDetailStock => 'Lager';

  @override
  String get bottleDetailLocation => 'Placering i källaren';

  @override
  String get bottleDetailRack => 'Vinställ';

  @override
  String get bottleDetailShelf => 'Hylla';

  @override
  String get bottleDetailPurchasePrice => 'Inköpspris';

  @override
  String get bottleDetailEstimatedValue => 'Uppskattat värde';

  @override
  String get bottleDetailFoodPairings => 'Rekommenderade matkombinationer';

  @override
  String get bottleDetailTastingNotes => 'Sommelierprofil';

  @override
  String get bottleDetailDrinkButton => 'Korka upp denna flaska';

  @override
  String get bottleDetailEdit => 'Redigera';

  @override
  String get bottleDetailDelete => 'Ta bort';

  @override
  String get bottleDetailDeleteConfirm =>
      'Är du säker på att du vill ta bort den här flaskan permanent från din källare?';

  @override
  String get deleteBottleTitle => 'Ta Bort Permanent';

  @override
  String get deleteBottleExplanation =>
      'Varning: permanent borttagning raderar flaskan och dess historik helt.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Korka upp / Drick: arkiverar flaskan i din provningshistorik, uppdaterar statistik och sparar dina anteckningar.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Ta bort permanent: raderar posten spårlöst (rekommenderas vid felskrivningar, trasiga flaskor eller dubbletter).';

  @override
  String get deleteBottleActionConfirm => 'Ta Bort Permanent';

  @override
  String get deleteBottleActionDrinkInstead => 'Korka upp och drick i stället';

  @override
  String get cancel => 'Avbryt';

  @override
  String get confirm => 'Bekräfta';

  @override
  String get checkoutTitle => 'Provsmaka och Korka upp ur Källaren';

  @override
  String get checkoutSelectPrompt =>
      'Tryck för att välja en flaska ur källaren...';

  @override
  String get checkoutQtyOpened => 'Antal öppnade flaskor';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'av $total i vinkällaren';
  }

  @override
  String get checkoutRating => 'Provningsbetyg';

  @override
  String get checkoutFoodPairing => 'Matchande rätter (valfritt)';

  @override
  String get checkoutFoodHint => 't.ex. Grillad entrecôte, svamprisotto...';

  @override
  String get checkoutNotes => 'Provningsintryck och Anteckningar';

  @override
  String get checkoutNotesHint => 'Aromer, balans, längd, upplevelse...';

  @override
  String get checkoutSubmit => 'Bekräfta provning';

  @override
  String get checkoutSuccess => 'Provningen har registrerats!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Hej! Jag är Chatmelier. Fråga mig om mat- och vinkombinationer, dryckesråd eller rekommendationer baserade på dina källarflaskor.';

  @override
  String get chatAnalyzing => 'Chatmelier analyserar din vinkällare...';

  @override
  String get chatInputHint => 'Fråga Chatmelier...';

  @override
  String get chatChipTonight => '🍷 Vad ska jag dricka ikväll?';

  @override
  String get chatChipSteak => '🥩 Matcha med en god biff';

  @override
  String get chatChipSeafood => '🐟 Bästa vita vinet till skaldjur';

  @override
  String get chatChipPeak => '⏰ Vilka flaskor är på sin absoluta topp?';

  @override
  String get journalTitle => 'Provningsjournal';

  @override
  String get journalEmpty => 'Inga provningar registrerade ännu';

  @override
  String get journalEmptySub =>
      'Korka upp en flaska från din källare för att påbörja din logg';

  @override
  String journalTastedOn(String date) {
    return 'Provat den $date';
  }

  @override
  String get statsTitle => 'Källarstatistik';

  @override
  String get statsTotalBottles => 'Flaskor i Källaren';

  @override
  String get statsTotalValue => 'Källarvärde';

  @override
  String get statsBottlesEnjoyed => 'Avnjutna Flaskor';

  @override
  String get statsByColor => 'Fördelning per Vintyp';

  @override
  String get statsByMaturity => 'Fördelning per Mognad';

  @override
  String get statsByRegion => 'Toppregioner';

  @override
  String get statsByCountry => 'Toppländer';

  @override
  String get profileTitle => 'Profil och Inställningar';

  @override
  String get profileEmail => 'E-postadress';

  @override
  String get profileDisplayName => 'Visningsnamn';

  @override
  String get profileDefaultCurrency => 'Standardvaluta';

  @override
  String get profileLanguage => 'Appens språk';

  @override
  String get profileLanguageSystem => 'Automatiskt (Systemets språk)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Standardvaluta uppdaterad: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Språket har uppdaterats';

  @override
  String get profileLogout => 'Logga ut';

  @override
  String get profileAbout => 'Om Chatmelier';

  @override
  String get scanTitle => 'Skanna Vinetikett';

  @override
  String get scanTakePhoto => 'Ta foto';

  @override
  String get scanPickGallery => 'Välj från galleri';

  @override
  String get scanAnalyzing => 'Chatmelier AI analyserar etiketten...';

  @override
  String get scanIdentified => 'Vin identifierat av Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Lägg till i min källare';

  @override
  String get loginTitle => 'Logga in';

  @override
  String get loginTagline => 'Din Smarta AI-drivna Vinkällare';

  @override
  String get loginTabMagicLink => '✉️ Inloggningslänk';

  @override
  String get loginTabPassword => '🔑 Lösenord';

  @override
  String get loginEmailLabel => 'E-postadress';

  @override
  String get loginPasswordLabel => 'Lösenord';

  @override
  String get loginSendMagicLink => 'Skicka inloggningslänk';

  @override
  String get loginSignInButton => 'Logga in';

  @override
  String get loginOrDivider => 'ELLER';

  @override
  String get loginGoogleButton => 'Fortsätt med Google';

  @override
  String get loginRegisterLink => 'Har du inget konto? Skapa ett';

  @override
  String get registerTitle => 'Skapa Konto';

  @override
  String get registerNameLabel => 'Visningsnamn';

  @override
  String get registerSubmitButton => 'Skapa mitt konto';

  @override
  String get registerFillAllFields => 'Vänligen fyll i alla fält';

  @override
  String get registerWelcome => '🎉 Välkommen till Chatmelier!';

  @override
  String get registerErrorGeneric => 'Ett fel uppstod vid registreringen';

  @override
  String get authWelcome => 'Välkommen till Chatmelier';

  @override
  String get authSubtitle =>
      'Din personliga smarta vinkällarhanterare och AI-sommelier';

  @override
  String get authGoogle => 'Fortsätt med Google';

  @override
  String get authMagicLink => 'Logga in med e-postlänk';

  @override
  String get authEmail => 'E-postadress';

  @override
  String get authNoAccount => 'Har du inget konto? Skapa ett';

  @override
  String get authHaveAccount => 'Har du redan ett konto? Logga in';

  @override
  String get changelogTitle => 'Versionshistorik och Nyheter';

  @override
  String get changelogEmpty => 'Inga versionsanteckningar tillgängliga.';

  @override
  String get scratchcardTitle => 'Världens Terroir-skrapkarta';

  @override
  String get profileChangelog => 'Versionshistorik & Ändringar';

  @override
  String get profileScratchcard => 'Världens Terroir-skrapkarta';

  @override
  String get navBar => 'Bar';

  @override
  String get navProfile => 'Min profil';

  @override
  String get quickActions => 'SNABBAKTIONER';

  @override
  String get appSubtitle => 'Sommelier & Vinkällare';

  @override
  String get profileTabPalate => 'Gom';

  @override
  String get profileTabSettings => 'Inställningar';

  @override
  String get profileTabTools => 'Verktyg';

  @override
  String get profileTabAccount => 'Konto';

  @override
  String get profileTheme => 'Tema / Utseende';

  @override
  String get profileThemeLight => 'Ljust ☀️';

  @override
  String get profileThemeDark => 'Mörkt 🌙';

  @override
  String get profileThemeSystem => 'System ⚙️';

  @override
  String get profileFriends => 'Vänner & Smakkartor 🍷';

  @override
  String get profileExport => 'Exportera Källare & Värderingsrapport 📊';

  @override
  String get profileDeleteAccount => 'Radera mitt konto permanent';

  @override
  String get profileDeleteConfirmTitle => 'Radera permanent';

  @override
  String get profileDeleteConfirmMsg =>
      'Denna åtgärd kan inte ångras. All din data raderas permanent.';

  @override
  String get badgesGalleryTitle => 'Trofégalleri';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total upplåsta • $pct% slutfört';
  }

  @override
  String get badgesFilterAll => 'Alla';

  @override
  String get badgesEmpty => 'Inga märken hittades i den här kategorin.';

  @override
  String get badgesUnlockedChip => 'Upplåst ✨';

  @override
  String get badgesStatusUnlocked => 'Märke upplåst!';

  @override
  String get badgesStatusInProgress => 'Pågående';

  @override
  String get badgesObjectiveLabel => 'Mål:';

  @override
  String get badgesChatmelierLoreTitle => 'Chatmeliers Vetenskap & Historia';

  @override
  String get badgesCloseButton => 'Stäng';

  @override
  String get badgesTierLabel => 'Nivå';

  @override
  String get badgesShowcaseTitle => 'Troféer & Märken';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked av $total upplåsta';
  }

  @override
  String get badgesShowcaseGallery => 'Galleri';

  @override
  String get cocktailsTitle => 'Bar & Cocktails';

  @override
  String get cocktailsReadyToShake => 'Redo att skakas';

  @override
  String get cocktailsMissingOne => '1 saknas';

  @override
  String get cocktailsManagePantry => 'Hantera Barskafferi';

  @override
  String get cocktailsResetPantry => 'Återställ Barskafferi';

  @override
  String get save => 'Spara';

  @override
  String get continueAnyway => 'Fortsätt ändå';

  @override
  String get cellarDetected => 'Vinkällare identifierad: ';

  @override
  String proximityWifi(String ssid) {
    return 'Ansluten till Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'GPS-position identifierad ($distance)';
  }

  @override
  String get proximitySwitch => 'Växla';

  @override
  String get proximityIgnore => 'Ignorera';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Växlade automatiskt till \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Avlägsen vinkällare identifierad';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Du är ansluten till Wi-Fi \"$ssid\" som är kopplat till din andra källare \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Du befinner dig cirka $distance från \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nVill du ändå lägga till denna flaska i källaren \"$cellar\"?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nVill du ändå plocka ut denna flaska från källaren \"$cellar\"?';
  }

  @override
  String get ratingExceptional => '🏆 Enastående';

  @override
  String get ratingRemarkable => '✨ Anmärkningsvärd';

  @override
  String get ratingVeryGood => '🍷 Mycket god';

  @override
  String get ratingPleasant => '👍 Trevlig';

  @override
  String get ratingPassable => 'Godkänd';

  @override
  String get checkoutWhoTasted => 'Vem provade detta vin med dig?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'flaskor',
      one: 'flaska',
    );
    return '$producer • I lager: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Lägg till gäst';

  @override
  String get checkoutAddGuestHint => 'Lägg till (Mamma, Pappa...)';

  @override
  String get checkoutCloseAndTaste => 'Stäng och njut 🍷';

  @override
  String get checkoutSommelierThinking =>
      'Sommelieren förbereder provningsberättelser...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Luftningstimer aktiv på din låsskärm!';

  @override
  String get checkoutStartAerationTimer => 'Starta timer ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Luftningstimer';

  @override
  String get checkoutDelayedTonight => 'I kväll kl. 22:00';

  @override
  String get checkoutDelayedTonightSub =>
      'Perfekt efter måltiden för att reflektera i lugn och ro';

  @override
  String get checkoutDelayedTomorrow => 'I morgon förmiddag kl. 11:00';

  @override
  String get checkoutDelayedTomorrowSub =>
      'För att skriva ner dina intryck i stillhet';

  @override
  String get checkoutDelayedWeekend => 'I helgen (Lördag kl. 11:00)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Ta god tid på dig under en ledig stund';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'Om 2 timmar ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Snabb påminnelse när provningen avslutats';

  @override
  String get checkoutDelayedCustom => 'Välj datum och tid...';

  @override
  String get reviewPackagingDetected => 'Förpackningsformat identifierat';

  @override
  String get reviewSingleBottleOnly => 'Nej, endast 1 flaska';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Ja, $count flaskor';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Lagret har uppdaterats! ($count flaskor i källaren)';
  }

  @override
  String get reviewVintageYear => 'Årgång / Skördeår';

  @override
  String get reviewNonVintage => 'Hoppa över / Utan årgång (NV)';

  @override
  String get reviewValidate => 'Bekräfta';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name har lagts till i vinkällaren!';
  }

  @override
  String get reviewBottleAnalysis => 'Flaskanalys';

  @override
  String get reviewDiscard => 'Avbryt';

  @override
  String get reviewDiscardConfirmTitle => 'Avbryta registreringen?';

  @override
  String get reviewContinueEditing => 'Fortsätt redigera';

  @override
  String get reviewDiscardWithoutSaving => 'Avsluta utan att spara';

  @override
  String get reviewBottleDetails => 'Flaskdetaljer';

  @override
  String get reviewStockInCellar => 'Lager i källaren';

  @override
  String get reviewStockAddition => 'Lägg till';

  @override
  String get reviewStockNewTotal => 'Nytt totalantal';

  @override
  String get reviewQuantityToAdd => 'Antal att lägga till:';

  @override
  String get reviewSeparateEntry =>
      'Skapa separat post (annan hylla eller inköpspris)';

  @override
  String get reviewRetryAi => 'Försök igen med AI-analys';

  @override
  String get reviewEnlarge => 'Förstora';

  @override
  String get reviewGeneralInfo => 'Allmän information';

  @override
  String get reviewOriginTerroir => 'Ursprung & Terroir';

  @override
  String get reviewQuantityPurchase => 'Antal & Köpinformation';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi identifierat och kopplat: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Kunde inte hitta Wi-Fi (aktivera platstjänster eller ange manuellt)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS-koordinater sparade ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'GPS-position inte tillgänglig. Kontrollera behörigheter.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Vinkällaren \"$cellar\" har skapats!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Fel vid skapande: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 meter (mycket exakt)';

  @override
  String get cellarRadiusRecommended => '300 meter (rekommenderas)';

  @override
  String get cellarRadius500m => '500 meter';

  @override
  String get cellarRadius1km => '1 kilometer';

  @override
  String get cellarRadius3km => '3 kilometer';

  @override
  String get cellarCreateButton => 'Skapa vinkällare';

  @override
  String get cellarUseCurrentGps => 'Ange nuvarande GPS-position';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Källarinställningar för \"$cellar\" har uppdaterats';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Fel vid uppdatering: $error';
  }

  @override
  String get wineTypeRed => 'Rött Vin 🍷';

  @override
  String get wineTypeWhite => 'Vitt Vin 🥂';

  @override
  String get wineTypeRose => 'Rosévin 🌸';

  @override
  String get wineTypeSparkling => 'Mousserande Vin 🍾';

  @override
  String get wineTypeDessert => 'Dessertvin / Sött 🍯';

  @override
  String get wineTypeLiqueur => 'Likör 🍯';

  @override
  String get wineTypeSpirit => 'Spritdrycker 🥃';

  @override
  String get wineTypeGrappa => 'Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Fruktsprit / Eau-de-Vie 🍐';

  @override
  String get wineTypeWhisky => 'Whisky 🥃';

  @override
  String get wineTypeRum => 'Rom 🏴‍☠️';

  @override
  String get wineTypeGin => 'Gin 🍸';

  @override
  String get wineTypeVodka => 'Vodka 🧊';

  @override
  String get wineTypeTequila => 'Tequila 🌵';

  @override
  String get wineTypeCognac => 'Cognac 🍷';

  @override
  String get cellarCreateTitle => 'Skapa en ny vinkällare';

  @override
  String get cellarManageTitle => 'Hantera vinkällare';

  @override
  String get cellarNameLabel => 'Källarnamn *';

  @override
  String get cellarNameHint => 't.ex. Huvudkällaren, Vinkylen i köket';

  @override
  String get cellarNameRequired => 'Vänligen ange ett namn';

  @override
  String get cellarLocationLabel => 'Plats / Stad (valfritt)';

  @override
  String get cellarLocationHint => 't.ex. Stockholm, Beaune';

  @override
  String get cellarNicknameLabel => 'Smeknamn / Rum (valfritt)';

  @override
  String get cellarNicknameHint => 't.ex. Källarvalvet, Vardagsrummet';

  @override
  String get cellarDescriptionLabel => 'Beskrivning (valfritt)';

  @override
  String get cellarDescriptionHint =>
      't.ex. Svalt källarutrymme, 70% luftfuktighet';

  @override
  String get cellarWifiLabel => 'Kopplat Wi-Fi (valfritt)';

  @override
  String get cellarWifiHint => 't.ex. Vinkallare-WiFi';

  @override
  String get cellarLinkCurrentWifi => 'Koppla till nuvarande Wi-Fi';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Hämta nuvarande Wi-Fi';

  @override
  String get cellarRadiusLabel => 'GPS-radie';

  @override
  String get cellarAutoDetectionHeader => 'Automatisk identifiering & växling';

  @override
  String get cellarAutoDetectionDesc =>
      'Koppla ditt Wi-Fi eller dina GPS-koordinater för att automatiskt växla till denna källare när du är på plats.';

  @override
  String get cellarLatitudeLabel => 'Latitud';

  @override
  String get cellarLongitudeLabel => 'Longitud';

  @override
  String get checkoutGuidedTasting => 'Guidad provning';

  @override
  String get checkoutGuidedTastingShared =>
      'Dela intryck i tur och ordning eller tillsammans';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analysera utseende, doft och smak och förfina din profil';

  @override
  String get checkoutUncorkNowRateLater => 'Korka upp nu, betygsätt senare';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Direkt uttag • Välj tid för påminnelse (i kväll, i morgon...)';

  @override
  String get checkoutUncorkAeration => 'Korka upp & Luftningstimer';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Direkt uttag • $minutes min luftning rekommenderas';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Direkt uttag • Dekanterings- & luftningstimer';

  @override
  String get checkoutSommelierServiceAdvice => 'Serveringsråd från sommelieren';

  @override
  String get checkoutHistoryAnecdotes => 'Berättelser & Anekdoter';

  @override
  String get checkoutNoDecanting => 'Ingen dekantering krävs';

  @override
  String get checkoutStoryTitle => 'Berättelsen om denna flaska 📖';

  @override
  String get checkoutStorySubtitle =>
      'Fängslande historier att dela vid bordet';

  @override
  String get checkoutStoryTerroir => 'Terroir & Druvsorter';

  @override
  String get checkoutStoryVintage => 'Årgångens historia';

  @override
  String get checkoutStoryTastingSecret => 'Provningshemlighet';

  @override
  String get checkoutStoryTableAnecdote => 'Bordsanekdot';

  @override
  String get checkoutJournalArchivedNotice =>
      'Oroa dig inte: denna flaska arkiveras i din provningsdagbok med foton och anteckningar.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Flaskan är uppkorkad! Luftningstimer ($minutes min) aktiv på låsskärmen.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'Flaskan plockas ut direkt. Bekräfta önskad luftningstid:';

  @override
  String get checkoutRateWine => 'Betygsätt vinet';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Starta ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Sommelier-tips: lufta i $minutes min. Timer på låsskärmen redo.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Påminnelse schemalagd efter provningen för att spara dina intryck.';

  @override
  String get checkoutBottleRemovedSuccess =>
      'Flaskan har plockats ut ur källaren!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Trevlig provning. Påminnelse schemalagd till $date.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'Varje deltagares smakprofil kommer att berikas automatiskt.';

  @override
  String checkoutCellarOf(String name) {
    return 'Vinkällare tillhörande $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Lager: $count fl.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Lägg till en familjemedlem eller vän som deltar i provningen (t.ex. Mamma, Pappa, Erik...).';

  @override
  String get checkoutAddGuestNameLabel => 'Förnamn / Namn';

  @override
  String get checkoutDelayedSheetTitle => 'Korka upp och betygsätt senare';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'När vill du få en påminnelse för att anteckna dina intryck?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'I kväll om 2 timmar ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'I kväll kl. 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'i kväll kl. $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'i morgon kl. $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'den $date kl. $time';
  }

  @override
  String get add => 'Lägg till';

  @override
  String get cellarWinesTab => '🍷 Viner';

  @override
  String get cellarSpiritsTab => '🥃 Spritdrycker';

  @override
  String get cellarPairWithDish => 'Vilket vin till min maträtt?';

  @override
  String get cellarCollapseAll => 'Fäll ihop alla';

  @override
  String get cellarExpandAll => 'Fäll ut alla';

  @override
  String get cellarSort => 'Sortera';

  @override
  String get cellarCategories => 'Kategorier';

  @override
  String get cellarFavorites => 'Favoriter';

  @override
  String get cellarGridView => 'Rutnät';

  @override
  String get cellarListView => 'Lista';

  @override
  String get cellarClearFilters => 'Rensa filter';

  @override
  String get cellarNoBottlesCategory => 'Inga flaskor i denna kategori';

  @override
  String get cellarNoBottlesCriteria => 'Inga flaskor matchar dessa kriterier';

  @override
  String get feedbackSheetTitle => 'Tester-feedback och anteckning';

  @override
  String get feedbackStylus => 'Penna:';

  @override
  String get feedbackUndo => 'Ångra senaste streck';

  @override
  String get feedbackClear => 'Rensa allt';

  @override
  String get feedbackHint =>
      'Ringa in området och beskriv feedback eller fel...';

  @override
  String get feedbackSubmit => 'Skicka rapport';

  @override
  String get feedbackSubmitting => 'Skickar...';

  @override
  String get feedbackNoScreenshot => 'Ingen skärmdump tillgänglig';

  @override
  String get feedbackEmptyError =>
      'Lägg till en kommentar eller rita på skärmdumpen.';

  @override
  String get feedbackSuccess =>
      'Tack för din feedback! 🍷 Rapporten har skickats.';

  @override
  String feedbackError(String error) {
    return 'Fel vid skickande: $error';
  }

  @override
  String get checkoutFastExit => 'Snabb-uttag utan frågeformulär ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Uttag pågår...';

  @override
  String get checkoutRatingSubtitle => 'Ge ditt helhetsbetyg efter provningen';

  @override
  String get checkoutRecommendedBadge => 'Rekommenderas';

  @override
  String get tastingWhoTastedTitle => '👥 Vem provade detta vin?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Välj provarna. Smakprofilerna kommer att berikas automatiskt.';

  @override
  String get tastingHowToTaste => 'Hur vill du prova?';

  @override
  String get tastingEachTurn => 'I tur och ordning';

  @override
  String get tastingEachTurnDesc =>
      '📱 Skicka runt telefonen: var och en svarar separat i sin egen takt.';

  @override
  String get tastingTogether => 'Tillsammans';

  @override
  String get tastingTogetherDesc =>
      '🥂 Ett gemensamt formulär fylls i tillsammans vid bordet.';

  @override
  String get tastingBlindMode => 'Blindprovningsläge';

  @override
  String get tastingBlindModeDesc =>
      'Döljer vinets namn och startar ett roligt bordsquiz med festlig avtäckning!';

  @override
  String get tastingPrimaryProfile => 'Huvudprofil';

  @override
  String get tastingAppInstalled => 'App installerad 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count formulär ifyllda',
      one: '1 formulär ifyllt',
      zero: '0 formulär ifyllda',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 Doften — Aromuttryck';

  @override
  String get tastingStepNezSubtitle =>
      'Snurra glaset och fånga de aromlager som frigörs.';

  @override
  String get tastingAromaIntensity => 'Aromintensitet:';

  @override
  String get tastingAromaDiscreet => '🤫 Subtil / Diskret';

  @override
  String get tastingAromaExplosive => '💥 Explosiv / Kraftfull';

  @override
  String get tastingStepBoucheTitle => '⚖️ Smaken — Balans & Struktur';

  @override
  String get tastingStepBoucheSubtitle =>
      'Beskriv texturen, syran och balansen i munnen.';

  @override
  String get tastingAcidity => 'Syra:';

  @override
  String get tastingAcidityFreshness => 'Syra & Friskhet:';

  @override
  String get tastingAcidityFlat => '🫠 Flack / Låg syra';

  @override
  String get tastingAciditySharp => '⚡ Krispig / Spänstig';

  @override
  String get tastingTannins => 'Tanniner (Strävhet):';

  @override
  String get tastingTanninsSilky => '🧶 Silkeslena / Mjuka';

  @override
  String get tastingTanninsGrippy => '💪 Fasta / Strukturerade';

  @override
  String get tastingMinerality => 'Mineralitet & Skärpa:';

  @override
  String get tastingMineralityRound => '🧈 Rund / Smörig';

  @override
  String get tastingMineralityCrisp => '🪨 Mineralisk / Ren';

  @override
  String get tastingEffervescence => 'Mousse (Bubblor):';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fin / Delikat';

  @override
  String get tastingEffervescenceVibrant => '🎆 Livlig / Krämig';

  @override
  String get tastingBody => 'Kropp / Fyllighet:';

  @override
  String get tastingBodyLight => '🍃 Lätt / Elegant';

  @override
  String get tastingBodyFull => '🏋️ Fyllig / Kraftfull';

  @override
  String get tastingLength => 'Eftersmak / Längd:';

  @override
  String get tastingLengthShort => '⏱️ Kort';

  @override
  String get tastingLengthLong => '♾️ Mycket lång eftersmak';

  @override
  String get tastingStepVerdictTitle => '✅ Slutligt omdöme';

  @override
  String get tastingBuyAgain => 'Skulle du köpa denna flaska igen?';

  @override
  String get tastingBuyAgainYes => '🤩 Absolut!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Kanske';

  @override
  String get tastingBuyAgainNo => '👎 Nej tack';

  @override
  String get tastingIdealMoment => 'Passande tillfälle för detta vin?';

  @override
  String get tastingMomentApero => '🥂 Till fördrink / Aperitif';

  @override
  String get tastingMomentMeal => '🍽️ Vardagsmiddag';

  @override
  String get tastingMomentDinner => '🎩 Festmåltid';

  @override
  String get tastingMomentRomantic => '🕯️ Romantisk middag';

  @override
  String get tastingMomentSolo => '🧘 Egen stund i lugn och ro';

  @override
  String get tastingWhatLiked => 'Vad du gillade mest:';

  @override
  String get tastingWhatDisliked => 'Vad du gillade minst:';

  @override
  String get tastingOccasionLabel => 'Tillfälle / Minne (valfritt) ✨';

  @override
  String get tastingOccasionHint =>
      't.ex. Födelsedag, Middag med levande ljus, Återträff...';

  @override
  String get tastingAddPhoto => 'Lägg till ett bordsfoto 📸';

  @override
  String get tastingPhotoSaved => 'Foto sparat 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Slutbetyg & Helhetsintryck';

  @override
  String get tastingStepImpressionSubtitle =>
      'Sätt ditt helhetsbetyg efter att ha upplevt doft och smak.';

  @override
  String get tastingOverallFeeling => 'Ditt allmänna intryck:';

  @override
  String get tastingScoreOutOf10 => 'Betyg från 1 till 10:';

  @override
  String get tastingCompletedTitle => 'Provningen är slutförd & sparad!';

  @override
  String get tastingCompletedSubtitle =>
      'Smakprofilerna har uppdaterats framgångsrikt ✨';

  @override
  String get tastingBottleRemoved =>
      'Flaskan har öppnats och plockats ut ur källaren';

  @override
  String get tastingConsultDebrief =>
      'Se sommelierens genomgång (Dolda nyanser & Terroir)';

  @override
  String get tastingFinishButton => 'Avsluta ✨';

  @override
  String get tastingNextTaster => 'Bekräfta → Nästa provare';

  @override
  String get tastingConfirmAndFinish => 'Bekräfta & Avsluta ✨';

  @override
  String get tastingQuitTitle => 'Avbryta frågeformuläret?';

  @override
  String get tastingQuitMessage => 'Dina svar kommer inte att sparas.';

  @override
  String get tastingContinue => 'Fortsätt';

  @override
  String get tastingQuit => 'Avsluta';

  @override
  String tastingStartCount(int count) {
    return 'Starta ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Synkroniserat med ${name}s app ✨';
  }

  @override
  String get tastingProfileEnriched => 'Smakprofil berikad';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Sensorisk träffsäkerhet: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle =>
      'Smakernas ursprung & Vinets hemligheter';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Upptäck varifrån aromer, färg och struktur härstammar';

  @override
  String get tastingBlindQuizTitle => 'Blindprovnings-quiz vid bordet 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. Vilken är vinets ursprungsregion? 🌍';

  @override
  String get tastingBlindQuizQ2 =>
      '2. Vilken är den huvudsakliga druvsorten? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Uppskattad årgång / ålder? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Uppskattat prisintervall? 💶';

  @override
  String get tastingBlindRevealTitle =>
      'Stor avtäckning av den mystiska flaskan 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Quiz-resultat: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Oenologisk och molekylär genomgång';

  @override
  String get tastingSensoryAcuity => 'SENSORISK TRÄFFSÄKERHET';

  @override
  String tastingPrecision(int score) {
    return 'Precision $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. ÖVERENSSTÄMMELSE & CRU-KARAKTÄR';

  @override
  String get tastingWhatYouDetected => 'VAD DU UPPTÄCKTE:';

  @override
  String get tastingArchetypeSignature => 'VINETS TYPISKA SIGNATUR:';

  @override
  String get tastingHiddenNuancesTitle =>
      'SUBTILA NYANSER ATT SÖKA EFTER I NÄSTA GLAS:';

  @override
  String get tastingPillarsTitle => '2. OENOLOGISK VETENSKAP & MOLEKYLER';

  @override
  String get tastingPillarsSubtitle =>
      'Varför har detta vin just denna struktur, dessa aromer och denna färg?';

  @override
  String get tastingChatWithSommelier =>
      'Fördjupa dig i vinmakningens hemligheter med Chatmelier';

  @override
  String get aromaFruitsRouges => 'Röda bär (jordgubb, körsbär)';

  @override
  String get aromaFruitsNoirs => 'Mörka bär (björnbär, svarta vinbär)';

  @override
  String get aromaFruitsBlancs => 'Ljus frukt (persika, päron, äpple)';

  @override
  String get aromaAgrumes => 'Citrusfrukter (citron, grapefrukt)';

  @override
  String get aromaFloral => 'Blommigt (viol, ros)';

  @override
  String get aromaVegetal => 'Örter och grönska (paprika, undervegetation)';

  @override
  String get aromaEpicesDouces => 'Söta kryddor (kanel, muskot)';

  @override
  String get aromaEpicesVives => 'Pikanta kryddor (svartpeppar)';

  @override
  String get aromaBoise => 'Fatkaraktär & Vanilj (ek)';

  @override
  String get aromaBeurre => 'Smör & Brioche';

  @override
  String get aromaMineral => 'Mineralitet (flinta, kalk)';

  @override
  String get aromaMiel => 'Honung & Sylt';

  @override
  String get aromaChocolat => 'Mörk choklad & Kaffe';

  @override
  String get aromaFumee => 'Rökigt & Rostat';

  @override
  String get emojiDisliked => 'Inte min smak';

  @override
  String get emojiMeh => 'Sådär';

  @override
  String get emojiDecent => 'Helt okej';

  @override
  String get emojiVeryGood => 'Mycket gott';

  @override
  String get emojiLoved => 'Fantastiskt!';

  @override
  String get likedFreshness => 'Friskheten';

  @override
  String get likedFruitiness => 'Fruktigheten';

  @override
  String get likedComplexity => 'Komplexiteten';

  @override
  String get likedElegance => 'Elegansen';

  @override
  String get likedPower => 'Fylligheten och kraften';

  @override
  String get likedSilky => 'Den silkeslena texturen';

  @override
  String get likedOriginality => 'Karaktären och särarten';

  @override
  String get likedFoodPairing => 'Maten och vinets samspel';

  @override
  String get likedMinerality => 'Mineraliteten';

  @override
  String get likedLength => 'Den långa eftersmaken';

  @override
  String get likedDisappointing => 'Inget / En besvikelse 😕';

  @override
  String get dislikedTooAcidic => 'För hög syra';

  @override
  String get dislikedTooTannic => 'För strävt / kartiga tanniner';

  @override
  String get dislikedTooOaked => 'För mycket ekfat / vanilj';

  @override
  String get dislikedTooAlcoholic => 'För eldigt / alkoholvarmt';

  @override
  String get dislikedTooThin => 'För tunt / vattnigt';

  @override
  String get dislikedLacksFruit => 'För lite frukt';

  @override
  String get dislikedTooSweet => 'För sött';

  @override
  String get dislikedTooExpensive => 'För dyrt i förhållande till kvalitet';

  @override
  String get dislikedNothing => 'Inget, vinet var alldeles förträffligt!';

  @override
  String get tastingStepTasters => 'Provare';

  @override
  String get tastingStepNezNav => 'Doft';

  @override
  String get tastingStepBoucheNav => 'Smak';

  @override
  String get tastingStepVerdictNav => 'Omdöme';

  @override
  String get tastingStepRatingNav => 'Betyg';

  @override
  String get tastingBack => 'Tillbaka';

  @override
  String get tastingNext => 'Nästa';

  @override
  String get tastingSaving => 'Sparar...';

  @override
  String get tastingHeaderTitle => 'Provningsformulär';

  @override
  String tastingAnswersOf(String name) {
    return 'Svar från $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Ge telefonen vidare till $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Dina svar har sparats.\nNu är det ${name}s tur.';
  }

  @override
  String get tastingDictateButton => 'Diktera intryck från bordet 🎙️';

  @override
  String get tastingDictateHint =>
      'Tala eller skriv fritt: Chatmelier AI fyller automatiskt i aromer och smakbalans!';

  @override
  String get tastingDictateMicTip =>
      'Tips: tryck på mikrofonen på ditt tangentbord för att diktera!';

  @override
  String get tastingTakePhoto => 'Ta ett foto vid bordet 📸';

  @override
  String get tastingChooseGallery => 'Välj från galleriet 🖼️';

  @override
  String get tastingConclaveSummary => 'Sammanfattning av provningen';

  @override
  String get tastingCellarMaster => 'Källarmästare';

  @override
  String get tastingGuestTaster => 'Gästprovare';

  @override
  String tastingProfileTag(String type) {
    return 'Profil: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Fri provningsanteckning sparad.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Utseende/Färg: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Struktur: $structure ($caudalies caudalier)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Nyckelmolekyler: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Avgörande faktor: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Druvsorter: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Provningsintryck applicerade av Chatmelier AI ✨';

  @override
  String get tastingBlindYourPredictions =>
      'Sammanfattning av blindgissningarna:';

  @override
  String get tastingBlindGuessCorrect => 'Helt rätt! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Gör era gissningar innan etiketten avtäcks!';

  @override
  String tastingStartTaster(String name) {
    return 'Nu kör vi, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Strålande!';

  @override
  String tastingQuizWas(String answer) {
    return '(Rätt svar var: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      't.ex.: Johan älskade vinet och gav 8.5/10, kände toner av björnbär och skog. Anna gav 7/10 och tyckte syran stack ut lite...';

  @override
  String get tastingDictateAnalyzing => 'Analyserar...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Analysera och för in i formuläret ✨';

  @override
  String get tastingFormatExpress => 'Snabbformat (1 sida) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Betyg, nyckelaromer och snabbt omdöme på 30 sek.';

  @override
  String get tastingFormatSommelier => 'Sommelierformat (Detaljerat) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Djupgående analys av doft, smakbalans, eftersmak och terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'Vad är en caudalie? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalie = 1 sekunds kvarhängande smak efter att vinet svalts eller spottats ut.\n• 1 till 4 caudalier: lätt och friskt vin\n• 5 till 7 caudalier: mycket fin balans\n• 8 till 12+ caudalier: enastående toppvin!';

  @override
  String get tastingAddCustomAroma => '+ Egen arom';

  @override
  String get tastingCustomAromaDialogTitle => 'Lägg till en specifik arom';

  @override
  String get tastingCustomAromaHint =>
      't.ex. Rökt flinta, Vildhallon, Torkad ros...';

  @override
  String get tastingFoodSynergyTitle => 'Kombination med mat 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Sublim';

  @override
  String get tastingSynergyHarmonious => '👍 Mycket harmonisk';

  @override
  String get tastingSynergyNeutral => '😐 Varken eller / Neutral';

  @override
  String get tastingSynergyClashing => '⚡ Skärande';

  @override
  String get checkoutFastRatingTitle => 'Snabbetyg med 1 tryck (valfritt):';

  @override
  String get checkoutActionTastingTitle => 'Prova detta vin';

  @override
  String get checkoutActionTastingSubtitle =>
      'Snabbformat (1 sida) eller detaljerat sommelierformat';

  @override
  String get checkoutActionDeferredRemind => 'Påminn mig senare 🌙';

  @override
  String get checkoutActionAerationTimer => 'Luftningstimer ⏱️';
}
