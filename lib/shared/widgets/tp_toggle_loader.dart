import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';

/// 로고의 토글을 줄인 기다림 표시. 질문의 답을 기다릴 때만 쓴다.
///
/// 1.4초마다 꺼짐 → 켜짐(채움) → 머묾 → 꺼짐. iOS 는 움직이는 동안 손잡이가
/// 가로로 늘어난 유리 렌즈가 된다. `motion.loops` 가 꺼져 있으면(동작 줄이기,
/// 테스트) 켜진 채로 멈춘다. 디자인 캔버스 "시작 · 로딩" 3–4.
class TpToggleLoader extends StatefulWidget {
  const TpToggleLoader({super.key});

  static const Size size = Size(38, 20);
  static const Duration period = Duration(milliseconds: 1400);

  /// 한 주기 안에서 손잡이 자리(0 왼쪽 · 1 오른쪽)와 움직이는 정도.
  static ({double at, double moving}) phase(double t) {
    const curve = Cubic(.45, 0, .2, 1);
    double move(double a, double b) => curve.transform((t - a) / (b - a));
    if (t < .12) return (at: 0, moving: 0);
    if (t < .44) {
      final p = (t - .12) / .32;
      return (at: move(.12, .44), moving: math.sin(math.pi * p));
    }
    if (t < .62) return (at: 1, moving: 0);
    if (t < .94) {
      final p = (t - .62) / .32;
      return (at: 1 - move(.62, .94), moving: math.sin(math.pi * p));
    }
    return (at: 0, moving: 0);
  }

  @override
  State<TpToggleLoader> createState() => _TpToggleLoaderState();
}

class _TpToggleLoaderState extends State<TpToggleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: TpToggleLoader.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.motion.loops) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final scheme = Theme.of(context).colorScheme;
    final fill = glass ? const Color(0xFF0A84FF) : scheme.primary;
    final knob = glass ? Colors.white : scheme.onPrimary;
    final track = glass ? sys.fill : scheme.surfaceContainerHighest;
    final loops = context.motion.loops;

    return ExcludeSemantics(
      child: SizedBox.fromSize(
        size: TpToggleLoader.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final p = loops
                ? TpToggleLoader.phase(_c.value)
                : (at: 1.0, moving: 0.0);
            const inset = 2.0;
            const d = 16.0;
            final travel = TpToggleLoader.size.width - d - inset * 2;
            final lens = glass ? 1 + .45 * p.moving : 1.0;
            final w = d * lens;
            final x = inset + travel * p.at - (w - d) * p.at;
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: ColoredBox(color: track)),
                  // 채움은 손잡이 오른쪽 끝까지 둥근 캡슐이라 손잡이와 이어진다.
                  // 꺼져 있을 때는 없고, 손잡이가 떠나면서 차오른다.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: x + w + inset,
                    child: Opacity(
                      opacity: math.min(1, p.at * 4),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: fill,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: x,
                    top: inset,
                    width: w,
                    height: d,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: knob,
                        borderRadius: BorderRadius.circular(d / 2),
                        boxShadow: glass
                            ? const <BoxShadow>[
                                BoxShadow(
                                  color: Color(0x2E000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
