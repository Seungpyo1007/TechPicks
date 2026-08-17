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
    this.tint,
    this.interactive = true,
  });

  final Widget child;

  /// 모서리 반지름. [capsule] 이면 무시된다.
  final double radius;

  /// 알약인가. 탭 바와 헤더 알약이 그렇다.
  final bool capsule;

  /// 유리에 섞을 색.
  ///
  /// **크롬 본체에는 안 쓴다** — 색을 얹는 순간 OS 유리가 그 아래로 사라진다.
  /// 고른 탭 알약처럼 색 자체가 뜻인 자리에만 준다.
  final Color? tint;

  /// 눌렸을 때 OS 가 유리를 눌러 줄지. 장식이면 끈다.
  final bool interactive;

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
      tint: tint,
      // 누르면 OS 가 유리를 눌러 준다. 우리가 스케일을 흉내 내는 것보다
      // 훨씬 유리 같다 — 빛이 같이 움직인다.
      interactive: interactive,
    ),
    child: child,
  );
}

/// 시스템 탭 바 한 칸.
class TpNativeTabItem {
  const TpNativeTabItem({
    required this.label,
    required this.symbol,
    required this.activeSymbol,
  });

  final String label;
  final String symbol;
  final String activeSymbol;
}

/// iOS 26 의 시스템 탭 바.
///
/// 유리를 우리 알약 뒤에 깔아주는 것과 **바가 통째로 시스템 것**인 것은 다르다.
/// 고른 칸의 방울이 바에 녹아들었다 떨어지는 그 움직임은 한 유리 컨테이너
/// 안에서만 나오고, 그건 `UITabBar` 안에 있다.
///
/// 명세의 치수는 여기서도 우리가 준다: 높이 62, 좌우 12(셸이 잡는다), 파란
/// 강조, 우리 라벨과 타이포. 아이콘만 SF Symbol 이다 — Material 아이콘을 PNG 로
/// 구워 넘기면 선 굵기도 선택 상태 전환도 OS 것이 아니게 된다.
///
/// **플러그인이 고르지도 않은 칸을 알려온다.** 바를 세울 때 다섯 칸 전부에
/// 대해 한꺼번에(같은 밀리초에 4·0·2·3·1) 알려오고, 탭을 바꾼 뒤에도 100ms 쯤
/// 뒤에 예전 칸을 한 번 더 알려온다. 그대로 받으면 홈을 눌렀는데 내 정보가
/// 켜진다. 그래서 **손가락이 바에 닿은 직후의 첫 통보만** 받는다.
class TpNativeTabBar extends StatefulWidget {
  const TpNativeTabBar({
    super.key,
    required this.items,
    required this.index,
    required this.onSelected,
    required this.height,
    required this.tint,
    required this.labelStyle,
  });

  final List<TpNativeTabItem> items;
  final int index;
  final ValueChanged<int>? onSelected;
  final double height;

  /// 고른 칸의 강조색.
  final Color tint;

  final TextStyle labelStyle;

  /// 플러그인이 유리를 흘려보내려고 상자를 `height + 20` 으로 잡는다. 위쪽
  /// 20pt 는 비고 바는 아래에 붙는다. 담는 쪽이 62 로 잘라두면 그만큼 넘쳐서
  /// 터치가 어긋난다.
  static const double overflow = 20;

  /// 손가락이 닿고 나서 이 시간 안에 온 통보만 사람이 고른 것으로 본다.
  static const Duration claimWindow = Duration(milliseconds: 600);

  @override
  State<TpNativeTabBar> createState() => _TpNativeTabBarState();
}

class _TpNativeTabBarState extends State<TpNativeTabBar> {
  /// 마지막으로 바를 누른 시각.
  DateTime? _touchedAt;

  /// 이번 터치의 통보를 이미 받았는가.
  bool _claimed = true;

  void _onTouch(PointerDownEvent _) {
    _touchedAt = DateTime.now();
    _claimed = false;
  }

  void _onNative(int index) {
    final at = _touchedAt;
    if (_claimed || at == null) return;
    if (DateTime.now().difference(at) > TpNativeTabBar.claimWindow) return;

    _claimed = true;
    widget.onSelected?.call(index);
  }

  @override
  Widget build(BuildContext context) => Listener(
    // 플랫폼 뷰가 터치를 그대로 받게 두고, 닿았다는 사실만 엿본다.
    behavior: HitTestBehavior.translucent,
    onPointerDown: _onTouch,
    child: LiquidGlassTabBar(
      currentIndex: widget.index,
      onTabSelected: _onNative,
      height: widget.height,
      selectedItemColor: widget.tint,
      // 칸이 다섯이라 꽉 채운다. 가운데 모으기는 두세 칸짜리 바의 모양이다.
      iosItemPositioning: LiquidGlassTabBarItemPositioning.fill,
      labelTextStyle: widget.labelStyle,
      items: <LiquidGlassTabItem>[
        for (final item in widget.items)
          LiquidGlassTabItem(
            label: item.label,
            icon: NativeLiquidGlassIcon.sfSymbol(item.symbol),
            selectedIcon: NativeLiquidGlassIcon.sfSymbol(item.activeSymbol),
          ),
      ],
    ),
  );
}
