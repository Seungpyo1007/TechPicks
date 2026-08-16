import '../app/shell/tp_tab.dart';
import '../domain/model/device_specs.dart';
import '../domain/model/ranking.dart';
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
  static const String tabHome = 'tabHome';
  static const String tabRank = 'tabRank';
  static const String tabCompare = 'tabCmp';
  static const String tabAsk = 'tabAsk';
  static const String tabYou = 'tabYou';

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
  static const String rankBy = 'rankBy';
  static const String rankNote = 'rankNote';
  static const String rankCapped = 'rankCapped';
  static const String scanCta = 'scanCta';
  static const String scanShort = 'scanShort';
  static const String noDevices = 'noDevices';

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
  static const String notifications = 'notifications';
  static const String currency = 'currency';
  static const String changePassword = 'changePw';
  static const String pwResetSent = 'pwResetSent';
  static const String pwResetFailed = 'pwResetFailed';
  static const String nameLabel = 'nameLabel';
  static const String save = 'save';
  static const String logout = 'logout';
  static const String on = 'on';
  static const String off = 'off';
  static const String noAccountYet = 'noAccountYet';
  static const String yourDevice = 'yourDevice';
  static const String yourDeviceUnknown = 'yourDeviceUnknown';
  static const String yourDeviceUnavailable = 'yourDeviceUnavailable';

  // 온보딩
  static const String skip = 'skip';
  static const String next = 'next';
  static const String start = 'start';
  static const List<({String title, String body})> onboarding = [
    (title: 'onb1', body: 'onb1b'),
    (title: 'onb2', body: 'onb2b'),
    (title: 'onb3', body: 'onb3b'),
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
  static const String loginAnon = 'lAnon';
  static const String noAccount = 'noAccount';
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
  static const String a11yProcessorRow = 'a11yProcessorRow';
  static const String a11yAxis = 'a11yAxis';
  static const String a11yAxisMissing = 'a11yAxisMissing';
  static const String a11yIndex = 'a11yIndex';
  static const String a11yCompareCell = 'a11yCompareCell';
  static const String a11yWinner = 'a11yWinner';

  static String tab(TpTab tab) => switch (tab) {
    TpTab.home => tabHome,
    TpTab.rank => tabRank,
    TpTab.compare => tabCompare,
    TpTab.ask => tabAsk,
    TpTab.you => tabYou,
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
