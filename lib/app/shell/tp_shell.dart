import '../theme/tp_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../theme/tp_tokens.dart';
import '../theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import 'tp_tab.dart';
import 'tp_tab_bar.dart';
import 'tp_window.dart';
import '../theme/tp_icons.dart';

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
    this.trailing,
    this.floatingAction,
    this.scrollTitle,
  });

  final Widget child;

  /// 축소 헤더에 들어가는 제목. iOS 는 유리 알약, Android 는 app bar.
  final String? title;

  /// 현재 탭. null 이면 푸시된 화면이다. 탭 바는 [TabHost] 가 그리고 셸은 자리만 비운다.
  final TpTab? tab;

  final TpChromeMode mode;
  final VoidCallback? onBack;

  /// 헤더 오른쪽 버튼. 지금은 상세의 공유가 유일하다.
  final TpShellAction? trailing;

  /// Android 확장 FAB. iOS 는 콘텐츠 안 인라인 버튼을 쓰므로 무시한다.
  final Widget? floatingAction;

  /// iOS 에서 큰 제목이 콘텐츠 안에 있는 화면의 제목.
  ///
  /// 큰 제목이 스크롤로 사라지면 헤더 알약에 작은 제목으로 떠오른다. 안
  /// 그러면 스크롤한 홈은 이름 없는 화면이 된다. [title] 이 있으면 무시한다.
  final String? scrollTitle;

  /// 큰 제목(34pt)이 헤더 밑으로 다 들어갔다고 보는 스크롤 양.
  static const double _scrollTitleAfter = 44;

  static const double _iosHeaderScrim = 106;
  static const double _iosContentTop = 60;

  static const double _androidTabHeight = TpTabBar.androidHeight;

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
          child: TpReselect(
            tab: tab,
            onReselect: _scrollToTop,
            child: Builder(
              builder: (context) =>
                  t.isGlass ? _buildIos(context) : _buildAndroid(context),
            ),
          ),
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
    final body = _column(context, child);

    if (mode == TpChromeMode.full && context.tp.isGlass) {
      return TpChromeInsets(
        advisory: inset,
        physical: EdgeInsets.zero,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(padding: inset),
          child: body,
        ),
      );
    }
    return TpChromeInsets(
      advisory: EdgeInsets.zero,
      physical: inset,
      child: MediaQuery(
        // 패딩으로 이미 비웠다. 그대로 두면 인셋을 읽는 화면이 두 번 비운다.
        data: MediaQuery.of(context).copyWith(padding: EdgeInsets.zero),
        child: Padding(padding: inset, child: body),
      ),
    );
  }

  /// 넓은 창에서 본문을 가운데 한 칸으로 묶는다.
  ///
  /// 이 앱의 화면들은 폰 프레임만 보고 만들어졌고 최대 폭 제약이 하나도
  /// 없다. 1440pt 짜리 창에서는 전부 그냥 늘어난다 — 상담 말풍선이 1098pt
  /// 슬래브가 되고 랭킹 행은 이름과 값 사이가 1200pt 벌어진다.
  ///
  /// **여기 한 곳에서만 한다.** 화면 본문이 전부 이 목을 지나고, 전체 폭에
  /// `Positioned` 로 그리던 셋(상담 컴포저·비교 고정 버튼·뷰어 컨트롤)도
  /// 자기 화면의 `Stack` 안에 있어서 같이 좁혀진다.
  ///
  /// `takeover` 는 그냥 둔다 — 스캐너와 3D 뷰어는 창을 다 써야 한다.
  Widget _column(BuildContext context, Widget child) {
    if (mode == TpChromeMode.takeover) return child;
    if (tpWindowClass(context) == TpWindowClass.compact) return child;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: tpContentMaxWidth),
        child: child,
      ),
    );
  }

  /// 이 화면의 목록을 맨 위로 올린다. 상태 바를 누르거나 지금 탭을 다시
  /// 누를 때. iOS 에서는 Scaffold 가 해주던 일인데 이 앱은 Scaffold 가 없다.
  static void _scrollToTop(BuildContext context) {
    final controller = PrimaryScrollController.maybeOf(context);
    if (controller == null) return;
    final move = context.motion.reveal;
    for (final position in controller.positions.toList()) {
      if (move.duration == Duration.zero) {
        position.jumpTo(0);
      } else {
        position.animateTo(
          0,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  /// [past] 가 있으면 켜질 때만 보인다. 숨은 동안은 트리에 없다 — 누를
  /// 수도, 스크린 리더가 큰 제목과 두 번 읽을 수도 없다.
  Widget _fadeIn(
    BuildContext context,
    ValueListenable<bool>? past,
    Widget child,
  ) {
    if (past == null) return child;
    final move = context.motion.selection;
    return ValueListenableBuilder<bool>(
      valueListenable: past,
      child: child,
      builder: (context, shown, child) => AnimatedSwitcher(
        duration: move.duration,
        switchInCurve: move.curve,
        switchOutCurve: move.curve,
        child: shown ? child : const SizedBox.shrink(),
      ),
    );
  }

  // ── iOS 26 Liquid Glass ──────────────────────────────────────
  Widget _buildIos(BuildContext context) {
    if (title == null && scrollTitle != null && mode == TpChromeMode.full) {
      return _ScrollPast(
        after: _scrollTitleAfter,
        builder: (context, past) => _buildIosChrome(context, past),
      );
    }
    return _buildIosChrome(context, null);
  }

  Widget _buildIosChrome(BuildContext context, ValueListenable<bool>? past) {
    final t = context.tp;
    final type = context.tpText;
    final safe = MediaQuery.viewPaddingOf(context);
    final showChrome = mode == TpChromeMode.full;
    final takeover = mode == TpChromeMode.takeover;
    // 헤더 알약에 들어갈 글자. 스크롤 제목은 [past] 가 켜질 때만 보인다.
    final pillTitle = title ?? (past == null ? null : scrollTitle);

    final topInset = switch (mode) {
      TpChromeMode.full => safe.top + _iosContentTop,
      TpChromeMode.plain => safe.top + 12,
      TpChromeMode.takeover => 0.0,
    };
    final bottomInset = takeover
        // 인수 화면은 위아래로 화면을 통째로 쓴다. 여기서 안전 영역을 비우면
        // 어두운 화면 아래로 밝은 배경이 띠처럼 남는다. 스캔·뷰어는 자기
        // 컨트롤에 안전 영역을 직접 더한다.
        ? 0.0
        : (tab != null
              ? safe.bottom + TpTabBar.coverOf(context) + 16
              : safe.bottom + 24);

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
            child: child,
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

        if (showChrome &&
            (onBack != null || pillTitle != null || trailing != null))
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
                    child: TpSurface.chrome(
                      radius: TpTokens.rControl,
                      child: SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(TpIcons.ios.back, size: 22),
                      ),
                    ),
                  )
                // 오른쪽에만 버튼이 있으면 제목이 왼쪽으로 밀린다.
                else if (trailing != null && pillTitle != null)
                  const SizedBox(width: 48),
                // 제목이 없는 화면(상세)은 밀어줄 것이 없어 오른쪽 버튼이
                // 왼쪽에 붙는다.
                if (pillTitle == null && trailing != null) const Spacer(),
                if (pillTitle != null) ...<Widget>[
                  const Spacer(),
                  _fadeIn(
                    context,
                    past,
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
                          // 시스템 바처럼 글자 확대에 상한을 둔다. 알약 높이가
                          // 고정이라 넘치면 잘린다.
                          MediaQuery.withClampedTextScaling(
                            maxScaleFactor: 1.2,
                            child: Text(pillTitle, style: type.appBarTitle),
                          ),
                        ],
                      ),
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
                else if (onBack != null && pillTitle != null)
                  const SizedBox(width: 48),
              ],
            ),
          ),

        // 상태 바를 누르면 맨 위로. iOS 는 그 자리의 탭을 앱에 넘겨준다.
        if (!takeover)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: safe.top,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              excludeFromSemantics: true,
              onTap: () => _scrollToTop(context),
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

    // 넓은 창에서는 바닥 바 대신 왼쪽 레일이다. 1440pt 짜리 창에서 다섯 칸이
    // 288pt 씩 벌어진 바가 창 아래를 가로지르는 건 폰 것을 늘려 놓은 모양이다.
    final rail =
        showChrome &&
        tab != null &&
        tpWindowClass(context) != TpWindowClass.compact;

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
        : (tab != null && !rail
                  ? _androidTabHeight + safe.bottom + 12
                  : safe.bottom + 24) +
              (floatingAction != null ? _androidFabInset : 0);

    final body = Stack(
      children: <Widget>[
        Positioned.fill(
          child: _content(
            context,
            top: topInset,
            bottom: bottomInset,
            child: child,
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
              // 앱 바 **바탕**은 창을 가로지르고 그 **안의 것**만 본문과 같은
              // 칸에 든다. 안 그러면 큰 제목이 창 왼쪽 끝에 붙고 카드는 가운데
              // 있어서 둘이 다른 화면처럼 보인다.
              child: _column(
                context,
                Column(
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
          ),

        if (floatingAction != null)
          Positioned(
            right: 16,
            bottom:
                (tab != null ? _androidTabHeight + safe.bottom : safe.bottom) +
                16,
            child: floatingAction!,
          ),
      ],
    );
    return body;
  }
}

///
/// 명세 Assets 표가 크기를 못박았다 — iOS 13×19, Android 16×22.
/// 장식이라 스크린 리더에서는 뺀다. 제목이 바로 옆에 있다.
/// 헤더의 앱 마크.
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

/// 세로 스크롤이 [after] 를 넘었는지 알려준다. 넘나들 때만 다시 그린다.
class _ScrollPast extends StatefulWidget {
  const _ScrollPast({required this.after, required this.builder});

  final double after;
  final Widget Function(BuildContext context, ValueListenable<bool> past)
  builder;

  @override
  State<_ScrollPast> createState() => _ScrollPastState();
}

class _ScrollPastState extends State<_ScrollPast> {
  final ValueNotifier<bool> _past = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _past.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (n) {
        // 안쪽의 가로 목록(칩 줄)이 굴러도 제목이 깜빡이면 안 된다.
        if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
          _past.value = n.metrics.pixels > widget.after;
        }
        return false;
      },
      child: widget.builder(context, _past),
    );
  }
}

/// 지금 탭을 다시 누르면 [TabHost] 가 알린다. 이 셸의 탭이면 맨 위로.
class TpReselect extends StatefulWidget {
  const TpReselect({
    super.key,
    required this.tab,
    required this.onReselect,
    required this.child,
  });

  final TpTab? tab;
  final void Function(BuildContext context) onReselect;
  final Widget child;

  @override
  State<TpReselect> createState() => TpReselectState();
}

class TpReselectState extends State<TpReselect> {
  TpTabReselectNotifier? _bus;
  final GlobalKey _inner = GlobalKey();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bus = widget.tab == null ? null : TpTabReselect.maybeOf(context);
    if (bus == _bus) return;
    _bus?.removeListener(_heard);
    _bus = bus?..addListener(_heard);
  }

  void _heard() {
    final inner = _inner.currentContext;
    if (_bus?.last == widget.tab && inner != null) widget.onReselect(inner);
  }

  @override
  void dispose() {
    _bus?.removeListener(_heard);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _inner, child: widget.child);
}
