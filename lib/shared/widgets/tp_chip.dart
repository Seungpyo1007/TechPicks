import '../../app/theme/tp_motion.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';

/// 카테고리·정렬 축을 고르는 알약 칩.
///
/// 활성은 파란 채움에 흰 글자. 누르면 90ms 동안 0.97 로 줄었다 돌아온다
/// (`docs/DESIGN_HANDOFF.md` — Interactions).
class TpChip extends StatefulWidget {
  const TpChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<TpChip> createState() => _TpChipState();
}

class _TpChipState extends State<TpChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final motion = context.motion;
    final enabled = widget.onTap != null;

    return Semantics(
      // 못 누르는 칩은 버튼이라고 하지 않는다.
      button: enabled,
      selected: widget.selected,
      // decoration: 으로 칠한 상자는 히트 테스트에 안 잡힌다. 이게 없으면
      // 버튼이 글자 글리프 위에서만 눌린다.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        // 못 누르는 칩은 눌린 척도 하지 않는다. onTapDown 만 달아둬도
        // 시맨틱 트리에 탭 액션이 생겨 버튼처럼 읽힌다.
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        // 알약은 36pt 라 접근성 기준(44)에 못 미친다. 위아래로 4pt 씩
        // 눌리는 영역만 넓힌다 — 보이는 크기는 그대로다.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: AnimatedScale(
            scale: _pressed ? 0.97 : 1,
            duration: motion.press.duration,
            curve: motion.press.curve,
            child: AnimatedContainer(
              duration: motion.selection.duration,
              curve: motion.selection.curve,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: widget.selected ? TpTokens.blue : t.chipBg,
                borderRadius: BorderRadius.circular(TpTokens.rControl),
              ),
              child: Text(
                widget.label,
                style: type.body.copyWith(
                  fontSize: 13.5,
                  fontWeight: t.boldWeight,
                  // 못 누르는 칩은 그렇게 보여야 한다. 랭킹의 Laptops 가
                  // 데이터가 없어 꺼져 있는데 켜진 것과 똑같이 생겼었다.
                  color: widget.selected
                      ? Colors.white
                      : enabled
                      ? TpTokens.ink
                      : t.dim,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
