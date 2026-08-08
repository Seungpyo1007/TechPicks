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
    final enabled = widget.onTap != null;

    return Semantics(
      // 못 누르는 칩은 버튼이라고 하지 않는다.
      button: enabled,
      selected: widget.selected,
      child: GestureDetector(
        onTap: widget.onTap,
        // 못 누르는 칩은 눌린 척도 하지 않는다. onTapDown 만 달아둬도
        // 시맨틱 트리에 탭 액션이 생겨 버튼처럼 읽힌다.
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
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
                color: widget.selected ? Colors.white : TpTokens.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
