import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/analytics.dart';
import '../domain/model/device_specs.dart';
import '../feature/ask/ask_screen.dart';
import '../feature/compare/compare_screen.dart';
import '../feature/compare/picker_screen.dart';
import '../feature/detail/detail_screen.dart';
import '../feature/home/home_screen.dart';
import '../feature/rank/rank_tab.dart';
import '../feature/scan/scan_screen.dart';
import '../feature/share/tp_link.dart';
import '../feature/viewer/viewer_screen.dart';
import '../feature/you/you_screen.dart';
import 'providers.dart';
import 'shell/tp_tab.dart';

/// 탭 다섯 개를 들고 있는 화면.
///
/// 명세의 back stack 은 한 단계다. 상세·선택·스캔·뷰어는 이 위로 밀어 올리고
/// 뒤로 가면 원래 탭으로 돌아온다. 그 이상 복잡한 이력이 필요한 화면이 없다.
///
/// go_router 를 쓰지 않았다. 계획서에는 딥링크를 이유로 적어뒀는데 명세에
/// 딥링크 요구가 없다. 필요해지면 그때 바꾼다.
class TabHost extends ConsumerStatefulWidget {
  const TabHost({super.key, this.initialTab = TpTab.home});

  final TpTab initialTab;

  @override
  ConsumerState<TabHost> createState() => _TabHostState();
}

class _TabHostState extends ConsumerState<TabHost> {
  late TpTab _tab = widget.initialTab;

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
    // 프레임 뒤로 미룬다. initState 에는 아직 Navigator 가 없고, 링크가
    // 상세를 밀어 올리려면 그게 필요하다.
    ref.listenManual(pendingLinkProvider, (_, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openLink();
      });
    }, fireImmediately: true);
  }

  void _openLink() {
    switch (ref.read(pendingLinkProvider.notifier).take()) {
      case DeviceTarget(:final slug):
        TpAnalytics.linkOpened('device');
        _openDevice(slug);
      case CompareTarget(:final a, :final b):
        TpAnalytics.linkOpened('compare');
        _openCompare(a, b);
      case null:
        break;
    }
  }

  /// 링크로 들어온 비교. 두 슬롯을 채우고 비교 탭으로 간다.
  void _openCompare(String a, String b) {
    final compare = ref.read(compareProvider.notifier);
    compare.pick(CompareSide.a, a);
    compare.pick(CompareSide.b, b);
    Navigator.of(context).popUntil((r) => r.isFirst);
    _select(TpTab.compare);
  }

  void _select(TpTab tab) => setState(() => _tab = tab);

  Future<void> _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  void _openDevice(String slug) => _push(
    DetailScreen(
      slug: slug,
      onBack: () => Navigator.of(context).pop(),
      onCompare: _compareWith,
      onView3D: (s) => _openViewer(s),
    ),
  );

  /// 상세에서 넘어오면 A 슬롯에 그 기기를 넣고 비교 탭으로 간다.
  void _compareWith(String slug) {
    ref.read(compareProvider.notifier).pick(CompareSide.a, slug);
    Navigator.of(context).popUntil((r) => r.isFirst);
    _select(TpTab.compare);
  }

  void _openViewer(String slug) {
    final name =
        ref
            .read(catalogProvider)
            .value
            ?.smartphones
            .where((d) => d.slug == slug)
            .firstOrNull
            ?.name ??
        slug;
    _push(
      ViewerScreen(deviceName: name, onBack: () => Navigator.of(context).pop()),
    );
  }

  void _openPicker(CompareSide side) {
    ref.read(pickSlotProvider.notifier).set(side);
    _push(PickerScreen(onDone: () => Navigator.of(context).pop()));
  }

  /// 비교 중인 두 기기를 그대로 상담으로 넘긴다.
  ///
  /// 한쪽이라도 비어 있으면 물어볼 게 없으니 탭만 바꾼다.
  void _askAboutCompared() {
    _select(TpTab.ask);

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

  void _openScan() => _push(
    ScanScreen(
      onBack: () => Navigator.of(context).pop(),
      onOpenDevice: (slug) {
        Navigator.of(context).pop();
        _openDevice(slug);
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    // 다른 탭에서 시스템 뒤로 가기를 누르면 앱을 끄는 대신 홈으로 온다.
    // 명세의 back stack 은 밀어 올린 화면만 다루고 탭은 언급하지 않는데,
    // Android 에서 탭 하나 눌렀다가 뒤로 갔다고 앱이 꺼지면 사고에 가깝다.
    return PopScope(
      canPop: _tab == TpTab.home,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(TpTab.home);
      },
      child: _stack(),
    );
  }

  Widget _stack() {
    // IndexedStack 이라 탭을 오가도 스크롤 위치와 입력이 남는다.
    return IndexedStack(
      index: TpTab.values.indexOf(_tab),
      children: <Widget>[
        HomeScreen(
          onTabSelected: _select,
          onDeviceTap: _openDevice,
          onAdd: () => _select(TpTab.rank),
          onCompareAll: () => _select(TpTab.compare),
          onAskWhy: () => _select(TpTab.ask),
          onMoversTap: () => _select(TpTab.rank),
        ),
        RankTab(
          onTabSelected: _select,
          onDeviceTap: _openDevice,
          onScan: _openScan,
        ),
        CompareScreen(
          onTabSelected: _select,
          onPick: _openPicker,
          onAskWhy: _askAboutCompared,
        ),
        AskScreen(onTabSelected: _select, onDeviceTap: _openDevice),
        YouScreen(
          onTabSelected: _select,
          name: ref.watch(currentUserProvider)?.name,
          email: ref.watch(currentUserProvider)?.email,
          // 손님 표시도 같이 지운다. 안 지우면 로그아웃해도 탭에 남는다.
          onLogout: () {
            unawaited(ref.read(currentUserProvider.notifier).signOut());
            unawaited(ref.read(guestProvider.notifier).clear());
          },
          onDeviceTap: _openDevice,
        ),
      ],
    );
  }
}
