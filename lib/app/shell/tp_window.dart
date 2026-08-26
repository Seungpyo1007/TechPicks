import 'package:flutter/widgets.dart';

/// 창의 크기 등급.
///
/// 이 앱은 폰 프레임(402×874 / 412×892)만 보고 만들어졌다. 웹으로 오면서
/// 1440pt 짜리 창이 생기는데, 지금은 **최대 폭 제약이 `lib/` 전체에 하나도
/// 없어서** 전부 그냥 늘어난다 — 상담 말풍선이 1098pt 슬래브가 되고, 탭
/// 캡슐이 1416pt 알약 안에 22pt 아이콘 하나를 담는다.
///
/// 경계는 Material 의 window size class 를 따른다. 지어낸 숫자가 아니라
/// 남들도 쓰는 숫자여야 나중에 위젯을 가져다 쓸 때 안 어긋난다.
enum TpWindowClass {
  /// 폰. 지금까지 만들어 온 것 그대로다.
  compact,

  /// 큰 폰 가로·작은 태블릿.
  medium,

  /// 태블릿 가로·데스크톱 브라우저.
  expanded,
}

/// 지금 창이 어느 등급인지.
///
/// [InheritedWidget] 을 안 쓴다. 밀린 화면(상세·뷰어·픽커·스캔)은 별도
/// 라우트라 [TabHost] 범위의 상속 위젯을 못 본다. `MediaQuery` 는 어디서나
/// 보인다 — `tpContentInset` 과 같은 자유 함수 꼴로 맞춘다.
TpWindowClass tpWindowClass(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) return TpWindowClass.compact;
  if (width < 1024) return TpWindowClass.medium;
  return TpWindowClass.expanded;
}

/// 본문 한 칸의 최대 폭.
///
/// 폰에서 만든 화면들이 그대로 읽히는 폭이다. 더 넓히면 랭킹 행의 이름과
/// 값 사이가 다시 벌어지고, 더 좁히면 비교의 두 칸이 눌린다.
const double tpContentMaxWidth = 840;
