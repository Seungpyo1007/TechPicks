import '../../core/error_reporter.dart';
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
        //
        // 이 식별자는 카탈로그 이름과 안 맞는다. 맞추려면 식별자→제품명 표가
        // 있어야 하는데 어디에도 없다. ScanMatcher 는 낱말 단위로 세므로
        // 이걸로는 아무것도 안 걸리고, You 화면이 "카탈로그에 아직 없습니다"
        // 로 떨어진다 — 안드로이드의 `SM-S931B` 와 같은 처지다.
        return ThisDevice(name: info.utsname.machine, brand: 'Apple');
      }
    } catch (e, s) {
      // 플러그인이 없는 환경(테스트·데스크톱)에서는 그냥 없는 것으로 둔다.
      TpErrors.record(e, s, reason: 'deviceInfo.read');
    }
    return null;
  }
}
