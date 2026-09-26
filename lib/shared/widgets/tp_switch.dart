import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';

/// 켜고 끄기. iOS 는 iOS 26 모양, Android 는 M3 [Switch].
///
/// Flutter 의 CupertinoSwitch 는 iOS 18 까지의 둥근 손잡이라 설정 목록에서
/// 혼자 옛날 모양이다. 네이티브 UISwitch 는 플랫폼 뷰라 목록 안에서 화면
/// 전환과 따로 논다. 그래서 iOS 26 치수로 직접 그린다.
class TpSwitch extends StatelessWidget {
  const TpSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => context.tp.isGlass
      ? _GlassSwitch(value: value, onChanged: onChanged)
      : Switch(value: value, onChanged: onChanged);
}

/// iOS 26 스위치: 트랙 64 × 28, 손잡이 38 × 24 캡슐, 안쪽 2.
class _GlassSwitch extends StatefulWidget {
  const _GlassSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  static const double width = 64;
  static const double height = 28;
  static const double inset = 2;
  static const double knob = 38;

  @override
  State<_GlassSwitch> createState() => _GlassSwitchState();
}

class _GlassSwitchState extends State<_GlassSwitch> {
  /// 누르고 있는 동안 손잡이가 조금 늘어난다(시스템과 같이).
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final move = context.motion.selection;
    final on = widget.value;
    final knob = _GlassSwitch.knob + (_down ? 6 : 0);
    return Semantics(
      toggled: on,
      onTap: () => widget.onChanged(!on),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapCancel: () => setState(() => _down = false),
        onTap: () {
          setState(() => _down = false);
          widget.onChanged(!on);
        },
        child: AnimatedContainer(
          duration: move.duration,
          curve: move.curve,
          width: _GlassSwitch.width,
          height: _GlassSwitch.height,
          padding: const EdgeInsets.all(_GlassSwitch.inset),
          decoration: BoxDecoration(
            color: on ? const Color(0xFF34C759) : sys.fill,
            borderRadius: BorderRadius.circular(_GlassSwitch.height / 2),
          ),
          child: AnimatedAlign(
            duration: move.duration,
            curve: move.curve,
            alignment: on ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: context.motion.press.duration,
              curve: move.curve,
              width: knob,
              height: _GlassSwitch.height - _GlassSwitch.inset * 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x26000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
