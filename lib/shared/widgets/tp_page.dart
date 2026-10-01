import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/shell/tp_tab_bar.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../copy_keys.dart';
import 'tp_group.dart';
import 'tp_menu.dart';
import '../brand/tp_logo.dart';
import '../coach/tp_coach.dart';
import 'tp_arrive.dart';
import 'tp_surface.dart';

/// 화면 맨 위 버튼 줄. **Apple 표준 그대로**다(iOS 26 UINavigationBar 를
/// 시뮬레이터에서 잰 값 — 설정·미리 알림·파일·연락처):
///
/// - 바 높이 [height] 54, 안전 영역 바로 아래에서 시작.
/// - 버튼 줄은 바 맨 위 44pt([row]). 버튼 가운데가 안전 영역 +22.
/// - 좌우 여백 [side] 20. 뒤로 버튼 (20, 안전 영역, 44, 44).
/// - 큰 제목은 바 아래 +4 에서 시작(안전 영역 +58), x 20.
///
/// 한동안 화면마다 달랐고, 그다음엔 로그인 X 에 맞췄다(+26, 16). 둘 다
/// 시스템 앱과 나란히 두면 버튼이 4pt 낮고 안쪽이었다.
class TpTopBar extends StatelessWidget {
  const TpTopBar({
    super.key,
    this.leading,
    this.middle,
    this.trailing,
    this.safeTop = true,
    this.padding,
  });

  static const double height = 54;
  static const double row = 44;
  static const double side = 20;

  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;

  /// 안전 영역을 여기서 비울지. 이미 SafeArea 안이면 false.
  final bool safeTop;

  /// 좌우 여백. 없으면 [side] 20. Android M3 앱 바는 앞 4 · 뒤 16.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      top: safeTop ? MediaQuery.paddingOf(context).top : 0,
    ),
    // Android 는 터치 최소가 48 이라 줄도 48(바 56).
    child: SizedBox(
      height: context.tp.isGlass ? height : 56,
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: context.tp.isGlass ? row : 48,
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: side),
            child: NavigationToolbar(
              leading: leading,
              middle: middle,
              trailing: trailing,
              middleSpacing: 12,
            ),
          ),
        ),
      ),
    ),
  );
}

/// 시트 위 버튼의 몫. iOS 26 은 글자 대신 X 와 체크 원으로 그린다.
enum TpBarRole { none, close, confirm }

/// 툴바 버튼 하나.
class TpBarAction {
  const TpBarAction({
    required this.label,
    this.icon,
    this.onTap,
    this.role = TpBarRole.none,
    this.text = false,
    this.filled = false,
    this.child,
    this.menu,
    this.symbol,
    this.active = false,
    this.coach,
  });

  /// 스크린 리더 이름. [text] 면 화면에도 이 글자가 나온다.
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// 닫기(취소)·확인(완료·저장). iOS 는 X / 액센트 체크 원, Android 는 글자.
  final TpBarRole role;

  /// 아이콘 대신 글자 캡슐("완료", "취소").
  final bool text;

  /// 액센트로 채운 캡슐("저장").
  final bool filled;

  /// 아이콘 자리에 직접 그릴 것(프로필 이니셜 원).
  final Widget? child;

  /// 있으면 누를 때 풀다운 메뉴가 열린다.
  final List<TpMenuItem>? menu;

  /// SF Symbol 이름. iOS 26 에서 메뉴 버튼을 시스템 것으로 그릴 때 쓴다.
  final String? symbol;

  /// 걸려 있는 상태(필터). 모양은 그대로 두고 아이콘만 액센트로.
  final bool active;

  /// 화면 안 안내가 가리킬 이름([TpCoachTarget.id]).
  final String? coach;
}

/// v3 화면 뼈대. 큰 제목 + 슬리버 목록.
///
/// iOS 는 큰 제목이 내용과 같이 스크롤돼 올라가고, 위에는 유리 버튼만 떠
/// 있다(가운데 작은 제목으로 줄어들지 않는다). Android 는 `SliverAppBar.large`.
///
/// 탭 바 자리는 여기서 비운다. 탭 바 자체는 [TabHost] 가 그린다.
class TpPage extends StatelessWidget {
  const TpPage({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.tab,
    this.onBack,
    this.actions = const <TpBarAction>[],
    this.leading,
    this.onRefresh,
    this.floating,
    this.largeTitle = true,
    this.showTitle = true,
    this.coach = const <TpCoachStep>[],
  });

