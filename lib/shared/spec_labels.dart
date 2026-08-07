import '../domain/model/device_specs.dart';
import '../domain/model/tp_index.dart';

/// 화면에 찍는 이름.
///
/// 상세와 비교가 같은 표를 쓰므로 한 곳에 둔다. 번역 파일로 옮길 때도 여기만
/// 갈아끼우면 된다.
abstract final class SpecLabels {
  static const Map<SpecKind, String> spec = <SpecKind, String>{
    SpecKind.tpIndex: 'TP Index',
    SpecKind.price: 'Price',
    SpecKind.screen: 'Screen',
    SpecKind.chipset: 'Chipset',
    SpecKind.camera: 'Camera',
    SpecKind.battery: 'Battery',
    SpecKind.os: 'OS',
    SpecKind.weight: 'Weight',
    SpecKind.thickness: 'Thickness',
    SpecKind.released: 'Released',
  };

  static const Map<TpAxisKind, String> axis = <TpAxisKind, String>{
    TpAxisKind.performance: 'Performance',
    TpAxisKind.camera: 'Camera',
    TpAxisKind.display: 'Display',
    TpAxisKind.battery: 'Battery',
    TpAxisKind.value: 'Value',
  };

  static String of(SpecKind kind) => spec[kind] ?? kind.key;
}
