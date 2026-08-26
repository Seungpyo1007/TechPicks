import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../domain/model/device_specs.dart';
import '../feature/ask/ask_screen.dart';
import '../feature/compare/compare_screen.dart';
import '../feature/compare/picker_screen.dart';
import '../feature/detail/detail_screen.dart';
import '../feature/home/home_screen.dart';
import '../feature/login/email_login_screen.dart';
import '../feature/login/login_screen.dart';
import '../feature/onboarding/onboarding_screen.dart';
import '../feature/rank/rank_tab.dart';
import '../feature/scan/scan_screen.dart';
import '../feature/share/tp_link.dart';
import '../feature/viewer/viewer_screen.dart';
import '../feature/you/you_screen.dart';
import 'providers.dart';
import 'shell/tp_tab.dart';
import 'tab_host.dart';

/// 주소 문법.
///
/// [TpLink] 의 것과 같은 모양이다 — 우연이 아니라 처음부터 같았다. 커스텀
/// 스킴 `techpicks://device/x` 가 그냥 `/device/x` 가 된다.
abstract final class TpRoute {
  static const String home = '/';
  static const String rank = '/rank';
  static const String compare = '/compare';
  static const String ask = '/ask';
  static const String you = '/you';

  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String emailLogin = '/login/email';
  static const String scan = '/scan';

  /// 탭 하나가 사는 자리.
  static String of(TpTab tab) => switch (tab) {
    TpTab.home => home,
    TpTab.rank => rank,
    TpTab.compare => compare,
    TpTab.ask => ask,
    TpTab.you => you,
  };
}

/// 앱의 라우터. 한 번만 만든다 — 다시 만들면 이력이 날아간다.
final routerProvider = Provider<GoRouter>((ref) => buildRouter(ref));

