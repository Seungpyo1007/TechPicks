import 'package:flutter/material.dart';

/// 하단 탭. v3 에서 넷이 됐다(오늘 · 둘러보기 · 비교 + 검색).
///
/// 질문과 내 정보는 탭이 아니라 시트다. 질문은 보고 있던 기기를 들고 열리고,
/// 내 정보는 오늘 화면 오른쪽 위 프로필 버튼 뒤에 있다.
///
/// **값의 순서가 곧 셸 브랜치의 순서다.** TabHost 가 `values[currentIndex]`
/// 로 지금 탭을 읽으므로 순서를 바꾸면 다른 탭이 열린다 — 오류는 안 난다.
/// `test/unit/router_shape_test.dart` 가 지킨다.
enum TpTab {
  today(
    'today',
    Icons.home_outlined,
    Icons.home_rounded,
    'house',
    'house.fill',
  ),
  browse(
    'browse',
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
    'square.grid.2x2',
    'square.grid.2x2.fill',
  ),
  compare(
    'compare',
    Icons.balance_outlined,
    Icons.balance_rounded,
    // 저울. 채운 변형이 있는 심볼이라 옆칸들과 무게가 맞는다.
    'scalemass',
    'scalemass.fill',
  ),

  /// 검색 역할 탭. iOS 26 에서는 바 오른쪽에 떨어진 원으로 그려진다.
  search(
    'search',
    Icons.search,
    Icons.search,
    'magnifyingglass',
    'magnifyingglass',
  );

  const TpTab(
    this.key,
    this.icon,
    this.activeIcon,
    this.symbol,
    this.activeSymbol,
  );

  final String key;

  final IconData icon;
  final IconData activeIcon;

  /// iOS 네이티브 탭 바에 넘기는 SF Symbol 이름.
  ///
  /// iOS 26 탭 바는 심볼을 알아서 채운다. 그래서 채운 변형이 있는 심볼만 고른다
  /// — 하나만 선 그림이면 바가 들쭉날쭉해 보인다.
  final String symbol;
  final String activeSymbol;

  /// 바 안에 칸으로 들어가는 탭. 검색은 칸이 아니라 바 옆의 원이다.
  static const List<TpTab> bar = <TpTab>[today, browse, compare];
}
