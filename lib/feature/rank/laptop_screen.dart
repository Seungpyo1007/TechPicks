import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_sys.dart';
import '../../data/dto/laptop.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import 'category_chips.dart';
import 'rank_category.dart';

/// 둘러보기 · 노트북. 점수가 없어 가격대로 묶는다.
class LaptopScreen extends ConsumerWidget {
  const LaptopScreen({super.key, this.onCategory});

  final ValueChanged<RankCategory>? onCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laptops = ref.watch(laptopsProvider);
    final money = ref.watch(moneyProvider);
    final items = laptops.value?.byPrice ?? const <Laptop>[];
    final tiers = <String, List<Laptop>>{};
    for (final l in items) {
      tiers
          .putIfAbsent(tierOf(l.msrpUsd) ?? K.laptopNoScore, () => <Laptop>[])
          .add(l);
    }

    return TpPage(
      title: K.tab(TpTab.browse).tr(),
      tab: TpTab.browse,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: CategoryChips(
              current: RankCategory.laptops,
              onSelect: onCategory ?? (_) {},
            ),
          ),
        ),
        if (laptops.hasError)
          const SliverToBoxAdapter(child: TpCatalogError())
        else if (items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                K.noDevices.tr(),
                style: TextStyle(color: context.sys.label2),
              ),
            ),
          )
        else
          for (final e in tiers.entries)
            SliverToBoxAdapter(
              child: TpGroup(
                header: e.key.tr(),
                children: <Widget>[
                  for (final l in e.value)
                    TpRow(
                      title: l.name,
                      subtitle: _sub(l),
                      value: money.format(l.msrpUsd),
                      chevron: false,
                    ),
                ],
              ),
            ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
            child: Text(
              K.laptopNote.tr(),
              style: TextStyle(fontSize: 13, color: context.sys.label2),
            ),
          ),
        ),
      ],
    );
  }

  static String _sub(Laptop l) => <String>[
    if (l.cpuName case final v? when v.isNotEmpty) v,
    if (l.gpuName case final v? when v.isNotEmpty) v,
    if (l.display?.sizeInch case final v?)
      '${v == v.roundToDouble() ? v.round() : v}″',
  ].join(' · ');

  /// 가격대. 기준은 $3,000 / $1,500.
  static String? tierOf(int? usd) => switch (usd) {
    null => null,
    >= 3000 => K.laptopTierHigh,
    >= 1500 => K.laptopTierPerf,
    _ => K.laptopTierMain,
  };
}
