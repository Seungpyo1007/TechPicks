import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/tp_glass.dart';
import 'package:techpicks/app/theme/tp_native_glass.dart';

/// 유리 패키지가 앱 전체로 새지 않게 막는다.
///
/// 둘 다 위젯을 잔뜩 들고 온다. `liquid_glass_widgets` 는 `GlassScaffold`·
/// `GlassTabBar` 를, `native_liquid_glass` 는 `LiquidGlassTabBar`(애플 기본
/// 탭 바 그대로)를 준다. 그걸 화면에서 쓰기 시작하면 명세가 못박은 치수
/// (탭 62pt·반지름 999·파란 알약)가 패키지 취향으로 덮이고, 안드로이드 M3
/// 크롬도 같이 끌려간다.
///
/// 그래서 **가져오는 것은 표면뿐**이고, import 는 정해진 파일에만 있다.
void main() {
  /// 패키지 [package] 를 import 해도 되는 파일들.
  void expectImportsOnlyIn(String package, Set<String> allowed) {
    final needle = "import 'package:$package/";
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final normalizedPath = entity.path.replaceAll(r'\', '/');
      if (allowed.contains(normalizedPath)) continue;
      // 글로 언급하는 것은 괜찮다. import 만 센다.
      if (entity.readAsStringSync().contains(needle)) {
        offenders.add(normalizedPath);
      }
    }

    expect(offenders, isEmpty, reason: '$package 는 정해진 파일에서만 부른다');
  }

  test('셰이더 유리는 정해진 파일에서만 부른다', () {
    expectImportsOnlyIn('liquid_glass_widgets', <String>{
      'lib/app/theme/tp_glass.dart',
      'lib/shared/widgets/tp_surface.dart',
    });
  });

  test('OS 유리는 정해진 파일에서만 부른다', () {
    expectImportsOnlyIn('native_liquid_glass', <String>{
      'lib/app/theme/tp_native_glass.dart',
    });
  });

  test('테스트에서는 유리를 안 켠다', () {
    // 셰이더는 매 프레임 다시 그려서 pumpAndSettle 이 안 끝나고, 플랫폼 뷰는
    // 테스트에 아예 없어서 크롬이 통째로 빈 상자가 된다.
    expect(TpGlassRuntime.enabled, isFalse);
    expect(TpNativeGlass.enabled, isFalse);
  });
}
