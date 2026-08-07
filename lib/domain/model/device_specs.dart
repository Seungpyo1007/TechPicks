import '../../data/dto/smartphone.dart';
import 'tp_index.dart';
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
        value: formatPrice(d.msrpUsd),
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
  static String formatPrice(int? usd) {
    if (usd == null) return empty;
    final s = usd.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '\$$buf';
  }

  static String _screen(Smartphone d) {
    final disp = d.display;
    if (disp == null) return empty;
    final parts = <String>[
      if (disp.sizeInch != null) '${_trim(disp.sizeInch!)}"',
      if (disp.type != null) disp.type!,
      if (disp.refreshHz != null) '${disp.refreshHz}Hz',
    ];
    return parts.isEmpty ? empty : parts.join(' · ');
  }

  /// 후면 카메라 화소를 큰 순서로. 셀피는 뺀다.
  static String _camera(Smartphone d) {
    final rear = d.cameras
        .where((c) => c.type != 'selfie' && c.mp != null)
        .map((c) => c.mp!)
        .toList()
      ..sort((a, b) => b.compareTo(a));
    if (rear.isEmpty) return empty;
    return rear.map((mp) => '${_trim(mp)}MP').join(' + ');
  }

  static String _battery(Smartphone d) {
    if (d.batteryMah == null) return empty;
    final w = d.chargingWiredW;
    return w == null ? '${d.batteryMah}mAh' : '${d.batteryMah}mAh · ${w}W';
  }

  static String _os(Smartphone d) {
    if (d.os == null) return empty;
    return d.osVersion == null ? d.os! : '${d.os} ${d.osVersion}';
  }

  /// 소수점이 0 이면 떼고 찍는다. `6.0"` 보다 `6"` 가 낫다.
  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();
}
