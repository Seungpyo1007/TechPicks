import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:motor/motor.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import 'tp_arrive.dart';
import 'tp_number.dart';
import 'tp_pressable.dart';

/// iOS inset grouped 목록의 한 묶음. 위 레이블, 칸들, 아래 설명.
///
/// Android 는 카드 없이 섹션 제목 + 행.
class TpGroup extends StatelessWidget {
  const TpGroup({
    super.key,
    required this.children,
    this.header,
    this.footer,
    this.headerAction,
    this.big = false,
    this.padding,
    this.m3 = false,
  });

  final List<Widget> children;
  final String? header;
  final String? footer;

  /// 헤더 오른쪽 글자 버튼("추가").
  final Widget? headerAction;

  /// 헤더를 Title 3(20 Bold)로. "관심 목록"처럼 섹션 제목 역할일 때.
  final bool big;

  /// 칸 안쪽 여백. 카드처럼 쓰는 묶음(판정 카드)에 준다.
  final EdgeInsets? padding;

  /// Android 에서 M3 목록으로. 줄이 화면 끝까지 가서 들여쓰기는 줄 안쪽
  /// 16 하나뿐이고, 줄 높이는 56 / 72(부제). iOS 는 그대로.
  final bool m3;

  static const double radius = 26;

  /// 이 줄이 M3 목록 안에 있는가.
  static bool m3Of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_M3Rows>() != null;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final flush = m3 && !glass;
    final rows = <Widget>[
      // 화면이 나타날 때 행이 차례로 들어온다(TpArrive).
      for (var i = 0; i < children.length; i++)
        TpArrive(
          index: i,
          child: _Separated(last: i == children.length - 1, child: children[i]),
        ),
    ];
    final head = header == null
        ? null
        : Padding(
            padding: EdgeInsets.fromLTRB(
              glass || flush ? 16 : 0,
              big ? 12 : 0,
              glass || flush ? 16 : 0,
              big ? 4 : 7,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    header!,
                    style: big
                        ? TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: sys.label,
                          )
                        : glass
                        ? TextStyle(fontSize: 13, color: sys.label2)
                        : TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: sys.accentText,
                          ),
                  ),
                ),
                ?headerAction,
              ],
            ),
          );
    final body = glass
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: sys.cell,
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Padding(
                padding: padding ?? EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: rows,
                ),
              ),
            ),
          )
        : Padding(
            padding: padding ?? EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: flush
                  ? <Widget>[for (final c in children) _M3Rows(child: c)]
                  : children,
            ),
          );
    return Padding(
      padding: flush
          ? const EdgeInsets.only(bottom: 8)
          : const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ?head,
          body,
          if (footer != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                glass || flush ? 16 : 0,
                flush ? 4 : 7,
                glass || flush ? 16 : 0,
                0,
              ),
              child: Text(
                footer!,
                style: flush
                    ? TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        color: sys.label2,
                      )
                    : TextStyle(fontSize: 13, height: 1.38, color: sys.label2),
              ),
            ),
        ],
      ),
    );
  }
}

/// [TpGroup.m3] 안의 줄. [TpRow] 가 보고 높이와 글자 크기를 바꾼다.
class _M3Rows extends InheritedWidget {
  const _M3Rows({required super.child});

  @override
  bool updateShouldNotify(_M3Rows oldWidget) => false;
}

/// M3 목록 묶음 사이 구분선. 1pt, outline 35%.
class TpM3Divider extends StatelessWidget {
  const TpM3Divider({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Container(
      height: 1,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: .35),
    ),
  );
}

/// 긴 목록(랭킹)용. 화면에 보이는 행만 짓는다.
class TpGroupSliver extends StatelessWidget {
  const TpGroupSliver({
    super.key,
    required this.count,
    required this.builder,
    this.header,
    this.footer,
  });

