import 'package:app_links/app_links.dart';

/// 밖에서 들어온 링크.
///
/// 화면은 이 인터페이스만 본다. 테스트가 플랫폼 채널을 타지 않아도 되게 하려는
/// 것이다. 받은 URI 를 해석하는 것은 [TpLink] 가 하고 여기서는 나르기만 한다.
abstract class DeepLinkService {
  /// 앱이 꺼져 있을 때 눌린 링크. 없으면 null.
  Future<Uri?> initial();

  /// 앱이 떠 있는 동안 들어오는 링크.
  Stream<Uri> stream();
}

/// `app_links` 구현.
class AppLinksService implements DeepLinkService {
  AppLinksService({AppLinks? links}) : _links = links ?? AppLinks();

  final AppLinks _links;

  @override
  Future<Uri?> initial() => _links.getInitialLink();

  @override
  Stream<Uri> stream() => _links.uriLinkStream;
}
