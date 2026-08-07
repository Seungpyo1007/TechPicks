import 'package:flutter/material.dart';

/// 확정 디자인의 토큰. 값의 출처는 `docs/DESIGN_HANDOFF.md` — Design Tokens.
///
/// 두 플랫폼이 같은 팔레트를 쓰지만 표현 방식이 다르다. iOS 는 반투명 유리에
/// 블러와 그림자를 얹고, Android M3 는 불투명한 톤 단계로만 층을 만든다.
/// 그래서 하나의 토큰 집합에 두 구현을 두고 플랫폼으로 고른다.
///
/// 색은 전부 앱 로고(`NBlogo_black.png`)에서 뽑았다. **빨강은 쓰지 않는다.**
@immutable
class TpTokens extends ThemeExtension<TpTokens> {
  const TpTokens({
    required this.isGlass,
    required this.fontFamily,
    required this.fontFamilyFallback,
    required this.boldWeight,
    required this.pageBackground,
    required this.card,
    required this.cardStrong,
    required this.blurSigma,
    required this.saturation,
    required this.cardShadow,
    required this.buttonShadow,
    required this.hasSpecular,
    required this.rCard,
    required this.rInner,
    required this.rIcon,
    required this.hairline,
    required this.track,
    required this.barFill,
    required this.tintFill,
    required this.chipBg,
    required this.inputBg,
    required this.inputShadow,
    required this.slotBg,
    required this.heroFill,
    required this.heroInk,
    required this.heroChip,
    required this.dim,
  });

  // ── 공용 팔레트 ───────────────────────────────────────────────
  /// 주 색. 로고에서 샘플링.
  ///
  /// 명세 값은 `#0C78D8` 인데 흰 글자를 얹으면 대비가 4.474 라 WCAG AA
  /// 본문 기준(4.5)에 0.03 모자란다. 버튼 라벨이 15px 이라 그 기준이 걸린다.
  /// 명도를 한 단계만 낮춘 `#0C77D7` 이면 4.53 이고, 채널당 1 차이라 눈으로는
  /// 구분되지 않는다.
  static const Color blue = Color(0xFF0C77D7);

  /// 그라디언트 끝, 눌린 상태.
  static const Color blueDark = Color(0xFF0B5490);

  /// 바·하이라이트의 그라디언트 시작.
  static const Color blueLight = Color(0xFF0090F0);

  /// 밝은 바탕 위의 파란 **글자**.
  ///
  /// [blue] 를 그대로 글자로 쓰면 대비가 3.72–4.25 라 WCAG AA 본문 기준에
  /// 못 미친다. 같은 팔레트의 [blueDark] 는 6.5 이상이라 그걸 쓴다.
  /// 채움(버튼·칩·막대)은 그대로 [blue] 다 — 그쪽은 흰 글자와의 대비가
  /// 문제이고 그건 통과한다.
  static const Color blueText = blueDark;

  /// 로고에서 같이 뽑은 중립 잉크.
  static const Color graphite = Color(0xFF484848);

  /// 본문 텍스트.
  static const Color ink = Color(0xFF14161A);

  /// 탭 바 배경. 두 플랫폼 공통값이지만 iOS 는 유리 캡슐을 대신 쓴다.
  static const Color tabBarFill = Color(0xFFE6EBF4);

  /// 유리(iOS)인가 톤(Android)인가. 블러·그림자·스페큘러를 켤지 결정한다.
  final bool isGlass;

  final String? fontFamily;
  final List<String> fontFamilyFallback;

  /// 강조 굵기. iOS 는 600, M3 는 500. **M3 에서 600~800 을 쓰지 않는다.**
  final FontWeight boldWeight;

  /// 화면 바탕. iOS 는 세로 그라디언트, Android 는 단색.
  final Decoration pageBackground;

  final Color card;
  final Color cardStrong;

  /// `BackdropFilter` 시그마. Android 는 0 이고 블러를 걸지 않는다.
  final double blurSigma;

  /// 블러와 함께 거는 채도. 1.0 이면 보정 없음.
  final double saturation;

  /// 카드 바깥 그림자. CSS 의 inset 하이라이트는 [hasSpecular] 로 따로 그린다.
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> buttonShadow;

  /// 카드 위쪽 모서리의 1px 반사광. iOS 만 그린다.
  final bool hasSpecular;

  // ── 반지름 ───────────────────────────────────────────────────
  /// 동심 규칙: 28 카드 안은 22, 그 안은 16. 같거나 더 크면 안 된다.
  final double rCard;
  final double rInner;
  final double rIcon;

  /// 알약형 컨트롤. 두 플랫폼 공통.
  static const double rControl = 999;

  final Color hairline;
  final Color track;

  /// 점수 막대 채움. iOS 는 가로 그라디언트, Android 는 단색.
  final Gradient barFill;

  final Color tintFill;
  final Color chipBg;
  final Color inputBg;
  final List<BoxShadow> inputShadow;

  /// 상세 화면의 제품 사진 자리.
  final Color slotBg;

  final Decoration heroFill;
  final Color heroInk;
  final Color heroChip;

  /// 흐린 보조 텍스트.
  final Color dim;

