// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'La mia Cantina';

  @override
  String get navCellar => 'Cantina';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'Storico';

  @override
  String get navStats => 'Statistiche';

  @override
  String get actionMenuTitle => 'Azioni Cantina';

  @override
  String get actionAddBottle => 'Aggiungi una bottiglia';

  @override
  String get actionAddBottleSub => 'Scansiona etichetta o inserimento manuale';

  @override
  String get actionCheckoutBottle => 'Degusta / Stappa una bottiglia';

  @override
  String get actionCheckoutBottleSub =>
      'Registra degustazione e scala dallo stock';

  @override
  String get actionLookupWine => 'Consulta / Identifica un vino';

  @override
  String get actionLookupWineSub => 'Scoperta e analisi istantanea con IA';

  @override
  String get searchWinePlaceholder =>
      'Cerca annata, produttore, denominazione...';

  @override
  String get emptyCellarTitle => 'La tua cantina è vuota';

  @override
  String get emptyCellarSub =>
      'Scansiona la tua prima bottiglia per iniziare la collezione';

  @override
  String get emptyCellarButton => 'Aggiungi la mia prima bottiglia';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bottiglie',
      one: '1 bottiglia',
      zero: '0 bottiglie',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Valore totale';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterRed => 'Rosso';

  @override
  String get filterWhite => 'Bianco';

  @override
  String get filterRose => 'Rosato';

  @override
  String get filterSparkling => 'Spumante';

  @override
  String get filterSheetTitle => 'Filtri Cantina';

  @override
  String get filterReset => 'Reimposta';

  @override
  String get filterApply => 'Applica filtri';

  @override
  String get filterMaturity => 'Stato di Maturità / Apogeo';

  @override
  String get maturityAtPeak => 'All\'apogeo';

  @override
  String get maturityDrinkSoon => 'Da bere presto';

  @override
  String get maturityAging => 'Da affinare';

  @override
  String get maturityTooYoung => 'Troppo giovane';

  @override
  String get maturityPastPeak => 'Oltre il picco';

  @override
  String get filterContinents => 'Continenti';

  @override
  String get filterCountries => 'Paesi';

  @override
  String get filterGrapes => 'Vitigni';

  @override
  String get filterAppellations => 'Regioni e Denominazioni';

  @override
  String get bottleDetailInfo => 'Informazioni e Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Finestra di Beva';

  @override
  String get bottleDetailTerroirMap => 'Mappa del Terroir e Origine';

  @override
  String get bottleDetailLabelPhoto => 'Foto originale dell\'etichetta';

  @override
  String get bottleDetailVintage => 'Annata';

  @override
  String get bottleDetailProducer => 'Produttore / Cantina';

  @override
  String get bottleDetailRegion => 'Regione';

  @override
  String get bottleDetailCountry => 'Paese';

  @override
  String get bottleDetailAppellation => 'Denominazione';

  @override
  String get bottleDetailGrapes => 'Vitigni';

  @override
  String get bottleDetailAlcohol => 'Gradazione alcolica';

  @override
  String get bottleDetailStock => 'Scorta';

  @override
  String get bottleDetailLocation => 'Posizione in cantina';

  @override
  String get bottleDetailRack => 'Scaffale';

  @override
  String get bottleDetailShelf => 'Ripiano';

  @override
  String get bottleDetailPurchasePrice => 'Prezzo d\'acquisto';

  @override
  String get bottleDetailEstimatedValue => 'Valore stimato';

  @override
  String get bottleDetailFoodPairings => 'Abbinamenti gastronomici consigliati';

  @override
  String get bottleDetailTastingNotes => 'Profilo Sommelier';

  @override
  String get bottleDetailDrinkButton => 'Stappa questa bottiglia';

  @override
  String get bottleDetailEdit => 'Modifica';

  @override
  String get bottleDetailDelete => 'Elimina';

  @override
  String get bottleDetailDeleteConfirm =>
      'Sei sicuro di voler eliminare definitivamente questa bottiglia dalla tua cantina?';

  @override
  String get deleteBottleTitle => 'Elimina Definitivamente';

  @override
  String get deleteBottleExplanation =>
      'Attenzione: l\'eliminazione rimuove in modo permanente la bottiglia dalla cantina e dallo storico.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Stappa / Bevi: archivia la bottiglia nello storico delle degustazioni, aggiorna le statistiche e conserva le note.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Elimina definitivamente: cancella completamente il record senza lasciare traccia (consigliato per errori, rotture o duplicati).';

  @override
  String get deleteBottleActionConfirm => 'Elimina Definitivamente';

  @override
  String get deleteBottleActionDrinkInstead => 'Stappa / Bevi invece';

  @override
  String get cancel => 'Annulla';

  @override
  String get confirm => 'Conferma';

  @override
  String get checkoutTitle => 'Degusta e Stappa dalla Cantina';

  @override
  String get checkoutSelectPrompt =>
      'Tocca per scegliere una bottiglia dalla cantina...';

  @override
  String get checkoutQtyOpened => 'Numero di bottiglie aperte';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'su $total in cantina';
  }

  @override
  String get checkoutRating => 'Valutazione di Degustazione';

  @override
  String get checkoutFoodPairing => 'Piatti e Cibi abbinati (opzionale)';

  @override
  String get checkoutFoodHint =>
      'es. Bistecca alla fiorentina, risotto ai funghi porcini...';

  @override
  String get checkoutNotes => 'Impressioni e Commenti di Degustazione';

  @override
  String get checkoutNotesHint => 'Aromi, equilibrio, persistenza, emozioni...';

  @override
  String get checkoutSubmit => 'Conferma degustazione';

  @override
  String get checkoutSuccess => 'Degustazione registrata con successo!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Buongiorno! Sono Chatmelier. Chiedimi consigli su abbinamenti cibo-vino, momenti di beva o suggerimenti basati sulle bottiglie che hai in cantina.';

  @override
  String get chatAnalyzing => 'Chatmelier sta analizzando la tua cantina...';

  @override
  String get chatInputHint => 'Chiedi a Chatmelier...';

  @override
  String get chatChipTonight => '🍷 Cosa dovrei bere stasera?';

  @override
  String get chatChipSteak => '🥩 Abbina una bottiglia alla bistecca';

  @override
  String get chatChipSeafood => '🐟 Miglior bianco per frutti di mare';

  @override
  String get chatChipPeak => '⏰ Quali bottiglie sono all\'apogeo?';

  @override
  String get journalTitle => 'Diario di Degustazione';

  @override
  String get journalEmpty => 'Nessuna degustazione registrata';

  @override
  String get journalEmptySub =>
      'Stappa e degusta una bottiglia dalla tua cantina per iniziare il diario';

  @override
  String journalTastedOn(String date) {
    return 'Degustato il $date';
  }

  @override
  String get statsTitle => 'Statistiche Cantina';

  @override
  String get statsTotalBottles => 'Bottiglie in Cantina';

  @override
  String get statsTotalValue => 'Valore della Cantina';

  @override
  String get statsBottlesEnjoyed => 'Bottiglie Degustate';

  @override
  String get statsByColor => 'Distribuzione per Tipologia';

  @override
  String get statsByMaturity => 'Distribuzione per Maturità';

  @override
  String get statsByRegion => 'Regioni Principali';

  @override
  String get statsByCountry => 'Paesi Principali';

  @override
  String get profileTitle => 'Profilo e Impostazioni';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileDisplayName => 'Nome visualizzato';

  @override
  String get profileDefaultCurrency => 'Valuta predefinita';

  @override
  String get profileLanguage => 'Lingua dell\'applicazione';

  @override
  String get profileLanguageSystem => 'Automatica (Sistema)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Valuta predefinita aggiornata: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Lingua aggiornata';

  @override
  String get profileLogout => 'Disconnetti';

  @override
  String get profileAbout => 'Informazioni su Chatmelier';

  @override
  String get scanTitle => 'Scansiona Etichetta';

  @override
  String get scanTakePhoto => 'Scatta foto';

  @override
  String get scanPickGallery => 'Scegli dalla galleria';

  @override
  String get scanAnalyzing =>
      'L\'IA di Chatmelier sta analizzando l\'etichetta...';

  @override
  String get scanIdentified => 'Vino identificato da Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Aggiungi alla mia cantina';

  @override
  String get loginTitle => 'Accedi';

  @override
  String get loginTagline => 'La tua Cantina Intelligente Condivisa con IA';

  @override
  String get loginTabMagicLink => '✉️ Link di Accesso';

  @override
  String get loginTabPassword => '🔑 Password';

  @override
  String get loginEmailLabel => 'Indirizzo email';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginSendMagicLink => 'Invia link di accesso';

  @override
  String get loginSignInButton => 'Accedi';

  @override
  String get loginOrDivider => 'OPPURE';

  @override
  String get loginGoogleButton => 'Continua con Google';

  @override
  String get loginRegisterLink => 'Non hai un account? Registrati';

  @override
  String get registerTitle => 'Crea Account';

  @override
  String get registerNameLabel => 'Nome visualizzato';

  @override
  String get registerSubmitButton => 'Crea il mio account';

  @override
  String get registerFillAllFields => 'Compila tutti i campi';

  @override
  String get registerWelcome => '🎉 Benvenuto su Chatmelier!';

  @override
  String get registerErrorGeneric => 'Errore durante la registrazione';

  @override
  String get authWelcome => 'Benvenuto su Chatmelier';

  @override
  String get authSubtitle =>
      'Il tuo assistente sommelier e gestore intelligente di cantina';

  @override
  String get authGoogle => 'Continua con Google';

  @override
  String get authMagicLink => 'Accedi con link email';

  @override
  String get authEmail => 'Indirizzo email';

  @override
  String get authNoAccount => 'Non hai un account? Registrati';

  @override
  String get authHaveAccount => 'Hai già un account? Accedi';

  @override
  String get changelogTitle => 'Note di Versione e Novità';

  @override
  String get changelogEmpty => 'Nessuna nota di versione disponibile.';

  @override
  String get scratchcardTitle => 'Mappa a Gratta e Vinci dei Terroir';

  @override
  String get profileChangelog => 'Cronologia Versioni e Novità';

  @override
  String get profileScratchcard => 'Mappa a Gratta e Vinci dei Terroir';

  @override
  String get navProfile => 'Profilo';

  @override
  String get quickActions => 'AZIONI RAPIDE';

  @override
  String get appSubtitle => 'Sommelier e Cantina';

  @override
  String get profileTabPalate => 'Palato';

  @override
  String get profileTabSettings => 'Impostazioni';

  @override
  String get profileTabTools => 'Strumenti';

  @override
  String get profileTabAccount => 'Account';

  @override
  String get profileTheme => 'Tema / Aspetto';

  @override
  String get profileThemeLight => 'Chiaro ☀️';

  @override
  String get profileThemeDark => 'Scuro 🌙';

  @override
  String get profileThemeSystem => 'Sistema ⚙️';

  @override
  String get profileFriends => 'Amici e Mappa dei Gusti 🍷';

  @override
  String get profileExport => 'Esporta Cantina e Perizia 📊';

  @override
  String get profileDeleteAccount => 'Elimina definitivamente l\'account';

  @override
  String get profileDeleteConfirmTitle => 'Elimina definitivamente';

  @override
  String get profileDeleteConfirmMsg =>
      'Questa azione è irreversibile. Tutti i tuoi dati verranno cancellati.';

  @override
  String get badgesGalleryTitle => 'Galleria dei Trofei';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total sbloccati • $pct% completato';
  }

  @override
  String get badgesFilterAll => 'Tutti';

  @override
  String get badgesEmpty => 'Nessun distintivo trovato in questa categoria.';

  @override
  String get badgesUnlockedChip => 'Sbloccato ✨';

  @override
  String get badgesStatusUnlocked => 'Distintivo sbloccato!';

  @override
  String get badgesStatusInProgress => 'In corso';

  @override
  String get badgesObjectiveLabel => 'Obiettivo:';

  @override
  String get badgesChatmelierLoreTitle => 'Scienza e Storia di Chatmelier';

  @override
  String get badgesCloseButton => 'Chiudi';

  @override
  String get badgesTierLabel => 'Grado';

  @override
  String get badgesShowcaseTitle => 'Trofei e Distintivi';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked su $total sbloccati';
  }

  @override
  String get badgesShowcaseGallery => 'Galleria';

  @override
  String get save => 'Salva';

  @override
  String get continueAnyway => 'Continua comunque';

  @override
  String get cellarDetected => 'Cantina rilevata: ';

  @override
  String proximityWifi(String ssid) {
    return 'Connesso al Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'Posizione GPS rilevata a $distance';
  }

  @override
  String get proximitySwitch => 'Passa a questa';

  @override
  String get proximityIgnore => 'Ignora';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Passato automaticamente a \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Cantina distante rilevata';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Sei attualmente connesso al Wi-Fi \"$ssid\" associato all\'altra tua cantina \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Ti trovi attualmente a circa $distance da \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nVuoi comunque aggiungere questa bottiglia alla cantina \"$cellar\"?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nVuoi comunque prelevare questa bottiglia dalla cantina \"$cellar\"?';
  }

  @override
  String get ratingExceptional => '🏆 Eccezionale';

  @override
  String get ratingRemarkable => '✨ Notevole';

  @override
  String get ratingVeryGood => '🍷 Ottimo';

  @override
  String get ratingPleasant => '👍 Piacevole';

  @override
  String get ratingPassable => 'Discreto';

  @override
  String get checkoutWhoTasted => 'Chi ha degustato questo vino con te?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'bottiglie',
      one: 'bottiglia',
    );
    return '$producer • In cantina: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Aggiungi un ospite';

  @override
  String get checkoutAddGuestHint => 'Aggiungi (Mamma, Papà...)';

  @override
  String get checkoutCloseAndTaste => 'Chiudi e degusta 🍷';

  @override
  String get checkoutSommelierThinking =>
      'Il sommelier sta preparando gli aneddoti...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Timer di aerazione attivo sulla schermata di blocco!';

  @override
  String get checkoutStartAerationTimer => 'Avvia timer ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Timer di aerazione';

  @override
  String get checkoutDelayedTonight => 'Stasera alle 22:00';

  @override
  String get checkoutDelayedTonightSub =>
      'Ideale dopo il pasto per assaporare il momento';

  @override
  String get checkoutDelayedTomorrow => 'Domani mattina alle 11:00';

  @override
  String get checkoutDelayedTomorrowSub =>
      'Per annotare le tue impressioni con calma';

  @override
  String get checkoutDelayedWeekend =>
      'Questo fine settimana (Sabato alle 11:00)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Prenditi il tuo tempo in un momento libero';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'Tra 2 ore ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Promemoria rapido al termine della degustazione';

  @override
  String get checkoutDelayedCustom => 'Scegli data e ora personalizzate...';

  @override
  String get reviewPackagingDetected => 'Formato confezione rilevato';

  @override
  String get reviewSingleBottleOnly => 'No, solo 1 bottiglia';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Sì, $count bottiglie';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Scorte aggiornate con successo! ($count bottiglie in cantina)';
  }

  @override
  String get reviewVintageYear => 'Annata / Anno di vendemmia';

  @override
  String get reviewNonVintage => 'Salta / Senza annata (NV)';

  @override
  String get reviewValidate => 'Conferma';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name aggiunta con successo alla cantina!';
  }

  @override
  String get reviewBottleAnalysis => 'Analisi della bottiglia';

  @override
  String get reviewDiscard => 'Elimina';

  @override
  String get reviewDiscardConfirmTitle => 'Annullare l\'inserimento?';

  @override
  String get reviewContinueEditing => 'Continua a modificare';

  @override
  String get reviewDiscardWithoutSaving => 'Esci senza salvare';

  @override
  String get reviewBottleDetails => 'Dettagli della bottiglia';

  @override
  String get reviewStockInCellar => 'Scorte in cantina';

  @override
  String get reviewStockAddition => 'Aggiungi';

  @override
  String get reviewStockNewTotal => 'Nuovo totale';

  @override
  String get reviewQuantityToAdd => 'Quantità da aggiungere:';

  @override
  String get reviewSeparateEntry =>
      'Crea una voce separata (scaffale o prezzo diverso)';

  @override
  String get reviewRetryAi => 'Riprova analisi IA';

  @override
  String get reviewEnlarge => 'Ingrandisci';

  @override
  String get reviewGeneralInfo => 'Informazioni generali';

  @override
  String get reviewOriginTerroir => 'Origine e Terroir';

  @override
  String get reviewQuantityPurchase => 'Quantità & Dettagli acquisto';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi rilevato e associato: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Impossibile rilevare il Wi-Fi (attiva la posizione o inserisci manualmente)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 Coordinate GPS acquisite ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'Posizione GPS non disponibile. Verifica le autorizzazioni.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Cantina \"$cellar\" creata con successo!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Errore durante la creazione: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 metri (molto preciso)';

  @override
  String get cellarRadiusRecommended => '300 metri (consigliato)';

  @override
  String get cellarRadius500m => '500 metri';

  @override
  String get cellarRadius1km => '1 chilometro';

  @override
  String get cellarRadius3km => '3 chilometri';

  @override
  String get cellarCreateButton => 'Crea cantina';

  @override
  String get cellarUseCurrentGps => 'Imposta con posizione GPS attuale';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Impostazioni cantina \"$cellar\" aggiornate';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Errore durante l\'aggiornamento: $error';
  }

  @override
  String get wineTypeRed => 'Vino Rosso 🍷';

  @override
  String get wineTypeWhite => 'Vino Bianco 🥂';

  @override
  String get wineTypeRose => 'Vino Rosato 🌸';

  @override
  String get wineTypeSparkling => 'Spumante / Bollicine 🍾';

  @override
  String get wineTypeDessert => 'Vino Dolce / Passito 🍯';

  @override
  String get bottleSizeCustom => 'Altra capacità…';

  @override
  String get bottleSizeCustomTitle => 'Capacità personalizzata';

  @override
  String get bottleSizeCustomLabel => 'Capacità in centilitri';

  @override
  String get bottleSizeCustomInvalid =>
      'Inserisci una capacità tra 1 e 3000 cl.';

  @override
  String get wineTypeLiqueur => 'Liquore 🍯';

  @override
  String get wineTypeSpirit => 'Distillati 🥃';

  @override
  String get wineTypeGrappa => 'Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Acquavite di Frutta 🍐';

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
  String get cellarCreateTitle => 'Crea una nuova cantina';

  @override
  String get cellarManageTitle => 'Gestisci cantina';

  @override
  String get cellarNameLabel => 'Nome della cantina *';

  @override
  String get cellarNameHint => 'es. Cantina di casa, Cantinetta in taverna';

  @override
  String get cellarNameRequired => 'Inserisci un nome';

  @override
  String get cellarLocationLabel => 'Località / Città (opzionale)';

  @override
  String get cellarLocationHint => 'es. Verona, Montalcino';

  @override
  String get cellarNicknameLabel => 'Soprannome / Stanza (opzionale)';

  @override
  String get cellarNicknameHint => 'es. Semininterrato, Cantinetta salotto';

  @override
  String get cellarDescriptionLabel => 'Descrizione (opzionale)';

  @override
  String get cellarDescriptionHint =>
      'es. Cantina sotterranea fresca, umidità 70%';

  @override
  String get cellarWifiLabel => 'Wi-Fi associato (opzionale)';

  @override
  String get cellarWifiHint => 'es. Wi-Fi-Cantina';

  @override
  String get cellarLinkCurrentWifi => 'Associa al Wi-Fi attuale';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Acquisisci Wi-Fi attuale';

  @override
  String get cellarRadiusLabel => 'Raggio di rilevamento GPS';

  @override
  String get cellarAutoDetectionHeader =>
      'Rilevamento & Transizione automatica';

  @override
  String get cellarAutoDetectionDesc =>
      'Collega la tua rete Wi-Fi o le coordinate GPS per passare automaticamente a questa cantina quando sei sul posto.';

  @override
  String get cellarLatitudeLabel => 'Latitudine';

  @override
  String get cellarLongitudeLabel => 'Longitudine';

  @override
  String get checkoutGuidedTasting => 'Degustazione guidata';

  @override
  String get checkoutGuidedTastingShared =>
      'Condividi le impressioni a turno o insieme';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analizza esame visivo, olfattivo e gustativo per affinare il tuo profilo';

  @override
  String get checkoutUncorkNowRateLater => 'Stappa ora, valuta dopo';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Prelievo immediato • Scegli l\'ora del promemoria (stasera, domani...)';

  @override
  String get checkoutUncorkAeration => 'Stappa & Timer aerazione';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Prelievo immediato • Si consigliano $minutes min di aerazione';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Prelievo immediato • Timer di decantazione o aerazione';

  @override
  String get checkoutSommelierServiceAdvice =>
      'Consigli di servizio del sommelier';

  @override
  String get checkoutHistoryAnecdotes => 'Storie & Aneddoti';

  @override
  String get checkoutNoDecanting => 'Nessuna decantazione necessaria';

  @override
  String get checkoutStoryTitle => 'La storia di questa bottiglia 📖';

  @override
  String get checkoutStorySubtitle =>
      'Aneddoti affascinanti da condividere a tavola';

  @override
  String get checkoutStoryTerroir => 'Terroir & Vitigni';

  @override
  String get checkoutStoryVintage => 'La storia dell\'annata';

  @override
  String get checkoutStoryTastingSecret => 'Segreto di degustazione';

  @override
  String get checkoutStoryTableAnecdote => 'Aneddoto da raccontare';

  @override
  String get checkoutJournalArchivedNotice =>
      'Tranquillo: questa bottiglia sarà archiviata con cura nel tuo Diario con foto e appunti.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Bottiglia stappata! Timer di aerazione ($minutes min) attivo sulla schermata di blocco.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'La bottiglia verrà stappata e prelevata subito. Conferma la durata dell\'aerazione prima del servizio:';

  @override
  String get checkoutRateWine => 'Valuta il vino';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Avvia ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Consiglio sommelier: aerare per $minutes min. Timer schermata di blocco pronto.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Promemoria programmato dopo la degustazione per registrare le impressioni.';

  @override
  String get checkoutBottleRemovedSuccess =>
      'Bottiglia prelevata dalla cantina!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Buona degustazione. Promemoria programmato $date per registrare le tue note.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'Il profilo gustativo di ciascun partecipante verrà arricchito automaticamente.';

  @override
  String checkoutCellarOf(String name) {
    return 'Cantina di $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Scorte: $count bt.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Aggiungi un familiare o un amico presente a questa degustazione (es. Mamma, Papà, Marco...).';

  @override
  String get checkoutAddGuestNameLabel => 'Nome / Soprannome';

  @override
  String get checkoutDelayedSheetTitle => 'Stappa e valuta più tardi';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'Quando vorresti ricevere il promemoria per le tue impressioni?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Stasera tra 2 ore ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Stasera alle 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'stasera alle $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'domani alle $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'il $date alle $time';
  }

  @override
  String get add => 'Aggiungi';

  @override
  String get cellarWinesTab => '🍷 Vini';

  @override
  String get cellarSpiritsTab => '🥃 Distillati';

  @override
  String get cellarPairWithDish => 'Quale vino per il mio piatto?';

  @override
  String get cellarCollapseAll => 'Comprimi tutto';

  @override
  String get cellarExpandAll => 'Espandi tutto';

  @override
  String get cellarSort => 'Ordina';

  @override
  String get cellarCategories => 'Categorie';

  @override
  String get cellarFavorites => 'Preferiti';

  @override
  String get cellarGridView => 'Griglia';

  @override
  String get cellarListView => 'Elenco';

  @override
  String get cellarClearFilters => 'Cancella filtri';

  @override
  String get cellarNoBottlesCategory => 'Nessuna bottiglia in questa categoria';

  @override
  String get cellarNoBottlesCriteria =>
      'Nessuna bottiglia corrisponde a questi criteri';

  @override
  String get feedbackSheetTitle => 'Feedback tester e annotazione';

  @override
  String get feedbackStylus => 'Penna:';

  @override
  String get feedbackUndo => 'Annulla ultimo tratto';

  @override
  String get feedbackClear => 'Cancella tutto';

  @override
  String get feedbackHint =>
      'Cerchia l\'area e descrivi il feedback o il bug...';

  @override
  String get feedbackSubmit => 'Invia segnalazione';

  @override
  String get feedbackSubmitting => 'Invio in corso...';

  @override
  String get feedbackNoScreenshot => 'Nessuno screenshot disponibile';

  @override
  String get feedbackEmptyError =>
      'Aggiungi un commento o disegna sullo screenshot.';

  @override
  String get feedbackSuccess =>
      'Grazie per il tuo feedback! 🍷 Segnalazione inviata.';

  @override
  String feedbackError(String error) {
    return 'Errore durante l\'invio: $error';
  }

  @override
  String get checkoutFastExit => 'Prelievo rapido senza questionario ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Prelievo in corso...';

  @override
  String get checkoutRatingSubtitle =>
      'Assegna il tuo voto complessivo dopo la degustazione';

  @override
  String get checkoutRecommendedBadge => 'Consigliato';

  @override
  String get tastingWhoTastedTitle => '👥 Chi ha degustato questo vino?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Seleziona i partecipanti. I profili di gusto si arricchiranno automaticamente.';

  @override
  String get tastingHowToTaste => 'Come degustare?';

  @override
  String get tastingEachTurn => 'Ognuno a turno';

  @override
  String get tastingEachTurnDesc =>
      '📱 Passando il telefono: ciascuno risponde separatamente al proprio ritmo.';

  @override
  String get tastingTogether => 'Tutti insieme';

  @override
  String get tastingTogetherDesc =>
      '🥂 Un unico questionario compilato insieme per tutti i commensali.';

  @override
  String get tastingBlindMode => 'Modalità Degustazione alla Cieca';

  @override
  String get tastingBlindModeDesc =>
      'Nasconde il nome del vino e attiva un quiz interattivo al tavolo con svelamento finale!';

  @override
  String get tastingPrimaryProfile => 'Profilo principale';

  @override
  String get tastingAppInstalled => 'App installata 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questionari completati',
      one: '1 questionario completato',
      zero: '0 questionari completati',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle =>
      '👃 L\'Esame Olfattivo — Espressione degli aromi';

  @override
  String get tastingStepNezSubtitle =>
      'Fai roteare il calice e cogli i sentori che salgono al naso.';

  @override
  String get tastingFaultTitle => 'Il vino ha uno di questi odori?';

  @override
  String get tastingFaultSubtitle =>
      'Se sì, la bottiglia è difettosa: non dipende dal tuo palato né dallo stile del vino.';

  @override
  String get tastingFaultCorkLabel => '📦 Cartone bagnato, cantina ammuffita';

  @override
  String get tastingFaultCorkExplain =>
      'Sentore di tappo (TCA). Il vino non c\'entra e non migliorerà con l\'aerazione: al ristorante puoi chiedere un\'altra bottiglia.';

  @override
  String get tastingFaultOxidationLabel => '🍎 Mela ammaccata, aceto, sherry';

  @override
  String get tastingFaultOxidationExplain =>
      'Ossidazione. La bottiglia ha preso aria, spesso per un tappo difettoso o un affinamento troppo lungo.';

  @override
  String get tastingFaultReductionLabel => '🥚 Fiammifero, uovo, cavolo';

  @override
  String get tastingFaultReductionExplain =>
      'Riduzione. Buona notizia: spesso svanisce con l\'aria. Decanta venti minuti e riassaggia prima di giudicare.';

  @override
  String get tastingFaultExcluded =>
      'Questa degustazione non conterà per il tuo profilo di gusto.';

  @override
  String get tastingAromaIntensity => 'Intensità aromatica:';

  @override
  String get tastingAromaDiscreet => '🤫 Sottile / Delicata';

  @override
  String get tastingAromaExplosive => '💥 Esplosiva / Intensa';

  @override
  String get tastingStepBoucheTitle => '⚖️ L\'Esame Gustativo — Equilibrio';

  @override
  String get tastingStepBoucheSubtitle =>
      'Descrivi la consistenza, la freschezza e l\'armonia in bocca.';

  @override
  String get tastingAcidity => 'Acidità / Freschezza:';

  @override
  String get tastingAcidityFreshness => 'Acidità & Vivacità:';

  @override
  String get tastingAcidityFlat => '🫠 Piatto / Seduto';

  @override
  String get tastingAciditySharp => '⚡ Tagliente / Fresco';

  @override
  String get tastingTannins => 'Tannini:';

  @override
  String get tastingTanninsSilky => '🧶 Setosi / Morbidi';

  @override
  String get tastingTanninsGrippy => '💪 Fitti / Vigorosi';

  @override
  String get tastingMinerality => 'Mineralità & Sapidità:';

  @override
  String get tastingMineralityRound => '🧈 Rotondo / Grasso';

  @override
  String get tastingMineralityCrisp => '🪨 Minerale / Teso';

  @override
  String get tastingEffervescence => 'Effervescenza (Perlage):';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fine / Carezzevole';

  @override
  String get tastingEffervescenceVibrant => '🎆 Vivace / Cremoso';

  @override
  String get tastingBody => 'Corpo / Struttura:';

  @override
  String get tastingBodyLight => '🍃 Leggero / Agile';

  @override
  String get tastingBodyFull => '🏋️ Corposo / Robusto';

  @override
  String get tastingLength => 'Persistenza / Lunghezza:';

  @override
  String get tastingLengthShort => '⏱️ Corta';

  @override
  String get tastingLengthLong => '♾️ Molto persistente';

  @override
  String get tastingStepVerdictTitle => '✅ Verdetto finale';

  @override
  String get sipSectionTitle => '🍷 Il sorso';

  @override
  String get tasteConfidenceUnknown =>
      'Non conosco ancora il tuo palato: l\'alone mostra ciò che sto indovinando.';

  @override
  String tasteConfidenceKnown(String percent) {
    return 'Palato noto al $percent %. La sfocatura segna ciò che sto ancora indovinando.';
  }

  @override
  String tasteConfidenceFrontier(String axis) {
    return 'Ciò che conosco meno: $axis.';
  }

  @override
  String get sipSectionSubtitle =>
      'Due tocchi, e questo calice insegna qualcosa al tuo profilo di gusto.';

  @override
  String get tastingBuyAgain => 'Ricompreresti questa bottiglia?';

  @override
  String get tastingBuyAgainYes => '🤩 Assolutamente sì!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Forse';

  @override
  String get tastingBuyAgainNo => '👎 No, grazie';

  @override
  String get tastingIdealMoment => 'Occasione ideale per questo vino?';

  @override
  String get tastingMomentApero => '🥂 Aperitivo';

  @override
  String get tastingMomentMeal => '🍽️ Pranzo informale';

  @override
  String get tastingMomentDinner => '🎩 Cena importante';

  @override
  String get tastingMomentRomantic => '🕯️ Cena romantica';

  @override
  String get tastingMomentSolo => '🧘 Momento di relax personale';

  @override
  String get tastingWhatLiked => 'Cosa ti è piaciuto di più:';

  @override
  String get tastingWhatDisliked => 'Cosa ti è piaciuto di meno:';

  @override
  String get tastingOccasionLabel =>
      'Occasione / Ricordo condiviso (opzionale) ✨';

  @override
  String get tastingOccasionHint =>
      'es. Compleanno, Cena a lume di candela, Rimpatriata...';

  @override
  String get tastingAddPhoto => 'Aggiungi una foto ricordo della tavola 📸';

  @override
  String get tastingPhotoSaved => 'Foto ricordo salvata 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Voto finale & Impressione';

  @override
  String get tastingStepImpressionSubtitle =>
      'Dopo aver gustato profumi e sapore, assegna il tuo punteggio globale.';

  @override
  String get tastingOverallFeeling => 'La tua impressione generale:';

  @override
  String get tastingScoreOutOf10 => 'Voto su 10:';

  @override
  String get tastingCompletedTitle => 'Degustazione completata & registrata!';

  @override
  String get tastingCompletedSubtitle =>
      'I profili di gusto sono stati aggiornati con successo ✨';

  @override
  String get tastingBottleRemoved =>
      'Bottiglia stappata e prelevata dalla cantina';

  @override
  String get tastingConsultDebrief =>
      'Guarda il debriefing del sommelier (Sfumature nascoste & Terroir)';

  @override
  String get tastingFinishButton => 'Fine ✨';

  @override
  String get tastingNextTaster => 'Conferma → Prossimo degustatore';

  @override
  String get tastingConfirmAndFinish => 'Conferma & Concludi ✨';

  @override
  String get tastingQuitTitle => 'Abbandonare il questionario?';

  @override
  String get tastingQuitMessage => 'Le tue risposte non verranno salvate.';

  @override
  String get tastingContinue => 'Continua';

  @override
  String get tastingQuit => 'Esci';

  @override
  String tastingStartCount(int count) {
    return 'Inizia ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Sincronizzato con l\'app di $name ✨';
  }

  @override
  String get tastingProfileEnriched => 'Profilo gustativo arricchito';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Acutezza sensoriale: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle =>
      'Origine dei sapori & Segreti del vino';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Scopri da dove provengono profumi, colore e corpo del tuo vino';

  @override
  String get tastingBlindQuizTitle => 'Quiz al tavolo alla cieca 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. Qual è la regione di origine? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. Qual è il vitigno principale? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Età presunta / Annata? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Prezzo stimato? 💶';

  @override
  String get tastingBlindRevealTitle =>
      'Grande svelamento della bottiglia misteriosa 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Punteggio del quiz alla cieca: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Debriefing enologico e molecolare';

  @override
  String get tastingSensoryAcuity => 'ACUTEZZA SENSORIALE';

  @override
  String tastingPrecision(int score) {
    return 'Precisione $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. CONCORDANZA & FIRMA DEL CRU';

  @override
  String get tastingWhatYouDetected => 'COSA HAI RILEVATO:';

  @override
  String get tastingArchetypeSignature => 'FIRMA ARCHETIPICA DEL VINO:';

  @override
  String get tastingHiddenNuancesTitle =>
      'SFUMATURE SOTTILI DA COGLIERE NEL PROSSIMO CALICE:';

  @override
  String get tastingPillarsTitle => '2. SCIENZA ENOLOGICA & MOLECOLE';

  @override
  String get tastingPillarsSubtitle =>
      'Perché questo vino presenta questa struttura, questi aromi e questo colore?';

  @override
  String get tastingChatWithSommelier =>
      'Approfondisci i segreti di vinificazione con Chatmelier';

  @override
  String get aromaFruitsRouges => 'Frutti rossi (fragola, ciliegia)';

  @override
  String get aromaFruitsNoirs => 'Frutti scuri (mora, ribes nero)';

  @override
  String get aromaFruitsBlancs => 'Frutta bianca/gialla (pesca, mela, pera)';

  @override
  String get aromaAgrumes => 'Agrumi (limone, pompelmo)';

  @override
  String get aromaFloral => 'Floreale (viola, rosa, acacia)';

  @override
  String get aromaVegetal => 'Vegetale ed erbaceo (peperone, erba tagliata)';

  @override
  String get aromaEpicesDouces => 'Spezie dolci (cannella, noce moscata)';

  @override
  String get aromaEpicesVives => 'Spezie piccanti / Pepe nero';

  @override
  String get aromaBoise => 'Note tostate & Vaniglia (rovere)';

  @override
  String get aromaBeurre => 'Burro & Brioche';

  @override
  String get aromaMineral => 'Minerale (pietra focaia, gesso)';

  @override
  String get aromaMiel => 'Miele & Confettura';

  @override
  String get aromaChocolat => 'Cioccolato fondente & Caffè';

  @override
  String get aromaFumee => 'Affumicato & Fumé';

  @override
  String get emojiDisliked => 'Non piaciuto';

  @override
  String get emojiMeh => 'Così così';

  @override
  String get emojiDecent => 'Discreto';

  @override
  String get emojiVeryGood => 'Molto buono';

  @override
  String get emojiLoved => 'Entusiasta!';

  @override
  String get likedFreshness => 'Freschezza e beva';

  @override
  String get likedFruitiness => 'Frutto succoso';

  @override
  String get likedComplexity => 'Complessità';

  @override
  String get likedElegance => 'Eleganza e classe';

  @override
  String get likedPower => 'Corpo e calore';

  @override
  String get likedSilky => 'Tannino vellutato';

  @override
  String get likedOriginality => 'Personalità e tipicità';

  @override
  String get likedFoodPairing => 'Sinergia con il cibo';

  @override
  String get likedMinerality => 'Sapidità minerale';

  @override
  String get likedLength => 'Persistenza finale';

  @override
  String get likedDisappointing => 'Nulla / Deludente 😕';

  @override
  String get dislikedTooAcidic => 'Troppo acido';

  @override
  String get dislikedTooTannic => 'Troppo tannico / astringente';

  @override
  String get dislikedTooOaked => 'Troppo boisé / vanigliato';

  @override
  String get dislikedTooAlcoholic => 'Troppo alcolico / caldo';

  @override
  String get dislikedTooThin => 'Troppo leggero / acquoso';

  @override
  String get dislikedLacksFruit => 'Poco frutto';

  @override
  String get dislikedTooSweet => 'Troppo dolce';

  @override
  String get dislikedTooExpensive => 'Troppo caro per la qualità';

  @override
  String get dislikedNothing => 'Nulla, era semplicemente perfetto!';

  @override
  String get tastingStepTasters => 'Degustatori';

  @override
  String get tastingStepNezNav => 'Naso';

  @override
  String get tastingStepBoucheNav => 'Bocca';

  @override
  String get tastingStepVerdictNav => 'Verdetto';

  @override
  String get tastingStepRatingNav => 'Voto';

  @override
  String get tastingBack => 'Indietro';

  @override
  String get tastingNext => 'Avanti';

  @override
  String get tastingSaving => 'Salvataggio...';

  @override
  String get tastingHeaderTitle => 'Questionario di degustazione';

  @override
  String tastingAnswersOf(String name) {
    return 'Risposte di $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Passa il telefono a $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Le tue risposte sono state registrate.\nOra tocca a $name.';
  }

  @override
  String get tastingDictateButton => 'Detta impressioni al tavolo 🎙️';

  @override
  String get tastingDictateHint =>
      'Parla o scrivi spontaneamente: l\'IA Chatmelier pre-compilerà aromi e bilanciamento in bocca!';

  @override
  String get tastingDictateMicTip =>
      'Suggerimento: attiva il microfono sulla tastiera per dettare a voce!';

  @override
  String get tastingTakePhoto => 'Scatta una foto a tavola 📸';

  @override
  String get tastingChooseGallery => 'Scegli dalla galleria 🖼️';

  @override
  String get tastingConclaveSummary => 'Sintesi del conclave';

  @override
  String get tastingCellarMaster => 'Maestro di Cantina';

  @override
  String get tastingGuestTaster => 'Degustatore Ospite';

  @override
  String tastingProfileTag(String type) {
    return 'Profilo: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Degustazione libera registrata.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Aspetto: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Struttura: $structure ($caudalies caudalie)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Molecole chiave: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Fattore chiave: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Vitigni: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Impressioni di degustazione applicate dall\'IA Chatmelier ✨';

  @override
  String get tastingBlindYourPredictions =>
      'Riepilogo delle previsioni al tavolo:';

  @override
  String get tastingBlindGuessCorrect => 'Indovinato! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Fai le tue previsioni prima del grande svelamento finale!';

  @override
  String tastingStartTaster(String name) {
    return 'Tocca a te, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Bravissimo!';

  @override
  String tastingQuizWas(String answer) {
    return '(La risposta corretta era: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'es.: Paolo entusiasta con 8.5/10, note di mora e sottobosco. Elena dà 7/10 trovando il vino leggermente acido...';

  @override
  String get tastingDictateAnalyzing => 'Analisi in corso...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Analizza & Applica alle schede ✨';

  @override
  String get tastingFormatExpress => 'Formato Express (1 pagina) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Voto, aromi principali e verdetto rapido in 30s';

  @override
  String get tastingFormatSommelier => 'Formato Sommelier (Dettagliato) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Analisi approfondita di naso, palato, persistenza e terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'Cos\'è una caudalie? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalie = 1 secondo di persistenza del sapore dopo aver deglutito o sputato.\n• Da 1 a 4 caudalie: vino fresco e leggero\n• Da 5 a 7 caudalie: splendido equilibrio\n• Da 8 a 12+ caudalie: vino grandioso d\'eccellenza!';

  @override
  String get tastingAddCustomAroma => '+ Aroma personalizzato';

  @override
  String get tastingCustomAromaDialogTitle => 'Aggiungi un aroma preciso';

  @override
  String get tastingCustomAromaHint =>
      'es. Pietra focaia affumicata, Mora selvatica, Rosa appassita...';

  @override
  String get tastingFoodSynergyTitle => 'Sinergia con il cibo 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Sublime';

  @override
  String get tastingSynergyHarmonious => '👍 Armonico';

  @override
  String get tastingSynergyNeutral => '😐 Neutro';

  @override
  String get tastingSynergyClashing => '⚡ Contrastante';

  @override
  String get checkoutFastRatingTitle => 'Voto rapido in 1 tocco (opzionale):';

  @override
  String get checkoutActionTastingTitle => 'Degusta questo vino';

  @override
  String get checkoutActionTastingSubtitle =>
      'Formato express (1 pagina) o dettagliato da sommelier';

  @override
  String get checkoutActionDeferredRemind => 'Ricordamelo più tardi 🌙';

  @override
  String get checkoutActionAerationTimer => 'Timer di aerazione ⏱️';

  @override
  String get externalTastingTitle => 'Degustazione fuori cantina';

  @override
  String get externalTastingSubtitle =>
      'Ristorante, bar, a casa di amici... senza toccare le tue scorte';

  @override
  String get externalTastingWithWhom => 'Con chi stai degustando questo vino?';

  @override
  String get externalTastingWhere => 'Dove stai degustando questo vino?';

  @override
  String get externalTastingSearchingPlaces =>
      'Cerco ristoranti, bar e amici intorno a te...';

  @override
  String get externalTastingGpsActive => 'GPS attivo';

  @override
  String externalTastingPlaceGuess(String place) {
    return 'Sembra che tu sia da: $place';
  }

  @override
  String get externalTastingFavoritePlaceNote =>
      'Luogo preferito memorizzato automaticamente da Chatmelier';

  @override
  String get externalTastingChangePlace => 'Cambia luogo';

  @override
  String get externalTastingOtherPlace => 'A casa di un amico / Altro luogo...';

  @override
  String get externalTastingNoPlaceFound =>
      'Nessun ristorante rilevato nelle immediate vicinanze.';

  @override
  String get externalTastingPlaceLabel => 'Da chi o dove ti trovi? *';

  @override
  String get externalTastingPlaceHint =>
      'Es.: Da Dimitri, Dai miei genitori, Casa in campagna...';

  @override
  String externalTastingRememberPlace(String place) {
    return 'Memorizza \"$place\" in questa posizione GPS per le prossime visite';
  }

  @override
  String get externalTastingDefaultPlace => 'Al ristorante';

  @override
  String get externalTastingAiIdentifyTitle =>
      'Identifica con l\'IA (bar, ristorante, lavagna)';

  @override
  String get externalTastingAiIdentifyDesc =>
      'Scrivi qualche parola (es.: \"Saint-Joseph Coursodon 2021\" o \"Bandol Terrebrune\") per precompilare la scheda.';

  @override
  String get externalTastingAiIdentifyHint =>
      'Es.: Saint-Joseph 2021 Coursodon...';

  @override
  String get externalTastingDetect => 'Rileva';

  @override
  String get externalTastingAiScanningSub =>
      'Rilevamento di produttore, annata, vitigni e note...';

  @override
  String get externalTastingPhotoAdded => 'Foto dell\'etichetta aggiunta';

  @override
  String get externalTastingPhotoAddedSub =>
      'Visibile nel tuo diario di degustazione';

  @override
  String get externalTastingReplacePhoto => 'Sostituisci';

  @override
  String get externalTastingDeletePhoto => 'Elimina la foto';

  @override
  String get externalTastingScanLabelTitle =>
      'Fotografa l\'etichetta (scansione IA)';

  @override
  String get externalTastingScanLabelSub =>
      'Riconoscimento automatico del vino e aggiunta al diario';

  @override
  String get externalTastingScanLabelButton => 'Scansione IA';

  @override
  String get externalTastingTakePhotoSub =>
      'Fotografa l\'etichetta con la fotocamera';

  @override
  String get externalTastingPickGallerySub => 'Seleziona una foto esistente';

  @override
  String get externalTastingWineNameLabel => 'Nome del vino *';

  @override
  String get externalTastingWineNameHint => 'Es.: Domaine de Terrebrune';

  @override
  String get externalTastingProducerHint => 'Es.: Famille Delon';

  @override
  String get externalTastingRegionLabel => 'Regione / Denominazione';

  @override
  String get externalTastingRegionHint => 'Es.: Bandol rosso';

  @override
  String get externalTastingRatingLabel => 'Voto di degustazione:';

  @override
  String get externalTastingFavorite => 'Colpo di fulmine';

  @override
  String get externalTastingFoodLabel => 'Abbinamento cibo-vino';

  @override
  String get externalTastingNotesLabel => 'Impressioni e aromi percepiti';

  @override
  String get externalTastingNotesHint =>
      'Es.: Frutta nera intensa, tannini setosi, ottima persistenza...';

  @override
  String get externalTastingSubmit => 'Salva e valuta ✨';

  @override
  String get externalTastingNameRequired => 'Indica almeno il nome del vino.';

  @override
  String get externalTastingSaved =>
      'Degustazione fuori cantina salvata! Chatmelier se ne ricorderà.';

  @override
  String externalTastingAiRecognized(String name) {
    return '✨ Bottiglia riconosciuta dall\'IA: $name';
  }

  @override
  String externalTastingAiFilled(String name) {
    return '✨ Scheda completata dall\'IA: $name';
  }

  @override
  String externalTastingAnalysisError(String error) {
    return 'Errore di analisi: $error';
  }

  @override
  String externalTastingSaveError(String error) {
    return 'Errore: $error';
  }
}
