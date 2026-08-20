import 'package:animations/animations.dart'
    show SharedAxisPageTransitionsBuilder, SharedAxisTransitionType;
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tp_motion.dart';
import 'tp_tokens.dart';
import 'tp_typography.dart';

/// 어느 크롬으로 그릴지. 실제 앱은 OS 로 정하지만, 프로토타입처럼 강제로
/// 바꿔볼 수 있어야 디자인 대조가 된다.
enum TpChrome {
  ios,
  android;

  /// 현재 플랫폼에 맞는 크롬.
  ///
  /// **웹은 언제나 M3 다.** 여기 주석에 오래 "데스크톱·웹은 Android 쪽으로
  /// 떨어뜨린다"고 적혀 있었는데 사실이 아니었다 — 웹에서
  /// [defaultTargetPlatform] 은 브라우저 UA 에서 나오므로 맥에서 연 브라우저는
  /// `macOS` 로 보고되고, 그러면 데스크톱 창에 **폰용 유리 크롬**이 깔렸다.
  /// 같은 주소인데 윈도우에서 열면 다른 앱이 나왔다.
  ///
  /// 유리는 웹에서 어차피 꺼진다([TpGlassRuntime]·[TpNativeGlass]). 그 상태로
  /// iOS 토큰을 쓰면 면마다 `BackdropFilter` 만 남는데, 그건 웹에서 가장 비싼
  /// 원시 연산이다. M3 토큰은 `blurSigma: 0` 이라 그것도 같이 사라진다.
  static TpChrome forPlatform([TargetPlatform? platform, bool web = kIsWeb]) {
    if (web) return TpChrome.android;
    final p = platform ?? defaultTargetPlatform;
    return p == TargetPlatform.iOS || p == TargetPlatform.macOS
        ? TpChrome.ios
        : TpChrome.android;
  }
}

/// 크롬별 [ThemeData].
///
/// 색과 타이포는 [TpTokens]·[TpTypography] 확장에 들어 있고, 여기서는
/// Material 위젯이 기본으로 집어가는 값만 맞춘다.
abstract final class AppTheme {
  static ThemeData of(TpChrome chrome, {bool dark = false}) {
    final glass = chrome == TpChrome.ios;
    final tokens = TpTokens.pick(glass: glass, dark: dark);
    final type = TpTypography.of(tokens);
    final motion = glass ? TpMotion.ios() : TpMotion.android();

    final scheme =
        ColorScheme.fromSeed(
          seedColor: TpTokens.blue,
          brightness: dark ? Brightness.dark : Brightness.light,
        ).copyWith(
          primary: TpTokens.blue,
          onPrimary: Colors.white,
          // 화면 바탕은 TpShell 이 토큰으로 칠한다. 여기 값은 Material 위젯이
          // 자기 기본색을 고를 때만 쓰인다.
          surface: dark
              ? (glass ? const Color(0xFF0D141D) : const Color(0xFF101418))
              : (glass ? const Color(0xFFEEF3FA) : const Color(0xFFF6F8FC)),
          onSurface: tokens.ink,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: tokens.fontFamily,
      fontFamilyFallback: tokens.fontFamilyFallback,
      splashFactory: chrome == TpChrome.ios
          ? NoSplash.splashFactory
          : InkRipple.splashFactory,
      // 명세 Interactions: iOS 는 오른쪽에서 밀려 들어오고(가장자리 스와이프
      // 포함), Android 는 shared axis X.
      //
      // shared axis 는 flutter.dev 의 animations 패키지가 M3 정의 그대로 낸다.
      // 직접 그렸다가 공식 구현으로 바꿨다 — 곡선과 지속 시간을 우리가 다시
      // 맞출 이유가 없다.
      //
      // 모든 TargetPlatform 에 같은 걸 넣는다. PageTransitionsTheme 은
      // Theme.platform 으로 고르는데, 그러면 전환이 호스트 OS 를 따라가고
      // 크롬 선택과 어긋난다.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          for (final p in TargetPlatform.values)
            p: chrome == TpChrome.ios
                ? const CupertinoPageTransitionsBuilder()
                : const SharedAxisPageTransitionsBuilder(
                    transitionType: SharedAxisTransitionType.horizontal,
                  ),
        },
      ),
      textTheme: TextTheme(
        headlineLarge: type.largeTitle,
        headlineMedium: type.largeAppBarTitle,
        titleLarge: type.appBarTitle,
        titleMedium: type.cardTitle,
        bodyMedium: type.body,
        bodySmall: type.secondary,
        labelSmall: type.caption,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens, type, motion],
    );
  }
}
