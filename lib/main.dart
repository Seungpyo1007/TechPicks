import 'dart:async' show unawaited;
import 'dart:ui' show PlatformDispatcher;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme/tp_glass.dart';
import 'core/analytics.dart';
import 'core/error_reporter.dart';
import 'firebase_options.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // 네이티브 스플래시를 첫 프레임에서 걷지 않고 붙잡아 둔다. 안 그러면
  // Firebase·번역·셰이더를 준비하는 동안 빈 화면이 한 번 지나간다.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await EasyLocalization.ensureInitialized();

  // 유리 셰이더를 미리 굽는다. 안 하면 첫 프레임에 크롬이 하얗게 번쩍인다.
  await TpGlassRuntime.warmUp();

  // Firebase 가 없어도 앱은 뜬다. 로그인만 안 되고 랭킹·비교·상담은 다 된다.
  // google-services.json 이 아직 온전하지 않아 (oauth_client 가 비어 있다)
  // 여기서 죽으면 개발 중에 아무것도 못 본다.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _wireCrashlytics();
    TpAnalytics.use(_FirebaseAnalyticsSink(FirebaseAnalytics.instance));
  } catch (_) {
    // 로그인 화면이 "연결되지 않았다"로 떨어진다. 여기서 실패하면 기록할
    // 곳도 없으므로 TpErrors 는 조용한 기본값을 유지한다.
  }

  // 여기서 걷는다. 이 뒤로는 앱이 같은 로고를 같은 자리에 그리고 있어서
  // 넘어오는 순간이 화면에 안 보인다 — [TpLaunch] 가 그걸 이어받는다.
  FlutterNativeSplash.remove();

  runApp(
    EasyLocalization(
      supportedLocales: const <Locale>[Locale('en', 'US'), Locale('ko', 'KR')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const ProviderScope(child: TechPicksApp()),
    ),
  );
}

/// 삼킨 실패와 안 잡힌 예외를 Crashlytics 로 보낸다.
///
/// Firebase 초기화가 성공했을 때만 부른다. 실패한 상태에서 부르면 그 자체가
/// 던진다.
void _wireCrashlytics() {
  final crashlytics = FirebaseCrashlytics.instance;

  TpErrors.use(_CrashlyticsSink(crashlytics));

  // Flutter 프레임워크가 잡은 것.
  FlutterError.onError = crashlytics.recordFlutterFatalError;

  // 그 밖에서 새어 나온 것.
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}

/// 삼킨 실패는 non-fatal 로 남긴다. 앱은 계속 돌고 있었다.
class _CrashlyticsSink implements ErrorSink {
  const _CrashlyticsSink(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  void record(Object error, StackTrace? stack, {String? reason}) {
    _crashlytics.recordError(error, stack, reason: reason, fatal: false);
  }
}

/// 이벤트를 Firebase 로 보낸다.
///
/// 이름과 값만 보낸다. 질문 원문이나 기기 식별자는 안 보낸다.
class _FirebaseAnalyticsSink implements AnalyticsSink {
  const _FirebaseAnalyticsSink(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  void log(String event, Map<String, Object> params) {
    unawaited(_analytics.logEvent(name: event, parameters: params));
  }
}
