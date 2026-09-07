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
}
