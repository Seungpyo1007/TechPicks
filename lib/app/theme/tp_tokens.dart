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
    required this.isDark,
    required this.ink,
    required this.link,
    required this.mutedInk,
    required this.tabBar,
    required this.scrim,
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
    required this.chromeFill,
    required this.chromeFillRaised,
    required this.chromeBlurSigma,
    required this.chromeSaturation,
    required this.chromeShadow,
    required this.chromeShadowRaised,
    required this.chromeEdge,
    required this.chromeDim,
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

  /// 밝은 테마의 본문 텍스트.
  static const Color inkLight = Color(0xFF14161A);

  /// 탭 바 배경. 두 플랫폼 공통값이지만 iOS 는 유리 캡슐을 대신 쓴다.
  static const Color tabBarFill = Color(0xFFE6EBF4);

  /// 유리(iOS)인가 톤(Android)인가. 블러·그림자·스페큘러를 켤지 결정한다.
  final bool isGlass;

  // ── 어두운 테마 ──────────────────────────────────────────────
  // 명세에 다크 토큰 표가 없다. **색을 지어내지 않고 규칙으로 뒤집었다:**
  // 배경은 같은 남색 계열(#141E2D)의 가장 어두운 쪽으로 내리고, 유리는
  // 흰색을 낮은 알파로 얹고, 잉크는 거의 흰색으로 올린다. 파란 **글자**만
  // 예외다 — 밝은 바탕에서는 [blueDark] 가 대비를 벌었지만 어두운 바탕에서는
  // 반대라 [blueLight] 쪽으로 옮긴다. 채움(버튼·막대)은 양쪽 다 [blue] 다.

  /// 어두운 테마인가. 상태 표시줄 밝기와 그림자 세기를 여기로 고른다.
  final bool isDark;

  /// 본문 텍스트. 밝을 때 `#14161A`, 어두울 때 거의 흰색.
  final Color ink;

  /// 파란 글자. 밝은 바탕에서는 [blueDark], 어두운 바탕에서는 밝은 파랑.
  final Color link;

  /// 중립 보조 잉크. 랭킹 순위 숫자처럼 잉크보다 한 단계 흐린 글자.
  final Color mutedInk;

  /// Android 탭 바 채움. iOS 는 유리 캡슐이라 안 쓴다.
  final Color tabBar;

  /// 헤더 아래 106px 그라디언트. 배경의 맨 위 색과 같아야 이어져 보인다.
  final Color scrim;

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

  // ── 크롬 유리 ────────────────────────────────────────────────
  // 명세는 크롬을 카드보다 **더 흐리고 더 진하게** 잡는다. 여태 카드 값을
  // 그대로 써서 탭 바가 그냥 밝은 알약으로 보였다. 값의 출처는 프로토타입
  // (`docs/design/index.html:553·567`) 이다 — 핸드오프 표에는 컨트롤 한 줄뿐이라
  // 캡슐의 더 깊은 그림자가 빠져 있다.

  /// 헤더 알약 채움. `rgba(250,251,253,.62)`.
  final Color chromeFill;

  /// 탭 캡슐 채움. 컨트롤보다 조금 진하다. `rgba(250,251,253,.66)`.
  final Color chromeFillRaised;

  /// 크롬 블러. Android 는 0.
  final double chromeBlurSigma;

  /// 크롬 채도.
  final double chromeSaturation;

  final List<BoxShadow> chromeShadow;
  final List<BoxShadow> chromeShadowRaised;

  /// 크롬 아래 모서리의 0.5px 그림자 선. `inset 0 -0.5px 0 rgba(20,40,70,.06)`.
  final Color? chromeEdge;

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

  /// 크롬 위의 흐린 글자 — 안 고른 탭 라벨·아이콘.
  ///
  /// 크롬이 카드보다 투명해지면서 뒤 배경이 비쳐 [dim] 으로는 대비가 4.44 로
  /// 떨어졌다(기준 4.5). 유리 위에서만 조금 더 진하게 쓴다.
  final Color chromeDim;

  /// iOS 26 Liquid Glass.
  factory TpTokens.ios() => const TpTokens(
    isGlass: true,
    isDark: false,
    ink: inkLight,
    link: blueText,
    mutedInk: graphite,
    tabBar: tabBarFill,
    scrim: Color(0xFFEEF3FA),
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
    chromeFill: Color(0x9EFAFBFD), // rgba(250,251,253,.62)
    chromeFillRaised: Color(0xA8FAFBFD), // rgba(250,251,253,.66)
    chromeBlurSigma: 34,
    chromeSaturation: 2,
    chromeShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x260F2341), // rgba(15,35,65,.15)
        blurRadius: 22,
        offset: Offset(0, 6),
      ),
    ],
    chromeShadowRaised: <BoxShadow>[
      BoxShadow(
        color: Color(0x290F2341), // rgba(15,35,65,.16)
        blurRadius: 32,
        offset: Offset(0, 10),
      ),
    ],
    chromeEdge: Color(0x0F142846), // rgba(20,40,70,.06)
    chromeDim: Color(0xAD141E2D), // rgba(20,30,45,.68) — 대비 5.1
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

  /// 어두운 iOS. 같은 유리를 밤에 놓은 것이다.
  factory TpTokens.iosDark() => const TpTokens(
    isGlass: true,
    isDark: true,
    ink: Color(0xFFF2F5F9),
    link: Color(0xFF5FB4F7),
    mutedInk: Color(0xFFB9C2CE),
    tabBar: Color(0xFF171E28),
    scrim: Color(0xFF121A24),
    fontFamily: null,
    fontFamilyFallback: <String>[],
    boldWeight: FontWeight.w600,
    pageBackground: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color(0xFF121A24),
          Color(0xFF0D141D),
          Color(0xFF101823),
          Color(0xFF141C27),
        ],
        stops: <double>[0, .42, .78, 1],
      ),
    ),
    // 어두운 유리는 흰색을 낮은 알파로 얹는다. 밝을 때처럼 .58 을 쓰면
    // 카드가 배경보다 밝아져 종이처럼 보인다.
    card: Color(0x1AFFFFFF), // white .10
    cardStrong: Color(0x26FFFFFF), // white .15
    blurSigma: 26,
    saturation: 1.8,
    cardShadow: <BoxShadow>[
      // 어두운 바탕에서는 그림자가 거의 안 보인다. 더 진하게 준다.
      BoxShadow(color: Color(0x3D000000), blurRadius: 28, offset: Offset(0, 10)),
    ],
    buttonShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x520C78D8),
        blurRadius: 18,
        offset: Offset(0, 6),
      ),
    ],
    hasSpecular: true,
    chromeFill: Color(0x9E141A24), // rgba(20,26,36,.62)
    chromeFillRaised: Color(0xA8141A24), // rgba(20,26,36,.66)
    chromeBlurSigma: 34,
    chromeSaturation: 2,
    chromeShadow: <BoxShadow>[
      BoxShadow(color: Color(0x59000000), blurRadius: 22, offset: Offset(0, 6)),
    ],
    chromeShadowRaised: <BoxShadow>[
      BoxShadow(color: Color(0x66000000), blurRadius: 32, offset: Offset(0, 10)),
    ],
    chromeEdge: Color(0x14000000),
    chromeDim: Color(0xC7FFFFFF), // white .78
    rCard: 28,
    rInner: 22,
    rIcon: 26,
    hairline: Color(0x1AFFFFFF), // white .10
    track: Color(0x24FFFFFF), // white .14
    barFill: LinearGradient(colors: <Color>[blue, blueLight]),
    tintFill: Color(0x380090F0), // rgba(0,144,240,.22)
    chipBg: Color(0x1FFFFFFF), // white .12
    inputBg: Color(0x1AFFFFFF), // white .10
    inputShadow: <BoxShadow>[
      BoxShadow(color: Color(0x40000000), blurRadius: 26, offset: Offset(0, 8)),
    ],
    slotBg: Color(0x0FFFFFFF), // white .06
    heroFill: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: <Color>[blueDark, Color(0xFF06243E)],
      ),
    ),
    heroInk: Color(0xFFFFFFFF),
    heroChip: Color(0x2EFFFFFF), // white .18
    dim: dimInkDark,
  );

  /// Android Material 3. 반투명이 아니라 톤 단계로 층을 만든다.
  factory TpTokens.android() => const TpTokens(
    isGlass: false,
    isDark: false,
    ink: inkLight,
    link: blueText,
    mutedInk: graphite,
    tabBar: tabBarFill,
    scrim: Color(0xFFF6F8FC),
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
    // 톤 단계로 층을 만든다. 유리가 아니라 블러도 그림자도 없다.
    chromeFill: Color(0xFFF6F8FC),
    chromeFillRaised: tabBarFill,
    chromeBlurSigma: 0,
    chromeSaturation: 1,
    chromeShadow: <BoxShadow>[],
    chromeShadowRaised: <BoxShadow>[],
    chromeEdge: null,
    chromeDim: dimInk,
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

  /// 어두운 Android. M3 는 밤에도 톤 단계다 — 여전히 불투명이고 블러가 없다.
  factory TpTokens.androidDark() => const TpTokens(
    isGlass: false,
    isDark: true,
    ink: Color(0xFFE7ECF2),
    link: Color(0xFF7FC0F8),
    mutedInk: Color(0xFFAAB4C0),
    tabBar: Color(0xFF171C22),
    scrim: Color(0xFF101418),
    fontFamily: 'Roboto Flex',
    fontFamilyFallback: <String>['Roboto'],
    boldWeight: FontWeight.w500,
    pageBackground: BoxDecoration(color: Color(0xFF101418)),
    card: Color(0xFF191E24),
    cardStrong: Color(0xFF212831),
    blurSigma: 0,
    saturation: 1,
    cardShadow: <BoxShadow>[],
    buttonShadow: <BoxShadow>[
      BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(0, 1)),
    ],
    hasSpecular: false,
    chromeFill: Color(0xFF101418),
    chromeFillRaised: Color(0xFF171C22),
    chromeBlurSigma: 0,
    chromeSaturation: 1,
    chromeShadow: <BoxShadow>[],
    chromeShadowRaised: <BoxShadow>[],
    chromeEdge: null,
    chromeDim: dimInkDark,
    rCard: 20,
    rInner: 16,
    rIcon: 24,
    hairline: Color(0x17FFFFFF), // white .09
    track: Color(0xFF2A323C),
    barFill: LinearGradient(colors: <Color>[blueLight, blueLight]),
    tintFill: Color(0xFF123A5E),
    chipBg: Color(0xFF1E262F),
    inputBg: Color(0xFF212932),
    inputShadow: <BoxShadow>[
      BoxShadow(color: Color(0x40000000), blurRadius: 6, offset: Offset(0, 2)),
    ],
    slotBg: Color(0xFF1A212A),
    heroFill: BoxDecoration(color: Color(0xFF12324F)),
    heroInk: Color(0xFFDCE9F7),
    heroChip: Color(0x3D0090F0),
    dim: dimInkDark,
  );

  /// 어두운 바탕의 흐린 보조 텍스트.
  ///
  /// 밝은 쪽과 같은 규칙이다 — 기준(4.5:1)을 막 넘기는 값. 가장 밝은
  /// 배경(#212831)에서도 흰색 .70 이면 6.4 다.
  static const Color dimInkDark = Color(0xB3FFFFFF); // white .70

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

  /// 네 벌 중 하나를 고른다.
  static TpTokens pick({required bool glass, required bool dark}) => glass
      ? (dark ? TpTokens.iosDark() : TpTokens.ios())
      : (dark ? TpTokens.androidDark() : TpTokens.android());

  @override
  TpTokens copyWith({bool? isGlass, bool? isDark}) {
    final glass = isGlass ?? this.isGlass;
    final dark = isDark ?? this.isDark;
    if (glass == this.isGlass && dark == this.isDark) return this;
    return TpTokens.pick(glass: glass, dark: dark);
  }

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
