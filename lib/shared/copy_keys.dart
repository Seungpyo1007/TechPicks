import '../app/shell/tp_tab.dart';
import '../domain/model/device_specs.dart';
import '../domain/model/ranking.dart';
import '../app/providers.dart' show TpCurrency;
import '../domain/model/search_index.dart';
import '../domain/model/tp_index.dart';

/// 번역 키.
///
/// 값은 `assets/translations/en-US.json` / `ko-KR.json` 에 있고, 그 원본은
/// 프로토타입의 `T` 객체다 (`docs/design/index.html`). 키 이름도 그쪽을
/// 그대로 쓴다 — 명세가 "Add them to ... under the same keys" 라고 했다.
///
/// 문자열을 코드에 흩어두지 않고 여기 모으는 이유는, 화면이 쓰는 키가 실제로
/// 번역 파일에 있는지 테스트가 한 곳에서 확인할 수 있게 하려는 것이다.
abstract final class K {
  // 탭
  static const String tabToday = 'tabToday';
  static const String tabBrowse = 'tabBrowse';
  static const String tabCompare = 'tabCompare';
  static const String tabSearch = 'tabSearch';
  static const String askTitle = 'askTitle';
  static const String sort = 'sort';
  static const String filter = 'filter';
  static const String sortScore = 'sortScore';
  static const String sortName = 'sortName';
  static const String sortPriceHigh = 'sortPriceHigh';
  static const String sortPriceLow = 'sortPriceLow';
  static const String allPrices = 'allPrices';
  static const String cpuStatus = 'cpuStatus';
  static const String laptopStatus = 'laptopStatus';
  static const String clear = 'clear';
  static const String rankStatus = 'rankStatus';
  static const String buildRowSub = 'buildRowSub';
  static const String weights = 'weights';
  static const String removeShort = 'removeShort';
  static const String browseByKind = 'browseByKind';
  static const String recent = 'recent';
  static const String searchTry = 'searchTry';
  static const String searchTryMore = 'searchTryMore';
  static const String done = 'done';
  static const String buildUse = 'buildUse';

  // 홈
  static const String homeTitle = 'homeTitle';
  static const String homeSubNone = 'homeSubNone';
  static const String homeSubOne = 'homeSubOne';
  static const String homeSubMany = 'homeSubMany';
  static const String verdictReason = 'verdictReason';
  static const String verdictNoData = 'verdictNoData';
  static const String verdict = 'verdict';
  static const String tpIndex = 'tpIndex';
  static const String shortlist = 'shortlist';
  static const String remove = 'remove';
  static const String addDevice = 'addDevice';
  static const String compareAll = 'compareAll';
  static const String askWhy = 'askWhy';
  static const String movers = 'movers';
  static const String emptyShortlist = 'emptyShortlist';
  static const String emptyShortlistBody = 'emptyShortlistBody';
  static const String emptyShortlistCta = 'emptyShortlistCta';

  // 랭킹
  static const String rankTitle = 'rankTitle';
  static const String cpus = 'cpus';
  static const String laptops = 'laptops';
  static const String rankNote = 'rankNote';
  static const String rankCapped = 'rankCapped';
  static const String scanCta = 'scanCta';
  static const String scanShort = 'scanShort';
  static const String noDevices = 'noDevices';
  static const String noMatches = 'noMatches';
  static const String allBrands = 'allBrands';
  static const String brand = 'brand';

  // 프로세서
  static const String cpuTitle = 'cpuTitle';
  static const String phones = 'phones';
  static const String cpuMobile = 'cpuMobile';
  static const String cpuLaptop = 'cpuLaptop';
  static const String cpuNote = 'cpuNote';

  // 비교
  static const String compareTitle = 'cmpTitle';
  static const String choose = 'choose';
  static const String cancel = 'cancel';
  static const String close = 'close';
  static const String back = 'back';
  static const String chooseTwo = 'chooseTwo';
  static const String searchHint = 'searchHint';
  static const String tapToChange = 'tapToChange';

  // 상세
  static const String addShortlist = 'addShort';
  static const String inShortlist = 'inShort';
  static const String compareButton = 'compareB';
  static const String view3d = 'view3d';
  static const String dataSource = 'dataSource';
  static const String brandFounded = 'brandFounded';
  static const String brandSite = 'brandSite';
  static const String loadFailed = 'loadFailed';
  static const String loadFailedBody = 'loadFailedBody';
  static const String catalogFailedTitle = 'catalogFailedTitle';
  static const String catalogFailedBody = 'catalogFailedBody';
  static const String retry = 'retry';
  static const String offlineTitle = 'offlineTitle';
  static const String offlineBody = 'offlineBody';

