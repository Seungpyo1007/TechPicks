import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_sys.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/ranking.dart';
import '../../domain/model/tp_money.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_sheet.dart';
import 'browse_screen.dart';
import 'rank_category.dart';
import '../../shared/widgets/tp_shimmer.dart';

/// 둘러보기 · 스마트폰. 뼈대는 [BrowseScreen] 이 그린다.
class RankScreen extends StatelessWidget {
  const RankScreen({super.key, this.onDeviceTap, this.onCategory});

  final ValueChanged<RankCategory>? onCategory;
  final ValueChanged<String>? onDeviceTap;

  @override
  Widget build(BuildContext context) => BrowseScreen(
    category: RankCategory.phones,
    onDeviceTap: onDeviceTap,
    onCategory: onCategory,
  );
}

/// 브랜드 고르기 시트.
Future<void> pickBrand(
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

class RankRow extends StatelessWidget {
  const RankRow({
    super.key,
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

class RankSkeleton extends StatelessWidget {
  const RankSkeleton({super.key});

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
