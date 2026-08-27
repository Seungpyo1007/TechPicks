import 'package:easy_localization/easy_localization.dart';

import '../domain/model/device_specs.dart';
import '../domain/model/tp_index.dart';
import 'copy_keys.dart';

/// 화면에 찍는 이름. 상세와 비교가 같은 표를 쓴다.
abstract final class SpecLabels {
  static String of(SpecKind kind) => K.spec(kind).tr();

  static String axis(TpAxisKind kind) => K.axis(kind).tr();
}
