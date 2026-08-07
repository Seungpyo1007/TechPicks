import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// 앱이 지원하는 언어.
enum TpLocale {
  en(Locale('en', 'US'), 'English'),
  ko(Locale('ko', 'KR'), '한국어');

  const TpLocale(this.locale, this.label);

  final Locale locale;

  /// 화면에 찍는 이름. 이건 번역하지 않는다 — 언어 목록은 각 언어로 적는다.
  final String label;

  static TpLocale of(Locale locale) => values.firstWhere(
        (l) => l.locale.languageCode == locale.languageCode,
        orElse: () => TpLocale.en,
      );
}

/// 언어 전환.
///
/// v1 은 언어를 바꾸면 restart_app 으로 앱을 재시작했다. 명세가 그 안내
/// 다이얼로그를 없애고 즉시 반영하라고 했다.
///
/// 인터페이스로 둔 이유는 테스트 때문이다. easy_localization 의
/// `context.setLocale` 은 그 위젯이 트리에 있어야 하는데, 위젯 테스트에서는
/// 그걸 올리지 않는다 (test/support/harness.dart 참고).
abstract class LocaleController {
  TpLocale get current;

  Future<void> set(TpLocale next);
}

/// easy_localization 을 쓰는 구현. 저장도 그쪽이 알아서 한다.
class EasyLocaleController implements LocaleController {
  EasyLocaleController(this.context);

  final BuildContext context;

  @override
  TpLocale get current => TpLocale.of(context.locale);

  @override
  Future<void> set(TpLocale next) => context.setLocale(next.locale);
}
