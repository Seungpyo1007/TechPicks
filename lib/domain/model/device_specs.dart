import '../../data/dto/smartphone.dart';
import 'tp_index.dart';
import 'tp_money.dart';
import 'tp_weights.dart';

/// 상세와 비교가 같은 순서로 보여주는 속성.
///
/// 목록은 `docs/DESIGN_HANDOFF.md` — Compare 의 것을 그대로 쓴다. 상세도 같은
/// 목록이라고 명시돼 있어서 한 곳에서 만든다.
enum SpecKind {
  tpIndex('spec_tp_index'),
  price('spec_price'),
  screen('spec_screen'),
  chipset('spec_chipset'),
  camera('spec_camera'),
  battery('spec_battery'),
  os('spec_os'),
  weight('spec_weight'),
  thickness('spec_thickness'),
  released('spec_released');

  const SpecKind(this.key);

  /// `assets/translations/*.json` 의 번역 키.
  final String key;
}

/// 승자를 못 가리는 줄이 대신 보여주는 점수 축.
///
/// 화면·프로세서·카메라는 문자열이라 무엇이 나은지 데이터만 보고 못 정한다
/// ([DeviceComparison._winner] 를 볼 것). 대신 그 줄에 대응하는 0–100 점수를
/// 막대로 깐다 — 승자를 선언하지 않으면서 크기는 보여준다.
///
/// 축 **이름은 화면에 안 찍는다.** `axCam`·`axBatt` 가 행 라벨
/// (`detailSpecCamera`·`detailSpecBattery`)과 영어에서도 한국어에서도 같은
/// 문자열이라, 찍는 순간 같은 글자가 화면에 둘이 된다.
extension SpecScoreAxis on SpecKind {
  TpAxisKind? get scoreAxis => switch (this) {
    SpecKind.screen => TpAxisKind.display,
    SpecKind.chipset => TpAxisKind.performance,
    SpecKind.camera => TpAxisKind.camera,
    _ => null,
  };
}

/// 속성 한 줄.
class DeviceSpec {
  const DeviceSpec({
    required this.kind,
    required this.value,
    this.comparable,
    this.higherIsBetter = true,
  });

  final SpecKind kind;

  /// 화면에 그대로 찍는 문자열. 값이 없으면 대시.
  final String value;

  /// 비교 화면에서 승자를 가릴 때 쓰는 수치. null 이면 비교하지 않는다.
  final double? comparable;

  final bool higherIsBetter;

  bool get hasValue => value != DeviceSpecs.empty;
}

abstract final class DeviceSpecs {
  /// 값이 없을 때 찍는 문자.
  static const String empty = '—';

  static List<DeviceSpec> of(
    Smartphone d, [
    TpWeights weights = TpWeights.defaults,
    TpMoney money = const TpMoney.usd(),
  ]) {
    final index = TpIndex.of(d.score, weights);

    return <DeviceSpec>[
      DeviceSpec(
        kind: SpecKind.tpIndex,
        value: index?.toString() ?? empty,
        comparable: index?.toDouble(),
      ),
      DeviceSpec(
        kind: SpecKind.price,
        // 환산은 **보여줄 때만**. 아래 comparable 은 USD 그대로다 —
        // 환율이 움직여도 어느 쪽이 싼지는 안 바뀌어야 한다.
        value: money.format(d.msrpUsd),
        comparable: d.msrpUsd?.toDouble(),
        // 싼 쪽이 이긴다.
        higherIsBetter: false,
      ),
      DeviceSpec(kind: SpecKind.screen, value: _screen(d)),
      DeviceSpec(kind: SpecKind.chipset, value: d.soc?.name ?? empty),
      DeviceSpec(kind: SpecKind.camera, value: _camera(d)),
      DeviceSpec(
        kind: SpecKind.battery,
        value: _battery(d),
        comparable: d.batteryMah?.toDouble(),
      ),
      DeviceSpec(kind: SpecKind.os, value: _os(d)),
      // 무게와 두께는 수치지만 비교 대상에서 뺐다. 명세가 숫자로 비교하는
      // 행을 index·price·battery 셋으로 못박았고, 가벼운 쪽이 항상 낫다고
      // 할 수도 없다(배터리를 줄여 가벼운 경우가 있다).
      DeviceSpec(
        kind: SpecKind.weight,
        value: d.weightG == null ? empty : '${_trim(d.weightG!)} g',
      ),
      DeviceSpec(
        kind: SpecKind.thickness,
        value: d.dimensions?.depthMm == null
            ? empty
            : '${_trim(d.dimensions!.depthMm!)} mm',
      ),
      DeviceSpec(kind: SpecKind.released, value: d.releaseDate ?? empty),
    ];
  }

