// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => 'マイセラー';

  @override
  String get navCellar => 'セラー';

  @override
  String get navChat => 'チャット';

  @override
  String get navJournal => '履歴';

  @override
  String get navStats => '統計';

  @override
  String get actionMenuTitle => 'セラー操作';

  @override
  String get actionAddBottle => 'ワインを追加';

  @override
  String get actionAddBottleSub => 'ラベル撮影または手動入力';

  @override
  String get actionCheckoutBottle => '抜栓・テイスティング記録';

  @override
  String get actionCheckoutBottleSub => '試飲メモを記録して在庫を減らす';

  @override
  String get actionLookupWine => 'ワインを調べる・識別';

  @override
  String get actionLookupWineSub => 'AIによる瞬時のワイン解析と解説';

  @override
  String get searchWinePlaceholder => 'ヴィンテージ、生産者、アペラシオンを検索...';

  @override
  String get emptyCellarTitle => 'セラーにワインがありません';

  @override
  String get emptyCellarSub => '最初の1本をスキャンしてコレクションを始めましょう';

  @override
  String get emptyCellarButton => '最初の1本を追加';

  @override
  String cellarBottlesCount(int count) {
    return '$count 本';
  }

  @override
  String get cellarTotalValue => '総資産価値';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterRed => '赤ワイン';

  @override
  String get filterWhite => '白ワイン';

  @override
  String get filterRose => 'ロゼ';

  @override
  String get filterSparkling => 'スパークリング';

  @override
  String get filterSheetTitle => 'セラー絞り込み';

  @override
  String get filterReset => 'リセット';

  @override
  String get filterApply => 'フィルターを適用';

  @override
  String get filterMaturity => '熟成状態・飲み頃';

  @override
  String get maturityAtPeak => '今が飲み頃';

  @override
  String get maturityDrinkSoon => '早めの抜栓推奨';

  @override
  String get maturityAging => '熟成中（キープ）';

  @override
  String get maturityTooYoung => 'まだ若い';

  @override
  String get maturityPastPeak => 'ピーク超過';

  @override
  String get filterContinents => '大陸';

  @override
  String get filterCountries => '生産国';

  @override
  String get filterGrapes => 'ブドウ品種';

  @override
  String get filterAppellations => '産地・アペラシオン';

  @override
  String get bottleDetailInfo => 'ワイン情報とテロワール';

  @override
  String get bottleDetailDrinkingWindow => '飲み頃期間';

  @override
  String get bottleDetailTerroirMap => 'テロワール＆産地マップ';

  @override
  String get bottleDetailLabelPhoto => 'スキャンしたラベル写真';

  @override
  String get bottleDetailVintage => 'ヴィンテージ（収穫年）';

  @override
  String get bottleDetailProducer => '生産者・ワイナリー';

  @override
  String get bottleDetailRegion => '地域・産地';

  @override
  String get bottleDetailCountry => '生産国';

  @override
  String get bottleDetailAppellation => 'アペラシオン・原産地呼称';

  @override
  String get bottleDetailGrapes => '使用ブドウ品種';

  @override
  String get bottleDetailAlcohol => 'アルコール度数';

  @override
  String get bottleDetailStock => '在庫数';

  @override
  String get bottleDetailLocation => 'セラー内の保管場所';

  @override
  String get bottleDetailRack => 'ラック';

  @override
  String get bottleDetailShelf => '棚番号';

  @override
  String get bottleDetailPurchasePrice => '購入価格';

  @override
  String get bottleDetailEstimatedValue => '現在推定価値';

  @override
  String get bottleDetailFoodPairings => 'おすすめのマリアージュ・料理';

  @override
  String get bottleDetailTastingNotes => 'ソムリエプロファイル';

  @override
  String get bottleDetailDrinkButton => 'このワインを抜栓する';

  @override
  String get bottleDetailEdit => '編集';

  @override
  String get bottleDetailDelete => '削除';

  @override
  String get bottleDetailDeleteConfirm => 'このボトルをセラーから完全に削除してもよろしいですか？';

  @override
  String get deleteBottleTitle => '完全に削除';

  @override
  String get deleteBottleExplanation => '警告: 削除すると、セラーおよび履歴からすべてのデータが永久に失われます。';

  @override
  String get deleteBottleDifferenceDrink =>
      '抜栓・飲む: テイスティング履歴に保管され、統計を更新しメモを保持します。';

  @override
  String get deleteBottleDifferenceDelete =>
      '完全に削除: 痕跡を残さず消去します（誤登録や破損、重複時におすすめ）。';

  @override
  String get deleteBottleActionConfirm => '完全に削除する';

  @override
  String get deleteBottleActionDrinkInstead => '削除せず抜栓記録にする';

  @override
  String get cancel => 'キャンセル';

  @override
  String get confirm => '確認';

  @override
  String get checkoutTitle => 'セラーから抜栓・試飲';

  @override
  String get checkoutSelectPrompt => 'タップしてセラーからボトルを選択...';

  @override
  String get checkoutQtyOpened => '抜栓した本数';

  @override
  String checkoutQtyOfTotal(int total) {
    return 'セラー内の全 $total 本中';
  }

  @override
  String get checkoutRating => 'テイスティング評価';

  @override
  String get checkoutFoodPairing => '合わせた料理（任意）';

  @override
  String get checkoutFoodHint => '例: 特選牛ステーキ、キノコのリゾット...';

  @override
  String get checkoutNotes => 'テイスティングコメント・印象';

  @override
  String get checkoutNotesHint => 'アロマ、酸味、タンニン、余韻の長さ...';

  @override
  String get checkoutSubmit => '試飲記録を保存';

  @override
  String get checkoutSuccess => 'テイスティングを記録しました！';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      'こんにちは！AIソムリエのChatmelierです。料理に合うワインや飲み頃のアドバイス、セラーの在庫に基づくおすすめなど何でも聞いてください。';

  @override
  String get chatAnalyzing => 'Chatmelierがセラーを分析中...';

  @override
  String get chatInputHint => 'Chatmelierに相談する...';

  @override
  String get chatChipTonight => '🍷 今夜何を飲むべき？';

  @override
  String get chatChipSteak => '🥩 ステーキに合う手持ちのワイン';

  @override
  String get chatChipSeafood => '🐟 シーフードに最適な白ワイン';

  @override
  String get chatChipPeak => '⏰ 今まさに飲み頃のボトルは？';

  @override
  String get journalTitle => 'テイスティング日誌';

  @override
  String get journalEmpty => 'テイスティング記録がまだありません';

  @override
  String get journalEmptySub => 'セラーのワインを抜栓して記録を始めましょう';

  @override
  String journalTastedOn(String date) {
    return '$date に試飲';
  }

  @override
  String get statsTitle => 'セラー統計';

  @override
  String get statsTotalBottles => '保管本数';

  @override
  String get statsTotalValue => 'セラー総価値';

  @override
  String get statsBottlesEnjoyed => '楽しんだ本数';

  @override
  String get statsByColor => 'タイプ別比率';

  @override
  String get statsByMaturity => '熟成状態別比率';

  @override
  String get statsByRegion => '産地ランキング';

  @override
  String get statsByCountry => '生産国ランキング';

  @override
  String get profileTitle => 'プロフィールと設定';

  @override
  String get profileEmail => 'メールアドレス';

  @override
  String get profileDisplayName => '表示名';

  @override
  String get profileDefaultCurrency => 'デフォルト通貨';

  @override
  String get profileLanguage => 'アプリの言語';

  @override
  String get profileLanguageSystem => '自動（端末の設定）';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return '通貨を更新しました: $currency';
  }

  @override
  String get profileLanguageUpdated => '言語を更新しました';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get profileAbout => 'Chatmelierについて';

  @override
  String get scanTitle => 'ラベルをスキャン';

  @override
  String get scanTakePhoto => '写真を撮影';

  @override
  String get scanPickGallery => 'アルバムから選択';

  @override
  String get scanAnalyzing => 'AIがラベルを分析しています...';

  @override
  String get scanIdentified => 'ワインを特定しました ✨';

  @override
  String get scanSaveToCellar => 'セラーに追加する';

  @override
  String get loginTitle => 'ログイン';

  @override
  String get loginTagline => 'AIと創るスマートワインセラー';

  @override
  String get loginTabMagicLink => '✉️ メールリンク';

  @override
  String get loginTabPassword => '🔑 パスワード';

  @override
  String get loginEmailLabel => 'メールアドレス';

  @override
  String get loginPasswordLabel => 'パスワード';

  @override
  String get loginSendMagicLink => 'ログインリンクを送信';

  @override
  String get loginSignInButton => 'ログイン';

  @override
  String get loginOrDivider => 'または';

  @override
  String get loginGoogleButton => 'Googleで続ける';

  @override
  String get loginRegisterLink => 'アカウントをお持ちでないですか？ 新規登録';

  @override
  String get registerTitle => 'アカウント登録';

  @override
  String get registerNameLabel => 'お名前 / ニックネーム';

  @override
  String get registerSubmitButton => 'アカウントを作成';

  @override
  String get registerFillAllFields => 'すべての項目を入力してください';

  @override
  String get registerWelcome => '🎉 Chatmelierへようこそ！';

  @override
  String get registerErrorGeneric => '登録エラーが発生しました';

  @override
  String get authWelcome => 'Chatmelierへようこそ';

  @override
  String get authSubtitle => 'あなたのスマートワインセラー管理＆AI専属ソムリエ';

  @override
  String get authGoogle => 'Googleでログイン';

  @override
  String get authMagicLink => 'メールリンクでログイン';

  @override
  String get authEmail => 'メールアドレス';

  @override
  String get authNoAccount => 'アカウントをお持ちでない方は登録';

  @override
  String get authHaveAccount => 'すでにアカウントをお持ちの方はログイン';

  @override
  String get changelogTitle => 'バージョン履歴と更新情報';

  @override
  String get changelogEmpty => '更新情報はありません。';

  @override
  String get scratchcardTitle => '世界のテロワールスクラッチマップ';

  @override
  String get profileChangelog => 'バージョン履歴と新機能';

  @override
  String get profileScratchcard => '世界のテロワールスクラッチマップ';

  @override
  String get navProfile => 'マイページ';

  @override
  String get quickActions => 'クイックアクション';

  @override
  String get appSubtitle => 'ソムリエ＆ワインセラー';

  @override
  String get profileTabPalate => 'テイスティング';

  @override
  String get profileTabSettings => '設定';

  @override
  String get profileTabTools => 'ツール';

  @override
  String get profileTabAccount => 'アカウント';

  @override
  String get profileTheme => 'テーマ / 外観';

  @override
  String get profileThemeLight => 'ライト ☀️';

  @override
  String get profileThemeDark => 'ダーク 🌙';

  @override
  String get profileThemeSystem => 'システム ⚙️';

  @override
  String get profileFriends => 'フレンド＆味覚マップ 🍷';

  @override
  String get profileExport => 'セラー＆査定レポートのエクスポート 📊';

  @override
  String get profileDeleteAccount => 'アカウントを完全に削除';

  @override
  String get profileDeleteConfirmTitle => '完全に削除';

  @override
  String get profileDeleteConfirmMsg => 'この操作は取り消せません。すべてのデータが消去されます。';

  @override
  String get badgesGalleryTitle => 'トロフィーギャラリー';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total 獲得済み • 達成率 $pct%';
  }

  @override
  String get badgesFilterAll => 'すべて';

  @override
  String get badgesEmpty => 'このカテゴリーにはバッジがありません。';

  @override
  String get badgesUnlockedChip => '獲得済み ✨';

  @override
  String get badgesStatusUnlocked => 'バッジを獲得しました！';

  @override
  String get badgesStatusInProgress => '進行中';

  @override
  String get badgesObjectiveLabel => '目標:';

  @override
  String get badgesChatmelierLoreTitle => 'シャトゥメリエのワイン科学と歴史';

  @override
  String get badgesCloseButton => '閉じる';

  @override
  String get badgesTierLabel => 'ランク';

  @override
  String get badgesShowcaseTitle => 'トロフィー＆バッジ';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked / $total 獲得';
  }

  @override
  String get badgesShowcaseGallery => 'ギャラリー';

  @override
  String get save => '保存';

  @override
  String get continueAnyway => 'そのまま続行';

  @override
  String get cellarDetected => 'セラーを検出: ';

  @override
  String proximityWifi(String ssid) {
    return 'Wi-Fi「$ssid」に接続中';
  }

  @override
  String proximityGps(String distance) {
    return 'GPS位置（$distance）を検出';
  }

  @override
  String get proximitySwitch => '切り替える';

  @override
  String get proximityIgnore => '無視する';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍「$cellar」に自動的に切り替えました';
  }

  @override
  String get distantCellarTitle => '離れたセラーを検出';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return '現在、別のセラー「$cellar」に関連付けられたWi-Fi「$ssid」に接続されています。';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return '現在、「$cellar」から約$distance離れた場所にいます。';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\nそれでもこのボトルをセラー「$cellar」に追加しますか？';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\nそれでもこのボトルをセラー「$cellar」から出庫しますか？';
  }

  @override
  String get ratingExceptional => '🏆 傑出';

  @override
  String get ratingRemarkable => '✨ 素晴らしい';

  @override
  String get ratingVeryGood => '🍷 とても良い';

  @override
  String get ratingPleasant => '👍 心地よい';

  @override
  String get ratingPassable => '普通';

  @override
  String get checkoutWhoTasted => '誰と一緒にこのワインを楽しみましたか？';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: '本',
      one: '本',
    );
    return '$producer • 在庫: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => 'ゲストを追加';

  @override
  String get checkoutAddGuestHint => '名前を追加 (母、父...)';

  @override
  String get checkoutCloseAndTaste => '閉じてテイスティングを楽しむ 🍷';

  @override
  String get checkoutSommelierThinking => 'ソムリエがテイスティングの物語を準備中...';

  @override
  String get checkoutAerationTimerActive => '⏱️ ロック画面でエアレーションタイマーが作動中！';

  @override
  String get checkoutStartAerationTimer => 'タイマーを開始 ⏱️';

  @override
  String get checkoutAerationTimerTitle => 'エアレーションタイマー';

  @override
  String get checkoutDelayedTonight => '今夜 22:00';

  @override
  String get checkoutDelayedTonightSub => '食後にゆっくりと余韻を振り返るのに最適';

  @override
  String get checkoutDelayedTomorrow => '明朝 11:00';

  @override
  String get checkoutDelayedTomorrowSub => '静かな時間にテイスティングの印象を記録';

  @override
  String get checkoutDelayedWeekend => '今週末 (土曜 11:00)';

  @override
  String get checkoutDelayedWeekendSub => '休日のリラックスした時間に';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return '2時間後 ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub => 'テイスティング終了時のクイックリマインダー';

  @override
  String get checkoutDelayedCustom => '日時を指定...';

  @override
  String get reviewPackagingDetected => 'パッケージを検出';

  @override
  String get reviewSingleBottleOnly => 'いいえ、1本のみ';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return 'はい、$count本';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 在庫が正常に更新されました！（セラー内: $count本）';
  }

  @override
  String get reviewVintageYear => 'ヴィンテージ / 収穫年';

  @override
  String get reviewNonVintage => 'スキップ / ノン・ヴィンテージ (NV)';

  @override
  String get reviewValidate => '確定する';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾「$name」がセラーに正常に追加されました！';
  }

  @override
  String get reviewBottleAnalysis => 'ボトルの分析';

  @override
  String get reviewDiscard => '破棄';

  @override
  String get reviewDiscardConfirmTitle => '入力を破棄しますか？';

  @override
  String get reviewContinueEditing => '編集を続ける';

  @override
  String get reviewDiscardWithoutSaving => '保存せずに破棄';

  @override
  String get reviewBottleDetails => 'ボトルの詳細';

  @override
  String get reviewStockInCellar => 'セラー内在庫';

  @override
  String get reviewStockAddition => '追加';

  @override
  String get reviewStockNewTotal => '新しい合計';

  @override
  String get reviewQuantityToAdd => '追加する数量:';

  @override
  String get reviewSeparateEntry => '別のエントリを作成（ラック/価格が異なる場合）';

  @override
  String get reviewRetryAi => 'AI分析を再試行';

  @override
  String get reviewEnlarge => '拡大';

  @override
  String get reviewGeneralInfo => '基本情報';

  @override
  String get reviewOriginTerroir => '産地 & テロワール';

  @override
  String get reviewQuantityPurchase => '数量 & 購入情報';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fiを検出して連携:「$ssid」';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Wi-Fiを検出できませんでした（位置情報を有効にするか手動入力してください）';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS座標を取得 ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible => 'GPS位置を取得できません。位置情報の権限を確認してください。';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ セラー「$cellar」が正常に作成されました！';
  }

  @override
  String cellarCreationError(String error) {
    return '作成エラー: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 m（高精度）';

  @override
  String get cellarRadiusRecommended => '300 m（推奨）';

  @override
  String get cellarRadius500m => '500 m';

  @override
  String get cellarRadius1km => '1 km';

  @override
  String get cellarRadius3km => '3 km';

  @override
  String get cellarCreateButton => 'セラーを作成';

  @override
  String get cellarUseCurrentGps => '現在のGPS位置を設定';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ セラー「$cellar」の設定を更新しました';
  }

  @override
  String cellarUpdateError(String error) {
    return '更新エラー: $error';
  }

  @override
  String get wineTypeRed => '赤ワイン 🍷';

  @override
  String get wineTypeWhite => '白ワイン 🥂';

  @override
  String get wineTypeRose => 'ロゼワイン 🌸';

  @override
  String get wineTypeSparkling => 'スパークリング 🍾';

  @override
  String get wineTypeDessert => 'デザート / 極甘口 🍯';

  @override
  String get wineTypeLiqueur => 'リキュール 🍯';

  @override
  String get wineTypeSpirit => 'スピリッツ 🥃';

  @override
  String get wineTypeGrappa => 'グラッパ 🍇';

  @override
  String get wineTypeEauDeVie => 'フルーツブランデー 🍐';

  @override
  String get wineTypeWhisky => 'ウイスキー 🥃';

  @override
  String get wineTypeRum => 'ラム 🏴‍☠️';

  @override
  String get wineTypeGin => 'ジン 🍸';

  @override
  String get wineTypeVodka => 'ウォッカ 🧊';

  @override
  String get wineTypeTequila => 'テキーラ 🌵';

  @override
  String get wineTypeCognac => 'コニャック 🍷';

  @override
  String get cellarCreateTitle => '新しいセラーを作成';

  @override
  String get cellarManageTitle => 'セラーの管理';

  @override
  String get cellarNameLabel => 'セラー名 *';

  @override
  String get cellarNameHint => '例: 自宅セラー、別邸ワインセラー';

  @override
  String get cellarNameRequired => '名前を入力してください';

  @override
  String get cellarLocationLabel => '場所 / 都市 (任意)';

  @override
  String get cellarLocationHint => '例: 東京、ボルドー';

  @override
  String get cellarNicknameLabel => 'ニックネーム / 設置部屋 (任意)';

  @override
  String get cellarNicknameHint => '例: 地下室、リビングワインセラー';

  @override
  String get cellarDescriptionLabel => '説明 (任意)';

  @override
  String get cellarDescriptionHint => '例: 温度14℃、湿度70%の地下セラー';

  @override
  String get cellarWifiLabel => '関連Wi-Fi (任意)';

  @override
  String get cellarWifiHint => '例: Home-Cellar-WiFi';

  @override
  String get cellarLinkCurrentWifi => '現在のWi-Fiを関連付ける';

  @override
  String get cellarCaptureCurrentWifiTooltip => '現在のWi-Fiを取得';

  @override
  String get cellarRadiusLabel => 'GPS検出半径';

  @override
  String get cellarAutoDetectionHeader => '自動検出 & スマート切り替え';

  @override
  String get cellarAutoDetectionDesc =>
      'Wi-FiネットワークまたはGPS座標を連携すると、その場所に到着した際に自動でセラーが切り替わります。';

  @override
  String get cellarLatitudeLabel => '緯度';

  @override
  String get cellarLongitudeLabel => '経度';

  @override
  String get checkoutGuidedTasting => 'ガイド付きテイスティング';

  @override
  String get checkoutGuidedTastingShared => '一人ずつ、またはみんなで印象を共有';

  @override
  String get checkoutGuidedTastingSolo => '外観、香り、味わいを分析して味覚プロフィールを洗練';

  @override
  String get checkoutUncorkNowRateLater => '今すぐ抜栓、あとで評価';

  @override
  String get checkoutUncorkNowRateLaterSub => '即時出庫 • リマインダー時刻を選択 (今夜、明日...)';

  @override
  String get checkoutUncorkAeration => '抜栓 & エアレーションタイマー';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return '即時出庫 • $minutes分のエアレーション推奨';
  }

  @override
  String get checkoutUncorkAerationSub => '即時出庫 • デキャンタージュ / エアレーションタイマー';

  @override
  String get checkoutSommelierServiceAdvice => 'ソムリエのサーヴィスアドバイス';

  @override
  String get checkoutHistoryAnecdotes => '物語 & エピソード';

  @override
  String get checkoutNoDecanting => 'デキャンタージュ不要';

  @override
  String get checkoutStoryTitle => 'このボトルの物語 📖';

  @override
  String get checkoutStorySubtitle => '食卓で語り合える魅力的なエピソード';

  @override
  String get checkoutStoryTerroir => 'テロワール & ブドウ品種';

  @override
  String get checkoutStoryVintage => 'ヴィンテージの物語';

  @override
  String get checkoutStoryTastingSecret => 'テイスティングの秘密';

  @override
  String get checkoutStoryTableAnecdote => 'テーブルでの小話';

  @override
  String get checkoutJournalArchivedNotice =>
      'ご安心ください: このボトルは写真やメモとともにテイスティング日誌に大切に保存されます。';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return 'ボトルを抜栓しました！エアレーションタイマー（$minutes分）がロック画面で作動中です。';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      'ボトルは即座に抜栓され出庫されます。テイスティング前のエアレーション時間を確認してください:';

  @override
  String get checkoutRateWine => 'ワインを評価';

  @override
  String checkoutStartTimerAction(int minutes) {
    return 'タイマー $minutes分 ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return 'ソムリエのアドバイス: $minutes分のエアレーション。ロック画面タイマー準備完了。';
  }

  @override
  String get checkoutAdviceReminderSnack => '印象を記録するためのリマインダーを設定しました。';

  @override
  String get checkoutBottleRemovedSuccess => 'ボトルがセラーから出庫されました！';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return 'テイスティングをお楽しみください。$dateにリマインダーをお送りします。';
  }

  @override
  String get checkoutWhoTastedSubtitle => '各参加者の味覚プロフィールが自動的に強化されます。';

  @override
  String checkoutCellarOf(String name) {
    return '$nameのセラー';
  }

  @override
  String checkoutStockBout(int count) {
    return '在庫: $count本';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      'このテイスティングに同席しているご家族やご友人を追加します（例: お母さん、お父さん、花子...）。';

  @override
  String get checkoutAddGuestNameLabel => '名前 / ニックネーム';

  @override
  String get checkoutDelayedSheetTitle => '抜栓してあとで評価';

  @override
  String get checkoutDelayedSheetSubtitle => 'テイスティングの感想をいつ記録しますか？';

  @override
  String checkoutDelayedTonightTime(String time) {
    return '今夜 2時間後 ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => '今夜 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return '今夜 $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return '明日 $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return '$date $time';
  }

  @override
  String get add => '追加';

  @override
  String get cellarWinesTab => '🍷 ワイン';

  @override
  String get cellarSpiritsTab => '🥃 スピリッツ';

  @override
  String get cellarPairWithDish => '料理に合うワインは？';

  @override
  String get cellarCollapseAll => 'すべて折りたたむ';

  @override
  String get cellarExpandAll => 'すべて展開';

  @override
  String get cellarSort => '並び替え';

  @override
  String get cellarCategories => 'カテゴリー';

  @override
  String get cellarFavorites => 'お気に入り';

  @override
  String get cellarGridView => 'グリッド';

  @override
  String get cellarListView => 'リスト';

  @override
  String get cellarClearFilters => 'フィルターをクリア';

  @override
  String get cellarNoBottlesCategory => 'このカテゴリーにボトルはありません';

  @override
  String get cellarNoBottlesCriteria => '条件に一致するボトルがありません';

  @override
  String get feedbackSheetTitle => 'テスターフィードバック＆アノテーション';

  @override
  String get feedbackStylus => 'ペン：';

  @override
  String get feedbackUndo => '最後の線を元に戻す';

  @override
  String get feedbackClear => 'すべて消去';

  @override
  String get feedbackHint => '該当箇所を囲んで、フィードバックや不具合を記入してください...';

  @override
  String get feedbackSubmit => 'レポートを送信';

  @override
  String get feedbackSubmitting => '送信中...';

  @override
  String get feedbackNoScreenshot => 'スクリーンショットはありません';

  @override
  String get feedbackEmptyError => 'コメントを追加するか、スクリーンショットに書き込んでください。';

  @override
  String get feedbackSuccess => 'フィードバックありがとうございます！ 🍷 レポートを送信しました。';

  @override
  String feedbackError(String error) {
    return '送信エラー：$error';
  }

  @override
  String get checkoutFastExit => 'アンケートなしでクイック出庫 ⚡';

  @override
  String get checkoutFastExitSubmitting => '出庫処理中...';

  @override
  String get checkoutRatingSubtitle => 'テイスティング後の全体評価を入力';

  @override
  String get checkoutRecommendedBadge => 'おすすめ';

  @override
  String get tastingWhoTastedTitle => '👥 誰がこのワインを試飲しましたか？';

  @override
  String get tastingWhoTastedSubtitle => 'テイスターを選択してください。味覚プロファイルが自動的に学習されます。';

  @override
  String get tastingHowToTaste => 'テイスティング方法';

  @override
  String get tastingEachTurn => '順番にテイスティング';

  @override
  String get tastingEachTurnDesc => '📱 スマホを回しながら: 各自が自分のペースで回答します。';

  @override
  String get tastingTogether => 'みんなで一緒に';

  @override
  String get tastingTogetherDesc => '🥂 全員で話し合いながら1つのアンケートを完成させます。';

  @override
  String get tastingBlindMode => 'ブラインドテイスティングモード';

  @override
  String get tastingBlindModeDesc => 'ワイン名を伏せて、食卓でクイズを楽しんだ後に正解を発表！';

  @override
  String get tastingPrimaryProfile => 'メインプロファイル';

  @override
  String get tastingAppInstalled => 'アプリインストール済み 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件完了',
      one: '1件完了',
      zero: 'アンケート未完了',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 香り — アロマの表現';

  @override
  String get tastingStepNezSubtitle => 'グラスを回して立ち上るアロマとニュアンスを感じ取ってください。';

  @override
  String get tastingAromaIntensity => '香りの強さ:';

  @override
  String get tastingAromaDiscreet => '🤫 穏やか・繊細';

  @override
  String get tastingAromaExplosive => '💥 華やか・力強い';

  @override
  String get tastingStepBoucheTitle => '⚖️ 味わい — バランス';

  @override
  String get tastingStepBoucheSubtitle => '口に含んだときのテクスチャーと調和を表現してください。';

  @override
  String get tastingAcidity => '酸味:';

  @override
  String get tastingAcidityFreshness => '酸味 & フレッシュ感:';

  @override
  String get tastingAcidityFlat => '🫠 穏やか / まろやか';

  @override
  String get tastingAciditySharp => '⚡ キレがある / シャープ';

  @override
  String get tastingTannins => 'タンニン (渋み):';

  @override
  String get tastingTanninsSilky => '🧶 シルキー / 滑らか';

  @override
  String get tastingTanninsGrippy => '💪 骨格がある / 力強い';

  @override
  String get tastingMinerality => 'ミネラル感 & 鮮感:';

  @override
  String get tastingMineralityRound => '🧈 まろやか / リッチ';

  @override
  String get tastingMineralityCrisp => '🪨 ミネラリー / 引き締まった';

  @override
  String get tastingEffervescence => '泡立ち:';

  @override
  String get tastingEffervescenceDelicate => '🫧 きめ細やか / 繊細';

  @override
  String get tastingEffervescenceVibrant => '🎆 快活 / クリーミー';

  @override
  String get tastingBody => 'ボディ / 密度:';

  @override
  String get tastingBodyLight => '🍃 軽やか / エレガント';

  @override
  String get tastingBodyFull => '🏋️ 重厚 / フルボディ';

  @override
  String get tastingLength => '余韻 / 長さ:';

  @override
  String get tastingLengthShort => '⏱️ 短め';

  @override
  String get tastingLengthLong => '♾️ 長く続く余韻';

  @override
  String get tastingStepVerdictTitle => '✅ 総合判定';

  @override
  String get tastingBuyAgain => 'このボトルをまた購入したいですか？';

  @override
  String get tastingBuyAgainYes => '🤩 ぜひ買いたい！';

  @override
  String get tastingBuyAgainMaybe => '🤔 機会があれば';

  @override
  String get tastingBuyAgainNo => '👎 今回は見送り';

  @override
  String get tastingIdealMoment => 'このワインに最適なシーンは？';

  @override
  String get tastingMomentApero => '🥂 アペリティフ / 乾杯';

  @override
  String get tastingMomentMeal => '🍽️ カジュアルな食事';

  @override
  String get tastingMomentDinner => '🎩 特別なディナー';

  @override
  String get tastingMomentRomantic => '🕯️ ロマンチックな夜';

  @override
  String get tastingMomentSolo => '🧘 一人の贅沢な時間';

  @override
  String get tastingWhatLiked => '特に気に入った点:';

  @override
  String get tastingWhatDisliked => '少し気になった点:';

  @override
  String get tastingOccasionLabel => 'シーン / 思い出 (任意) ✨';

  @override
  String get tastingOccasionHint => '例: 誕生日、記念日、友人との語らい...';

  @override
  String get tastingAddPhoto => '食卓の記念写真を追加 📸';

  @override
  String get tastingPhotoSaved => '写真が保存されました 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 最終評価 & 印象';

  @override
  String get tastingStepImpressionSubtitle => '香りと味わいをじっくり堪能した後の総合評価をつけてください。';

  @override
  String get tastingOverallFeeling => '全体の印象:';

  @override
  String get tastingScoreOutOf10 => '10点満点での評価:';

  @override
  String get tastingCompletedTitle => 'テイスティング完了 & 記録完了！';

  @override
  String get tastingCompletedSubtitle => '味覚プロファイルが正常に更新されました ✨';

  @override
  String get tastingBottleRemoved => 'ボトルが抜栓され、セラーから出庫されました';

  @override
  String get tastingConsultDebrief => 'ソムリエのデブリーフィングを見る（隠れたニュアンス & テロワール）';

  @override
  String get tastingFinishButton => '完了 ✨';

  @override
  String get tastingNextTaster => '確定 → 次のテイスターへ';

  @override
  String get tastingConfirmAndFinish => '確定して終了 ✨';

  @override
  String get tastingQuitTitle => 'アンケートを終了しますか？';

  @override
  String get tastingQuitMessage => '回答は保存されません。';

  @override
  String get tastingContinue => '続ける';

  @override
  String get tastingQuit => '終了する';

  @override
  String tastingStartCount(int count) {
    return '開始 ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return '$nameのアプリに同期しました ✨';
  }

  @override
  String get tastingProfileEnriched => '味覚プロファイルが強化されました';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return '官能鋭敏度: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle => '香りの起源 & ワインの秘密';

  @override
  String get tastingFlavorOriginsSubtitle => 'アロマ、色調、骨格がどこから生まれるのかを探求';

  @override
  String get tastingBlindQuizTitle => 'ブラインドテイスティング・テーブルクイズ 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. 原産地（地域）はどこでしょう？ 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. 主なブドウ品種は何でしょう？ 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. 推定年数 / ヴィンテージは？ 📅';

  @override
  String get tastingBlindQuizQ4 => '4. 推定価格帯は？ 💶';

  @override
  String get tastingBlindRevealTitle => 'ミステリーボトルの正体発表 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return 'ブラインドクイズ スコア: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => '醸造学 & 分子デブリーフィング';

  @override
  String get tastingSensoryAcuity => '感覚の鋭敏度';

  @override
  String tastingPrecision(int score) {
    return '的中率 $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. 一致度 & クリュの個性';

  @override
  String get tastingWhatYouDetected => 'あなたが感じ取った要素:';

  @override
  String get tastingArchetypeSignature => 'このワインの典型的な個性:';

  @override
  String get tastingHiddenNuancesTitle => '次の一杯で見つけたい繊細なニュアンス:';

  @override
  String get tastingPillarsTitle => '2. 醸造科学 & 分子構造';

  @override
  String get tastingPillarsSubtitle => 'なぜこのワインはこの骨格、アロマ、色調を持つのか？';

  @override
  String get tastingChatWithSommelier => 'Chatmelierでワイン造りの秘密をさらに深掘りする';

  @override
  String get aromaFruitsRouges => '赤系果実 (チェリー・イチゴ)';

  @override
  String get aromaFruitsNoirs => '黒系果実 (カシス・ブルーベリー)';

  @override
  String get aromaFruitsBlancs => '白系果実 (白桃・洋ナシ・リンゴ)';

  @override
  String get aromaAgrumes => '柑橘類 (レモン・グレープフルーツ)';

  @override
  String get aromaFloral => 'フローラル (スミレ・バラ)';

  @override
  String get aromaVegetal => '植物・ハーブ (ピーマン・下草)';

  @override
  String get aromaEpicesDouces => '甘やかなスパイス (シナモン・ナツメグ)';

  @override
  String get aromaEpicesVives => '刺激的なスパイス (黒コショウ)';

  @override
  String get aromaBoise => 'オーク・樽香 (ヴァニラ・トースト)';

  @override
  String get aromaBeurre => 'バター・ブリオッシュ';

  @override
  String get aromaMineral => 'ミネラル・火打石';

  @override
  String get aromaMiel => '蜂蜜・コンフィチュール';

  @override
  String get aromaChocolat => 'チョコレート・カカオ';

  @override
  String get aromaFumee => 'スモーク・燻製香';

  @override
  String get emojiDisliked => 'いまいち';

  @override
  String get emojiMeh => '普通';

  @override
  String get emojiDecent => 'まあまあ';

  @override
  String get emojiVeryGood => 'とても良い';

  @override
  String get emojiLoved => '最高！';

  @override
  String get likedFreshness => 'みずみずしいフレッシュ感';

  @override
  String get likedFruitiness => 'ピュアな果実味';

  @override
  String get likedComplexity => 'アロマの複雑さ';

  @override
  String get likedElegance => 'エレガンス・気品';

  @override
  String get likedPower => '力強さ・豊かなボディ';

  @override
  String get likedSilky => 'シルキーで滑らかな舌触り';

  @override
  String get likedOriginality => '個性的でユニークな魅力';

  @override
  String get likedFoodPairing => 'お料理との絶妙な調和';

  @override
  String get likedMinerality => '引き締まったミネラル感';

  @override
  String get likedLength => '長く心に残る余韻';

  @override
  String get likedDisappointing => '特になし / 残念 😕';

  @override
  String get dislikedTooAcidic => '酸味が強すぎる';

  @override
  String get dislikedTooTannic => '渋み (タンニン) が強すぎる';

  @override
  String get dislikedTooOaked => '樽香 / ヴァニラが強すぎる';

  @override
  String get dislikedTooAlcoholic => 'アルコール感が強すぎる';

  @override
  String get dislikedTooThin => '軽すぎる / 水っぽい';

  @override
  String get dislikedLacksFruit => '果実味が足りない';

  @override
  String get dislikedTooSweet => '甘すぎる';

  @override
  String get dislikedTooExpensive => '価格に見合わない';

  @override
  String get dislikedNothing => '文句なし、完璧でした！';

  @override
  String get tastingStepTasters => 'テイスター';

  @override
  String get tastingStepNezNav => '香り';

  @override
  String get tastingStepBoucheNav => '味わい';

  @override
  String get tastingStepVerdictNav => '判定';

  @override
  String get tastingStepRatingNav => '総合評価';

  @override
  String get tastingBack => '戻る';

  @override
  String get tastingNext => '次へ';

  @override
  String get tastingSaving => '保存中...';

  @override
  String get tastingHeaderTitle => 'テイスティングアンケート';

  @override
  String tastingAnswersOf(String name) {
    return '$nameの回答';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return '$nameにスマートフォンを渡してください 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return 'あなたの回答を記録しました。\n次は$nameの番です。';
  }

  @override
  String get tastingDictateButton => 'テーブルでの感想を音声入力 🎙️';

  @override
  String get tastingDictateHint =>
      '自然に話すか入力してください。Chatmelier AIがアロマと味わいのバランスを自動補完します！';

  @override
  String get tastingDictateMicTip => 'ヒント: キーボードのマイクボタンを押して声で入力できます！';

  @override
  String get tastingTakePhoto => '食卓の写真を撮影 📸';

  @override
  String get tastingChooseGallery => 'ギャラリーから選択 🖼️';

  @override
  String get tastingConclaveSummary => 'テイスティング結果のまとめ';

  @override
  String get tastingCellarMaster => 'セラーマスター';

  @override
  String get tastingGuestTaster => 'ゲストテイスター';

  @override
  String tastingProfileTag(String type) {
    return 'プロファイル: $type';
  }

  @override
  String get tastingFreeTastingRecorded => 'フリーテイスティングが記録されました。';

  @override
  String tastingAppearanceLabel(String appearance) {
    return '外観: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return '骨格: $structure ($caudaliesコダリー)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return '主要分子: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return 'キー要素: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return 'ブドウ品種: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI => 'Chatmelier AIによってテイスティング印象が適用されました ✨';

  @override
  String get tastingBlindYourPredictions => 'ブラインド予想のまとめ:';

  @override
  String get tastingBlindGuessCorrect => '正解です！ 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt => '最後の正解発表の前に、みんなで予想を立ててみましょう！';

  @override
  String tastingStartTaster(String name) {
    return 'さあ、始めましょう、$name！ 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 お見事！';

  @override
  String tastingQuizWas(String answer) {
    return '(正解: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      '例: ベルナールは大絶賛で8.5点、下草とカシスの香り。キャロは7点で少し酸味が際立つと感じた...';

  @override
  String get tastingDictateAnalyzing => '分析中...';

  @override
  String get tastingDictateAnalyzeAndApply => '分析してシートに反映 ✨';

  @override
  String get tastingFormatExpress => 'エクスプレス形式 (1ページ) ⚡';

  @override
  String get tastingFormatExpressDesc => '30秒で点数、主要アロマ、評価を入力';

  @override
  String get tastingFormatSommelier => 'ソムリエ形式 (詳細) 🎓';

  @override
  String get tastingFormatSommelierDesc => '香り、口当たりのバランス、余韻、テロワールを徹底分析';

  @override
  String get tastingCaudalieTooltipTitle => 'コダリー (Caudalie) とは？ ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1コダリー = 飲み込んだ（または吐き出した）後の香りの持続時間1秒間。\n• 1〜4コダリー：軽やかですっきりしたワイン\n• 5〜7コダリー：バランスの取れた素晴らしいワイン\n• 8〜12+コダリー：傑出した偉大なグラン・ヴァン！';

  @override
  String get tastingAddCustomAroma => '+ カスタムアロマ';

  @override
  String get tastingCustomAromaDialogTitle => '固有のアロマを追加';

  @override
  String get tastingCustomAromaHint => '例: スモーキーな火打石、野イチゴ、乾燥したバラ...';

  @override
  String get tastingFoodSynergyTitle => '料理との相性 (マリアージュ) 🍽️';

  @override
  String get tastingSynergySublime => '🤩 最高のマリアージュ';

  @override
  String get tastingSynergyHarmonious => '👍 調和している';

  @override
  String get tastingSynergyNeutral => '😐 普通 / 中立';

  @override
  String get tastingSynergyClashing => '⚡ ぶつかり合う';

  @override
  String get checkoutFastRatingTitle => 'ワンタップ簡単評価 (任意):';

  @override
  String get checkoutActionTastingTitle => 'このワインをテイスティング';

  @override
  String get checkoutActionTastingSubtitle => 'エクスプレス (1ページ) または詳細ソムリエ形式';

  @override
  String get checkoutActionDeferredRemind => 'あとでリマインド 🌙';

  @override
  String get checkoutActionAerationTimer => 'エアレーションタイマー ⏱️';
}
