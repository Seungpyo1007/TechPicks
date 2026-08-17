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
import 'tp_launch.dart';

/// 앱 루트.
class TechPicksApp extends ConsumerWidget {
  const TechPicksApp({super.key, this.chrome});

  /// 강제할 크롬. null 이면 OS 로 정한다.
  final TpChrome? chrome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chrome = this.chrome ?? TpChrome.forPlatform();
    return MaterialApp(
      title: 'TechPicks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(chrome),
      darkTheme: AppTheme.of(chrome, dark: true),
      themeMode: ref.watch(themeModeProvider),
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
  @override
  void initState() {
    super.initState();
    // 딥링크는 온보딩·로그인 중에도 들어온다. 여기서 구독을 열어두지 않으면
    // 탭이 뜨기 전에 온 링크를 아무도 안 듣는다. 여는 것은 TabHost 가 한다.
    ref.listenManual(pendingLinkProvider, (_, _) {});

    // 관심 목록 동기화. 로그인하는 순간 맞춰야 하므로 로그인 화면보다 위에서
    // 살아 있어야 한다.
    ref.listenManual(shortlistSyncProvider, (_, _) {});
  }

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

    // 저장값을 읽는 동안은 스플래시가 그대로 떠 있다. 예전에는 여기서 빈
    // 화면을 그렸고, 그래서 켤 때마다 흰 화면이 한 번 깜빡였다.
    return TpLaunch(
      ready: onboarded != null,
      child: onboarded == null
          ? const SizedBox.expand()
          : _first(onboarded: onboarded),
    );
  }

  /// 온보딩 · 로그인 · 탭 중 무엇을 보여줄지.
  Widget _first({required bool onboarded}) {
    final user = ref.watch(currentUserProvider);
    final guest = ref.watch(guestProvider);

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
