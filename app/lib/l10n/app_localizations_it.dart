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
  String get navBar => 'Bar';

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
  String get cocktailsTitle => 'Bar e Cocktail';

  @override
  String get cocktailsReadyToShake => 'Pronti da shakerare';

  @override
  String get cocktailsMissingOne => '1 mancante';

  @override
  String get cocktailsManagePantry => 'Gestisci Riserva';

  @override
  String get cocktailsResetPantry => 'Ripristina Riserva';
}
