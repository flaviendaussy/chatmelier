// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Catalan Valencian (`ca`).
class AppLocalizationsCa extends AppLocalizations {
  AppLocalizationsCa([String locale = 'ca']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'El meu Celler';

  @override
  String get navCellar => 'Celler';

  @override
  String get navChat => 'Xat';

  @override
  String get navJournal => 'Històric';

  @override
  String get navStats => 'Estadístiques';

  @override
  String get actionMenuTitle => 'Accions del Celler';

  @override
  String get actionAddBottle => 'Afegir una ampolla';

  @override
  String get actionAddBottleSub => 'Escriure etiqueta o entrada manual';

  @override
  String get actionCheckoutBottle => 'Tastar / Obrir ampolla';

  @override
  String get actionCheckoutBottleSub =>
      'Registrar tast i descomptar de l\'estoc';

  @override
  String get actionLookupWine => 'Consultar / Identificar un vi';

  @override
  String get actionLookupWineSub => 'Descobriment i anàlisi instantània amb IA';

  @override
  String get searchWinePlaceholder => 'Cercar anyada, celler, denominació...';

  @override
  String get emptyCellarTitle => 'El teu celler està buit';

  @override
  String get emptyCellarSub =>
      'Escaneja la teva primera ampolla per començar la col·lecció';

  @override
  String get emptyCellarButton => 'Afegir la meva primera ampolla';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ampolles',
      one: '1 ampolla',
      zero: '0 ampolles',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Valor total';

  @override
  String get filterAll => 'Tots';

  @override
  String get filterRed => 'Negre';

  @override
  String get filterWhite => 'Blanc';

  @override
  String get filterRose => 'Rosat';

  @override
  String get filterSparkling => 'Escumós';

  @override
  String get filterSheetTitle => 'Filtres del Celler';

  @override
  String get filterReset => 'Restablir';

  @override
  String get filterApply => 'Aplicar filtres';

  @override
  String get filterMaturity => 'Estat de Maduresa / Apogeu';

  @override
  String get maturityAtPeak => 'En el seu apogeu';

  @override
  String get maturityDrinkSoon => 'Beure aviat';

  @override
  String get maturityAging => 'En criança';

  @override
  String get maturityTooYoung => 'Massa jove';

  @override
  String get maturityPastPeak => 'Passat';

  @override
  String get filterContinents => 'Continents';

  @override
  String get filterCountries => 'Països';

  @override
  String get filterGrapes => 'Varietats de raïm';

  @override
  String get filterAppellations => 'Regions i Denominacions';

  @override
  String get bottleDetailInfo => 'Informació i Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Finestra de Consum';

  @override
  String get bottleDetailTerroirMap => 'Mapa del Terroir i Origen';

  @override
  String get bottleDetailLabelPhoto => 'Foto original de l\'etiqueta';

  @override
  String get bottleDetailVintage => 'Anyada';

  @override
  String get bottleDetailProducer => 'Celler / Productor';

  @override
  String get bottleDetailRegion => 'Regió';

  @override
  String get bottleDetailCountry => 'País';

  @override
  String get bottleDetailAppellation => 'Denominació d\'Origen';

  @override
  String get bottleDetailGrapes => 'Varietats de raïm';

  @override
  String get bottleDetailAlcohol => 'Graduació alcohòlica';

  @override
  String get bottleDetailStock => 'Estoc';

  @override
  String get bottleDetailLocation => 'Ubicació al celler';

  @override
  String get bottleDetailRack => 'Prestatge';

  @override
  String get bottleDetailShelf => 'Balda';

  @override
  String get bottleDetailPurchasePrice => 'Preu de compra';

  @override
  String get bottleDetailEstimatedValue => 'Valor estimat';

  @override
  String get bottleDetailFoodPairings => 'Maridatges recomanats';

  @override
  String get bottleDetailTastingNotes => 'Perfil de Sommelier';

  @override
  String get bottleDetailDrinkButton => 'Obrir aquesta ampolla';

  @override
  String get bottleDetailEdit => 'Editar';

  @override
  String get bottleDetailDelete => 'Eliminar';

  @override
  String get bottleDetailDeleteConfirm =>
      'Segur que vols eliminar definitivament aquesta ampolla del teu celler?';

  @override
  String get deleteBottleTitle => 'Eliminar Definitivament';

  @override
  String get deleteBottleExplanation =>
      'Avís: eliminar esborrarà permanentment aquesta ampolla del celler i de l\'historial.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Obrir / Beure: arxiva l\'ampolla a l\'historial de tast, actualitza les estadístiques i conserva les teves notes.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Eliminar definitivament: esborra completament el registre sense deixar rastre (recomanat per errors, ampolles trencades o duplicats).';

  @override
  String get deleteBottleActionConfirm => 'Eliminar Definitivament';

  @override
  String get deleteBottleActionDrinkInstead =>
      'Obrir / Beure en comptes d\'eliminar';

  @override
  String get cancel => 'Cancel·lar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get checkoutTitle => 'Tastar i Obrir del Celler';

  @override
  String get checkoutSelectPrompt => 'Toca per triar una ampolla del celler...';

  @override
  String get checkoutQtyOpened => 'Nombre d\'ampolles obertes';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'de $total al celler';
  }

