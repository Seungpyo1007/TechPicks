import '../../app/theme/tp_motion.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import 'tp_press.dart';
import 'tp_pressable.dart';

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
      child: TpPressable(
        onTap: widget.onTap,
        haptic: TpHaptic.selection,
        // 알약은 36pt 라 접근성 기준(44)에 못 미친다. 위아래로 4pt 씩
        // 눌리는 영역만 넓힌다 — 보이는 크기는 그대로다.
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
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
                    ? t.ink
                    : t.dim,
              ),
            ),
          ),
        ),
        builder: (context, press, child) {
          if (press == 0) return child!;
          // 칩은 가로 목록 안이라 폭이 무한대로 들어온다. 알약은 원래 작아서
          // 비율 0.97 이 맞는 자리다.
          return Transform.scale(
            scale: 1 - 0.03 * press,
            transformHitTests: false,
            child: ColorFiltered(
              // 고른 칩은 파란 채움이라 밝히면 바랜다. 눌린 만큼 어둡게.
              colorFilter: widget.selected
                  ? TpPressFeel.darken(press)
                  : TpPress.filterAt(press),
              child: child,
            ),
          );
        },
      ),
    );
  }
}
