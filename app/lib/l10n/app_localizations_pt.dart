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
  String get save => 'Guardar';

  @override
  String get continueAnyway => 'Continuar mesmo assim';

  @override
  String get cellarDetected => 'Garrafeira detetada: ';

  @override
  String proximityWifi(String ssid) {
    return 'Ligado ao Wi-Fi \"$ssid\"';
  }

  @override
  String proximityGps(String distance) {
    return 'Localização GPS detetada a $distance';
  }

  @override
  String get proximitySwitch => 'Alternar';

  @override
  String get proximityIgnore => 'Ignorar';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 Alternado automaticamente para \"$cellar\"';
  }

  @override
  String get distantCellarTitle => 'Garrafeira distante detetada';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return 'Está atualmente ligado ao Wi-Fi \"$ssid\" associado à sua outra garrafeira \"$cellar\".';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return 'Encontra-se a aproximadamente $distance de \"$cellar\".';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nAinda deseja adicionar esta garrafa à garrafeira \"$cellar\"?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nAinda deseja retirar esta garrafa da garrafeira \"$cellar\"?';
  }

  @override
  String get ratingExceptional => '🏆 Excecional';

  @override
  String get ratingRemarkable => '✨ Notável';

  @override
  String get ratingVeryGood => '🍷 Muito bom';

  @override
  String get ratingPleasant => '👍 Agradável';

  @override
  String get ratingPassable => 'Razoável';

  @override
  String get checkoutWhoTasted => 'Quem provou este vinho consigo?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: 'garrafas',
      one: 'garrafa',
    );
    return '$producer • Em stock: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'Adicionar convidado';

  @override
  String get checkoutAddGuestHint => 'Adicionar (Mãe, Pai...)';

  @override
  String get checkoutCloseAndTaste => 'Fechar e desfrutar 🍷';

  @override
  String get checkoutSommelierThinking =>
      'O sommelier está a preparar as notas de prova...';

  @override
  String get checkoutAerationTimerActive =>
      '⏱️ Temporizador de arejamento ativo no ecrã de bloqueio!';

  @override
  String get checkoutStartAerationTimer => 'Iniciar temporizador ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'Temporizador de Arejamento';

  @override
  String get checkoutDelayedTonight => 'Hoje às 22:00';

  @override
  String get checkoutDelayedTonightSub =>
      'Ideal após a refeição para saborear o momento';

  @override
  String get checkoutDelayedTomorrow => 'Amanhã às 11:00';

  @override
  String get checkoutDelayedTomorrowSub =>
      'Para registar as suas impressões com calma';

  @override
  String get checkoutDelayedWeekend => 'Este fim de semana (Sábado às 11:00)';

  @override
  String get checkoutDelayedWeekendSub =>
      'Tome o seu tempo num momento de lazer';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return 'Em 2 horas ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub =>
      'Lembrete rápido no final da prova';

  @override
  String get checkoutDelayedCustom => 'Escolher data e hora personalizadas...';

  @override
  String get reviewPackagingDetected => 'Formato de embalagem detetado';

  @override
  String get reviewSingleBottleOnly => 'Não, apenas 1 garrafa';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'Sim, $count garrafas';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 Stock atualizado com sucesso! ($count garrafas na garrafeira)';
  }

  @override
  String get reviewVintageYear => 'Ano de colheita / Safra';

  @override
  String get reviewNonVintage => 'Ignorar / Não safrado (NV)';

  @override
  String get reviewValidate => 'Confirmar';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 $name adicionado com sucesso à garrafeira!';
  }

  @override
  String get reviewBottleAnalysis => 'Análise da garrafa';

  @override
  String get reviewDiscard => 'Descartar';

  @override
  String get reviewDiscardConfirmTitle => 'Descartar registo?';

  @override
  String get reviewContinueEditing => 'Continuar a editar';

  @override
  String get reviewDiscardWithoutSaving => 'Sair sem guardar';

  @override
  String get reviewBottleDetails => 'Detalhes da garrafa';

  @override
  String get reviewStockInCellar => 'Stock na garrafeira';

  @override
  String get reviewStockAddition => 'Adicionar';

  @override
  String get reviewStockNewTotal => 'Novo total';

  @override
  String get reviewQuantityToAdd => 'Quantidade a adicionar:';

  @override
  String get reviewSeparateEntry =>
      'Criar entrada separada (prateleira ou preço diferente)';

  @override
  String get reviewRetryAi => 'Repetir análise IA';

  @override
  String get reviewEnlarge => 'Ampliar';

  @override
  String get reviewGeneralInfo => 'Informações gerais';

  @override
  String get reviewOriginTerroir => 'Origem & Terroir';

  @override
  String get reviewQuantityPurchase => 'Quantidade & Compra';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi detetado e associado: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Não foi possível detetar o Wi-Fi (ative a localização ou introduza manualmente)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 Coordenadas GPS capturadas ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible =>
      'Localização GPS indisponível. Verifique as permissões.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ Garrafeira \"$cellar\" criada com sucesso!';
  }

  @override
  String cellarCreationError(String error) {
    return 'Erro durante a criação: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 metros (muito preciso)';

  @override
  String get cellarRadiusRecommended => '300 metros (recomendado)';

  @override
  String get cellarRadius500m => '500 metros';

  @override
  String get cellarRadius1km => '1 quilómetro';

  @override
  String get cellarRadius3km => '3 quilómetros';

  @override
  String get cellarCreateButton => 'Criar garrafeira';

  @override
  String get cellarUseCurrentGps => 'Definir com localização GPS atual';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ Definições da garrafeira \"$cellar\" atualizadas';
  }

  @override
  String cellarUpdateError(String error) {
    return 'Erro ao atualizar: $error';
  }

  @override
  String get wineTypeRed => 'Vinho Tinto 🍷';

  @override
  String get wineTypeWhite => 'Vinho Branco 🥂';

  @override
  String get wineTypeRose => 'Vinho Rosé 🌸';

  @override
  String get wineTypeSparkling => 'Espumante 🍾';

  @override
  String get wineTypeDessert => 'Vinho de Sobremesa / Licoroso 🍯';

  @override
  String get bottleSizeCustom => 'Outra capacidade…';

  @override
  String get bottleSizeCustomTitle => 'Capacidade personalizada';

  @override
  String get bottleSizeCustomLabel => 'Capacidade em centilitros';

  @override
  String get bottleSizeCustomInvalid =>
      'Introduza uma capacidade entre 1 e 3000 cl.';

  @override
  String get wineTypeLiqueur => 'Licor 🍯';

  @override
  String get wineTypeSpirit => 'Destilados 🥃';

  @override
  String get wineTypeGrappa => 'Bagaço / Grappa 🍇';

  @override
  String get wineTypeEauDeVie => 'Aguardente de Frutas 🍐';

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
  String get wineTypeCognac => 'Cognac / Brandy 🍷';

  @override
  String get cellarCreateTitle => 'Criar nova garrafeira';

  @override
  String get cellarManageTitle => 'Gerir garrafeira';

  @override
  String get cellarNameLabel => 'Nome da garrafeira *';

  @override
  String get cellarNameHint => 'ex. Garrafeira de Casa, Cave Principal';

  @override
  String get cellarNameRequired => 'Por favor introduza um nome';

  @override
  String get cellarLocationLabel => 'Localização / Cidade (opcional)';

  @override
  String get cellarLocationHint => 'ex. Lisboa, Porto, Beaune';

  @override
  String get cellarNicknameLabel => 'Alcunha / Divisão (opcional)';

  @override
  String get cellarNicknameHint => 'ex. Cave, Garrafeira da sala';

  @override
  String get cellarDescriptionLabel => 'Descrição (opcional)';

  @override
  String get cellarDescriptionHint =>
      'ex. Cave subterrânea fresca, humidade 70%';

  @override
  String get cellarWifiLabel => 'Wi-Fi associado (opcional)';

  @override
  String get cellarWifiHint => 'ex. Wi-Fi-Garrafeira';

  @override
  String get cellarLinkCurrentWifi => 'Associar ao Wi-Fi atual';

  @override
  String get cellarCaptureCurrentWifiTooltip => 'Capturar Wi-Fi atual';

  @override
  String get cellarRadiusLabel => 'Raio de deteção GPS';

  @override
  String get cellarAutoDetectionHeader => 'Deteção e Transição Automática';

  @override
  String get cellarAutoDetectionDesc =>
      'Associe a sua rede Wi-Fi ou coordenadas GPS para mudar automaticamente para esta garrafeira quando estiver lá.';

  @override
  String get cellarLatitudeLabel => 'Latitude';

  @override
  String get cellarLongitudeLabel => 'Longitude';

  @override
  String get checkoutGuidedTasting => 'Prova guiada';

  @override
  String get checkoutGuidedTastingShared =>
      'Partilhe impressões à vez ou em conjunto';

  @override
  String get checkoutGuidedTastingSolo =>
      'Analise a fase visual, olfativa e gustativa e refine o seu perfil';

  @override
  String get checkoutUncorkNowRateLater => 'Abrir agora, avaliar depois';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      'Saída imediata • Escolha a hora do lembrete (hoje, amanhã...)';

  @override
  String get checkoutUncorkAeration => 'Abrir & Temporizador de arejamento';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return 'Saída imediata • $minutes min de arejamento recomendados';
  }

  @override
  String get checkoutUncorkAerationSub =>
      'Saída imediata • Temporizador de decantação ou arejamento';

  @override
  String get checkoutSommelierServiceAdvice =>
      'Conselhos de serviço do sommelier';

  @override
  String get checkoutHistoryAnecdotes => 'Histórias & Curiosidades';

  @override
  String get checkoutNoDecanting => 'Não necessita de decantação';

  @override
  String get checkoutStoryTitle => 'A história desta garrafa 📖';

  @override
  String get checkoutStorySubtitle =>
      'Histórias fascinantes para partilhar à mesa';

  @override
  String get checkoutStoryTerroir => 'Terroir & Castas';

  @override
  String get checkoutStoryVintage => 'A história da safra';

  @override
  String get checkoutStoryTastingSecret => 'Segredo de prova';

  @override
  String get checkoutStoryTableAnecdote => 'Curiosidade para a mesa';

  @override
  String get checkoutJournalArchivedNotice =>
      'Não se preocupe: esta garrafa será arquivada no seu Diário de Prova com notas e fotos.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'Garrafa aberta! Temporizador de arejamento ($minutes min) ativo no ecrã.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'A garrafa será retirada imediatamente. Confirme a duração do arejamento:';

  @override
  String get checkoutRateWine => 'Avaliar vinho';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'Temporizador ${minutes}m ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'Dica sommelier: arejar $minutes min. Temporizador de ecrã pronto.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      'Lembrete agendado após a prova para registar as impressões.';

  @override
  String get checkoutBottleRemovedSuccess => 'Garrafa retirada da garrafeira!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'Boa prova. Lembrete agendado para $date.';
  }

  @override
  String get checkoutWhoTastedSubtitle =>
      'O perfil gustativo de cada participante será enriquecido automaticamente.';

  @override
  String checkoutCellarOf(String name) {
    return 'Garrafeira de $name';
  }

  @override
  String checkoutStockBout(int count) {
    return 'Stock: $count gar.';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'Adicione um familiar ou amigo presente nesta prova (ex. Mãe, Pai, Ana...).';

  @override
  String get checkoutAddGuestNameLabel => 'Nome / Alcunha';

  @override
  String get checkoutDelayedSheetTitle => 'Abrir e avaliar mais tarde';

  @override
  String get checkoutDelayedSheetSubtitle =>
      'Quando deseja receber o lembrete para as suas notas?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return 'Hoje em 2 horas ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => 'Hoje às 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return 'hoje às $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return 'amanhã às $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return 'a $date às $time';
  }

  @override
  String get add => 'Adicionar';

  @override
  String get cellarWinesTab => '🍷 Vinhos';

  @override
  String get cellarSpiritsTab => '🥃 Espirituosos';

  @override
  String get cellarPairWithDish => 'Que vinho para o meu prato?';

  @override
  String get cellarCollapseAll => 'Recolher tudo';

  @override
  String get cellarExpandAll => 'Expandir tudo';

  @override
  String get cellarSort => 'Ordenar';

  @override
  String get cellarCategories => 'Categorias';

  @override
  String get cellarFavorites => 'Favoritos';

  @override
  String get cellarGridView => 'Grelha';

  @override
  String get cellarListView => 'Lista';

  @override
  String get cellarClearFilters => 'Limpar filtros';

  @override
  String get cellarNoBottlesCategory => 'Nenhuma garrafa nesta categoria';

  @override
  String get cellarNoBottlesCriteria =>
      'Nenhuma garrafa corresponde a estes critérios';

  @override
  String get feedbackSheetTitle => 'Feedback do testador e anotação';

  @override
  String get feedbackStylus => 'Caneta:';

  @override
  String get feedbackUndo => 'Desfazer último traço';

  @override
  String get feedbackClear => 'Limpar tudo';

  @override
  String get feedbackHint => 'Circule a área e descreva o feedback ou erro...';

  @override
  String get feedbackSubmit => 'Enviar relatório';

  @override
  String get feedbackSubmitting => 'Enviando...';

  @override
  String get feedbackNoScreenshot => 'Nenhuma captura de ecrã disponível';

  @override
  String get feedbackEmptyError =>
      'Por favor adicione um comentário ou desenhe na captura.';

  @override
  String get feedbackSuccess =>
      'Obrigado pelo seu feedback! 🍷 Relatório enviado.';

  @override
  String feedbackError(String error) {
    return 'Erro ao enviar: $error';
  }

  @override
  String get checkoutFastExit => 'Saída rápida sem questionário ⚡';

  @override
  String get checkoutFastExitSubmitting => 'A processar saída...';

  @override
  String get checkoutRatingSubtitle => 'Atribua a sua nota geral após a prova';

  @override
  String get checkoutRecommendedBadge => 'Recomendado';

  @override
  String get tastingWhoTastedTitle => '👥 Quem provou este vinho?';

  @override
  String get tastingWhoTastedSubtitle =>
      'Selecione os participantes. Os perfis de sabor serão enriquecidos automaticamente.';

  @override
  String get tastingHowToTaste => 'Como provar?';

  @override
  String get tastingEachTurn => 'Cada um à vez';

  @override
  String get tastingEachTurnDesc =>
      '📱 Passando o telemóvel: cada pessoa responde separadamente ao seu ritmo.';

  @override
  String get tastingTogether => 'Todos juntos';

  @override
  String get tastingTogetherDesc =>
      '🥂 Um único questionário preenchido em conjunto por todos.';

  @override
  String get tastingBlindMode => 'Modo Prova às Cegas';

  @override
  String get tastingBlindModeDesc =>
      'Oculte o nome do vinho e inicie um questionário divertido com revelação final!';

  @override
  String get tastingPrimaryProfile => 'Perfil principal';

  @override
  String get tastingAppInstalled => 'Aplicação instalada 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count questionários preenchidos',
      one: '1 questionário preenchido',
      zero: '0 questionários preenchidos',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 O Olfato — Expressão aromática';

  @override
  String get tastingStepNezSubtitle =>
      'Rode o copo e aprecie os aromas que se desprendem.';

  @override
  String get tastingFaultTitle => 'O vinho cheira a alguma destas coisas?';

  @override
  String get tastingFaultSubtitle =>
      'Se sim, a garrafa está defeituosa — não é o seu paladar nem o estilo do vinho.';

  @override
  String get tastingFaultCorkLabel => '📦 Cartão húmido, adega bolorenta';

  @override
  String get tastingFaultCorkExplain =>
      'Aroma a rolha (TCA). O vinho não tem culpa e não melhora com o arejamento — num restaurante, pode pedir outra garrafa.';

  @override
  String get tastingFaultOxidationLabel => '🍎 Maçã passada, vinagre, xerez';

  @override
  String get tastingFaultOxidationExplain =>
      'Oxidação. A garrafa apanhou ar, muitas vezes por uma rolha deficiente ou uma guarda demasiado longa.';

  @override
  String get tastingFaultReductionLabel => '🥚 Fósforo, ovo, couve';

  @override
  String get tastingFaultReductionExplain =>
      'Redução. Boa notícia: costuma desaparecer com o ar. Decante vinte minutos e prove de novo antes de julgar.';

  @override
  String get tastingFaultExcluded =>
      'Esta prova não contará para o seu perfil de gosto.';

  @override
  String get tastingAromaIntensity => 'Intensidade aromática:';

  @override
  String get tastingAromaDiscreet => '🤫 Discreta / Delicada';

  @override
  String get tastingAromaExplosive => '💥 Explosiva / Potente';

  @override
  String get tastingStepBoucheTitle => '⚖️ A Boca — Equilíbrio e Textura';

  @override
  String get tastingStepBoucheSubtitle =>
      'Descreva a textura, frescura e harmonia no palato.';

  @override
  String get tastingAcidity => 'Acidez:';

  @override
  String get tastingAcidityFreshness => 'Acidez e Frescura:';

  @override
  String get tastingAcidityFlat => '🫠 Plana / Baixa';

  @override
  String get tastingAciditySharp => '⚡ Viva / Cortante';

  @override
  String get tastingTannins => 'Taninos:';

  @override
  String get tastingTanninsSilky => '🧶 Sedosos / Polidos';

  @override
  String get tastingTanninsGrippy => '💪 Firmes / Estruturados';

  @override
  String get tastingMinerality => 'Mineralidade & Salinidade:';

  @override
  String get tastingMineralityRound => '🧈 Redondo / Gordo';

  @override
  String get tastingMineralityCrisp => '🪨 Mineral / Preciso';

  @override
  String get tastingEffervescence => 'Efervescência (Bolha):';

  @override
  String get tastingEffervescenceDelicate => '🫧 Fina / Delicada';

  @override
  String get tastingEffervescenceVibrant => '🎆 Viva / Cremosa';

  @override
  String get tastingBody => 'Corpo / Volume:';

  @override
  String get tastingBodyLight => '🍃 Ligeiro / Elegante';

  @override
  String get tastingBodyFull => '🏋️ Encorpado / Robusto';

  @override
  String get tastingLength => 'Persistência / Final de boca:';

  @override
  String get tastingLengthShort => '⏱️ Curto';

  @override
  String get tastingLengthLong => '♾️ Muito longo';

  @override
  String get tastingStepVerdictTitle => '✅ Veredito final';

  @override
  String get sipSectionTitle => '🍷 O gole';

  @override
  String get tasteConfidenceUnknown =>
      'Ainda não conheço o seu paladar — o halo mostra o que estou a adivinhar.';

  @override
  String get tasteEvidenceTitle => 'De onde vem este perfil';

  @override
  String get tasteEvidenceEmpty =>
      'Ainda nada registado. O seu perfil constrói-se à medida que prova.';

  @override
  String get tasteEvidenceOpen => 'Ver de onde vem este perfil';

  @override
  String tasteConfidenceKnown(String percent) {
    return 'Paladar conhecido a $percent %. A desfocagem marca o que ainda adivinho.';
  }

  @override
  String tasteConfidenceFrontier(String axis) {
    return 'O que menos conheço: $axis.';
  }

  @override
  String get sipSectionSubtitle =>
      'Dois toques, e este copo ensina algo ao seu perfil de gosto.';

  @override
  String get tastingBuyAgain => 'Compraria esta garrafa novamente?';

  @override
  String get tastingBuyAgainYes => '🤩 Com certeza!';

  @override
  String get tastingBuyAgainMaybe => '🤔 Talvez';

  @override
  String get tastingBuyAgainNo => '👎 Não, obrigado';

  @override
  String get tastingIdealMoment => 'Ocasião ideal para este vinho?';

  @override
  String get tastingMomentApero => '🥂 Aperitivo';

  @override
  String get tastingMomentMeal => '🍽️ Refeição informal';

  @override
  String get tastingMomentDinner => '🎩 Jantar de gala';

  @override
  String get tastingMomentRomantic => '🕯️ Jantar romântico';

  @override
  String get tastingMomentSolo => '🧘 Momento de tranquilidade';

  @override
  String get tastingWhatLiked => 'O que mais apreciou:';

  @override
  String get tastingWhatDisliked => 'O que menos apreciou:';

  @override
  String get tastingOccasionLabel => 'Ocasião / Memória (opcional) ✨';

  @override
  String get tastingOccasionHint =>
      'ex. Aniversário, Jantar a dois, Reunião de amigos...';

  @override
  String get tastingAddPhoto => 'Adicionar foto da mesa 📸';

  @override
  String get tastingPhotoSaved => 'Foto guardada 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 Nota final & Impressão';

  @override
  String get tastingStepImpressionSubtitle =>
      'Após saborear o aroma e o palato, atribua a sua classificação geral.';

  @override
  String get tastingOverallFeeling => 'A sua impressão geral:';

  @override
  String get tastingScoreOutOf10 => 'Nota de 0 a 10:';

  @override
  String get tastingCompletedTitle => 'Prova concluída & guardada!';

  @override
  String get tastingCompletedSubtitle =>
      'Os perfis de sabor foram atualizados com sucesso ✨';

  @override
  String get tastingBottleRemoved => 'Garrafa aberta e retirada da garrafeira';

  @override
  String get tastingConsultDebrief =>
      'Ver análise do sommelier (Nuances ocultas & Terroir)';

  @override
  String get tastingFinishButton => 'Concluir ✨';

  @override
  String get tastingNextTaster => 'Validar → Próximo provador';

  @override
  String get tastingConfirmAndFinish => 'Validar & Concluir ✨';

  @override
  String get tastingQuitTitle => 'Sair do questionário?';

  @override
  String get tastingQuitMessage => 'As suas respostas não serão guardadas.';

  @override
  String get tastingContinue => 'Continuar';

  @override
  String get tastingQuit => 'Sair';

  @override
  String tastingStartCount(int count) {
    return 'Iniciar ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return 'Sincronizado com a app de $name ✨';
  }

  @override
  String get tastingProfileEnriched => 'Perfil gustativo enriquecido';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return 'Acuidade sensorial: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle =>
      'Origem dos sabores & Segredos do vinho';

  @override
  String get tastingFlavorOriginsSubtitle =>
      'Descubra de onde provêm os aromas, a cor e o corpo do seu vinho';

  @override
  String get tastingBlindQuizTitle => 'Quiz de mesa às cegas 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. Qual é a região de origem? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. Qual é a casta principal? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. Ano de colheita / Idade estimada? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. Preço estimado no mercado? 💶';

  @override
  String get tastingBlindRevealTitle =>
      'Grande revelação da garrafa misteriosa 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'Pontuação da prova às cegas: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => 'Análise enológica e molecular';

  @override
  String get tastingSensoryAcuity => 'ACUIDADE SENSORIAL';

  @override
  String tastingPrecision(int score) {
    return 'Precisão $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. CONCORDÂNCIA E ASSINATURA DO CRU';

  @override
  String get tastingWhatYouDetected => 'O QUE DETETOU:';

  @override
  String get tastingArchetypeSignature => 'ASSINATURA TÍPICA DO VINHO:';

  @override
  String get tastingHiddenNuancesTitle =>
      'NUANCES SUTIS PARA O SEU PRÓXIMO COPO:';

  @override
  String get tastingPillarsTitle => '2. CIÊNCIA ENOLÓGICA E MOLÉCULAS';

  @override
  String get tastingPillarsSubtitle =>
      'Porque é que este vinho tem esta estrutura, estes aromas e esta cor?';

  @override
  String get tastingChatWithSommelier =>
      'Aprofunde os segredos de vinificação com o Chatmelier';

  @override
  String get aromaFruitsRouges => 'Frutos vermelhos (morango, cereja)';

  @override
  String get aromaFruitsNoirs => 'Frutos pretos (amora, cassis)';

  @override
  String get aromaFruitsBlancs =>
      'Fruta branca e de caroço (pêssego, pera, maçã)';

  @override
  String get aromaAgrumes => 'Citrinos (limão, toranja)';

  @override
  String get aromaFloral => 'Floral (violeta, rosa)';

  @override
  String get aromaVegetal => 'Vegetal e herbáceo (pimento, bosque)';

  @override
  String get aromaEpicesDouces => 'Especiarias doces (canela, noz-moscada)';

  @override
  String get aromaEpicesVives => 'Especiarias picantes (pimenta preta)';

  @override
  String get aromaBoise => 'Carvalho e Baunilha (estágio)';

  @override
  String get aromaBeurre => 'Manteiga e Brioche';

  @override
  String get aromaMineral => 'Mineral (pederneira, giz)';

  @override
  String get aromaMiel => 'Mel e Compota';

  @override
  String get aromaChocolat => 'Chocolate preto e Café';

  @override
  String get aromaFumee => 'Fumado e Tostado';

  @override
  String get emojiDisliked => 'Não gostei';

  @override
  String get emojiMeh => 'Assim-assim';

  @override
  String get emojiDecent => 'Razoável';

  @override
  String get emojiVeryGood => 'Muito bom';

  @override
  String get emojiLoved => 'Adorei!';

  @override
  String get likedFreshness => 'A frescura e vivacidade';

  @override
  String get likedFruitiness => 'A fruta generosa';

  @override
  String get likedComplexity => 'A complexidade aromática';

  @override
  String get likedElegance => 'A elegância e harmonia';

  @override
  String get likedPower => 'A potência e o corpo';

  @override
  String get likedSilky => 'A textura aveludada';

  @override
  String get likedOriginality => 'A originalidade e carácter';

  @override
  String get likedFoodPairing => 'A combinação com o prato';

  @override
  String get likedMinerality => 'A mineralidade';

  @override
  String get likedLength => 'O final de boca longo';

  @override
  String get likedDisappointing => 'Nada / Fraco 😕';

  @override
  String get dislikedTooAcidic => 'Demasiado ácido';

  @override
  String get dislikedTooTannic => 'Demasiado tânico';

  @override
  String get dislikedTooOaked => 'Demasiado amadeirado';

  @override
  String get dislikedTooAlcoholic => 'Demasiado alcoólico';

  @override
  String get dislikedTooThin => 'Demasiado ligeiro / aquoso';

  @override
  String get dislikedLacksFruit => 'Falta de fruta';

  @override
  String get dislikedTooSweet => 'Demasiado doce';

  @override
  String get dislikedTooExpensive => 'Demasiado caro para a qualidade';

  @override
  String get dislikedNothing => 'Nada, estava irrepreensível!';

  @override
  String get tastingStepTasters => 'Provadores';

  @override
  String get tastingStepNezNav => 'Nariz';

  @override
  String get tastingStepBoucheNav => 'Boca';

  @override
  String get tastingStepVerdictNav => 'Veredito';

  @override
  String get tastingStepRatingNav => 'Nota';

  @override
  String get tastingBack => 'Voltar';

  @override
  String get tastingNext => 'Seguinte';

  @override
  String get tastingSaving => 'A guardar...';

  @override
  String get tastingHeaderTitle => 'Questionário de prova';

  @override
  String tastingAnswersOf(String name) {
    return 'Respostas de $name';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return 'Passe o telemóvel a $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'As suas respostas foram gravadas.\nAgora é a vez de $name.';
  }

  @override
  String get tastingDictateButton => 'Ditar impressões da mesa 🎙️';

  @override
  String get tastingDictateHint =>
      'Fale ou escreva livremente: a IA Chatmelier preencherá automaticamente os aromas e o equilíbrio de boca!';

  @override
  String get tastingDictateMicTip =>
      'Dica: ative o microfone no teclado para ditar por voz!';

  @override
  String get tastingTakePhoto => 'Tirar foto da mesa 📸';

  @override
  String get tastingChooseGallery => 'Escolher da galeria 🖼️';

  @override
  String get tastingConclaveSummary => 'Resumo da prova';

  @override
  String get tastingCellarMaster => 'Mestre de Garrafeira';

  @override
  String get tastingGuestTaster => 'Provador Convidado';

  @override
  String tastingProfileTag(String type) {
    return 'Perfil: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'Nota de prova livre gravada.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return 'Aspeto: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return 'Estrutura: $structure ($caudalies caudalies)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return 'Moléculas-chave: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'Fator determinante: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'Castas: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI =>
      'Impressões aplicadas pela IA Chatmelier ✨';

  @override
  String get tastingBlindYourPredictions => 'Resumo dos palpites às cegas:';

  @override
  String get tastingBlindGuessCorrect => 'Acertou! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt =>
      'Faça os seus palpites antes de revelar o rótulo!';

  @override
  String tastingStartTaster(String name) {
    return 'Vamos a isso, $name! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 Parabéns!';

  @override
  String tastingQuizWas(String answer) {
    return '(A resposta era: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      'ex.: O Manuel adorou dando 8.5/10, notas de bosque e cassis. A Maria deu 7/10 achando a acidez um pouco viva...';

  @override
  String get tastingDictateAnalyzing => 'A analisar...';

  @override
  String get tastingDictateAnalyzeAndApply => 'Analisar e Aplicar às fichas ✨';

  @override
  String get tastingFormatExpress => 'Formato Expresso (1 página) ⚡';

  @override
  String get tastingFormatExpressDesc =>
      'Nota, aromas principais e veredito rápido em 30s';

  @override
  String get tastingFormatSommelier => 'Formato Sommelier (Detalhado) 🎓';

  @override
  String get tastingFormatSommelierDesc =>
      'Análise aprofundada de nariz, boca, persistência e terroir';

  @override
  String get tastingCaudalieTooltipTitle => 'O que é uma caudalie? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 caudalie = 1 segundo de persistência dos sabores após engolir ou cuspir.\n• 1 a 4 caudalies: vinho leve e fresco\n• 5 a 7 caudalies: belo equilíbrio\n• 8 a 12+ caudalies: vinho excecional!';

  @override
  String get tastingAddCustomAroma => '+ Aroma personalizado';

  @override
  String get tastingCustomAromaDialogTitle => 'Adicionar aroma específico';

  @override
  String get tastingCustomAromaHint =>
      'ex. Pederneira fumada, Amora silvestre, Rosa seca...';

  @override
  String get tastingFoodSynergyTitle => 'Harmonização com a comida 🍽️';

  @override
  String get tastingSynergySublime => '🤩 Sublime';

  @override
  String get tastingSynergyHarmonious => '👍 Harmonioso';

  @override
  String get tastingSynergyNeutral => '😐 Neutro';

  @override
  String get tastingSynergyClashing => '⚡ Conflituoso';

  @override
  String get checkoutFastRatingTitle =>
      'Classificação rápida num toque (opcional):';

  @override
  String get checkoutActionTastingTitle => 'Provar este vinho';

  @override
  String get checkoutActionTastingSubtitle =>
      'Formato expresso (1 página) ou detalhado de sommelier';

  @override
  String get checkoutActionDeferredRemind => 'Lembrar mais tarde 🌙';

  @override
  String get checkoutActionAerationTimer => 'Temporizador de arejamento ⏱️';

  @override
  String get externalTastingTitle => 'Prova fora da adega';

  @override
  String get externalTastingSubtitle =>
      'Restaurante, bar, em casa de amigos... sem mexer no seu stock';

  @override
  String get externalTastingWithWhom => 'Com quem está a provar este vinho?';

  @override
  String get externalTastingWhere => 'Onde está a provar este vinho?';

  @override
  String get externalTastingSearchingPlaces =>
      'A procurar restaurantes, bares e amigos à sua volta...';

  @override
  String get externalTastingGpsActive => 'GPS ativo';

  @override
  String externalTastingPlaceGuess(String place) {
    return 'Parece que está em: $place';
  }

  @override
  String get externalTastingFavoritePlaceNote =>
      'Local favorito memorizado automaticamente pelo Chatmelier';

  @override
  String get externalTastingChangePlace => 'Mudar de local';

  @override
  String get externalTastingOtherPlace =>
      'Em casa de um amigo / Outro local...';

  @override
  String get externalTastingNoPlaceFound =>
      'Nenhum restaurante detetado nas imediações.';

  @override
  String get externalTastingPlaceLabel => 'Em casa de quem ou onde está? *';

  @override
  String get externalTastingPlaceHint =>
      'Ex.: Casa do Dimitri, Casa dos meus pais, Casa de campo...';

  @override
  String externalTastingRememberPlace(String place) {
    return 'Memorizar \"$place\" nesta posição GPS para as próximas visitas';
  }

  @override
  String get externalTastingDefaultPlace => 'No restaurante';

  @override
  String get externalTastingAiIdentifyTitle =>
      'Identificar com IA (bar, restaurante, quadro)';

  @override
  String get externalTastingAiIdentifyDesc =>
      'Escreva algumas palavras (ex.: \"Saint-Joseph Coursodon 2021\" ou \"Bandol Terrebrune\") para preencher a ficha.';

  @override
  String get externalTastingAiIdentifyHint =>
      'Ex.: Saint-Joseph 2021 Coursodon...';

  @override
  String get externalTastingDetect => 'Detetar';

  @override
  String get externalTastingAiScanningSub =>
      'A detetar produtor, colheita, castas e notas...';

  @override
  String get externalTastingPhotoAdded => 'Foto do rótulo adicionada';

  @override
  String get externalTastingPhotoAddedSub => 'Visível no seu diário de provas';

  @override
  String get externalTastingReplacePhoto => 'Substituir';

  @override
  String get externalTastingDeletePhoto => 'Eliminar a foto';

  @override
  String get externalTastingScanLabelTitle =>
      'Fotografar o rótulo (leitura IA)';

  @override
  String get externalTastingScanLabelSub =>
      'Reconhecimento automático do vinho e registo no diário';

  @override
  String get externalTastingScanLabelButton => 'Leitura IA';

  @override
  String get externalTastingTakePhotoSub => 'Fotografar o rótulo com a câmara';

  @override
  String get externalTastingPickGallerySub => 'Selecionar uma foto existente';

  @override
  String get externalTastingWineNameLabel => 'Nome do vinho *';

  @override
  String get externalTastingWineNameHint => 'Ex.: Domaine de Terrebrune';

  @override
  String get externalTastingProducerHint => 'Ex.: Famille Delon';

  @override
  String get externalTastingRegionLabel => 'Região / Denominação';

  @override
  String get externalTastingRegionHint => 'Ex.: Bandol tinto';

  @override
  String get externalTastingRatingLabel => 'Nota de prova:';

  @override
  String get externalTastingFavorite => 'Adorei';

  @override
  String get externalTastingFoodLabel => 'Harmonização';

  @override
  String get externalTastingNotesLabel => 'Impressões e aromas percebidos';

  @override
  String get externalTastingNotesHint =>
      'Ex.: Fruta preta intensa, taninos sedosos, ótima persistência...';

  @override
  String get externalTastingSubmit => 'Guardar e avaliar ✨';

  @override
  String get externalTastingNameRequired =>
      'Indique pelo menos o nome do vinho.';

  @override
  String get externalTastingSaved =>
      'Prova fora da adega guardada! O Chatmelier vai lembrar-se dela.';

  @override
  String externalTastingAiRecognized(String name) {
    return '✨ Garrafa reconhecida pela IA: $name';
  }

  @override
  String externalTastingAiFilled(String name) {
    return '✨ Ficha preenchida pela IA: $name';
  }

  @override
  String externalTastingAnalysisError(String error) {
    return 'Erro de análise: $error';
  }

  @override
  String externalTastingSaveError(String error) {
    return 'Erro: $error';
  }
}
