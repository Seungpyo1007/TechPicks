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
          child: const TechPicksRoot(),
        ),
      ),
    );
  }
}

/// 온보딩 → 로그인 → 탭.
///
/// 로그인은 건너뛸 수 있다. 명세의 "Browse without an account" 가 그 자리다.
/// 계정 없이도 랭킹·비교·상담이 다 되어야 한다.
/// 온보딩·로그인·탭 중 무엇을 보여줄지 고르는 분기.
///
/// [TechPicksApp] 이 MaterialApp 을 직접 만들기 때문에 테스트가 앱 전체를
/// 올리면 MaterialApp 이 겹친다. 분기만 떼어 쓸 수 있게 공개해 둔다.
class TechPicksRoot extends ConsumerStatefulWidget {
  const TechPicksRoot({super.key});

  @override
  ConsumerState<TechPicksRoot> createState() => _RootState();
}

class _RootState extends ConsumerState<TechPicksRoot> {
  void _openEmail({bool signUp = false}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EmailLoginScreen(
          startInSignUp: signUp,
          onBack: () => Navigator.of(context).pop(),
          onSignedIn: () {
            Navigator.of(context).pop();
            setState(() {});
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final onboarded = ref.watch(onboardingDoneProvider);
    final user = ref.watch(currentUserProvider);
    final guest = ref.watch(guestProvider);

    // 아직 저장값을 못 읽었다. 온보딩과 탭 중 뭘 보여줄지 모르는 상태라
    // 아무것도 안 그린다. 배경색은 테마가 이미 깔아둔다.
    if (onboarded == null) {
      return const SizedBox.expand();
    }
    if (!onboarded) {
      return const OnboardingScreen();
    }
    if (user == null && !guest) {
      return LoginScreen(
        onSignedIn: () => setState(() {}),
        // 푸터의 `Sign up` 은 가입 화면을 연다. 지금까지는 로그인을
        // 건너뛰어서, 가입하려던 사람이 그냥 앱에 들어와 버렸다.
        onSignUp: () => _openEmail(signUp: true),
        onEmail: () => _openEmail(),
        onBrowse: () => ref.read(guestProvider.notifier).stay(),
      );
    }
    return const TabHost();
  }
}
