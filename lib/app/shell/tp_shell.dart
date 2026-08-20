import '../theme/tp_motion.dart';
import '../theme/tp_native_glass.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../theme/tp_tokens.dart';
import '../theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import 'tp_tab.dart';
import '../../shared/widgets/tp_press.dart';

/// 셸이 크롬에 내준 자리.
///
/// 탭 화면은 콘텐츠가 크롬 아래로 흐른다 — 유리는 뒤에 뭔가 지나가야 유리다.
/// 대신 스크롤 뷰가 이걸 자기 패딩에 더해야 마지막 항목이 탭 바 뒤에 숨지
/// 않는다.
EdgeInsets tpContentInset(BuildContext context) =>
    MediaQuery.paddingOf(context);

/// 셸이 위아래에 낸 자리를 **어떻게** 냈는지까지 알려준다.
///
/// 두 크롬이 같은 숫자를 다른 방법으로 낸다. 유리는 콘텐츠를 크롬 뒤로
/// 흘려보내고 [MediaQuery.padding] 으로 **알려만** 주고, 안드로이드는 진짜
/// [Padding] 으로 **이미 비운다**. 대부분의 화면은 [tpContentInset] 하나면
/// 되는데, 키보드를 피해야 하는 화면은 둘을 구분해야 한다 — 알려만 준 자리는
/// 키보드가 올라오면 다시 쓸 수 있고(그 아래 탭 바는 어차피 키보드에 가린다),
/// 이미 비운 자리는 애초에 우리 것이 아니다.
///
/// 이게 없을 때 상담 화면의 입력 바가 키보드 위 122pt 에 떠 있었다.
class TpChromeInsets extends InheritedWidget {
  const TpChromeInsets({
    super.key,
    required this.advisory,
    required this.physical,
    required super.child,
  });

  /// MediaQuery 로만 알려준 자리. 콘텐츠가 그 아래로 흐른다.
  final EdgeInsets advisory;

  /// 패딩으로 이미 비워 둔 자리.
  final EdgeInsets physical;

  static const TpChromeInsets zero = TpChromeInsets(
    advisory: EdgeInsets.zero,
    physical: EdgeInsets.zero,
    child: SizedBox.shrink(),
  );

  static TpChromeInsets of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpChromeInsets>() ?? zero;

