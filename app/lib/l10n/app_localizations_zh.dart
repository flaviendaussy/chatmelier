// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => '我的酒窖';

  @override
  String get navCellar => '酒窖';

  @override
  String get navChat => '侍酒师';

  @override
  String get navJournal => '记录';

  @override
  String get navStats => '统计';

  @override
  String get actionMenuTitle => '酒窖操作';

  @override
  String get actionAddBottle => '添加一瓶酒';

  @override
  String get actionAddBottleSub => '扫描酒标或手动输入';

  @override
  String get actionCheckoutBottle => '品鉴 / 开瓶出窖';

  @override
  String get actionCheckoutBottleSub => '记录品鉴笔记并扣减库存';

  @override
  String get actionLookupWine => '查询 / 识别葡萄酒';

  @override
  String get actionLookupWineSub => '即时AI风土与葡萄品种分析';

  @override
  String get searchWinePlaceholder => '搜索年份、酒庄、产区...';

  @override
  String get emptyCellarTitle => '您的酒窖暂无存酒';

  @override
  String get emptyCellarSub => '扫描您的第一瓶酒，开启您的数字酒窖收藏';

  @override
  String get emptyCellarButton => '添加我的第一瓶酒';

  @override
  String cellarBottlesCount(int count) {
    return '$count 瓶';
  }

  @override
  String get cellarTotalValue => '总估值';

  @override
  String get filterAll => '全部';

  @override
  String get filterRed => '红葡萄酒';

  @override
  String get filterWhite => '白葡萄酒';

  @override
  String get filterRose => '桃红';

  @override
  String get filterSparkling => '起泡酒';

  @override
  String get filterSheetTitle => '酒窖筛选';

  @override
  String get filterReset => '重置';

  @override
  String get filterApply => '应用筛选';

  @override
  String get filterMaturity => '适饮状态 / 巅峰期';

  @override
  String get maturityAtPeak => '正值巅峰';

  @override
  String get maturityDrinkSoon => '宜尽快饮用';

  @override
  String get maturityAging => '继续陈年';

  @override
  String get maturityTooYoung => '尚显年轻';

  @override
  String get maturityPastPeak => '已过巅峰';

  @override
  String get filterContinents => '大洲';

  @override
  String get filterCountries => '国家';

  @override
  String get filterGrapes => '葡萄品种';

  @override
  String get filterAppellations => '产区与法定命名';

  @override
  String get bottleDetailInfo => '基本信息与风土';

  @override
  String get bottleDetailDrinkingWindow => '最佳适饮期';

  @override
  String get bottleDetailTerroirMap => '风土与产地地图';

  @override
  String get bottleDetailLabelPhoto => '扫描的原始酒标照片';

  @override
  String get bottleDetailVintage => '年份';

  @override
  String get bottleDetailProducer => '酒庄 / 生产商';

  @override
  String get bottleDetailRegion => '产区';

  @override
  String get bottleDetailCountry => '国家';

  @override
  String get bottleDetailAppellation => '产区原产地命名';

  @override
  String get bottleDetailGrapes => '葡萄品种';

  @override
  String get bottleDetailAlcohol => '酒精度';

  @override
  String get bottleDetailStock => '库存数量';

  @override
  String get bottleDetailLocation => '存放位置';

  @override
  String get bottleDetailRack => '酒架';

  @override
  String get bottleDetailShelf => '层号';

  @override
  String get bottleDetailPurchasePrice => '购买价格';

  @override
  String get bottleDetailEstimatedValue => '预估价值';

  @override
  String get bottleDetailFoodPairings => '推荐搭配菜肴';

  @override
  String get bottleDetailTastingNotes => '侍酒师品鉴档案';

  @override
  String get bottleDetailDrinkButton => '开瓶出窖';

  @override
  String get bottleDetailEdit => '编辑';

  @override
  String get bottleDetailDelete => '删除';

  @override
  String get bottleDetailDeleteConfirm => '确定要从您的酒窖中永久删除这瓶酒吗？';

  @override
  String get deleteBottleTitle => '永久删除';

  @override
  String get deleteBottleExplanation => '警告：永久删除将从酒窖和历史记录中彻底抹除此瓶酒。';

  @override
  String get deleteBottleDifferenceDrink => '开瓶饮用：将归档至品鉴记录，更新统计数据并完整保留您的笔记。';

  @override
  String get deleteBottleDifferenceDelete => '永久删除：完全抹除记录不留痕迹（适用于误输入、破损或重复）。';

  @override
  String get deleteBottleActionConfirm => '永久删除';

  @override
  String get deleteBottleActionDrinkInstead => '改为开瓶品鉴';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get checkoutTitle => '品鉴与开瓶出窖';

  @override
  String get checkoutSelectPrompt => '点击从酒窖中选择一瓶酒...';

  @override
  String get checkoutQtyOpened => '开瓶数量';

  @override
  String checkoutQtyOfTotal(int total) {
    return '酒窖共 $total 瓶中';
  }

  @override
  String get checkoutRating => '品鉴评分';

  @override
  String get checkoutFoodPairing => '搭配菜肴（选填）';

  @override
  String get checkoutFoodHint => '例如：炭烤眼肉牛排、松露菌菇烩饭...';

  @override
  String get checkoutNotes => '品鉴心得与风味描述';

  @override
  String get checkoutNotesHint => '香气、酸度、单宁、余味长度...';

  @override
  String get checkoutSubmit => '确认品鉴';

  @override
  String get checkoutSuccess => '品鉴记录已成功保存！';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      '您好！我是Chatmelier专属AI侍酒师。随时向我咨询餐酒搭配、适饮建议或根据您的酒窖库存定制推荐。';

  @override
  String get chatAnalyzing => 'Chatmelier 正在分析您的酒窖...';

  @override
  String get chatInputHint => '向 Chatmelier 提问...';

  @override
  String get chatChipTonight => '🍷 今晚适合开哪瓶酒？';

  @override
  String get chatChipSteak => '🥩 配牛排的最佳葡萄酒';

  @override
  String get chatChipSeafood => '🐟 配海鲜的高分白葡萄酒';

  @override
  String get chatChipPeak => '⏰ 哪些酒正处于巅峰适饮期？';

  @override
  String get journalTitle => '品鉴日志';

  @override
  String get journalEmpty => '暂无品鉴记录';

  @override
  String get journalEmptySub => '从酒窖中开一瓶酒开启您的品鉴记录';

  @override
  String journalTastedOn(String date) {
    return '品鉴于 $date';
  }

  @override
  String get statsTitle => '酒窖统计';

  @override
  String get statsTotalBottles => '当前存酒';

  @override
  String get statsTotalValue => '酒窖总估值';

  @override
  String get statsBottlesEnjoyed => '已享用瓶数';

  @override
  String get statsByColor => '类型分布';

  @override
  String get statsByMaturity => '熟成状态分布';

  @override
  String get statsByRegion => '主要产区';

  @override
  String get statsByCountry => '主要国家';

  @override
  String get profileTitle => '个人档案与设置';

  @override
  String get profileEmail => '电子邮箱';

  @override
  String get profileDisplayName => '显示名称';

  @override
  String get profileDefaultCurrency => '默认货币';

  @override
  String get profileLanguage => '应用语言';

  @override
  String get profileLanguageSystem => '自动（遵循手机系统）';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return '默认货币已更新为：$currency';
  }

  @override
  String get profileLanguageUpdated => '语言已更新';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileAbout => '关于 Chatmelier';

  @override
  String get scanTitle => '扫描酒标';

  @override
  String get scanTakePhoto => '拍照';

  @override
  String get scanPickGallery => '相册选择';

  @override
  String get scanAnalyzing => 'Chatmelier AI 正在识别酒标...';

  @override
  String get scanIdentified => '已成功识别葡萄酒 ✨';

  @override
  String get scanSaveToCellar => '存入我的酒窖';

  @override
  String get loginTitle => '登录';

  @override
  String get loginTagline => '您的AI智能共享酒窖管家';

  @override
  String get loginTabMagicLink => '✉️ 邮件免密链接';

  @override
  String get loginTabPassword => '🔑 密码登录';

  @override
  String get loginEmailLabel => '邮箱地址';

  @override
  String get loginPasswordLabel => '密码';

  @override
  String get loginSendMagicLink => '获取登录链接';

  @override
  String get loginSignInButton => '登录';

  @override
  String get loginOrDivider => '或';

  @override
  String get loginGoogleButton => '使用 Google 登录';

  @override
  String get loginRegisterLink => '还没有账号？立即注册';

  @override
  String get registerTitle => '创建新账号';

  @override
  String get registerNameLabel => '显示名称';

  @override
  String get registerSubmitButton => '创建我的账号';

  @override
  String get registerFillAllFields => '请填写所有必要字段';

  @override
  String get registerWelcome => '🎉 欢迎加入 Chatmelier！';

  @override
  String get registerErrorGeneric => '注册出错，请稍后重试';

  @override
  String get authWelcome => '欢迎使用 Chatmelier';

  @override
  String get authSubtitle => '您的智能酒窖管理助手与AI侍酒顾问';

  @override
  String get authGoogle => '使用 Google 登录';

  @override
  String get authMagicLink => '使用邮件链接登录';

  @override
  String get authEmail => '邮箱地址';

  @override
  String get authNoAccount => '没有账号？立即注册';

  @override
  String get authHaveAccount => '已有账号？直接登录';

  @override
  String get changelogTitle => '版本历史与更新说明';

  @override
  String get changelogEmpty => '暂无版本说明。';

  @override
  String get scratchcardTitle => '世界风土刮刮乐地图';

  @override
  String get profileChangelog => '版本历史与更新说明';

  @override
  String get profileScratchcard => '世界风土刮刮乐地图';

  @override
  String get navBar => '酒吧';

  @override
  String get navProfile => '个人';

  @override
  String get quickActions => '快捷操作';

  @override
  String get appSubtitle => '智能侍酒师与酒窖';

  @override
  String get profileTabPalate => '口感风味';

  @override
  String get profileTabSettings => '设置';

  @override
  String get profileTabTools => '工具';

  @override
  String get profileTabAccount => '账户';

  @override
  String get profileTheme => '外观 / 主题';

  @override
  String get profileThemeLight => '浅色 ☀️';

  @override
  String get profileThemeDark => '深色 🌙';

  @override
  String get profileThemeSystem => '跟随系统 ⚙️';

  @override
  String get profileFriends => '好友与风味地图 🍷';

  @override
  String get profileExport => '导出酒窖与资产评估报告 📊';

  @override
  String get profileDeleteAccount => '永久注销我的账户';

  @override
  String get profileDeleteConfirmTitle => '永久删除';

  @override
  String get profileDeleteConfirmMsg => '此操作不可撤销，您的所有数据将被清除。';

  @override
  String get badgesGalleryTitle => '成就与奖杯馆';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '已解锁 $unlocked / $total • 完成度 $pct%';
  }

  @override
  String get badgesFilterAll => '全部';

  @override
  String get badgesEmpty => '该分类暂无勋章。';

  @override
  String get badgesUnlockedChip => '已解锁 ✨';

  @override
  String get badgesStatusUnlocked => '恭喜解锁勋章！';

  @override
  String get badgesStatusInProgress => '进行中';

  @override
  String get badgesObjectiveLabel => '目标：';

  @override
  String get badgesChatmelierLoreTitle => '沙特梅利耶的科学与风土典故';

  @override
  String get badgesCloseButton => '关闭';

  @override
  String get badgesTierLabel => '等级';

  @override
  String get badgesShowcaseTitle => '奖杯与勋章';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '已解锁 $unlocked / $total';
  }

  @override
  String get badgesShowcaseGallery => '勋章馆';

  @override
  String get cocktailsTitle => '酒吧与鸡尾酒';

  @override
  String get cocktailsReadyToShake => '立即调制';

  @override
  String get cocktailsMissingOne => '仅缺1种原料';

  @override
  String get cocktailsManagePantry => '管理吧台库存';

  @override
  String get cocktailsResetPantry => '重置吧台库存';

  @override
  String get save => '保存';

  @override
  String get continueAnyway => '仍然继续';

  @override
  String get cellarDetected => '检测到酒窖: ';

  @override
  String proximityWifi(String ssid) {
    return '已连接至 Wi-Fi “$ssid”';
  }

  @override
  String proximityGps(String distance) {
    return '检测到 GPS 定位，距离 $distance';
  }

  @override
  String get proximitySwitch => '切换';

  @override
  String get proximityIgnore => '忽略';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 已自动切换至 “$cellar”';
  }

  @override
  String get distantCellarTitle => '检测到异地酒窖';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return '您当前连接的 Wi-Fi “$ssid” 与您的另一座酒窖 “$cellar” 关联。';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return '您当前所在位置距离酒窖 “$cellar” 约 $distance。';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\n您仍要将此瓶酒添加到酒窖 “$cellar” 吗？';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\n您仍要将此瓶酒从酒窖 “$cellar” 出库吗？';
  }

  @override
  String get ratingExceptional => '🏆 杰出';

  @override
  String get ratingRemarkable => '✨ 卓越';

  @override
  String get ratingVeryGood => '🍷 极佳';

  @override
  String get ratingPleasant => '👍 愉悦';

  @override
  String get ratingPassable => '尚可';

  @override
  String get checkoutWhoTasted => '谁与您一同品鉴了这款酒？';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: '瓶',
      one: '瓶',
    );
    return '$producer • 库存: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => '添加同饮者';

  @override
  String get checkoutAddGuestHint => '添加 (妈妈、爸爸、朋友...)';

  @override
  String get checkoutCloseAndTaste => '关闭并尽情品鉴 🍷';

  @override
  String get checkoutSommelierThinking => '侍酒师正在准备品鉴故事...';

  @override
  String get checkoutAerationTimerActive => '⏱️ 醒酒计时器已在锁屏界面启动！';

  @override
  String get checkoutStartAerationTimer => '启动醒酒计时 ⏱️';

  @override
  String get checkoutAerationTimerTitle => '醒酒计时器';

  @override
  String get checkoutDelayedTonight => '今晚 22:00';

  @override
  String get checkoutDelayedTonightSub => '餐后安静品味余韵的理想时刻';

  @override
  String get checkoutDelayedTomorrow => '明天上午 11:00';

  @override
  String get checkoutDelayedTomorrowSub => '在静谧时光中从容记录品鉴印象';

  @override
  String get checkoutDelayedWeekend => '本周末 (周六 11:00)';

  @override
  String get checkoutDelayedWeekendSub => '在闲暇假日里从容回顾';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return '2 小时后 ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub => '品鉴结束时的快捷提醒';

  @override
  String get checkoutDelayedCustom => '自选提醒日期与时间...';

  @override
  String get reviewPackagingDetected => '检测到包装规格';

  @override
  String get reviewSingleBottleOnly => '否，仅 1 瓶';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return '是，共 $count 瓶';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 库存更新成功！（酒窖现有: $count 瓶）';
  }

  @override
  String get reviewVintageYear => '年份 / 收获年';

  @override
  String get reviewNonVintage => '跳过 / 无年份 (NV)';

  @override
  String get reviewValidate => '确认入库';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 “$name” 已成功加入酒窖！';
  }

  @override
  String get reviewBottleAnalysis => '酒款深度解析';

  @override
  String get reviewDiscard => '放弃';

  @override
  String get reviewDiscardConfirmTitle => '放弃当前录入？';

  @override
  String get reviewContinueEditing => '继续编辑';

  @override
  String get reviewDiscardWithoutSaving => '不保存直接退出';

  @override
  String get reviewBottleDetails => '酒款详细信息';

  @override
  String get reviewStockInCellar => '酒窖库存';

  @override
  String get reviewStockAddition => '入库增加';

  @override
  String get reviewStockNewTotal => '变更后总数';

  @override
  String get reviewQuantityToAdd => '入库瓶数:';

  @override
  String get reviewSeparateEntry => '创建独立档案（不同货架或购入价格）';

  @override
  String get reviewRetryAi => '重试 AI 分析';

  @override
  String get reviewEnlarge => '查看大图';

  @override
  String get reviewGeneralInfo => '基础信息';

  @override
  String get reviewOriginTerroir => '产区与风土';

  @override
  String get reviewQuantityPurchase => '数量与购买记录';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 已识别并关联 Wi-Fi: “$ssid”';
  }

  @override
  String get cellarWifiDetectionFailed => '未能识别 Wi-Fi（请开启定位或手动输入）';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS 坐标已捕获 ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible => '无法获取 GPS 坐标，请检查系统定位权限。';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ 酒窖 “$cellar” 创建成功！';
  }

  @override
  String cellarCreationError(String error) {
    return '创建出错: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 米（极精准）';

  @override
  String get cellarRadiusRecommended => '300 米（推荐）';

  @override
  String get cellarRadius500m => '500 米';

  @override
  String get cellarRadius1km => '1 公里';

  @override
  String get cellarRadius3km => '3 公里';

  @override
  String get cellarCreateButton => '创建酒窖';

  @override
  String get cellarUseCurrentGps => '设为当前 GPS 定位';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ 酒窖 “$cellar” 设置已更新';
  }

  @override
  String cellarUpdateError(String error) {
    return '更新失败: $error';
  }

  @override
  String get wineTypeRed => '红葡萄酒 🍷';

  @override
  String get wineTypeWhite => '白葡萄酒 🥂';

  @override
  String get wineTypeRose => '桃红葡萄酒 🌸';

  @override
  String get wineTypeSparkling => '起泡酒 🍾';

  @override
  String get wineTypeDessert => '甜酒 / 贵腐 🍯';

  @override
  String get wineTypeLiqueur => '利口酒 🍯';

  @override
  String get wineTypeSpirit => '烈酒 🥃';

  @override
  String get wineTypeGrappa => '果渣白兰地 🍇';

  @override
  String get wineTypeEauDeVie => '水果蒸馏酒 🍐';

  @override
  String get wineTypeWhisky => '威士忌 🥃';

  @override
  String get wineTypeRum => '朗姆酒 🏴‍☠️';

  @override
  String get wineTypeGin => '金酒 🍸';

  @override
  String get wineTypeVodka => '伏特加 🧊';

  @override
  String get wineTypeTequila => '龙舌兰 🌵';

  @override
  String get wineTypeCognac => '干邑白兰地 🍷';

  @override
  String get cellarCreateTitle => '创建新酒窖';

  @override
  String get cellarManageTitle => '管理酒窖';

  @override
  String get cellarNameLabel => '酒窖名称 *';

  @override
  String get cellarNameHint => '例如：家中主酒窖、私人酒庄地下室';

  @override
  String get cellarNameRequired => '请输入酒窖名称';

  @override
  String get cellarLocationLabel => '地理位置 / 城市 (可选)';

  @override
  String get cellarLocationHint => '例如：上海、波尔多';

  @override
  String get cellarNicknameLabel => '别称 / 房间 (可选)';

  @override
  String get cellarNicknameHint => '例如：地下恒温室、客厅红酒柜';

  @override
  String get cellarDescriptionLabel => '描述 (可选)';

  @override
  String get cellarDescriptionHint => '例如：恒温12°C、湿度70%地下酒窖';

  @override
  String get cellarWifiLabel => '关联 Wi-Fi (可选)';

  @override
  String get cellarWifiHint => '例如：Home-Cellar-5G';

  @override
  String get cellarLinkCurrentWifi => '关联当前 Wi-Fi';

  @override
  String get cellarCaptureCurrentWifiTooltip => '捕获当前 Wi-Fi';

  @override
  String get cellarRadiusLabel => 'GPS 检测半径';

  @override
  String get cellarAutoDetectionHeader => '智能识别与场景切换';

  @override
  String get cellarAutoDetectionDesc =>
      '绑定您的 Wi-Fi 或 GPS 坐标，当您踏入该区域时将自动无缝切换至对应酒窖。';

  @override
  String get cellarLatitudeLabel => '纬度';

  @override
  String get cellarLongitudeLabel => '经度';

  @override
  String get checkoutGuidedTasting => '向导式专业品鉴';

  @override
  String get checkoutGuidedTastingShared => '逐一传递或全桌共享品鉴心得';

  @override
  String get checkoutGuidedTastingSolo => '从观色、闻香到品味平衡，精炼您的专属味蕾画像';

  @override
  String get checkoutUncorkNowRateLater => '立即开瓶，稍后品评';

  @override
  String get checkoutUncorkNowRateLaterSub => '即时出库 • 选择提醒时机（今晚、明天...）';

  @override
  String get checkoutUncorkAeration => '开瓶并启动醒酒计时';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return '即时出库 • 推荐醒酒 $minutes 分钟';
  }

  @override
  String get checkoutUncorkAerationSub => '即时出库 • 醒酒 / 换瓶倒计时';

  @override
  String get checkoutSommelierServiceAdvice => '侍酒师专业侍酒建议';

  @override
  String get checkoutHistoryAnecdotes => '酒庄故事与奇闻轶事';

  @override
  String get checkoutNoDecanting => '无需醒酒换瓶';

  @override
  String get checkoutStoryTitle => '佳酿故事篇章 📖';

  @override
  String get checkoutStorySubtitle => '餐桌上令人着迷的谈资';

  @override
  String get checkoutStoryTerroir => '风土与葡萄品种';

  @override
  String get checkoutStoryVintage => '该年份的气候传奇';

  @override
  String get checkoutStoryTastingSecret => '品鉴私密技巧';

  @override
  String get checkoutStoryTableAnecdote => '餐桌小八卦';

  @override
  String get checkoutJournalArchivedNotice => '请放心：此酒款将连同您的照片和笔记完好归档在品鉴日志中。';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return '佳酿已开启！醒酒计时器（$minutes 分钟）正在锁屏界面运行。';
  }

  @override
  String get checkoutAerationDialogPrompt => '瓶酒将立即出库。请在品鉴前确认建议醒酒时长：';

  @override
  String get checkoutRateWine => '评分与记录';

  @override
  String checkoutStartTimerAction(int minutes) {
    return '计时 $minutes 分钟 ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return '侍酒师建议：醒酒 $minutes 分钟。锁屏计时器已就绪。';
  }

  @override
  String get checkoutAdviceReminderSnack => '已设置品后提醒，稍后记录您的心动印象。';

  @override
  String get checkoutBottleRemovedSuccess => '佳酿已成功从酒窖出库！';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return '祝您品鉴愉快。已安排于 $date 提醒您记录感官笔记。';
  }

  @override
  String get checkoutWhoTastedSubtitle => '每位共饮者的味蕾模型都将获得自适应强化。';

  @override
  String checkoutCellarOf(String name) {
    return '$name 的私藏酒窖';
  }

  @override
  String checkoutStockBout(int count) {
    return '库存: $count 瓶';
  }

  @override
  String get checkoutAddGuestDialogDesc => '添加参与本次品鉴的亲朋好友（例如：妈妈、爸爸、小李...）。';

  @override
  String get checkoutAddGuestNameLabel => '姓名 / 昵称';

  @override
  String get checkoutDelayedSheetTitle => '开瓶并稍后评析';

  @override
  String get checkoutDelayedSheetSubtitle => '您希望在何时接收品鉴印象记录提醒？';

  @override
  String checkoutDelayedTonightTime(String time) {
    return '今晚 2 小时后 ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => '今晚 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return '今晚 $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return '明天 $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return '$date $time';
  }

  @override
  String get add => '添加';

  @override
  String get cellarWinesTab => '🍷 葡萄酒';

  @override
  String get cellarSpiritsTab => '🥃 烈酒';

  @override
  String get cellarPairWithDish => '什么酒配这道菜？';

  @override
  String get cellarCollapseAll => '全部折叠';

  @override
  String get cellarExpandAll => '全部展开';

  @override
  String get cellarSort => '排序';

  @override
  String get cellarCategories => '分类';

  @override
  String get cellarFavorites => '收藏';

  @override
  String get cellarGridView => '网格';

  @override
  String get cellarListView => '列表';

  @override
  String get cellarClearFilters => '清除筛选';

  @override
  String get cellarNoBottlesCategory => '该分类下没有酒';

  @override
  String get cellarNoBottlesCriteria => '没有符合条件的酒';

  @override
  String get feedbackSheetTitle => '测试者反馈与标注';

  @override
  String get feedbackStylus => '画笔：';

  @override
  String get feedbackUndo => '撤销最后一笔';

  @override
  String get feedbackClear => '全部清除';

  @override
  String get feedbackHint => '圈出区域并描述您的反馈或问题...';

  @override
  String get feedbackSubmit => '发送报告';

  @override
  String get feedbackSubmitting => '正在发送...';

  @override
  String get feedbackNoScreenshot => '无可用屏幕截图';

  @override
  String get feedbackEmptyError => '请添加评论或在屏幕截图上绘制。';

  @override
  String get feedbackSuccess => '感谢您的反馈！ 🍷 报告已发送。';

  @override
  String feedbackError(String error) {
    return '发送出错：$error';
  }

  @override
  String get checkoutFastExit => '无需问卷极速出库 ⚡';

  @override
  String get checkoutFastExitSubmitting => '正在出库...';

  @override
  String get checkoutRatingSubtitle => '品饮后为佳酿打出整体评分';

  @override
  String get checkoutRecommendedBadge => '推荐';

  @override
  String get tastingWhoTastedTitle => '👥 谁品尝了这款酒？';

  @override
  String get tastingWhoTastedSubtitle => '选择品鉴者。系统将自动丰富各位的专属味蕾偏好。';

  @override
  String get tastingHowToTaste => '选择品鉴方式';

  @override
  String get tastingEachTurn => '轮流传递品鉴';

  @override
  String get tastingEachTurnDesc => '📱 传递手机：每位宾客按自己的节奏独立答卷。';

  @override
  String get tastingTogether => '全桌共同品鉴';

  @override
  String get tastingTogetherDesc => '🥂 大家讨论商议，共同完成一份问卷。';

  @override
  String get tastingBlindMode => '盲品挑战模式';

  @override
  String get tastingBlindModeDesc => '隐藏酒款全名，开启餐桌竞猜互动并在最后震撼揭晓！';

  @override
  String get tastingPrimaryProfile => '主档案';

  @override
  String get tastingAppInstalled => '已安装应用 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '已完成 $count 份问卷',
      one: '已完成 1 份问卷',
      zero: '暂无完成问卷',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 嗅觉 — 香气表达';

  @override
  String get tastingStepNezSubtitle => '轻摇酒杯，捕捉酒液升腾出的多层次芬芳与微小香气。';

  @override
  String get tastingAromaIntensity => '香气浓郁度:';

  @override
  String get tastingAromaDiscreet => '🤫 幽雅内敛';

  @override
  String get tastingAromaExplosive => '💥 浓郁奔放';

  @override
  String get tastingStepBoucheTitle => '⚖️ 口感 — 结构与平衡';

  @override
  String get tastingStepBoucheSubtitle => '描述酒液在口腔中的质感、酸涩平衡与酒体厚度。';

  @override
  String get tastingAcidity => '酸度表现:';

  @override
  String get tastingAcidityFreshness => '酸度与生津感:';

  @override
  String get tastingAcidityFlat => '🫠 柔和平缓 / 偏低';

  @override
  String get tastingAciditySharp => '⚡ 清脆凌厉 / 活泼';

  @override
  String get tastingTannins => '单宁结构:';

  @override
  String get tastingTanninsSilky => '🧶 丝滑细腻 / 柔润';

  @override
  String get tastingTanninsGrippy => '💪 紧致抓口 / 强劲';

  @override
  String get tastingMinerality => '矿物感与鲜爽度:';

  @override
  String get tastingMineralityRound => '🧈 圆润肥硕 / 饱满';

  @override
  String get tastingMineralityCrisp => '🪨 矿感分明 / 纯净';

  @override
  String get tastingEffervescence => '气泡活力:';

  @override
  String get tastingEffervescenceDelicate => '🫧 细腻绵密 / 柔和';

  @override
  String get tastingEffervescenceVibrant => '🎆 活泼持久 / 乳脂感';

  @override
  String get tastingBody => '酒体 / 质感:';

  @override
  String get tastingBodyLight => '🍃 轻盈飘逸';

  @override
  String get tastingBodyFull => '🏋️ 厚重饱满';

  @override
  String get tastingLength => '余韵 / 回味时长:';

  @override
  String get tastingLengthShort => '⏱️ 短促';

  @override
  String get tastingLengthLong => '♾️ 绵长悠远';

  @override
  String get tastingStepVerdictTitle => '✅ 终局裁决';

  @override
  String get tastingBuyAgain => '您未来还会回购这款佳酿吗？';

  @override
  String get tastingBuyAgainYes => '🤩 必须回购！';

  @override
  String get tastingBuyAgainMaybe => '🤔 视情况而定';

  @override
  String get tastingBuyAgainNo => '👎 暂时不考虑';

  @override
  String get tastingIdealMoment => '此酒的绝佳享用场景？';

  @override
  String get tastingMomentApero => '🥂 餐前开胃小酌';

  @override
  String get tastingMomentMeal => '🍽️ 家常温馨小聚';

  @override
  String get tastingMomentDinner => '🎩 高端盛宴大餐';

  @override
  String get tastingMomentRomantic => '🕯️ 浪漫烛光晚餐';

  @override
  String get tastingMomentSolo => '🧘 独处冥想时光';

  @override
  String get tastingWhatLiked => '最打动您的特质:';

  @override
  String get tastingWhatDisliked => '稍显美中不足之处:';

  @override
  String get tastingOccasionLabel => '场合 / 记忆点 (可选) ✨';

  @override
  String get tastingOccasionHint => '例如：生日纪念、乔迁之喜、老友重逢...';

  @override
  String get tastingAddPhoto => '拍下餐桌纪念照 📸';

  @override
  String get tastingPhotoSaved => '餐桌照片已珍藏 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 最终打分与总评';

  @override
  String get tastingStepImpressionSubtitle => '在细细品味闻香与口感后，给出您的综合评分。';

  @override
  String get tastingOverallFeeling => '总体感觉:';

  @override
  String get tastingScoreOutOf10 => '十分制评分:';

  @override
  String get tastingCompletedTitle => '品鉴记录已圆满保存！';

  @override
  String get tastingCompletedSubtitle => '各位的味蕾偏好档案已同步更新 ✨';

  @override
  String get tastingBottleRemoved => '瓶酒已开启并从酒窖中出库';

  @override
  String get tastingConsultDebrief => '查看侍酒师复盘解析（隐藏风味与风土密码）';

  @override
  String get tastingFinishButton => '圆满结束 ✨';

  @override
  String get tastingNextTaster => '确认 → 交给下一位品鉴者';

  @override
  String get tastingConfirmAndFinish => '确认并完成 ✨';

  @override
  String get tastingQuitTitle => '离开品鉴问卷？';

  @override
  String get tastingQuitMessage => '您当前填写的回答将不会被保存。';

  @override
  String get tastingContinue => '继续品鉴';

  @override
  String get tastingQuit => '退出';

  @override
  String tastingStartCount(int count) {
    return '开始品鉴 ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return '已同步至 $name 的应用档案 ✨';
  }

  @override
  String get tastingProfileEnriched => '味蕾画像已深度进化';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return '感官敏锐度: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle => '风味起源与佳酿密码';

  @override
  String get tastingFlavorOriginsSubtitle => '探索香气、色泽与骨架的自然孕育源泉';

  @override
  String get tastingBlindQuizTitle => '盲品餐桌竞猜 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. 这款酒的原产地大区是哪里？ 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. 最主要的葡萄品种是什么？ 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. 预估它的年份 / 陈年时间？ 📅';

  @override
  String get tastingBlindQuizQ4 => '4. 预估的市场价格区间？ 💶';

  @override
  String get tastingBlindRevealTitle => '神秘佳酿真容揭晓 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return '盲品竞猜得分: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => '酿造学与分子风味复盘';

  @override
  String get tastingSensoryAcuity => '感官敏锐度';

  @override
  String tastingPrecision(int score) {
    return '命中准确率 $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. 品种契合度与名庄印记';

  @override
  String get tastingWhatYouDetected => '您捕捉到的特征:';

  @override
  String get tastingArchetypeSignature => '此酒的经典典型风格:';

  @override
  String get tastingHiddenNuancesTitle => '在下一杯中值得留意的微妙层次:';

  @override
  String get tastingPillarsTitle => '2. 酿造科学与分子风味';

  @override
  String get tastingPillarsSubtitle => '为何这款酒拥有此等骨架、芬芳与色泽？';

  @override
  String get tastingChatWithSommelier => '与 Chatmelier 畅聊更深层的酿造秘密';

  @override
  String get aromaFruitsRouges => '红色浆果 (樱桃/草莓/覆盆子)';

  @override
  String get aromaFruitsNoirs => '黑色浆果 (黑加仑/黑莓/蓝莓)';

  @override
  String get aromaFruitsBlancs => '白核果实 (白桃/洋梨/青苹果)';

  @override
  String get aromaAgrumes => '柑橘类 (柠檬/西柚/橙皮)';

  @override
  String get aromaFloral => '花香 (紫罗兰/玫瑰/槐花)';

  @override
  String get aromaVegetal => '植物与草本 (青椒/灌木/干草)';

  @override
  String get aromaEpicesDouces => '甜香料 (肉桂/肉豆蔻/丁香)';

  @override
  String get aromaEpicesVives => '辛香料 (黑胡椒/生姜)';

  @override
  String get aromaBoise => '橡木陈酿 (香草/烤面包/椰子)';

  @override
  String get aromaBeurre => '黄油与奶油蛋卷';

  @override
  String get aromaMineral => '矿物风土 (燧石/白垩/火石)';

  @override
  String get aromaMiel => '成熟蜂蜜与果酱';

  @override
  String get aromaChocolat => '黑巧克力与烘焙咖啡';

  @override
  String get aromaFumee => '烟熏与烘烤气息';

  @override
  String get emojiDisliked => '不喜欢';

  @override
  String get emojiMeh => '平淡';

  @override
  String get emojiDecent => '尚可';

  @override
  String get emojiVeryGood => '非常好';

  @override
  String get emojiLoved => '惊艳陶醉！';

  @override
  String get likedFreshness => '清亮活泼的酸度';

  @override
  String get likedFruitiness => '纯净浓郁的果香';

  @override
  String get likedComplexity => '引人入胜的复杂度';

  @override
  String get likedElegance => '高贵雅致的平衡';

  @override
  String get likedPower => '雄浑深厚的酒体';

  @override
  String get likedSilky => '丝绒般的柔滑单宁';

  @override
  String get likedOriginality => '别具一格的风土个性';

  @override
  String get likedFoodPairing => '相得益彰的餐酒契合';

  @override
  String get likedMinerality => '贯穿始终的矿物感';

  @override
  String get likedLength => '绵长动人的回味';

  @override
  String get likedDisappointing => '平平无奇 / 略感遗憾 😕';

  @override
  String get dislikedTooAcidic => '酸度过于尖锐刺口';

  @override
  String get dislikedTooTannic => '单宁生涩粗糙';

  @override
  String get dislikedTooOaked => '橡木与香草味过重';

  @override
  String get dislikedTooAlcoholic => '酒精度过高灼喉';

  @override
  String get dislikedTooThin => '酒体过于单薄寡淡';

  @override
  String get dislikedLacksFruit => '缺乏果香表现力';

  @override
  String get dislikedTooSweet => '残糖偏高稍显甜腻';

  @override
  String get dislikedTooExpensive => '价格明显高于品质';

  @override
  String get dislikedNothing => '无可挑剔，表现极佳！';

  @override
  String get tastingStepTasters => '品鉴者';

  @override
  String get tastingStepNezNav => '闻香';

  @override
  String get tastingStepBoucheNav => '品味';

  @override
  String get tastingStepVerdictNav => '裁决';

  @override
  String get tastingStepRatingNav => '评分';

  @override
  String get tastingBack => '返回';

  @override
  String get tastingNext => '下一步';

  @override
  String get tastingSaving => '保存中...';

  @override
  String get tastingHeaderTitle => '佳酿品鉴问卷';

  @override
  String tastingAnswersOf(String name) {
    return '$name 的品鉴作答';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return '请将手机传递给 $name 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return '您的品鉴记录已妥善保存。\n接下来请 $name 作答。';
  }

  @override
  String get tastingDictateButton => '语音口述餐桌印象 🎙️';

  @override
  String get tastingDictateHint => '自然畅聊或输入，Chatmelier AI 将自动萃取香气与口感指标！';

  @override
  String get tastingDictateMicTip => '提示：点击键盘麦克风图标即可开始语音口述！';

  @override
  String get tastingTakePhoto => '拍摄餐桌佳酿照片 📸';

  @override
  String get tastingChooseGallery => '从相册中选择 🖼️';

  @override
  String get tastingConclaveSummary => '全桌品鉴结论汇编';

  @override
  String get tastingCellarMaster => '酒窖掌门人';

  @override
  String get tastingGuestTaster => '受邀品酒客';

  @override
  String tastingProfileTag(String type) {
    return '偏好画像: $type';
  }

  @override
  String get tastingFreeTastingRecorded => '随心自由品鉴笔记已收录。';

  @override
  String tastingAppearanceLabel(String appearance) {
    return '外观: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return '骨架: $structure ($caudalies 秒余韵)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return '关键分子: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return '核心线索: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return '葡萄品种: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI => '品鉴印象已由 Chatmelier AI 智能应用 ✨';

  @override
  String get tastingBlindYourPredictions => '全桌盲品预测汇总:';

  @override
  String get tastingBlindGuessCorrect => '竞猜命中！ 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt => '在最后揭晓酒标之前，快写下您的竞猜预测吧！';

  @override
  String tastingStartTaster(String name) {
    return '准备好了吗，$name！ 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 太棒了！';

  @override
  String tastingQuizWas(String answer) {
    return '(正确答案是: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      '例如：老王非常喜欢给出了8.5分，有浓郁黑醋栗和雪松香气；小李打了7分觉得酸度略微突出...';

  @override
  String get tastingDictateAnalyzing => 'AI 正在智能解析...';

  @override
  String get tastingDictateAnalyzeAndApply => '解析并自动填入品鉴表 ✨';

  @override
  String get tastingFormatExpress => '极速快品 (1页) ⚡';

  @override
  String get tastingFormatExpressDesc => '30秒内快速记录评分、核心香气与简评';

  @override
  String get tastingFormatSommelier => '侍酒师详评 (深度) 🎓';

  @override
  String get tastingFormatSommelierDesc => '深度剖析香气演变、口感平衡、余韵长度与风土特色';

  @override
  String get tastingCaudalieTooltipTitle => '什么是余香秒数 (Caudalie)？ ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 Caudalie = 吞咽或吐酒后，香气与风味在口腔中留存的 1 整秒。\n• 1 至 4 秒：轻盈清爽的易饮佳酿\n• 5 至 7 秒：平衡优美的高品质酒款\n• 8 至 12+ 秒：传世名庄的惊艳极品！';

  @override
  String get tastingAddCustomAroma => '+ 自定义香气';

  @override
  String get tastingCustomAromaDialogTitle => '添加具体香气特质';

  @override
  String get tastingCustomAromaHint => '例如：燧石矿火、野生黑莓、干玫瑰花瓣...';

  @override
  String get tastingFoodSynergyTitle => '餐酒契合度 (Synergy) 🍽️';

  @override
  String get tastingSynergySublime => '🤩 绝妙升华';

  @override
  String get tastingSynergyHarmonious => '👍 和谐协调';

  @override
  String get tastingSynergyNeutral => '😐 平淡中立';

  @override
  String get tastingSynergyClashing => '⚡ 冲突排斥';

  @override
  String get checkoutFastRatingTitle => '单手一键速评 (可选):';

  @override
  String get checkoutActionTastingTitle => '品鉴此酒';

  @override
  String get checkoutActionTastingSubtitle => '极速单页版或侍酒师专业详评版';

  @override
  String get checkoutActionDeferredRemind => '稍后提醒 🌙';

  @override
  String get checkoutActionAerationTimer => '醒酒计时器 ⏱️';
}
