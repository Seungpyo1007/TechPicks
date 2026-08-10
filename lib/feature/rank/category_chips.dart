import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/widgets/tp_chip.dart';
import 'rank_category.dart';

/// 랭킹 탭 맨 위의 카테고리 칩 행. 세 카테고리 화면이 같은 걸 쓴다.
class CategoryChips extends ConsumerWidget {
  const CategoryChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(rankCategoryProvider);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RankCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = RankCategory.values[i];
          // Laptops 화면(명세 §6)이 아직 없다. 누르면 빈 화면이 뜨는 것보다
          // 못 누르는 게 낫다.
          final enabled = category != RankCategory.laptops;
          return TpChip(
            label: category.key.tr(),
            selected: category == current,
            onTap: enabled
                ? () => ref.read(rankCategoryProvider.notifier).set(category)
                : null,
          );
        },
      ),
    );
  }
}
