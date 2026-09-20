import 'package:flutter/material.dart';

/// 하단 탭. v1 의 카테고리 탭(Home/CPU/Phone/Laptop/Profile)을 대체한다.
///
/// 탭은 사용자가 하려는 일 단위다. 카테고리(폰·프로세서·노트북)는 [browse]
/// 안에, 결론을 내는 두 도구(비교·조립 견적)는 [decide] 안에 들어간다.
///
/// **값의 순서가 곧 셸 브랜치의 순서다.** TabHost 가 `values[currentIndex]`
/// 로 지금 탭을 읽으므로 순서를 바꾸면 다른 탭이 열린다 — 오류는 안 난다.
/// `test/unit/router_shape_test.dart` 가 지킨다.
enum TpTab {
  home('home', Icons.home_outlined, Icons.home_rounded, 'house', 'house.fill'),
  browse(
    'browse',
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
    'square.grid.2x2',
    'square.grid.2x2.fill',
  ),
  decide(
    'decide',
    Icons.balance_outlined,
    Icons.balance_rounded,
    // 저울이다. 이 탭은 비교와 조립 견적을 함께 들고 있어서, 둘 다 "후보를
    // 올려놓고 결론을 얻는다"는 한 가지 일이다. 예전 아이콘은 두 사각형이라
    // 비교만 가리켰다.
    'scalemass',
    'scalemass.fill',
  ),
  ask(
    'ask',
    Icons.forum_outlined,
    Icons.forum_rounded,
    'message',
    'message.fill',
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
  ///
  /// **iOS 26 탭 바는 심볼을 알아서 채운다.** 윤곽선 이름을 줘도 채운 변형으로
  /// 그린다 — 애플 기본 앱들의 탭 바가 다 그렇다. 그래서 무게는 우리가 못
  /// 정하고, 우리가 정할 수 있는 건 **채운 변형이 있는 심볼을 고르는 것**이다.
  ///
  /// 처음에 비교를 `arrow.left.arrow.right` 로 뒀더니 그것만 채운 변형이 없어
  /// 혼자 가는 선 그림으로 남았다. 옆칸들은 까만 덩어리인데 하나만 실선이라
  /// 바가 들쭉날쭉해 보였다 — "아이콘이 두껍다"는 인상의 절반은 그 어긋남이다.
  /// 다섯 개 모두 채운 변형이 있는 것으로 맞췄다.
  final String symbol;
  final String activeSymbol;
}
