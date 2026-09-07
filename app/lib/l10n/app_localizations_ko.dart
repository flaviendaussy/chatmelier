// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Chatmelier';

  @override
  String get defaultCellarName => '내 와인셀러';

  @override
  String get navCellar => '셀러';

  @override
  String get navChat => '소믈리에';

  @override
  String get navJournal => '기록';

  @override
  String get navStats => '통계';

  @override
  String get actionMenuTitle => '셀러 메뉴';

  @override
  String get actionAddBottle => '와인 등록하기';

  @override
  String get actionAddBottleSub => '라벨 스캔 또는 직접 입력';

  @override
  String get actionCheckoutBottle => '오픈 및 시음 기록';

  @override
  String get actionCheckoutBottleSub => '시음 노트를 남기고 재고 차감';

  @override
  String get actionLookupWine => '와인 조회 및 식별';

  @override
  String get actionLookupWineSub => 'AI를 통한 즉각적인 테루아 분석';

  @override
  String get searchWinePlaceholder => '빈티지, 생산자, 아펠라시옹 검색...';

  @override
  String get emptyCellarTitle => '셀러가 비어 있습니다';

  @override
  String get emptyCellarSub => '첫 번째 와인을 스캔하여 컬렉션을 시작하세요';

  @override
  String get emptyCellarButton => '첫 와인 등록하기';

  @override
  String cellarBottlesCount(int count) {
    return '$count 병';
  }

  @override
  String get cellarTotalValue => '셀러 총 가치';

  @override
  String get filterAll => '전체';

  @override
  String get filterRed => '레드';

  @override
  String get filterWhite => '화이트';

  @override
  String get filterRose => '로제';

  @override
  String get filterSparkling => '스파클링';

  @override
  String get filterSheetTitle => '셀러 필터';

  @override
  String get filterReset => '초기화';

  @override
  String get filterApply => '필터 적용';

  @override
  String get filterMaturity => '시음 적기 및 숙성도';

  @override
  String get maturityAtPeak => '지금이 절정기';

  @override
  String get maturityDrinkSoon => '빠른 시음 권장';

  @override
  String get maturityAging => '숙성 중 (보관)';

  @override
  String get maturityTooYoung => '아직 어림';

  @override
  String get maturityPastPeak => '적기 지남';

  @override
  String get filterContinents => '대륙';

  @override
  String get filterCountries => '생산국';

  @override
  String get filterGrapes => '포도 품종';

  @override
  String get filterAppellations => '지역 및 명칭';

  @override
  String get bottleDetailInfo => '와인 정보 및 테루아';

  @override
  String get bottleDetailDrinkingWindow => '추천 시음 시기';

  @override
  String get bottleDetailTerroirMap => '테루아 및 원산지 지도';

  @override
  String get bottleDetailLabelPhoto => '스캔한 원본 라벨 사진';

  @override
  String get bottleDetailVintage => '빈티지';

  @override
  String get bottleDetailProducer => '와이너리 / 생산자';

  @override
  String get bottleDetailRegion => '생산 지역';

  @override
  String get bottleDetailCountry => '국가';

  @override
  String get bottleDetailAppellation => '원산지 명칭 (AOC)';

  @override
  String get bottleDetailGrapes => '품종';

  @override
  String get bottleDetailAlcohol => '알코올 도수';

  @override
  String get bottleDetailStock => '보유 수량';

  @override
  String get bottleDetailLocation => '셀러 보관 위치';

  @override
  String get bottleDetailRack => '랙';

  @override
  String get bottleDetailShelf => '선반';

  @override
  String get bottleDetailPurchasePrice => '구매 가격';

  @override
  String get bottleDetailEstimatedValue => '현재 추정 가치';

  @override
  String get bottleDetailFoodPairings => '추천 마리아주 / 요리';

  @override
  String get bottleDetailTastingNotes => '소믈리에 프로필';

  @override
  String get bottleDetailDrinkButton => '이 와인 오픈하기';

  @override
  String get bottleDetailEdit => '수정';

  @override
  String get bottleDetailDelete => '삭제';

  @override
  String get bottleDetailDeleteConfirm => '이 와인을 셀러에서 완전히 삭제하시겠습니까?';

  @override
  String get deleteBottleTitle => '영구 삭제';

  @override
  String get deleteBottleExplanation =>
      '경고: 완전히 삭제하면 셀러 및 시음 기록에서 영구적으로 지워집니다.';

  @override
  String get deleteBottleDifferenceDrink =>
      '오픈 / 마시기: 시음 기록에 보관되며, 통계가 갱신되고 메모가 유지됩니다.';

  @override
  String get deleteBottleDifferenceDelete =>
      '영구 삭제: 흔적 없이 완전히 지웁니다 (오입력, 파손, 중복 등록 시 추천).';

  @override
  String get deleteBottleActionConfirm => '영구 삭제하기';

  @override
  String get deleteBottleActionDrinkInstead => '대신 오픈 기록 남기기';

  @override
  String get cancel => '취소';

  @override
  String get confirm => '확인';

  @override
  String get checkoutTitle => '셀러에서 오픈 및 시음';

  @override
  String get checkoutSelectPrompt => '셀러에서 오픈할 와인을 선택하세요...';

  @override
  String get checkoutQtyOpened => '오픈한 병 수';

  @override
  String checkoutQtyOfTotal(int total) {
    return '셀러 내 총 $total병 중';
  }

  @override
  String get checkoutRating => '시음 평점';

  @override
  String get checkoutFoodPairing => '함께한 음식 (선택)';

  @override
  String get checkoutFoodHint => '예: 채끝 등심 스테이크, 버섯 리소토...';

  @override
  String get checkoutNotes => '시음 소감 및 테이스팅 노트';

  @override
  String get checkoutNotesHint => '아로마, 산미, 타닌, 여운의 길이...';

  @override
  String get checkoutSubmit => '시음 기록 완료';

  @override
  String get checkoutSuccess => '시음 기록이 성공적으로 저장되었습니다!';

  @override
  String get chatTitle => 'Chatmelier';

  @override
  String get chatGreeting =>
      '안녕하세요! AI 소믈리에 Chatmelier입니다. 음식 페어링, 오늘 마시기 좋은 와인, 보유 와인 추천 등 무엇이든 물어보세요.';

  @override
  String get chatAnalyzing => 'Chatmelier가 셀러를 분석 중입니다...';

  @override
  String get chatInputHint => 'Chatmelier에게 물어보세요...';

  @override
  String get chatChipTonight => '🍷 오늘 밤 마실 최고의 와인은?';

  @override
  String get chatChipSteak => '🥩 스테이크와 어울리는 셀러 와인';

  @override
  String get chatChipSeafood => '🐟 해산물 요리에 추천하는 화이트';

  @override
  String get chatChipPeak => '⏰ 지금 딱 마시기 좋은 와인은?';

  @override
  String get journalTitle => '시음 다이어리';

  @override
  String get journalEmpty => '아직 작성된 시음 기록이 없습니다';

  @override
  String get journalEmptySub => '셀러의 와인을 오픈하여 나만의 시음 일기를 시작하세요';

  @override
  String journalTastedOn(String date) {
    return '$date 시음';
  }

  @override
  String get statsTitle => '셀러 통계';

  @override
  String get statsTotalBottles => '셀러 보유 병 수';

  @override
  String get statsTotalValue => '셀러 총 가치';

  @override
  String get statsBottlesEnjoyed => '지금까지 마신 와인';

  @override
  String get statsByColor => '와인 타입별 분포';

  @override
  String get statsByMaturity => '숙성도별 분포';

  @override
  String get statsByRegion => '선호 지역 TOP';

  @override
  String get statsByCountry => '선호 국가 TOP';

  @override
  String get profileTitle => '프로필 및 설정';

  @override
  String get profileEmail => '이메일';

  @override
  String get profileDisplayName => '표시 이름';

  @override
  String get profileDefaultCurrency => '기본 통화';

  @override
  String get profileLanguage => '앱 언어';

  @override
  String get profileLanguageSystem => '자동 (스마트폰 시스템 언어)';

  @override
  String get profileLanguageFr => 'Français';

  @override
  String get profileLanguageEn => 'English';

  @override
  String profileCurrencyUpdated(String currency) {
    return '기본 통화가 변경되었습니다: $currency';
  }

  @override
  String get profileLanguageUpdated => '언어가 변경되었습니다';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get profileAbout => 'Chatmelier 정보';

  @override
  String get scanTitle => '와인 라벨 스캔';

  @override
  String get scanTakePhoto => '사진 촬영';

  @override
  String get scanPickGallery => '앨범에서 선택';

  @override
  String get scanAnalyzing => 'AI가 와인 라벨을 분석하고 있습니다...';

  @override
  String get scanIdentified => '와인을 식별했습니다 ✨';

  @override
  String get scanSaveToCellar => '내 셀러에 담기';

  @override
  String get loginTitle => '로그인';

  @override
  String get loginTagline => 'AI와 함께하는 스마트 공유 와인 셀러';

  @override
  String get loginTabMagicLink => '✉️ 매직 링크';

  @override
  String get loginTabPassword => '🔑 비밀번호';

  @override
  String get loginEmailLabel => '이메일 주소';

  @override
  String get loginPasswordLabel => '비밀번호';

  @override
  String get loginSendMagicLink => '로그인 링크 받기';

  @override
  String get loginSignInButton => '로그인';

  @override
  String get loginOrDivider => '또는';

  @override
  String get loginGoogleButton => 'Google 계정으로 계속';

  @override
  String get loginRegisterLink => '계정이 없으신가요? 회원가입';

  @override
  String get registerTitle => '회원가입';

  @override
  String get registerNameLabel => '이름 / 닉네임';

  @override
  String get registerSubmitButton => '계정 만들기';

  @override
  String get registerFillAllFields => '모든 항목을 입력해 주세요';

  @override
  String get registerWelcome => '🎉 Chatmelier에 오신 것을 환영합니다!';

  @override
  String get registerErrorGeneric => '회원가입 중 오류가 발생했습니다';

  @override
  String get authWelcome => 'Chatmelier에 오신 것을 환영합니다';

  @override
  String get authSubtitle => '나만의 스마트 와인셀러 관리자 & AI 전속 소믈리에';

  @override
  String get authGoogle => 'Google로 계속하기';

  @override
  String get authMagicLink => '이메일 링크로 로그인';

  @override
  String get authEmail => '이메일 주소';

  @override
  String get authNoAccount => '계정이 없으신가요? 회원가입';

  @override
  String get authHaveAccount => '이미 계정이 있으신가요? 로그인';

  @override
  String get changelogTitle => '버전 기록 및 새 소식';

  @override
  String get changelogEmpty => '새 소식이 없습니다.';

  @override
  String get scratchcardTitle => '세계 테루아 스크래치 맵';

  @override
  String get profileChangelog => '버전 기록 및 업데이트';

  @override
  String get profileScratchcard => '세계 테루아 스크래치 맵';

  @override
  String get navBar => '바';

  @override
  String get navProfile => '프로필';

  @override
  String get quickActions => '빠른 작업';

  @override
  String get appSubtitle => '스마트 소믈리에 & 와인셀러';

  @override
  String get profileTabPalate => '미각 취향';

  @override
  String get profileTabSettings => '설정';

  @override
  String get profileTabTools => '도구';

  @override
  String get profileTabAccount => '계정';

  @override
  String get profileTheme => '테마 / 모드';

  @override
  String get profileThemeLight => '라이트 ☀️';

  @override
  String get profileThemeDark => '다크 🌙';

  @override
  String get profileThemeSystem => '시스템 ⚙️';

  @override
  String get profileFriends => '친구 & 테이스트 맵 🍷';

  @override
  String get profileExport => '셀러 및 자산 평가서 내보내기 📊';

  @override
  String get profileDeleteAccount => '계정 영구 삭제';

  @override
  String get profileDeleteConfirmTitle => '영구 삭제';

  @override
  String get profileDeleteConfirmMsg =>
      '이 작업은 취소할 수 없습니다. 모든 데이터가 영구적으로 삭제됩니다.';

  @override
  String get badgesGalleryTitle => '트로피 갤러리';

  @override
  String badgesGallerySubtitle(Object pct, Object total, Object unlocked) {
    return '$unlocked / $total 개 잠금 해제 • $pct% 달성';
  }

  @override
  String get badgesFilterAll => '전체';

  @override
  String get badgesEmpty => '이 카테고리에는 배지가 없습니다.';

  @override
  String get badgesUnlockedChip => '잠금 해제 ✨';

  @override
  String get badgesStatusUnlocked => '배지가 잠금 해제되었습니다!';

  @override
  String get badgesStatusInProgress => '진행 중';

  @override
  String get badgesObjectiveLabel => '목표:';

  @override
  String get badgesChatmelierLoreTitle => '샤트믈리에의 와인 과학 및 스토리';

  @override
  String get badgesCloseButton => '닫기';

  @override
  String get badgesTierLabel => '등급';

  @override
  String get badgesShowcaseTitle => '트로피 및 배지';

  @override
  String badgesShowcaseCount(Object total, Object unlocked) {
    return '$unlocked / $total 잠금 해제됨';
  }

  @override
  String get badgesShowcaseGallery => '갤러리';

  @override
  String get cocktailsTitle => '바 & 칵테일';

  @override
  String get cocktailsReadyToShake => '지금 셰이킹 가능';

  @override
  String get cocktailsMissingOne => '재료 1개 부족';

  @override
  String get cocktailsManagePantry => '바 팬트리 관리';

  @override
  String get cocktailsResetPantry => '팬트리 재설정';
}