  final int count;
  final IndexedWidgetBuilder builder;
  final String? header;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    return SliverMainAxisGroup(
      slivers: <Widget>[
        if (header != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(glass ? 32 : 16, 0, 32, 7),
              child: Text(
                header!,
                style: TextStyle(fontSize: 13, color: sys.label2),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              color: glass ? sys.cell : Colors.transparent,
              borderRadius: BorderRadius.circular(TpGroup.radius),
            ),
            sliver: SliverList.builder(
              itemCount: count,
              itemBuilder: (context, i) => TpArrive(
                index: i,
                child: glass
                    ? _Separated(
                        last: i == count - 1,
                        child: builder(context, i),
                      )
                    : builder(context, i),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(glass ? 32 : 16, 7, 32, 24),
            child: footer == null
                ? const SizedBox.shrink()
                : Text(
                    footer!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.38,
                      color: sys.label2,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

/// 행 아래 구분선. 행이 [TpRow] 면 그 들여쓰기를 따른다.
class _Separated extends StatelessWidget {
  const _Separated({required this.last, required this.child});

  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (last) return child;
    final indent = child is TpRow ? (child as TpRow).separatorIndent : 16.0;
    return Stack(
      children: <Widget>[
        child,
        Positioned(
          left: indent,
          right: 0,
          bottom: 0,
          height: 0.5,
          child: ColoredBox(color: context.sys.separator),
        ),
      ],
    );
  }
}

/// 목록 한 줄.
///
/// 누르면 배경색만 바뀐다. 행마다 애니메이션 빌더나 색 필터를 달지 않는다.
class TpRow extends StatefulWidget {
  const TpRow({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
    this.chevron,
    this.checked = false,
    this.destructive = false,
    this.dimmed = false,
    this.semanticsLabel,
    this.titleStyle,
    this.valueStyle,
    this.numeric = false,
    this.below,
    this.toggled,
  });

  /// 켜고 끄는 줄이면 지금 상태. 스위치로 읽힌다.
  final bool? toggled;

  final String title;
  final String? subtitle;

  /// 오른쪽 값(보조 글자색).
  final String? value;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// null 이면 [onTap] 이 있을 때만 보인다.
  final bool? chevron;
  final bool checked;
  final bool destructive;

  /// 고를 수 없는 선택지.
  final bool dimmed;
  final String? semanticsLabel;
  final TextStyle? titleStyle;
  final TextStyle? valueStyle;

  /// 값이 숫자라 바뀔 때 자리마다 굴러간다([TpNumber]).
  final bool numeric;

  /// 제목 줄 아래에 붙는 것(순위 행의 트랙).
  final Widget? below;

  double get separatorIndent => leading == null ? 16 : 60;

  @override
  State<TpRow> createState() => _TpRowState();
}

class _TpRowState extends State<TpRow> {
  bool _down = false;

  void _set(bool v) {
    if (widget.onTap != null && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final w = widget;
    final glass = context.tp.isGlass;
    final titleColor = w.destructive
        ? sys.destructive
        : w.dimmed
        ? sys.label2
        : sys.label;
    final chevron = w.chevron ?? (w.onTap != null && !w.checked);
    final m3 = !glass && TpGroup.m3Of(context);
    final centred = w.destructive && w.leading == null && w.value == null;

    final text = Column(
      crossAxisAlignment: centred
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          w.title,
          style: TextStyle(
            fontSize: m3 ? 16 : 17,
            height: m3 ? 1.5 : 1.29,
            color: titleColor,
          ).merge(w.titleStyle),
        ),
        if (w.subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(
              w.subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: m3 ? 14 : 13,
                height: m3 ? 20 / 14 : 1.38,
                color: sys.label2,
              ),
            ),
          ),
        ?w.below,
      ],
    );

    Widget rowOf(double maxValue) => Container(
      constraints: BoxConstraints(
        minHeight: m3
            ? (w.subtitle == null ? 56 : 72)
            : (w.subtitle == null ? 48 : 60),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _down
          ? (glass ? sys.fill3 : sys.fill.withValues(alpha: .4))
          : Colors.transparent,
      child: Row(
        children: <Widget>[
          if (w.leading != null) ...<Widget>[
            w.leading!,
            SizedBox(width: m3 ? 16 : 12),
          ],
          Expanded(child: text),
          if (w.value != null) ...<Widget>[
            const SizedBox(width: 12),
            // 값은 오른쪽 끝에 붙고, 길면 행의 60% 까지만 쓰고 줄바꿈한다.
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxValue),
              child: w.numeric
                  ? TpNumber(
                      w.value!,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: m3 ? 14 : 17,
                        color: sys.label2,
                      ).merge(w.valueStyle),
                    )
                  : Text(
                      w.value!,
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        fontSize: m3 ? 14 : 17,
                        color: sys.label2,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ).merge(w.valueStyle),
                    ),
            ),
          ],
          if (w.trailing != null) ...<Widget>[
            const SizedBox(width: 8),
            w.trailing!,
          ],
          if (w.checked) ...<Widget>[
            const SizedBox(width: 8),
            Icon(
              glass ? CupertinoIcons.check_mark : Icons.check,
              size: m3 ? 24 : 20,
              color: TpSys.accent,
            ),
          ],
          if (chevron && glass) ...<Widget>[
            const SizedBox(width: 6),
            Icon(CupertinoIcons.chevron_forward, size: 16, color: sys.label3),
          ],
        ],
      ),
    );

    final row = LayoutBuilder(
      builder: (context, box) =>
          rowOf(box.maxWidth.isFinite ? box.maxWidth * 0.6 : 240),
    );

    // 행 전체가 한 문장이다. 안 그러면 누르는 노드와 글자 노드가 갈라져
    // "이름 없는 버튼"이 된다.
    final label =
        w.semanticsLabel ??
        <String?>[w.title, w.subtitle, w.value].whereType<String>().join(', ');
    return Semantics(
      button: w.onTap != null && w.toggled == null,
      toggled: w.toggled,
      selected: w.checked,
      label: label,
      excludeSemantics: true,
      onTap: w.onTap,
      child: TpTappable(onTap: w.onTap, onDown: _set, child: row),
    );
  }
}

/// 설정 행 앞의 색 아이콘 타일. 설정 앱과 같은 30pt, 모서리 8.
class TpIconTile extends StatelessWidget {
  const TpIconTile({super.key, required this.icon, this.color = TpSys.accent});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 30,
    height: 30,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(icon, size: 18, color: Colors.white),
  );
}