  final String title;
  final List<Widget> slivers;
  final String? subtitle;

  /// 탭 화면이면 그 탭. 다시 누르면 맨 위로 가고, 아래를 탭 바만큼 비운다.
  final TpTab? tab;

  final VoidCallback? onBack;
  final List<TpBarAction> actions;

  /// 왼쪽 버튼(시트의 "취소"). [onBack] 이 있으면 무시한다.
  final TpBarAction? leading;

  /// 당겨서 새로고침.
  final Future<void> Function()? onRefresh;

  /// 탭 바 위에 떠 있는 버튼(비교의 "이유 물어보기").
  final Widget? floating;

  /// false 면 처음부터 작은 제목(시트 안 push 화면).
  final bool largeTitle;

  /// false 면 제목을 그리지 않고 바에 버튼만 둔다. [largeTitle] 이 false 일
  /// 때만 쓴다. 첫 카드가 곧 제목인 화면(내 정보).
  final bool showTitle;

  /// 이 화면에 처음 들어왔을 때 한 번 보여줄 안내. 이름은 [tab] 으로 정한다.
  final List<TpCoachStep> coach;

  static void scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null || !controller.hasClients) return;
    // 동작 줄이기면 바로 맨 위로.
    final reduced = MediaQuery.disableAnimationsOf(context);
    for (final p in controller.positions.toList()) {
      if (reduced) {
        p.jumpTo(0);
        continue;
      }
      p.animateTo(
        0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final safe = MediaQuery.viewPaddingOf(context);
    // 떠 있는 버튼이 있으면 마지막 행이 그 뒤로 숨지 않게 더 비운다.
    // 키보드가 올라와 있으면(네이티브 검색창) 마지막 행을 그 위까지 올릴 수
    // 있어야 한다.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final bottom =
        math.max(safe.bottom, keyboard) +
        (tab != null ? TpTabBar.coverOf(context) : 0) +
        (floating != null ? 80 : 24);
    final glass = context.tp.isGlass;

    final body = CustomScrollView(
      primary: true,
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      slivers: <Widget>[
        if (glass) _iosBar(context) else _androidBar(context),
        if (subtitle != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(TpTopBar.side, 0, 16, 4),
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 15, height: 1.33, color: sys.label2),
              ),
            ),
          ),
        if (onRefresh != null && glass)
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
            builder: _refreshMark,
          ),
        ...slivers,
        SliverToBoxAdapter(child: SizedBox(height: bottom)),
      ],
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: ColoredBox(
        color: sys.background,
        child: Material(
          type: MaterialType.transparency,
          child: TpReselect(
            tab: tab,
            onReselect: scrollToTop,
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: _Stamp(
                    tab: tab,
                    coach: coach,
                    child: onRefresh != null && !glass
                        ? _TpRefresh(onRefresh: onRefresh!, child: body)
                        : body,
                  ),
                ),
                if (floating != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom:
                        safe.bottom +
                        (tab != null ? TpTabBar.coverOf(context) : 0) +
                        12,
                    // iOS 는 가운데 캡슐, Android 는 오른쪽 아래 확장 FAB.
                    child: Align(
                      alignment: glass
                          ? Alignment.center
                          : AlignmentDirectional.centerEnd,
                      child: floating,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iosBar(BuildContext context) {
    final sys = context.sys;
    final lead = onBack != null
        ? TpBarButton(
            action: TpBarAction(
              label: K.back.tr(),
              icon: CupertinoIcons.chevron_back,
              symbol: 'chevron.backward',
              onTap: onBack,
            ),
          )
        : (leading == null ? null : TpBarButton(action: leading!));
    final trail = actions.isEmpty
        ? null
        : _ActionsArrive(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < actions.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  TpBarButton(action: actions[i]),
                ],
              ],
            ),
          );
    final titleText = showTitle ? Text(title) : const SizedBox.shrink();
    if (!largeTitle) {
      final top = MediaQuery.paddingOf(context).top;
      return SliverPersistentHeader(
        pinned: true,
        delegate: _SmallBar(
          height: top + TpTopBar.height,
          bar: ColoredBox(
            color: sys.background.withValues(alpha: .92),
            child: TpTopBar(
              leading: lead,
              trailing: trail,
              middle: DefaultTextStyle(
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: sys.label,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: titleText,
              ),
            ),
          ),
        ),
      );
    }
    // 큰 제목은 내용과 같이 올라가고, 바에는 버튼만 남는다. 줄어든 작은
    // 제목이 가운데 붙는 옛 방식은 Liquid Glass 툴바와 안 맞는다.
    final top = MediaQuery.paddingOf(context).top;
    return SliverMainAxisGroup(
      slivers: <Widget>[
        SliverPersistentHeader(
          pinned: true,
          delegate: _GlassEdge(
            top: top,
            color: sys.background,
            leading: lead,
            trailing: trail,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            // Apple 큰 제목: 바 아래 +4, 왼쪽 20.
            padding: const EdgeInsets.fromLTRB(TpTopBar.side, 4, 16, 8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 34,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .4,
                  color: sys.label,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _androidBar(BuildContext context) {
    final back = onBack != null
        ? IconButton(
            onPressed: onBack,
            tooltip: K.back.tr(),
            icon: const Icon(Icons.arrow_back),
          )
        : (leading == null
              ? null
              : Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: TextButton(
                    onPressed: leading!.onTap,
                    child: Text(leading!.label),
                  ),
                ));
    // 글자 버튼은 기본 자리 56 에 안 들어가 "Cancel" 이 잘린다. 글자 폭만큼 연다.
    double? leadingWidth;
    if (onBack == null && leading != null) {
      final label = TextPainter(
        text: TextSpan(
          text: leading!.label,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        textScaler: MediaQuery.textScalerOf(context),
        textDirection: Directionality.of(context),
        maxLines: 1,
      )..layout();
      // 버튼 최소 폭 64, 안쪽 12·12, 앞 4.
      leadingWidth = math.max(64, label.width + 24) + 4;
      label.dispose();
    }
    Widget coach(TpBarAction a, Widget child) =>
        a.coach == null ? child : TpCoachTarget(id: a.coach!, child: child);
    final acts = <Widget>[
      for (final a in actions)
        _ActionsArrive(
          child: coach(
            a,
            a.text
                ? (a.filled
                      ? Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilledButton(
                            onPressed: a.onTap,
                            child: Text(a.label),
                          ),
                        )
                      : TextButton(onPressed: a.onTap, child: Text(a.label)))
                : a.menu != null
                ? TpMenu(
                    items: a.menu!,
                    builder: (context, open) => IconButton(
                      onPressed: open,
                      tooltip: a.label,
                      icon: a.child ?? Icon(a.icon),
                    ),
                  )
                : IconButton(
                    onPressed: a.onTap,
                    tooltip: a.label,
                    icon: a.child ?? Icon(a.icon),
                  ),
          ),
        ),
      const SizedBox(width: 4),
    ];
    if (!largeTitle) {
      return SliverAppBar(
        pinned: true,
        title: showTitle ? Text(title) : null,
        leading: back,
        leadingWidth: leadingWidth,
        automaticallyImplyLeading: false,
        actions: acts,
      );
    }
    return SliverAppBar.large(
      title: Text(title),
      leading: back,
      leadingWidth: leadingWidth,
      automaticallyImplyLeading: false,
      actions: acts,
    );
  }
}

/// 화면이 보이게 된 순간을 찍는다. 탭 화면은 그 탭이 켜질 때마다, 나머지는
/// 처음 지어질 때 한 번.
class _Stamp extends StatefulWidget {
  const _Stamp({required this.tab, required this.child, this.coach = const []});

  final TpTab? tab;
  final Widget child;

  /// 이 탭에 처음 들어왔을 때 띄울 안내.
  final List<TpCoachStep> coach;

  @override
  State<_Stamp> createState() => _StampState();
}

class _StampState extends State<_Stamp> {
  DateTime? _at;
  TpTab? _active;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tab = widget.tab;
    if (tab == null) {
      _at ??= DateTime.now();
      return;
    }
    final active = TpActiveTab.maybeOf(context);
    // 탭 호스트 밖(테스트, 단독 화면)이면 처음 한 번.
    if (active == null) {
      _at ??= DateTime.now();
      return;
    }
    if (active == tab && _active != tab) {
      _at = DateTime.now();
      _coachLater(tab);
    } else if (active != tab && _active == tab) {
      _coachTimer?.cancel();
      TpCoach.dismissFor(tab.name);
    }
    _active = active;
  }

  Timer? _coachTimer;

  @override
  void didUpdateWidget(_Stamp old) {
    super.didUpdateWidget(old);
    // 안내가 늦게 생겼다(화면이 다 불러온 뒤). 이 탭이 켜져 있으면 그때 예약.
    final tab = widget.tab;
    if (tab != null &&
        old.coach.isEmpty &&
        widget.coach.isNotEmpty &&
        _active == tab) {
      _coachLater(tab);
    }
  }

  /// 도착 연출(줄·툴바 버튼)이 끝난 뒤에 띄운다. 움직이는 버튼을 가리키면
  /// 구멍이 엉뚱한 자리에 뚫린다.
  static const Duration coachDelay = Duration(milliseconds: 900);

  void _coachLater(TpTab tab) {
    if (widget.coach.isEmpty) return;
    _coachTimer?.cancel();
    _coachTimer = Timer(coachDelay, () {
      if (!mounted) return;
      unawaited(
        TpCoach.maybeShow(context, screen: tab.name, steps: widget.coach),
      );
    });
  }

  @override
  void dispose() {
    _coachTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TpArriveScope(
    at: TpArriveScope.latest(TpArriveScope.of(context), _at),
    child: widget.child,
  );
}

/// 화면이 나타날 때 툴바 버튼이 살짝 커지며 떠오른다. 탭을 바꿀 때 버튼이 툭
/// 바뀌지 않게.
class _ActionsArrive extends StatefulWidget {
  const _ActionsArrive({required this.child});

  final Widget child;

  @override
  State<_ActionsArrive> createState() => _ActionsArriveState();
}

class _ActionsArriveState extends State<_ActionsArrive>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
  );
  CurvedAnimation? _t;
  DateTime? _played;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final move = context.motion.contentSwap;
    _t ??= CurvedAnimation(parent: _c, curve: move.curve);
    final at = TpArriveScope.freshOf(context);
    if (at == null || at == _played) return;
    _played = at;
    if (move.duration == Duration.zero) return;
    _c.duration = move.duration;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _t?.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t!;
    return FadeTransition(
      opacity: t,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.85, end: 1).animate(t),
        child: widget.child,
      ),
    );
  }
}

