import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/tp_glass.dart';

/// 유리 패키지가 앱 전체로 새지 않게 막는다.
///
/// `liquid_glass_widgets` 는 자기 iOS 26 모양을 가진 위젯을 60개쯤 들고 온다 —
/// `GlassScaffold`·`GlassTabBar`·`GlassButton`. 그걸 화면에서 쓰기 시작하면
/// 명세가 못박은 치수(탭 62pt·반지름 999·파란 알약)가 패키지 취향으로 덮이고,
/// 안드로이드 M3 크롬도 같이 끌려간다.
///
/// 그래서 **가져오는 것은 표면 하나**고, import 는 세 파일에만 있다.
void main() {
  const allowed = <String>{
    'lib/app/theme/tp_glass.dart',
    'lib/shared/widgets/tp_surface.dart',
  };

  test('유리 패키지는 정해진 파일에서만 부른다', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path;
      if (allowed.contains(path)) continue;
      if (entity.readAsStringSync().contains('liquid_glass_widgets')) {
        offenders.add(path);
      }
    }

    expect(offenders, isEmpty, reason: '유리는 TpSurface 한 겹으로만 쓴다');
  });

  test('테스트에서는 셰이더를 안 켠다', () {
    // 켜지면 유리가 매 프레임 다시 그려서 pumpAndSettle 이 안 끝난다.
    expect(TpGlassRuntime.enabled, isFalse);
  });
}
