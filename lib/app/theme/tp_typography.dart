import 'package:flutter/material.dart';

import 'tp_tokens.dart';

/// 타입 스케일. `docs/DESIGN_HANDOFF.md` — Type scale 표를 그대로 옮겼다.
///
/// 두 플랫폼이 크기는 대부분 같고 굵기만 다르다. iOS 는 600/700 을 쓰고
/// M3 는 400/500 만 쓴다.
///
/// 명세의 `em` 단위 자간은 px 로 환산했다. 예를 들어 34px 에 `-0.032em` 은
/// `34 * -0.032 = -1.088`.
@immutable
class TpTypography extends ThemeExtension<TpTypography> {
  const TpTypography({
    required this.largeTitle,
    required this.largeAppBarTitle,
    required this.appBarTitle,
    required this.cardTitle,
    required this.body,
    required this.secondary,
    required this.caption,
    required this.tabLabel,
    required this.eyebrow,
    required this.indexNumeral,
  });

  /// 화면 h1. iOS 콘텐츠 안에 놓이고, Android 는 large app bar 가 대신한다.
  final TextStyle largeTitle;

  /// Android large app bar 제목.
  final TextStyle largeAppBarTitle;

  /// 축소된 app bar 제목. iOS 는 유리 알약 안.
  final TextStyle appBarTitle;

  final TextStyle cardTitle;
  final TextStyle body;
  final TextStyle secondary;
  final TextStyle caption;
  final TextStyle tabLabel;

  /// 섹션 머리말. 대문자 + 넓은 자간.
  final TextStyle eyebrow;

  /// TP Index 히어로 숫자.
  final TextStyle indexNumeral;

  factory TpTypography.of(TpTokens t) {
    final base = TextStyle(
      fontFamily: t.fontFamily,
      fontFamilyFallback: t.fontFamilyFallback,
      color: TpTokens.ink,
    );
    final glass = t.isGlass;

    return TpTypography(
      largeTitle: base.copyWith(
        fontSize: 34,
        height: 1.1,
        fontWeight: glass ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: 34 * -0.032,
      ),
      largeAppBarTitle: base.copyWith(
        fontSize: 28,
        height: 1.15,
        fontWeight: FontWeight.w400,
      ),
      appBarTitle: base.copyWith(
        fontSize: glass ? 15 : 20,
        height: glass ? null : 1.2,
        fontWeight: t.boldWeight,
      ),
      cardTitle: base.copyWith(fontSize: 17, fontWeight: t.boldWeight),
      body: base.copyWith(fontSize: 15, height: 1.4),
      secondary: base.copyWith(fontSize: 13.5, color: t.dim),
      caption: base.copyWith(fontSize: 11.5, color: t.dim),
      tabLabel: base.copyWith(fontSize: 10, fontWeight: t.boldWeight),
      eyebrow: base.copyWith(
        fontSize: 11,
        fontWeight: t.boldWeight,
        letterSpacing: 11 * 0.13,
        color: t.dim,
      ),
      indexNumeral: base.copyWith(
        fontSize: 62,
        fontWeight: glass ? FontWeight.w700 : FontWeight.w500,
        letterSpacing: 62 * -0.035,
        height: 1,
      ),
    );
  }

  @override
  TpTypography copyWith() => this;

  @override
  TpTypography lerp(ThemeExtension<TpTypography>? other, double t) {
    if (other is! TpTypography) return this;
    return t < 0.5 ? this : other;
  }
}

extension TpTypographyX on BuildContext {
  TpTypography get tpText => Theme.of(this).extension<TpTypography>()!;
}
