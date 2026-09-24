import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/shell/tp_tab_bar.dart';
import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../copy_keys.dart';
import 'tp_group.dart';
import 'tp_menu.dart';
import 'tp_surface.dart';

/// 툴바 버튼 하나.
class TpBarAction {
  const TpBarAction({
    required this.label,
    this.icon,
    this.onTap,
    this.text = false,
    this.filled = false,
    this.child,
    this.menu,
  });

  /// 스크린 리더 이름. [text] 면 화면에도 이 글자가 나온다.
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  /// 아이콘 대신 글자 캡슐("완료", "취소").
  final bool text;

  /// 액센트로 채운 캡슐("저장").
  final bool filled;

  /// 아이콘 자리에 직접 그릴 것(프로필 이니셜 원).
  final Widget? child;

  /// 있으면 누를 때 풀다운 메뉴가 열린다.
  final List<TpMenuItem>? menu;
}

/// v3 화면 뼈대. large title 이 스크롤하면 줄어드는 표준 네비게이션 바 위에
/// 슬리버 목록을 올린다.
///
/// iOS 는 `CupertinoSliverNavigationBar`: 맨 위에서는 바 배경이 없고, 내용이
/// 밑으로 지나가기 시작하면 배경과 작은 제목이 나타난다. Android 는
/// `SliverAppBar.large`.
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
    final bottom =
        safe.bottom +
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
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Text(
                subtitle!,
                style: TextStyle(fontSize: 15, height: 1.33, color: sys.label2),
              ),
            ),
          ),
        if (onRefresh != null && glass)
          CupertinoSliverRefreshControl(onRefresh: onRefresh),
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
                  child: onRefresh != null && !glass
                      ? RefreshIndicator(onRefresh: onRefresh!, child: body)
                      : body,
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
              onTap: onBack,
            ),
          )
        : (leading == null ? null : TpBarButton(action: leading!));
    final trail = actions.isEmpty
        ? null
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              for (var i = 0; i < actions.length; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 8),
                TpBarButton(action: actions[i]),
              ],
            ],
          );
    final titleText = Text(title);
    if (!largeTitle) {
      final top = MediaQuery.paddingOf(context).top;
      return SliverPersistentHeader(
        pinned: true,
        delegate: _SmallBar(
          height: top + 52,
          bar: CupertinoNavigationBar(
            middle: titleText,
            leading: lead,
            trailing: trail,
            automaticallyImplyLeading: false,
            automaticallyImplyMiddle: false,
            transitionBetweenRoutes: false,
            border: null,
            backgroundColor: sys.background.withValues(alpha: .92),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
          ),
        ),
      );
    }
    return CupertinoSliverNavigationBar(
      largeTitle: titleText,
      middle: titleText,
      alwaysShowMiddle: false,
      leading: lead,
      trailing: trail,
      automaticallyImplyLeading: false,
      automaticallyImplyTitle: false,
      transitionBetweenRoutes: false,
      border: null,
      backgroundColor: sys.background.withValues(alpha: .92),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
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
              : TextButton(
                  onPressed: leading!.onTap,
                  child: Text(leading!.label),
                ));
    final acts = <Widget>[
      for (final a in actions)
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
      const SizedBox(width: 4),
    ];
    if (!largeTitle) {
      return SliverAppBar(
        pinned: true,
        title: Text(title),
        leading: back,
        automaticallyImplyLeading: false,
        actions: acts,
      );
    }
    return SliverAppBar.large(
      title: Text(title),
      leading: back,
      automaticallyImplyLeading: false,
      actions: acts,
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

/// iOS 26 툴바 버튼. 44pt 유리 원, 글자면 유리 캡슐, 저장은 액센트 캡슐.
class TpBarButton extends StatelessWidget {
  const TpBarButton({super.key, required this.action});

  final TpBarAction action;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final a = action;
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
                child: a.child ?? Icon(a.icon, size: 20, color: sys.label),
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
enum TpPillKind { filled, tinted, gray }

class TpPill extends StatelessWidget {
  const TpPill({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = TpPillKind.filled,
    this.icon,
    this.height = 50,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onTap;
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
    };
    final disabled = onTap == null;
    final face = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: disabled ? sys.fill3 : bg,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: disabled ? sys.label2 : fg),
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
      onTap: onTap,
      child: TpTappable(onTap: onTap, press: true, child: face),
    );
  }
}
