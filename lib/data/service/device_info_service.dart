import '../../core/error_reporter.dart';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;

/// 지금 이 앱이 돌고 있는 기기.
class ThisDevice {
  const ThisDevice({required this.name, this.brand});

  /// 화면에 찍는 이름. `SM-S931B` 같은 모델 코드일 수도 있다.
  final String name;

  final String? brand;

  /// 카탈로그와 맞춰볼 때 쓰는 문자열.
  String get searchable =>
      brand == null || brand!.isEmpty ? name : '$brand $name';
}

/// v1 은 이걸 CPU 탭에 띄웠다. 제품 DB 가 있어야 할 자리에 내 기기 정보가
/// 있어서 기능명과 실제가 어긋났다. 명세가 "그건 You 화면에 속한다"고 짚었다.
abstract class DeviceInfoService {
  Future<ThisDevice?> read();
}

class PlatformDeviceInfoService implements DeviceInfoService {
  PlatformDeviceInfoService({DeviceInfoPlugin? plugin})
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  @override
  Future<ThisDevice?> read() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final info = await _plugin.androidInfo;
        return ThisDevice(name: info.model, brand: info.manufacturer);
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final info = await _plugin.iosInfo;
        // utsname.machine 은 `iPhone18,4` 같은 식별자라 사람이 못 읽고 카탈로그
        // 이름과도 안 맞았다. 플러그인이 주는 제품명(`iPhone Air`)을 먼저 쓴다.
        // `name` 은 사용자가 바꾼 기기 이름이라 쓰지 않는다.
        final model = info.modelName.trim();
        return ThisDevice(
          name: model.isNotEmpty ? model : info.utsname.machine,
          brand: 'Apple',
        );
      }
    } catch (e, s) {
      // 플러그인이 없는 환경(테스트·데스크톱)에서는 그냥 없는 것으로 둔다.
      TpErrors.record(e, s, reason: 'deviceInfo.read');
    }
    return null;
  }
}