  @override
  String get checkoutRating => 'Puntuació del Tast';

  @override
  String get checkoutFoodPairing => 'Plats i Àpats associats (opcional)';

  @override
  String get checkoutFoodHint => 'ex. Carn a la brasa, arròs de bolets...';

  @override
  String get checkoutNotes => 'Impressions i Notes de Tast';

  @override
  String get checkoutNotesHint =>
      'Aromes, equilibri, persistència, emocions...';

  @override
  String get checkoutSubmit => 'Confirmar tast';

  @override
  String get checkoutSuccess => 'Tast registrat correctament!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Hola! Sóc en Chatmelier. Demana\'m maridatges, recomanacions de beure o suggeriments segons les ampolles que tens al celler.';

  @override
  String get chatAnalyzing => 'En Chatmelier està analitzant el teu celler...';

  @override
  String get chatInputHint => 'Pregunta a en Chatmelier...';

  @override
  String get chatChipTonight => '🍷 Què hauria de beure aquesta nit?';

  @override
  String get chatChipSteak => '🥩 Maridar amb un bon entrecot';

  @override
  String get chatChipSeafood => '🐟 Millor blanc per a marisc';

  @override
  String get chatChipPeak => '⏰ Quines ampolles estan en el seu apogeu?';

  @override
  String get journalTitle => 'Diari de Tast';

  @override
  String get journalEmpty => 'Cap tast registrat encara';

  @override
  String get journalEmptySub =>
      'Obre i tasta una ampolla del teu celler per començar el diari';

  @override
  String journalTastedOn(String date) {
    return 'Tastat el $date';
  }

  @override
  String get statsTitle => 'Estadístiques del Celler';

  @override
  String get statsTotalBottles => 'Ampolles al Celler';

  @override
  String get statsTotalValue => 'Valor del Celler';

  @override
  String get statsBottlesEnjoyed => 'Ampolles Gaudiades';

  @override
  String get statsByColor => 'Distribució per Tipus';

  @override
  String get statsByMaturity => 'Distribució per Maduresa';

  @override
  String get statsByRegion => 'Principals Regions';

  @override
  String get statsByCountry => 'Principals Països';

  @override
  String get profileTitle => 'Perfil i Configuració';

  @override
  String get profileEmail => 'Correu electrònic';

  @override
  String get profileDisplayName => 'Nom visible';

  @override
  String get profileDefaultCurrency => 'Moneda per defecte';

  @override
  String get profileLanguage => 'Idioma de l\'aplicació';

  @override
  String get profileLanguageSystem => 'Automàtic (Sistema)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Moneda per defecte actualitzada: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Idioma actualitzat';

  @override
  String get profileLogout => 'Tancar sessió';

  @override
  String get profileAbout => 'Sobre Chatmelier';

  @override
  String get scanTitle => 'Escanejar Etiqueta';

  @override
  String get scanTakePhoto => 'Fer foto';

  @override
  String get scanPickGallery => 'Triar de la galeria';

  @override
  String get scanAnalyzing =>
      'La IA de Chatmelier està analitzant l\'etiqueta...';

  @override
  String get scanIdentified => 'Vi identificat per en Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Afegir al meu celler';

  @override
  String get loginTitle => 'Iniciar Sessió';

  @override
  String get loginTagline => 'El teu Celler Intel·ligent Compartit amb IA';

  @override
  String get loginTabMagicLink => '✉️ Enllaç d\'Accés';

  @override
  String get loginTabPassword => '🔑 Contrasenya';

