import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

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
      if (Platform.isAndroid) {
        final info = await _plugin.androidInfo;
        return ThisDevice(name: info.model, brand: info.manufacturer);
      }
      if (Platform.isIOS) {
        final info = await _plugin.iosInfo;
        // iOS 는 utsname.machine 이 `iPhone16,2` 형태다. 사람이 읽는 이름은
        // name 쪽인데 사용자가 바꿀 수 있어 모델명 우선.
        return ThisDevice(name: info.utsname.machine, brand: 'Apple');
      }
    } catch (_) {
      // 플러그인이 없는 환경(테스트·데스크톱)에서는 그냥 없는 것으로 둔다.
    }
    return null;
  }
}
