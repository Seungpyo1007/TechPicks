import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import 'rank_category.dart';

/// 둘러보기 맨 위의 카테고리 세그먼트. 세 카테고리 화면이 같은 걸 쓴다.
///
/// 지금 카테고리는 주소가 쥔다. 고르면 바깥이 주소를 바꾼다.
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
    if (!context.tp.isGlass) {
      return SegmentedButton<RankCategory>(
        segments: <ButtonSegment<RankCategory>>[
          for (final c in RankCategory.values)
            ButtonSegment<RankCategory>(value: c, label: Text(c.key.tr())),
        ],
        selected: <RankCategory>{current},
        onSelectionChanged: (s) => onSelect(s.first),
      );
    }
    if (TpNativeGlass.enabled) {
      return Semantics(
        container: true,
        child: SizedBox(
          width: double.infinity,
          child: TpNativeSegmented(
            labels: <String>[for (final c in RankCategory.values) c.key.tr()],
            index: RankCategory.values.indexOf(current),
            onChanged: (i) {
              final c = RankCategory.values[i];
              if (c != current) onSelect(c);
            },
          ),
        ),
      );
    }
    final sys = context.sys;
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<RankCategory>(
        groupValue: current,
        backgroundColor: sys.fill3,
        padding: const EdgeInsets.all(3),
        onValueChanged: (c) {
          if (c != null && c != current) onSelect(c);
        },
        children: <RankCategory, Widget>{
          for (final c in RankCategory.values)
            c: Padding(
              padding: const EdgeInsets.symmetric(vertical: 13),
              child: Text(
                c.key.tr(),
                style: TextStyle(fontSize: 15, color: sys.label),
              ),
            ),
        },
      ),
    );
  }
}
