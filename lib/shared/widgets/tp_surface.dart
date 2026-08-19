import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../app/theme/tp_glass.dart';
import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_tokens.dart';
import 'tp_press.dart';

/// 카드·시트·크롬이 공통으로 쓰는 면.
///
/// iOS 는 뒤를 블러하고 채도를 올린 반투명 유리, Android 는 불투명한 톤 단계다.
/// 두 경우를 한 위젯에서 처리해 화면 코드가 플랫폼 분기를 갖지 않게 한다.
///
/// CSS 의 `inset 0 1px 0` 하이라이트는 Flutter [BoxShadow] 로 표현할 수 없어
/// 위쪽 모서리에 1px 그라디언트를 얹는 방식으로 대신한다.
class TpSurface extends StatelessWidget {
  const TpSurface({
    super.key,
    required this.child,
    this.strong = false,
    this.radius,
    this.padding,
    this.shadow = true,
    this.onTap,
    this.onLongPress,
    this.chrome = false,
    this.raised = false,
    this.opaque = false,
    this.semanticsLabel,
  });

  /// 크롬 등급 유리. 카드보다 더 흐리고 더 진하다.
  ///
  /// 명세가 카드와 크롬에 다른 값을 주는데 여태 카드 값 하나로 다 그렸다.
  /// 그래서 탭 바가 유리가 아니라 밝은 알약으로 보였다.
  const TpSurface.chrome({
    super.key,
    required this.child,
    this.radius,
    this.padding,
    this.shadow = true,
    this.onTap,
    this.onLongPress,
    this.raised = false,
  }) : strong = true,
       chrome = true,
       opaque = false,
       semanticsLabel = null;

  final Widget child;

  /// 더 불투명한 면. 홈의 결론 카드처럼 강조가 필요한 곳에 쓴다.
  final bool strong;

  /// 기본값은 토큰의 카드 반지름. 안쪽 요소는 [TpTokens.rInner] 를 넘길 것.
  final double? radius;

  final EdgeInsetsGeometry? padding;
  final bool shadow;
  final VoidCallback? onTap;

  /// 길게 눌러 지우는 행에 쓴다. 명세 §3 의 shortlist 행이 그렇다.
  final VoidCallback? onLongPress;

  /// 크롬 등급으로 그릴지. [TpSurface.chrome] 이 켠다.
  final bool chrome;

  /// 탭 캡슐. 컨트롤보다 진하고 그림자가 깊다.
  final bool raised;

  /// 누를 수 있는 면이 스크린 리더에 알릴 이름. [onTap] 이 있을 때만 쓴다.
  final String? semanticsLabel;

  /// 뒤가 비치지 않는 면.
  ///
  /// 유리는 **자기 레이어에서** 그려진다(`useOwnLayer`). 그 레이어 뒤에 아무
  /// 것도 없는 자리 — 라우트 위에 뜨는 시트가 그렇다 — 에서는 흐릴 대상이
  /// 없어서 흐림이 안 걸리고, 72% 흰 면 아래로 아래 화면 글자가 그대로
  /// 읽힌다. 브랜드 시트는 목록 열두 줄이 랭킹 오십 줄 위에 겹쳤다.
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final r = BorderRadius.circular(radius ?? t.rCard);

    // "투명도 줄이기"를 켠 사람에게는 유리를 걷는다. Flutter 에 그 플래그가
    // 없어서 같은 설정 화면에 있는 고대비를 대신 본다.
    final flatten = opaque || MediaQuery.highContrastOf(context);

    final rawFill = chrome
        ? (raised ? t.chromeFillRaised : t.chromeFill)
        : (strong ? t.cardStrong : t.card);
    final fill = flatten ? _opaque(rawFill) : rawFill;
    final sigma = flatten ? 0.0 : (chrome ? t.chromeBlurSigma : t.blurSigma);
    final saturation = chrome ? t.chromeSaturation : t.saturation;
    final shadows = chrome
        ? (raised ? t.chromeShadowRaised : t.chromeShadow)
        : t.cardShadow;

    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

