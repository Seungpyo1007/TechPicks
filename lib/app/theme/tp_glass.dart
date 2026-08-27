import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// 진짜 유리를 켤지 말지 한 곳에서 정한다.
///
/// `liquid_glass_widgets` 는 Impeller 위에서 굴절·엣지 조명·색수차를 셰이더로
/// 돌린다. 켜도 되는 자리가 좁아서 게이트를 따로 둔다.
///
/// - **테스트에서는 끈다.** 셰이더가 매 프레임 다시 그려서 `pumpAndSettle` 이
///   안 끝난다. 이 저장소는 이미 그 부류로 10분 타임아웃을 겪었다.
/// - **iOS 만.** 안드로이드 크롬은 M3 라 유리가 아니고, 토큰도 블러 0 이다.
/// - **웹은 안 한다.** Skia 에서는 아무것도 안 그려진다.
///
/// 꺼져 있으면 [TpSurface] 가 원래의 `BackdropFilter` 로 그린다 — 그림이
/// 크게 다르지 않아서, 패키지가 실기기에서 별로면 이 게이트만 닫으면 된다.
abstract final class TpGlassRuntime {
  /// 테스트가 켜고 끌 수 있게 열어둔다. null 이면 아래 규칙대로.
  @visibleForTesting
  static bool? debugOverride;

  static bool get enabled {
    if (debugOverride != null) return debugOverride!;
    if (kIsWeb) return false;
    if (Platform.environment.containsKey('FLUTTER_TEST')) return false;
    return defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 셰이더를 미리 굽는다. `main()` 에서 한 번.
  ///
  /// 안 하면 유리가 처음 보이는 프레임에 흰 번쩍임이 있다. 게이트가 닫혀
  /// 있으면 아무 일도 안 한다.
  static Future<void> warmUp() async {
    if (!enabled) return;
    await LiquidGlassWidgets.initialize();
  }
}

/// 우리 토큰을 패키지 설정으로 옮긴다.
///
/// 색·블러·그림자는 계속 [TpTokens] 가 정한다. 패키지에서 가져오는 것은
/// **굴절과 엣지 조명**뿐이다 — 그 둘이 `BackdropFilter` 로 안 되는 것이고,
/// 탭 바가 밝은 알약처럼 보이던 이유다.
abstract final class TpGlassSpec {
  static LiquidGlassSettings of({
    required Color fill,
    required double blur,
    required double saturation,
    required List<BoxShadow> shadow,
    required bool chrome,
  }) => LiquidGlassSettings(
    glassColor: fill,
    blur: blur,
    saturation: saturation,
    // 크롬은 두껍고 카드는 얇다. 두꺼울수록 가장자리가 더 휜다.
    thickness: chrome ? 16 : 10,
    // 색수차는 기본값(0.01)도 글자 위에서 보인다. 우리 크롬 뒤로는 목록이
    // 지나가므로 더 낮춘다.
    chromaticAberration: 0.004,
    lightIntensity: chrome ? 0.5 : 0.35,
    refractiveIndex: 1.18,
    shadow: shadow.isEmpty ? null : shadow,
  );

  /// 어느 등급으로 그릴지.
  ///
  /// 크롬은 화면당 두 장뿐이라 셰이더를 다 쓴다. 카드는 목록에 수십 장이
  /// 깔리므로 가벼운 쪽이다.
  static GlassQuality quality({required bool chrome}) =>
      chrome ? GlassQuality.premium : GlassQuality.standard;
}