/// 1–3위 액센트 원, 그 뒤로는 보조 글자 숫자.
class TpRankBadge extends StatelessWidget {
  const TpRankBadge({super.key, required this.rank});

  final int rank;

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      return Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: TpSys.accent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$rank',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }
    return SizedBox(
      width: 28,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: context.sys.label2,
        ),
      ),
    );
  }
}

/// 값 막대. 순위 행 3pt, 점수 6pt.
class TpTrack extends StatelessWidget {
  const TpTrack({super.key, required this.value, this.height = 3});

  /// 0–1.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: SizedBox(
      height: height,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: ColoredBox(color: context.sys.fill)),
          Positioned.fill(
            // 화면이 나타나면 0 에서부터 찬다. 등장 신호가 바뀔 때마다 새로.
            child: SingleMotionBuilder(
              key: ValueKey<DateTime?>(TpArriveScope.of(context)),
              from: TpArriveScope.freshOf(context) == null ? null : 0,
              value: value.clamp(0.0, 1.0),
              motion: context.motion.smooth,
              builder: (context, v, child) => Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: v.clamp(0.0, 1.0),
                  heightFactor: 1,
                  child: child,
                ),
              ),
              child: const ColoredBox(color: TpSys.accent),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 누를 수 있는 것. 손가락, Tab + Enter/Space 둘 다 받는다.
///
/// [press] 면 누르는 동안 0.97 로 줄어든다(알약·툴바 버튼·칩). 행은 끄고
/// [onDown] 으로 배경을 칠한다 — iOS 표 셀과 같다.
class TpTappable extends StatelessWidget {
  const TpTappable({
    super.key,
    required this.onTap,
    required this.child,
    this.onDown,
    this.press = false,
  });

  final VoidCallback? onTap;
  final Widget child;

  /// 눌림 표시. true 로 들어왔다가 false 로 나간다.
  final ValueChanged<bool>? onDown;

  /// 누르는 동안 줄어든다.
  final bool press;

  @override
  Widget build(BuildContext context) {
    if (onTap == null) return child;
    if (press) {
      // 눌림은 포인터로 잡는다. 스크롤 안에서 onTapDown 은 100ms 늦다.
      return TpPressable(
        onTap: onTap,
        haptic: TpHaptic.none,
        semantics: false,
        builder: (context, t, child) =>
            TpPressPaint.scale(t, double.infinity, child!),
        child: child,
      );
    }
    return FocusableActionDetector(
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap!();
            return null;
          },
        ),
      },
      onShowFocusHighlight: onDown,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: onTap,
        onTapDown: onDown == null ? null : (_) => onDown!(true),
        onTapUp: onDown == null ? null : (_) => onDown!(false),
        onTapCancel: onDown == null ? null : () => onDown!(false),
        child: child,
      ),
    );
  }
}
