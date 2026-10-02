/// 로딩 화면을 눈으로 보려고 일부러 늦추는 시간(ms).
///
/// 평소엔 0 이라 아무것도 안 한다. 폰에서 볼 때만
/// `--dart-define=TP_SLOW_MS=3000` 으로 켠다.
const int _slowMs = int.fromEnvironment('TP_SLOW_MS');

Future<void> slowLoad() => _slowMs > 0
    ? Future<void>.delayed(const Duration(milliseconds: _slowMs))
    : Future<void>.value();
