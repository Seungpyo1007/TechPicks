import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../shared/widgets/tp_chip.dart';
import 'rank_category.dart';

/// 둘러보기 탭 맨 위의 카테고리 칩 행. 세 카테고리 화면이 같은 걸 쓴다.
///
/// 예전에는 프로바이더를 직접 읽고 썼다. 카테고리가 진짜 라우트가 되면서
/// 주소와 프로바이더 둘이 같은 것을 말하게 됐고, 그러면 한쪽만 바뀌는 날이
/// 온다 — 지금 카테고리는 **주소가 쥔다.**
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.current,
    required this.onSelect,
  });

  final RankCategory current;
  final ValueChanged<RankCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RankCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final category = RankCategory.values[i];
          return TpChip(
            label: category.key.tr(),
            selected: category == current,
            onTap: () => onSelect(category),
          );
        },
      ),
    );
  }
}
