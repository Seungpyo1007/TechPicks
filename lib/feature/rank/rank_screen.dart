import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_motion.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/ranking.dart';
import '../../domain/model/tp_money.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_menu.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_sheet.dart';
import 'category_chips.dart';
import 'rank_category.dart';
import '../../shared/widgets/tp_shimmer.dart';

/// 둘러보기 · 스마트폰.
///
/// 세그먼트로 카테고리, 툴바로 브랜드와 정렬. 목록은 보이는 행만 짓는다.
class RankScreen extends ConsumerStatefulWidget {
  const RankScreen({super.key, this.onDeviceTap, this.onCategory});

  final ValueChanged<RankCategory>? onCategory;
  final ValueChanged<String>? onDeviceTap;

  @override
  ConsumerState<RankScreen> createState() => _RankScreenState();
}

class _RankScreenState extends ConsumerState<RankScreen> {
  /// 정렬이나 브랜드가 바뀐 횟수와 시각. 이때 새로 지어진 위쪽 행만 들어온다 —
  /// 스크롤로 다시 지어지는 행은 가만히 있어야 한다.
  int _generation = 0;
  DateTime? _changedAt;

  void _changed() => setState(() {
    _generation++;
    _changedAt = DateTime.now();
  });

  @override
  Widget build(BuildContext context) {
    ref.listen(rankAxisProvider, (_, _) => _changed());
    ref.listen(rankBrandProvider, (_, _) => _changed());
    final onCategory = widget.onCategory;
    final onDeviceTap = widget.onDeviceTap;
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final money = ref.watch(moneyProvider);
    final axis = ref.watch(rankAxisProvider);
    final ranked = ref.watch(rankVisibleProvider);
    final catalog = ref.watch(catalogProvider);
    final brands = ref.watch(rankBrandsProvider);
    final brand = ref.watch(rankBrandProvider);
    final loading = catalog is AsyncLoading && !catalog.hasError;

    final sortItems = <TpMenuItem>[
      for (final a in RankAxis.values)
        TpMenuItem(
          label: K.rankAxis(a).tr(),
          checked: a == axis,
          onTap: () => ref.read(rankAxisProvider.notifier).set(a),
        ),
    ];

    final Widget list;
    if (loading) {
      list = const SliverToBoxAdapter(child: _Skeleton());
    } else if (catalog.hasError) {
      list = const SliverToBoxAdapter(child: TpCatalogError());
    } else if (ranked.isEmpty) {
      list = SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(K.noMatches.tr(), style: TextStyle(color: sys.label2)),
        ),
      );
    } else {
      final changedAt = _changedAt;
      list = TpGroupSliver(
        key: ValueKey<int>(_generation),
        count: ranked.length,
        footer: K.rankNote.tr(),
        builder: (context, i) => _Arrive(
          index: i,
          changedAt: changedAt,
          child: _RankRow(
            entry: ranked[i],
            axis: axis,
            money: money,
            onTap: onDeviceTap == null
                ? null
                : () => onDeviceTap(ranked[i].device.slug),
          ),
        ),
      );
    }

    return TpPage(
      title: K.tab(TpTab.browse).tr(),
      tab: TpTab.browse,
      actions: <TpBarAction>[
        if (brand != null)
          TpBarAction(
            label: brand,
            text: true,
            filled: true,
            onTap: () => _pickBrand(context, ref, brands, brand),
          )
        else
          TpBarAction(
            label: K.brand.tr(),
            icon: context.tp.isGlass
                ? CupertinoIcons.line_horizontal_3_decrease
                : Icons.filter_list,
            onTap: brands.isEmpty
                ? null
                : () => _pickBrand(context, ref, brands, brand),
          ),
        // Android 는 정렬을 칩 줄로 보여준다(M3 에서는 칩이 표준).
        if (glass)
          TpBarAction(
            label: K.sort.tr(),
            icon: CupertinoIcons.arrow_up_arrow_down,
            menu: sortItems,
          ),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: CategoryChips(
              current: RankCategory.phones,
              onSelect: onCategory ?? (_) {},
            ),
          ),
        ),
        if (!glass)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                itemCount: RankAxis.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final a = RankAxis.values[i];
                  return FilterChip(
                    label: Text(K.rankAxis(a).tr()),
                    selected: a == axis,
                    onSelected: (_) =>
                        ref.read(rankAxisProvider.notifier).set(a),
                  );
                },
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 24, 7),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    K.rankStatus.tr(
                      args: <String>[
                        K.rankAxis(axis).tr(),
                        brand ?? K.allBrands.tr(),
                        '${ranked.length}',
                      ],
                    ),
                    style: TextStyle(fontSize: 13, color: sys.label2),
                  ),
                ),
                if (brand != null)
                  GestureDetector(
                    onTap: () => ref.read(rankBrandProvider.notifier).set(null),
                    child: Text(
                      K.clear.tr(),
                      style: TextStyle(fontSize: 13, color: sys.accentText),
                    ),
                  ),
              ],
            ),
          ),
        ),
        list,
      ],
    );
  }
}

