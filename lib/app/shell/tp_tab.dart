import 'package:flutter/material.dart';

/// 하단 탭. v1 의 카테고리 탭(Home/CPU/Phone/Laptop/Profile)을 대체한다.
///
/// 카테고리는 [rank] 안으로 들어갔다. 탭은 이제 사용자가 하려는 일 단위다.
enum TpTab {
  home('home', Icons.home_outlined, Icons.home_rounded, 'house', 'house.fill'),
  rank(
    'rank',
    Icons.leaderboard_outlined,
    Icons.leaderboard_rounded,
    'chart.bar',
    'chart.bar.fill',
  ),
  compare(
    'compare',
    Icons.compare_arrows_outlined,
    Icons.compare_arrows_rounded,
    'arrow.left.arrow.right',
    'arrow.left.arrow.right',
  ),
  ask(
    'ask',
    Icons.forum_outlined,
    Icons.forum_rounded,
    'bubble.left.and.bubble.right',
    'bubble.left.and.bubble.right.fill',
  ),
  you(
    'you',
    Icons.person_outline,
    Icons.person_rounded,
    'person',
    'person.fill',
  );

  const TpTab(
    this.key,
    this.icon,
    this.activeIcon,
    this.symbol,
    this.activeSymbol,
  );

  /// `assets/translations/*.json` 의 번역 키.
  final String key;

  final IconData icon;
  final IconData activeIcon;

  /// iOS 네이티브 탭 바에 넘기는 SF Symbol 이름.
  final String symbol;
  final String activeSymbol;
}
