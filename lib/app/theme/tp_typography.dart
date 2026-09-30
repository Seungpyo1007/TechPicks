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
      color: t.ink,
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
        letterSpacing: glass ? sfTracking(15) : null,
      ),
      cardTitle: base.copyWith(
        fontSize: 17,
        fontWeight: t.boldWeight,
        letterSpacing: glass ? sfTracking(17) : null,
      ),
      body: base.copyWith(
        fontSize: 15,
        height: 1.4,
        letterSpacing: glass ? sfTracking(15) : null,
      ),
      secondary: base.copyWith(
        fontSize: 13.5,
        color: t.dim,
        letterSpacing: glass ? sfTracking(13.5) : null,
      ),
      caption: base.copyWith(
        fontSize: 11.5,
        color: t.dim,
        letterSpacing: glass ? sfTracking(11.5) : null,
      ),
      tabLabel: base.copyWith(
        fontSize: 10,
        fontWeight: t.boldWeight,
        letterSpacing: glass ? sfTracking(10) : null,
      ),
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

  /// SF Pro 의 크기별 자간(pt). UIKit 은 시스템 글꼴에 이걸 알아서 주는데
  /// Flutter 는 안 준다. 그래서 본문이 네이티브보다 헐겁게 보였다.
  ///
  /// Apple 의 SF Pro 트래킹 표에서 우리가 쓰는 크기만 옮겼다. 사이 값은
  /// 가까운 두 점을 잇는다.
  static double sfTracking(double size) {
    const table = <(double, double)>[
      (10, 0.12),
      (11, 0.06),
      (12, 0),
      (13, -0.08),
      (15, -0.23),
      (17, -0.43),
      (20, -0.45),
    ];
    if (size <= table.first.$1) return table.first.$2;
    if (size >= table.last.$1) return table.last.$2;
    for (var i = 1; i < table.length; i++) {
      final (hiSize, hiTrack) = table[i];
      if (size <= hiSize) {
        final (loSize, loTrack) = table[i - 1];
        final f = (size - loSize) / (hiSize - loSize);
        return loTrack + (hiTrack - loTrack) * f;
      }
    }
    return 0;
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
