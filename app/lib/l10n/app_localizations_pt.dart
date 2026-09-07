// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'Minha Adega';

  @override
  String get navCellar => 'Adega';

  @override
  String get navChat => 'Chat';

  @override
  String get navJournal => 'Histórico';

  @override
  String get navStats => 'Estatísticas';

  @override
  String get actionMenuTitle => 'Ações da Adega';

  @override
  String get actionAddBottle => 'Adicionar uma garrafa';

  @override
  String get actionAddBottleSub => 'Digitalizar rótulo ou entrada manual';

  @override
  String get actionCheckoutBottle => 'Degustar / Abrir garrafa';

  @override
  String get actionCheckoutBottleSub => 'Registar prova e dar baixa no stock';

  @override
  String get actionLookupWine => 'Consultar / Identificar vinho';

  @override
  String get actionLookupWineSub => 'Descoberta e análise instantânea por IA';

  @override
  String get searchWinePlaceholder =>
      'Pesquisar colheita, produtor, denominação...';

  @override
  String get emptyCellarTitle => 'A sua adega está vazia';

  @override
  String get emptyCellarSub =>
      'Digitalize a sua primeira garrafa para começar a coleção';

  @override
  String get emptyCellarButton => 'Adicionar a primeira garrafa';

  @override
  String cellarBottlesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count garrafas',
      one: '1 garrafa',
      zero: '0 garrafas',
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
  String get filterWhite => 'Branco';

  @override
  String get filterRose => 'Rosé';

  @override
  String get filterSparkling => 'Espumante';

  @override
  String get filterSheetTitle => 'Filtros da Adega';

  @override
  String get filterReset => 'Repor';

  @override
  String get filterApply => 'Aplicar filtros';

  @override
  String get filterMaturity => 'Estado de Maturação / Apogeu';

  @override
  String get maturityAtPeak => 'No apogeu';

  @override
  String get maturityDrinkSoon => 'Consumir em breve';

  @override
  String get maturityAging => 'Em guarda';

  @override
  String get maturityTooYoung => 'Demasiado jovem';

  @override
  String get maturityPastPeak => 'Ultrapassado';

  @override
  String get filterContinents => 'Continentes';

  @override
  String get filterCountries => 'Países';

  @override
  String get filterGrapes => 'Castas';

  @override
  String get filterAppellations => 'Regiões e Denominações';

  @override
  String get bottleDetailInfo => 'Informações e Terroir';

  @override
  String get bottleDetailDrinkingWindow => 'Janela de Consumo';

  @override
  String get bottleDetailTerroirMap => 'Mapa de Terroir e Origem';

  @override
  String get bottleDetailLabelPhoto => 'Foto original do rótulo';

  @override
  String get bottleDetailVintage => 'Colheita / Ano';

  @override
  String get bottleDetailProducer => 'Produtor / Quinta';

  @override
  String get bottleDetailRegion => 'Região';

  @override
  String get bottleDetailCountry => 'País';

  @override
  String get bottleDetailAppellation => 'Denominação de Origem';

  @override
  String get bottleDetailGrapes => 'Castas';

  @override
  String get bottleDetailAlcohol => 'Teor alcoólico';

  @override
  String get bottleDetailStock => 'Stock';

  @override
  String get bottleDetailLocation => 'Localização na adega';

  @override
  String get bottleDetailRack => 'Prateleira';

  @override
  String get bottleDetailShelf => 'Gaveta';

  @override
  String get bottleDetailPurchasePrice => 'Preço de compra';

  @override
  String get bottleDetailEstimatedValue => 'Valor estimado';

  @override
  String get bottleDetailFoodPairings =>
      'Harmonizações gastronómicas recomendadas';

  @override
  String get bottleDetailTastingNotes => 'Perfil do Escanção';

  @override
  String get bottleDetailDrinkButton => 'Abrir esta garrafa';

  @override
  String get bottleDetailEdit => 'Editar';

  @override
  String get bottleDetailDelete => 'Eliminar';

  @override
  String get bottleDetailDeleteConfirm =>
      'Tem a certeza de que deseja eliminar permanentemente esta garrafa da sua adega?';

  @override
  String get deleteBottleTitle => 'Eliminar Definitivamente';

  @override
  String get deleteBottleExplanation =>
      'Aviso: a eliminação apaga permanentemente todos os registos desta garrafa da adega e do histórico.';

  @override
  String get deleteBottleDifferenceDrink =>
      'Abrir / Beber: arquiva a garrafa no histórico de provas, atualiza estatísticas e preserva as suas notas.';

  @override
  String get deleteBottleDifferenceDelete =>
      'Eliminar definitivamente: apaga por completo o registo sem deixar rasto (recomendado para erros, quebras ou duplicados).';

  @override
  String get deleteBottleActionConfirm => 'Eliminar Definitivamente';

  @override
  String get deleteBottleActionDrinkInstead =>
      'Abrir / Beber em vez de eliminar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get checkoutTitle => 'Provar e Abrir da Adega';

  @override
  String get checkoutSelectPrompt =>
      'Toque para escolher uma garrafa da sua adega...';

  @override
  String get checkoutQtyOpened => 'Número de garrafas abertas';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'de $total na adega';
  }

  @override
  String get checkoutRating => 'Classificação da Prova';

  @override
  String get checkoutFoodPairing => 'Pratos e Acompanhamentos (opcional)';

  @override
  String get checkoutFoodHint => 'ex. Posta mirandesa, risotto de cogumelos...';

  @override
  String get checkoutNotes => 'Impressões e Notas de Prova';

  @override
  String get checkoutNotesHint =>
      'Aromas, equilíbrio, persistência, sensações...';

  @override
  String get checkoutSubmit => 'Confirmar prova';

  @override
  String get checkoutSuccess => 'Prova registada com sucesso!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'Olá! Sou o Chatmelier. Peça-me harmonizações, conselhos de consumo ou sugestões com base nas garrafas que tem na sua adega.';

  @override
  String get chatAnalyzing => 'O Chatmelier está a analisar a sua adega...';

  @override
  String get chatInputHint => 'Pergunte ao Chatmelier...';

  @override
  String get chatChipTonight => '🍷 O que devo beber esta noite?';

  @override
  String get chatChipSteak => '🥩 Harmonizar com bife suculento';

  @override
  String get chatChipSeafood => '🐟 Melhor branco para marisco';

  @override
  String get chatChipPeak => '⏰ Quais garrafas estão no apogeu?';

  @override
  String get journalTitle => 'Diário de Provas';

  @override
  String get journalEmpty => 'Nenhuma prova registada até agora';

  @override
  String get journalEmptySub =>
      'Abra e prove uma garrafa da sua adega para iniciar o seu diário';

  @override
  String journalTastedOn(String date) {
    return 'Degustado em $date';
  }

  @override
  String get statsTitle => 'Estatísticas da Adega';

  @override
  String get statsTotalBottles => 'Garrafas na Adega';

  @override
  String get statsTotalValue => 'Valor da Adega';

  @override
  String get statsBottlesEnjoyed => 'Garrafas Desfrutadas';

  @override
  String get statsByColor => 'Distribuição por Tipo';

  @override
  String get statsByMaturity => 'Distribuição por Maturação';

  @override
  String get statsByRegion => 'Principais Regiões';

  @override
  String get statsByCountry => 'Principais Países';

  @override
  String get profileTitle => 'Perfil e Definições';

  @override
  String get profileEmail => 'E-mail';

  @override
  String get profileDisplayName => 'Nome de apresentação';

  @override
  String get profileDefaultCurrency => 'Moeda predefinida';

  @override
  String get profileLanguage => 'Idioma da aplicação';

  @override
  String get profileLanguageSystem => 'Automático (Sistema)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return 'Moeda predefinida atualizada: $currency';
  }

  @override
  String get profileLanguageUpdated => 'Idioma atualizado';

  @override
  String get profileLogout => 'Terminar sessão';

  @override
  String get profileAbout => 'Sobre o Chatmelier';

  @override
  String get scanTitle => 'Digitalizar Rótulo';

  @override
  String get scanTakePhoto => 'Tirar foto';

  @override
  String get scanPickGallery => 'Escolher da galeria';

  @override
  String get scanAnalyzing => 'A IA do Chatmelier está a analisar o rótulo...';

  @override
  String get scanIdentified => 'Vinho identificado pelo Chatmelier ✨';

  @override
  String get scanSaveToCellar => 'Adicionar à minha adega';

  @override
  String get loginTitle => 'Iniciar Sessão';

  @override
  String get loginTagline => 'A sua Adega Inteligente Partilhada com IA';

  @override
  String get loginTabMagicLink => '✉️ Ligação de Acesso';

  @override
  String get loginTabPassword => '🔑 Palavra-passe';

  @override
  String get loginEmailLabel => 'Endereço de e-mail';

  @override
  String get loginPasswordLabel => 'Palavra-passe';

  @override
  String get loginSendMagicLink => 'Enviar ligação de acesso';

  @override
  String get loginSignInButton => 'Iniciar Sessão';

  @override
  String get loginOrDivider => 'OU';

  @override
  String get loginGoogleButton => 'Continuar com o Google';

  @override
  String get loginRegisterLink => 'Não tem conta? Registe-se';

  @override
  String get registerTitle => 'Criar Conta';

  @override
  String get registerNameLabel => 'Nome de apresentação';

  @override
  String get registerSubmitButton => 'Criar a minha conta';

  @override
  String get registerFillAllFields => 'Por favor preencha todos os campos';

  @override
  String get registerWelcome => '🎉 Bem-vindo ao Chatmelier!';

  @override
  String get registerErrorGeneric => 'Erro ao registar a conta';

  @override
  String get authWelcome => 'Bem-vindo ao Chatmelier';

  @override
  String get authSubtitle =>
      'O seu escanção inteligente e gestor de adega pessoal';

  @override
  String get authGoogle => 'Continuar com o Google';

  @override
  String get authMagicLink => 'Entrar com ligação por e-mail';

  @override
  String get authEmail => 'Endereço de e-mail';

  @override
  String get authNoAccount => 'Não tem conta? Registe-se';

  @override
  String get authHaveAccount => 'Já tem conta? Iniciar sessão';

  @override
  String get changelogTitle => 'Novidades e Notas de Versão';

  @override
  String get changelogEmpty => 'Nenhuma nota de versão disponível.';

  @override
  String get scratchcardTitle => 'Mapa para Raspar dos Terroirs';

  @override
  String get profileChangelog => 'Histórico de Versões e Novidades';

  @override
  String get profileScratchcard => 'Mapa para Raspar dos Terroirs';

  @override
  String get navBar => 'Bar';

  @override
  String get navProfile => 'Perfil';

  @override
  String get quickActions => 'AÇÕES RÁPIDAS';

  @override
  String get appSubtitle => 'Sommelier e Adega';

  @override
  String get profileTabPalate => 'Paladar';

  @override
  String get profileTabSettings => 'Definições';

  @override
  String get profileTabTools => 'Ferramentas';

  @override
  String get profileTabAccount => 'Conta';

  @override
  String get profileTheme => 'Tema / Aparência';

  @override
  String get profileThemeLight => 'Claro ☀️';

  @override
  String get profileThemeDark => 'Escuro 🌙';

  @override
  String get profileThemeSystem => 'Sistema ⚙️';

  @override
  String get profileFriends => 'Amigos e Mapa de Gostos 🍷';

  @override
  String get profileExport => 'Exportar Adega e Relatório 📊';

  @override
  String get profileDeleteAccount => 'Eliminar definitivamente a minha conta';

  @override
  String get profileDeleteConfirmTitle => 'Eliminar definitivamente';

  @override
  String get profileDeleteConfirmMsg =>
      'Esta ação é irreversível. Todos os seus dados serão eliminados.';

  @override
  String get badgesGalleryTitle => 'Galeria de Troféus';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total desbloqueados • $pct% concluído';
  }

  @override
  String get badgesFilterAll => 'Todos';

  @override
  String get badgesEmpty => 'Nenhum emblema encontrado nesta categoria.';

  @override
  String get badgesUnlockedChip => 'Desbloqueado ✨';

  @override
  String get badgesStatusUnlocked => 'Emblema desbloqueado!';

  @override
  String get badgesStatusInProgress => 'Em progresso';

  @override
  String get badgesObjectiveLabel => 'Objetivo:';

  @override
  String get badgesChatmelierLoreTitle => 'Ciência e História do Chatmelier';

  @override
  String get badgesCloseButton => 'Fechar';

  @override
  String get badgesTierLabel => 'Grau';

  @override
  String get badgesShowcaseTitle => 'Troféus e Emblemas';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked de $total desbloqueados';
  }

  @override
  String get badgesShowcaseGallery => 'Galeria';

  @override
  String get cocktailsTitle => 'Bar e Cocktails';

  @override
  String get cocktailsReadyToShake => 'Prontos para agitar';

  @override
  String get cocktailsMissingOne => 'Falta 1';

  @override
  String get cocktailsManagePantry => 'Gerir Reserva';

  @override
  String get cocktailsResetPantry => 'Repor Reserva';
}