  // 공유
  static const String share = 'share';
  static const String shareDevice = 'shareDevice';
  static const String shareSubject = 'shareSubject';

  // 상담
  static const String chatSeed = 'chatSeed';
  static const String askHint = 'askHint';
  static const String askThinking = 'askThinking';
  static const String send = 'send';
  static const String askFailed = 'askFailed';
  static const String askFromCatalog = 'askFromCatalog';
  static const String askLocalTop = 'askLocalTop';
  static const String askLocalBudget = 'askLocalBudget';
  static const List<String> askSuggestions = <String>[
    'askSuggest1',
    'askSuggest2',
    'askSuggest3',
    'askSuggest4',
  ];

  // 내 정보
  static const String you = 'you';
  static const String editProfile = 'editProfile';
  static const String priorities = 'priorities';
  static const String prioritiesNote = 'prioritiesNote';
  static const String reset = 'reset';
  static const String language = 'language';
  static const String darkMode = 'darkMode';
  static const String aiEngine = 'aiEngine';
  static const String aiEngineAuto = 'aiEngineAuto';
  static const String aiEngineOnDevice = 'aiEngineOnDevice';
  static const String aiEngineCloud = 'aiEngineCloud';
  static const String aiEngineUnavailable = 'aiEngineUnavailable';
  static const String aiEngineDisabled = 'aiEngineDisabled';
  static const String themeSystem = 'themeSystem';
  static const String themeLight = 'themeLight';
  static const String themeDark = 'themeDark';
  static const String notifications = 'notifications';
  static const String changePassword = 'changePw';
  static const String pwResetSent = 'pwResetSent';
  static const String pwResetFailed = 'pwResetFailed';
  static const String nameLabel = 'nameLabel';
  static const String usernameLabel = 'usernameLabel';
  static const String pronounsLabel = 'pronounsLabel';
  static const String phoneLabel = 'phoneLabel';
  static const String genderLabel = 'genderLabel';
  static const String changePhoto = 'changePhoto';
  static const String photoFailed = 'photoFailed';
  static const String profileSaved = 'profileSaved';
  static const String profileFailed = 'profileFailed';
  static const String save = 'save';
  static const String logout = 'logout';
  static const String logoutConfirm = 'logoutConfirm';
  static const String on = 'on';
  static const String off = 'off';
  static const String yourDevice = 'yourDevice';
  static const String yourDeviceUnknown = 'yourDeviceUnknown';
  static const String yourDeviceUnavailable = 'yourDeviceUnavailable';

  static const String seeAll = 'seeAll';
  static const String askPlaceholder = 'askPlaceholder';

  /// TP 지수 설명. **기본 가중치일 때만** 쓴다 — 문구가 25/25/20/20/10 을
  /// 못박고 있는데 그건 기본값일 뿐이고 You 에서 바꿀 수 있다.
  static const String indexNote = 'indexNote';
  static const String indexNoteCustom = 'indexNoteCustom';

  // 데이터 출처. CC-BY-SA 4.0 은 표기가 선택이 아니다.
  // 통화. currency 키는 여태 죽어 있었다 — 값이 USD 하나뿐이라 고를 게
  // 없어서 줄을 뺐었다. 원화가 들어오면서 되살아난다.
  static const String currency = 'currency';
  static const String currencyAuto = 'currencyAuto';
  static const String currencyUsd = 'currencyUsd';
  static const String currencyKrw = 'currencyKrw';
  static const String fxNote = 'fxNote';
  static const String fxNoteOffline = 'fxNoteOffline';

  static String currencyOf(TpCurrency c) => switch (c) {
    TpCurrency.auto => currencyAuto,
    TpCurrency.usd => currencyUsd,
    TpCurrency.krw => currencyKrw,
  };

  // 통합 검색. 기존 searchHint 는 "기기 검색" 이라 폰 전용 문구다 —
  // 픽커와 랭킹이 쓴다. 세 갈래를 다 훑는 여기는 제 문구가 필요하다.
  static const String searchTitle = 'searchTitle';
  static const String searchAllHint = 'searchAllHint';
  static const String searchEmpty = 'searchEmpty';
  static const String searchKindPhone = 'searchKindPhone';
  static const String searchKindCpu = 'searchKindCpu';
  static const String searchKindLaptop = 'searchKindLaptop';
  static const String searchCount = 'searchCount';

  /// 갈래 라벨. SearchKind 가 아니라 여기 둔다 — 도메인 열거형이 화면
  /// 문구까지 들면 두 관심사가 한 곳에 섞인다.
  static String searchKind(SearchKind kind) => switch (kind) {
    SearchKind.phone => searchKindPhone,
    SearchKind.processor => searchKindCpu,
    SearchKind.laptop => searchKindLaptop,
  };

