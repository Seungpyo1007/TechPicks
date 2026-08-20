import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'locale_controller.dart';
import 'providers.dart';
import 'router.dart';
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
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'TechPicks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.of(chrome),
      darkTheme: AppTheme.of(chrome, dark: true),
      themeMode: ref.watch(themeModeProvider),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      routerConfig: router,
      builder: (inner, child) => ProviderScope(
        // LocaleController 는 easy_localization 의 context 가 필요해서
        // MaterialApp 아래에서 만들어 넣는다.
        overrides: [
          localeControllerProvider.overrideWithValue(
            EasyLocaleController(inner),
          ),
        ],
        child: TechPicksRoot(child: child ?? const SizedBox.expand()),
      ),
    );
  }
}

/// 앱 전체를 감싸는 자리.
///
/// 예전에는 여기서 온보딩·로그인·탭을 if/else 로 골랐다. 그 분기는 이제
/// 라우터의 `redirect` 에 있다([buildRouter]). 여기 남은 일은 둘이다 —
/// 저장값을 읽는 동안 로고를 들고 있는 것, 그리고 화면이 뜨기 전부터 살아
/// 있어야 하는 구독 둘.
class TechPicksRoot extends ConsumerStatefulWidget {
  const TechPicksRoot({super.key, required this.child});

  final Widget child;

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

  @override
  Widget build(BuildContext context) {
    // 저장값을 읽는 동안은 스플래시가 그대로 떠 있다. 예전에는 여기서 빈
    // 화면을 그렸고, 그래서 켤 때마다 흰 화면이 한 번 깜빡였다.
    final onboarded = ref.watch(onboardingDoneProvider);
    return TpLaunch(ready: onboarded != null, child: widget.child);
  }
}
