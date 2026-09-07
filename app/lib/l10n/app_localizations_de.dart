// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'Mein Weinkeller';

  @override
  String get navCellar => 'Keller';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'Verlauf';

  @override
  String get navStats => 'Statistik';

  @override
  String get actionMenuTitle => 'Keller-Aktionen';

  @override
  String get actionAddBottle => 'Flasche hinzufügen';

  @override
  String get actionAddBottleSub => 'Etikett scannen oder manuell eingeben';

  @override
  String get actionCheckoutBottle => 'Flasche verkosten / entnehmen';

  @override
  String get actionCheckoutBottleSub =>
      'Verkostung festhalten und Bestand anpassen';

  @override
  String get actionLookupWine => 'Wein nachschlagen / identifizieren';

  @override
  String get actionLookupWineSub =>
      'Sofortige KI-Erkennung und Terroir-Analyse';

  @override
  String get searchWinePlaceholder =>
      'Jahrgang, Weingut, Appellation suchen...';

  @override
  String get emptyCellarTitle => 'Dein Weinkeller ist leer';

  @override
  String get emptyCellarSub =>
      'Scanne deine erste Flasche, um deine Sammlung zu starten';

  @override
  String get emptyCellarButton => 'Erste Flasche hinzufügen';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Flaschen',
      one: '1 Flasche',
      zero: '0 Flaschen',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Gesamtwert';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterRed => 'Rot';

  @override
  String get filterWhite => 'Weiß';

  @override
  String get filterRose => 'Rosé';

  @override
  String get filterSparkling => 'Schaumwein';

  @override
  String get filterSheetTitle => 'Kellerfilter';

  @override
  String get filterReset => 'Zurücksetzen';

  @override
  String get filterApply => 'Filter anwenden';

  @override
  String get filterMaturity => 'Reifestatus / Trinkfenster';

  @override
  String get maturityAtPeak => 'Auf dem Höhepunkt';

  @override
  String get maturityDrinkSoon => 'Bald trinken';

  @override
  String get maturityAging => 'Lagerfähig';

  @override
  String get maturityTooYoung => 'Noch zu jung';

  @override
  String get maturityPastPeak => 'Über dem Zenit';

  @override
  String get filterContinents => 'Kontinente';

  @override
  String get filterCountries => 'Länder';

  @override
  String get filterGrapes => 'Rebsorten';

  @override
  String get filterAppellations => 'Regionen & Appellationen';

  @override
  String get bottleDetailInfo => 'Informationen & Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Trinkfenster';

  @override
  String get bottleDetailTerroirMap => 'Terroir- & Herkunftskarte';

  @override
  String get bottleDetailLabelPhoto => 'Originalfoto des Etiketts';

  @override
  String get bottleDetailVintage => 'Jahrgang';

  @override
  String get bottleDetailProducer => 'Weingut / Erzeuger';

  @override
  String get bottleDetailRegion => 'Region';

  @override
  String get bottleDetailCountry => 'Land';

  @override
  String get bottleDetailAppellation => 'Appellation / Anbaugebiet';

  @override
  String get bottleDetailGrapes => 'Rebsorten';

  @override
  String get bottleDetailAlcohol => 'Alkoholgehalt';

  @override
  String get bottleDetailStock => 'Bestand';

  @override
  String get bottleDetailLocation => 'Lagerort im Keller';

  @override
  String get bottleDetailRack => 'Regal';

  @override
  String get bottleDetailShelf => 'Fach';

  @override
  String get bottleDetailPurchasePrice => 'Kaufpreis';

  @override
  String get bottleDetailEstimatedValue => 'Geschätzter Wert';

  @override
  String get bottleDetailFoodPairings => 'Empfohlene Speisebegleiter';

  @override
  String get bottleDetailTastingNotes => 'Sommelier-Profil';

  @override
  String get bottleDetailDrinkButton => 'Diese Flasche entkorken';

  @override
  String get bottleDetailEdit => 'Bearbeiten';

  @override
  String get bottleDetailDelete => 'Löschen';

  @override
  String get bottleDetailDeleteConfirm =>
      'Möchtest du diese Flasche wirklich dauerhaft aus deinem Keller löschen?';

  @override
  String get deleteBottleTitle => 'Dauerhaft Löschen';

  @override
  String get deleteBottleExplanation =>
      'Achtung: Beim endgültigen Löschen werden alle Einträge dieser Flasche unwiderruflich entfernt.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Entkorken / Trinken: archiviert die Flasche im Verkostungsbuch, aktualisiert Statistiken und behält Notizen.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Endgültig löschen: entfernt den Eintrag spurlos (empfohlen bei Tippfehlern, Bruch oder Dubletten).';

  @override
  String get deleteBottleActionConfirm => 'Dauerhaft Löschen';

  @override
  String get deleteBottleActionDrinkInstead =>
      'Stattdessen entkorken / trinken';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get checkoutTitle => 'Verkosten & aus Keller entnehmen';

  @override
  String get checkoutSelectPrompt =>
      'Tippen, um eine Flasche aus dem Keller zu wählen...';

  @override
  String get checkoutQtyOpened => 'Anzahl geöffneter Flaschen';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'von $total im Weinkeller';
  }

  @override
  String get checkoutRating => 'Verkostungsbewertung';

  @override
  String get checkoutFoodPairing => 'Begleitendes Essen (optional)';

  @override
  String get checkoutFoodHint =>
      'z.B. Rindersteak vom Grill, Steinpilzrisotto...';

  @override
  String get checkoutNotes => 'Verkostungseindrücke & Notizen';

  @override
  String get checkoutNotesHint => 'Aromen, Balance, Abgang, Nuancen...';

  @override
  String get checkoutSubmit => 'Verkostung bestätigen';

  @override
  String get checkoutSuccess => 'Verkostung erfolgreich erfasst!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Hallo! Ich bin Chatmelier. Frage mich nach Wein-Speisen-Paarungen, Trinkempfehlungen oder Kellertipps basierend auf deinen Flaschen.';

  @override
  String get chatAnalyzing => 'Chatmelier analysiert deinen Weinkeller...';

  @override
  String get chatInputHint => 'Frag Chatmelier...';

  @override
  String get chatChipTonight => '🍷 Welchen Wein sollte ich heute trinken?';

  @override
  String get chatChipSteak => '🥩 Welcher Wein passt zum Steak?';

  @override
  String get chatChipSeafood => '🐟 Bester Weißwein zu Meeresfrüchten';

  @override
  String get chatChipPeak => '⏰ Welche Flaschen sind auf dem Höhepunkt?';

  @override
  String get journalTitle => 'Verkostungstagebuch';

  @override
  String get journalEmpty => 'Noch keine Verkostungen erfasst';

  @override
  String get journalEmptySub =>
      'Entkorke eine Flasche aus deinem Keller, um dein Tagebuch zu starten';

  @override
  String journalTastedOn(String date) {
    return 'Verkostet am $date';
  }

  @override
  String get statsTitle => 'Kellerstatistiken';

  @override
  String get statsTotalBottles => 'Flaschen im Keller';

  @override
  String get statsTotalValue => 'Kellerwert';

  @override
  String get statsBottlesEnjoyed => 'Genossene Flaschen';

  @override
  String get statsByColor => 'Verteilung nach Weinfarbe';

  @override
  String get statsByMaturity => 'Verteilung nach Reifestatus';

  @override
  String get statsByRegion => 'Top-Regionen';

  @override
  String get statsByCountry => 'Top-Länder';

  @override
  String get profileTitle => 'Profil & Einstellungen';

  @override
  String get profileEmail => 'E-Mail';

  @override
  String get profileDisplayName => 'Anzeigename';

  @override
  String get profileDefaultCurrency => 'Standardwährung';

  @override
  String get profileLanguage => 'App-Sprache';

  @override
  String get profileLanguageSystem => 'Automatisch (System)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Standardwährung aktualisiert: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Sprache aktualisiert';

  @override
  String get profileLogout => 'Abmelden';

  @override
  String get profileAbout => 'Über Chatmelier';

  @override
  String get scanTitle => 'Weinetikett Scannen';

  @override
  String get scanTakePhoto => 'Foto aufnehmen';

  @override
  String get scanPickGallery => 'Aus Galerie wählen';

  @override
  String get scanAnalyzing => 'Chatmelier-KI analysiert das Etikett...';

  @override
  String get scanIdentified => 'Wein von Chatmelier erkannt ✨';

  @override
  String get scanSaveToCellar => 'Zu meinem Keller hinzufügen';

  @override
  String get loginTitle => 'Anmelden';

  @override
  String get loginTagline => 'Dein intelligenter KI-gestützter Weinkeller';

  @override
  String get loginTabMagicLink => '✉️ Anmeldelink';

  @override
  String get loginTabPassword => '🔑 Passwort';

  @override
  String get loginEmailLabel => 'E-Mail-Adresse';

  @override
  String get loginPasswordLabel => 'Passwort';

  @override
  String get loginSendMagicLink => 'Anmeldelink anfordern';

  @override
  String get loginSignInButton => 'Anmelden';

  @override
  String get loginOrDivider => 'ODER';

  @override
  String get loginGoogleButton => 'Mit Google fortfahren';

  @override
  String get loginRegisterLink => 'Noch kein Konto? Jetzt registrieren';

  @override
  String get registerTitle => 'Konto Erstellen';

  @override
  String get registerNameLabel => 'Anzeigename';

  @override
  String get registerSubmitButton => 'Mein Konto erstellen';

  @override
  String get registerFillAllFields => 'Bitte alle Felder ausfüllen';

  @override
  String get registerWelcome => '🎉 Willkommen bei Chatmelier!';

  @override
  String get registerErrorGeneric => 'Fehler bei der Registrierung';

  @override
  String get authWelcome => 'Willkommen bei Chatmelier';

  @override
  String get authSubtitle =>
      'Dein persönlicher KI-Sommelier & intelligenter Kellermeister';

  @override
  String get authGoogle => 'Mit Google fortfahren';

  @override
  String get authMagicLink => 'Per E-Mail-Link anmelden';

  @override
  String get authEmail => 'E-Mail-Adresse';

  @override
  String get authNoAccount => 'Noch kein Konto? Jetzt registrieren';

  @override
  String get authHaveAccount => 'Bereits registriert? Anmelden';

  @override
  String get changelogTitle => 'Versionshinweise & Neuigkeiten';

  @override
  String get changelogEmpty => 'Keine Versionshinweise vorhanden.';

  @override
  String get scratchcardTitle => 'Welt-Terroir-Rubbelkarte';

  @override
  String get profileChangelog => 'Versionshistorie & Änderungen';

  @override
  String get profileScratchcard => 'Welt-Terroir-Rubbelkarte';

  @override
  String get navBar => 'Bar';

  @override
  String get navProfile => 'Profil';

  @override
  String get quickActions => 'SCHNELLAKTIONEN';

  @override
  String get appSubtitle => 'Sommelier & Weinkeller';

  @override
  String get profileTabPalate => 'Gaumen';

  @override
  String get profileTabSettings => 'Einstellungen';

  @override
  String get profileTabTools => 'Werkzeuge';

  @override
  String get profileTabAccount => 'Konto';

  @override
  String get profileTheme => 'Design / Thema';

  @override
  String get profileThemeLight => 'Hell ☀️';

  @override
  String get profileThemeDark => 'Dunkel 🌙';

  @override
  String get profileThemeSystem => 'System ⚙️';

  @override
  String get profileFriends => 'Freunde & Geschmackskarte 🍷';

  @override
  String get profileExport => 'Keller & Gutachten exportieren 📊';

  @override
  String get profileDeleteAccount => 'Mein Konto endgültig löschen';

  @override
  String get profileDeleteConfirmTitle => 'Endgültig löschen';

  @override
  String get profileDeleteConfirmMsg =>
      'Diese Aktion ist unwiderruflich. Alle Ihre Daten werden gelöscht.';

  @override
  String get badgesGalleryTitle => 'Trophäen-Galerie';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total freigeschaltet • $pct% abgeschlossen';
  }

  @override
  String get badgesFilterAll => 'Alle';

  @override
  String get badgesEmpty => 'Keine Abzeichen in dieser Kategorie gefunden.';

  @override
  String get badgesUnlockedChip => 'Freigeschaltet ✨';

  @override
  String get badgesStatusUnlocked => 'Abzeichen freigeschaltet!';

  @override
  String get badgesStatusInProgress => 'In Arbeit';

  @override
  String get badgesObjectiveLabel => 'Ziel:';

  @override
  String get badgesChatmelierLoreTitle =>
      'Wissenschaft & Geschichte von Chatmelier';

  @override
  String get badgesCloseButton => 'Schließen';

  @override
  String get badgesTierLabel => 'Rang';

  @override
  String get badgesShowcaseTitle => 'Trophäen & Abzeichen';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked von $total freigeschaltet';
  }

  @override
  String get badgesShowcaseGallery => 'Galerie';

  @override
  String get cocktailsTitle => 'Bar & Cocktails';

  @override
  String get cocktailsReadyToShake => 'Bereit zum Shaken';

  @override
  String get cocktailsMissingOne => '1 fehlt';

  @override
  String get cocktailsManagePantry => 'Vorrat verwalten';

  @override
  String get cocktailsResetPantry => 'Vorrat zurücksetzen';
}
