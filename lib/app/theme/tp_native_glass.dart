import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

/// OS 가 직접 그리는 유리.
///
/// 여태 크롬은 **유리 흉내**였다. `BackdropFilter` 는 흐리고 채도를 올릴 뿐이고,
/// `liquid_glass_widgets` 는 셰이더로 굴절을 그린다 — 둘 다 우리가 그린 그림이다.
/// iOS 26 의 진짜 Liquid Glass 는 OS 안에 있고, 렌즈처럼 배경을 빨아들이고
/// 기울기와 주변 밝기에 반응하고 서로 붙었다 떨어진다. 그건 흉내로 안 된다.
///
/// [native_liquid_glass] 가 SwiftUI 의 `.glassEffect()` 를 플랫폼 뷰로 꽂아준다.
/// **크롬에만 쓴다** — 화면당 두 장이다. 카드에 쓰면 목록 하나에 플랫폼 뷰가
/// 수십 개 생긴다.
abstract final class TpNativeGlass {
  /// 테스트가 켜고 끌 수 있게 열어둔다.
  @visibleForTesting
  static bool? debugOverride;

  /// 이 기기에서 진짜 유리를 쓸 수 있는가.
  ///
  /// iOS 26 미만이면 플러그인이 아무것도 안 그린다(빈 상자를 돌려준다). 그래서
  /// 여기서 미리 갈라두고, 안 되면 예전 경로가 그대로 그린다.
  static bool get enabled {
    if (debugOverride != null) return debugOverride!;
    if (kIsWeb) return false;
    // 플랫폼 뷰는 테스트에 없다. 크롬이 통째로 빈 상자가 된다.
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return NativeLiquidGlassUtils.supportsLiquidGlass;
  }
}

/// 크롬 한 장을 진짜 유리 위에 얹는다.
///
/// 유리는 OS 가 그리고, 그 위의 글자·아이콘·파란 알약은 그대로 Flutter 가
/// 그린다. 명세가 못박은 치수(탭 62pt·반지름 999·좌우 12)는 우리 것으로 남는다 —
/// 패키지의 `LiquidGlassTabBar` 를 쓰면 애플 기본 탭 바 모양으로 덮인다.
class TpNativeGlassSurface extends StatelessWidget {
  const TpNativeGlassSurface({
    super.key,
    required this.child,
    required this.radius,
    this.capsule = false,
  });

  final Widget child;

  /// 모서리 반지름. [capsule] 이면 무시된다.
  final double radius;

  /// 알약인가. 탭 바와 헤더 알약이 그렇다.
  final bool capsule;

  @override
  Widget build(BuildContext context) => LiquidGlassContainer(
    config: LiquidGlassConfig(
      // regular 는 배경을 더 많이 빨아들이고, clear 는 더 투명하다. 크롬 뒤로
      // 목록이 지나가야 하므로 regular 다.
      effect: LiquidGlassEffect.regular,
      shape: capsule
          ? LiquidGlassEffectShape.capsule
          : LiquidGlassEffectShape.rect,
      cornerRadius: capsule ? null : radius,
      // 색을 안 얹는다. 유리는 색이 아니라 뒤에 있는 것으로 보인다.
      tint: null,
      // 누르면 OS 가 유리를 눌러 준다. 우리가 스케일을 흉내 내는 것보다
      // 훨씬 유리 같다 — 빛이 같이 움직인다.
      interactive: true,
    ),
    child: child,
  );
}