  @override
  String get loginEmailLabel => 'Correu electrònic';

  @override
  String get loginPasswordLabel => 'Contrasenya';

  @override
  String get loginSendMagicLink => 'Enviar enllaç d\'accés';

  @override
  String get loginSignInButton => 'Iniciar Sessió';

  @override
  String get loginOrDivider => 'O';

  @override
  String get loginGoogleButton => 'Continuar amb Google';

  @override
  String get loginRegisterLink => 'No tens compte? Registra\'t';

  @override
  String get registerTitle => 'Crear Compte';

  @override
  String get registerNameLabel => 'Nom visible';

  @override
  String get registerSubmitButton => 'Crear el meu compte';

  @override
  String get registerFillAllFields => 'Omple tots els camps';

  @override
  String get registerWelcome => '🎉 Benvingut a Chatmelier!';

  @override
  String get registerErrorGeneric => 'Error en crear el compte';

  @override
  String get authWelcome => 'Benvingut a Chatmelier';

  @override
  String get authSubtitle =>
      'El teu sommelier intel·ligent i gestor de celler personal';

  @override
  String get authGoogle => 'Continuar amb Google';

  @override
  String get authMagicLink => 'Accedir amb enllaç per correu';

  @override
  String get authEmail => 'Correu electrònic';

  @override
  String get authNoAccount => 'No tens compte? Registra\'t';

  @override
  String get authHaveAccount => 'Ja tens compte? Inicia sessió';

  @override
  String get changelogTitle => 'Novetats i Registre de Canvis';

  @override
  String get changelogEmpty => 'Cap nota de versió disponible.';

  @override
  String get scratchcardTitle => 'Mapa per Rascar dels Terroirs';

  @override
  String get profileChangelog => 'Historial de Versions i Novetats';

  @override
  String get profileScratchcard => 'Mapa per Rascar dels Terroirs';

  @override
  String get navBar => 'Bar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get quickActions => 'ACCIONS RÀPIDES';

  @override
  String get appSubtitle => 'Sommelier i Celler';

  @override
  String get profileTabPalate => 'Paladar';

  @override
  String get profileTabSettings => 'Ajustos';

  @override
  String get profileTabTools => 'Eines';

  @override
  String get profileTabAccount => 'Compte';

  @override
  String get profileTheme => 'Tema / Aparença';

  @override
  String get profileThemeLight => 'Clar ☀️';

  @override
  String get profileThemeDark => 'Fosc 🌙';

  @override
  String get profileThemeSystem => 'Sistema ⚙️';

  @override
  String get profileFriends => 'Amics i Mapa de Gustos 🍷';

  @override
  String get profileExport => 'Exportar Celler i Informe 📊';

  @override
  String get profileDeleteAccount => 'Eliminar definitivament el meu compte';

  @override
  String get profileDeleteConfirmTitle => 'Eliminar definitivament';

  @override
  String get profileDeleteConfirmMsg =>
      'Aquesta acció és irreversible. Totes les vostres dades seran eliminades.';

  @override
  String get badgesGalleryTitle => 'Galeria de Trofeus';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total desbloquejats • $pct% completat';
  }

  @override
  String get badgesFilterAll => 'Tots';

  @override
  String get badgesEmpty => 'No s\'han trobat medalles en aquesta categoria.';

  @override
  String get badgesUnlockedChip => 'Desbloquejat ✨';

  @override
  String get badgesStatusUnlocked => 'Medalla desbloquejada!';

  @override
  String get badgesStatusInProgress => 'En progrés';

  @override
  String get badgesObjectiveLabel => 'Objectiu:';

  @override
  String get badgesChatmelierLoreTitle => 'Ciència i Història de Chatmelier';

  @override
  String get badgesCloseButton => 'Tancar';

  @override
  String get badgesTierLabel => 'Rang';

  @override
  String get badgesShowcaseTitle => 'Trofeus i Medalles';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked de $total desbloquejats';
  }

  @override
  String get badgesShowcaseGallery => 'Galeria';

  @override
  String get cocktailsTitle => 'Bar i Còctels';

  @override
  String get cocktailsReadyToShake => 'A punt per sacsejar';

  @override
  String get cocktailsMissingOne => 'En falta 1';

  @override
  String get cocktailsManagePantry => 'Gestionar Reserva';

  @override
  String get cocktailsResetPantry => 'Restablir Reserva';
}