  /// iOS 26 Liquid Glass.
  factory TpTokens.ios() => const TpTokens(
        isGlass: true,
        // 시스템 폰트를 그대로 쓴다. null 이면 Flutter 가 SF Pro 로 붙는다.
        fontFamily: null,
        fontFamilyFallback: <String>[],
        boldWeight: FontWeight.w600,
        pageBackground: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFEEF3FA),
              Color(0xFFE4ECF6),
              Color(0xFFEAF1F9),
              Color(0xFFF1F5FB),
            ],
            stops: <double>[0, .42, .78, 1],
          ),
        ),
        card: Color(0x94FFFFFF), // rgba(255,255,255,.58)
        cardStrong: Color(0xB8FFFFFF), // rgba(255,255,255,.72)
        blurSigma: 26,
        saturation: 1.8,
        cardShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x0F122644), // rgba(18,38,68,.06)
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x14122644), // rgba(18,38,68,.08)
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
        buttonShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x520C78D8), // rgba(12,120,216,.32)
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
        hasSpecular: true,
        rCard: 28,
        rInner: 22,
        rIcon: 26,
        hairline: Color(0x14142846), // rgba(20,40,70,.08)
        track: Color(0x17142846), // rgba(20,40,70,.09)
        barFill: LinearGradient(colors: <Color>[blue, blueLight]),
        tintFill: Color(0x1F0C78D8), // rgba(12,120,216,.12)
        chipBg: Color(0xB3FFFFFF), // rgba(255,255,255,.7)
        inputBg: Color(0xB8FFFFFF), // rgba(255,255,255,.72)
        inputShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x24122644), // rgba(18,38,68,.14)
            blurRadius: 26,
            offset: Offset(0, 8),
          ),
        ],
        slotBg: Color(0x73FFFFFF), // rgba(255,255,255,.45)
        heroFill: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[blue, blueDark],
          ),
        ),
        heroInk: Color(0xFFFFFFFF),
        heroChip: Color(0x38FFFFFF), // rgba(255,255,255,.22)
        dim: dimInk, // 명세는 .55 인데 대비가 모자란다 — dimInk 주석 참고
      );

  /// Android Material 3. 반투명이 아니라 톤 단계로 층을 만든다.
  factory TpTokens.android() => const TpTokens(
        isGlass: false,
        fontFamily: 'Roboto Flex',
        fontFamilyFallback: <String>['Roboto'],
        boldWeight: FontWeight.w500,
        pageBackground: BoxDecoration(color: Color(0xFFF6F8FC)),
        card: Color(0xFFEDF1F7),
        cardStrong: Color(0xFFE6EDF6),
        blurSigma: 0,
        saturation: 1,
        cardShadow: <BoxShadow>[],
        buttonShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x2E000000), // rgba(0,0,0,.18)
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
        hasSpecular: false,
        rCard: 20,
        rInner: 16,
        rIcon: 24,
        hairline: Color(0x12142846), // rgba(20,40,70,.07)
        track: Color(0xFFD6E2F2),
        barFill: LinearGradient(colors: <Color>[blue, blue]),
        tintFill: Color(0xFFD6E5F9),
        chipBg: Color(0xFFE3EBF6),
        inputBg: Color(0xFFE6EDF6),
        inputShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x1A000000), // rgba(0,0,0,.10)
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
        slotBg: Color(0xFFE1E8F2),
        heroFill: BoxDecoration(color: Color(0xFFD6E5F9)),
        heroInk: Color(0xFF0A2F52),
        heroChip: Color(0x290C78D8), // rgba(12,120,216,.16)
        dim: dimInk,
      );

  /// 흐린 보조 텍스트.
  ///
  /// **명세와 다른 유일한 색이다.** 명세는 iOS `rgba(20,30,45,.55)`,
  /// Android `.58` 인데 두 값 모두 WCAG AA 본문 기준(4.5:1)에 못 미친다.
  /// 실측하면 배경에 따라 3.61–3.76 이고, 이 색을 쓰는 글자는 대부분
  /// 10–13.5px 라 4.5 가 적용된다.
  ///
  /// 알파를 .63 으로 올리면 가장 어두운 배경(#E4ECF6)에서도 4.58 이 된다.
  /// 그 이상 올릴 이유가 없어 기준을 막 넘기는 값으로 뒀다.
  ///
  /// 디자인 쪽에서 다른 값을 확정하면 여기만 바꾸면 된다.
  static const Color dimInk = Color(0xA1141E2D); // rgba(20,30,45,.63)

  /// Android 전용 확장 톤. 컨테이너보다 한 단계 높은 면.
  static const Color androidBarBg = Color(0xFFF6F8FC);

  /// FAB 그림자. Android 만 쓴다.
  static const List<BoxShadow> fabShadow = <BoxShadow>[
    BoxShadow(
      color: Color(0x29000000), // rgba(0,0,0,.16)
      blurRadius: 6,
      offset: Offset(0, 3),
    ),
    BoxShadow(
      color: Color(0x570C78D8), // rgba(12,120,216,.34)
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// 카드 위쪽 모서리를 따라 흐르는 1px 반사광.
  static const LinearGradient specular = LinearGradient(
    colors: <Color>[
      Color(0x00FFFFFF),
      Color(0xF2FFFFFF), // rgba(255,255,255,.95)
      Color(0x00FFFFFF),
    ],
  );

  @override
  TpTokens copyWith({bool? isGlass}) =>
      isGlass == null || isGlass == this.isGlass
          ? this
          : (isGlass ? TpTokens.ios() : TpTokens.android());

  /// 두 크롬 사이를 애니메이션할 일이 없다. 중간값 대신 한쪽을 고른다.
  @override
  TpTokens lerp(ThemeExtension<TpTokens>? other, double t) {
    if (other is! TpTokens) return this;
    return t < 0.5 ? this : other;
  }
}

/// [TpTokens] 를 짧게 꺼내 쓰기 위한 확장.
extension TpTokensX on BuildContext {
  TpTokens get tp => Theme.of(this).extension<TpTokens>()!;
}
