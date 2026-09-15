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
  String get save => 'Desa';

  @override
  String get continueAnyway => 'Continua igualment';

  @override
  String get cellarDetected => 'Celler detectat: ';

  @override
  String proximityWifi(String ssid) {
    return 'Connectat a la xarxa Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'Ubicació GPS detectada a $distance';
  }

  @override
  String get proximitySwitch => 'Canvia';

  @override
  String get proximityIgnore => 'Ignora';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 S\'ha canviat automàticament a \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Celler llunyà detectat';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Actualment estàs connectat a la xarxa Wi-Fi \"$ssid\" associada amb el teu altre celler \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Et trobes a aproximadament $distance de \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nEncara vols afegir aquesta ampolla al celler \"$cellar\"?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nEncara vols retirar aquesta ampolla del celler \"$cellar\"?';
  }

  @override
  String get ratingExceptional => '🏆 Excepcional';

  @override
  String get ratingRemarkable => '✨ Notable';

  @override
  String get ratingVeryGood => '🍷 Molt bo';

  @override
  String get ratingPleasant => '👍 Agradable';

  @override
  String get ratingPassable => 'Acceptable';

  @override
  String get checkoutWhoTasted => 'Qui ha tastat aquest vi amb tu?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'ampolles',
      one: 'ampolla',
    );
    return '$producer • En estoc: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Afegeix un convidat';

  @override
  String get checkoutAddGuestHint => 'Afegeix (Mare, Pare...)';

  @override
  String get checkoutCloseAndTaste => 'Tanca i gaudeix 🍷';

  @override
  String get checkoutSommelierThinking =>
      'El sommelier està preparant anècdotes...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Temporitzador d\'airejament actiu a la pantalla de bloqueig!';

  @override
  String get checkoutStartAerationTimer => 'Inicia temporitzador ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Temporitzador d\'airejament';

  @override
  String get checkoutDelayedTonight => 'Aquesta nit a les 22:00';

  @override
  String get checkoutDelayedTonightSub =>
      'Ideal després de l\'àpat per pair i recordar el moment';

  @override
  String get checkoutDelayedTomorrow => 'Demà al matí a les 11:00';

  @override
  String get checkoutDelayedTomorrowSub =>
      'Per anotar les teves impressions amb calma';

  @override
  String get checkoutDelayedWeekend =>
      'Aquest cap de setmana (Dissabte a les 11:00)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Pren-te el teu temps en una estona lliure';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'En 2 hores ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Recordatori ràpid en acabar el tast';

  @override
  String get checkoutDelayedCustom => 'Tria data i hora personalitzades...';

  @override
  String get reviewPackagingDetected => 'Format d\'embalatge detectat';

  @override
  String get reviewSingleBottleOnly => 'No, només 1 ampolla';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Sí, $count ampolles';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Estoc actualitzat amb èxit! ($count ampolles al celler)';
  }

  @override
  String get reviewVintageYear => 'Anyada / Any de collita';

  @override
  String get reviewNonVintage => 'Omet / Sense anyada (NV)';

  @override
  String get reviewValidate => 'Confirma';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name afegida amb èxit al celler!';
  }

  @override
  String get reviewBottleAnalysis => 'Anàlisi de l\'ampolla';

  @override
  String get reviewDiscard => 'Descarta';

  @override
  String get reviewDiscardConfirmTitle => 'Descartar l\'entrada?';

  @override
  String get reviewContinueEditing => 'Continua editant';

  @override
  String get reviewDiscardWithoutSaving => 'Surt sense desar';

  @override
  String get reviewBottleDetails => 'Detalls de l\'ampolla';

  @override
  String get reviewStockInCellar => 'Estoc al celler';

  @override
  String get reviewStockAddition => 'Afegeix';

  @override
  String get reviewStockNewTotal => 'Nou total';

  @override
  String get reviewQuantityToAdd => 'Quantitat a afegir:';

  @override
  String get reviewSeparateEntry =>
      'Crea una entrada separada (prestatge o preu diferent)';

  @override
  String get reviewRetryAi => 'Reintenta anàlisi IA';

  @override
  String get reviewEnlarge => 'Amplia';

  @override
  String get reviewGeneralInfo => 'Informació general';

  @override
  String get reviewOriginTerroir => 'Origen & Terroir';

  @override
  String get reviewQuantityPurchase => 'Quantitat & Detalls de compra';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi detectat i vinculat: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'No s\'ha pogut detectar el Wi-Fi (activa la ubicació o introdueix-lo manualment)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 Coordenades GPS capturades ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'Ubicació GPS no disponible. Comprova els permisos.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Celler \"$cellar\" creat amb èxit!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Error durant la creació: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 metres (molt precís)';

  @override
  String get cellarRadiusRecommended => '300 metres (recomanat)';

  @override
  String get cellarRadius500m => '500 metres';

  @override
  String get cellarRadius1km => '1 quilòmetre';

  @override
  String get cellarRadius3km => '3 quilòmetres';

  @override
  String get cellarCreateButton => 'Crea el celler';

  @override
  String get cellarUseCurrentGps => 'Defineix amb la posició GPS actual';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Paràmetres del celler \"$cellar\" actualitzats';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Error en actualitzar: $error';
  }

  @override
  String get wineTypeRed => 'Vi Negre 🍷';

  @override
  String get wineTypeWhite => 'Vi Blanc 🥂';

  @override
  String get wineTypeRose => 'Vi Rosat 🌸';

  @override
  String get wineTypeSparkling => 'Escumós / Cava 🍾';

  @override
  String get wineTypeDessert => 'Vi Dolç / Generós 🍯';

  @override
  String get wineTypeLiqueur => 'Licor 🍯';

  @override
  String get wineTypeSpirit => 'Destil·lats 🥃';

  @override
  String get wineTypeGrappa => 'Grappa / Marc 🍇';

  @override
  String get wineTypeEauDeVie => 'Aguardent de Fruita 🍐';

  @override
  String get wineTypeWhisky => 'Whisky 🥃';

  @override
  String get wineTypeRum => 'Rom 🏴‍☠️';

  @override
  String get wineTypeGin => 'Ginebra 🍸';

  @override
  String get wineTypeVodka => 'Vodka 🧊';

  @override
  String get wineTypeTequila => 'Tequila 🌵';

  @override
  String get wineTypeCognac => 'Cognac / Brandi 🍷';

  @override
  String get cellarCreateTitle => 'Crea un nou celler';

  @override
  String get cellarManageTitle => 'Gestiona el celler';

  @override
  String get cellarNameLabel => 'Nom del celler *';

  @override
  String get cellarNameHint => 'ex. Celler de Casa, Vinoteca Menjador';

  @override
  String get cellarNameRequired => 'Introdueix un nom';

  @override
  String get cellarLocationLabel => 'Ubicació / Ciutat (opcional)';

  @override
  String get cellarLocationHint => 'ex. Barcelona, Priorat';

  @override
  String get cellarNicknameLabel => 'Sobrenom / Sala (opcional)';

  @override
  String get cellarNicknameHint => 'ex. Soterrani, Nevera de vins';

  @override
  String get cellarDescriptionLabel => 'Descripció (opcional)';

  @override
  String get cellarDescriptionHint =>
      'ex. Cova subterrània fresca, humitat 70%';

  @override
  String get cellarWifiLabel => 'Wi-Fi associat (opcional)';

  @override
  String get cellarWifiHint => 'ex. Wi-Fi-Celler';

  @override
  String get cellarLinkCurrentWifi => 'Vincula al Wi-Fi actual';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Captura el Wi-Fi actual';

  @override
  String get cellarRadiusLabel => 'Radi de detecció GPS';

  @override
  String get cellarAutoDetectionHeader => 'Detecció i Transició Automàtica';

  @override
  String get cellarAutoDetectionDesc =>
      'Vincula la teva xarxa Wi-Fi o coordenades GPS per canviar automàticament a aquest celler en arribar-hi.';

  @override
  String get cellarLatitudeLabel => 'Latitud';

  @override
  String get cellarLongitudeLabel => 'Longitud';

  @override
  String get checkoutGuidedTasting => 'Tast guiat';

  @override
  String get checkoutGuidedTastingShared =>
      'Comparteix impressions per torns o conjuntament';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analitza aspecte visual, nas i boca i perfecciona el teu perfil';

  @override
  String get checkoutUncorkNowRateLater => 'Obre ara, valora després';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Sortida immediata • Tria l\'hora del recordatori (avui, demà...)';

  @override
  String get checkoutUncorkAeration => 'Obre & Temporitzador d\'airejament';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Sortida immediata • $minutes min d\'airejament recomanats';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Sortida immediata • Temporitzador de decantació o airejament';

  @override
  String get checkoutSommelierServiceAdvice =>
      'Consells de servei del sommelier';

  @override
  String get checkoutHistoryAnecdotes => 'Històries & Anècdotes';

  @override
  String get checkoutNoDecanting => 'No cal decantació';

  @override
  String get checkoutStoryTitle => 'La història d\'aquesta ampolla 📖';

  @override
  String get checkoutStorySubtitle =>
      'Anècdotes captivadores per compartir a taula';

  @override
  String get checkoutStoryTerroir => 'Terroir & Varietats';

  @override
  String get checkoutStoryVintage => 'La història de l\'anyada';

  @override
  String get checkoutStoryTastingSecret => 'Secret de tast';

  @override
  String get checkoutStoryTableAnecdote => 'Anècdota per a la taula';

  @override
  String get checkoutJournalArchivedNotice =>
      'Tranquil: aquesta ampolla s\'arxivarà al teu Diari de Tast amb fotos i notes.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Ampolla oberta! Temporitzador d\'airejament ($minutes min) actiu a la pantalla de bloqueig.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'L\'ampolla es retirarà immediatament. Confirma la durada de l\'airejament:';

  @override
  String get checkoutRateWine => 'Valora el vi';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Temporitzador ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Consell sommelier: airejar $minutes min. Temporitzador llest.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Recordatori programat després del tast per recollir les teves impressions.';

  @override
  String get checkoutBottleRemovedSuccess => 'Ampolla retirada del celler!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Gaudeix del tast. Recordatori programat per al $date.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'El perfil de gust de cada comensal s\'enriquirà automàticament.';

  @override
  String checkoutCellarOf(String name) {
    return 'Celler de $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Estoc: $count amp.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Afegeix un familiar o amic present en aquest tast (ex. Mare, Pare, Laia...).';

  @override
  String get checkoutAddGuestNameLabel => 'Nom / Sobrenom';

  @override
  String get checkoutDelayedSheetTitle => 'Obre i valora més tard';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'Quan vols rebre el recordatori per a les teves impressions?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Aquesta nit en 2 hores ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Aquesta nit a les 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'aquesta nit a les $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'demà a les $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'el $date a les $time';
  }

  @override
  String get add => 'Afegir';

  @override
  String get cellarWinesTab => '🍷 Vins';

  @override
  String get cellarSpiritsTab => '🥃 Destil·lats';

  @override
  String get cellarPairWithDish => 'Quin vi per al meu plat?';

  @override
  String get cellarCollapseAll => 'Plegar tot';

  @override
  String get cellarExpandAll => 'Desplegar tot';

  @override
  String get cellarSort => 'Ordenar';

  @override
  String get cellarCategories => 'Categories';

  @override
  String get cellarFavorites => 'Preferits';

  @override
  String get cellarGridView => 'Graella';

  @override
  String get cellarListView => 'Llista';

  @override
  String get cellarClearFilters => 'Esborrar filtres';

  @override
  String get cellarNoBottlesCategory => 'Cap ampolla en aquesta categoria';

  @override
  String get cellarNoBottlesCriteria =>
      'Cap ampolla coincideix amb aquests criteris';

  @override
  String get feedbackSheetTitle => 'Comentaris del tester i anotació';

  @override
  String get feedbackStylus => 'Llapis:';

  @override
  String get feedbackUndo => 'Desfer l\'últim traç';

  @override
  String get feedbackClear => 'Esborrar tot';

  @override
  String get feedbackHint =>
      'Encercla la zona i descriu els teus comentaris o error...';

  @override
  String get feedbackSubmit => 'Enviar informe';

  @override
  String get feedbackSubmitting => 'Enviant...';

  @override
  String get feedbackNoScreenshot => 'Cap captura de pantalla disponible';

  @override
  String get feedbackEmptyError =>
      'Si us plau, afegeix un comentari o dibuixa a la captura.';

  @override
  String get feedbackSuccess =>
      'Gràcies pels teus comentaris! 🍷 Informe enviat.';

  @override
  String feedbackError(String error) {
    return 'Error en enviar: $error';
  }

  @override
  String get checkoutFastExit => 'Sortida ràpida sense qüestionari ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Processant sortida...';

  @override
  String get checkoutRatingSubtitle =>
      'Atorga la teva nota global després de tastar';

  @override
  String get checkoutRecommendedBadge => 'Recomanat';

  @override
  String get tastingWhoTastedTitle => '👥 Qui ha tastat aquest vi?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Selecciona els tastadors. Els perfils de gust s\'enriquiran automàticament.';

  @override
  String get tastingHowToTaste => 'Com tastar?';

  @override
  String get tastingEachTurn => 'Cadascú al seu torn';

  @override
  String get tastingEachTurnDesc =>
      '📱 Passant el telèfon: cadascú respon per separat al seu ritme.';

  @override
  String get tastingTogether => 'Tots plegats';

  @override
  String get tastingTogetherDesc =>
      '🥂 Un únic qüestionari completat entre tots a la taula.';

  @override
  String get tastingBlindMode => 'Mode Tast a Cegues';

  @override
  String get tastingBlindModeDesc =>
      'Amaga el nom del vi i comença un concurs interactiu amb revelació final!';

  @override
  String get tastingPrimaryProfile => 'Perfil principal';

  @override
  String get tastingAppInstalled => 'Aplicació instal·lada 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count qüestionaris completats',
      one: '1 qüestionari completat',
      zero: '0 qüestionaris completats',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 L\'Examen Olfactiu — Aromes';

  @override
  String get tastingStepNezSubtitle =>
      'Fes girar la copa i capta les aromes que se\'n desprenen.';

  @override
  String get tastingAromaIntensity => 'Intensitat aromàtica:';

  @override
  String get tastingAromaDiscreet => '🤫 Subtil / Discreta';

  @override
  String get tastingAromaExplosive => '💥 Explosiva / Potent';

  @override
  String get tastingStepBoucheTitle => '⚖️ L\'Examen Gustatiu — Equilibri';

  @override
  String get tastingStepBoucheSubtitle =>
      'Descriu la textura, la frescor i l\'harmonia en boca.';

  @override
  String get tastingAcidity => 'Sensació d\'acidesa:';

  @override
  String get tastingAcidityFreshness => 'Acidesa i Frescor:';

  @override
  String get tastingAcidityFlat => '🫠 Pla / Desmanegat';

  @override
  String get tastingAciditySharp => '⚡ Viu / Esmolat';

  @override
  String get tastingTannins => 'Tanins:';

  @override
  String get tastingTanninsSilky => '🧶 Sedosos / Amables';

  @override
  String get tastingTanninsGrippy => '💪 Ferms / Estructurats';

  @override
  String get tastingMinerality => 'Mineralitat i Vivor:';

  @override
  String get tastingMineralityRound => '🧈 Rodó / Greixós';

  @override
  String get tastingMineralityCrisp => '🪨 Mineral / Precís';

  @override
  String get tastingEffervescence => 'Efervescència (Bambolla):';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fina / Delicada';

  @override
  String get tastingEffervescenceVibrant => '🎆 Viva / Cremosa';

  @override
  String get tastingBody => 'Cos / Estructura:';

  @override
  String get tastingBodyLight => '🍃 Lleuger / Àgil';

  @override
  String get tastingBodyFull => '🏋️ Robust / Corpulent';

  @override
  String get tastingLength => 'Persistència / Longitud:';

  @override
  String get tastingLengthShort => '⏱️ Curta';

  @override
  String get tastingLengthLong => '♾️ Molt perllongada';

  @override
  String get tastingStepVerdictTitle => '✅ Veredicte final';

  @override
  String get tastingBuyAgain => 'Tornaries a comprar aquesta ampolla?';

  @override
  String get tastingBuyAgainYes => '🤩 I tant!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Potser';

  @override
  String get tastingBuyAgainNo => '👎 No, gràcies';

  @override
  String get tastingIdealMoment => 'Moment ideal per a aquest vi?';

  @override
  String get tastingMomentApero => '🥂 Aperitiu';

  @override
  String get tastingMomentMeal => '🍽️ Àpat informal';

  @override
  String get tastingMomentDinner => '🎩 Sopar de gala';

  @override
  String get tastingMomentRomantic => '🕯️ Sopar romàntic';

  @override
  String get tastingMomentSolo => '🧘 Moment de calma en solitud';

  @override
  String get tastingWhatLiked => 'El que més t\'ha agradat:';

  @override
  String get tastingWhatDisliked => 'El que menys t\'ha convençut:';

  @override
  String get tastingOccasionLabel => 'Ocasió / Record compartit (opcional) ✨';

  @override
  String get tastingOccasionHint =>
      'ex. Aniversari, Sopar amb espelmes, Retrobament...';

  @override
  String get tastingAddPhoto => 'Afegeix una foto de record de la taula 📸';

  @override
  String get tastingPhotoSaved => 'Foto desada 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Puntuació final i Impressió';

  @override
  String get tastingStepImpressionSubtitle =>
      'Després de gaudir del nas i la boca, atorga la teva nota global.';

  @override
  String get tastingOverallFeeling => 'La teva impressió general:';

  @override
  String get tastingScoreOutOf10 => 'Nota sobre 10:';

  @override
  String get tastingCompletedTitle => 'Tast finalitzat i desat!';

  @override
  String get tastingCompletedSubtitle =>
      'Els perfils de gust s\'han actualitzat amb èxit ✨';

  @override
  String get tastingBottleRemoved => 'Ampolla oberta i retirada del celler';

  @override
  String get tastingConsultDebrief =>
      'Mira l\'anàlisi del sommelier (Matisos ocults i Terroir)';

  @override
  String get tastingFinishButton => 'Finalitza ✨';

  @override
  String get tastingNextTaster => 'Valida → Següent tastador';

  @override
  String get tastingConfirmAndFinish => 'Valida i Conclou ✨';

  @override
  String get tastingQuitTitle => 'Vols sortir del qüestionari?';

  @override
  String get tastingQuitMessage => 'Les teves respostes actuals no es desaran.';

  @override
  String get tastingContinue => 'Continua';

  @override
  String get tastingQuit => 'Surt';

  @override
  String tastingStartCount(int count) {
    return 'Comença ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Sincronitzat amb l\'aplicació de $name ✨';
  }

  @override
  String get tastingProfileEnriched => 'Perfil gustatiu enriquit';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Agudesa sensorial: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle => 'Origen dels sabors i Secrets del vi';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Descobreix d\'on provenen les aromes, el color i l\'estructura del vi';

  @override
  String get tastingBlindQuizTitle => 'Concurs de tast a cegues a taula 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. Quina és la regió d\'origen? 🌍';

  @override
  String get tastingBlindQuizQ2 =>
      '2. Quina és la varietat principal de raïm? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Anyada estimada o edat del vi? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Preu estimat al mercat? 💶';

  @override
  String get tastingBlindRevealTitle =>
      'Gran revelació de l\'ampolla misteriosa 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Puntuació del concurs a cegues: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Anàlisi enològica i molecular';

  @override
  String get tastingSensoryAcuity => 'AGUDESA SENSORIAL';

  @override
  String tastingPrecision(int score) {
    return 'Precisió $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. CONCORDANÇA I SEGELL DEL CRU';

  @override
  String get tastingWhatYouDetected => 'EL QUE HAS DETECTAT:';

  @override
  String get tastingArchetypeSignature => 'SIGNATURA ARQUETÍPICA DEL VI:';

  @override
  String get tastingHiddenNuancesTitle =>
      'MATISOS SUBTILS PER A LA TEVA PROPERA COPA:';

  @override
  String get tastingPillarsTitle => '2. CIÈNCIA ENOLÒGICA I MOLÈCULES';

  @override
  String get tastingPillarsSubtitle =>
      'Per què aquest vi té aquesta estructura, aquestes aromes i aquest color?';

  @override
  String get tastingChatWithSommelier =>
      'Aprofundeix en els secrets enològics amb Chatmelier';

  @override
  String get aromaFruitsRouges => 'Fruits vermells (maduixa, cirera)';

  @override
  String get aromaFruitsNoirs => 'Fruits negres (mora, grosella negra)';

  @override
  String get aromaFruitsBlancs => 'Fruita blanca i d\'os (préssec, pera, poma)';

  @override
  String get aromaAgrumes => 'Cítrics (llimona, aranja)';

  @override
  String get aromaFloral => 'Floral (violeta, rosa)';

  @override
  String get aromaVegetal => 'Vegetal i herbes (pebrot, sotabosc)';

  @override
  String get aromaEpicesDouces => 'Espècies dolces (canyella, nou moscada)';

  @override
  String get aromaEpicesVives => 'Espècies picants (pebre negre)';

  @override
  String get aromaBoise => 'Roure i Vainilla (criança)';

  @override
  String get aromaBeurre => 'Mantega i Brioix';

  @override
  String get aromaMineral => 'Mineral (pedra foguera, guix)';

  @override
  String get aromaMiel => 'Mel i Confitura';

  @override
  String get aromaChocolat => 'Xocolata negra i Cafè';

  @override
  String get aromaFumee => 'Fumat i Torrat';

  @override
  String get emojiDisliked => 'No m\'ha agradat';

  @override
  String get emojiMeh => 'Passable';

  @override
  String get emojiDecent => 'Correcte';

  @override
  String get emojiVeryGood => 'Molt bo';

  @override
  String get emojiLoved => 'M\'ha encantat!';

  @override
  String get likedFreshness => 'La frescor';

  @override
  String get likedFruitiness => 'La fruita';

  @override
  String get likedComplexity => 'La complexitat';

  @override
  String get likedElegance => 'L\'elegància';

  @override
  String get likedPower => 'La potència';

  @override
  String get likedSilky => 'La textura sedosa';

  @override
  String get likedOriginality => 'L\'originalitat';

  @override
  String get likedFoodPairing => 'El maridatge';

  @override
  String get likedMinerality => 'La mineralitat';

  @override
  String get likedLength => 'La persistència';

  @override
  String get likedDisappointing => 'Res / Decepcionant 😕';

  @override
  String get dislikedTooAcidic => 'Massa àcid';

  @override
  String get dislikedTooTannic => 'Massa tànic';

  @override
  String get dislikedTooOaked => 'Massa roure / avainillat';

  @override
  String get dislikedTooAlcoholic => 'Massa alcohòlic';

  @override
  String get dislikedTooThin => 'Massa lleuger';

  @override
  String get dislikedLacksFruit => 'Manca de fruita';

  @override
  String get dislikedTooSweet => 'Massa dolç';

  @override
  String get dislikedTooExpensive => 'Massa car per a la qualitat';

  @override
  String get dislikedNothing => 'Res, era absolutament impecable!';

  @override
  String get tastingStepTasters => 'Tastadors';

  @override
  String get tastingStepNezNav => 'Nas';

  @override
  String get tastingStepBoucheNav => 'Boca';

  @override
  String get tastingStepVerdictNav => 'Veredicte';

  @override
  String get tastingStepRatingNav => 'Nota';

  @override
  String get tastingBack => 'Enrere';

  @override
  String get tastingNext => 'Següent';

  @override
  String get tastingSaving => 'Desant...';

  @override
  String get tastingHeaderTitle => 'Qüestionari de tast';

  @override
  String tastingAnswersOf(String name) {
    return 'Respostes de $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Passa el telèfon a $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'S\'han desat les teves respostes.\nAra li toca a $name.';
  }

  @override
  String get tastingDictateButton => 'Dicta impressions de la taula 🎙️';

  @override
  String get tastingDictateHint =>
      'Parla o escriu lliurement: la IA Chatmelier completarà les aromes i l\'equilibri en boca!';

  @override
  String get tastingDictateMicTip =>
      'Consell: activa el micròfon del teclat per dictar en veu alta!';

  @override
  String get tastingTakePhoto => 'Fes una foto de la taula 📸';

  @override
  String get tastingChooseGallery => 'Tria de la galeria 🖼️';

  @override
  String get tastingConclaveSummary => 'Resum del tast';

  @override
  String get tastingCellarMaster => 'Mestre de Celler';

  @override
  String get tastingGuestTaster => 'Tastador Convidat';

  @override
  String tastingProfileTag(String type) {
    return 'Perfil: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Nota de tast lliure registrada.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Aspecte: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Estructura: $structure ($caudalies caudalies)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Molècules clau: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Factor determinant: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Varietats: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Impressions aplicades per Chatmelier AI ✨';

  @override
  String get tastingBlindYourPredictions => 'Resum de prediccions a cegues:';

  @override
  String get tastingBlindGuessCorrect => 'Encertat! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Fes les teves prediccions abans de destapar l\'etiqueta!';

  @override
  String tastingStartTaster(String name) {
    return 'Som-hi, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Bravo!';

  @override
  String tastingQuizWas(String answer) {
    return '(La resposta era: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'ex.: En Joan fascinat amb 8.5/10, notes de mora i sotabosc. La Maria li ha posat un 7/10 trobant l\'acidesa una mica alta...';

  @override
  String get tastingDictateAnalyzing => 'Analitzant...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Analitza i Aplica a les fitxes ✨';

  @override
  String get tastingFormatExpress => 'Format Exprés (1 pàgina) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Nota, aromes clau i veredicte ràpid en 30s';

  @override
  String get tastingFormatSommelier => 'Format Sommelier (Detallat) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Anàlisi aprofundida de nas, boca, persistència i terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'Què és una caudalie? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalie = 1 segon de persistència del sabor després d\'empassar o escopir.\n• D\'1 a 4 caudalies: vi fresc i lleuger\n• De 5 a 7 caudalies: gran equilibri\n• De 8 a 12+ caudalies: un vi excepcional!';

  @override
  String get tastingAddCustomAroma => '+ Aroma personalitzada';

  @override
  String get tastingCustomAromaDialogTitle => 'Afegeix una aroma concreta';

  @override
  String get tastingCustomAromaHint =>
      'ex. Pedra foguera fumada, Mora silvestre, Rosa seca...';

  @override
  String get tastingFoodSynergyTitle => 'Sinergia amb el menjar 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Sublim';

  @override
  String get tastingSynergyHarmonious => '👍 Harmoniosa';

  @override
  String get tastingSynergyNeutral => '😐 Neutra';

  @override
  String get tastingSynergyClashing => '⚡ Discordant';

  @override
  String get checkoutFastRatingTitle => 'Puntuació ràpida en 1 toc (opcional):';

  @override
  String get checkoutActionTastingTitle => 'Tastar aquest vi';

  @override
  String get checkoutActionTastingSubtitle =>
      'Format exprés (1 pàgina) o detallat de sommelier';

  @override
  String get checkoutActionDeferredRemind => 'Recorda-m\'ho més tard 🌙';

  @override
  String get checkoutActionAerationTimer => 'Temporitzador d\'airejament ⏱️';
}
