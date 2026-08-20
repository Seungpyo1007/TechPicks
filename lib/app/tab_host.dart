import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics.dart';
import '../feature/share/tp_link.dart';
import 'providers.dart';
import 'router.dart';
import 'shell/tp_shell.dart';
import 'shell/tp_tab.dart';

/// 탭 다섯 개를 들고 있는 자리.
///
/// 명세의 back stack 은 한 단계다. 상세·선택·스캔·뷰어는 이 위로 밀어 올리고
/// 뒤로 가면 원래 탭으로 돌아온다.
///
/// 여기 오래 "go_router 를 쓰지 않았다. 필요해지면 그때 바꾼다"고 적혀 있었다.
/// 웹으로 오면서 그때가 됐다 — 주소창이 끝까지 안 바뀌고, 브라우저 뒤로가기가
/// 홈 탭 점프로 먹히고, 공유한 링크를 열 방법이 없었다.
/// [StatefulShellRoute.indexedStack] 은 여기 있던 것과 같은 패턴이다.
class TabHost extends ConsumerStatefulWidget {
  const TabHost({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<TabHost> createState() => _TabHostState();
}

class _TabHostState extends ConsumerState<TabHost> {
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

    // 다른 탭에서 시스템 뒤로 가기를 누르면 앱을 끄는 대신 홈으로 온다.
    // 명세의 back stack 은 밀어 올린 화면만 다루고 탭은 언급하지 않는데,
    // Android 에서 탭 하나 눌렀다가 뒤로 갔다고 앱이 꺼지면 사고에 가깝다.
    //
    // **웹에서는 안 한다.** 브라우저 뒤로가기까지 여기로 들어와서, 이력을
    // 되짚는 대신 홈 탭으로 점프하고 제스처를 먹었다.
    return PopScope(
      canPop: kIsWeb || tab == TpTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(TpRoute.home);
      },
      // 지금 어느 탭인지 아래로 알린다. 본문의 전환은 각 화면의 셸이 한다 —
      // 여기서 통째로 감싸면 탭 캡슐까지 같이 줄었다 커진다.
      child: TpActiveTab(tab: tab, child: widget.shell),
    );
  }
}
