// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'Mijn Kelder';

  @override
  String get navCellar => 'Kelder';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'Geschied.';

  @override
  String get navStats => 'Statist.';

  @override
  String get actionMenuTitle => 'Kelderacties';

  @override
  String get actionAddBottle => 'Fles toevoegen';

  @override
  String get actionAddBottleSub => 'Etiket scannen of handmatig invoeren';

  @override
  String get actionCheckoutBottle => 'Fles ontkurken / Proeven';

  @override
  String get actionCheckoutBottleSub =>
      'Proefnotitie vastleggen en uit voorraad halen';

  @override
  String get actionLookupWine => 'Wijn raadplegen / Identificeren';

  @override
  String get actionLookupWineSub => 'Directe AI-wijndetectie en advies';

  @override
  String get searchWinePlaceholder => 'Zoek jaargang, wijnhuis, herkomst...';

  @override
  String get emptyCellarTitle => 'Je wijnkelder is leeg';

  @override
  String get emptyCellarSub =>
      'Scan je eerste fles om je digitale collectie te starten';

  @override
  String get emptyCellarButton => 'Mijn eerste fles toevoegen';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count flessen',
      one: '1 fles',
      zero: '0 flessen',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Totale waarde';

  @override
  String get filterAll => 'Alles';

  @override
  String get filterRed => 'Rood';

  @override
  String get filterWhite => 'Wit';

  @override
  String get filterRose => 'Rosé';

  @override
  String get filterSparkling => 'Mousserend';

  @override
  String get filterSheetTitle => 'Kelderfilters';

  @override
  String get filterReset => 'Herstellen';

  @override
  String get filterApply => 'Filters toepassen';

  @override
  String get filterMaturity => 'Rijpingsstatus / Dronk';

  @override
  String get maturityAtPeak => 'Op dronk';

  @override
  String get maturityDrinkSoon => 'Snel drinken';

  @override
  String get maturityAging => 'Opleggen';

  @override
  String get maturityTooYoung => 'Te jong';

  @override
  String get maturityPastPeak => 'Over het hoogtepunt';

  @override
  String get filterContinents => 'Continenten';

  @override
  String get filterCountries => 'Landen';

  @override
  String get filterGrapes => 'Druivenrassen';

  @override
  String get filterAppellations => 'Regio\'s en Appellaties';

  @override
  String get bottleDetailInfo => 'Informatie en Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Drinkvenster';

  @override
  String get bottleDetailTerroirMap => 'Terroir- en Oorsprongskaart';

  @override
  String get bottleDetailLabelPhoto => 'Originele etiketfoto';

  @override
  String get bottleDetailVintage => 'Jaargang';

  @override
  String get bottleDetailProducer => 'Producent / Wijnhuis';

  @override
  String get bottleDetailRegion => 'Regio';

  @override
  String get bottleDetailCountry => 'Land';

  @override
  String get bottleDetailAppellation => 'Appellatie';

  @override
  String get bottleDetailGrapes => 'Druivenrassen';

  @override
  String get bottleDetailAlcohol => 'Alcoholpercentage';

  @override
  String get bottleDetailStock => 'Voorraad';

  @override
  String get bottleDetailLocation => 'Kelderlocatie';

  @override
  String get bottleDetailRack => 'Rek';

  @override
  String get bottleDetailShelf => 'Plank';

  @override
  String get bottleDetailPurchasePrice => 'Aankoopprijs';

  @override
  String get bottleDetailEstimatedValue => 'Geschatte waarde';

  @override
  String get bottleDetailFoodPairings => 'Aanbevolen wijn-spijscombinaties';

  @override
  String get bottleDetailTastingNotes => 'Sommelierprofiel';

  @override
  String get bottleDetailDrinkButton => 'Deze fles ontkurken';

  @override
  String get bottleDetailEdit => 'Bewerken';

  @override
  String get bottleDetailDelete => 'Verwijderen';

  @override
  String get bottleDetailDeleteConfirm =>
      'Weet je zeker dat je deze fles definitief uit je kelder wilt verwijderen?';

  @override
  String get deleteBottleTitle => 'Definitief Verwijderen';

  @override
  String get deleteBottleExplanation =>
      'Let op: verwijderen wist alle gegevens van deze fles permanent uit je kelder en historiek.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Ontkurken / Drinken: archiveert de fles in je proefgeschiedenis, werkt statistieken bij en bewaart notities.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Definitief verwijderen: wist het record volledig zonder sporen na te laten (aanbevolen bij typefouten, breuk of dubbels).';

  @override
  String get deleteBottleActionConfirm => 'Definitief Verwijderen';

  @override
  String get deleteBottleActionDrinkInstead => 'Toch ontkurken / drinken';

  @override
  String get cancel => 'Annuleren';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get checkoutTitle => 'Proeven en Ontkurken uit Kelder';

  @override
  String get checkoutSelectPrompt =>
      'Tik om een fles uit je kelder te kiezen...';

  @override
  String get checkoutQtyOpened => 'Aantal geopende flessen';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'van $total in kelder';
  }

  @override
  String get checkoutRating => 'Proefbeoordeling';

  @override
  String get checkoutFoodPairing => 'Bijpassende gerechten (optioneel)';

  @override
  String get checkoutFoodHint =>
      'bijv. Gegrilde entrecote, paddenstoelenrisotto...';

  @override
  String get checkoutNotes => 'Proefnotities en Indrukken';

  @override
  String get checkoutNotesHint => 'Aroma\'s, balans, afdronk, beleving...';

  @override
  String get checkoutSubmit => 'Proeverij bevestigen';

  @override
  String get checkoutSuccess => 'Proeverij succesvol vastgelegd!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Hallo! Ik ben Chatmelier. Vraag me om wijn-spijssuggesties, drinkadvies of keldertips op basis van je huidige voorraad.';

  @override
  String get chatAnalyzing => 'Chatmelier analyseert je kelder...';

  @override
  String get chatInputHint => 'Vraag het aan Chatmelier...';

  @override
  String get chatChipTonight => '🍷 Wat zal ik vanavond drinken?';

  @override
  String get chatChipSteak => '🥩 Wijnadvies bij een malse biefstuk';

  @override
  String get chatChipSeafood => '🐟 Beste witte wijn bij zeevruchten';

  @override
  String get chatChipPeak => '⏰ Welke flessen zijn nu perfect op dronk?';

  @override
  String get journalTitle => 'Proefdagboek';

  @override
  String get journalEmpty => 'Nog geen proefnotities vastgelegd';

  @override
  String get journalEmptySub =>
      'Ontkurk een fles uit je kelder om je logboek te starten';

  @override
  String journalTastedOn(String date) {
    return 'Geproefd op $date';
  }

  @override
  String get statsTitle => 'Kelderstatistieken';

  @override
  String get statsTotalBottles => 'Flessen in Kelder';

  @override
  String get statsTotalValue => 'Kelderwaarde';

  @override
  String get statsBottlesEnjoyed => 'Gedronken Flessen';

  @override
  String get statsByColor => 'Verdeling naar Kleur';

  @override
  String get statsByMaturity => 'Verdeling naar Dronk';

  @override
  String get statsByRegion => 'Belangrijkste Regio\'s';

  @override
  String get statsByCountry => 'Belangrijkste Landen';

  @override
  String get profileTitle => 'Profiel en Instellingen';

  @override
  String get profileEmail => 'E-mailadres';

  @override
  String get profileDisplayName => 'Weergavenaam';

  @override
  String get profileDefaultCurrency => 'Standaardvaluta';

  @override
  String get profileLanguage => 'Taal van de app';

  @override
  String get profileLanguageSystem => 'Automatisch (Systeem)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Standaardvaluta bijgewerkt: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Taal bijgewerkt';

  @override
  String get profileLogout => 'Uitloggen';

  @override
  String get profileAbout => 'Over Chatmelier';

  @override
  String get scanTitle => 'Wijnetiket Scannen';

  @override
  String get scanTakePhoto => 'Foto maken';

  @override
  String get scanPickGallery => 'Kiezen uit galerij';

  @override
  String get scanAnalyzing => 'Chatmelier AI analyseert het etiket...';

  @override
  String get scanIdentified => 'Wijn herkend door Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Toevoegen aan mijn kelder';

  @override
  String get loginTitle => 'Inloggen';

  @override
  String get loginTagline => 'Je Slimme Gedeelde Wijnkelder met AI';

  @override
  String get loginTabMagicLink => '✉️ Inloglink';

  @override
  String get loginTabPassword => '🔑 Wachtwoord';

  @override
  String get loginEmailLabel => 'E-mailadres';

  @override
  String get loginPasswordLabel => 'Wachtwoord';

  @override
  String get loginSendMagicLink => 'Inloglink versturen';

  @override
  String get loginSignInButton => 'Inloggen';

  @override
  String get loginOrDivider => 'OF';

  @override
  String get loginGoogleButton => 'Doorgaan met Google';

  @override
  String get loginRegisterLink => 'Nog geen account? Maak er een aan';

  @override
  String get registerTitle => 'Account Aanmaken';

  @override
  String get registerNameLabel => 'Weergavenaam';

  @override
  String get registerSubmitButton => 'Mijn account aanmaken';

  @override
  String get registerFillAllFields => 'Vul alle velden in';

  @override
  String get registerWelcome => '🎉 Welkom bij Chatmelier!';

  @override
  String get registerErrorGeneric => 'Fout bij registreren';

  @override
  String get authWelcome => 'Welkom bij Chatmelier';

  @override
  String get authSubtitle => 'Je slimme wijnkelderbeheerder en AI-sommelier';

  @override
  String get authGoogle => 'Doorgaan met Google';

  @override
  String get authMagicLink => 'Inloggen via e-maillink';

  @override
  String get authEmail => 'E-mailadres';

  @override
  String get authNoAccount => 'Nog geen account? Registreer je';

  @override
  String get authHaveAccount => 'Heb je al een account? Log in';

  @override
  String get changelogTitle => 'Versiegeschiedenis en Notities';

  @override
  String get changelogEmpty => 'Geen versienotities beschikbaar.';

  @override
  String get scratchcardTitle => 'Terroir Kraskaart van de Wereld';

  @override
  String get profileChangelog => 'Versiegeschiedenis & Wijzigingen';

  @override
  String get profileScratchcard => 'Terroir Kraskaart van de Wereld';

  @override
  String get navBar => 'Bar';

  @override
  String get navProfile => 'Profiel';

  @override
  String get quickActions => 'SNELLE ACTIES';

  @override
  String get appSubtitle => 'Sommelier & Wijnkelder';

  @override
  String get profileTabPalate => 'Smaak';

  @override
  String get profileTabSettings => 'Instellingen';

  @override
  String get profileTabTools => 'Gereedschappen';

  @override
  String get profileTabAccount => 'Account';

  @override
  String get profileTheme => 'Thema / Uitstraling';

  @override
  String get profileThemeLight => 'Licht ☀️';

  @override
  String get profileThemeDark => 'Donker 🌙';

  @override
  String get profileThemeSystem => 'Systeem ⚙️';

  @override
  String get profileFriends => 'Vrienden & Smaakkaart 🍷';

  @override
  String get profileExport => 'Kelder & Taxatierapport exporteren 📊';

  @override
  String get profileDeleteAccount => 'Mijn account definitief verwijderen';

  @override
  String get profileDeleteConfirmTitle => 'Definitief verwijderen';

  @override
  String get profileDeleteConfirmMsg =>
      'Deze actie is onomkeerbaar. Al uw gegevens worden verwijderd.';

  @override
  String get badgesGalleryTitle => 'Trofeeëngalerij';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total ontgrendeld • $pct% voltooid';
  }

  @override
  String get badgesFilterAll => 'Alle';

  @override
  String get badgesEmpty => 'Geen medailles gevonden in deze categorie.';

  @override
  String get badgesUnlockedChip => 'Ontgrendeld ✨';

  @override
  String get badgesStatusUnlocked => 'Medaille ontgrendeld!';

  @override
  String get badgesStatusInProgress => 'In uitvoering';

  @override
  String get badgesObjectiveLabel => 'Doel:';

  @override
  String get badgesChatmelierLoreTitle =>
      'Wetenschap & Verhalen van Chatmelier';

  @override
  String get badgesCloseButton => 'Sluiten';

  @override
  String get badgesTierLabel => 'Rangorde';

  @override
  String get badgesShowcaseTitle => 'Trofeeën & Medailles';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked van $total ontgrendeld';
  }

  @override
  String get badgesShowcaseGallery => 'Galerij';

  @override
  String get cocktailsTitle => 'Bar & Cocktails';

  @override
  String get cocktailsReadyToShake => 'Klaar om te shaken';

  @override
  String get cocktailsMissingOne => '1 ontbrekend';

  @override
  String get cocktailsManagePantry => 'Voorraad beheren';

  @override
  String get cocktailsResetPantry => 'Voorraad resetten';

  @override
  String get save => 'Opslaan';

  @override
  String get continueAnyway => 'Toch doorgaan';

  @override
  String get cellarDetected => 'Wijnkelder gedetecteerd: ';

  @override
  String proximityWifi(String ssid) {
    return 'Verbonden met wifi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'GPS-locatie gedetecteerd op $distance';
  }

  @override
  String get proximitySwitch => 'Overschakelen';

  @override
  String get proximityIgnore => 'Negeren';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Automatisch overgeschakeld naar \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Afgelegen kelder gedetecteerd';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'U bent momenteel verbonden met wifi \"$ssid\", gekoppeld aan uw andere kelder \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'U bevindt zich momenteel op ongeveer $distance van \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nWilt u deze fles toch toevoegen aan kelder \"$cellar\"?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nWilt u deze fles toch uitboeken uit kelder \"$cellar\"?';
  }

  @override
  String get ratingExceptional => '🏆 Uitzonderlijk';

  @override
  String get ratingRemarkable => '✨ Opmerkelijk';

  @override
  String get ratingVeryGood => '🍷 Zeer goed';

  @override
  String get ratingPleasant => '👍 Aangenaam';

  @override
  String get ratingPassable => 'Redelijk';

  @override
  String get checkoutWhoTasted => 'Wie heeft deze wijn met u geproefd?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'flessen',
      one: 'fles',
    );
    return '$producer • In voorraad: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Gast toevoegen';

  @override
  String get checkoutAddGuestHint => 'Naam toevoegen (Moeder, Vader...)';

  @override
  String get checkoutCloseAndTaste => 'Sluiten & Genieten 🍷';

  @override
  String get checkoutSommelierThinking =>
      'De sommelier bereidt proefnotities voor...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Beluchtingstimer actief op uw vergrendelingsscherm!';

  @override
  String get checkoutStartAerationTimer => 'Timer starten ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Beluchtingstimer';

  @override
  String get checkoutDelayedTonight => 'Vanavond om 22:00 uur';

  @override
  String get checkoutDelayedTonightSub =>
      'Ideaal na de maaltijd om de indrukken te verdiepen';

  @override
  String get checkoutDelayedTomorrow => 'Morgenochtend om 11:00 uur';

  @override
  String get checkoutDelayedTomorrowSub =>
      'Om in alle rust uw proefnotities vast te leggen';

  @override
  String get checkoutDelayedWeekend => 'Dit weekend (Zaterdag 11:00 uur)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Neem de tijd op een ontspannen moment';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'Over 2 uur ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Snelle herinnering na afloop van de proeverij';

  @override
  String get checkoutDelayedCustom => 'Kies datum & tijd...';

  @override
  String get reviewPackagingDetected => 'Verpakkingsformaat gedetecteerd';

  @override
  String get reviewSingleBottleOnly => 'Nee, slechts 1 fles';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Ja, $count flessen';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Voorraad succesvol bijgewerkt! ($count flessen in kelder)';
  }

  @override
  String get reviewVintageYear => 'Jaargang / Oogstjaar';

  @override
  String get reviewNonVintage => 'Overslaan / Zonder jaargang (NV)';

  @override
  String get reviewValidate => 'Bevestigen';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name succesvol toegevoegd aan de wijnkelder!';
  }

  @override
  String get reviewBottleAnalysis => 'Flesanalyse';

  @override
  String get reviewDiscard => 'Verwerpen';

  @override
  String get reviewDiscardConfirmTitle => 'Invoer verwerpen?';

  @override
  String get reviewContinueEditing => 'Verder bewerken';

  @override
  String get reviewDiscardWithoutSaving => 'Afsluiten zonder opslaan';

  @override
  String get reviewBottleDetails => 'Flesdetails';

  @override
  String get reviewStockInCellar => 'Keldervoorraad';

  @override
  String get reviewStockAddition => 'Toevoegen';

  @override
  String get reviewStockNewTotal => 'Nieuw totaal';

  @override
  String get reviewQuantityToAdd => 'Toe te voegen aantal:';

  @override
  String get reviewSeparateEntry =>
      'Aparte invoer maken (ander rek of aankoopprijs)';

  @override
  String get reviewRetryAi => 'AI-analyse opnieuw proberen';

  @override
  String get reviewEnlarge => 'Vergroten';

  @override
  String get reviewGeneralInfo => 'Algemene informatie';

  @override
  String get reviewOriginTerroir => 'Herkomst & Terroir';

  @override
  String get reviewQuantityPurchase => 'Aantal & Aankoopgegevens';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wifi gedetecteerd & gekoppeld: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Wifi kon niet worden gedetecteerd (schakel locatie in of voer handmatig in)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS-coördinaten vastgelegd ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'GPS-locatie niet beschikbaar. Controleer locatiemachtigingen.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Wijnkelder \"$cellar\" succesvol aangemaakt!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Fout bij aanmaken: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 meter (zeer nauwkeurig)';

  @override
  String get cellarRadiusRecommended => '300 meter (aanbevolen)';

  @override
  String get cellarRadius500m => '500 meter';

  @override
  String get cellarRadius1km => '1 kilometer';

  @override
  String get cellarRadius3km => '3 kilometer';

  @override
  String get cellarCreateButton => 'Wijnkelder aanmaken';

  @override
  String get cellarUseCurrentGps => 'Instellen met huidige GPS-locatie';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Kelderinstellingen voor \"$cellar\" bijgewerkt';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Fout bij bijwerken: $error';
  }

  @override
  String get wineTypeRed => 'Rode Wijn 🍷';

  @override
  String get wineTypeWhite => 'Witte Wijn 🥂';

  @override
  String get wineTypeRose => 'Roséwijn 🌸';

  @override
  String get wineTypeSparkling => 'Mousserende Wijn 🍾';

  @override
  String get wineTypeDessert => 'Dessertwijn / Zoet 🍯';

  @override
  String get wineTypeLiqueur => 'Likeur 🍯';

  @override
  String get wineTypeSpirit => 'Gedistilleerd 🥃';

  @override
  String get wineTypeGrappa => 'Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Vruchtenbrandewijn 🍐';

  @override
  String get wineTypeWhisky => 'Whisky 🥃';

  @override
  String get wineTypeRum => 'Rum 🏴‍☠️';

  @override
  String get wineTypeGin => 'Gin 🍸';

  @override
  String get wineTypeVodka => 'Wodka 🧊';

  @override
  String get wineTypeTequila => 'Tequila 🌵';

  @override
  String get wineTypeCognac => 'Cognac 🍷';

  @override
  String get cellarCreateTitle => 'Nieuwe wijnkelder aanmaken';

  @override
  String get cellarManageTitle => 'Wijnkelder beheren';

  @override
  String get cellarNameLabel => 'Keldernaam *';

  @override
  String get cellarNameHint => 'bijv. Hoofdkelder, Wijnklimaatkast Woonkamer';

  @override
  String get cellarNameRequired => 'Voer een naam in';

  @override
  String get cellarLocationLabel => 'Plaats / Stad (optioneel)';

  @override
  String get cellarLocationHint => 'bijv. Amsterdam, Beaune';

  @override
  String get cellarNicknameLabel => 'Bijnaam / Ruimte (optioneel)';

  @override
  String get cellarNicknameHint => 'bijv. Gewelfde kelder, Woonkamer';

  @override
  String get cellarDescriptionLabel => 'Beschrijving (optioneel)';

  @override
  String get cellarDescriptionHint =>
      'bijv. Koele kelder, 70% luchtvochtigheid';

  @override
  String get cellarWifiLabel => 'Gekoppelde wifi (optioneel)';

  @override
  String get cellarWifiHint => 'bijv. Wijnkelder-Wifi';

  @override
  String get cellarLinkCurrentWifi => 'Koppelen aan huidige wifi';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Huidige wifi vastleggen';

  @override
  String get cellarRadiusLabel => 'GPS-detectiestraal';

  @override
  String get cellarAutoDetectionHeader => 'Automatische detectie & overgang';

  @override
  String get cellarAutoDetectionDesc =>
      'Koppel uw wifi-netwerk of GPS-coördinaten om automatisch over te schakelen naar deze kelder zodra u er bent.';

  @override
  String get cellarLatitudeLabel => 'Breedtegraad';

  @override
  String get cellarLongitudeLabel => 'Lengtegraad';

  @override
  String get checkoutGuidedTasting => 'Begeleide proeverij';

  @override
  String get checkoutGuidedTastingShared =>
      'Deel indrukken om de beurt of gezamenlijk';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analyseer kleur, geur en smaak en verfijn uw smaakprofiel';

  @override
  String get checkoutUncorkNowRateLater => 'Nu openen, later beoordelen';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Direct uitboeken • Kies herinneringstijd (vanavond, morgen...)';

  @override
  String get checkoutUncorkAeration => 'Ontkurken & Beluchtingstimer';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Direct uitboeken • $minutes min beluchting aanbevolen';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Direct uitboeken • Decanteer- & beluchtingstimer';

  @override
  String get checkoutSommelierServiceAdvice => 'Schenktips van de sommelier';

  @override
  String get checkoutHistoryAnecdotes => 'Verhalen & Anekdotes';

  @override
  String get checkoutNoDecanting => 'Geen decantering nodig';

  @override
  String get checkoutStoryTitle => 'Het verhaal van deze fles 📖';

  @override
  String get checkoutStorySubtitle => 'Boeiende verhalen om aan tafel te delen';

  @override
  String get checkoutStoryTerroir => 'Terroir & Druivenrassen';

  @override
  String get checkoutStoryVintage => 'Het verhaal van de jaargang';

  @override
  String get checkoutStoryTastingSecret => 'Proefgeheim';

  @override
  String get checkoutStoryTableAnecdote => 'Tafelanekdote';

  @override
  String get checkoutJournalArchivedNotice =>
      'Wees gerust: deze fles wordt bewaard in uw Proefdagboek met foto\'s en notities.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Fles geopend! Beluchtingstimer ($minutes min) actief op vergrendelingsscherm.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'De fles wordt direct geopend en uitgeboekt. Bevestig de gewenste beluchtingstijd:';

  @override
  String get checkoutRateWine => 'Wijn beoordelen';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Start ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Sommeliertip: $minutes min beluchten. Vergrendelscherm-timer klaar.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Herinnering na proeverij ingepland om uw notities vast te leggen.';

  @override
  String get checkoutBottleRemovedSuccess =>
      'Fles uitgeboekt uit de wijnkelder!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Geniet van de proeverij. Herinnering ingepland voor $date.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'Het smaakprofiel van elke deelnemer wordt automatisch verrijkt.';

  @override
  String checkoutCellarOf(String name) {
    return 'Kelder van $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Voorraad: $count fl.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Voeg een familielid of vriend toe die aanwezig is bij deze proeverij (bijv. Moeder, Vader, Thomas...).';

  @override
  String get checkoutAddGuestNameLabel => 'Voornaam / Naam';

  @override
  String get checkoutDelayedSheetTitle => 'Openen & later beoordelen';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'Wanneer wilt u een herinnering ontvangen voor uw proefnotities?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Vanavond over 2 uur ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Vanavond om 21:00 uur';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'vanavond om $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'morgen om $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'op $date om $time';
  }

  @override
  String get add => 'Toevoegen';

  @override
  String get cellarWinesTab => '🍷 Wijnen';

  @override
  String get cellarSpiritsTab => '🥃 Gedistilleerd';

  @override
  String get cellarPairWithDish => 'Welke wijn bij mijn gerecht?';

  @override
  String get cellarCollapseAll => 'Alles inklappen';

  @override
  String get cellarExpandAll => 'Alles uitklappen';

  @override
  String get cellarSort => 'Sorteren';

  @override
  String get cellarCategories => 'Categorieën';

  @override
  String get cellarFavorites => 'Favorieten';

  @override
  String get cellarGridView => 'Raster';

  @override
  String get cellarListView => 'Lijst';

  @override
  String get cellarClearFilters => 'Filters wissen';

  @override
  String get cellarNoBottlesCategory => 'Geen flessen in deze categorie';

  @override
  String get cellarNoBottlesCriteria =>
      'Geen flessen voldoen aan deze criteria';

  @override
  String get feedbackSheetTitle => 'Tester-feedback en annotatie';

  @override
  String get feedbackStylus => 'Stylus:';

  @override
  String get feedbackUndo => 'Laatste streek ongedaan maken';

  @override
  String get feedbackClear => 'Alles wissen';

  @override
  String get feedbackHint =>
      'Omcirkel het gebied en beschrijf uw feedback of bug...';

  @override
  String get feedbackSubmit => 'Rapport verzenden';

  @override
  String get feedbackSubmitting => 'Verzenden...';

  @override
  String get feedbackNoScreenshot => 'Geen schermafbeelding beschikbaar';

  @override
  String get feedbackEmptyError =>
      'Voeg een opmerking toe of teken op de schermafbeelding.';

  @override
  String get feedbackSuccess =>
      'Bedankt voor uw feedback! 🍷 Rapport verzonden.';

  @override
  String feedbackError(String error) {
    return 'Fout bij verzenden: $error';
  }

  @override
  String get checkoutFastExit => 'Snel uitboeken zonder vragenlijst ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Bezig met uitboeken...';

  @override
  String get checkoutRatingSubtitle => 'Geef uw algemene score na de proeverij';

  @override
  String get checkoutRecommendedBadge => 'Aanbevolen';

  @override
  String get tastingWhoTastedTitle => '👥 Wie heeft deze wijn geproefd?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Selecteer de proevers. Smaakprofielen worden automatisch verrijkt.';

  @override
  String get tastingHowToTaste => 'Hoe wilt u proeven?';

  @override
  String get tastingEachTurn => 'Om de beurt';

  @override
  String get tastingEachTurnDesc =>
      '📱 Telefoon doorgeven: iedereen beantwoordt apart in eigen tempo.';

  @override
  String get tastingTogether => 'Gezamenlijk';

  @override
  String get tastingTogetherDesc =>
      '🥂 Eén gezamenlijke vragenlijst voor alle gasten aan tafel.';

  @override
  String get tastingBlindMode => 'Blindproeverij-modus';

  @override
  String get tastingBlindModeDesc =>
      'Verbergt de wijnnaam en start een spannende tafelquiz met feestelijke onthulling!';

  @override
  String get tastingPrimaryProfile => 'Hoofdprofiel';

  @override
  String get tastingAppInstalled => 'App geïnstalleerd 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count vragenlijsten ingevuld',
      one: '1 vragenlijst ingevuld',
      zero: '0 vragenlijsten ingevuld',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 De Neus — Geurexpressie';

  @override
  String get tastingStepNezSubtitle =>
      'Wals het glas en neem de opstijgende geurlagen waar.';

  @override
  String get tastingAromaIntensity => 'Aromatische intensiteit:';

  @override
  String get tastingAromaDiscreet => '🤫 Subtiel / Verfijnd';

  @override
  String get tastingAromaExplosive => '💥 Uitbundig / Krachtig';

  @override
  String get tastingStepBoucheTitle => '⚖️ De Mond — Balans & Structuur';

  @override
  String get tastingStepBoucheSubtitle =>
      'Beschrijf textuur, frisheid en balans in de mond.';

  @override
  String get tastingAcidity => 'Zuren / Frisheid:';

  @override
  String get tastingAcidityFreshness => 'Zuren & Levendigheid:';

  @override
  String get tastingAcidityFlat => '🫠 Vlak / Log';

  @override
  String get tastingAciditySharp => '⚡ Strak / Levendig';

  @override
  String get tastingTannins => 'Tannines:';

  @override
  String get tastingTanninsSilky => '🧶 Zijdezacht / Soepel';

  @override
  String get tastingTanninsGrippy => '💪 Stevig / Gestructureerd';

  @override
  String get tastingMinerality => 'Mineraliteit & Spanning:';

  @override
  String get tastingMineralityRound => '🧈 Rond / Rijk';

  @override
  String get tastingMineralityCrisp => '🪨 Mineraal / Zuiver';

  @override
  String get tastingEffervescence => 'Mousse (Bubbels):';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fijn / Zacht';

  @override
  String get tastingEffervescenceVibrant => '🎆 Levendig / Romig';

  @override
  String get tastingBody => 'Body / Gewicht:';

  @override
  String get tastingBodyLight => '🍃 Licht / Elegant';

  @override
  String get tastingBodyFull => '🏋️ Vol / Krachtig';

  @override
  String get tastingLength => 'Afdronk / Lengte:';

  @override
  String get tastingLengthShort => '⏱️ Kort';

  @override
  String get tastingLengthLong => '♾️ Zeer lang aanhoudend';

  @override
  String get tastingStepVerdictTitle => '✅ Eindconclusie';

  @override
  String get tastingBuyAgain => 'Zou u deze fles opnieuw kopen?';

  @override
  String get tastingBuyAgainYes => '🤩 Zeker weten!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Misschien';

  @override
  String get tastingBuyAgainNo => '👎 Nee, dank u';

  @override
  String get tastingIdealMoment => 'Ideale gelegenheid voor deze wijn?';

  @override
  String get tastingMomentApero => '🥂 Aperitief';

  @override
  String get tastingMomentMeal => '🍽️ Informele maaltijd';

  @override
  String get tastingMomentDinner => '🎩 Feestelijk diner';

  @override
  String get tastingMomentRomantic => '🕯️ Romantisch diner';

  @override
  String get tastingMomentSolo => '🧘 Rustig genietmoment';

  @override
  String get tastingWhatLiked => 'Wat u het meest beviel:';

  @override
  String get tastingWhatDisliked => 'Wat u minder beviel:';

  @override
  String get tastingOccasionLabel => 'Gelegenheid / Herinnering (optioneel) ✨';

  @override
  String get tastingOccasionHint =>
      'bijv. Verjaardag, Diner bij kaarslicht, Reünie...';

  @override
  String get tastingAddPhoto => 'Voeg een herinneringsfoto toe 📸';

  @override
  String get tastingPhotoSaved => 'Foto opgeslagen 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Eindscore & Indruk';

  @override
  String get tastingStepImpressionSubtitle =>
      'Ken na geur en smaak uw algehele waardering toe.';

  @override
  String get tastingOverallFeeling => 'Uw algemene indruk:';

  @override
  String get tastingScoreOutOf10 => 'Score op een schaal van 10:';

  @override
  String get tastingCompletedTitle => 'Proeverij afgerond & opgeslagen!';

  @override
  String get tastingCompletedSubtitle =>
      'Smaakprofielen zijn succesvol bijgewerkt ✨';

  @override
  String get tastingBottleRemoved =>
      'Fles ontkurkt en uitgeboekt uit de wijnkelder';

  @override
  String get tastingConsultDebrief =>
      'Bekijk sommelier-debriefing (Verborgen nuances & Terroir)';

  @override
  String get tastingFinishButton => 'Afronden ✨';

  @override
  String get tastingNextTaster => 'Bevestigen → Volgende proever';

  @override
  String get tastingConfirmAndFinish => 'Bevestigen & Voltooien ✨';

  @override
  String get tastingQuitTitle => 'Vragenlijst verlaten?';

  @override
  String get tastingQuitMessage =>
      'Uw huidige antwoorden worden niet opgeslagen.';

  @override
  String get tastingContinue => 'Verdergaan';

  @override
  String get tastingQuit => 'Verlaten';

  @override
  String tastingStartCount(int count) {
    return 'Starten ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Gesynchroniseerd met $name\'s app ✨';
  }

  @override
  String get tastingProfileEnriched => 'Smaakprofiel verdiept';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Sensorische trefzekerheid: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle => 'Herkomst van smaken & Wijngeheimen';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Ontdek waar geuren, kleur en structuur vandaan komen';

  @override
  String get tastingBlindQuizTitle => 'Blindproeverij-tafelquiz 🙈';

  @override
  String get tastingBlindQuizQ1 =>
      '1. Uit welke wijnregio is deze wijn afkomstig? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. Wat is het belangrijkste druivenras? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Geschatte jaargang / leeftijd? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Geschat prijsniveau? 💶';

  @override
  String get tastingBlindRevealTitle =>
      'Grote onthulling van de mysterieuze fles 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Quiz-score: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Oenologische en moleculaire analyse';

  @override
  String get tastingSensoryAcuity => 'SENSORISCHE SCHERPZINNIGHEID';

  @override
  String tastingPrecision(int score) {
    return 'Trefzekerheid $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. OVEREENSTEMMING & CRU-KARAKTER';

  @override
  String get tastingWhatYouDetected => 'WAT U HEEFT WAARGENOMEN:';

  @override
  String get tastingArchetypeSignature => 'TYPISCHE SIGNATUUR VAN DE WIJN:';

  @override
  String get tastingHiddenNuancesTitle =>
      'SUBTIELE NUANCES VOOR HET VOLGENDE GLAS:';

  @override
  String get tastingPillarsTitle => '2. OENOLOGISCHE WETENSCHAP & MOLECULEN';

  @override
  String get tastingPillarsSubtitle =>
      'Waarom heeft deze wijn juist deze structuur, aroma\'s en kleur?';

  @override
  String get tastingChatWithSommelier =>
      'Verdiep wijnbouwgeheimen met Chatmelier';

  @override
  String get aromaFruitsRouges => 'Rood fruit (aardbei, kers)';

  @override
  String get aromaFruitsNoirs => 'Donker fruit (braam, zwarte bes)';

  @override
  String get aromaFruitsBlancs => 'Wit/geel fruit (perzik, peer, appel)';

  @override
  String get aromaAgrumes => 'Citrusvruchten (citroen, grapefruit)';

  @override
  String get aromaFloral => 'Bloemig (viooltjes, roos)';

  @override
  String get aromaVegetal => 'Kruidig & plantaardig (paprika, kreupelhout)';

  @override
  String get aromaEpicesDouces => 'Zoete specerijen (kaneel, nootmuskaat)';

  @override
  String get aromaEpicesVives => 'Pikante specerijen (zwarte peper)';

  @override
  String get aromaBoise => 'Houtrijping & vanille (eik)';

  @override
  String get aromaBeurre => 'Boter & Brioche';

  @override
  String get aromaMineral => 'Mineraal (vuursteen, krijt)';

  @override
  String get aromaMiel => 'Honing & Confituur';

  @override
  String get aromaChocolat => 'Pure chocolade & Koffie';

  @override
  String get aromaFumee => 'Rokerig & Geroosterd';

  @override
  String get emojiDisliked => 'Niet bevallen';

  @override
  String get emojiMeh => 'Matig';

  @override
  String get emojiDecent => 'Aardig';

  @override
  String get emojiVeryGood => 'Erg goed';

  @override
  String get emojiLoved => 'Fantastisch!';

  @override
  String get likedFreshness => 'De levendige frisheid';

  @override
  String get likedFruitiness => 'Het sappige fruit';

  @override
  String get likedComplexity => 'De complexiteit';

  @override
  String get likedElegance => 'De elegantie';

  @override
  String get likedPower => 'De kracht en structuur';

  @override
  String get likedSilky => 'De zijdezachte textuur';

  @override
  String get likedOriginality => 'De originaliteit en typiciteit';

  @override
  String get likedFoodPairing => 'De harmonie met het gerecht';

  @override
  String get likedMinerality => 'De mineraliteit';

  @override
  String get likedLength => 'De lange afdronk';

  @override
  String get likedDisappointing => 'Niets / Teleurstellend 😕';

  @override
  String get dislikedTooAcidic => 'Te zuur';

  @override
  String get dislikedTooTannic => 'Te tanninerijk / stroef';

  @override
  String get dislikedTooOaked => 'Te houterig / overmatig vanille';

  @override
  String get dislikedTooAlcoholic => 'Te alcoholisch / branderig';

  @override
  String get dislikedTooThin => 'Te licht / waterig';

  @override
  String get dislikedLacksFruit => 'Weinig fruit';

  @override
  String get dislikedTooSweet => 'Te zoet';

  @override
  String get dislikedTooExpensive => 'Te duur voor de kwaliteit';

  @override
  String get dislikedNothing => 'Niets, de wijn was uitstekend!';

  @override
  String get tastingStepTasters => 'Proevers';

  @override
  String get tastingStepNezNav => 'Neus';

  @override
  String get tastingStepBoucheNav => 'Mond';

  @override
  String get tastingStepVerdictNav => 'Oordeel';

  @override
  String get tastingStepRatingNav => 'Score';

  @override
  String get tastingBack => 'Terug';

  @override
  String get tastingNext => 'Volgende';

  @override
  String get tastingSaving => 'Bezig met opslaan...';

  @override
  String get tastingHeaderTitle => 'Proefformulier';

  @override
  String tastingAnswersOf(String name) {
    return 'Antwoorden van $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Geef de telefoon door aan $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Uw antwoorden zijn vastgelegd.\nNu is $name aan de beurt.';
  }

  @override
  String get tastingDictateButton => 'Tafelindrukken inspreken 🎙️';

  @override
  String get tastingDictateHint =>
      'Spreek of schrijf vrijuit: Chatmelier AI vult aroma\'s en mondgevoel automatisch in!';

  @override
  String get tastingDictateMicTip =>
      'Tip: activeer de microfoon op uw toetsenbord om hardop te dicteren!';

  @override
  String get tastingTakePhoto => 'Tafelfoto maken 📸';

  @override
  String get tastingChooseGallery => 'Kiezen uit galerij 🖼️';

  @override
  String get tastingConclaveSummary => 'Overzicht van de proeverij';

  @override
  String get tastingCellarMaster => 'Keldermeester';

  @override
  String get tastingGuestTaster => 'Gastproever';

  @override
  String tastingProfileTag(String type) {
    return 'Profiel: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Vrije proefnotitie opgeslagen.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Kleur/Zicht: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Structuur: $structure ($caudalies caudalies)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Sleutelmoleculen: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Doorslaggevende factor: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Druivenrassen: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Proefindrukken toegepast door Chatmelier AI ✨';

  @override
  String get tastingBlindYourPredictions => 'Overzicht van de voorspellingen:';

  @override
  String get tastingBlindGuessCorrect => 'Juist geraden! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Doe uw voorspellingen voordat het etiket wordt onthuld!';

  @override
  String tastingStartTaster(String name) {
    return 'Laten we beginnen, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Geweldig gedaan!';

  @override
  String tastingQuizWas(String answer) {
    return '(Het juiste antwoord was: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'bijv.: Peter vond hem fantastisch met 8.5/10, tonen van bosbessen en cederhout. Laura gaf 7/10 en vond de zuren wat prominent...';

  @override
  String get tastingDictateAnalyzing => 'Bezig met analyseren...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Analyseren en toepassen op fiches ✨';

  @override
  String get tastingFormatExpress => 'Snelle proeverij (1 pagina) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Score, hoofdaroma\'s en kort eindoordeel in 30 sec.';

  @override
  String get tastingFormatSommelier => 'Sommelier-formaat (Gedetailleerd) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Grondige analyse van geur, smaakbalans, afdronk & terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'Wat is een caudalie? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalie = 1 seconde aanhoudende smaak na doorslikken of uitspugen.\n• 1 tot 4 caudalies: lichte, frisse wijn\n• 5 tot 7 caudalies: prachtige harmonie\n• 8 tot 12+ caudalies: uitzonderlijke topwijn!';

  @override
  String get tastingAddCustomAroma => '+ Eigen aroma';

  @override
  String get tastingCustomAromaDialogTitle => 'Aroma toevoegen';

  @override
  String get tastingCustomAromaHint =>
      'bijv. Vuursteen, Wilde braam, Gedroogde rozen...';

  @override
  String get tastingFoodSynergyTitle => 'Combinatie met het gerecht 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Subliem';

  @override
  String get tastingSynergyHarmonious => '👍 Zeer harmonieus';

  @override
  String get tastingSynergyNeutral => '😐 Neutraal';

  @override
  String get tastingSynergyClashing => '⚡ Vloekend';

  @override
  String get checkoutFastRatingTitle =>
      'Snelle beoordeling in 1 tik (optioneel):';

  @override
  String get checkoutActionTastingTitle => 'Deze wijn proeven';

  @override
  String get checkoutActionTastingSubtitle =>
      'Express (1 pagina) of uitgebreid sommelier-formaat';

  @override
  String get checkoutActionDeferredRemind => 'Later herinneren 🌙';

  @override
  String get checkoutActionAerationTimer => 'Beluchtingstimer ⏱️';
}
