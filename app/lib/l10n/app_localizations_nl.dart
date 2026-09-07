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
  String get badgesTierLabel => 'Rang';

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
}