  // 조립 견적. 용도 라벨과 요구사양 라벨은 BuildUseCase·RequirementKind 가
  // 제 key 로 들고 있다 — 도메인이 문장을 안 만들되 키는 안다.
  static const String buildTitle = 'buildTitle';
  static const String buildBudget = 'buildBudget';
  static const String buildEmpty = 'buildEmpty';
  static const String buildReasonGpu = 'buildReasonGpu';
  static const String buildReasonCpu = 'buildReasonCpu';
  static const String buildHeadroom = 'buildHeadroom';
  static const String buildTight = 'buildTight';
  static const String buildPsu = 'buildPsu';
  static const String buildReq = 'buildReq';
  static const String buildReqNone = 'buildReqNone';
  static const String buildReqNoIgpu = 'buildReqNoIgpu';
  static const String buildWatts = 'buildWatts';
  static const String buildBottleneckCpu = 'buildBottleneckCpu';
  static const String buildBottleneckGpu = 'buildBottleneckGpu';
  static const String buildScope = 'buildScope';
  static const String buildPsuNote = 'buildPsuNote';

  // 노트북
  static const String laptopTitle = 'laptopTitle';
  static const String laptopNote = 'laptopNote';
  static const String laptopTierHigh = 'laptopTierHigh';
  static const String laptopTierPerf = 'laptopTierPerf';
  static const String laptopTierMain = 'laptopTierMain';
  static const String laptopNoScore = 'laptopNoScore';
  static const String specRam = 'specRam';
  static const String specStorage = 'specStorage';
  static const String specGpu = 'specGpu';

  static const String sources = 'sources';
  static const String sourcesIntro = 'sourcesIntro';
  static const String sourcesDataset = 'sourcesDataset';
  static const String sourcesLicense = 'sourcesLicense';
  static const String sourcesRepo = 'sourcesRepo';
  static const String sourcesContents = 'sourcesContents';
  static const String sourcesPhones = 'sourcesPhones';
  static const String sourcesCpus = 'sourcesCpus';
  static const String sourcesSocs = 'sourcesSocs';
  static const String sourcesBrands = 'sourcesBrands';
  static const String sourcesVersion = 'sourcesVersion';
  static const String sourcesPerDevice = 'sourcesPerDevice';
  static const String sourcesAppCode = 'sourcesAppCode';

  // 온보딩
  static const String skip = 'skip';
  static const String next = 'next';
  static const String startSignIn = 'startSignIn';
  static const String startGuest = 'startGuest';
  static const List<({String title, String body})> onboarding = [
    (title: 'onb1', body: 'onb1b'),
    (title: 'onb2', body: 'onb2b'),
    (title: 'onb3', body: 'onb3b'),
    (title: 'onb4', body: 'onb4b'),
  ];