class _SmallBar extends SliverPersistentHeaderDelegate {
  _SmallBar({required this.height, required this.bar});

  final double height;
  final Widget bar;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(
        height: height,
        child: Align(alignment: Alignment.bottomCenter, child: bar),
      );

  @override
  bool shouldRebuild(_SmallBar old) => old.height != height || old.bar != bar;
}

/// 큰 제목 화면의 위 가장자리. 버튼만 있고 제목은 없다.
///
/// 배경은 바탕색에서 투명으로 번지는 띠다. 내용이 상태 막대·버튼 뒤로 지나갈
/// 때 글자가 겹쳐 읽히지 않게 할 만큼만. 띠는 탭을 받지 않는다.
class _GlassEdge extends SliverPersistentHeaderDelegate {
  _GlassEdge({
    required this.top,
    required this.color,
    this.leading,
    this.trailing,
  });

  final double top;
  final Color color;
  final Widget? leading;
  final Widget? trailing;

  static const double bar = TpTopBar.height;

  @override
  double get minExtent => top + bar;

  @override
  double get maxExtent => top + bar;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      Stack(
        fit: StackFit.expand,
        children: <Widget>[
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    color,
                    color.withValues(alpha: .85),
                    color.withValues(alpha: 0),
                  ],
                  stops: const <double>[0, .55, 1],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: top,
            height: bar,
            child: TpTopBar(
              safeTop: false,
              leading: leading,
              trailing: trailing,
            ),
          ),
        ],
      );

  @override
  bool shouldRebuild(_GlassEdge old) =>
      old.top != top ||
      old.color != color ||
      old.leading != leading ||
      old.trailing != trailing;
}