  @override
  bool updateShouldNotify(TpChromeInsets old) =>
      advisory != old.advisory || physical != old.physical;
}

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

  static const double iosTabHeight = 62;

  /// 고른 탭 알약. 명세 프로토타입이 48 을 준다.
  static const double iosTabPill = 48;
  static const double _iosTabGap = 10;
  static const double _iosHeaderScrim = 106;
  static const double _iosContentTop = 60;

  static const double _androidTabHeight = 78;

  /// FAB 가 가리는 만큼 콘텐츠 아래를 더 비운다.
  ///
  /// 명세 Chrome geometry 의 Android content padding-bottom 이 그렇게 적혀
  /// 있다 — 90(보통) / 164(FAB 있음). 이걸 안 빼면 목록 끝의 문구가 FAB
  /// 뒤에 영영 숨는다.
  static const double _androidFabInset = 74;
  static const double _androidAppBar = 64;
  static const double _androidLargeTitle = 88;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 배경이 어두워지면 시계와 배터리도 같이 뒤집혀야 한다. 안 하면
      // 검은 글자가 검은 배경 위에 남는다.
      value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: DecoratedBox(
        decoration: t.pageBackground,
        // Ink 계열 위젯(InkWell, IconButton)이 Material 조상을 요구한다.
        // 배경은 위 DecoratedBox 가 그리므로 여기서는 투명하게 둔다.
        child: Material(
          type: MaterialType.transparency,
          child: t.isGlass ? _buildIos(context) : _buildAndroid(context),
        ),
      ),
    );
  }

  /// 콘텐츠에 크롬 자리를 어떻게 줄지.
  ///
  /// **탭 화면만 크롬 아래로 흐른다.** 유리는 뒤에 뭔가 지나가야 유리이므로
  /// 자리를 패딩으로 막지 않고 [MediaQuery] 로 알려주고, 화면들이 자기 스크롤
  /// 패딩에 더한다.
  ///
  /// 나머지(plain·takeover)는 뒤로 지나갈 크롬이 없다. 그런데도 한동안 같은
  /// 규칙을 썼더니, 인셋을 안 읽는 화면 여섯 곳이 상태 바 아래에서 시작했다 —
  /// 온보딩의 "건너뛰기"가 배터리 아이콘과 겹쳤다. 그쪽은 자리를 그냥 비운다.
  Widget _content(
    BuildContext context, {
    required double top,
    required double bottom,
    required Widget child,
  }) {
    // 안드로이드 크롬은 불투명하다. 뒤로 지나가는 것이 안 보이므로 흐르게 할
    // 이유가 없다 — 자리를 그냥 비운다.
    final inset = EdgeInsets.only(top: top, bottom: bottom);

    if (mode == TpChromeMode.full && context.tp.isGlass) {
      return TpChromeInsets(
        advisory: inset,
        physical: EdgeInsets.zero,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: inset),
          child: child,
        ),
      );
    }
    return TpChromeInsets(
      advisory: EdgeInsets.zero,
      physical: inset,
      child: MediaQuery(
        // 패딩으로 이미 비웠다. 그대로 두면 인셋을 읽는 화면이 두 번 비운다.
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
        child: Padding(padding: inset, child: child),
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
        // 인수 화면은 위아래로 화면을 통째로 쓴다. 여기서 안전 영역을 비우면
        // 어두운 화면 아래로 밝은 배경이 띠처럼 남는다. 스캔·뷰어는 자기
        // 컨트롤에 안전 영역을 직접 더한다.
        ? 0.0
        : (tab != null ? tabBottom + iosTabHeight + 16 : safe.bottom + 24);

    return Stack(
      children: <Widget>[
        // 인셋을 패딩으로 주면 콘텐츠가 크롬 **위쪽에서 잘린다** — 유리 뒤로
        // 지나가는 것이 없으니 아무리 흐려도 밝은 알약으로만 보인다. 그래서
        // 자리를 통째로 주고 인셋은 MediaQuery 로 넘긴다. 화면들은 그걸
        // 자기 스크롤 패딩에 더해 마지막 항목이 안 가리게 한다.
        Positioned.fill(
          child: _content(
            context,
            top: topInset,
            bottom: bottomInset,
            child: _TabBody(tab: tab, child: child),
          ),
        ),

        // 헤더 스크림. 콘텐츠가 상태 바 아래로 스크롤될 때 글자가 겹치지 않게 한다.
        //
        // 위쪽 안전 영역까지는 **불투명**이다. 처음에는 위에서부터 .92 로
        // 옅어지게 뒀는데, 시계 높이에서 알파가 .7 이라 큰 제목이 시계를
        // 뚫고 올라왔다. 스크롤한 홈에서 "오늘"과 5:57 이 겹쳤다.
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
                      t.scrim,
                      t.scrim,
                      t.scrim.withValues(alpha: 0),
                    ],
                    stops: <double>[
                      0,
                      (safe.top / _iosHeaderScrim).clamp(0.0, 0.9),
                      1,
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
                    child: const TpSurface.chrome(
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
                  TpSurface.chrome(
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
                    child: TpSurface.chrome(
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
            // 시스템 바는 자기 여백을 스스로 잡는다. 우리가 좌우 12 를 또
            // 물리면 그 안쪽으로 한 번 더 들어가 좁고 붕 뜬 바가 된다.
            left: TpNativeGlass.enabled ? 0 : 12,
            right: TpNativeGlass.enabled ? 0 : 12,
            // 시스템 바는 홈 인디케이터 바로 위에 앉는다. 명세의 44pt 는
            // 우리가 그리는 알약 바의 값이다.
            bottom: TpNativeGlass.enabled ? safe.bottom : tabBottom,
            height: TpNativeGlass.enabled
                ? iosTabHeight + TpNativeTabBar.overflow
                : iosTabHeight,
            child: TpNativeGlass.enabled
                ? TpNativeTabBar(
                    index: TpTab.values.indexOf(tab!),
                    onSelected: onTabSelected == null
                        ? null
                        : (i) => onTabSelected!(TpTab.values[i]),
                    height: iosTabHeight,
                    tint: TpTokens.blue,
                    // 아이콘 크기도 라벨 타이포도 안 넘긴다. 우리 값을 얹는
                    // 순간 간격이 어긋난다 — 28pt 아이콘은 라벨을 덮었다.
                    // 시스템 바의 간격은 UIKit 이 잡게 둔다.
                    items: <TpNativeTabItem>[
                      for (final t in TpTab.values)
                        TpNativeTabItem(
                          label: K.tab(t).tr(),
                          symbol: t.symbol,
                          activeSymbol: t.activeSymbol,
                        ),
                    ],
                  )
                : TpSurface.chrome(
                    raised: true,
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
        ? 0.0
        : (tab != null
                  ? _androidTabHeight + safe.bottom + 12
                  : safe.bottom + 24) +
              (floatingAction != null ? _androidFabInset : 0);

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: _content(
            context,
            top: topInset,
            bottom: bottomInset,
            child: _TabBody(tab: tab, child: child),
          ),
        ),

        if (showChrome)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: t.chromeFill,
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
              color: t.tabBar,
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
    return LayoutBuilder(
      builder: (context, box) {
        final tabs = TpTab.values;
        final cell = box.maxWidth / tabs.length;
        final index = tabs.indexOf(current);

        return Stack(
          children: <Widget>[
            // 알약은 한 장뿐이고 칸에서 칸으로 미끄러진다. 칸마다 따로 그려
            // 색만 교차시키던 때는 아무것도 움직이지 않아 툭 바뀌는 것처럼
            // 보였다. 명세 프로토타입도 알약이 칸을 꽉 채운다(flex:1, 48).
            AnimatedPositioned(
              key: const ValueKey<String>('tab-pill'),
              duration: motion.selection.duration,
              curve: motion.selection.curve,
              left: index * cell,
              width: cell,
              top: (TpShell.iosTabHeight - TpShell.iosTabPill) / 2,
              height: TpShell.iosTabPill,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                // 고른 알약도 유리다. iOS 26 의 탭 바는 알약과 바가 같은
                // 재질이고, 여기만 불투명 파랑이면 유리 위에 스티커를 붙인
                // 것처럼 보인다. 파랑은 색이 아니라 **틴트**로 들어간다.
                //
                // 바와 하나로 합쳐지지는(glassEffectUnion) 않는다 — 플랫폼
                // 뷰마다 네임스페이스가 따로라 그건 한 컨테이너 안에서만 된다.
                child: TpNativeGlass.enabled
                    ? TpNativeGlassSurface(
                        radius: TpTokens.rControl,
                        capsule: true,
                        tint: TpTokens.blue,
                        // 누르는 것은 그 아래 탭 항목이다. 알약은 장식이다.
                        interactive: false,
                        child: const SizedBox.expand(),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: TpTokens.blue,
                          borderRadius: BorderRadius.circular(
                            TpTokens.rControl,
                          ),
                        ),
                      ),
              ),
            ),
            Row(
              children: tabs.map((TpTab t) {
                final active = t == current;
                final color = active ? Colors.white : tokens.chromeDim;
                return Expanded(
                  child: Semantics(
                    button: onSelected != null,
                    selected: active,
                    label: K.tab(t).tr(),
                    // excludeSemantics 는 안쪽 글자와 **함께 탭 액션도**
                    // 지운다. 그래서 보이스오버가 "탭, 버튼"이라고 읽어주고
                    // 두 번 눌러도 아무 일이 없었다 — 탭을 바꿀 수가 없었다.
                    onTap: onSelected == null ? null : () => onSelected!(t),
                    excludeSemantics: true,
                    child: TpPress(
                      semanticsButton: false,
                      onTap: onSelected == null ? null : () => onSelected!(t),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            // 알약이 지나가는 동안 글자·아이콘 색도 같이 넘어간다.
                            TweenAnimationBuilder<Color?>(
                              tween: ColorTween(end: color),
                              duration: motion.selection.duration,
                              curve: motion.selection.curve,
                              builder: (context, value, _) => Icon(
                                active ? t.activeIcon : t.icon,
                                size: 22,
                                color: value,
                              ),
                            ),
                            const SizedBox(height: 2),
                            AnimatedDefaultTextStyle(
                              duration: motion.selection.duration,
                              curve: motion.selection.curve,
                              // 라벨이 두 줄이 되면 캡슐(62)을 넘긴다. 명세가
                              // 높이를 고정해서 늘릴 수 없다.
                              style: type.tabLabel.copyWith(color: color),
                              child: Text(
                                K.tab(t).tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
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
        final move = context.motion.selection;
        return Expanded(
          child: InkWell(
            onTap: onSelected == null ? null : () => onSelected!(t),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // iOS 는 알약이 180ms 로 차오르는데 여기는 색이 툭 바뀌었다.
                // 같은 동작이 두 크롬에서 정반대로 보였다.
                AnimatedSwitcher(
                  duration: move.duration,
                  switchInCurve: move.curve,
                  child: Icon(
                    active ? t.activeIcon : t.icon,
                    key: ValueKey<bool>(active),
                    size: 24,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: move.duration,
                  curve: move.curve,
                  style: type.tabLabel.copyWith(color: color),
                  child: Text(K.tab(t).tr()),
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

/// 지금 보고 있는 탭. [TabHost] 가 알려주고 셸이 듣는다.
class TpActiveTab extends InheritedWidget {
  const TpActiveTab({super.key, required this.tab, required super.child});

  final TpTab tab;

  static TpTab? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpActiveTab>()?.tab;

  @override
  bool updateShouldNotify(TpActiveTab old) => old.tab != tab;
}

/// 탭 본문이 들어올 때의 전환.
///
/// 탭 알약은 칸에서 칸으로 미끄러지는데 그 아래 본문은 툭 갈렸다. 한 동작
/// 안에서 한쪽만 움직이면 나머지가 고장 난 것처럼 읽힌다.
///
/// M3 의 fade-through 와 같은 모양이다: 나가는 것은 안 보여주고 **들어오는
/// 것**만 옅게·조금 작게 시작해 제자리로 온다.
///
/// **크롬은 안 움직인다.** 셸 안쪽에서 콘텐츠만 감싸기 때문이다 — 바깥에서
/// 화면을 통째로 감싸면 탭 캡슐까지 같이 줄었다 커진다.
class _TabBody extends StatefulWidget {
  const _TabBody({required this.tab, required this.child});

  /// 이 셸이 그리는 탭. null 이면(상세·스캔·뷰어) 아무것도 안 한다.
  final TpTab? tab;

  final Widget child;

  @override
  State<_TabBody> createState() => _TabBodyState();
}

class _TabBodyState extends State<_TabBody>
    with SingleTickerProviderStateMixin {
  // late final 로 두면 안 된다. 탭이 아닌 셸(상세·스캔·뷰어)은 build 가 먼저
  // 빠져나가서 dispose 가 **첫 접근**이 되고, 그때는 트리가 이미 떨어져 나가
  // TickerMode 를 못 찾는다.
  late final AnimationController _c;

  TpTab? _active;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1),
      value: 1,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = TpActiveTab.maybeOf(context);
    final was = _active;
    _active = active;

    // 처음 붙을 때는 안 움직인다. 앱을 켜자마자 홈이 커지며 나타나면
    // 화면이 한 번 튄 것처럼 보인다.
    if (was == null || active == was) return;
    if (widget.tab == null || active != widget.tab) return;

    final move = context.motion.contentSwap;
    if (move.duration == Duration.zero) return;
    _c.duration = move.duration;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.tab == null) return widget.child;

    final curve = CurvedAnimation(
      parent: _c,
      curve: context.motion.contentSwap.curve,
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final t = curve.value;
        if (t == 1) return child!;
        return Opacity(
          opacity: t,
          // 96% 에서 시작한다. 더 줄이면 목록이 크게 튀어 보이고, 안 줄이면
          // 페이드만 남아 어디서 온 건지 안 읽힌다.
          child: Transform.scale(scale: 0.96 + 0.04 * t, child: child),
        );
      },
      child: widget.child,
    );
  }
}