  /// `$1,299`. 값이 없으면 대시.
  ///
  /// 환율을 모르는 자리가 쓴다. 로케일을 아는 화면은 [TpMoney] 를 받아서
  /// 쓴다 — 이건 그 기본값과 같다.
  static String formatPrice(int? usd) {
    if (usd == null) return empty;
    return '\$${group(usd)}';
  }

  /// 천 단위 쉼표. `5000` → `5,000`.
  static String group(int n) {
    final s = n.abs().toString();
    final buf = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// `5,000mAh · 60W`. 충전 값이 없으면 용량만.
  static String battery(int? mah, [num? watts]) {
    if (mah == null) return empty;
    final cell = '${group(mah)}mAh';
    return watts == null ? cell : '$cell · ${_trim(watts.toDouble())}W';
  }

  /// 패널 이름에서 종류만 남긴다. 제조사 상표와 괄호 설명은 뺀다.
  ///
  /// `Dynamic LTPO AMOLED 2X (Privacy Display)` → `LTPO AMOLED`.
  /// 아는 낱말이 하나도 없으면 괄호만 떼고 그대로.
  static String panel(String type) {
    final plain = type.replaceAll(RegExp(r'\s*\(.*?\)'), '').trim();
    final kept = plain
        .split(RegExp(r'\s+'))
        .where((w) => _panelWords.contains(w.toUpperCase()))
        .toList();
    return kept.isEmpty ? plain : kept.join(' ');
  }

  static const Set<String> _panelWords = <String>{
    'LTPO',
    'LTPS',
    'IPS',
    'PLS',
    'AMOLED',
    'OLED',
    'POLED',
    'LCD',
  };

  static String _screen(Smartphone d) {
    final disp = d.display;
    if (disp == null) return empty;
    final parts = <String>[
      if (disp.sizeInch != null) '${_trim(disp.sizeInch!)}"',
      // 전체 이름을 쓰면 값이 세 줄까지 늘어난다.
      if (disp.type != null) panel(disp.type!),
      if (disp.refreshHz != null) '${disp.refreshHz}Hz',
    ];
    return parts.isEmpty ? empty : parts.join(' · ');
  }

  /// 후면 카메라 화소를 큰 순서로. 셀피는 뺀다.
  static String _camera(Smartphone d) {
    final rear =
        d.cameras
            .where((c) => c.type != 'selfie' && c.mp != null)
            .map((c) => c.mp!)
            .toList()
          ..sort((a, b) => b.compareTo(a));
    if (rear.isEmpty) return empty;
    return rear.map((mp) => '${_trim(mp)}MP').join(' + ');
  }

  static String _battery(Smartphone d) =>
      battery(d.batteryMah, d.chargingWiredW);

  static String _os(Smartphone d) {
    if (d.os == null) return empty;
    return d.osVersion == null ? d.os! : '${d.os} ${d.osVersion}';
  }

  /// 소수점이 0 이면 떼고 찍는다. `6.0"` 보다 `6"` 가 낫다.
  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}

/// 비교 한 줄. 두 기기의 같은 속성을 나란히 놓고 승자를 표시한다.
class SpecPair {
  const SpecPair({
    required this.kind,
    required this.a,
    required this.b,
    required this.winner,
  });

  final SpecKind kind;
  final DeviceSpec a;
  final DeviceSpec b;

  /// 이긴 쪽. 비길 수 없거나 비교 대상이 아니면 null.
  final CompareSide? winner;

  bool get isTie => winner == null;
}

enum CompareSide { a, b }

abstract final class DeviceComparison {
  /// 두 기기를 명세의 속성 순서대로 짝지어 승자를 낸다.
  ///
  /// 수치가 있는 줄만 비교한다. 명세가 "textual rows are marked only where a
  /// winner is unambiguous" 라고 했는데, 화면·칩셋·OS 같은 문자열은 무엇이
  /// 나은지 데이터만 보고 정할 수 없다. 그래서 표시하지 않는다.
  static List<SpecPair> of(
    Smartphone a,
    Smartphone b, [
    TpWeights weights = TpWeights.defaults,
    TpMoney money = const TpMoney.usd(),
  ]) {
    final left = DeviceSpecs.of(a, weights, money);
    final right = DeviceSpecs.of(b, weights, money);

    return <SpecPair>[
      for (var i = 0; i < left.length; i++)
        SpecPair(
          kind: left[i].kind,
          a: left[i],
          b: right[i],
          winner: _winner(left[i], right[i]),
        ),
    ];
  }

  static CompareSide? _winner(DeviceSpec a, DeviceSpec b) {
    final x = a.comparable;
    final y = b.comparable;
    // 한쪽만 값이 있으면 그쪽이 이긴 것처럼 보이지만, 없는 값은 나쁜 값이
    // 아니라 모르는 값이다. 표시하지 않는다.
    if (x == null || y == null || x == y) return null;
    final aWins = a.higherIsBetter ? x > y : x < y;
    return aWins ? CompareSide.a : CompareSide.b;
  }
}
