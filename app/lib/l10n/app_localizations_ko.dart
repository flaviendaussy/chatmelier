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
  String get save => '저장';

  @override
  String get continueAnyway => '계속 진행';

  @override
  String get cellarDetected => '셀러 감지: ';

  @override
  String proximityWifi(String ssid) {
    return 'Wi-Fi \"$ssid\"에 연결됨';
  }

  @override
  String proximityGps(String distance) {
    return 'GPS 위치 감지 (거리: $distance)';
  }

  @override
  String get proximitySwitch => '전환';

  @override
  String get proximityIgnore => '무시';

  @override
  String proximitySwitchedSnack(String cellar) {
    return '📍 \"$cellar\" 셀러로 자동 전환되었습니다';
  }

  @override
  String get distantCellarTitle => '원거리 셀러 감지';

  @override
  String distantCellarWifiWarning(String ssid, String cellar) {
    return '현재 다른 셀러 \"$cellar\"에 연결된 Wi-Fi \"$ssid\"에 접속되어 있습니다.';
  }

  @override
  String distantCellarGpsWarning(String distance, String cellar) {
    return '현재 \"$cellar\" 셀러에서 약 $distance 떨어져 있습니다.';
  }

  @override
  String distantCellarAddConfirm(String warning, String cellar) {
    return '$warning\n\n그래도 이 와인을 \"$cellar\" 셀러에 추가하시겠습니까?';
  }

  @override
  String distantCellarCheckoutConfirm(String warning, String cellar) {
    return '$warning\n\n그래도 이 와인을 \"$cellar\" 셀러에서 출고하시겠습니까?';
  }

  @override
  String get ratingExceptional => '🏆 독보적';

  @override
  String get ratingRemarkable => '✨ 훌륭함';

  @override
  String get ratingVeryGood => '🍷 매우 좋음';

  @override
  String get ratingPleasant => '👍 기분 좋음';

  @override
  String get ratingPassable => '보통';

  @override
  String get checkoutWhoTasted => '누구와 함께 이 와인을 테이스팅하셨나요?';

  @override
  String checkoutStockRemaining(String producer, int qty) {
    String _temp0 = intl.Intl.pluralLogic(
      qty,
      locale: localeName,
      other: '병',
      one: '병',
    );
    return '$producer • 재고: $qty $_temp0';
  }

  @override
  String get checkoutAddGuest => '게스트 추가';

  @override
  String get checkoutAddGuestHint => '이름 추가 (엄마, 아빠, 친구...)';

  @override
  String get checkoutCloseAndTaste => '닫고 테이스팅 즐기기 🍷';

  @override
  String get checkoutSommelierThinking => '소믈리에가 와인 이야기를 준비 중입니다...';

  @override
  String get checkoutAerationTimerActive => '⏱️ 잠금 화면에서 에어레이션 타이머 작동 중!';

  @override
  String get checkoutStartAerationTimer => '타이머 시작 ⏱️';

  @override
  String get checkoutAerationTimerTitle => '에어레이션 타이머';

  @override
  String get checkoutDelayedTonight => '오늘 밤 22:00';

  @override
  String get checkoutDelayedTonightSub => '식사 후 여유롭게 여운을 정리하기에 이상적';

  @override
  String get checkoutDelayedTomorrow => '내일 오전 11:00';

  @override
  String get checkoutDelayedTomorrowSub => '조용한 시간에 테이스팅 느낌을 기록';

  @override
  String get checkoutDelayedWeekend => '이번 주말 (토요일 오전 11:00)';

  @override
  String get checkoutDelayedWeekendSub => '주말 여유 시간에 차분하게';

  @override
  String checkoutDelayedInTwoHours(String time) {
    return '2시간 후 ($time)';
  }

  @override
  String get checkoutDelayedInTwoHoursSub => '테이스팅 마무리 시점의 빠른 리마인더';

  @override
  String get checkoutDelayedCustom => '날짜 및 시간 직접 선택...';

  @override
  String get reviewPackagingDetected => '패키지 규격 감지';

  @override
  String get reviewSingleBottleOnly => '아니요, 1병만';

  @override
  String reviewMultipleBottlesConfirm(int count) {
    return '예, 총 $count병';
  }

  @override
  String reviewStockUpdatedSuccess(int count) {
    return '🍾 재고가 성공적으로 업데이트되었습니다! (셀러 내: $count병)';
  }

  @override
  String get reviewVintageYear => '빈티지 / 생산 연도';

  @override
  String get reviewNonVintage => '건너뛰기 / 논빈티지 (NV)';

  @override
  String get reviewValidate => '입고 확정';

  @override
  String reviewBottleAddedSuccess(String name) {
    return '🍾 \"$name\" 와인이 셀러에 성공적으로 추가되었습니다!';
  }

  @override
  String get reviewBottleAnalysis => '와인 정밀 분석';

  @override
  String get reviewDiscard => '취소';

  @override
  String get reviewDiscardConfirmTitle => '입력을 취소하시겠습니까?';

  @override
  String get reviewContinueEditing => '계속 편집';

  @override
  String get reviewDiscardWithoutSaving => '저장하지 않고 나가기';

  @override
  String get reviewBottleDetails => '와인 상세 정보';

  @override
  String get reviewStockInCellar => '셀러 재고';

  @override
  String get reviewStockAddition => '입고 추가';

  @override
  String get reviewStockNewTotal => '변경 후 총수량';

  @override
  String get reviewQuantityToAdd => '추가할 수량:';

  @override
  String get reviewSeparateEntry => '별도 항목 생성 (다른 랙 또는 구매 가격)';

  @override
  String get reviewRetryAi => 'AI 분석 재시도';

  @override
  String get reviewEnlarge => '확대 보기';

  @override
  String get reviewGeneralInfo => '기본 정보';

  @override
  String get reviewOriginTerroir => '원산지 및 테루아';

  @override
  String get reviewQuantityPurchase => '수량 및 구매 정보';

  @override
  String cellarWifiDetectedSuccess(String ssid) {
    return '📡 Wi-Fi 감지 및 연동 완료: \"$ssid\"';
  }

  @override
  String get cellarWifiDetectionFailed =>
      'Wi-Fi를 감지할 수 없습니다 (위치 서비스를 켜거나 직접 입력하세요)';

  @override
  String cellarGpsCoordsCaptured(String lat, String lon) {
    return '📍 GPS 좌표 획득 완료 ($lat, $lon)';
  }

  @override
  String get cellarGpsInaccessible => 'GPS 위치에 접근할 수 없습니다. 위치 권한을 확인하세요.';

  @override
  String cellarCreatedSuccess(String cellar) {
    return '✨ \"$cellar\" 셀러가 성공적으로 생성되었습니다!';
  }

  @override
  String cellarCreationError(String error) {
    return '생성 중 오류: $error';
  }

  @override
  String get cellarRadiusPrecise => '100 m (정밀 감지)';

  @override
  String get cellarRadiusRecommended => '300 m (권장)';

  @override
  String get cellarRadius500m => '500 m';

  @override
  String get cellarRadius1km => '1 km';

  @override
  String get cellarRadius3km => '3 km';

  @override
  String get cellarCreateButton => '셀러 생성하기';

  @override
  String get cellarUseCurrentGps => '현재 GPS 위치로 설정';

  @override
  String cellarUpdatedSuccess(String cellar) {
    return '✅ \"$cellar\" 셀러 설정이 업데이트되었습니다';
  }

  @override
  String cellarUpdateError(String error) {
    return '업데이트 오류: $error';
  }

  @override
  String get wineTypeRed => '레드 와인 🍷';

  @override
  String get wineTypeWhite => '화이트 와인 🥂';

  @override
  String get wineTypeRose => '로제 와인 🌸';

  @override
  String get wineTypeSparkling => '스파클링 와인 🍾';

  @override
  String get wineTypeDessert => '디저트 / 스위트 🍯';

  @override
  String get bottleSizeCustom => '기타 용량…';

  @override
  String get bottleSizeCustomTitle => '사용자 지정 용량';

  @override
  String get bottleSizeCustomLabel => '용량 (센티리터)';

  @override
  String get bottleSizeCustomInvalid => '1에서 3000 cl 사이로 입력하세요.';

  @override
  String get wineTypeLiqueur => '리큐어 🍯';

  @override
  String get wineTypeSpirit => '스피릿 / 증류주 🥃';

  @override
  String get wineTypeGrappa => '그라파 🍇';

  @override
  String get wineTypeEauDeVie => '오드비 (과일 브랜디) 🍐';

  @override
  String get wineTypeWhisky => '위스키 🥃';

  @override
  String get wineTypeRum => '럼 🏴‍☠️';

  @override
  String get wineTypeGin => '진 🍸';

  @override
  String get wineTypeVodka => '보드카 🧊';

  @override
  String get wineTypeTequila => '데킬라 🌵';

  @override
  String get wineTypeCognac => '꼬냑 🍷';

  @override
  String get cellarCreateTitle => '새 셀러 만들기';

  @override
  String get cellarManageTitle => '셀러 관리';

  @override
  String get cellarNameLabel => '셀러 이름 *';

  @override
  String get cellarNameHint => '예: 집 셀러, 본가 와인고';

  @override
  String get cellarNameRequired => '셀러 이름을 입력하세요';

  @override
  String get cellarLocationLabel => '위치 / 도시 (선택)';

  @override
  String get cellarLocationHint => '예: 서울, 보르도';

  @override
  String get cellarNicknameLabel => '별칭 / 보관 방 (선택)';

  @override
  String get cellarNicknameHint => '예: 지하 저장고, 거실 와인셀러';

  @override
  String get cellarDescriptionLabel => '설명 (선택)';

  @override
  String get cellarDescriptionHint => '예: 온도 13°C, 습도 70% 지하 보관';

  @override
  String get cellarWifiLabel => '연결된 Wi-Fi (선택)';

  @override
  String get cellarWifiHint => '예: Home-Cellar-5G';

  @override
  String get cellarLinkCurrentWifi => '현재 Wi-Fi와 연동';

  @override
  String get cellarCaptureCurrentWifiTooltip => '현재 Wi-Fi 가져오기';

  @override
  String get cellarRadiusLabel => 'GPS 감지 반경';

  @override
  String get cellarAutoDetectionHeader => '스마트 자동 감지 및 전환';

  @override
  String get cellarAutoDetectionDesc =>
      'Wi-Fi 또는 GPS 좌표를 연동하면 해당 장소에 도착했을 때 자동으로 셀러가 전환됩니다.';

  @override
  String get cellarLatitudeLabel => '위도';

  @override
  String get cellarLongitudeLabel => '경도';

  @override
  String get checkoutGuidedTasting => '가이드 테이스팅';

  @override
  String get checkoutGuidedTastingShared => '차례대로 또는 함께 인상을 공유';

  @override
  String get checkoutGuidedTastingSolo => '외관, 향, 맛의 균형을 분석하여 맞춤 미각 프로필 완성';

  @override
  String get checkoutUncorkNowRateLater => '지금 오픈, 평가는 나중에';

  @override
  String get checkoutUncorkNowRateLaterSub =>
      '즉시 출고 • 리마인더 시점 선택 (오늘 밤, 내일...)';

  @override
  String get checkoutUncorkAeration => '오픈 및 에어레이션 타이머';

  @override
  String checkoutUncorkAerationAdvised(int minutes) {
    return '즉시 출고 • $minutes분 에어레이션 권장';
  }

  @override
  String get checkoutUncorkAerationSub => '즉시 출고 • 디캔팅 / 에어레이션 카운트다운';

  @override
  String get checkoutSommelierServiceAdvice => '소믈리에 서빙 가이드';

  @override
  String get checkoutHistoryAnecdotes => '와이너리 이야기 & 비하인드';

  @override
  String get checkoutNoDecanting => '디캔팅 불필요';

  @override
  String get checkoutStoryTitle => '이 와인의 이야기 📖';

  @override
  String get checkoutStorySubtitle => '식탁에서 나누기 좋은 흥미로운 에피소드';

  @override
  String get checkoutStoryTerroir => '테루아 & 포도 품종';

  @override
  String get checkoutStoryVintage => '빈티지 이야기';

  @override
  String get checkoutStoryTastingSecret => '테이스팅 시크릿';

  @override
  String get checkoutStoryTableAnecdote => '테이블 토크 팁';

  @override
  String get checkoutJournalArchivedNotice =>
      '안심하세요: 이 와인은 사진 및 메모와 함께 테이스팅 일지에 정성스럽게 보관됩니다.';

  @override
  String checkoutBottleUncorkedAerationSuccess(int minutes) {
    return '와인이 오픈되었습니다! 에어레이션 타이머($minutes분)가 잠금 화면에서 실행 중입니다.';
  }

  @override
  String get checkoutAerationDialogPrompt =>
      '와인이 즉시 출고됩니다. 테이스팅 전 에어레이션 권장 시간을 확인하세요:';

  @override
  String get checkoutRateWine => '와인 평가하기';

  @override
  String checkoutStartTimerAction(int minutes) {
    return '타이머 $minutes분 ⏱️';
  }

  @override
  String checkoutAdviceAerationSnack(int minutes) {
    return '소믈리에 팁: $minutes분 에어레이션 추천. 잠금 화면 타이머 준비 완료.';
  }

  @override
  String get checkoutAdviceReminderSnack =>
      '테이스팅 후 느낌을 기록할 수 있도록 리마인더가 예약되었습니다.';

  @override
  String get checkoutBottleRemovedSuccess => '와인이 셀러에서 출고되었습니다!';

  @override
  String checkoutBottleRemovedReminder(String date) {
    return '즐거운 테이스팅 되세요. $date에 인상을 기록하도록 알려드릴게요.';
  }

  @override
  String get checkoutWhoTastedSubtitle => '모든 참가자의 미각 프로필이 자동으로 정교해집니다.';

  @override
  String checkoutCellarOf(String name) {
    return '$name 님의 셀러';
  }

  @override
  String checkoutStockBout(int count) {
    return '재고: $count병';
  }

  @override
  String get checkoutAddGuestDialogDesc =>
      '이번 테이스팅에 함께한 가족이나 친구를 추가하세요 (예: 엄마, 아빠, 영희...).';

  @override
  String get checkoutAddGuestNameLabel => '이름 / 닉네임';

  @override
  String get checkoutDelayedSheetTitle => '오픈 후 나중에 평가하기';

  @override
  String get checkoutDelayedSheetSubtitle => '언제 테이스팅 인상을 기록할 리마인더를 받으시겠어요?';

  @override
  String checkoutDelayedTonightTime(String time) {
    return '오늘 밤 2시간 후 ($time)';
  }

  @override
  String get checkoutDelayedTonightFixed => '오늘 밤 21:00';

  @override
  String checkoutDateTonightLabel(String time) {
    return '오늘 밤 $time';
  }

  @override
  String checkoutDateTomorrowLabel(String time) {
    return '내일 $time';
  }

  @override
  String checkoutDateCustomLabel(String date, String time) {
    return '$date $time';
  }

  @override
  String get add => '추가';

  @override
  String get cellarWinesTab => '🍷 와인';

  @override
  String get cellarSpiritsTab => '🥃 스피릿';

  @override
  String get cellarPairWithDish => '이 요리에 어울리는 와인은?';

  @override
  String get cellarCollapseAll => '모두 접기';

  @override
  String get cellarExpandAll => '모두 펼치기';

  @override
  String get cellarSort => '정렬';

  @override
  String get cellarCategories => '카테고리';

  @override
  String get cellarFavorites => '즐겨찾기';

  @override
  String get cellarGridView => '그리드';

  @override
  String get cellarListView => '목록';

  @override
  String get cellarClearFilters => '필터 초기화';

  @override
  String get cellarNoBottlesCategory => '이 카테고리에 와인이 없습니다';

  @override
  String get cellarNoBottlesCriteria => '조건에 맞는 와인이 없습니다';

  @override
  String get feedbackSheetTitle => '테스터 피드백 및 주석';

  @override
  String get feedbackStylus => '펜:';

  @override
  String get feedbackUndo => '마지막 획 실행 취소';

  @override
  String get feedbackClear => '모두 지우기';

  @override
  String get feedbackHint => '영역을 표시하고 의견이나 버그를 설명해주세요...';

  @override
  String get feedbackSubmit => '보고서 보내기';

  @override
  String get feedbackSubmitting => '전송 중...';

  @override
  String get feedbackNoScreenshot => '사용 가능한 스크린샷이 없습니다';

  @override
  String get feedbackEmptyError => '댓글을 추가하거나 스크린샷에 그려주세요.';

  @override
  String get feedbackSuccess => '소중한 피드백 감사합니다! 🍷 보고서가 전송되었습니다.';

  @override
  String feedbackError(String error) {
    return '전송 오류: $error';
  }

  @override
  String get checkoutFastExit => '설문 없이 빠른 출고 ⚡';

  @override
  String get checkoutFastExitSubmitting => '출고 진행 중...';

  @override
  String get checkoutRatingSubtitle => '시음 후 와인의 종합 점수를 남겨주세요';

  @override
  String get checkoutRecommendedBadge => '추천';

  @override
  String get tastingWhoTastedTitle => '👥 누구와 이 와인을 시음했나요?';

  @override
  String get tastingWhoTastedSubtitle => '테이스터를 선택하세요. 취향 프로필이 자동으로 맞춤 학습됩니다.';

  @override
  String get tastingHowToTaste => '테이스팅 진행 방식';

  @override
  String get tastingEachTurn => '차례대로 돌아가며';

  @override
  String get tastingEachTurnDesc => '📱 스마트폰을 넘기며: 각자 자신의 속도에 맞춰 따로 답변합니다.';

  @override
  String get tastingTogether => '모두 다 함께';

  @override
  String get tastingTogetherDesc => '🥂 식탁에서 대화를 나누며 하나의 답변지를 함께 완성합니다.';

  @override
  String get tastingBlindMode => '블라인드 테이스팅 모드';

  @override
  String get tastingBlindModeDesc => '와인 이름을 숨기고 식탁 퀴즈를 즐긴 후 정답을 화려하게 공개합니다!';

  @override
  String get tastingPrimaryProfile => '대표 프로필';

  @override
  String get tastingAppInstalled => '앱 설치됨 📱';

  @override
  String tastingQuestionnairesCompletedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '설문 $count건 완료',
      one: '설문 1건 완료',
      zero: '작성된 설문 없음',
    );
    return '$_temp0';
  }

  @override
  String get tastingStepNezTitle => '👃 향 (노즈) — 아로마 표현';

  @override
  String get tastingStepNezSubtitle => '스월링 후 글라스에서 피어오르는 다채로운 향기를 감상하세요.';

  @override
  String get tastingFaultTitle => '와인에서 다음과 같은 냄새가 나나요?';

  @override
  String get tastingFaultSubtitle =>
      '그렇다면 병에 결함이 있는 것입니다. 당신의 미각 탓도, 와인의 스타일 탓도 아닙니다.';

  @override
  String get tastingFaultCorkLabel => '📦 젖은 골판지, 퀴퀴한 지하실';

  @override
  String get tastingFaultCorkExplain =>
      '코르크 오염(TCA). 와인 탓이 아니며 공기와 접촉해도 나아지지 않습니다. 레스토랑에서는 다른 병을 요청할 수 있습니다.';

  @override
  String get tastingFaultOxidationLabel => '🍎 갈변한 사과, 식초, 셰리';

  @override
  String get tastingFaultOxidationExplain =>
      '산화. 코르크 불량이나 지나치게 긴 숙성으로 병에 공기가 들어갔습니다.';

  @override
  String get tastingFaultReductionLabel => '🥚 성냥, 달걀, 양배추';

  @override
  String get tastingFaultReductionExplain =>
      '환원취. 좋은 소식은 공기와 만나면 대개 사라진다는 점입니다. 20분간 디캔팅한 뒤 다시 맛보세요.';

  @override
  String get tastingFaultExcluded => '이 시음은 취향 프로필에 반영되지 않습니다.';

  @override
  String get tastingAromaIntensity => '향의 강도:';

  @override
  String get tastingAromaDiscreet => '🤫 은은하고 섬세함';

  @override
  String get tastingAromaExplosive => '💥 화려하고 폭발적';

  @override
  String get tastingStepBoucheTitle => '⚖️ 맛 (팔레트) — 균형미';

  @override
  String get tastingStepBoucheSubtitle => '입안에서 느껴지는 질감과 산미, 타닌의 조화를 표현하세요.';

  @override
  String get tastingAcidity => '산미의 느낌:';

  @override
  String get tastingAcidityFreshness => '산미 & 청량감:';

  @override
  String get tastingAcidityFlat => '🫠 펑퍼짐함 / 밋밋함';

  @override
  String get tastingAciditySharp => '⚡ 날카로움 / 짜릿함';

  @override
  String get tastingTannins => '타닌 (떫은맛):';

  @override
  String get tastingTanninsSilky => '🧶 부드럽고 실키함';

  @override
  String get tastingTanninsGrippy => '💪 탄탄하고 그립감 있음';

  @override
  String get tastingMinerality => '미네랄감 & 생동감:';

  @override
  String get tastingMineralityRound => '🧈 둥글둥글하고 리치함';

  @override
  String get tastingMineralityCrisp => '🪨 또렷한 미네랄 / 맑음';

  @override
  String get tastingEffervescence => '기포 (스파클링):';

  @override
  String get tastingEffervescenceDelicate => '🫧 섬세하고 부드러움';

  @override
  String get tastingEffervescenceVibrant => '🎆 활기차고 크리미함';

  @override
  String get tastingBody => '바디감 / 무게감:';

  @override
  String get tastingBodyLight => '🍃 가볍고 산뜻함';

  @override
  String get tastingBodyFull => '🏋️ 묵직하고 웅장함';

  @override
  String get tastingLength => '피니시 / 여운의 길이:';

  @override
  String get tastingLengthShort => '⏱️ 짧은 편';

  @override
  String get tastingLengthLong => '♾️ 길게 이어지는 여운';

  @override
  String get tastingStepVerdictTitle => '✅ 최종 판정';

  @override
  String get sipSectionTitle => '🍷 한 모금';

  @override
  String get tasteConfidenceUnknown => '아직 당신의 미각을 모릅니다. 번짐은 제가 추측하는 부분입니다.';

  @override
  String tasteConfidenceKnown(String percent) {
    return '미각 파악도 $percent%. 흐릿한 부분은 아직 추측 중입니다.';
  }

  @override
  String tasteConfidenceFrontier(String axis) {
    return '가장 모르는 것: $axis.';
  }

  @override
  String get sipSectionSubtitle => '두 번만 누르면 이 한 잔이 당신의 취향 프로필에 무언가를 알려줍니다.';

  @override
  String get tastingBuyAgain => '이 와인을 다시 구매하시겠습니까?';

  @override
  String get tastingBuyAgainYes => '🤩 꼭 다시 살 거예요!';

  @override
  String get tastingBuyAgainMaybe => '🤔 기회가 된다면';

  @override
  String get tastingBuyAgainNo => '👎 이번엔 괜찮아요';

  @override
  String get tastingIdealMoment => '이 와인과 가장 어울리는 순간은?';

  @override
  String get tastingMomentApero => '🥂 아페리티프 / 식전주';

  @override
  String get tastingMomentMeal => '🍽️ 편안한 일상 식사';

  @override
  String get tastingMomentDinner => '🎩 격식 있는 정찬 디너';

  @override
  String get tastingMomentRomantic => '🕯️ 로맨틱한 촛불 식사';

  @override
  String get tastingMomentSolo => '🧘 고요한 혼술의 시간';

  @override
  String get tastingWhatLiked => '가장 마음에 든 점:';

  @override
  String get tastingWhatDisliked => '조금 아쉬웠던 점:';

  @override
  String get tastingOccasionLabel => '기념 순간 / 추억 (선택) ✨';

  @override
  String get tastingOccasionHint => '예: 생일 파티, 기념일 디너, 오랜 친구 모임...';

  @override
  String get tastingAddPhoto => '테이블 기념 사진 추가 📸';

  @override
  String get tastingPhotoSaved => '테이블 사진이 저장되었습니다 📸';

  @override
  String get tastingStepImpressionTitle => '🎯 최종 평점 및 감상';

  @override
  String get tastingStepImpressionSubtitle => '향과 맛을 충분히 음미한 후 종합 점수를 매겨주세요.';

  @override
  String get tastingOverallFeeling => '전반적인 느낌:';

  @override
  String get tastingScoreOutOf10 => '10점 만점 평점:';

  @override
  String get tastingCompletedTitle => '테이스팅 기록 완료!';

  @override
  String get tastingCompletedSubtitle => '취향 프로필이 성공적으로 업데이트되었습니다 ✨';

  @override
  String get tastingBottleRemoved => '와인이 오픈되어 셀러에서 출고되었습니다';

  @override
  String get tastingConsultDebrief => '소믈리에 디브리핑 보기 (숨은 뉘앙스 & 테루아)';

  @override
  String get tastingFinishButton => '완료 ✨';

  @override
  String get tastingNextTaster => '확인 → 다음 테이스터로';

  @override
  String get tastingConfirmAndFinish => '확인 및 완료 ✨';

  @override
  String get tastingQuitTitle => '설문을 종료하시겠습니까?';

  @override
  String get tastingQuitMessage => '작성 중인 답변이 저장되지 않습니다.';

  @override
  String get tastingContinue => '계속하기';

  @override
  String get tastingQuit => '종료';

  @override
  String tastingStartCount(int count) {
    return '시작하기 ($count)';
  }

  @override
  String tastingProfileSynced(String name) {
    return '$name 님의 앱에 동기화 완료 ✨';
  }

  @override
  String get tastingProfileEnriched => '미각 프로필이 더 정교해졌습니다';

  @override
  String tastingAcuityScoreSummary(int score, String praise) {
    return '감각 예리도: $score% • $praise';
  }

  @override
  String get tastingFlavorOriginsTitle => '풍미의 기원 & 와인의 비밀';

  @override
  String get tastingFlavorOriginsSubtitle => '향과 색상, 구조가 어디서 탄생했는지 알아보세요';

  @override
  String get tastingBlindQuizTitle => '블라인드 테이스팅 테이블 퀴즈 🙈';

  @override
  String get tastingBlindQuizQ1 => '1. 이 와인의 생산 지역은 어디일까요? 🌍';

  @override
  String get tastingBlindQuizQ2 => '2. 주된 포도 품종은 무엇일까요? 🍇';

  @override
  String get tastingBlindQuizQ3 => '3. 예상 빈티지 / 숙성 기간은? 📅';

  @override
  String get tastingBlindQuizQ4 => '4. 예상 가격대는? 💶';

  @override
  String get tastingBlindRevealTitle => '미스터리 보틀 정답 대공개 🍾';

  @override
  String tastingBlindQuizScore(int score) {
    return '블라인드 퀴즈 점수: $score/4 🎯';
  }

  @override
  String get tastingDebriefTitle => '양조학 및 분자 디브리핑';

  @override
  String get tastingSensoryAcuity => '감각 예리도';

  @override
  String tastingPrecision(int score) {
    return '정확도 $score%';
  }

  @override
  String get tastingConcordanceTitle => '1. 일치도 및 크뤼 고유 캐릭터';

  @override
  String get tastingWhatYouDetected => '테이스터가 감지한 요소:';

  @override
  String get tastingArchetypeSignature => '이 와인의 전형적인 캐릭터:';

  @override
  String get tastingHiddenNuancesTitle => '다음 잔에서 찾아볼 섬세한 뉘앙스:';

  @override
  String get tastingPillarsTitle => '2. 양조 과학 및 분자 분석';

  @override
  String get tastingPillarsSubtitle => '왜 이 와인은 이러한 구조, 향, 색상을 띨까요?';

  @override
  String get tastingChatWithSommelier => 'Chatmelier와 양조 비밀 더 깊이 파헤치기';

  @override
  String get aromaFruitsRouges => '붉은 베리류 (딸기/체리/라즈베리)';

  @override
  String get aromaFruitsNoirs => '검은 베리류 (블랙베리/카시스/블루베리)';

  @override
  String get aromaFruitsBlancs => '백도/배/사과/서양배';

  @override
  String get aromaAgrumes => '시트러스 (레몬/라임/자몽)';

  @override
  String get aromaFloral => '플로럴 (제비꽃/장미/아카시아)';

  @override
  String get aromaVegetal => '허브 및 식물향 (피망/민트/풀내음)';

  @override
  String get aromaEpicesDouces => '달콤한 스파이스 (시나몬/넛멕/정향)';

  @override
  String get aromaEpicesVives => '알싸한 스파이스 (블랙페퍼/후추)';

  @override
  String get aromaBoise => '오크 숙성향 (바닐라/토스트/삼나무)';

  @override
  String get aromaBeurre => '버터 / 브리오슈';

  @override
  String get aromaMineral => '미네랄 (부싯돌/석회/백악질)';

  @override
  String get aromaMiel => '꿀 / 과일잼';

  @override
  String get aromaChocolat => '다크 초콜릿 / 볶은 커피';

  @override
  String get aromaFumee => '스모크 / 훈제향';

  @override
  String get emojiDisliked => '아쉬움';

  @override
  String get emojiMeh => '보통';

  @override
  String get emojiDecent => '괜찮음';

  @override
  String get emojiVeryGood => '매우 좋음';

  @override
  String get emojiLoved => '인생 와인!';

  @override
  String get likedFreshness => '생동감 있는 신선한 산미';

  @override
  String get likedFruitiness => '순수하고 풍성한 과실미';

  @override
  String get likedComplexity => '매혹적인 복합미';

  @override
  String get likedElegance => '우아하고 섬세한 밸런스';

  @override
  String get likedPower => '힘차고 풍부한 바디감';

  @override
  String get likedSilky => '실크처럼 부드러운 타닌';

  @override
  String get likedOriginality => '개성 넘치는 테루아의 독창성';

  @override
  String get likedFoodPairing => '음식과의 조화로운 마리아주';

  @override
  String get likedMinerality => '깔끔하고 세련된 미네랄리티';

  @override
  String get likedLength => '오랫동안 맴도는 깊은 여운';

  @override
  String get likedDisappointing => '특별히 없음 / 실망스러움 😕';

  @override
  String get dislikedTooAcidic => '산미가 지나치게 찌르고 시큼함';

  @override
  String get dislikedTooTannic => '타닌이 너무 떫고 껄끄러움';

  @override
  String get dislikedTooOaked => '오크 및 바닐라 향이 너무 과함';

  @override
  String get dislikedTooAlcoholic => '알코올 열감이 튀고 뜨거움';

  @override
  String get dislikedTooThin => '바디가 너무 묽고 싱거움';

  @override
  String get dislikedLacksFruit => '과실향이 너무 빈약함';

  @override
  String get dislikedTooSweet => '단맛이 지나쳐 쉽게 질림';

  @override
  String get dislikedTooExpensive => '품질 대비 가격이 너무 비쌈';

  @override
  String get dislikedNothing => '완벽함, 흠잡을 곳 없음!';

  @override
  String get tastingStepTasters => '테이스터';

  @override
  String get tastingStepNezNav => '향';

  @override
  String get tastingStepBoucheNav => '맛';

  @override
  String get tastingStepVerdictNav => '판정';

  @override
  String get tastingStepRatingNav => '평점';

  @override
  String get tastingBack => '이전';

  @override
  String get tastingNext => '다음';

  @override
  String get tastingSaving => '저장 중...';

  @override
  String get tastingHeaderTitle => '테이스팅 설문지';

  @override
  String tastingAnswersOf(String name) {
    return '$name 님의 답변';
  }

  @override
  String tastingPassPhoneTo(String name) {
    return '$name 님에게 스마트폰을 넘겨주세요 📱';
  }

  @override
  String tastingAnswersSavedTurn(String name) {
    return '답변이 안전하게 저장되었습니다.\n이제 $name 님의 차례입니다.';
  }

  @override
  String get tastingDictateButton => '테이블 감상 음성 받아쓰기 🎙️';

  @override
  String get tastingDictateHint =>
      '자유롭게 말하거나 적어주세요. Chatmelier AI가 향과 맛의 지표를 자동 완성합니다!';

  @override
  String get tastingDictateMicTip => '팁: 키보드의 마이크 버튼을 눌러 음성으로 빠르게 남길 수 있습니다!';

  @override
  String get tastingTakePhoto => '테이블 와인 사진 촬영 📸';

  @override
  String get tastingChooseGallery => '갤러리에서 선택 🖼️';

  @override
  String get tastingConclaveSummary => '테이스팅 종합 결과';

  @override
  String get tastingCellarMaster => '셀러 마스터';

  @override
  String get tastingGuestTaster => '초대 테이스터';

  @override
  String tastingProfileTag(String type) {
    return '취향 유형: $type';
  }

  @override
  String get tastingFreeTastingRecorded => '자유 테이스팅 메모가 기록되었습니다.';

  @override
  String tastingAppearanceLabel(String appearance) {
    return '외관: $appearance';
  }

  @override
  String tastingStructureLabel(String structure, int caudalies) {
    return '구조: $structure ($caudalies 코달리)';
  }

  @override
  String tastingKeyMolecules(String molecules) {
    return '주요 분자: $molecules';
  }

  @override
  String tastingKeyOrigin(String key) {
    return '핵심 요소: $key';
  }

  @override
  String tastingGrapesLabel(String grapes) {
    return '포도 품종: $grapes';
  }

  @override
  String get tastingAromaAppliedByAI => 'Chatmelier AI가 테이스팅 인상을 자동 적용했습니다 ✨';

  @override
  String get tastingBlindYourPredictions => '테이블 블라인드 예측 요약:';

  @override
  String get tastingBlindGuessCorrect => '정답입니다! 🎯';

  @override
  String get tastingBlindMakePredictionsPrompt => '최종 와인 공개 전에 모두의 예측을 남겨보세요!';

  @override
  String tastingStartTaster(String name) {
    return '자, 시작해볼까요, $name 님! 🍷';
  }

  @override
  String get tastingQuizBravo => '🎯 대단해요!';

  @override
  String tastingQuizWas(String answer) {
    return '(정답은: $answer)';
  }

  @override
  String get tastingDictateInputHint =>
      '예: 민수는 정말 좋아하며 8.5점, 흙내음과 블랙베리 향을 꼽음. 수진은 7점, 산미가 살짝 튄다고 느낌...';

  @override
  String get tastingDictateAnalyzing => 'AI 분석 중...';

  @override
  String get tastingDictateAnalyzeAndApply => '분석 및 설문지에 적용 ✨';

  @override
  String get tastingFormatExpress => '익스프레스 형식 (1페이지) ⚡';

  @override
  String get tastingFormatExpressDesc => '30초 만에 점수, 핵심 아로마, 한 줄 판정 기록';

  @override
  String get tastingFormatSommelier => '소믈리에 형식 (상세) 🎓';

  @override
  String get tastingFormatSommelierDesc => '향의 변화, 입안의 밸런스, 여운, 테루아 심층 분석';

  @override
  String get tastingCaudalieTooltipTitle => '코달리 (Caudalie)란? ⏱️';

  @override
  String get tastingCaudalieTooltipBody =>
      '1 코달리 = 와인을 삼키거나 뱉은 후 입안에서 향이 머무는 1초.\n• 1~4 코달리: 가볍고 산뜻한 와인\n• 5~7 코달리: 아름다운 균형을 지닌 와인\n• 8~12+ 코달리: 감탄이 절로 나오는 위대한 그랑 크뤼!';

  @override
  String get tastingAddCustomAroma => '+ 직접 아로마 추가';

  @override
  String get tastingCustomAromaDialogTitle => '특정 아로마 입력';

  @override
  String get tastingCustomAromaHint => '예: 스모키한 부싯돌, 산딸기, 말린 장미...';

  @override
  String get tastingFoodSynergyTitle => '음식과의 마리아주 궁합 🍽️';

  @override
  String get tastingSynergySublime => '🤩 환상의 조화';

  @override
  String get tastingSynergyHarmonious => '👍 훌륭한 균형';

  @override
  String get tastingSynergyNeutral => '😐 무난함';

  @override
  String get tastingSynergyClashing => '⚡ 불협화음';

  @override
  String get checkoutFastRatingTitle => '원탭 간편 평점 (선택):';

  @override
  String get checkoutActionTastingTitle => '이 와인 테이스팅하기';

  @override
  String get checkoutActionTastingSubtitle => '익스프레스 (1페이지) 또는 상세 소믈리에 형식';

  @override
  String get checkoutActionDeferredRemind => '나중에 알림 🌙';

  @override
  String get checkoutActionAerationTimer => '에어레이션 타이머 ⏱️';

  @override
  String get externalTastingTitle => '셀러 밖 시음';

  @override
  String get externalTastingSubtitle => '레스토랑, 바, 친구 집에서… 보유 재고는 그대로';

  @override
  String get externalTastingWithWhom => '이 와인을 누구와 함께 시음하나요?';

  @override
  String get externalTastingWhere => '이 와인을 어디에서 시음하나요?';

  @override
  String get externalTastingSearchingPlaces => '주변 레스토랑, 바, 친구를 찾는 중…';

  @override
  String get externalTastingGpsActive => 'GPS 켜짐';

  @override
  String externalTastingPlaceGuess(String place) {
    return '현재 위치로 추정됩니다: $place';
  }

  @override
  String get externalTastingFavoritePlaceNote =>
      'Chatmelier가 자동으로 기억한 즐겨 찾는 장소';

  @override
  String get externalTastingChangePlace => '장소 변경';

  @override
  String get externalTastingOtherPlace => '친구 집 / 다른 장소…';

  @override
  String get externalTastingNoPlaceFound => '바로 근처에서 레스토랑을 찾지 못했습니다.';

  @override
  String get externalTastingPlaceLabel => '누구의 집 또는 어디에 있나요? *';

  @override
  String get externalTastingPlaceHint => '예: 디미트리네 집, 부모님 댁, 시골집…';

  @override
  String externalTastingRememberPlace(String place) {
    return '이 GPS 위치에 \"$place\"을(를) 기억해 다음 방문에 사용';
  }

  @override
  String get externalTastingDefaultPlace => '레스토랑에서';

  @override
  String get externalTastingAiIdentifyTitle => 'AI로 식별 (바, 레스토랑, 칠판 메뉴)';

  @override
  String get externalTastingAiIdentifyDesc =>
      '몇 단어만 입력하면(예: \"Saint-Joseph Coursodon 2021\" 또는 \"Bandol Terrebrune\") 양식이 자동으로 채워집니다.';

  @override
  String get externalTastingAiIdentifyHint => '예: Saint-Joseph 2021 Coursodon…';

  @override
  String get externalTastingDetect => '인식';

  @override
  String get externalTastingAiScanningSub => '생산자, 빈티지, 품종, 테이스팅 노트를 인식하는 중…';

  @override
  String get externalTastingPhotoAdded => '라벨 사진을 추가했습니다';

  @override
  String get externalTastingPhotoAddedSub => '시음 일지에 표시됩니다';

  @override
  String get externalTastingReplacePhoto => '교체';

  @override
  String get externalTastingDeletePhoto => '사진 삭제';

  @override
  String get externalTastingScanLabelTitle => '라벨 촬영 (AI 스캔)';

  @override
  String get externalTastingScanLabelSub => '와인을 자동 인식해 일지에 추가합니다';

  @override
  String get externalTastingScanLabelButton => 'AI 스캔';

  @override
  String get externalTastingTakePhotoSub => '카메라로 라벨을 촬영합니다';

  @override
  String get externalTastingPickGallerySub => '기존 사진에서 선택';

  @override
  String get externalTastingWineNameLabel => '와인 이름 *';

  @override
  String get externalTastingWineNameHint => '예: Domaine de Terrebrune';

  @override
  String get externalTastingProducerHint => '예: Famille Delon';

  @override
  String get externalTastingRegionLabel => '지역 / 원산지 명칭';

  @override
  String get externalTastingRegionHint => '예: 방돌 레드';

  @override
  String get externalTastingRatingLabel => '시음 평점:';

  @override
  String get externalTastingFavorite => '마음에 쏙';

  @override
  String get externalTastingFoodLabel => '음식과의 페어링';

  @override
  String get externalTastingNotesLabel => '인상과 느낀 향';

  @override
  String get externalTastingNotesHint => '예: 진한 검은 과실, 실크 같은 타닌, 긴 여운…';

  @override
  String get externalTastingSubmit => '저장하고 평가하기 ✨';

  @override
  String get externalTastingNameRequired => '최소한 와인 이름을 입력해 주세요.';

  @override
  String get externalTastingSaved => '셀러 밖 시음을 저장했습니다! Chatmelier가 기억해 둘게요.';

  @override
  String externalTastingAiRecognized(String name) {
    return '✨ AI가 보틀을 인식했습니다: $name';
  }

  @override
  String externalTastingAiFilled(String name) {
    return '✨ AI가 양식을 채웠습니다: $name';
  }

  @override
  String externalTastingAnalysisError(String error) {
    return '분석 오류: $error';
  }

  @override
  String externalTastingSaveError(String error) {
    return '오류: $error';
  }
}
