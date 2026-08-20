import 'package:flutter/material.dart';

import 'tp_pressable.dart';

/// 최소 탭 영역을 보장하고, 눌리면 반응하는 래퍼.
///
/// 글자 링크는 높이가 20px 안팎이라 그대로 두면 누르기 어렵다. Android
/// 접근성 기준이 48dp, iOS 가 44pt 라 큰 쪽에 맞춘다. 보이는 크기는 그대로
/// 두고 히트 영역만 넓힌다.
///
/// 눌림 반응이 여기 있는 이유: 명세는 칩과 카드에만 눌림 규칙을 줬고, 나머지
/// 마흔 곳 가까이는 규칙이 없어 **아무것도 안 붙었다**. 링크·아이콘 버튼이
/// 죽은 것처럼 보이던 게 그래서다. 알약과 같은 박자([TpPressFeel])로 맞춘다.
class TpTapTarget extends StatefulWidget {
  const TpTapTarget({
    super.key,
    required this.child,
    required this.onTap,
    this.label,
    this.minSize = 48,
    this.link = false,
    this.pressScale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// 스크린 리더가 읽을 이름. 아이콘만 있는 버튼은 반드시 넣는다.
  final String? label;

  final double minSize;

  /// 앱 밖으로 나가는가. 스크린 리더가 버튼과 링크를 다르게 읽는다.
  final bool link;

  /// 눌렸을 때 줄어드는 정도. 1 이면 안 줄어든다 — 글자 한 줄짜리 링크가
  /// 문단 안에서 혼자 꿈틀거리는 게 어색할 때 쓴다.
  final double pressScale;

  @override
  State<TpTapTarget> createState() => _TpTapTargetState();
}

class _TpTapTargetState extends State<TpTapTarget> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      // 누를 것이 없으면 버튼도 링크도 아니다. 액션도 이 노드가 들고 있어야
      // 안쪽 GestureDetector 와 갈라지지 않는다.
      button: !widget.link && widget.onTap != null,
      link: widget.link && widget.onTap != null,
      label: widget.label,
      onTap: widget.onTap,
      child: TpPressable(
        // 바깥 Semantics 가 버튼·링크·이름·액션을 다 들고 있다.
        semantics: false,
        onTap: widget.onTap,
        haptic: TpHaptic.selection,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minSize,
            minHeight: widget.minSize,
          ),
          child: Center(widthFactor: 1, heightFactor: 1, child: widget.child),
        ),
        // AnimatedScale 을 그대로 둔다. 시간은 뼈대가 들고 있으므로 여기서는
        // 0 이다 — 붓이지 시계가 아니다.
        builder: (context, press, child) => AnimatedScale(
          scale: 1 - (1 - widget.pressScale) * press,
          duration: Duration.zero,
          child: child,
        ),
      ),
    );
  }
}