Future<void> _pickBrand(
  BuildContext context,
  WidgetRef ref,
  List<String> brands,
  String? current,
) async {
  final maxHeight = MediaQuery.sizeOf(context).height * 0.6;
  await showTpSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: TpGroup(
            header: K.brand.tr(),
            children: <Widget>[
              for (final option in <String?>[null, ...brands])
                TpRow(
                  title: option ?? K.allBrands.tr(),
                  checked: option == current,
                  chevron: false,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref.read(rankBrandProvider.notifier).set(option);
                  },
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.entry,
    required this.axis,
    required this.money,
    this.onTap,
  });

  final RankedDevice entry;
  final RankAxis axis;
  final TpMoney money;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final price = money.format(entry.device.msrpUsd);
    final sub = <String>[
      if (entry.device.brand?.name != null) entry.device.brand!.name,
      if (price != TpMoney.empty) price,
    ].join(' · ');
    return TpRow(
      title: entry.device.name,
      subtitle: sub,
      leading: TpRankBadge(rank: entry.position),
      value: formatAxisValue(axis, entry.axisValue, money),
      valueStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: entry.axisValue == null ? sys.label3 : sys.label,
      ),
      chevron: false,
      onTap: onTap,
      semanticsLabel: K.a11yRankRow.tr(
        args: <String>[
          '${entry.position}',
          entry.device.name,
          entry.index?.toString() ?? DeviceSpecs.empty,
        ],
      ),
      below: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TpTrack(value: entry.fraction),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => TpShimmer(
    child: TpGroup(
      children: <Widget>[
        for (var i = 0; i < 6; i++)
          SizedBox(
            height: 66,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.sys.fill3,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

String formatAxisValue(
  RankAxis axis,
  double? value, [
  TpMoney money = const TpMoney.usd(),
]) {
  if (value == null) return TpMoney.empty;
  if (axis == RankAxis.price) return money.format(value.round());
  return value.round().toString();
}

/// 재정렬 직후에 지어진 위쪽 행이 차례로 들어온다. `motion.reorder`(220ms).
class _Arrive extends StatefulWidget {
  const _Arrive({
    required this.index,
    required this.changedAt,
    required this.child,
  });

  final int index;
  final DateTime? changedAt;
  final Widget child;

  /// 이만큼만 움직인다. 화면 밖 행까지 기다리게 하면 느려 보인다.
  static const int rows = 12;

  /// 행 사이 간격.
  static const Duration step = Duration(milliseconds: 18);

  @override
  State<_Arrive> createState() => _ArriveState();
}

class _ArriveState extends State<_Arrive> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  CurvedAnimation? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final at = widget.changedAt;
    final move = context.motion.reorder;
    final fresh =
        at != null &&
        DateTime.now().difference(at) < const Duration(milliseconds: 300);
    if (!fresh ||
        widget.index >= _Arrive.rows ||
        move.duration == Duration.zero) {
      return;
    }
    final delay = _Arrive.step * widget.index;
    final total = move.duration + delay;
    final c = AnimationController(vsync: this, duration: total);
    _c = c;
    _t = CurvedAnimation(
      parent: c,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: move.curve,
      ),
    );
    c.forward();
  }

  @override
  void dispose() {
    _t?.dispose();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) return widget.child;
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.25),
          end: Offset.zero,
        ).animate(t),
        child: widget.child,
      ),
    );
  }
}