/// iOS 26 툴바 버튼. 44pt 유리 원, 글자면 유리 캡슐, 저장은 액센트 캡슐.
class TpBarButton extends StatelessWidget {
  const TpBarButton({super.key, required this.action});

  final TpBarAction action;

  @override
  Widget build(BuildContext context) {
    final button = _build(context);
    final coach = action.coach;
    return coach == null ? button : TpCoachTarget(id: coach, child: button);
  }

  Widget _build(BuildContext context) {
    final sys = context.sys;
    var a = action;
    // iOS 26 시트: "취소"는 X, "완료·저장"은 액센트 체크 원.
    if (context.tp.isGlass && a.role == TpBarRole.close) {
      a = TpBarAction(
        label: a.label,
        icon: CupertinoIcons.xmark,
        symbol: 'xmark',
        onTap: a.onTap,
        coach: a.coach,
      );
    } else if (context.tp.isGlass && a.role == TpBarRole.confirm) {
      final enabled = a.onTap != null;
      return Semantics(
        button: true,
        enabled: enabled,
        label: a.label,
        excludeSemantics: true,
        onTap: a.onTap,
        child: TpTappable(
          onTap: a.onTap,
          press: true,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : .4,
            duration: context.motion.press.duration,
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: TpSys.accent,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.checkmark,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      );
    }
    // iOS 26: 아이콘 버튼은 시스템 유리 버튼. 누르면 OS 가 유리를 눌러 준다 —
    // Flutter 가 플랫폼 뷰를 줄이는 것으로는 눌린 게 안 보였다.
    if (TpNativeGlass.enabled &&
        a.symbol != null &&
        a.menu == null &&
        !a.text &&
        !a.filled &&
        a.child == null) {
      return Semantics(
        button: true,
        label: a.label,
        excludeSemantics: true,
        onTap: a.onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: TpNativeIconButton(
            symbol: a.symbol!,
            onTap: a.onTap,
            tint: a.active ? TpSys.accent : null,
          ),
        ),
      );
    }
    // iOS 26: 메뉴 버튼은 시스템 유리 버튼 + UIMenu.
    if (TpNativeGlass.enabled && a.menu != null && a.symbol != null) {
      final menu = a.menu!;
      return SizedBox(
        width: 44,
        height: 44,
        child: TpNativeMenuButton(
          symbol: a.symbol!,
          label: a.label,
          tint: a.active ? TpSys.accent : null,
          entries: <TpNativeMenuEntry>[
            for (final m in menu)
              TpNativeMenuEntry(
                label: m.label,
                checked: m.checked,
                destructive: m.destructive,
              ),
          ],
          onSelected: (i) => menu[i].onTap(),
        ),
      );
    }
    final Widget face;
    if (a.filled) {
      face = Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TpSys.accent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          a.label,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );
    } else {
      final inner = a.text
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                widthFactor: 1,
                child: Text(
                  a.label,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: sys.label,
                  ),
                ),
              ),
            )
          : SizedBox(
              width: 44,
              child: Center(
                child:
                    a.child ??
                    Icon(
                      a.icon,
                      size: 20,
                      color: a.active ? TpSys.accent : sys.label,
                    ),
              ),
            );
      face = SizedBox(
        height: 44,
        child: TpNativeGlass.enabled
            ? TpNativeGlassSurface(radius: 22, capsule: true, child: inner)
            : TpSurface.chrome(radius: TpTokens.rControl, child: inner),
      );
    }
    Widget tappable(VoidCallback? onTap) => Semantics(
      button: true,
      label: a.label,
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(onTap: onTap, press: true, child: face),
    );
    if (a.menu != null) {
      return TpMenu(items: a.menu!, builder: (context, open) => tappable(open));
    }
    return tappable(a.onTap);
  }
}

