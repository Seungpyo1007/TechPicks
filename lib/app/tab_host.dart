import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics.dart';
import '../feature/share/tp_link.dart';
import 'providers.dart';
import 'router.dart';
import 'shell/tp_shell.dart';
import 'shell/tp_tab.dart';
import 'shell/tp_tab_bar.dart';
import 'shell/tp_window.dart';
import 'theme/tp_tokens.dart';

/// 탭 네 개와 하나뿐인 탭 바를 들고 있는 자리.
///
/// 명세의 back stack 은 한 단계다. 상세·선택·스캔·뷰어는 이 위로 밀어 올리고
/// 뒤로 가면 원래 탭으로 돌아온다.
///
/// [StatefulShellRoute.indexedStack] 은 탭 스크롤을 유지하는 IndexedStack
/// 에 주소와 이력만 붙인 것이다.
class TabHost extends ConsumerStatefulWidget {
  const TabHost({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<TabHost> createState() => _TabHostState();
}

class _TabHostState extends ConsumerState<TabHost> {
  final TpTabReselectNotifier _reselect = TpTabReselectNotifier();

  /// 검색 탭에서 접힌 바의 원 버튼이 돌아갈 곳.
  TpTab _lastBarTab = TpTab.today;

  @override
  void dispose() {
    _reselect.dispose();
    super.dispose();
  }

  void _select(TpTab picked, TpTab current) {
    if (picked == current) {
      _reselect.fire(picked);
      return;
    }
    context.go(TpRoute.of(picked));
  }

  @override
  void initState() {
    super.initState();
    // 지금 순위를 다음 실행의 비교 대상으로 남긴다. 이게 없으면 스냅샷이
    // 영영 비어 있고 홈의 "이번 주 변동"이 한 번도 안 뜬다.
    ref.listenManual(
      rankSnapshotSlugsProvider,
      (_, next) => ref.read(rankSnapshotProvider.notifier).saveOnce(next),
      fireImmediately: true,
    );

    // 딥링크. 온보딩·로그인 중에 들어온 것도 여기서 처음 열린다.
    //
    // 프레임 뒤로 미룬다. initState 에는 아직 라우터가 붙어 있지 않다.
    ref.listenManual(pendingLinkProvider, (_, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openLink();
      });
    }, fireImmediately: true);
  }

  void _openLink() {
    final target = ref.read(pendingLinkProvider.notifier).take();
    if (target == null) return;
    TpAnalytics.linkOpened(target is DeviceTarget ? 'device' : 'compare');
    // 링크 문법과 주소 문법이 같은 모양이다.
    context.go(TpLink.path(target));
  }

  @override
  Widget build(BuildContext context) {
    final tab = TpTab.values[widget.shell.currentIndex];
    if (tab != TpTab.search) _lastBarTab = tab;
    final rail =
        !context.tp.isGlass && tpWindowClass(context) != TpWindowClass.compact;

    // 다른 탭에서 시스템 뒤로 가기를 누르면 앱을 끄는 대신 홈으로 온다.
    // 명세의 back stack 은 밀어 올린 화면만 다루고 탭은 언급하지 않는데,
    // Android 에서 탭 하나 눌렀다가 뒤로 갔다고 앱이 꺼지면 사고에 가깝다.
    return PopScope(
      canPop: tab == TpTab.today,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(TpRoute.home);
      },
      child: TpActiveTab(
        tab: tab,
        child: TpSearchReturn(
          tab: _lastBarTab,
          onReturn: () => context.go(TpRoute.of(_lastBarTab)),
          child: TpTabReselect(
            notifier: _reselect,
            child: rail
                ? Row(
                    children: <Widget>[
                      TpTabRail(
                        current: tab,
                        onSelected: (t) => _select(t, tab),
                      ),
                      Expanded(child: widget.shell),
                    ],
                  )
                : Stack(
                    children: <Widget>[
                      Positioned.fill(child: widget.shell),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: TpTabBar(
                          current: tab,
                          returnTo: _lastBarTab,
                          onSelected: (t) => _select(t, tab),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
