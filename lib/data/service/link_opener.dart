import 'package:url_launcher/url_launcher.dart';

/// 앱 밖으로 나가는 링크.
///
/// 화면은 이 인터페이스만 본다. 테스트가 브라우저를 띄우지 않게 하려는 것이다.
abstract class LinkOpener {
  /// 열었으면 true. 못 열면 false — 화면은 아무 일도 안 일어난 것으로 둔다.
  Future<bool> open(Uri url);
}

/// `url_launcher` 구현.
class UrlLauncherOpener implements LinkOpener {
  const UrlLauncherOpener();

  @override
  Future<bool> open(Uri url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);
}

/// 화면이 여는 고정 주소.
abstract final class TpUrls {
  /// TechAPI 데이터의 라이선스. **표기만으로는 CC-BY-SA 를 못 지킨다** —
  /// 라이선스 본문에 닿을 수 있어야 한다.
  static final Uri license = Uri.parse(
    'https://creativecommons.org/licenses/by-sa/4.0/',
  );

  /// 앱 코드의 라이선스. You 화면 푸터가 Apache-2.0 이라고 적어뒀다.
  static final Uri appLicense = Uri.parse(
    'https://www.apache.org/licenses/LICENSE-2.0',
  );
}
