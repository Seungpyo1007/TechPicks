import 'package:flutter/material.dart';
import 'package:native_liquid_glass/native_liquid_glass.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';

/// 켜고 끄기. iOS 26 은 진짜 UISwitch, 그 아래 iOS 는 같은 치수로 그린 것,
/// Android 는 M3 [Switch].
///
/// Flutter 의 CupertinoSwitch 는 iOS 18 까지의 둥근 손잡이라 설정 목록에서
/// 혼자 옛날 모양이다. 유리 손잡이는 UIKit 만 그릴 수 있다.
class TpSwitch extends StatelessWidget {
  const TpSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    if (!context.tp.isGlass) return Switch(value: value, onChanged: onChanged);
    // iOS 26: 진짜 UISwitch. 누르면 손잡이가 유리 렌즈로 바뀐다.
    if (TpNativeGlass.enabled) {
      return LiquidGlassToggle(value: value, onChanged: onChanged);
    }
    return _GlassSwitch(value: value, onChanged: onChanged);
  }
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
