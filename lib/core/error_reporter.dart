import 'package:flutter/foundation.dart';

/// 삼킨 실패를 어디론가 보내는 곳.
///
/// 이 앱은 예외를 일부러 삼킨다 — 로그인이 안 돼도, 카탈로그를 못 읽어도
/// 화면이 죽는 것보다 낫다는 판단이다. 그래서 **프로덕션에서 어떤 실패가
/// 얼마나 나는지 아무것도 안 보인다.**
///
/// 삼키는 동작은 그대로 두고 기록만 남긴다.
abstract class ErrorSink {
  void record(Object error, StackTrace? stack, {String? reason});
}

/// 아무 데도 안 보낸다. 테스트와 Firebase 없는 빌드의 기본값.
class SilentErrorSink implements ErrorSink {
  const SilentErrorSink();

  @override
  void record(Object error, StackTrace? stack, {String? reason}) {}
}

/// 개발 중에 콘솔로 본다.
class DebugErrorSink implements ErrorSink {
  const DebugErrorSink();

  @override
  void record(Object error, StackTrace? stack, {String? reason}) {
    debugPrint('[삼킨 실패] ${reason ?? ''} $error');
  }
}

/// 앱 전역의 기록 지점.
///
/// 프로바이더로 넘기지 않는 이유는 기록하는 자리가 리포지토리·서비스 안이고
/// 그중 일부는 `ref` 를 안 들고 있기 때문이다. 호출부를 한 줄로 유지한다.
abstract final class TpErrors {
  static ErrorSink _sink = const SilentErrorSink();

  /// 앱 시작 때 한 번 갈아 끼운다. 테스트가 되돌릴 수 있게 이전 것을 돌려준다.
  static ErrorSink use(ErrorSink sink) {
    final previous = _sink;
    _sink = sink;
    return previous;
  }

  /// [reason] 은 어디서 삼켰는지다. 스택만으로는 구분이 안 된다.
  static void record(Object error, StackTrace? stack, {String? reason}) =>
      _sink.record(error, stack, reason: reason);
}
