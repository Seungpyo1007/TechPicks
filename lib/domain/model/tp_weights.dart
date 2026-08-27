import 'package:flutter/foundation.dart';

/// TP Index 를 계산할 때 각 축에 주는 비중.
///
/// **고정된 값이 아니다.** You 화면의 슬라이더가 이걸 바꾸고, 바뀌면 화면에
/// 보이는 모든 지수가 다시 계산된다. 그래서 TechAPI 가 내려주는
/// `score.overall` 을 그대로 쓰지 않는다. 그쪽은 TechAPI 의 가중치로 이미
/// 접힌 값이라 사용자가 손댈 수 없다.
///
/// 기본값은 `docs/DESIGN_HANDOFF.md` — Data model 의 식과 같다.
@immutable
class TpWeights {
  const TpWeights({
    required this.performance,
    required this.camera,
    required this.display,
    required this.battery,
    required this.value,
  });

  /// 명세의 기본 가중치.
  static const TpWeights defaults = TpWeights(
    performance: 0.25,
    camera: 0.25,
    display: 0.20,
    battery: 0.20,
    value: 0.10,
  );

  final double performance;
  final double camera;
  final double display;
  final double battery;
  final double value;

  double get total => performance + camera + display + battery + value;

  TpWeights copyWith({
    double? performance,
    double? camera,
    double? display,
    double? battery,
    double? value,
  }) => TpWeights(
    performance: performance ?? this.performance,
    camera: camera ?? this.camera,
    display: display ?? this.display,
    battery: battery ?? this.battery,
    value: value ?? this.value,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'performance': performance,
    'camera': camera,
    'display': display,
    'battery': battery,
    'value': value,
  };

  /// 저장된 값이 깨졌거나 없으면 기본값으로 떨어진다.
  factory TpWeights.fromJson(Map<String, dynamic> json) {
    double read(String key, double fallback) {
      final v = json[key];
      return v is num && v.isFinite && v >= 0 ? v.toDouble() : fallback;
    }

    return TpWeights(
      performance: read('performance', defaults.performance),
      camera: read('camera', defaults.camera),
      display: read('display', defaults.display),
      battery: read('battery', defaults.battery),
      value: read('value', defaults.value),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TpWeights &&
      other.performance == performance &&
      other.camera == camera &&
      other.display == display &&
      other.battery == battery &&
      other.value == value;

  @override
  int get hashCode => Object.hash(performance, camera, display, battery, value);

  @override
  String toString() =>
      'TpWeights(perf: $performance, cam: $camera, '
      'disp: $display, batt: $battery, val: $value)';
}
