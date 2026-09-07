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
  String get navProfile => 'Profil';

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
}
