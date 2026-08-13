import 'package:connectivity_plus/connectivity_plus.dart';

/// 지금 인터넷에 닿을 수 있는지.
///
/// 화면은 이 인터페이스만 본다. 실패 화면이 "불러오지 못했습니다"와 "인터넷이
/// 없습니다"를 구분하려면 이게 필요하다 — 사용자 입장에서 둘은 다른 사건이다.
///
/// **연결이 있다고 해서 서버가 산 것은 아니다.** 반대는 확실하다. 그래서
/// 오프라인일 때만 문구를 바꾸고, 온라인이면 지금까지대로 실패를 보여준다.
abstract class ConnectivityService {
  /// 지금 끊겨 있는가. 모르면 false — 모른다고 못 쓰게 만들지 않는다.
  Future<bool> offline();

  /// 연결이 붙거나 끊길 때마다.
  Stream<bool> changes();
}

/// `connectivity_plus` 구현.
class ConnectivityPlusService implements ConnectivityService {
  ConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> offline() async =>
      _offline(await _connectivity.checkConnectivity());

  @override
  Stream<bool> changes() => _connectivity.onConnectivityChanged.map(_offline);

  /// 결과가 여럿 올 수 있다(와이파이 + 모바일). 하나라도 있으면 온라인이다.
  static bool _offline(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);
}
