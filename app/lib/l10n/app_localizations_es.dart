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
  String get navBar => 'Bar';

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
  String get cocktailsTitle => 'Bar y Cócteles';

  @override
  String get cocktailsReadyToShake => 'Listos para agitar';

  @override
  String get cocktailsMissingOne => 'Falta 1';

  @override
  String get cocktailsManagePantry => 'Gestionar Reserva';

  @override
  String get cocktailsResetPantry => 'Restablecer Reserva';
}
