import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../cpu/processor_screen.dart';
import 'rank_category.dart';
import 'rank_screen.dart';

/// Rank 탭이 담고 있는 세 화면을 카테고리로 가른다.
///
/// 명세 탭 맵에서 `rank`/`cpu`/`laptop` 은 모두 Rank 탭을 켠 채로 서로를
/// 대체한다. 푸시가 아니라 교체라 뒤로 가기도 생기지 않는다.
class RankTab extends ConsumerWidget {
  const RankTab({super.key, this.onTabSelected, this.onDeviceTap, this.onScan});

  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(rankCategoryProvider)) {
      RankCategory.processors => ProcessorScreen(onTabSelected: onTabSelected),
      // Laptops 화면(명세 §6)은 아직 없다. 칩도 눌리지 않는다.
      RankCategory.phones || RankCategory.laptops => RankScreen(
        onTabSelected: onTabSelected,
        onDeviceTap: onDeviceTap,
        onScan: onScan,
      ),
    };
  }
}