/// 캡슐 버튼. 채움은 화면당 하나, 나머지는 tinted.
/// `plain` 은 바탕 없는 글자 버튼("비밀번호를 잊으셨나요?").
enum TpPillKind { filled, tinted, gray, plain }

class TpPill extends StatelessWidget {
  const TpPill({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = TpPillKind.filled,
    this.icon,
    this.height = 50,
    this.expand = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;

  /// 기다리는 중. 아이콘 자리에 돌림 표시가 뜨고 눌리지 않는다.
  final bool busy;
  final TpPillKind kind;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final (bg, fg) = switch (kind) {
      TpPillKind.filled => (TpSys.accent, Colors.white),
      TpPillKind.tinted => (sys.tint, sys.accentText),
      TpPillKind.gray => (sys.fill3, sys.label),
      TpPillKind.plain => (Colors.transparent, sys.accentText),
    };
    final disabled = onTap == null || busy;
    final move = context.motion.selection;
    // 종류가 바뀌면(담기 → 담김) 색은 번지고 아이콘은 튀어 들어온다.
    final face = AnimatedContainer(
      duration: move.duration,
      curve: move.curve,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: disabled && kind != TpPillKind.plain ? sys.fill3 : bg,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (busy) ...<Widget>[
            const TpLogoLoader(size: 18),
            const SizedBox(width: 8),
          ] else if (icon != null) ...<Widget>[
            AnimatedSwitcher(
              duration: move.duration,
              transitionBuilder: (child, a) => ScaleTransition(
                scale: a,
                child: FadeTransition(opacity: a, child: child),
              ),
              child: Icon(
                icon,
                key: ValueKey<IconData>(icon!),
                size: 18,
                color: disabled ? sys.label2 : fg,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: height >= 50 ? 17 : 15,
                fontWeight: FontWeight.w600,
                color: disabled ? sys.label2 : fg,
              ),
            ),
          ),
        ],
      ),
    );
    return Semantics(
      button: !disabled,
      label: label,
      excludeSemantics: true,
      onTap: busy ? null : onTap,
      child: TpTappable(onTap: busy ? null : onTap, press: true, child: face),
    );
  }
}

