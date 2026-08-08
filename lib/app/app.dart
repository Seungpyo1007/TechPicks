import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../feature/login/email_login_screen.dart';
import '../feature/login/login_screen.dart';
import '../feature/onboarding/onboarding_screen.dart';
import 'locale_controller.dart';
import 'providers.dart';
import 'tab_host.dart';
import 'theme/app_theme.dart';

/// 앱 루트.
class TechPicksApp extends StatelessWidget {
  const TechPicksApp({super.key, this.chrome});

  /// 강제할 크롬. null 이면 OS 로 정한다.
  final TpChrome? chrome;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TechPicks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(chrome ?? TpChrome.forPlatform()),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: Builder(
        // LocaleController 는 easy_localization 의 context 가 필요해서
        // MaterialApp 아래에서 만들어 넣는다.
        builder: (inner) => ProviderScope(
          overrides: [
            localeControllerProvider.overrideWithValue(
              EasyLocaleController(inner),
            ),
          ],
          child: const _Root(),
        ),
      ),
    );
  }
}

/// 온보딩 → 로그인 → 탭.
///
/// 로그인은 건너뛸 수 있다. 명세의 "Browse without an account" 가 그 자리다.
/// 계정 없이도 랭킹·비교·상담이 다 되어야 한다.
class _Root extends ConsumerStatefulWidget {
  const _Root();

  @override
  ConsumerState<_Root> createState() => _RootState();
}

class _RootState extends ConsumerState<_Root> {
  bool _skippedLogin = false;

  @override
  Widget build(BuildContext context) {
    final onboarded = ref.watch(onboardingDoneProvider);
    final user = ref.watch(currentUserProvider);

    if (!onboarded) {
      return const OnboardingScreen();
    }
    if (user == null && !_skippedLogin) {
      return LoginScreen(
        onSignedIn: () => setState(() {}),
        onSignUp: () => setState(() => _skippedLogin = true),
        onEmail: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => EmailLoginScreen(
              onBack: () => Navigator.of(context).pop(),
              onSignedIn: () {
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ),
        ),
      );
    }
    return const TabHost();
  }
}
