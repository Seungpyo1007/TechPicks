import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/coach/tp_coach.dart';
import '../../shared/copy_keys.dart';
import '../providers.dart';
import '../../shared/widgets/tp_press.dart';
import '../../shared/widgets/tp_surface.dart';
import '../theme/tp_icons.dart';
import '../theme/tp_motion.dart';
import '../theme/tp_native_glass.dart';
import '../theme/tp_tokens.dart';
import '../theme/tp_typography.dart';
import 'tp_tab.dart';
import 'tp_window.dart';

/// 앱에 하나뿐인 탭 바.
///
/// 예전에는 탭 화면마다 셸이 자기 탭 바를 그렸다. 다섯 브랜치를 미리 짓기
/// 때문에 네이티브 탭 바 플랫폼 뷰가 화면 뒤에 다섯 장 떠 있었다. 이제는
/// [TabHost] 가 이것 한 장을 그리고, 화면은 그 자리만 비운다.
class TpTabBar extends ConsumerWidget {
  const TpTabBar({
    super.key,
    required this.current,
    required this.onSelected,
    this.returnTo = TpTab.today,
  });

  final TpTab current;
  final ValueChanged<TpTab> onSelected;

  /// 검색 탭에서 바가 접혔을 때 원 버튼이 돌아갈 탭.
  final TpTab returnTo;

  /// iOS 바 높이. 시스템 바가 쓰는 값이다.
  static const double iosHeight = 62;

  /// 26 미만 대체 바가 홈 인디케이터에서 떨어지는 거리.
  static const double iosGap = 10;

  static const double androidHeight = 80;

  /// iOS 26 탭 바 플랫폼 뷰가 미리 잡아 두는 키보드 자리. 세로 키보드(예측 줄
  /// 포함) 보다 넉넉하게.
  static const double keyboardRoom = 420;

  /// 검색 탭에서 접힌 원과 필드의 바닥 여백. 시스템 탭 캡슐 바닥과 맞춘다
  /// (홈 인디케이터 안쪽으로 13pt 들어간 자리).
  static double searchBottom(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    if (!TpNativeGlass.enabled) return bottom + 4;
    return bottom > 21 ? bottom - 13 : bottom + 8;
  }

