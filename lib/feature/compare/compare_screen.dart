import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/dto/score.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../domain/model/tp_weights.dart';
import '../../shared/coach/tp_coach.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_bar.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_number.dart';
import '../../shared/widgets/tp_pop_in.dart';
import '../../shared/widgets/tp_reveal.dart';

double _lines(BuildContext context, TextStyle style, int lines) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize!) *
    (style.height ?? 1.25) *
    lines;

/// 비교. 두 기기 머리 카드, 한 장의 표.
class CompareScreen extends ConsumerStatefulWidget {
  const CompareScreen({super.key, this.onPick});

  final ValueChanged<CompareSide>? onPick;

  @override
  ConsumerState<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends ConsumerState<CompareScreen> {
  /// 머리 카드. 이게 바 뒤로 다 지나가면 이름 줄을 띄운다.
  final GlobalKey _heads = GlobalKey();

  ValueChanged<CompareSide>? get onPick => widget.onPick;

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final slots = ref.watch(compareProvider);
    final pairs = ref.watch(comparisonProvider);
    final weights = ref.watch(weightsProvider);

    Smartphone? find(String? slug) {
      final devices = catalog.value?.smartphones;
      if (devices == null || slug == null) return null;
      final hit = devices.where((d) => d.slug == slug);
      return hit.isEmpty ? null : hit.first;
    }

    final a = find(slots.a);
    final b = find(slots.b);
    final loading = catalog is AsyncLoading && !catalog.hasError;
    // 링크로 온 slug 가 카탈로그에 없으면 "두 대를 고르세요"만으론 왜 비었는지
    // 모른다.
    final linkMissing =
        catalog.hasValue &&
        ((slots.a != null && a == null) || (slots.b != null && b == null));

    final Widget table;
    if (loading) {
      table = const TpLoadingMark();
    } else if (catalog.hasError) {
      table = const TpCatalogError();
    } else if (pairs.isEmpty) {
      table = Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
        child: Text(
          (linkMissing ? K.compareLinkMissing : K.chooseTwo).tr(),
          style: TextStyle(fontSize: 15, color: context.sys.label2),
        ),
      );
    } else {
      table = _CompareTable(
        pairs: pairs,
        nameA: a?.name ?? '',
        nameB: b?.name ?? '',
        scoreA: a?.score,
        scoreB: b?.score,
      );
    }