  // 로그인
  static const String welcome = 'welcome';
  static const String welcomeSub = 'welcomeSubShort';
  static const String notConnected = 'notConnected';
  static const String emailNeeded = 'emailNeeded';
  static const String anonFailed = 'anonFailed';
  static const String loginGoogle = 'lGoogle';
  static const String loginApple = 'lApple';
  static const String loginEmail = 'lEmail';
  static const String signup = 'signup';
  static const String haveAccount = 'haveAccount';
  static const String emailTitle = 'emailTitle';
  static const String signupTitle = 'signupTitle';
  static const String emailLabel = 'emailLabel';
  static const String passwordLabel = 'passwordLabel';
  static const String signIn = 'signIn';
  static const String emailInvalid = 'emailInvalid';
  static const String passwordShort = 'passwordShort';
  static const String authFailed = 'authFailed';
  static const String signupFailed = 'signupFailed';
  static const String loginTitle = 'loginTitle';
  static const String loginWhy = 'loginWhy';
  static const String continueApple = 'continueApple';
  static const String continueGoogle = 'continueGoogle';
  static const String continueEmail = 'continueEmail';
  static const String legalLine = 'legalLine';
  static const String forgotPw = 'forgotPw';
  static const String resetTitle = 'resetTitle';
  static const String resetBody = 'resetBody';
  static const String resetSend = 'resetSend';
  static const String resetSent = 'resetSent';
  static const String pwHint = 'pwHint';
  static const String signedIn = 'signedIn';
  static const String guestTitle = 'guestTitle';
  static const String guestBody = 'guestBody';
  static const String account = 'account';
  static const String viaApple = 'viaApple';
  static const String viaGoogle = 'viaGoogle';
  static const String viaEmail = 'viaEmail';
  static const String verifyEmail = 'verifyEmail';
  static const String resend = 'resend';
  static const String verifySent = 'verifySent';
  static const String deleteAccount = 'deleteAccount';
  static const String deleteConfirm = 'deleteConfirm';
  static const String deletePassword = 'deletePassword';
  static const String delete = 'delete';
  static const String deleted = 'deleted';
  static const String promptTitle = 'promptTitle';
  static const String notNow = 'notNow';
  static const String coachDone = 'coachDone';
  static const String coachClose = 'coachClose';
  static const String coachReplay = 'coachReplay';
  static const String coachReplayed = 'coachReplayed';
  static const String coachVerdict = 'coachVerdict';
  static const String coachVerdictBody = 'coachVerdictBody';
  static const String coachWeights = 'coachWeights';
  static const String coachWeightsBody = 'coachWeightsBody';
  static const String coachAsk = 'coachAsk';
  static const String coachAskBody = 'coachAskBody';
  static const String coachYou = 'coachYou';
  static const String coachYouBody = 'coachYouBody';
  static const String coachSearch = 'coachSearch';
  static const String coachSearchBody = 'coachSearchBody';
  static const String coachCategory = 'coachCategory';
  static const String coachCategoryBody = 'coachCategoryBody';
  static const String coachFilter = 'coachFilter';
  static const String coachFilterBody = 'coachFilterBody';
  static const String coachCompare = 'coachCompare';
  static const String coachCompareBody = 'coachCompareBody';
  static const String weightsBalanced = 'weightsBalanced';
  static const String weightsLead = 'weightsLead';
  static const String unverified = 'unverified';
  static const String authBadCredentials = 'authBadCredentials';
  static const String authEmailInUse = 'authEmailInUse';
  static const String authWeakPassword = 'authWeakPassword';
  static const String authNetwork = 'authNetwork';
  static const String authTooMany = 'authTooMany';
  static const String authOtherProvider = 'authOtherProvider';
  static const String authRecentLogin = 'authRecentLogin';
  static const String authDisabled = 'authDisabled';
  static const String authNotConfigured = 'authNotConfigured';

  // 스캔 · 뷰어
  static const String scanTitle = 'scanTitle';
  static const String scanHintIdle = 'scanHintIdle';
  static const String scanHintDone = 'scanHintDone';
  static const String scanFieldLabel = 'scanFieldLabel';
  static const String scanFieldHint = 'scanFieldHint';
  static const String scanNoMatch = 'scanNoMatch';
  static const String detected = 'detected';
  static const String openDevice = 'open';
  static const String viewerNote = 'viewerNote';
  static const String partDisplay = 'partDisplay';
  static const String partBattery = 'partBattery';
  static const String partChip = 'partChip';
  static const String partCamera = 'partCamera';

  // 스크린 리더 전용. 화면에는 안 보이고 읽히기만 한다.
  static const String a11yRankRow = 'a11yRankRow';
  static const String a11yMoverRow = 'a11yMoverRow';
  static const String a11yMoverDown = 'a11yMoverDown';
  static const String a11yProcessorRow = 'a11yProcessorRow';
  static const String a11yAxis = 'a11yAxis';
  static const String a11yAxisMissing = 'a11yAxisMissing';
  static const String a11yIndex = 'a11yIndex';
  static const String a11yCompareCell = 'a11yCompareCell';
  static const String a11yWinner = 'a11yWinner';

  static String tab(TpTab tab) => switch (tab) {
    TpTab.today => tabToday,
    TpTab.browse => tabBrowse,
    TpTab.compare => tabCompare,
    TpTab.search => tabSearch,
  };

  static String axis(TpAxisKind kind) => switch (kind) {
    TpAxisKind.performance => 'axPerf',
    TpAxisKind.camera => 'axCam',
    TpAxisKind.display => 'axDisplay',
    TpAxisKind.battery => 'axBatt',
    TpAxisKind.value => 'axVal',
  };

  static String rankAxis(RankAxis axis) => switch (axis) {
    RankAxis.tpIndex => 'axIndex',
    RankAxis.battery => 'axBatt',
    RankAxis.camera => 'axCam',
    RankAxis.value => 'axVal',
    RankAxis.price => 'axPrice',
  };

  static String spec(SpecKind kind) => switch (kind) {
    SpecKind.tpIndex => tpIndex,
    SpecKind.price => 'detailSpecPrice',
    SpecKind.screen => 'detailSpecScreen',
    SpecKind.chipset => 'detailSpecChipset',
    SpecKind.camera => 'detailSpecCamera',
    SpecKind.battery => 'detailSpecBattery',
    SpecKind.os => 'detailSpecOs',
    SpecKind.weight => 'detailSpecWeight',
    SpecKind.thickness => 'detailSpecThickness',
    SpecKind.released => 'detailSpecReleased',
  };
}
