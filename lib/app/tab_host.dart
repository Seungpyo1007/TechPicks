import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/model/device_specs.dart';
import '../feature/ask/ask_screen.dart';
import '../feature/compare/compare_screen.dart';
import '../feature/compare/picker_screen.dart';
import '../feature/detail/detail_screen.dart';
import '../feature/home/home_screen.dart';
import '../feature/rank/rank_screen.dart';
import '../feature/scan/scan_screen.dart';
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

  void _select(TpTab tab) => setState(() => _tab = tab);

  Future<void> _push(Widget screen) => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );

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
    final name = ref
            .read(catalogProvider)
            .value
            ?.smartphones
            .where((d) => d.slug == slug)
            .firstOrNull
            ?.name ??
        slug;
    _push(ViewerScreen(
      deviceName: name,
      onBack: () => Navigator.of(context).pop(),
    ));
  }

  void _openPicker(CompareSide side) {
    ref.read(pickSlotProvider.notifier).set(side);
    _push(PickerScreen(onDone: () => Navigator.of(context).pop()));
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
        RankScreen(
          onTabSelected: _select,
          onDeviceTap: _openDevice,
          onScan: _openScan,
        ),
        CompareScreen(
          onTabSelected: _select,
          onPick: _openPicker,
          onAskWhy: () => _select(TpTab.ask),
        ),
        AskScreen(
          onTabSelected: _select,
          onDeviceTap: _openDevice,
        ),
        YouScreen(
          onTabSelected: _select,
          name: ref.watch(currentUserProvider)?.name,
          email: ref.watch(currentUserProvider)?.email,
          onLogout: () => ref.read(currentUserProvider.notifier).signOut(),
        ),
      ],
    );
  }
}
