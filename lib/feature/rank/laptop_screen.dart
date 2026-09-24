import 'package:flutter/material.dart';

import '../../app/theme/tp_sys.dart';
import '../../data/dto/laptop.dart';
import '../../domain/model/tp_money.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_group.dart';
import 'browse_screen.dart';
import 'rank_category.dart';

/// 둘러보기 · 노트북. 뼈대는 [BrowseScreen] 이 그린다. 점수가 없어 가격으로 줄 세운다.
class LaptopScreen extends StatelessWidget {
  const LaptopScreen({super.key, this.onCategory});

  final ValueChanged<RankCategory>? onCategory;

  @override
  Widget build(BuildContext context) =>
      BrowseScreen(category: RankCategory.laptops, onCategory: onCategory);

  static String sub(Laptop l) => <String>[
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

/// 노트북 한 줄. 폰·프로세서 행과 같은 모양 — 순위, 이름, 보조 줄, 막대, 값.
/// 막대는 가장 비싼 기종 대비 가격이다.
class LaptopRow extends StatelessWidget {
  const LaptopRow({
    super.key,
    required this.laptop,
    required this.position,
    required this.fraction,
    required this.money,
  });

  final Laptop laptop;
  final int position;
  final double fraction;
  final TpMoney money;

  @override
  Widget build(BuildContext context) => TpRow(
    title: laptop.name,
    subtitle: LaptopScreen.sub(laptop),
    leading: TpRankBadge(rank: position),
    value: money.format(laptop.msrpUsd),
    valueStyle: TextStyle(
      fontWeight: FontWeight.w600,
      color: context.sys.label,
    ),
    chevron: false,
    below: Padding(
      padding: const EdgeInsets.only(top: 6),
      child: TpTrack(value: fraction),
    ),
  );
}
