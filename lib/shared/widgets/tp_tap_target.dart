import 'package:flutter/material.dart';

/// 최소 탭 영역을 보장하는 래퍼.
///
/// 글자 링크는 높이가 20px 안팎이라 그대로 두면 누르기 어렵다. Android
/// 접근성 기준이 48dp, iOS 가 44pt 라 큰 쪽에 맞춘다. 보이는 크기는 그대로
/// 두고 히트 영역만 넓힌다.
class TpTapTarget extends StatelessWidget {
  const TpTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.label,
    this.minSize = 48,
    this.link = false,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 스크린 리더가 읽을 이름. 아이콘만 있는 버튼은 반드시 넣는다.
  final String? label;

  final double minSize;

  /// 앱 밖으로 나가는가. 스크린 리더가 버튼과 링크를 다르게 읽는다.
  final bool link;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: !link,
      link: link,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
          child: Center(widthFactor: 1, heightFactor: 1, child: child),
        ),
      ),
    );
  }
}