  /// 이 크롬에서 바가 가리는 높이(안전 영역 제외). 화면이 목록 아래를 이만큼 더 비운다.
  static double coverOf(BuildContext context) {
    if (context.tp.isGlass) {
      return iosHeight + (TpNativeGlass.enabled ? 0 : iosGap);
    }
    if (tpWindowClass(context) != TpWindowClass.compact) return 0;
    return androidHeight;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final safe = MediaQuery.viewPaddingOf(context);
    if (!context.tp.isGlass) {
      return _AndroidBar(
        current: current,
        onSelected: onSelected,
        bottom: safe.bottom,
      );
    }

    // iOS 26: 검색도 시스템 바가 한다. 검색 탭을 누르면 UIKit 이 칸을 밀어내고
    // 검색창을 바 자리로 펼치며, 검색창을 누르면 키보드 위로 올린다.
    //
    // 플랫폼 뷰 크기는 **절대 바꾸지 않는다.** 키보드에 맞춰 늘리던 때는 UIKit 이
    // 옛 크기로 자리를 잡아 검색창이 화면 위쪽까지 날아갔다가 내려왔다. 그래서
    // 처음부터 키보드 자리([keyboardRoom])까지 크게 잡는다.
    //
    // 대신 바·검색창이 있는 아래쪽 밖에서는 **아예 히트되지 않게** 한다
    // ([_BarHit]). 히트되면 플랫폼 뷰의 제스처가 아레나에 먼저 들어가 손을 뗄 때
    // 이겨 버려서, 그 뒤의 목록 행이 눌리지 않았다(스크롤만 됐다).
    if (TpNativeGlass.enabled) {
      final searching = current == TpTab.search;
      final keyboard = searching
          ? ref.watch(searchKeyboardHeightProvider)
          : 0.0;
      final command = ref.watch(searchCommandProvider);
      final total =
          iosHeight + TpNativeTabBar.overflow + safe.bottom + keyboardRoom;
      final area = iosHeight + math.max(safe.bottom, keyboard);
      // 검색 원은 UIKit 이 그려서 잴 수 없다. 같은 자리에 빈 칸을 두고 안내가
      // 그걸 가리킨다(오른쪽 21, 바닥은 시스템 탭 캡슐 바닥).
      return SizedBox(
        height: total,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: _BarHit(
                hits: (local) => local.dy >= total - area,
                child: TpNativeTabBar(
                  index: TpTab.bar.indexOf(searching ? returnTo : current),
                  onSelected: (i) => onSelected(TpTab.bar[i]),
                  onSearch: () => onSelected(TpTab.search),
                  searchLabel: K.tab(TpTab.search).tr(),
                  nativeSearch: true,
                  searchActive: searching,
                  searchPlaceholder: K.searchAllHint.tr(),
                  onSearchChanged: (q) =>
                      ref.read(searchQueryProvider.notifier).set(q),
                  onSearchKeyboard: (h) =>
                      ref.read(searchKeyboardHeightProvider.notifier).set(h),
                  keyboardDismissToken: ref.watch(searchKeyboardProvider),
                  searchText: command.text,
                  searchTextToken: command.textToken,
                  searchFocusToken: command.focusToken,
                  height: iosHeight + safe.bottom + keyboardRoom,
                  tint: TpTokens.blue,
                  items: <TpNativeTabItem>[
                    for (final t in TpTab.bar)
                      TpNativeTabItem(
                        label: K.tab(t).tr(),
                        symbol: t.symbol,
                        activeSymbol: t.activeSymbol,
                      ),
                  ],
                ),
              ),
            ),
            if (!searching)
              Positioned(
                right: 21,
                bottom: searchBottom(context),
                width: iosHeight,
                height: iosHeight,
                child: const IgnorePointer(
                  child: TpCoachTarget(id: 'search', child: SizedBox.expand()),
                ),
              ),
          ],
        ),
      );
    }

    // 26 미만: 검색 탭에서 바가 원 하나로 접히고, 필드는 검색 화면이 그린다.
    if (current == TpTab.search) {
      return Padding(
        padding: EdgeInsets.fromLTRB(21, 0, 21, searchBottom(context)),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: _GlassCircle(
            size: 50,
            label: K.tab(returnTo).tr(),
            icon: TpIcons.iosTab(returnTo, active: false),
            onTap: () => onSelected(returnTo),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(21, 0, 21, safe.bottom + iosGap),
      child: SizedBox(
        height: iosHeight,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TpSurface.chrome(
                raised: true,
                radius: TpTokens.rControl,
                child: _IosCells(current: current, onSelected: onSelected),
              ),
            ),
            const SizedBox(width: 10),
            TpCoachTarget(
              id: 'search',
              child: _GlassCircle(
                size: iosHeight,
                label: K.tab(TpTab.search).tr(),
                icon: CupertinoIcons.search,
                onTap: () => onSelected(TpTab.search),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 26 미만 iOS 바의 칸들. 고른 칸은 옅은 방울, 글자와 아이콘은 액센트.
class _IosCells extends StatelessWidget {
  const _IosCells({required this.current, required this.onSelected});

  final TpTab current;
  final ValueChanged<TpTab> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final move = context.motion.selection;
    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / TpTab.bar.length;
        final index = TpTab.bar.indexOf(current);
        return Stack(
          children: <Widget>[
            AnimatedPositioned(
              key: const ValueKey<String>('tab-pill'),
              duration: move.duration,
              curve: move.curve,
              left: index * cell + 4,
              width: cell - 8,
              top: 4,
              bottom: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.track,
                  borderRadius: BorderRadius.circular(TpTokens.rControl),
                ),
              ),
            ),
            Row(
              children: <Widget>[
                for (final tab in TpTab.bar)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: tab == current,
                      label: K.tab(tab).tr(),
                      onTap: () => onSelected(tab),
                      excludeSemantics: true,
                      child: TpPress(
                        semanticsButton: false,
                        onTap: () => onSelected(tab),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                TpIcons.iosTab(tab, active: tab == current),
                                size: 24,
                                color: tab == current ? TpTokens.blue : t.ink,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                K.tab(tab).tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: type.tabLabel.copyWith(
                                  color: tab == current ? TpTokens.blue : t.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({
    required this.size,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: TpPress(
      semanticsButton: false,
      onTap: onTap,
      // 캡슐로 넘기면 OS 가 정사각형 틀 안에서 납작하게 그린다. 반지름을
      // 절반으로 주면 원이 된다.
      child: TpSurface.chrome(
        raised: true,
        radius: size / 2,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 22, color: context.tp.ink),
        ),
      ),
    ),
  );
}

/// Android M3 NavigationBar. 검색도 한 칸이다 — Android 에는 검색 역할 탭이 없다.
class _AndroidBar extends StatelessWidget {
  const _AndroidBar({
    required this.current,
    required this.onSelected,
    required this.bottom,
  });

  final TpTab current;
  final ValueChanged<TpTab> onSelected;
  final double bottom;

  @override
  Widget build(BuildContext context) => NavigationBar(
    height: TpTabBar.androidHeight,
    selectedIndex: TpTab.values.indexOf(current),
    onDestinationSelected: (i) => onSelected(TpTab.values[i]),
    destinations: <Widget>[
      for (final t in TpTab.values)
        NavigationDestination(
          icon: Icon(t.icon),
          selectedIcon: Icon(t.activeIcon),
          label: K.tab(t).tr(),
        ),
    ],
  );
}

/// 넓은 창의 왼쪽 레일.
class TpTabRail extends StatelessWidget {
  const TpTabRail({super.key, required this.current, required this.onSelected});

  final TpTab current;
  final ValueChanged<TpTab> onSelected;

  @override
  Widget build(BuildContext context) => NavigationRail(
    selectedIndex: TpTab.values.indexOf(current),
    onDestinationSelected: (i) => onSelected(TpTab.values[i]),
    labelType: NavigationRailLabelType.all,
    destinations: <NavigationRailDestination>[
      for (final t in TpTab.values)
        NavigationRailDestination(
          icon: Icon(t.icon),
          selectedIcon: Icon(t.activeIcon),
          label: Text(K.tab(t).tr()),
        ),
    ],
  );
}

/// 검색 탭의 접힌 원이 돌아갈 곳. [TabHost] 가 넣어 준다.
class TpSearchReturn extends InheritedWidget {
  const TpSearchReturn({
    super.key,
    required this.tab,
    required this.onReturn,
    required super.child,
  });

  final TpTab tab;
  final VoidCallback onReturn;

  static TpSearchReturn? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpSearchReturn>();

  @override
  bool updateShouldNotify(TpSearchReturn old) => old.tab != tab;
}

/// 원 버튼. 검색 화면도 쓴다.
class TpGlassCircle extends StatelessWidget {
  const TpGlassCircle({
    super.key,
    required this.size,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final double size;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      _GlassCircle(size: size, label: label, icon: icon, onTap: onTap);
}

/// 지금 탭을 다시 눌렀다는 신호. 셸이 듣고 자기 목록을 맨 위로 올린다.
class TpTabReselect extends InheritedNotifier<TpTabReselectNotifier> {
  const TpTabReselect({
    super.key,
    required super.notifier,
    required super.child,
  });

  static TpTabReselectNotifier? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpTabReselect>()?.notifier;
}

class TpTabReselectNotifier extends ChangeNotifier {
  TpTab? last;

  void fire(TpTab tab) {
    last = tab;
    notifyListeners();
  }
}

/// [hits] 가 참인 자리만 히트된다. 그 밖의 터치는 이 아래(뒤의 화면)로 간다.
class _BarHit extends SingleChildRenderObjectWidget {
  const _BarHit({required this.hits, required super.child});

  final bool Function(Offset local) hits;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderBarHit(hits);

  @override
  void updateRenderObject(BuildContext context, _RenderBarHit renderObject) {
    renderObject.hits = hits;
  }
}

class _RenderBarHit extends RenderProxyBox {
  _RenderBarHit(this.hits);

  bool Function(Offset local) hits;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hits(position)) return false;
    return super.hitTest(result, position: position);
  }
}
