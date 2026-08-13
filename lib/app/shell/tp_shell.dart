import '../theme/tp_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../theme/tp_tokens.dart';
import '../theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import 'tp_tab.dart';

/// 화면이 크롬을 얼마나 쓰는지.
enum TpChromeMode {
  /// 헤더 + 탭 바. 대부분의 화면.
  full,

  /// 크롬 없이 콘텐츠만. 온보딩·로그인.
  plain,

  /// 상태 바 아래까지 콘텐츠가 올라오는 전면 인수 화면. 스캔·3D 뷰어.
  takeover,
}

/// 헤더 오른쪽 버튼.
///
/// 크롬마다 다르게 그린다 — iOS 는 뒤로 버튼과 같은 유리 알약, Android 는
/// 앱 바 액션. 화면은 무엇을 누르면 무엇이 되는지만 넘긴다.
class TpShellAction {
  const TpShellAction({required this.icon, required this.label, this.onTap});

  final IconData icon;

  /// 스크린 리더가 읽을 이름. 아이콘만 있는 버튼이라 없으면 안 된다.
  final String label;

  final VoidCallback? onTap;
}

/// 두 플랫폼 크롬을 한 위젯에서 처리한다.
///
/// 지오메트리는 `docs/DESIGN_HANDOFF.md` — Chrome geometry 표를 따른다.
/// 프로토타입은 고정 프레임(iOS 402×874, Android 412×892)에 상태 바 높이를
/// 상수로 박아뒀지만, 실제 기기는 노치·홈 인디케이터가 제각각이라 그 상수 대신
/// [MediaQuery] 의 안전 영역을 쓴다. 명세의 숫자는 안전 영역 **바깥에서부터의
/// 여백**으로 환산했다.
class TpShell extends StatelessWidget {
  const TpShell({
    super.key,
    required this.child,
    this.title,
    this.tab,
    this.mode = TpChromeMode.full,
    this.onBack,
    this.onTabSelected,
    this.trailing,
    this.floatingAction,
    this.extraBottomInset = 0,
  });

  final Widget child;

  /// 축소 헤더에 들어가는 제목. iOS 는 유리 알약, Android 는 app bar.
  final String? title;

  /// 현재 탭. null 이면 탭 바를 그리지 않는다(푸시된 화면).
  final TpTab? tab;

  final TpChromeMode mode;
  final VoidCallback? onBack;
  final ValueChanged<TpTab>? onTabSelected;

  /// 헤더 오른쪽 버튼. 지금은 상세의 공유가 유일하다.
  final TpShellAction? trailing;

  /// Android 확장 FAB. iOS 는 콘텐츠 안 인라인 버튼을 쓰므로 무시한다.
  final Widget? floatingAction;

  /// Ask 화면처럼 입력 바가 더 필요한 경우.
  final double extraBottomInset;

  static const double _iosTabHeight = 62;
  static const double _iosTabGap = 10;
  static const double _iosHeaderScrim = 106;
  static const double _iosContentTop = 60;