    // OS 가 직접 그리는 유리. 크롬에만 쓴다 — 화면당 두 장이고, 카드에 쓰면
    // 목록 하나에 플랫폼 뷰가 수십 개 생긴다.
    //
    // **우리 것을 하나도 얹지 않는다.** 스페큘러 1px 선도, 채움색도, 그림자도
    // 빼야 OS 유리가 자기 모습대로 보인다. 처음에는 토큰 채움색을 35% 로
    // 얹었는데, 그 얇은 막 하나가 유리를 도로 흉내로 만들었다 — 진짜 유리는
    // 색이 아니라 뒤에 있는 것으로 보인다.
    if (chrome && sigma > 0 && TpNativeGlass.enabled) {
      Widget glass = TpNativeGlassSurface(
        radius: radius ?? t.rCard,
        // 명세의 컨트롤 반지름은 999 다. 알약으로 넘기면 OS 가 높이에 맞춰
        // 깎는다 — 우리가 숫자로 흉내 내는 것보다 정확하다.
        capsule: (radius ?? t.rCard) >= TpTokens.rControl,
        child: content,
      );
      if (onTap != null || onLongPress != null) {
        glass = TpPress(
          onTap: onTap,
          onLongPress: onLongPress,
          semanticsLabel: semanticsLabel,
          child: glass,
        );
      }
      return glass;
    }

    if (t.hasSpecular) {
      content = Stack(
        children: <Widget>[
          content,
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: TpTokens.specular),
            ),
          ),
        ],
      );
    }

    // 셰이더 유리. 굴절과 엣지 조명은 BackdropFilter 로 안 되는 것들이다.
    if (sigma > 0 && TpGlassRuntime.enabled) {
      Widget glass = GlassContainer(
        shape: LiquidRoundedSuperellipse(borderRadius: radius ?? t.rCard),
        quality: TpGlassSpec.quality(chrome: chrome),
        // 우리 면은 각자 따로 서 있다. 층을 안 주면 premium 이 렌더 링크를
        // 못 찾아 죽고, 설정도 무시된다.
        useOwnLayer: true,
        settings: TpGlassSpec.of(
          fill: fill,
          blur: sigma,
          saturation: saturation,
          shadow: shadow ? shadows : const <BoxShadow>[],
          chrome: chrome,
        ),
        child: content,
      );
      if (onTap != null || onLongPress != null) {
        glass = TpPress(onTap: onTap, onLongPress: onLongPress, child: glass);
      }
      return glass;
    }

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: r),
      child: content,
    );

    if (sigma > 0) {
      surface = BackdropFilter(
        filter: ui.ImageFilter.compose(
          outer: ui.ColorFilter.matrix(_saturate(saturation)),
          inner: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        ),
        child: surface,
      );
    }

    surface = ClipRRect(borderRadius: r, child: surface);

    if (shadow && shadows.isNotEmpty) {
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: r, boxShadow: shadows),
        child: surface,
      );
    }

    if (onTap != null || onLongPress != null) {
      // 명세 Interactions: iOS 는 밝기 +4%, Android 는 M3 리플.
      surface = t.isGlass
          ? TpPress(
              onTap: onTap,
              onLongPress: onLongPress,
              semanticsLabel: semanticsLabel,
              child: surface,
            )
          : Semantics(
              button: true,
              label: semanticsLabel,
              child: Material(
                color: Colors.transparent,
                borderRadius: r,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  borderRadius: r,
                  child: surface,
                ),
              ),
            );
    }

    return surface;
  }
}

/// 뒤가 안 비치게 만든다. 앱 배경 위에 얹은 것과 같은 색이 되도록
/// 흰 종이에 한 번 섞는다.
Color _opaque(Color c) =>
    Color.alphaBlend(c, const Color(0xFFFFFFFF)).withValues(alpha: 1);

List<double> _saturate(double amount) {
  // ITU-R BT.601 휘도 계수. CSS filter 명세가 쓰는 값과 같다.
  const double lr = 0.213, lg = 0.715, lb = 0.072;
  final double sr = (1 - amount) * lr;
  final double sg = (1 - amount) * lg;
  final double sb = (1 - amount) * lb;
  return <double>[
    sr + amount, sg, sb, 0, 0, //
    sr, sg + amount, sb, 0, 0, //
    sr, sg, sb + amount, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}
