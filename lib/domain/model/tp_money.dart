/// 값을 보여주는 방식.
///
/// 카탈로그의 가격은 전부 **USD 기준가**다. 모델은 USD 로 두고 표시하는
/// 경계에서만 바꾼다 — 환산한 값을 모델에 넣으면 환율이 움직일 때마다
/// 저장된 값이 거짓이 된다.
///
/// `DeviceSpecs.formatPrice` 를 여기로 옮기지 않고 감싼다. 그건
/// `BuildContext` 없는 순수 정적이고, 부르는 곳 중 하나는 위젯도 아니다
/// (`ask_service.dart`). `TpWeights` 가 `DeviceSpecs.of` 에 인자로 들어가는
/// 것과 같은 자리에 둔다.
library;

/// 환율이 어디서 왔는지.
///
/// 화면에 밝힌다. 명세는 환율 환산을 금지했는데 그걸 뒤집는 것이라, 무슨
/// 값을 언제 받아 쓰는지 보이지 않으면 그냥 지어낸 숫자와 구분이 안 된다.
enum RateOrigin {
  /// 오늘 받은 값.
  live,

  /// 저장해둔 마지막 값. 네트워크가 없거나 실패했다.
  cached,

  /// 컴파일에 박힌 값. 한 번도 못 받았다.
  fallback,
}

/// USD → KRW 환율 한 벌.
class FxRate {
  const FxRate({
    required this.krwPerUsd,
    required this.asOf,
    required this.origin,
  });

  /// 1 USD 가 몇 원인지.
  final double krwPerUsd;

  /// 이 값을 받은 때.
  final DateTime asOf;

  final RateOrigin origin;

  /// 한 번도 못 받았을 때 쓰는 값.
  ///
  /// 날짜를 같이 박아둔다. 화면이 "언제 기준"인지 말할 수 있어야 하고,
  /// 이 상수가 낡았다는 것도 그 날짜로 드러난다.
  static final FxRate fallback = FxRate(
    krwPerUsd: 1373,
    asOf: DateTime.utc(2026, 9, 19),
    origin: RateOrigin.fallback,
  );

  /// 하루가 지나면 다시 받는다.
  bool staleAt(DateTime now) => now.difference(asOf) > const Duration(days: 1);
}

/// 값을 문자열로.
class TpMoney {
  /// 그대로 달러로. 기본값이다.
  const TpMoney.usd() : rate = null;

  /// 원화로 환산해서.
  const TpMoney.krw(FxRate this.rate);

  /// null 이면 환산하지 않는다.
  final FxRate? rate;

  bool get isKrw => rate != null;

  /// 값이 없으면 대시. [DeviceSpecs.empty] 와 같은 문자다 — 두 곳이 다른
  /// 글자를 쓰면 한 화면에 두 종류의 "없음" 이 생긴다.
  static const String empty = '—';

  /// `$1,299` 또는 `₩1,783,000`.
  String format(int? usd) {
    if (usd == null) return empty;
    final fx = rate;
    if (fx == null) return '\$${_group(usd)}';

    // 원 단위는 소수점이 없다. 천 원 미만을 버리면 "1,783,000" 처럼 읽기
    // 쉬운데, 그러면 싼 물건에서 오차가 커진다 — 반올림만 한다.
    final krw = (usd * fx.krwPerUsd).round();
    return '₩${_group(krw)}';
  }

  /// 세 자리마다 쉼표.
  static String _group(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}
