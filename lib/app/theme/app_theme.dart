import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'tp_tokens.dart';
import 'tp_typography.dart';

/// 어느 크롬으로 그릴지. 실제 앱은 OS 로 정하지만, 프로토타입처럼 강제로
/// 바꿔볼 수 있어야 디자인 대조가 된다.
enum TpChrome {
  ios,
  android;

  /// 현재 플랫폼에 맞는 크롬. 데스크톱·웹은 Android 쪽으로 떨어뜨린다.
  static TpChrome forPlatform([TargetPlatform? platform]) {
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
  static ThemeData of(TpChrome chrome) {
    final tokens =
        chrome == TpChrome.ios ? TpTokens.ios() : TpTokens.android();
    final type = TpTypography.of(tokens);

    final scheme = ColorScheme.fromSeed(
      seedColor: TpTokens.blue,
      brightness: Brightness.light,
    ).copyWith(
      primary: TpTokens.blue,
      onPrimary: Colors.white,
      surface: chrome == TpChrome.ios
          ? const Color(0xFFEEF3FA)
          : const Color(0xFFF6F8FC),
      onSurface: TpTokens.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      fontFamily: tokens.fontFamily,
      fontFamilyFallback: tokens.fontFamilyFallback,
      splashFactory:
          chrome == TpChrome.ios ? NoSplash.splashFactory : InkRipple.splashFactory,
      textTheme: TextTheme(
        headlineLarge: type.largeTitle,
        headlineMedium: type.largeAppBarTitle,
        titleLarge: type.appBarTitle,
        titleMedium: type.cardTitle,
        bodyMedium: type.body,
        bodySmall: type.secondary,
        labelSmall: type.caption,
      ),
      extensions: <ThemeExtension<dynamic>>[tokens, type],
    );
  }
}