    return TpPage(
      title: K.compareTitle.tr(),
      tab: TpTab.compare,
      coach: const <TpCoachStep>[
        TpCoachStep(
          target: 'compare-heads',
          title: K.coachCompare,
          body: K.coachCompareBody,
        ),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            // 두 대가 있으면 아래 여백은 이름 줄 자리가 맡는다.
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              a != null && b != null && pairs.isNotEmpty ? 0 : 16,
            ),
            child: TpReveal(
              loading: loading,
              // 읽는 동안은 비워 둔다. "고르기" 칸이 떴다가 기기로 바뀌면 튄다.
              child: loading
                  ? const SizedBox.shrink()
                  : TpCoachTarget(
                      id: 'compare-heads',
                      child: Row(
                        key: _heads,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: _Swap(
                              side: CompareSide.a,
                              slug: a?.slug,
                              child: _ColumnHead(
                                device: a,
                                weights: weights,
                                winner:
                                    pairs.isNotEmpty &&
                                    pairs.first.winner == CompareSide.a,
                                onTap: onPick == null
                                    ? null
                                    : () => onPick!(CompareSide.a),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Swap(
                              side: CompareSide.b,
                              slug: b?.slug,
                              child: _ColumnHead(
                                device: b,
                                weights: weights,
                                winner:
                                    pairs.isNotEmpty &&
                                    pairs.first.winner == CompareSide.b,
                                onTap: onPick == null
                                    ? null
                                    : () => onPick!(CompareSide.b),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (a != null && b != null && pairs.isNotEmpty)
          SliverPersistentHeader(
            pinned: true,
            delegate: _NamesBar(
              height: _NamesBar.heightFor(context),
              heads: _heads,
              a: a,
              b: b,
              weights: weights,
            ),
          ),
        SliverToBoxAdapter(
          child: TpReveal(loading: loading, order: 1, child: table),
        ),
      ],
    );
  }
}

/// 머리 카드의 기기가 바뀔 때. 맞바꾸면 새 기기가 반대편에서 밀려 들어온다
/// (A 칸은 오른쪽에서, B 칸은 왼쪽에서). 동작 줄이기면 바로 바뀐다.
class _Swap extends StatelessWidget {
  const _Swap({required this.side, required this.slug, required this.child});

  final CompareSide side;
  final String? slug;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final move = context.motion.contentSwap;
    final from = side == CompareSide.a ? .35 : -.35;
    return AnimatedSwitcher(
      duration: move.duration,
      switchInCurve: move.curve,
      switchOutCurve: move.curve,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        final incoming = child.key == ValueKey<String?>(slug);
        final offset = Tween<Offset>(
          begin: Offset(incoming ? from : -from, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: KeyedSubtree(key: ValueKey<String?>(slug), child: child),
    );
  }
}

/// 스크롤로 머리 카드가 지나가면 바 아래에 붙는 한 줄: 두 이름 + 지수.
///
/// 표 아래쪽을 볼 때 어느 열이 어느 기기인지 잃지 않게. 카드가 보이는 동안은
/// 자리만 차지하고 비어 있다(머리 카드와 표 사이 여백).
class _NamesBar extends SliverPersistentHeaderDelegate {
  _NamesBar({
    required this.height,
    required this.heads,
    required this.a,
    required this.b,
    required this.weights,
  });

  final double height;
  final GlobalKey heads;
  final Smartphone a;
  final Smartphone b;
  final TpWeights weights;

  static const TextStyle _style = TextStyle(
    fontSize: 13,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );

  static double heightFor(BuildContext context) =>
      _lines(context, _style, 1) + 14;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      SizedBox(
        height: height,
        child: _Names(heads: heads, a: a, b: b, weights: weights),
      );

  @override
  bool shouldRebuild(_NamesBar old) =>
      old.height != height ||
      old.a != a ||
      old.b != b ||
      old.weights != weights;
}

class _Names extends StatefulWidget {
  const _Names({
    required this.heads,
    required this.a,
    required this.b,
    required this.weights,
  });

  final GlobalKey heads;
  final Smartphone a;
  final Smartphone b;
  final TpWeights weights;

  @override
  State<_Names> createState() => _NamesState();
}

class _NamesState extends State<_Names> {
  ScrollPosition? _position;
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next == _position) return;
    _position?.removeListener(_check);
    _position = next?..addListener(_check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _position?.removeListener(_check);
    super.dispose();
  }

  /// 이 줄이 바 아래에 붙고 머리 카드가 그 위로 지나갔는가.
  void _check() {
    if (!mounted) return;
    final me = context.findRenderObject() as RenderBox?;
    final heads = widget.heads.currentContext?.findRenderObject() as RenderBox?;
    if (me == null || !me.attached || heads == null || !heads.attached) return;
    final top = me.localToGlobal(Offset.zero).dy;
    final bottom = heads.localToGlobal(Offset(0, heads.size.height)).dy;
    // 붙기 전에는 카드 바로 아래라 둘이 같다. 붙은 뒤에만 카드가 더 올라간다.
    final shown = bottom < top - .5;
    if (shown != _shown) setState(() => _shown = shown);
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    Widget side(Smartphone d, TextAlign align) {
      final index = TpIndex.of(d.score, widget.weights);
      return Expanded(
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: d.name),
              if (index != null)
                TextSpan(
                  text: '  $index',
                  style: TextStyle(color: sys.accentText),
                ),
            ],
          ),
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _NamesBar._style.copyWith(color: sys.label),
        ),
      );
    }

    return IgnorePointer(
      ignoring: !_shown,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: context.motion.selection.duration,
        child: ExcludeSemantics(
          // 머리 카드가 이미 같은 것을 읽어 준다.
          excluding: !_shown,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: sys.background.withValues(alpha: .92),
              border: Border(
                bottom: BorderSide(color: sys.separator, width: .5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: <Widget>[
                  side(widget.a, TextAlign.start),
                  const SizedBox(width: 10),
                  side(widget.b, TextAlign.end),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColumnHead extends StatelessWidget {
  const _ColumnHead({
    required this.device,
    required this.weights,
    required this.winner,
    this.onTap,
  });

  final Smartphone? device;
  final TpWeights weights;
  final bool winner;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final type = context.tpText;
    final nameStyle = TextStyle(
      fontSize: 17,
      height: 1.29,
      fontWeight: FontWeight.w600,
      color: sys.label,
    );
    final index = device == null ? null : TpIndex.of(device!.score, weights);
    final glass = context.tp.isGlass;

    if (device == null) {
      return Semantics(
        button: true,
        label: K.choose.tr(),
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          onTap: onTap,
          excludeFromSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: 150),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(TpGroup.radius),
              border: Border.all(color: sys.label3, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                TpPopIn(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sys.tint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      glass ? CupertinoIcons.add : Icons.add,
                      color: sys.accentText,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  K.choose.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: sys.accentText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: onTap != null,
      label: <String>[
        device!.name,
        if (index != null) K.a11yIndex.tr(args: <String>['$index']),
        K.tapToChange.tr(),
      ].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        excludeFromSemantics: true,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sys.cell,
            borderRadius: BorderRadius.circular(TpGroup.radius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: _lines(context, nameStyle, 2),
                ),
                child: Text(
                  device!.name,
                  style: nameStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: <Widget>[
                    MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: TpNumber(
                        index?.toString() ?? DeviceSpecs.empty,
                        style: type.indexNumeral.copyWith(
                          fontSize: 34,
                          color: winner ? TpSys.accent : sys.label,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              TpTrack(value: (index ?? 0) / 100),
              const SizedBox(height: 8),
              Text(
                K.tapToChange.tr(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: sys.accentText),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({
    required this.pairs,
    required this.nameA,
    required this.nameB,
    this.scoreA,
    this.scoreB,
  });

  final List<SpecPair> pairs;
  final String nameA;
  final String nameB;
  final SmartphoneScore? scoreA;
  final SmartphoneScore? scoreB;

  @override
  Widget build(BuildContext context) => TpGroup(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    children: <Widget>[
      for (final (i, pair) in pairs.indexed)
        _CompareRow(
          pair: pair,
          nameA: nameA,
          nameB: nameB,
          scoreA: scoreA,
          scoreB: scoreB,
          // 마지막 줄에도 선을 그으면 카드 안쪽에 선이 하나 떠 있다.
          last: i == pairs.length - 1,
        ),
    ],
  );
}

/// 한 줄. 이긴 셀만 파란 알약을 두르고 굵기를 올린다.
class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.pair,
    required this.nameA,
    required this.nameB,
    required this.last,
    this.scoreA,
    this.scoreB,
  });

  final SpecPair pair;
  final String nameA;
  final String nameB;
  final bool last;
  final SmartphoneScore? scoreA;
  final SmartphoneScore? scoreB;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final axis = pair.kind.scoreAxis;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(color: context.sys.separator, width: 0.5),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            SpecLabels.of(pair.kind),
            style: type.caption,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _Cell(
                  spec: pair.a,
                  won: pair.winner == CompareSide.a,
                  device: nameA,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Cell(
                  spec: pair.b,
                  won: pair.winner == CompareSide.b,
                  device: nameB,
                ),
              ),
            ],
          ),
          if (axis != null) ...<Widget>[
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(
                  child: _AxisBar(kind: axis, score: scoreA),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AxisBar(kind: axis, score: scoreB),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 승자를 못 가리는 줄이 대신 까는 점수 막대.
///
/// 화면·프로세서·카메라 줄에만 깐다([SpecScoreAxis.scoreAxis]).
///
/// 축 **이름은 안 그린다.** 행 라벨과 같은 글자가 둘이 된다
/// (`axCam`·`detailSpecCamera`). 이름은 스크린 리더에만 준다.
class _AxisBar extends StatelessWidget {
  const _AxisBar({required this.kind, required this.score});

  final TpAxisKind kind;
  final SmartphoneScore? score;

  @override
  Widget build(BuildContext context) {
    // 축 하나만 쓰지만 목록을 거쳐 가져온다. 따로 매핑을 두면 TpIndex 쪽
    // 축이 바뀔 때 여기만 남는다.
    final axis = TpIndex.axes(score).firstWhere((a) => a.kind == kind);

    return Semantics(
      container: true,
      // 막대만 있으면 못 읽는다. 점수 스트립과 같은 문장을 쓴다.
      label: axis.hasData
          ? K.a11yAxis.tr(
              args: <String>[
                SpecLabels.axis(axis.kind),
                axis.score!.round().toString(),
              ],
            )
          : K.a11yAxisMissing.tr(args: <String>[SpecLabels.axis(axis.kind)]),
      excludeSemantics: true,
      child: TpBar(fraction: axis.fraction),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.spec, required this.won, required this.device});

  final DeviceSpec spec;
  final bool won;

  /// 어느 기기의 값인지. 셀만 읽으면 알 수 없다.
  final String device;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final motion = context.motion;

    return Semantics(
      container: true,
      // 승패는 색으로만 표시된다. 색을 못 보면 알 수 없으니 읽어준다.
      // 잘린 값이 아니라 **온전한 값**을 읽는다.
      label: (won ? K.a11yWinner : K.a11yCompareCell).tr(
        args: <String>[device, spec.value],
      ),
      excludeSemantics: true,
      // 값 길이가 제각각이라 행 높이가 한 줄에서 네 줄까지 널뛰었다
      // (`200MP + 50MP + 50MP + 12MP` 는 153pt 폭에서 네 줄이다).
      // 두 줄 자리를 늘 비워 두고 그 이상은 자른다 — 카탈로그에서 두 줄에
      // 안 들어가는 값은 화면 설명의 꼬리뿐이다.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _lines(context, type.body, 2)),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          // 목록 안이라 세로가 무한이다. 이게 없으면 Align 이 무한을 채운다.
          heightFactor: 1,
          child: AnimatedContainer(
            duration: motion.valueChange.duration,
            curve: motion.valueChange.curve,
            // 이긴 표시가 셀을 통째로 칠하던 것을 글자에 맞는 알약으로
            // 줄인다. 안드로이드 토큰의 tintFill 은 불투명이라 셀 전체가
            // 파란 덩어리로 앉았다. 색은 그대로 둔다 — 대비가 증명된 짝이다.
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: won ? context.sys.tint : Colors.transparent,
              borderRadius: BorderRadius.circular(t.rInner - 8),
            ),
            child: AnimatedDefaultTextStyle(
              duration: motion.valueChange.duration,
              curve: motion.valueChange.curve,
              style: type.body.copyWith(
                fontWeight: won ? t.boldWeight : FontWeight.w400,
                color: won
                    ? context.sys.accentText
                    : spec.hasValue
                    ? context.sys.label
                    : context.sys.label3,
              ),
              child: Text(
                spec.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