  static const double _androidTabHeight = 78;
  static const double _androidAppBar = 64;
  static const double _androidLargeTitle = 88;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return DecoratedBox(
      decoration: t.pageBackground,
      // Ink 계열 위젯(InkWell, IconButton)이 Material 조상을 요구한다.
      // 배경은 위 DecoratedBox 가 그리므로 여기서는 투명하게 둔다.
      child: Material(
        type: MaterialType.transparency,
        child: t.isGlass ? _buildIos(context) : _buildAndroid(context),
      ),
    );
  }

  // ── iOS 26 Liquid Glass ──────────────────────────────────────
  Widget _buildIos(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final safe = MediaQuery.viewPaddingOf(context);
    final showChrome = mode == TpChromeMode.full;
    final takeover = mode == TpChromeMode.takeover;

    final topInset = switch (mode) {
      TpChromeMode.full => safe.top + _iosContentTop,
      TpChromeMode.plain => safe.top + 12,
      TpChromeMode.takeover => 0.0,
    };
    final tabBottom = safe.bottom + _iosTabGap;
    final bottomInset = takeover
        ? safe.bottom
        : (tab != null ? tabBottom + _iosTabHeight + 16 : safe.bottom + 24) +
              extraBottomInset;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            child: child,
          ),
        ),

        // 헤더 스크림. 콘텐츠가 상태 바 아래로 스크롤될 때 글자가 겹치지 않게 한다.
        if (showChrome)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _iosHeaderScrim,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFFEEF3FA).withValues(alpha: 0.92),
                      const Color(0xFFEEF3FA).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),

        if (showChrome && (onBack != null || title != null || trailing != null))
          Positioned(
            top: safe.top,
            left: 12,
            right: 12,
            // 유리 알약은 명세대로 42 로 그리고, 히트 영역만 48 을 채운다.
            height: 48,
            child: Row(
              children: <Widget>[
                if (onBack != null)
                  TpTapTarget(
                    onTap: onBack,
                    label: K.back.tr(),
                    child: const TpSurface(
                      strong: true,
                      radius: TpTokens.rControl,
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.chevron_left, size: 24),
                      ),
                    ),
                  )
                // 오른쪽에만 버튼이 있으면 제목이 왼쪽으로 밀린다.
                else if (trailing != null && title != null)
                  const SizedBox(width: 48),
                // 제목이 없는 화면(상세)은 밀어줄 것이 없어 오른쪽 버튼이
                // 왼쪽에 붙는다.
                if (title == null && trailing != null) const Spacer(),
                if (title != null) ...<Widget>[
                  const Spacer(),
                  TpSurface(
                    strong: true,
                    radius: TpTokens.rControl,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 11,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const _AppMark(width: 13, height: 19),
                        const SizedBox(width: 8),
                        Text(title!, style: type.appBarTitle),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
                if (trailing != null)
                  TpTapTarget(
                    onTap: trailing!.onTap,
                    label: trailing!.label,
                    child: TpSurface(
                      strong: true,
                      radius: TpTokens.rControl,
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(trailing!.icon, size: 22),
                      ),
                    ),
                  )
                // 뒤로 버튼과 좌우 균형을 맞춘다.
                else if (onBack != null && title != null)
                  const SizedBox(width: 48),
              ],
            ),
          ),

        if (tab != null)
          Positioned(
            left: 12,
            right: 12,
            bottom: tabBottom,
            height: _iosTabHeight,
            child: TpSurface(
              strong: true,
              radius: TpTokens.rControl,
              child: _IosTabBar(
                current: tab!,
                onSelected: onTabSelected,
                tokens: t,
                type: type,
              ),
            ),
          ),
      ],
    );
  }

  // ── Android Material 3 ───────────────────────────────────────
  Widget _buildAndroid(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final safe = MediaQuery.viewPaddingOf(context);
    final showChrome = mode == TpChromeMode.full;
    final takeover = mode == TpChromeMode.takeover;

    final headerHeight = title == null
        ? _androidAppBar
        : _androidAppBar + _androidLargeTitle;
    final topInset = switch (mode) {
      TpChromeMode.full => safe.top + headerHeight,
      TpChromeMode.plain => safe.top + 12,
      TpChromeMode.takeover => 0.0,
    };
    final bottomInset = takeover
        ? safe.bottom
        : (tab != null
                  ? _androidTabHeight + safe.bottom + 12
                  : safe.bottom + 24) +
              extraBottomInset;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.only(top: topInset, bottom: bottomInset),
            child: child,
          ),
        ),

        if (showChrome)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: TpTokens.androidBarBg,
              padding: EdgeInsets.only(top: safe.top),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    height: _androidAppBar,
                    child: Row(
                      children: <Widget>[
                        const SizedBox(width: 4),
                        if (onBack != null)
                          IconButton(
                            onPressed: onBack,
                            tooltip: K.back.tr(),
                            icon: const Icon(Icons.arrow_back),
                          )
                        else
                          const Padding(
                            padding: EdgeInsets.only(left: 12),
                            child: _AppMark(width: 16, height: 22),
                          ),
                        if (trailing != null) ...<Widget>[
                          const Spacer(),
                          IconButton(
                            onPressed: trailing!.onTap,
                            tooltip: trailing!.label,
                            icon: Icon(trailing!.icon),
                          ),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),
                  if (title != null)
                    SizedBox(
                      height: _androidLargeTitle,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(title!, style: type.largeAppBarTitle),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

        if (floatingAction != null)
          Positioned(
            right: 16,
            bottom:
                (tab != null ? _androidTabHeight + safe.bottom : safe.bottom) +
                16,
            child: floatingAction!,
          ),

        if (tab != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              color: TpTokens.tabBarFill,
              padding: EdgeInsets.only(bottom: safe.bottom),
              height: _androidTabHeight + safe.bottom,
              child: _AndroidTabBar(
                current: tab!,
                onSelected: onTabSelected,
                tokens: t,
                type: type,
              ),
            ),
          ),
      ],
    );
  }
}

/// 활성 탭이 파란 알약으로 채워지는 iOS 캡슐 바.
class _IosTabBar extends StatelessWidget {
  const _IosTabBar({
    required this.current,
    required this.onSelected,
    required this.tokens,
    required this.type,
  });

  final TpTab current;
  final ValueChanged<TpTab>? onSelected;
  final TpTokens tokens;
  final TpTypography type;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    return Row(
      children: TpTab.values.map((TpTab t) {
        final active = t == current;
        return Expanded(
          child: Semantics(
            button: true,
            selected: active,
            label: K.tab(t).tr(),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSelected == null ? null : () => onSelected!(t),
              child: Center(
                child: AnimatedContainer(
                  duration: motion.selection.duration,
                  curve: motion.selection.curve,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: active ? TpTokens.blue : Colors.transparent,
                    borderRadius: BorderRadius.circular(TpTokens.rControl),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(
                        active ? t.activeIcon : t.icon,
                        size: 22,
                        color: active ? Colors.white : tokens.dim,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        K.tab(t).tr(),
                        // 라벨이 두 줄이 되면 캡슐(62)을 넘긴다. 명세가 높이를
                        // 고정해서 늘릴 수 없다.
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.tabLabel.copyWith(
                          color: active ? Colors.white : tokens.dim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 활성 탭이 색으로만 표시되는 Android 고정 바.
class _AndroidTabBar extends StatelessWidget {
  const _AndroidTabBar({
    required this.current,
    required this.onSelected,
    required this.tokens,
    required this.type,
  });

  final TpTab current;
  final ValueChanged<TpTab>? onSelected;
  final TpTokens tokens;
  final TpTypography type;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TpTab.values.map((TpTab t) {
        final active = t == current;
        final color = active ? TpTokens.blue : tokens.dim;
        return Expanded(
          child: InkWell(
            onTap: onSelected == null ? null : () => onSelected!(t),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(active ? t.activeIcon : t.icon, size: 24, color: color),
                const SizedBox(height: 4),
                Text(
                  K.tab(t).tr(),
                  style: type.tabLabel.copyWith(color: color),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// 헤더의 앱 마크.
///
/// 명세 Assets 표가 크기를 못박았다 — iOS 13×19, Android 16×22.
/// 장식이라 스크린 리더에서는 뺀다. 제목이 바로 옆에 있다.
class _AppMark extends StatelessWidget {
  const _AppMark({required this.width, required this.height});

  static const String asset = 'assets/logo/NBlogo_black.png';

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
    ),
  );
}