/// iOS 당겨서 새로고침: 시스템 스피너 대신 로고 로더. 당기는 동안은 당긴 만큼
/// 나타나고, 놓으면 돈다.
Widget _refreshMark(
  BuildContext context,
  RefreshIndicatorMode mode,
  double pulled,
  double trigger,
  double extent,
) {
  final shown = (pulled / trigger).clamp(0.0, 1.0);
  if (mode == RefreshIndicatorMode.inactive || shown == 0) {
    return const SizedBox.shrink();
  }
  return Center(
    child: Opacity(
      opacity: mode == RefreshIndicatorMode.drag ? shown : 1,
      child: const TpLogoLoader(size: 26),
    ),
  );
}

/// Android 당겨서 새로고침: M3 동작(당기기·튕기기)은 그대로, 원형 스피너
/// 자리에 로고 로더.
class _TpRefresh extends StatefulWidget {
  const _TpRefresh({required this.onRefresh, required this.child});

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<_TpRefresh> createState() => _TpRefreshState();
}

class _TpRefreshState extends State<_TpRefresh> {
  RefreshIndicatorStatus? _status;

  @override
  Widget build(BuildContext context) {
    final busy =
        _status == RefreshIndicatorStatus.armed ||
        _status == RefreshIndicatorStatus.snap ||
        _status == RefreshIndicatorStatus.refresh;
    return Stack(
      children: <Widget>[
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: (s) {
            if (mounted && s != _status) setState(() => _status = s);
          },
          child: widget.child,
        ),
        Positioned(
          top: MediaQuery.paddingOf(context).top + 72,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedOpacity(
              opacity: busy ? 1 : 0,
              duration: context.motion.selection.duration,
              child: const Center(child: TpLogoLoader(size: 26)),
            ),
          ),
        ),
      ],
    );
  }
}
