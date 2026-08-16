import 'dart:ui' as ui;

import 'package:flutter/material.dart';

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
  });

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

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final r = BorderRadius.circular(radius ?? t.rCard);
    final fill = strong ? t.cardStrong : t.card;

    Widget content = padding == null
        ? child
        : Padding(padding: padding!, child: child);

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

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(color: fill, borderRadius: r),
      child: content,
    );

    if (t.blurSigma > 0) {
      surface = BackdropFilter(
        filter: ui.ImageFilter.compose(
          outer: ui.ColorFilter.matrix(_saturate(t.saturation)),
          inner: ui.ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
        ),
        child: surface,
      );
    }

    surface = ClipRRect(borderRadius: r, child: surface);

    if (shadow && t.cardShadow.isNotEmpty) {
      surface = DecoratedBox(
        decoration: BoxDecoration(borderRadius: r, boxShadow: t.cardShadow),
        child: surface,
      );
    }

    if (onTap != null || onLongPress != null) {
      // 명세 Interactions: iOS 는 밝기 +4%, Android 는 M3 리플.
      surface = t.isGlass
          ? TpPress(onTap: onTap, onLongPress: onLongPress, child: surface)
          : Material(
              color: Colors.transparent,
              borderRadius: r,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                onLongPress: onLongPress,
                borderRadius: r,
                child: surface,
              ),
            );
    }

    return surface;
  }
}

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
