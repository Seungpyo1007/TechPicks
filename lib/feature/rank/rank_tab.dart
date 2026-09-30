import 'package:flutter/material.dart';

import '../../domain/model/processor.dart';
import 'browse_screen.dart';
import 'rank_category.dart';

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
    this.onDeviceTap,
    this.onBuild,
    this.onAllProcessors,
    this.onCategory,
  });

  final RankCategory category;
  final ValueChanged<String>? onDeviceTap;
  final VoidCallback? onBuild;
  final ValueChanged<ProcessorSegment>? onAllProcessors;
  final ValueChanged<RankCategory>? onCategory;

  /// 셋 다 같은 [BrowseScreen] 이다. 카테고리를 바꿔도 화면은 그대로 남고
  /// 안의 내용만 바뀐다 — 세그먼트의 고른 칸이 미끄러지는 것도 그래서다.
  @override
  Widget build(BuildContext context) => BrowseScreen(
    category: category,
    onDeviceTap: onDeviceTap,
    onCategory: onCategory,
    onBuild: onBuild,
    onAllProcessors: onAllProcessors,
  );
}
