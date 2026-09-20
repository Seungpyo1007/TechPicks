import 'package:flutter/material.dart';

import '../../app/shell/tp_tab.dart';
import '../cpu/processor_screen.dart';
import 'laptop_screen.dart';
import 'rank_category.dart';
import 'rank_screen.dart';

/// 둘러보기 탭이 담고 있는 세 화면을 카테고리로 가른다.
///
/// 셋 다 하단 탭은 둘러보기로 남는다. 푸시가 아니라 교체라 뒤로 가기도
/// 생기지 않는다.
///
/// **카테고리는 주소가 쥔다.** 예전에는 프로바이더였고, `laptops` 는 화면이
/// 없어서 조용히 폰 화면으로 떨어졌다 — 칩을 눌러도 아무 일이 없는 것처럼
/// 보였다. 이제 셋 다 제 주소가 있다.
class RankTab extends StatelessWidget {
  const RankTab({
    super.key,
    required this.category,
    this.onTabSelected,
    this.onDeviceTap,
    this.onScan,
    this.onCategory,
  });

  final RankCategory category;
  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;
  final VoidCallback? onScan;
  final ValueChanged<RankCategory>? onCategory;

  @override
  Widget build(BuildContext context) {
    return switch (category) {
      RankCategory.processors => ProcessorScreen(
        onTabSelected: onTabSelected,
        onCategory: onCategory,
      ),
      RankCategory.laptops => LaptopScreen(
        onTabSelected: onTabSelected,
        onCategory: onCategory,
      ),
      RankCategory.phones => RankScreen(
        onTabSelected: onTabSelected,
        onDeviceTap: onDeviceTap,
        onScan: onScan,
        onCategory: onCategory,
      ),
    };
  }
}
