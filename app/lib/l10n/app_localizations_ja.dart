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
  String get navBar => 'バー';

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
  String get cocktailsTitle => 'バー＆カクテル';

  @override
  String get cocktailsReadyToShake => 'すぐに作れる';

  @override
  String get cocktailsMissingOne => 'あと1つ不足';

  @override
  String get cocktailsManagePantry => 'バーの在庫管理';

  @override
  String get cocktailsResetPantry => '在庫をリセット';
}