/// 앱의 라우터.
///
/// `StatefulShellRoute.indexedStack` 은 탭 스크롤과 입력을 유지하는
/// IndexedStack 에 주소와 이력을 붙인 것이다.
GoRouter buildRouter(Ref ref) {
  return GoRouter(
    initialLocation: TpRoute.home,
    navigatorKey: GlobalKey<NavigatorState>(),
    // 커스텀 스킴 딥링크는 플랫폼이 라우터에 **그대로** 넘긴다 —
    // `techpicks://compare/a/b` 는 우리 경로가 아니라서 라우터가 못 찾고
    // "Page Not Found" 를 그렸다. 문법은 TpLink 가 안다.
    onException: (context, state, router) {
      final target = TpLink.parse(state.uri);
      router.go(target == null ? TpRoute.home : TpLink.path(target));
    },
    // 게이트가 읽는 값이 바뀌면 다시 판단해야 한다. 예전에는 TechPicksRoot 가
    // `ref.watch` 로 다시 그리면서 저절로 됐는데, 라우터는 자기가 듣지 않으면
    // 온보딩을 끝내도 그 자리에 그대로 있는다.
    refreshListenable: _Gate(ref),
    // 온보딩·로그인 게이트. 예전에는 TechPicksRoot 의 if/else 였다.
    redirect: (context, state) {
      final onboarded = ref.read(onboardingDoneProvider);
      // 저장값을 읽는 중이다. TpLaunch 가 로고를 들고 있다.
      if (onboarded == null) return null;

      final here = state.matchedLocation;
      if (!onboarded) {
        return here == TpRoute.onboarding ? null : TpRoute.onboarding;
      }
      if (here == TpRoute.onboarding) return TpRoute.home;

      final signedIn =
          ref.read(currentUserProvider) != null || ref.read(guestProvider);
      if (!signedIn) {
        return here.startsWith(TpRoute.login) ? null : TpRoute.login;
      }
      return here.startsWith(TpRoute.login) ? TpRoute.home : null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: TpRoute.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: TpRoute.login,
        builder: (context, state) => _Login(),
        routes: <RouteBase>[
          GoRoute(
            path: 'email',
            builder: (context, state) => EmailLoginScreen(
              startInSignUp: state.uri.queryParameters['signUp'] == '1',
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(TpRoute.login),
              onSignedIn: () => context.go(TpRoute.home),
            ),
          ),
        ],
      ),

      // 다섯 탭. 브랜치 순서는 TpTab.values 와 같아야 한다.
      // 다섯 브랜치를 미리 짓는다(`preload`). 예전 `IndexedStack` 은 다섯을
      // 한 번에 만들었고, 스크롤·입력이 남는 것도 탭을 바꿀 때 본문이 옅게
      // 들어오는 것도 그걸 전제로 한다 — 게을리 지으면 각 탭의 **첫 방문**에만
      // 전환이 없다.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => TabHost(shell: shell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            preload: true,
            routes: <RouteBase>[
              GoRoute(
                path: TpRoute.home,
                builder: (context, state) => HomeScreen(
                  onTabSelected: (t) => context.go(TpRoute.of(t)),
                  onDeviceTap: (s) => context.push('/device/$s'),
                  onAdd: () => context.go(TpRoute.rank),
                  onCompareAll: () => context.go(TpRoute.compare),
                  onAskWhy: () => context.go(TpRoute.ask),
                  onMoversTap: () => context.go(TpRoute.rank),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: <RouteBase>[
              GoRoute(
                path: TpRoute.rank,
                builder: (context, state) => RankTab(
                  onTabSelected: (t) => context.go(TpRoute.of(t)),
                  onDeviceTap: (s) => context.push('/device/$s'),
                  onScan: () => context.push(TpRoute.scan),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: <RouteBase>[
              GoRoute(
                path: TpRoute.compare,
                builder: (context, state) => const _Compare(),
                routes: <RouteBase>[
                  // **`:a/:b` 보다 먼저** 와야 한다. 뒤에 두면
                  // `/compare/pick/a` 가 두 칸짜리 비교로 먼저 잡혀서
                  // a='pick', b='a' 인 비교를 열려고 한다.
                  GoRoute(
                    path: 'pick/:side',
                    builder: (context, state) => _Picker(
                      side: state.pathParameters['side'] == 'b'
                          ? CompareSide.b
                          : CompareSide.a,
                    ),
                  ),
                  // 링크로 들어온 비교. 두 슬롯을 채우고 같은 화면을 그린다.
                  GoRoute(
                    path: ':a/:b',
                    builder: (context, state) => _CompareWith(
                      a: state.pathParameters['a']!,
                      b: state.pathParameters['b']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: <RouteBase>[
              GoRoute(
                path: TpRoute.ask,
                builder: (context, state) => AskScreen(
                  onTabSelected: (t) => context.go(TpRoute.of(t)),
                  onDeviceTap: (s) => context.push('/device/$s'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: <RouteBase>[
              GoRoute(
                path: TpRoute.you,
                builder: (context, state) => const YouTab(),
              ),
            ],
          ),
        ],
      ),

      // 탭 위로 밀리는 화면들. 명세의 back stack 은 한 단계다.
      GoRoute(
        path: '/device/:slug',
        builder: (context, state) =>
            _Detail(slug: state.pathParameters['slug']!),
        routes: <RouteBase>[
          GoRoute(
            path: '3d',
            builder: (context, state) =>
                _Viewer(slug: state.pathParameters['slug']!),
          ),
        ],
      ),
      GoRoute(path: TpRoute.scan, builder: (context, state) => const _Scan()),
    ],
  );
}

/// 게이트가 보는 값이 바뀌면 라우터를 깨운다.
class _Gate extends ChangeNotifier {
  _Gate(Ref ref) {
    for (final sub in <void Function()>[
      () => ref.listen(onboardingDoneProvider, (_, _) => notifyListeners()),
      () => ref.listen(currentUserProvider, (_, _) => notifyListeners()),
      () => ref.listen(guestProvider, (_, _) => notifyListeners()),
    ]) {
      sub();
    }
  }
}

/// 두 슬롯을 채우고 비교를 그린다.
class _CompareWith extends ConsumerStatefulWidget {
  const _CompareWith({required this.a, required this.b});

  final String a;
  final String b;

  @override
  ConsumerState<_CompareWith> createState() => _CompareWithState();
}

class _CompareWithState extends ConsumerState<_CompareWith> {
  @override
  void initState() {
    super.initState();
    // 빌드 중에 프로바이더를 쓰면 안 된다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final compare = ref.read(compareProvider.notifier);
      compare.pick(CompareSide.a, widget.a);
      compare.pick(CompareSide.b, widget.b);
    });
  }

  @override
  Widget build(BuildContext context) => const _Compare();
}

class _Login extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => LoginScreen(
    onSignedIn: () => context.go(TpRoute.home),
    // 푸터의 `Sign up` 은 가입 화면을 연다. 지금까지는 로그인을 건너뛰어서,
    // 가입하려던 사람이 그냥 앱에 들어와 버렸다.
    onSignUp: () => context.go('${TpRoute.emailLogin}?signUp=1'),
    onEmail: () => context.go(TpRoute.emailLogin),
    onBrowse: () {
      unawaited(ref.read(guestProvider.notifier).stay());
      context.go(TpRoute.home);
    },
  );
}

/// 비교 탭. 프로바이더를 만지는 행동 둘이 있어서 감싼다.
class _Compare extends ConsumerWidget {
  const _Compare();

  @override
  Widget build(BuildContext context, WidgetRef ref) => CompareScreen(
    onTabSelected: (t) => context.go(TpRoute.of(t)),
    onPick: (side) => context.push('${TpRoute.compare}/pick/${side.name}'),
    onAskWhy: () => _askAboutCompared(context, ref),
  );

  /// 비교 중인 두 기기를 그대로 상담으로 넘긴다.
  ///
  /// 한쪽이라도 비어 있으면 물어볼 게 없으니 탭만 바꾼다.
  static void _askAboutCompared(BuildContext context, WidgetRef ref) {
    context.go(TpRoute.ask);

    final slots = ref.read(compareProvider);
    final catalog = ref.read(catalogProvider).value;
    if (catalog == null || slots.a == null || slots.b == null) return;

    String? nameOf(String slug) =>
        catalog.smartphones.where((d) => d.slug == slug).firstOrNull?.name;

    final a = nameOf(slots.a!);
    final b = nameOf(slots.b!);
    if (a == null || b == null) return;
    unawaited(ref.read(askProvider.notifier).askAbout(a, b));
  }
}

/// 내 정보 탭. 로그인 상태를 읽어야 해서 감싼다.
class YouTab extends ConsumerWidget {
  const YouTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => YouScreen(
    onTabSelected: (t) => context.go(TpRoute.of(t)),
    name: ref.watch(currentUserProvider)?.name,
    email: ref.watch(currentUserProvider)?.email,
    // 손님 표시도 같이 지운다. 안 지우면 로그아웃해도 탭에 남는다.
    onLogout: () {
      unawaited(ref.read(currentUserProvider.notifier).signOut());
      unawaited(ref.read(guestProvider.notifier).clear());
    },
    onDeviceTap: (s) => context.push('/device/$s'),
  );
}

class _Picker extends ConsumerStatefulWidget {
  const _Picker({required this.side});

  final CompareSide side;

  @override
  ConsumerState<_Picker> createState() => _PickerState();
}

class _PickerState extends ConsumerState<_Picker> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(pickSlotProvider.notifier).set(widget.side);
    });
  }

  @override
  Widget build(BuildContext context) =>
      PickerScreen(onDone: () => context.pop());
}

class _Detail extends ConsumerWidget {
  const _Detail({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) => DetailScreen(
    slug: slug,
    onBack: () => context.canPop() ? context.pop() : context.go(TpRoute.home),
    // 상세에서 넘어오면 A 슬롯에 그 기기를 넣고 비교 탭으로 간다.
    onCompare: (s) {
      ref.read(compareProvider.notifier).pick(CompareSide.a, s);
      context.go(TpRoute.compare);
    },
    onView3D: (s) => context.push('/device/$s/3d'),
  );
}

class _Viewer extends ConsumerWidget {
  const _Viewer({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name =
        ref
            .watch(catalogProvider)
            .value
            ?.smartphones
            .where((d) => d.slug == slug)
            .firstOrNull
            ?.name ??
        slug;
    return ViewerScreen(
      deviceName: name,
      onBack: () => context.canPop() ? context.pop() : context.go(TpRoute.home),
    );
  }
}

class _Scan extends StatelessWidget {
  const _Scan();

  @override
  Widget build(BuildContext context) => ScanScreen(
    onBack: () => context.canPop() ? context.pop() : context.go(TpRoute.rank),
    // 스캔 결과에서 상세로. 스캔은 이력에서 빠진다 — 뒤로 가면
    // 랭킹으로 돌아오는 게 맞다.
    onOpenDevice: (slug) => context.pushReplacement('/device/$slug'),
  );
}
