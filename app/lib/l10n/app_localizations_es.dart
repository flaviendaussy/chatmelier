// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'Mi Bodega';

  @override
  String get navCellar => 'Bodega';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'Historial';

  @override
  String get navStats => 'Estadísticas';

  @override
  String get actionMenuTitle => 'Acciones de Bodega';

  @override
  String get actionAddBottle => 'Añadir una botella';

  @override
  String get actionAddBottleSub => 'Escanear etiqueta o entrada manual';

  @override
  String get actionCheckoutBottle => 'Catar / Descorchar botella';

  @override
  String get actionCheckoutBottleSub =>
      'Registrar cata y descontar del inventario';

  @override
  String get actionLookupWine => 'Consultar / Identificar vino';

  @override
  String get actionLookupWineSub =>
      'Descubrimiento y análisis instantáneo con IA';

  @override
  String get searchWinePlaceholder => 'Buscar añada, bodega, denominación...';

  @override
  String get emptyCellarTitle => 'Tu bodega está vacía';

  @override
  String get emptyCellarSub =>
      'Escanea tu primera botella para comenzar tu colección';

  @override
  String get emptyCellarButton => 'Añadir mi primera botella';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count botellas',
      one: '1 botella',
      zero: '0 botellas',
    );
    return '$_temp0';
  }

  @override
  String get cellarTotalValue => 'Valor total';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterRed => 'Tinto';

  @override
  String get filterWhite => 'Blanco';

  @override
  String get filterRose => 'Rosado';

  @override
  String get filterSparkling => 'Espumoso';

  @override
  String get filterSheetTitle => 'Filtros de Bodega';

  @override
  String get filterReset => 'Restablecer';

  @override
  String get filterApply => 'Aplicar filtros';

  @override
  String get filterMaturity => 'Estado de Madurez / Apogeo';

  @override
  String get maturityAtPeak => 'En su apogeo';

  @override
  String get maturityDrinkSoon => 'Consumir pronto';

  @override
  String get maturityAging => 'En guarda';

  @override
  String get maturityTooYoung => 'Demasiado joven';

  @override
  String get maturityPastPeak => 'Pasado de fecha';

  @override
  String get filterContinents => 'Continentes';

  @override
  String get filterCountries => 'Países';

  @override
  String get filterGrapes => 'Variedades de uva';

  @override
  String get filterAppellations => 'Regiones y Denominaciones';

  @override
  String get bottleDetailInfo => 'Información y Terruño';

  @override
  String get bottleDetailDrinkingWindow => 'Ventana de Consumo';

  @override
  String get bottleDetailTerroirMap => 'Mapa de Terruño y Origen';

  @override
  String get bottleDetailLabelPhoto => 'Foto original de la etiqueta';

  @override
  String get bottleDetailVintage => 'Añada';

  @override
  String get bottleDetailProducer => 'Bodega / Productor';

  @override
  String get bottleDetailRegion => 'Región';

  @override
  String get bottleDetailCountry => 'País';

  @override
  String get bottleDetailAppellation => 'Denominación de Origen';

  @override
  String get bottleDetailGrapes => 'Variedades de uva';

  @override
  String get bottleDetailAlcohol => 'Grado alcohólico';

  @override
  String get bottleDetailStock => 'Existencias';

  @override
  String get bottleDetailLocation => 'Ubicación en bodega';

  @override
  String get bottleDetailRack => 'Estante';

  @override
  String get bottleDetailShelf => 'Balda';

  @override
  String get bottleDetailPurchasePrice => 'Precio de compra';

  @override
  String get bottleDetailEstimatedValue => 'Valor estimado';

  @override
  String get bottleDetailFoodPairings => 'Maridajes recomendados';

  @override
  String get bottleDetailTastingNotes => 'Perfil de Sumiller';

  @override
  String get bottleDetailDrinkButton => 'Descorchar esta botella';

  @override
  String get bottleDetailEdit => 'Editar';

  @override
  String get bottleDetailDelete => 'Eliminar';

  @override
  String get bottleDetailDeleteConfirm =>
      '¿Estás seguro de que deseas eliminar permanentemente esta botella de tu bodega?';

  @override
  String get deleteBottleTitle => 'Eliminar Definitivamente';

  @override
  String get deleteBottleExplanation =>
      'Advertencia: eliminar borrará permanentemente todo registro de esta botella de tu bodega e historial.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Descorchar / Beber: archiva la botella en tu historial de cata, actualiza estadísticas y guarda tus notas.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Eliminar definitivamente: borra completamente el registro sin dejar rastro (recomendado para errores, botellas rotas o duplicadas).';

  @override
  String get deleteBottleActionConfirm => 'Eliminar Definitivamente';

  @override
  String get deleteBottleActionDrinkInstead => 'Descorchar / Beber en su lugar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get checkoutTitle => 'Catar y Descorchar de la Bodega';

  @override
  String get checkoutSelectPrompt =>
      'Toca para elegir una botella de tu bodega...';

  @override
  String get checkoutQtyOpened => 'Número de botellas abiertas';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'de $total en la bodega';
  }

  @override
  String get checkoutRating => 'Puntuación de Cata';

  @override
  String get checkoutFoodPairing => 'Comida y Platos acompañantes (opcional)';

  @override
  String get checkoutFoodHint => 'ej. Chuletón a la brasa, risotto de setas...';

  @override
  String get checkoutNotes => 'Impresiones y Notas de Cata';

  @override
  String get checkoutNotesHint =>
      'Aromas, equilibrio, persistencia, sensaciones...';

  @override
  String get checkoutSubmit => 'Confirmar cata';

  @override
  String get checkoutSuccess => '¡Cata registrada con éxito!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      '¡Hola! Soy Chatmelier. Pídeme maridajes, recomendaciones para beber hoy o sugerencias basadas en las botellas que tienes en tu bodega.';

  @override
  String get chatAnalyzing => 'Chatmelier está analizando tu bodega...';

  @override
  String get chatInputHint => 'Pregunta a Chatmelier...';

  @override
  String get chatChipTonight => '🍷 ¿Qué debería beber esta noche?';

  @override
  String get chatChipSteak => '🥩 Maridar con un buen filete';

  @override
  String get chatChipSeafood => '🐟 Mejor blanco para marisco';

  @override
  String get chatChipPeak => '⏰ ¿Qué botellas están en su apogeo?';

  @override
  String get journalTitle => 'Cuaderno de Cata';

  @override
  String get journalEmpty => 'No hay catas registradas aún';

  @override
  String get journalEmptySub =>
      'Descorcha y cata una botella de tu bodega para iniciar tu registro';

  @override
  String journalTastedOn(String date) {
    return 'Catado el $date';
  }

  @override
  String get statsTitle => 'Estadísticas de Bodega';

  @override
  String get statsTotalBottles => 'Botellas en Bodega';

  @override
  String get statsTotalValue => 'Valor de la Bodega';

  @override
  String get statsBottlesEnjoyed => 'Botellas Disfrutadas';

  @override
  String get statsByColor => 'Distribución por Tipo';

  @override
  String get statsByMaturity => 'Distribución por Madurez';

  @override
  String get statsByRegion => 'Principales Regiones';

  @override
  String get statsByCountry => 'Principales Países';

  @override
  String get profileTitle => 'Perfil y Ajustes';

  @override
  String get profileEmail => 'Correo electrónico';

  @override
  String get profileDisplayName => 'Nombre para mostrar';

  @override
  String get profileDefaultCurrency => 'Moneda predeterminada';

  @override
  String get profileLanguage => 'Idioma de la aplicación';

  @override
  String get profileLanguageSystem => 'Automático (Sistema)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Moneda predeterminada actualizada: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Idioma actualizado';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get profileAbout => 'Acerca de Chatmelier';

  @override
  String get scanTitle => 'Escanear Etiqueta de Vino';

  @override
  String get scanTakePhoto => 'Tomar foto';

  @override
  String get scanPickGallery => 'Elegir de la galería';

  @override
  String get scanAnalyzing =>
      'La IA de Chatmelier está analizando la etiqueta...';

  @override
  String get scanIdentified => 'Vino identificado por Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Añadir a mi bodega';

  @override
  String get loginTitle => 'Iniciar Sesión';

  @override
  String get loginTagline => 'Tu Bodega Inteligente Compartida con IA';

  @override
  String get loginTabMagicLink => '✉️ Enlace de Acceso';

  @override
  String get loginTabPassword => '🔑 Contraseña';

  @override
  String get loginEmailLabel => 'Correo electrónico';

  @override
  String get loginPasswordLabel => 'Contraseña';

  @override
  String get loginSendMagicLink => 'Enviar enlace de acceso';

  @override
  String get loginSignInButton => 'Iniciar Sesión';

  @override
  String get loginOrDivider => 'O';

  @override
  String get loginGoogleButton => 'Continuar con Google';

  @override
  String get loginRegisterLink => '¿No tienes cuenta? Regístrate';

  @override
  String get registerTitle => 'Crear Cuenta';

  @override
  String get registerNameLabel => 'Nombre para mostrar';

  @override
  String get registerSubmitButton => 'Crear mi cuenta';

  @override
  String get registerFillAllFields => 'Por favor completa todos los campos';

  @override
  String get registerWelcome => '🎉 ¡Bienvenido a Chatmelier!';

  @override
  String get registerErrorGeneric => 'Error al registrar la cuenta';

  @override
  String get authWelcome => 'Bienvenido a Chatmelier';

  @override
  String get authSubtitle =>
      'Tu sumiller inteligente y gestor de bodega personal';

  @override
  String get authGoogle => 'Continuar con Google';

  @override
  String get authMagicLink => 'Acceder con enlace de correo';

  @override
  String get authEmail => 'Correo electrónico';

  @override
  String get authNoAccount => '¿No tienes cuenta? Regístrate';

  @override
  String get authHaveAccount => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get changelogTitle => 'Novedades y Registro de Cambios';

  @override
  String get changelogEmpty => 'No hay notas de versión disponibles.';

  @override
  String get scratchcardTitle => 'Mapa para Rascar de Terruños';

  @override
  String get profileChangelog => 'Historial de Versiones y Novedades';

  @override
  String get profileScratchcard => 'Mapa para Rascar de Terruños';

  @override
  String get navProfile => 'Perfil';

  @override
  String get quickActions => 'ACCIONES RÁPIDAS';

  @override
  String get appSubtitle => 'Sumiller y Bodega';

  @override
  String get profileTabPalate => 'Paladar';

  @override
  String get profileTabSettings => 'Ajustes';

  @override
  String get profileTabTools => 'Herramientas';

  @override
  String get profileTabAccount => 'Cuenta';

  @override
  String get profileTheme => 'Tema / Apariencia';

  @override
  String get profileThemeLight => 'Claro ☀️';

  @override
  String get profileThemeDark => 'Oscuro 🌙';

  @override
  String get profileThemeSystem => 'Sistema ⚙️';

  @override
  String get profileFriends => 'Amigos y Mapa de Gustos 🍷';

  @override
  String get profileExport => 'Exportar Bodega e Informe 📊';

  @override
  String get profileDeleteAccount => 'Eliminar definitivamente mi cuenta';

  @override
  String get profileDeleteConfirmTitle => 'Eliminar definitivamente';

  @override
  String get profileDeleteConfirmMsg =>
      'Esta acción es irreversible. Todos tus datos serán eliminados.';

  @override
  String get badgesGalleryTitle => 'Galería de Trofeos';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total desbloqueados • $pct% completado';
  }

  @override
  String get badgesFilterAll => 'Todos';

  @override
  String get badgesEmpty => 'No se encontraron medallas en esta categoría.';

  @override
  String get badgesUnlockedChip => 'Desbloqueado ✨';

  @override
  String get badgesStatusUnlocked => '¡Medalla desbloqueada!';

  @override
  String get badgesStatusInProgress => 'En progreso';

  @override
  String get badgesObjectiveLabel => 'Objetivo:';

  @override
  String get badgesChatmelierLoreTitle => 'Ciencia e Historia de Chatmelier';

  @override
  String get badgesCloseButton => 'Cerrar';

  @override
  String get badgesTierLabel => 'Rango';

  @override
  String get badgesShowcaseTitle => 'Trofeos y Medallas';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked de $total desbloqueados';
  }

  @override
  String get badgesShowcaseGallery => 'Galería';

  @override
  String get save => 'Guardar';

  @override
  String get continueAnyway => 'Continuar de todos modos';

  @override
  String get cellarDetected => 'Bodega detectada: ';

  @override
  String proximityWifi(String ssid) {
    return 'Conectado a la red Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'Ubicación GPS detectada a $distance';
  }

  @override
  String get proximitySwitch => 'Cambiar';

  @override
  String get proximityIgnore => 'Ignorar';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Cambiado automáticamente a \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Bodega lejana detectada';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Actualmente estás conectado a la red Wi-Fi \"$ssid\" asociada con tu otra bodega \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Te encuentras a aproximadamente $distance de \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\n¿Aún deseas añadir esta botella a la bodega \"$cellar\"?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\n¿Aún deseas descorchar esta botella de la bodega \"$cellar\"?';
  }

  @override
  String get ratingExceptional => '🏆 Excepcional';

  @override
  String get ratingRemarkable => '✨ Notable';

  @override
  String get ratingVeryGood => '🍷 Muy bueno';

  @override
  String get ratingPleasant => '👍 Agradable';

  @override
  String get ratingPassable => 'Aceptable';

  @override
  String get checkoutWhoTasted => '¿Quién cató este vino contigo?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'botellas',
      one: 'botella',
    );
    return '$producer • En bodega: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Añadir invitado';

  @override
  String get checkoutAddGuestHint => 'Añadir (Mamá, Papá...)';

  @override
  String get checkoutCloseAndTaste => 'Cerrar y degustar 🍷';

  @override
  String get checkoutSommelierThinking =>
      'El sumiller está preparando anécdotas...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ ¡Temporizador de aireación activo en tu pantalla de bloqueo!';

  @override
  String get checkoutStartAerationTimer => 'Iniciar temporizador ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Temporizador de aireación';

  @override
  String get checkoutDelayedTonight => 'Esta noche a las 22:00';

  @override
  String get checkoutDelayedTonightSub =>
      'Ideal después de la comida para saborear el momento';

  @override
  String get checkoutDelayedTomorrow => 'Mañana a las 11:00';

  @override
  String get checkoutDelayedTomorrowSub =>
      'Para anotar tus impresiones con calma';

  @override
  String get checkoutDelayedWeekend =>
      'Este fin de semana (Sábado a las 11:00)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Tómate tu tiempo en un momento libre';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'En 2 horas ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Recordatorio rápido al finalizar la cata';

  @override
  String get checkoutDelayedCustom => 'Elegir fecha y hora personalizadas...';

  @override
  String get reviewPackagingDetected => 'Formato de embalaje detectado';

  @override
  String get reviewSingleBottleOnly => 'No, solo 1 botella';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Sí, $count botellas';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 ¡Stock actualizado con éxito! ($count botellas en bodega)';
  }

  @override
  String get reviewVintageYear => 'Añada / Año de cosecha';

  @override
  String get reviewNonVintage => 'Omitir / Sin añada (NV)';

  @override
  String get reviewValidate => 'Confirmar';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 ¡$name añadida con éxito a la bodega!';
  }

  @override
  String get reviewBottleAnalysis => 'Análisis de la botella';

  @override
  String get reviewDiscard => 'Descartar';

  @override
  String get reviewDiscardConfirmTitle => '¿Descartar la entrada?';

  @override
  String get reviewContinueEditing => 'Continuar editando';

  @override
  String get reviewDiscardWithoutSaving => 'Salir sin guardar';

  @override
  String get reviewBottleDetails => 'Detalles de la botella';

  @override
  String get reviewStockInCellar => 'Stock en bodega';

  @override
  String get reviewStockAddition => 'Añadir';

  @override
  String get reviewStockNewTotal => 'Nuevo total';

  @override
  String get reviewQuantityToAdd => 'Cantidad a añadir:';

  @override
  String get reviewSeparateEntry =>
      'Crear una entrada independiente (distinto estante o precio)';

  @override
  String get reviewRetryAi => 'Reintentar análisis IA';

  @override
  String get reviewEnlarge => 'Ampliar';

  @override
  String get reviewGeneralInfo => 'Información general';

  @override
  String get reviewOriginTerroir => 'Origen y Terruño';

  @override
  String get reviewQuantityPurchase => 'Cantidad y Compra';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi detectado y vinculado: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'No se pudo detectar el Wi-Fi (activa la ubicación o ingrésalo manualmente)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 Coordenadas GPS obtenidas ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'Ubicación GPS no disponible. Revisa los permisos.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ ¡Bodega \"$cellar\" creada con éxito!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Error durante la creación: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 metros (muy preciso)';

  @override
  String get cellarRadiusRecommended => '300 metros (recomendado)';

  @override
  String get cellarRadius500m => '500 metros';

  @override
  String get cellarRadius1km => '1 kilómetro';

  @override
  String get cellarRadius3km => '3 kilómetros';

  @override
  String get cellarCreateButton => 'Crear bodega';

  @override
  String get cellarUseCurrentGps => 'Establecer con ubicación GPS actual';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Ajustes de bodega \"$cellar\" actualizados';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Error al actualizar: $error';
  }

  @override
  String get wineTypeRed => 'Vino Tinto 🍷';

  @override
  String get wineTypeWhite => 'Vino Blanco 🥂';

  @override
  String get wineTypeRose => 'Vino Rosado 🌸';

  @override
  String get wineTypeSparkling => 'Espumoso / Cava 🍾';

  @override
  String get wineTypeDessert => 'Vino Dulce / Generoso 🍯';

  @override
  String get wineTypeLiqueur => 'Licor 🍯';

  @override
  String get wineTypeSpirit => 'Destilados 🥃';

  @override
  String get wineTypeGrappa => 'Orujo / Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Aguardiente de Frutas 🍐';

  @override
  String get wineTypeWhisky => 'Whisky 🥃';

  @override
  String get wineTypeRum => 'Ron 🏴‍☠️';

  @override
  String get wineTypeGin => 'Ginebra 🍸';

  @override
  String get wineTypeVodka => 'Vodka 🧊';

  @override
  String get wineTypeTequila => 'Tequila 🌵';

  @override
  String get wineTypeCognac => 'Coñac / Brandy 🍷';

  @override
  String get cellarCreateTitle => 'Crear una nueva bodega';

  @override
  String get cellarManageTitle => 'Administrar bodega';

  @override
  String get cellarNameLabel => 'Nombre de la bodega *';

  @override
  String get cellarNameHint => 'ej. Bodega Principal, Vinoteca Salón';

  @override
  String get cellarNameRequired => 'Por favor ingresa un nombre';

  @override
  String get cellarLocationLabel => 'Ubicación / Ciudad (opcional)';

  @override
  String get cellarLocationHint => 'ej. Madrid, Rioja';

  @override
  String get cellarNicknameLabel => 'Apodo / Sala (opcional)';

  @override
  String get cellarNicknameHint => 'ej. Sótano, Armario climatizado';

  @override
  String get cellarDescriptionLabel => 'Descripción (opcional)';

  @override
  String get cellarDescriptionHint =>
      'ej. Cueva fresca subterránea, humedad 70%';

  @override
  String get cellarWifiLabel => 'Wi-Fi asociado (opcional)';

  @override
  String get cellarWifiHint => 'ej. Wi-Fi-Bodega';

  @override
  String get cellarLinkCurrentWifi => 'Vincular a la red Wi-Fi actual';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Capturar Wi-Fi actual';

  @override
  String get cellarRadiusLabel => 'Radio de detección GPS';

  @override
  String get cellarAutoDetectionHeader => 'Detección y Transición Automática';

  @override
  String get cellarAutoDetectionDesc =>
      'Vincula tu red Wi-Fi o coordenadas GPS para cambiar automáticamente a esta bodega al encontrarte en ella.';

  @override
  String get cellarLatitudeLabel => 'Latitud';

  @override
  String get cellarLongitudeLabel => 'Longitud';

  @override
  String get checkoutGuidedTasting => 'Cata guiada';

  @override
  String get checkoutGuidedTastingShared =>
      'Comparte tus impresiones por turnos o en conjunto';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analiza fase visual, olfativa y gustativa y afina tu perfil';

  @override
  String get checkoutUncorkNowRateLater => 'Descorchar ahora, valorar después';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Salida inmediata • Elige momento del recordatorio (esta noche, mañana...)';

  @override
  String get checkoutUncorkAeration => 'Descorchar y Temporizador de aireación';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Salida inmediata • Se recomiendan $minutes min de aireación';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Salida inmediata • Temporizador de decantación o aireación';

  @override
  String get checkoutSommelierServiceAdvice =>
      'Consejos de servicio del sumiller';

  @override
  String get checkoutHistoryAnecdotes => 'Historias y Anécdotas';

  @override
  String get checkoutNoDecanting => 'Sin decantación requerida';

  @override
  String get checkoutStoryTitle => 'La historia de esta botella 📖';

  @override
  String get checkoutStorySubtitle =>
      'Anécdotas cautivadoras para compartir en la mesa';

  @override
  String get checkoutStoryTerroir => 'Terruño y Variedades';

  @override
  String get checkoutStoryVintage => 'La historia de la añada';

  @override
  String get checkoutStoryTastingSecret => 'Secreto de cata';

  @override
  String get checkoutStoryTableAnecdote => 'Anécdota para la mesa';

  @override
  String get checkoutJournalArchivedNotice =>
      'Tranquilo: esta botella quedará archivada en tu Diario con tus fotos y notas.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return '¡Botella descorchada! Temporizador de aireación ($minutes min) en pantalla de bloqueo.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'La botella se descorchará de inmediato. Confirma la duración de aireación antes de servir:';

  @override
  String get checkoutRateWine => 'Valorar vino';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Temporizador ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Consejo sumiller: airear $minutes min. Temporizador de pantalla listo.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Recordatorio programado tras la cata para registrar tus impresiones.';

  @override
  String get checkoutBottleRemovedSuccess => '¡Botella retirada de la bodega!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Disfruta de la cata. Recordatorio programado para el $date.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'El perfil de gusto de cada comensal se enriquecerá automáticamente.';

  @override
  String checkoutCellarOf(String name) {
    return 'Bodega de $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Stock: $count bot.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Añade un ser querido o amigo presente en esta cata (ej. Mamá, Papá, Carmen...).';

  @override
  String get checkoutAddGuestNameLabel => 'Nombre / Apodo';

  @override
  String get checkoutDelayedSheetTitle => 'Descorchar y valorar más tarde';

  @override
  String get checkoutDelayedSheetSubtitle =>
      '¿Cuándo deseas recibir el recordatorio para tus impresiones?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Esta noche en 2 horas ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Esta noche a las 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'esta noche a las $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'mañana a las $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'el $date a las $time';
  }

  @override
  String get add => 'Añadir';

  @override
  String get cellarWinesTab => '🍷 Vinos';

  @override
  String get cellarSpiritsTab => '🥃 Espirituosos';

  @override
  String get cellarPairWithDish => '¿Qué vino para mi plato?';

  @override
  String get cellarCollapseAll => 'Plegar todo';

  @override
  String get cellarExpandAll => 'Desplegar todo';

  @override
  String get cellarSort => 'Ordenar';

  @override
  String get cellarCategories => 'Categorías';

  @override
  String get cellarFavorites => 'Favoritos';

  @override
  String get cellarGridView => 'Cuadrícula';

  @override
  String get cellarListView => 'Lista';

  @override
  String get cellarClearFilters => 'Borrar filtros';

  @override
  String get cellarNoBottlesCategory => 'No hay botellas en esta categoría';

  @override
  String get cellarNoBottlesCriteria =>
      'Ninguna botella coincide con estos criterios';

  @override
  String get feedbackSheetTitle => 'Comentarios de tester y anotación';

  @override
  String get feedbackStylus => 'Lápiz:';

  @override
  String get feedbackUndo => 'Deshacer último trazo';

  @override
  String get feedbackClear => 'Borrar todo';

  @override
  String get feedbackHint =>
      'Rodea el área y describe tus comentarios o error...';

  @override
  String get feedbackSubmit => 'Enviar informe';

  @override
  String get feedbackSubmitting => 'Enviando...';

  @override
  String get feedbackNoScreenshot => 'No hay captura de pantalla disponible';

  @override
  String get feedbackEmptyError =>
      'Por favor añade un comentario o dibuja en la captura.';

  @override
  String get feedbackSuccess =>
      '¡Gracias por tus comentarios! 🍷 Informe enviado.';

  @override
  String feedbackError(String error) {
    return 'Error al enviar: $error';
  }

  @override
  String get checkoutFastExit => 'Salida rápida sin cuestionario ⚡';

  @override
  String get checkoutFastExitSubmitting => 'Procesando salida...';

  @override
  String get checkoutRatingSubtitle =>
      'Asigna tu puntuación global tras degustar';

  @override
  String get checkoutRecommendedBadge => 'Recomendado';

  @override
  String get tastingWhoTastedTitle => '👥 ¿Quién cató este vino?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Selecciona a los catadores. Los perfiles de gusto se enriquecerán automáticamente.';

  @override
  String get tastingHowToTaste => '¿Cómo catar?';

  @override
  String get tastingEachTurn => 'Cada uno por turnos';

  @override
  String get tastingEachTurnDesc =>
      '📱 Pasando el móvil: cada persona responde por separado a su propio ritmo.';

  @override
  String get tastingTogether => 'Todos juntos';

  @override
  String get tastingTogetherDesc =>
      '🥂 Un único cuestionario completado en común por todos los presentes.';

  @override
  String get tastingBlindMode => 'Modo Cata a Ciegas';

  @override
  String get tastingBlindModeDesc =>
      'Oculta el nombre del vino y activa un divertido juego de mesa con revelación final.';

  @override
  String get tastingPrimaryProfile => 'Perfil principal';

  @override
  String get tastingAppInstalled => 'App instalada 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cuestionarios completados',
      one: '1 cuestionario completado',
      zero: '0 cuestionarios completados',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 Fase Olfativa — Aromas';

  @override
  String get tastingStepNezSubtitle =>
      'Gira la copa y capta las capas aromáticas que se liberan.';

  @override
  String get tastingAromaIntensity => 'Intensidad aromática:';

  @override
  String get tastingAromaDiscreet => '🤫 Sutil / Discreta';

  @override
  String get tastingAromaExplosive => '💥 Explosiva / Potente';

  @override
  String get tastingStepBoucheTitle => '⚖️ Fase Gustativa — Equilibrio';

  @override
  String get tastingStepBoucheSubtitle =>
      'Describe la textura, la frescura y la armonía en boca.';

  @override
  String get tastingAcidity => 'Sensación de acidez:';

  @override
  String get tastingAcidityFreshness => 'Acidez y Frescura:';

  @override
  String get tastingAcidityFlat => '🫠 Plano / Bajo';

  @override
  String get tastingAciditySharp => '⚡ Punzante / Fresco';

  @override
  String get tastingTannins => 'Taninos:';

  @override
  String get tastingTanninsSilky => '🧶 Sedosos / Amables';

  @override
  String get tastingTanninsGrippy => '💪 Firmes / Estructurados';

  @override
  String get tastingMinerality => 'Mineralidad y Tensión:';

  @override
  String get tastingMineralityRound => '🧈 Redondo / Graso';

  @override
  String get tastingMineralityCrisp => '🪨 Mineral / Preciso';

  @override
  String get tastingEffervescence => 'Efervescencia (Burbuja):';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fina / Delicada';

  @override
  String get tastingEffervescenceVibrant => '🎆 Viva / Cremosa';

  @override
  String get tastingBody => 'Cuerpo / Volumen:';

  @override
  String get tastingBodyLight => '🍃 Ligero / Fluido';

  @override
  String get tastingBodyFull => '🏋️ Robusto / Con cuerpo';

  @override
  String get tastingLength => 'Persistencia / Longitud:';

  @override
  String get tastingLengthShort => '⏱️ Corta';

  @override
  String get tastingLengthLong => '♾️ Muy prolongada';

  @override
  String get tastingStepVerdictTitle => '✅ Veredicto final';

  @override
  String get tastingBuyAgain => '¿Comprarías esta botella de nuevo?';

  @override
  String get tastingBuyAgainYes => '🤩 ¡Sin duda!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Quizás';

  @override
  String get tastingBuyAgainNo => '👎 No, gracias';

  @override
  String get tastingIdealMoment => '¿Momento ideal para este vino?';

  @override
  String get tastingMomentApero => '🥂 Aperitivo';

  @override
  String get tastingMomentMeal => '🍽️ Comida informal';

  @override
  String get tastingMomentDinner => '🎩 Cena de gala';

  @override
  String get tastingMomentRomantic => '🕯️ Cena romántica';

  @override
  String get tastingMomentSolo => '🧘 Momento de calma personal';

  @override
  String get tastingWhatLiked => 'Lo que más te ha gustado:';

  @override
  String get tastingWhatDisliked => 'Lo que menos te ha convencido:';

  @override
  String get tastingOccasionLabel => 'Ocasión / Recuerdo (opcional) ✨';

  @override
  String get tastingOccasionHint =>
      'ej. Cumpleaños, Cena a la luz de las velas, Reencuentro...';

  @override
  String get tastingAddPhoto => 'Añadir una foto recuerdo de la mesa 📸';

  @override
  String get tastingPhotoSaved => 'Foto guardada 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Puntuación final e Impresión';

  @override
  String get tastingStepImpressionSubtitle =>
      'Tras disfrutar de la nariz y la boca, otorga tu calificación global.';

  @override
  String get tastingOverallFeeling => 'Tu impresión general:';

  @override
  String get tastingScoreOutOf10 => 'Puntuación sobre 10:';

  @override
  String get tastingCompletedTitle => '¡Cata finalizada y guardada!';

  @override
  String get tastingCompletedSubtitle =>
      'Los perfiles de gusto se han actualizado con éxito ✨';

  @override
  String get tastingBottleRemoved =>
      'Botella descorchada y retirada de la bodega';

  @override
  String get tastingConsultDebrief =>
      'Ver análisis del sumiller (Matices ocultos y Terruño)';

  @override
  String get tastingFinishButton => 'Finalizar ✨';

  @override
  String get tastingNextTaster => 'Validar → Siguiente catador';

  @override
  String get tastingConfirmAndFinish => 'Validar y Terminar ✨';

  @override
  String get tastingQuitTitle => '¿Salir del cuestionario?';

  @override
  String get tastingQuitMessage => 'Tus respuestas actuales no se guardarán.';

  @override
  String get tastingContinue => 'Continuar';

  @override
  String get tastingQuit => 'Salir';

  @override
  String tastingStartCount(int count) {
    return 'Empezar ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Sincronizado con la app de $name ✨';
  }

  @override
  String get tastingProfileEnriched => 'Perfil gustativo enriquecido';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Agudeza sensorial: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle =>
      'Origen de los sabores y Secretos del vino';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Descubre de dónde nacen los aromas, el color y la estructura de tu vino';

  @override
  String get tastingBlindQuizTitle => 'Juego de mesa de cata a ciegas 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. ¿Cuál es la región de origen? 🌍';

  @override
  String get tastingBlindQuizQ2 =>
      '2. ¿Cuál es la variedad principal de uva? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. ¿Añada estimada o edad del vino? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. ¿Precio estimado de mercado? 💶';

  @override
  String get tastingBlindRevealTitle =>
      'Gran revelación de la botella misteriosa 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Puntuación del juego a ciegas: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Análisis enológico y molecular';

  @override
  String get tastingSensoryAcuity => 'AGUDEZA SENSORIAL';

  @override
  String tastingPrecision(int score) {
    return 'Precisión $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. CONCORDANCIA Y SELLO DEL CRU';

  @override
  String get tastingWhatYouDetected => 'LO QUE HAS DETECTADO:';

  @override
  String get tastingArchetypeSignature => 'FIRMA ARQUETÍPICA DEL VINO:';

  @override
  String get tastingHiddenNuancesTitle =>
      'MATICES SUTILES PARA TU PRÓXIMA COPA:';

  @override
  String get tastingPillarsTitle => '2. CIENCIA ENOLÓGICA Y MOLÉCULAS';

  @override
  String get tastingPillarsSubtitle =>
      '¿Por qué este vino tiene esta estructura, estos aromas y este color?';

  @override
  String get tastingChatWithSommelier =>
      'Profundiza en los secretos enológicos con Chatmelier';

  @override
  String get aromaFruitsRouges => 'Frutos rojos (fresa, cereza)';

  @override
  String get aromaFruitsNoirs => 'Frutos negros (mora, grosella negra)';

  @override
  String get aromaFruitsBlancs =>
      'Fruta blanca y de hueso (melocotón, pera, manzana)';

  @override
  String get aromaAgrumes => 'Cítricos (limón, pomelo)';

  @override
  String get aromaFloral => 'Floral (violeta, rosa)';

  @override
  String get aromaVegetal => 'Vegetal y hierbas (pimiento, sotobosque)';

  @override
  String get aromaEpicesDouces => 'Especias dulces (canela, nuez moscada)';

  @override
  String get aromaEpicesVives => 'Especias picantes (pimienta negra)';

  @override
  String get aromaBoise => 'Roble y Vainilla (crianza)';

  @override
  String get aromaBeurre => 'Mantequilla y Brioche';

  @override
  String get aromaMineral => 'Mineral (pedernal, tiza)';

  @override
  String get aromaMiel => 'Miel y Confitura';

  @override
  String get aromaChocolat => 'Chocolate negro y Café';

  @override
  String get aromaFumee => 'Ahumado y Tostado';

  @override
  String get emojiDisliked => 'No me gustó';

  @override
  String get emojiMeh => 'Pasable';

  @override
  String get emojiDecent => 'Decente';

  @override
  String get emojiVeryGood => 'Muy bueno';

  @override
  String get emojiLoved => '¡Fascinante!';

  @override
  String get likedFreshness => 'La frescura';

  @override
  String get likedFruitiness => 'La fruta';

  @override
  String get likedComplexity => 'La complejidad';

  @override
  String get likedElegance => 'La elegancia';

  @override
  String get likedPower => 'La potencia';

  @override
  String get likedSilky => 'La textura sedosa';

  @override
  String get likedOriginality => 'La originalidad';

  @override
  String get likedFoodPairing => 'El maridaje';

  @override
  String get likedMinerality => 'La mineralidad';

  @override
  String get likedLength => 'La persistencia';

  @override
  String get likedDisappointing => 'Nada / Decepcionante 😕';

  @override
  String get dislikedTooAcidic => 'Demasiado ácido';

  @override
  String get dislikedTooTannic => 'Demasiado tánico';

  @override
  String get dislikedTooOaked => 'Demasiado roble / avainillado';

  @override
  String get dislikedTooAlcoholic => 'Demasiado alcohólico';

  @override
  String get dislikedTooThin => 'Demasiado ligero';

  @override
  String get dislikedLacksFruit => 'Falta de fruta';

  @override
  String get dislikedTooSweet => 'Demasiado dulce';

  @override
  String get dislikedTooExpensive => 'Demasiado caro para su calidad';

  @override
  String get dislikedNothing => '¡Nada, estaba impecable!';

  @override
  String get tastingStepTasters => 'Catadores';

  @override
  String get tastingStepNezNav => 'Nariz';

  @override
  String get tastingStepBoucheNav => 'Boca';

  @override
  String get tastingStepVerdictNav => 'Veredicto';

  @override
  String get tastingStepRatingNav => 'Puntuación';

  @override
  String get tastingBack => 'Atrás';

  @override
  String get tastingNext => 'Siguiente';

  @override
  String get tastingSaving => 'Guardando...';

  @override
  String get tastingHeaderTitle => 'Cuestionario de cata';

  @override
  String tastingAnswersOf(String name) {
    return 'Respuestas de $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Pasa el móvil a $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'Tus respuestas han sido registradas.\nAhora le toca a $name.';
  }

  @override
  String get tastingDictateButton => 'Dictar impresiones de la mesa 🎙️';

  @override
  String get tastingDictateHint =>
      'Habla o escribe libremente: ¡la IA Chatmelier completará tus aromas y equilibrio en boca!';

  @override
  String get tastingDictateMicTip =>
      'Consejo: ¡activa el micrófono del teclado para dictar en voz alta!';

  @override
  String get tastingTakePhoto => 'Hacer foto de la mesa 📸';

  @override
  String get tastingChooseGallery => 'Elegir de la galería 🖼️';

  @override
  String get tastingConclaveSummary => 'Resumen de la cata';

  @override
  String get tastingCellarMaster => 'Maestro de Bodega';

  @override
  String get tastingGuestTaster => 'Catador Invitado';

  @override
  String tastingProfileTag(String type) {
    return 'Perfil: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Nota de cata libre registrada.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Fase visual: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Estructura: $structure ($caudalies caudalías)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Moléculas clave: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Factor clave: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Variedades: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Impresiones de cata aplicadas por Chatmelier AI ✨';

  @override
  String get tastingBlindYourPredictions => 'Resumen de predicciones a ciegas:';

  @override
  String get tastingBlindGuessCorrect => '¡Acierto! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      '¡Haz tus predicciones antes de revelar la etiqueta!';

  @override
  String tastingStartTaster(String name) {
    return '¡Adelante, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 ¡Bravo!';

  @override
  String tastingQuizWas(String answer) {
    return '(La respuesta era: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'ej.: A Pedro le fascinó dándole 8.5/10, notas de mora y sotobosque. María le dio 7/10 notando la acidez un poco alta...';

  @override
  String get tastingDictateAnalyzing => 'Analizando...';

  @override
  String get tastingDictateAnalyzeAndApply =>
      'Analizar y Aplicar a las fichas ✨';

  @override
  String get tastingFormatExpress => 'Formato Exprés (1 página) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Puntuación, aromas clave y veredicto rápido en 30s';

  @override
  String get tastingFormatSommelier => 'Formato Sumiller (Detallado) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Examen minucioso de nariz, boca, persistencia y terruño';

  @override
  String get tastingCaudalieTooltipTitle => '¿Qué es una caudalía? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalía = 1 segundo de persistencia del sabor tras tragar o escupir.\n• De 1 a 4 caudalías: vino fresco y ligero\n• De 5 a 7 caudalías: gran equilibrio\n• De 8 a 12+ caudalías: ¡un vino extraordinario!';

  @override
  String get tastingAddCustomAroma => '+ Aroma personalizado';

  @override
  String get tastingCustomAromaDialogTitle => 'Añadir un aroma concreto';

  @override
  String get tastingCustomAromaHint =>
      'ej. Sílex ahumado, Mora silvestre, Rosa seca...';

  @override
  String get tastingFoodSynergyTitle => 'Sinergia con la comida 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Sublime';

  @override
  String get tastingSynergyHarmonious => '👍 Armonioso';

  @override
  String get tastingSynergyNeutral => '😐 Neutro';

  @override
  String get tastingSynergyClashing => '⚡ Discordante';

  @override
  String get checkoutFastRatingTitle =>
      'Puntuación rápida en 1 toque (opcional):';

  @override
  String get checkoutActionTastingTitle => 'Catar este vino';

  @override
  String get checkoutActionTastingSubtitle =>
      'Formato exprés (1 página) o detallado de sumiller';

  @override
  String get checkoutActionDeferredRemind => 'Recordar más tarde 🌙';

  @override
  String get checkoutActionAerationTimer => 'Temporizador de aireación ⏱️';
}
