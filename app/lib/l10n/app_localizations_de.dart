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
  String chatChipDuo(String a, String b) {
    return '🍷 Was trinken $a und $b heute Abend?';
  }

  @override
  String chatChipSolo(String a) {
    return '🍷 Was trinken $a und ich heute Abend?';
  }

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
  String get badgesTierLabel => 'Rangstufe';

  @override
  String get badgesShowcaseTitle => 'Trophäen & Abzeichen';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked von $total freigeschaltet';
  }

  @override
  String get badgesShowcaseGallery => 'Medaillen-Galerie';

  @override
  String get save => 'Speichern';

  @override
  String get continueAnyway => 'Trotzdem fortfahren';

  @override
  String get cellarDetected => 'Weinkeller erkannt: ';

  @override
  String proximityWifi(String ssid) {
    return 'Mit WLAN „$ssid“ verbunden';
  }

  @override
  String proximityGps(String distance) {
    return 'GPS-Standort erkannt ($distance)';
  }

  @override
  String get proximitySwitch => 'Wechseln';

  @override
  String get proximityIgnore => 'Ignorieren';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Automatisch zu „$cellar“ gewechselt';
  }

  @override
  String get distantCellarTitle => 'Entfernter Weinkeller erkannt';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Sie sind derzeit mit dem WLAN „$ssid“ verbunden, das zu Ihrem anderen Weinkeller „$cellar“ gehört.';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Sie befinden sich derzeit ca. $distance von „$cellar“ entfernt.';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nMöchten Sie diese Flasche dennoch zum Keller „$cellar“ hinzufügen?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nMöchten Sie diese Flasche dennoch aus dem Keller „$cellar“ ausbuchen?';
  }

  @override
  String get ratingExceptional => '🏆 Herausragend';

  @override
  String get ratingRemarkable => '✨ Bemerkenswert';

  @override
  String get ratingVeryGood => '🍷 Sehr gut';

  @override
  String get ratingPleasant => '👍 Angenehm';

  @override
  String get ratingPassable => 'Passabel';

  @override
  String get checkoutWhoTasted => 'Wer hat diesen Wein mit Ihnen verkostet?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'Flaschen',
      one: 'Flasche',
    );
    return '$producer • Vorrat: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Gast hinzufügen';

  @override
  String get checkoutAddGuestHint => 'Namen hinzufügen (Mama, Papa...)';

  @override
  String get checkoutCloseAndTaste => 'Schließen & Genießen 🍷';

  @override
  String get checkoutSommelierThinking =>
      'Der Sommelier bereitet Verkostungsgeschichten vor...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Belüftungs-Timer auf Ihrem Sperrbildschirm aktiv!';

  @override
  String get checkoutStartAerationTimer => 'Timer starten ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Belüftungs-Timer';

  @override
  String get checkoutDelayedTonight => 'Heute Abend um 22:00 Uhr';

  @override
  String get checkoutDelayedTonightSub =>
      'Ideal nach dem Essen, um den Eindruck in Ruhe zu vertiefen';

  @override
  String get checkoutDelayedTomorrow => 'Morgen Vormittag um 11:00 Uhr';

  @override
  String get checkoutDelayedTomorrowSub =>
      'In aller Ruhe die Verkostungseindrücke notieren';

  @override
  String get checkoutDelayedWeekend => 'Dieses Wochenende (Samstag 11:00 Uhr)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Nehmen Sie sich Zeit in einem freien Moment';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'In 2 Stunden ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Schnelle Erinnerung zum Abschluss der Verkostung';

  @override
  String get checkoutDelayedCustom => 'Eigenes Datum & Uhrzeit wählen...';

  @override
  String get reviewPackagingDetected => 'Gebindeformat erkannt';

  @override
  String get reviewSingleBottleOnly => 'Nein, nur 1 Flasche';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Ja, $count Flaschen';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Bestand erfolgreich aktualisiert! ($count Flaschen im Keller)';
  }

  @override
  String get reviewVintageYear => 'Jahrgang / Erntejahr';

  @override
  String get reviewNonVintage => 'Überspringen / Ohne Jahrgang (NV)';

  @override
  String get reviewValidate => 'Bestätigen';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 „$name“ erfolgreich in den Keller aufgenommen!';
  }

  @override
  String get reviewBottleAnalysis => 'Flaschenanalyse';

  @override
  String get reviewDiscard => 'Verwerfen';

  @override
  String get reviewDiscardConfirmTitle => 'Eingabe verwerfen?';

  @override
  String get reviewContinueEditing => 'Weiter bearbeiten';

  @override
  String get reviewDiscardWithoutSaving => 'Ohne Speichern verwerfen';

  @override
  String get reviewBottleDetails => 'Flaschendetails';

  @override
  String get reviewStockInCellar => 'Kellerbestand';

  @override
  String get reviewStockAddition => 'Hinzufügen';

  @override
  String get reviewStockNewTotal => 'Neuer Gesamtbestand';

  @override
  String get reviewQuantityToAdd => 'Menge zum Hinzufügen:';

  @override
  String get reviewSeparateEntry =>
      'Separaten Eintrag anlegen (anderes Regal / anderer Preis)';

  @override
  String get reviewRetryAi => 'KI-Analyse wiederholen';

  @override
  String get reviewEnlarge => 'Vergrößern';

  @override
  String get reviewGeneralInfo => 'Allgemeine Angaben';

  @override
  String get reviewOriginTerroir => 'Herkunft & Terroir';

  @override
  String get reviewQuantityPurchase => 'Menge & Kaufdetails';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 WLAN erkannt & verknüpft: „$ssid“';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'WLAN konnte nicht erkannt werden (Standort aktivieren oder manuell eingeben)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS-Koordinaten erfasst ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'GPS-Standort nicht verfügbar. Prüfen Sie die Standortberechtigungen.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Keller „$cellar“ erfolgreich erstellt!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Fehler bei der Erstellung: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 Meter (sehr präzise)';

  @override
  String get cellarRadiusRecommended => '300 Meter (empfohlen)';

  @override
  String get cellarRadius500m => '500 Meter';

  @override
  String get cellarRadius1km => '1 Kilometer';

  @override
  String get cellarRadius3km => '3 Kilometer';

  @override
  String get cellarCreateButton => 'Keller anlegen';

  @override
  String get cellarUseCurrentGps => 'Mit aktuellem GPS-Standort belegen';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Kellereinstellungen für „$cellar“ aktualisiert';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Fehler beim Aktualisieren: $error';
  }

  @override
  String get wineTypeRed => 'Rotwein 🍷';

  @override
  String get wineTypeWhite => 'Weißwein 🥂';

  @override
  String get wineTypeRose => 'Roséwein 🌸';

  @override
  String get wineTypeSparkling => 'Schaumwein 🍾';

  @override
  String get wineTypeDessert => 'Dessertwein / Edelsüß 🍯';

  @override
  String get bottleSizeCustom => 'Andere Größe…';

  @override
  String get bottleSizeCustomTitle => 'Eigene Größe';

  @override
  String get bottleSizeCustomLabel => 'Inhalt in Zentilitern';

  @override
  String get bottleSizeCustomInvalid =>
      'Geben Sie einen Inhalt zwischen 1 und 3000 cl ein.';

  @override
  String get wineTypeLiqueur => 'Likör 🍯';

  @override
  String get wineTypeSpirit => 'Spirituosen 🥃';

  @override
  String get wineTypeGrappa => 'Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Obstbrand 🍐';

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
  String get cellarCreateTitle => 'Neuen Keller anlegen';

  @override
  String get cellarManageTitle => 'Keller verwalten';

  @override
  String get cellarNameLabel => 'Kellername *';

  @override
  String get cellarNameHint => 'z. B. Hauptkeller, Landhaus Weinschrank';

  @override
  String get cellarNameRequired => 'Bitte geben Sie einen Namen ein';

  @override
  String get cellarLocationLabel => 'Ort / Stadt (optional)';

  @override
  String get cellarLocationHint => 'z. B. München, Beaune';

  @override
  String get cellarNicknameLabel => 'Raum / Bezeichnung (optional)';

  @override
  String get cellarNicknameHint =>
      'z. B. Kellergewölbe, Wohnzimmer-Klimaschrank';

  @override
  String get cellarDescriptionLabel => 'Beschreibung (optional)';

  @override
  String get cellarDescriptionHint =>
      'z. B. Kühler Erdkeller, 70% Luftfeuchtigkeit';

  @override
  String get cellarWifiLabel => 'Zugehöriges WLAN (optional)';

  @override
  String get cellarWifiHint => 'z. B. Weinkeller-WLAN';

  @override
  String get cellarLinkCurrentWifi => 'Mit aktuellem WLAN verknüpfen';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Aktuelles WLAN erfassen';

  @override
  String get cellarRadiusLabel => 'GPS-Erkennungsradius';

  @override
  String get cellarAutoDetectionHeader => 'Automatische Erkennung & Übergang';

  @override
  String get cellarAutoDetectionDesc =>
      'Verknüpfen Sie Ihr WLAN oder Ihre GPS-Koordinaten, um automatisch zu diesem Keller zu wechseln, sobald Sie vor Ort sind.';

  @override
  String get cellarLatitudeLabel => 'Breitengrad';

  @override
  String get cellarLongitudeLabel => 'Längengrad';

  @override
  String get checkoutGuidedTasting => 'Geführte Verkostung';

  @override
  String get checkoutGuidedTastingShared =>
      'Eindrücke nacheinander oder gemeinsam teilen';

  @override
  String get checkoutGuidedTastingSolo =>
      'Auge, Nase und Gaumen analysieren und das Geschmacksprofil verfeinern';

  @override
  String get checkoutUncorkNowRateLater => 'Jetzt öffnen, später bewerten';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Sofortige Ausbuchung • Erinnerungszeit wählen (heute Abend, morgen...)';

  @override
  String get checkoutUncorkAeration => 'Öffnen & Belüftungs-Timer';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Sofortige Ausbuchung • $minutes Min. Belüftung empfohlen';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Sofortige Ausbuchung • Dekantier- & Belüftungs-Timer';

  @override
  String get checkoutSommelierServiceAdvice => 'Servier-Tipps des Sommeliers';

  @override
  String get checkoutHistoryAnecdotes => 'Geschichten & Anekdoten';

  @override
  String get checkoutNoDecanting => 'Kein Dekantieren erforderlich';

  @override
  String get checkoutStoryTitle => 'Die Geschichte dieser Flasche 📖';

  @override
  String get checkoutStorySubtitle =>
      'Fesselnde Geschichten für gesellige Tischgespräche';

  @override
  String get checkoutStoryTerroir => 'Terroir & Rebsorten';

  @override
  String get checkoutStoryVintage => 'Die Geschichte des Jahrgangs';

  @override
  String get checkoutStoryTastingSecret => 'Verkostungs-Geheimnis';

  @override
  String get checkoutStoryTableAnecdote => 'Tisch-Anekdote';

  @override
  String get checkoutJournalArchivedNotice =>
      'Keine Sorge: Diese Flasche wird sorgfältig mit Fotos und Notizen in Ihrem Verkostungsjournal archiviert.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Flasche geöffnet! Belüftungs-Timer ($minutes Min.) läuft auf Ihrem Sperrbildschirm.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'Die Flasche wird sofort geöffnet und ausgebucht. Bestätigen Sie die Belüftungsdauer vor der Verkostung:';

  @override
  String get checkoutRateWine => 'Wein bewerten';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Timer $minutes Min. ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Sommelier-Tipp: $minutes Min. belüften. Sperrbildschirm-Timer bereit.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Erinnerung nach der Verkostung für Ihre Notizen geplant.';

  @override
  String get checkoutBottleRemovedSuccess =>
      'Flasche erfolgreich aus dem Keller ausgebucht!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Genießen Sie Ihre Verkostung. Erinnerung für $date geplant, um Ihre Eindrücke festzuhalten.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'Das Geschmacksprofil aller Teilnehmer wird automatisch angereichert.';

  @override
  String checkoutCellarOf(String name) {
    return 'Weinkeller von $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Vorrat: $count Fl.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Fügen Sie Familie oder Freunde hinzu, die an dieser Verkostung teilnehmen (z. B. Mama, Papa, Sophie...).';

  @override
  String get checkoutAddGuestNameLabel => 'Vorname / Name';

  @override
  String get checkoutDelayedSheetTitle => 'Öffnen & später bewerten';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'Wann möchten Sie eine Erinnerung für Ihre Verkostungsnotizen erhalten?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Heute Abend in 2 Stunden ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Heute Abend um 21:00 Uhr';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'heute Abend um $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'morgen um $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'am $date um $time';
  }

  @override
  String get add => 'Hinzufügen';

  @override
  String get cellarWinesTab => '🍷 Weine';

  @override
  String get cellarSpiritsTab => '🥃 Spirituosen';

  @override
  String get cellarPairWithDish => 'Welcher Wein zu meinem Gericht?';

  @override
  String get cellarCollapseAll => 'Alles einklappen';

  @override
  String get cellarExpandAll => 'Alles ausklappen';

  @override
  String get cellarSort => 'Sortieren';

  @override
  String get cellarCategories => 'Kategorien';

  @override
  String get cellarFavorites => 'Favoriten';

  @override
  String get cellarGridView => 'Raster';

  @override
  String get cellarListView => 'Listenansicht';

  @override
  String get cellarClearFilters => 'Filter löschen';

  @override
  String get cellarNoBottlesCategory => 'Keine Flaschen in dieser Kategorie';

  @override
  String get cellarNoBottlesCriteria =>
      'Keine Flaschen entsprechen diesen Kriterien';

  @override
  String get feedbackSheetTitle => 'Tester-Feedback & Annotation';

  @override
  String get feedbackStylus => 'Stift:';

  @override
  String get feedbackUndo => 'Letzten Strich rückgängig machen';

  @override
  String get feedbackClear => 'Alles löschen';

  @override
  String get feedbackHint =>
      'Bereich einkreisen und Feedback oder Fehler beschreiben...';

  @override
  String get feedbackSubmit => 'Bericht senden';

  @override
  String get feedbackSubmitting => 'Wird gesendet...';

  @override
  String get feedbackNoScreenshot => 'Kein Screenshot verfügbar';

  @override
  String get feedbackEmptyError =>
      'Bitte einen Kommentar hinzufügen oder auf dem Screenshot zeichnen.';

  @override
  String get feedbackSuccess =>
      'Vielen Dank für Ihr Feedback! 🍷 Bericht wurde gesendet.';

  @override
  String feedbackError(String error) {
    return 'Fehler beim Senden: $error';
  }

  @override
  String get checkoutFastExit => 'Schnell-Ausbuchung ohne Fragebogen ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Ausbuchung läuft...';

  @override
  String get checkoutRatingSubtitle =>
      'Geben Sie Ihre Gesamtwertung nach der Verkostung ab';

  @override
  String get checkoutRecommendedBadge => 'Empfohlen';

  @override
  String get tastingWhoTastedTitle => '👥 Wer hat diesen Wein verkostet?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Wählen Sie die Verkoster aus. Die Geschmacksprofile werden automatisch trainiert.';

  @override
  String get tastingHowToTaste => 'Wie möchten Sie verkosten?';

  @override
  String get tastingEachTurn => 'Nacheinander';

  @override
  String get tastingEachTurnDesc =>
      '📱 Smartphone weiterreichen: Jeder antwortet separat im eigenen Tempo.';

  @override
  String get tastingTogether => 'Gemeinsam';

  @override
  String get tastingTogetherDesc =>
      '🥂 Ein einziger Fragebogen wird am Tisch gemeinsam ausgefüllt.';

  @override
  String get tastingBlindMode => 'Blindverkostungs-Modus';

  @override
  String get tastingBlindModeDesc =>
      'Verdeckt den Namen des Weins und startet ein spannendes Tisch-Quiz mit feierlicher Auflösung!';

  @override
  String get tastingPrimaryProfile => 'Hauptprofil';

  @override
  String get tastingAppInstalled => 'App installiert 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Fragebögen ausgefüllt',
      one: '1 Fragebogen ausgefüllt',
      zero: '0 Fragebögen ausgefüllt',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 Die Nase — Aromenausdruck';

  @override
  String get tastingStepNezSubtitle =>
      'Schwenken Sie das Glas und erfassen Sie die aufsteigenden Aromenschichten.';

  @override
  String get tastingFaultTitle => 'Riecht der Wein nach einem dieser Dinge?';

  @override
  String get tastingFaultSubtitle =>
      'Dann ist die Flasche fehlerhaft – es liegt weder an Ihrem Gaumen noch am Stil des Weins.';

  @override
  String get tastingFaultCorkLabel => '📦 Feuchte Pappe, muffiger Keller';

  @override
  String get tastingFaultCorkExplain =>
      'Korkschmecker (TCA). Der Wein kann nichts dafür und Belüften hilft nicht – im Restaurant dürfen Sie eine andere Flasche verlangen.';

  @override
  String get tastingFaultOxidationLabel => '🍎 Überreifer Apfel, Essig, Sherry';

  @override
  String get tastingFaultOxidationExplain =>
      'Oxidation. Die Flasche hat Luft gezogen, oft durch einen schadhaften Korken oder zu lange Lagerung.';

  @override
  String get tastingFaultReductionLabel => '🥚 Streichholz, Ei, Kohl';

  @override
  String get tastingFaultReductionExplain =>
      'Reduktion. Gute Nachricht: Sie verfliegt oft an der Luft. Zwanzig Minuten dekantieren und vor dem Urteil erneut probieren.';

  @override
  String get tastingFaultExcluded =>
      'Diese Verkostung fließt nicht in Ihr Geschmacksprofil ein.';

  @override
  String get tastingAromaIntensity => 'Aromenintensität:';

  @override
  String get tastingAromaDiscreet => '🤫 Dezent / Zurückhaltend';

  @override
  String get tastingAromaExplosive => '💥 Explosiv / Ausdrucksstark';

  @override
  String get tastingStepBoucheTitle => '⚖️ Der Gaumen — Balance & Harmonie';

  @override
  String get tastingStepBoucheSubtitle =>
      'Beschreiben Sie Textur, Säurespiel und Mundgefühl des Weins.';

  @override
  String get tastingAcidity => 'Säureeindruck:';

  @override
  String get tastingAcidityFreshness => 'Säure & Frische:';

  @override
  String get tastingAcidityFlat => '🫠 Mürbe / Flach';

  @override
  String get tastingAciditySharp => '⚡ Rassig / Frisch';

  @override
  String get tastingTannins => 'Tannine (Gerbstoffe):';

  @override
  String get tastingTanninsSilky => '🧶 Seidig / Fein gewoben';

  @override
  String get tastingTanninsGrippy => '💪 Griffig / Fest';

  @override
  String get tastingMinerality => 'Mineralität & Straffheit:';

  @override
  String get tastingMineralityRound => '🧈 Rund / Buttrig';

  @override
  String get tastingMineralityCrisp => '🪨 Mineralisch / Präzise';

  @override
  String get tastingEffervescence => 'Perlage:';

  @override
  String get tastingEffervescenceDelicate => '🫧 Feinperlig / Zart';

  @override
  String get tastingEffervescenceVibrant => '🎆 Lebendig / Cremig';

  @override
  String get tastingBody => 'Körper / Fülle:';

  @override
  String get tastingBodyLight => '🍃 Leicht / Schwebend';

  @override
  String get tastingBodyFull => '🏋️ Kräftig / Vollmundig';

  @override
  String get tastingLength => 'Abgang / Nachhall:';

  @override
  String get tastingLengthShort => '⏱️ Kurz';

  @override
  String get tastingLengthLong => '♾️ Sehr lang anhaltend';

  @override
  String get tastingStepVerdictTitle => '✅ Gesamturteil';

  @override
  String get sipSectionTitle => '🍷 Der Schluck';

  @override
  String get tasteConfidenceUnknown =>
      'Ich kenne Ihren Gaumen noch nicht – der Halo zeigt, was ich vermute.';

  @override
  String get tasteEvidenceTitle => 'Woher dieses Profil kommt';

  @override
  String get tasteEvidenceEmpty =>
      'Noch nichts erfasst. Ihr Profil entsteht beim Verkosten.';

  @override
  String get tasteEvidenceOpen => 'Sehen, woher dieses Profil kommt';

  @override
  String tasteConfidenceKnown(String percent) {
    return 'Gaumen zu $percent % bekannt. Die Unschärfe zeigt, was ich noch vermute.';
  }

  @override
  String tasteConfidenceFrontier(String axis) {
    return 'Was ich am wenigsten kenne: $axis.';
  }

  @override
  String get sipSectionSubtitle =>
      'Zwei Tipps, und dieses Glas bringt Ihrem Geschmacksprofil etwas bei.';

  @override
  String get tastingBuyAgain => 'Würden Sie diesen Wein nachkaufen?';

  @override
  String get tastingBuyAgainYes => '🤩 Unbedingt!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Vielleicht';

  @override
  String get tastingBuyAgainNo => '👎 Nein, danke';

  @override
  String get tastingIdealMoment => 'Idealer Anlass für diesen Wein?';

  @override
  String get tastingMomentApero => '🥂 Zum Aperitif';

  @override
  String get tastingMomentMeal => '🍽️ Gemütliches Essen';

  @override
  String get tastingMomentDinner => '🎩 Festliches Menü';

  @override
  String get tastingMomentRomantic => '🕯️ Romantisches Dinner';

  @override
  String get tastingMomentSolo => '🧘 Ruhiger Genussmoment';

  @override
  String get tastingWhatLiked => 'Was Ihnen besonders gefallen hat:';

  @override
  String get tastingWhatDisliked => 'Was Ihnen weniger gefallen hat:';

  @override
  String get tastingOccasionLabel => 'Anlass / Erinnerung (optional) ✨';

  @override
  String get tastingOccasionHint =>
      'z. B. Geburtstag, Kerzenschein, Wiedersehen...';

  @override
  String get tastingAddPhoto => 'Erinnerungsfoto des Tisches aufnehmen 📸';

  @override
  String get tastingPhotoSaved => 'Foto-Erinnerung gespeichert 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Endnote & Gesamteindruck';

  @override
  String get tastingStepImpressionSubtitle =>
      'Vergeben Sie nach Nase und Gaumen Ihre abschließende Wertung.';

  @override
  String get tastingOverallFeeling => 'Ihr Gesamteindruck:';

  @override
  String get tastingScoreOutOf10 => 'Wertung auf einer Skala bis 10:';

  @override
  String get tastingCompletedTitle => 'Verkostung abgeschlossen & gespeichert!';

  @override
  String get tastingCompletedSubtitle =>
      'Geschmacksprofile wurden erfolgreich aktualisiert ✨';

  @override
  String get tastingBottleRemoved =>
      'Flasche geöffnet & aus dem Weinkeller entnommen';

  @override
  String get tastingConsultDebrief =>
      'Sommelier-Debrief ansehen (Verborgene Nuancen & Terroir)';

  @override
  String get tastingFinishButton => 'Fertig ✨';

  @override
  String get tastingNextTaster => 'Bestätigen → Nächster Verkoster';

  @override
  String get tastingConfirmAndFinish => 'Bestätigen & Abschließen ✨';

  @override
  String get tastingQuitTitle => 'Fragebogen verlassen?';

  @override
  String get tastingQuitMessage =>
      'Ihre bisherigen Antworten werden nicht gespeichert.';

  @override
  String get tastingContinue => 'Fortfahren';

  @override
  String get tastingQuit => 'Verlassen';

  @override
  String tastingStartCount(int count) {
    return 'Starten ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Mit ${name}s App synchronisiert ✨';
  }

  @override
  String get tastingProfileEnriched => 'Geschmacksprofil erweitert';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Sensorische Treffsicherheit: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle =>
      'Ursprung der Aromen & Wein-Geheimnisse';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Entdecken Sie, woher Aromen, Farbe und Struktur des Weines stammen';

  @override
  String get tastingBlindQuizTitle => 'Blindverkostungs-Quiz am Tisch 🙈';

  @override
  String get tastingBlindQuizQ1 =>
      '1. Aus welcher Weinregion stammt dieser Wein? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. Was ist die vorherrschende Rebsorte? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Geschätzter Jahrgang / Reifealter? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Geschätztes Preisniveau? 💶';

  @override
  String get tastingBlindRevealTitle => 'Große Enthüllung der Flasche 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Quiz-Ergebnis: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Önologisches & Molekulares Debrief';

  @override
  String get tastingSensoryAcuity => 'SENSORISCHE SCHÄRFE';

  @override
  String tastingPrecision(int score) {
    return '$score% Treffgenauigkeit';
  }

  @override
  String get tastingConcordanceTitle => '1. KONKORDANZ & CRU-SIGNATUR';

  @override
  String get tastingWhatYouDetected => 'WAS SIE ERKANNT HABEN:';

  @override
  String get tastingArchetypeSignature => 'TYPISCHE SIGNATUR DIESES WEINES:';

  @override
  String get tastingHiddenNuancesTitle =>
      'SUBTILE NUANCEN FÜR DAS NÄCHSTE GLAS:';

  @override
  String get tastingPillarsTitle => '2. ÖNOLOGISCHE WISSENSCHAFT & MOLEKÜLE';

  @override
  String get tastingPillarsSubtitle =>
      'Warum hat dieser Wein genau diesen Körper, diese Aromen und diese Farbe?';

  @override
  String get tastingChatWithSommelier =>
      'Vertiefen Sie Ausbau-Geheimnisse mit Chatmelier';

  @override
  String get aromaFruitsRouges => 'Rote Beeren (Erdbeere, Kirsche)';

  @override
  String get aromaFruitsNoirs => 'Dunkle Beeren (Johannisbeere, Brombeere)';

  @override
  String get aromaFruitsBlancs => 'Helles Steinobst (Pfirsich, Birne, Apfel)';

  @override
  String get aromaAgrumes => 'Zitrusfrüchte (Zitrone, Grapefruit)';

  @override
  String get aromaFloral => 'Blumig (Veilchen, Rose)';

  @override
  String get aromaVegetal => 'Kräuterig & Pflanzlich (Paprika, Heu)';

  @override
  String get aromaEpicesDouces => 'Süße Gewürze (Zimt, Muskat)';

  @override
  String get aromaEpicesVives => 'Pfeffrig & Pikant (Schwarzer Pfeffer)';

  @override
  String get aromaBoise => 'Holzausbau & Vanille (Eichenfass)';

  @override
  String get aromaBeurre => 'Butter & Brioche';

  @override
  String get aromaMineral => 'Mineralisch (Feuerstein, Kreide)';

  @override
  String get aromaMiel => 'Honig & Konfitüre';

  @override
  String get aromaChocolat => 'Dunkle Schokolade & Kaffee';

  @override
  String get aromaFumee => 'Rauchig & Getoastet';

  @override
  String get emojiDisliked => 'Nicht mein Fall';

  @override
  String get emojiMeh => 'Mittelmäßig';

  @override
  String get emojiDecent => 'Ganz ordentlich';

  @override
  String get emojiVeryGood => 'Sehr gut';

  @override
  String get emojiLoved => 'Begeistert!';

  @override
  String get likedFreshness => 'Frische & Saftigkeit';

  @override
  String get likedFruitiness => 'Klare Fruchtbetontheit';

  @override
  String get likedComplexity => 'Komplexität';

  @override
  String get likedElegance => 'Eleganz & Finesse';

  @override
  String get likedPower => 'Kraft & Fülle';

  @override
  String get likedSilky => 'Seidige Textur';

  @override
  String get likedOriginality => 'Typizität & Originalität';

  @override
  String get likedFoodPairing => 'Hervorragende Speisenharmonie';

  @override
  String get likedMinerality => 'Mineralität';

  @override
  String get likedLength => 'Langer Nachhall';

  @override
  String get likedDisappointing => 'Nichts / Enttäuschend 😕';

  @override
  String get dislikedTooAcidic => 'Zu spitz / zu viel Säure';

  @override
  String get dislikedTooTannic => 'Zu adstringierend / pelzige Tannine';

  @override
  String get dislikedTooOaked => 'Zu holzbetont / übermäßig vanillig';

  @override
  String get dislikedTooAlcoholic => 'Zu alkoholisch / brennend';

  @override
  String get dislikedTooThin => 'Zu dünn / wässrig';

  @override
  String get dislikedLacksFruit => 'Zu wenig Frucht';

  @override
  String get dislikedTooSweet => 'Zu süß';

  @override
  String get dislikedTooExpensive => 'Zu teuer für die Qualität';

  @override
  String get dislikedNothing => 'Nichts, er war absolut perfekt!';

  @override
  String get tastingStepTasters => 'Verkoster';

  @override
  String get tastingStepNezNav => 'Nase';

  @override
  String get tastingStepBoucheNav => 'Gaumen';

  @override
  String get tastingStepVerdictNav => 'Urteil';

  @override
  String get tastingStepRatingNav => 'Wertung';

  @override
  String get tastingBack => 'Zurück';

  @override
  String get tastingNext => 'Weiter';

  @override
  String get tastingSaving => 'Wird gespeichert...';

  @override
  String get tastingHeaderTitle => 'Verkostungs-Fragebogen';

  @override
  String tastingAnswersOf(String name) {
    return 'Antworten von $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Reichen Sie das Smartphone an $name weiter 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Ihre Antworten wurden erfasst.\nJetzt ist $name an der Reihe.';
  }

  @override
  String get tastingDictateButton => 'Tischeindrücke diktieren 🎙️';

  @override
  String get tastingDictateHint =>
      'Sprechen oder schreiben Sie frei: Die Chatmelier-KI füllt Aromen und Gaumenbalance automatisch vor!';

  @override
  String get tastingDictateMicTip =>
      'Tipp: Mikrofon auf Ihrer Tastatur aktivieren, um laut zu diktieren!';

  @override
  String get tastingTakePhoto => 'Tischfoto aufnehmen 📸';

  @override
  String get tastingChooseGallery => 'Aus Galerie wählen 🖼️';

  @override
  String get tastingConclaveSummary => 'Zusammenfassung der Verkostung';

  @override
  String get tastingCellarMaster => 'Kellermeister';

  @override
  String get tastingGuestTaster => 'Gast-Verkoster';

  @override
  String tastingProfileTag(String type) {
    return 'Profil: $type';
  }

  @override
  String get tastingFreeTastingRecorded =>
      'Freie Verkostungsnotiz gespeichert.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Aussehen: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Struktur: $structure ($caudalies Caudalien)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Schlüsselmoleküle: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Prägender Faktor: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Rebsorten: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Verkostungseindrücke von der Chatmelier-KI übernommen ✨';

  @override
  String get tastingBlindYourPredictions => 'Zusammenfassung der Blind-Tipps:';

  @override
  String get tastingBlindGuessCorrect => 'Richtig getippt! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Geben Sie Ihre Tipps ab, bevor das Etikett enthüllt wird!';

  @override
  String tastingStartTaster(String name) {
    return 'Auf geht\'s, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Hervorragend!';

  @override
  String tastingQuizWas(String answer) {
    return '(Die Antwort lautete: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'z. B.: Michael fand ihn fantastisch mit 8,5/10, Waldbeer- und Zedernnoten. Anna gab 7/10 und fand die Säure etwas dominant...';

  @override
  String get tastingDictateAnalyzing => 'Wird analysiert...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Analysieren & in Bogen übernehmen ✨';

  @override
  String get tastingFormatExpress => 'Express-Format (1 Seite) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Wertung, Kernaromen und Kurzfazit in 30 Sek.';

  @override
  String get tastingFormatSommelier => 'Sommelier-Format (Detailliert) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Umfassende Analyse von Nase, Gaumenbalance, Abgang & Terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'Was ist eine Caudalie? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 Caudalie = 1 Sekunde anhaltender Geschmackseindruck nach dem Schlucken oder Ausspucken.\n• 1 bis 4 Caudalien: leichter, unkomplizierter Wein\n• 5 bis 7 Caudalien: wunderschöne Balance & Struktur\n• 8 bis 12+ Caudalien: herausragendes Spitzen-Gewächs!';

  @override
  String get tastingAddCustomAroma => '+ Eigenes Aroma';

  @override
  String get tastingCustomAromaDialogTitle => 'Präzises Aroma ergänzen';

  @override
  String get tastingCustomAromaHint =>
      'z. B. Nasser Schiefer, Walderdbeere, getrocknete Rosen...';

  @override
  String get tastingFoodSynergyTitle => 'Harmonie zur Speise 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Perfekte Symbiose';

  @override
  String get tastingSynergyHarmonious => '👍 Sehr harmonisch';

  @override
  String get tastingSynergyNeutral => '😐 Ausgeglichen / Neutral';

  @override
  String get tastingSynergyClashing => '⚡ Disharmonisch';

  @override
  String get checkoutFastRatingTitle =>
      'Schnellbewertung mit 1 Fingertipp (optional):';

  @override
  String get checkoutActionTastingTitle => 'Diesen Wein verkosten';

  @override
  String get checkoutActionTastingSubtitle =>
      'Express (1 Seite) oder detailliertes Sommelier-Format';

  @override
  String get checkoutActionDeferredRemind => 'Später erinnern 🌙';

  @override
  String get checkoutActionAerationTimer => 'Belüftungs-Timer ⏱️';

  @override
  String get externalTastingTitle => 'Verkostung außer Haus';

  @override
  String get externalTastingSubtitle =>
      'Restaurant, Bar, bei Freunden ... ohne Ihren Bestand zu ändern';

  @override
  String get externalTastingWithWhom => 'Mit wem verkosten Sie diesen Wein?';

  @override
  String get externalTastingWhere => 'Wo verkosten Sie diesen Wein?';

  @override
  String get externalTastingSearchingPlaces =>
      'Suche nach Restaurants, Bars & Freunden in Ihrer Nähe ...';

  @override
  String get externalTastingGpsActive => 'GPS aktiv';

  @override
  String externalTastingPlaceGuess(String place) {
    return 'Sie scheinen hier zu sein: $place';
  }

  @override
  String get externalTastingFavoritePlaceNote =>
      'Lieblingsort, den Chatmelier automatisch gespeichert hat';

  @override
  String get externalTastingChangePlace => 'Ort wechseln';

  @override
  String get externalTastingOtherPlace => 'Bei Freunden / Anderer Ort ...';

  @override
  String get externalTastingNoPlaceFound =>
      'In unmittelbarer Nähe wurde kein Restaurant erkannt.';

  @override
  String get externalTastingPlaceLabel => 'Bei wem oder wo sind Sie? *';

  @override
  String get externalTastingPlaceHint =>
      'z. B. Bei Dimitri, Bei meinen Eltern, Landhaus ...';

  @override
  String externalTastingRememberPlace(String place) {
    return '\"$place\" an dieser GPS-Position für Ihre nächsten Besuche merken';
  }

  @override
  String get externalTastingDefaultPlace => 'Im Restaurant';

  @override
  String get externalTastingAiIdentifyTitle =>
      'Mit KI erkennen (Bar, Restaurant, Tafel)';

  @override
  String get externalTastingAiIdentifyDesc =>
      'Geben Sie ein paar Wörter ein (z. B. \"Saint-Joseph Coursodon 2021\" oder \"Bandol Terrebrune\"), um das Formular vorauszufüllen.';

  @override
  String get externalTastingAiIdentifyHint =>
      'z. B. Saint-Joseph 2021 Coursodon ...';

  @override
  String get externalTastingDetect => 'Erkennen';

  @override
  String get externalTastingAiScanningSub =>
      'Erkennung von Weingut, Jahrgang, Rebsorten und Noten ...';

  @override
  String get externalTastingPhotoAdded => 'Etikettenfoto hinzugefügt';

  @override
  String get externalTastingPhotoAddedSub =>
      'Sichtbar in Ihrem Verkostungstagebuch';

  @override
  String get externalTastingReplacePhoto => 'Ersetzen';

  @override
  String get externalTastingDeletePhoto => 'Foto löschen';

  @override
  String get externalTastingScanLabelTitle => 'Etikett fotografieren (KI-Scan)';

  @override
  String get externalTastingScanLabelSub =>
      'Automatische Weinerkennung und Eintrag ins Tagebuch';

  @override
  String get externalTastingScanLabelButton => 'KI-Scan';

  @override
  String get externalTastingTakePhotoSub =>
      'Etikett mit der Kamera fotografieren';

  @override
  String get externalTastingPickGallerySub => 'Ein vorhandenes Foto auswählen';

  @override
  String get externalTastingWineNameLabel => 'Weinname *';

  @override
  String get externalTastingWineNameHint => 'z. B. Domaine de Terrebrune';

  @override
  String get externalTastingProducerHint => 'z. B. Famille Delon';

  @override
  String get externalTastingRegionLabel => 'Anbaugebiet / Appellation';

  @override
  String get externalTastingRegionHint => 'z. B. Bandol Rouge';

  @override
  String get externalTastingRatingLabel => 'Verkostungsnote:';

  @override
  String get externalTastingFavorite => 'Herzensfavorit';

  @override
  String get externalTastingFoodLabel => 'Speisen-Wein-Begleitung';

  @override
  String get externalTastingNotesLabel => 'Eindrücke & wahrgenommene Aromen';

  @override
  String get externalTastingNotesHint =>
      'z. B. Intensive dunkle Frucht, seidige Tannine, langer Abgang ...';

  @override
  String get externalTastingSubmit => 'Speichern & bewerten ✨';

  @override
  String get externalTastingNameRequired =>
      'Bitte geben Sie mindestens den Weinnamen an.';

  @override
  String get externalTastingSaved =>
      'Verkostung außer Haus gespeichert! Chatmelier wird sich daran erinnern.';

  @override
  String externalTastingAiRecognized(String name) {
    return '✨ Flasche von der KI erkannt: $name';
  }

  @override
  String externalTastingAiFilled(String name) {
    return '✨ Formular von der KI ausgefüllt: $name';
  }

  @override
  String externalTastingAnalysisError(String error) {
    return 'Analysefehler: $error';
  }

  @override
  String externalTastingSaveError(String error) {
    return 'Fehler: $error';
  }
}
