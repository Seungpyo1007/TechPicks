import 'package:flutter/material.dart';

import 'tp_press.dart';
import 'tp_pressable.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';

/// 버튼의 무게.
enum TpButtonKind {
  /// 파란 채움. 화면당 하나가 원칙이다.
  primary,

  /// 유리·톤 위의 밝은 알약.
  secondary,

  /// 채움도 테두리도 없는 글자 버튼. 파란 글씨다.
  plain,
}

/// 앱의 알약 버튼. **한 벌뿐이다.**
///
/// 전에는 같은 모양을 화면마다 따로 그렸다 — 홈 46, 상세 52, 로그인 52,
/// 온보딩 52, 랭킹 52/56, 스캔 46, 에러 46. 일곱 벌이 높이도 눌림 반응도
/// 제각각이었고, **일곱 벌 다 눌러도 아무 일이 없었다.**
///
/// 여기 모아 두면 규칙이 하나다: 높이 [height], 눌리면 0.97 로 줄고 살짝
/// 밝아진다(`motion.press`), 히트 영역은 알약 전체다.
class TpButton extends StatefulWidget {
  const TpButton({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = TpButtonKind.primary,
    this.icon,
    this.height = 52,
    this.expand = true,
    this.alignStart = false,
  });

  final String label;
  final VoidCallback? onTap;
  final TpButtonKind kind;

  /// 라벨 앞에 붙는 표시. 없으면 라벨만 가운데 놓는다.
  final Widget? icon;

  /// 명세가 52 를 준다. 카드 안에 들어가는 두 짝 버튼만 46 을 쓴다.
  final double height;

  /// 가로를 다 쓸지. 랭킹의 FAB 처럼 내용만큼만 차지해야 하는 곳은 false.
  final bool expand;

  /// 라벨을 왼쪽에 붙일지. 로그인 버튼은 명세가 왼쪽 정렬 + 왼쪽 마크다.
  final bool alignStart;

  @override
  State<TpButton> createState() => _TpButtonState();
}

class _TpButtonState extends State<TpButton> {
  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final filled = widget.kind == TpButtonKind.primary;
    final plain = widget.kind == TpButtonKind.plain;

    final label = Text(
      widget.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: widget.alignStart ? TextAlign.start : TextAlign.center,
      style: type.body.copyWith(
        fontWeight: t.boldWeight,
        color: filled
            ? Colors.white
            : plain
            ? t.link
            : t.ink,
      ),
    );

    return Semantics(
      button: true,
      child: LayoutBuilder(
        builder: (context, box) => TpPressable(
          onTap: widget.onTap,
          haptic: TpHaptic.impact,
          child: AnimatedContainer(
            // 상태가 바뀌어 색이 갈릴 때(담기 → 담김)는 선택 박자를 쓴다.
            duration: context.motion.selection.duration,
            curve: context.motion.selection.curve,
            height: widget.height,
            width: widget.expand ? double.infinity : null,
            padding: widget.alignStart
                ? const EdgeInsets.symmetric(horizontal: 18)
                : widget.expand
                ? null
                : const EdgeInsets.symmetric(horizontal: 20),
            alignment: widget.alignStart
                ? Alignment.centerLeft
                : Alignment.center,
            decoration: BoxDecoration(
              color: plain
                  ? Colors.transparent
                  : filled
                  ? TpTokens.blue
                  : t.chipBg,
              borderRadius: BorderRadius.circular(
                t.isGlass ? TpTokens.rControl : t.rInner,
              ),
              boxShadow: filled ? t.buttonShadow : null,
            ),
            child: widget.icon == null
                ? label
                : Row(
                    mainAxisSize: widget.alignStart
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    children: <Widget>[
                      widget.icon!,
                      const SizedBox(width: 14),
                      Flexible(child: label),
                    ],
                  ),
          ),
          builder: (context, press, child) {
            // 쉴 때는 아무것도 안 얹는다. 항등 필터라도 한 겹 더 그리는
            // 일이고, 색이 미세하게 달라진다.
            if (press == 0) return child!;
            return TpPressPaint.scale(
              press,
              box.maxWidth,
              ColorFiltered(
                colorFilter: filled
                    // 채운 면은 눌린 만큼 어두워진다. 밝히면 파랑이 바래
                    // 비활성처럼 보인다.
                    ? TpPressFeel.darken(press)
                    : TpPress.filterAt(press),
                child: child,
              ),
            );
          },
        ),
      ),
    );
  }
}
