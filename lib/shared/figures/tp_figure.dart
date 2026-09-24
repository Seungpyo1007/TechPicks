import 'package:flutter/widgets.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';

/// 그림 한 장이 어떻게 그려지는지. 0–1 진행도와 시스템 색을 받는다.
typedef TpFigurePaint =
    void Function(Canvas canvas, Size size, double t, TpSys sys);

/// 코드로 그린 일러스트. [active] 가 되면 한 번 재생하고 끝 프레임에서 멈춘다.
///
/// - 색은 [TpSys] 만 쓴다. 다크 모드는 따로 없다.
/// - 동작 줄이기면 끝 프레임만 그린다.
/// - 장식이라 스크린 리더에는 안 보인다. 뜻은 옆의 글자가 말한다.
/// - [active] 가 false 에서 true 로 바뀌면 처음부터 다시 튼다(온보딩 페이지).
class TpFigure extends StatefulWidget {
  const TpFigure({
    super.key,
    required this.paint,
    required this.height,
    this.duration = const Duration(milliseconds: 1900),
    this.active = true,
    this.delay = Duration.zero,
  });

  final TpFigurePaint paint;
  final double height;
  final Duration duration;
  final bool active;

  /// 화면이 자리를 잡은 뒤에 시작하려고 둔다.
  final Duration delay;

  @override
  State<TpFigure> createState() => _TpFigureState();
}

class _TpFigureState extends State<TpFigure>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration + widget.delay,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.active) _play();
  }

  @override
  void didUpdateWidget(TpFigure old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  void _play() {
    _started = true;
    if (context.motion.isReduced) {
      _c.value = 1;
      return;
    }
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final total = _c.duration!.inMicroseconds;
    final start = widget.delay.inMicroseconds / total;
    return ExcludeSemantics(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              // 아직 안 틀었으면 첫 프레임, 틀었으면 지연을 뺀 진행도.
              final raw = _started ? _c.value : 0.0;
              final t = start >= 1
                  ? raw
                  : ((raw - start) / (1 - start)).clamp(0.0, 1.0);
              return CustomPaint(painter: _Painter(widget.paint, t, sys));
            },
          ),
        ),
      ),
    );
  }
}

class _Painter extends CustomPainter {
  _Painter(this.draw, this.t, this.sys);

  final TpFigurePaint draw;
  final double t;
  final TpSys sys;

  @override
  void paint(Canvas canvas, Size size) => draw(canvas, size, t, sys);

  @override
  bool shouldRepaint(_Painter old) =>
      old.t != t || old.sys != sys || old.draw != draw;
}

/// 그림 안의 구간. [t] 가 [a]..[b] 사이에서 0→1 로 가고, 그 밖에서는 멈춘다.
double span(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

/// 스프링처럼 살짝 넘었다 돌아오는 구간. 코드 그림은 시간축 하나로 돌아서
/// 진짜 스프링 대신 같은 모양의 커브를 쓴다.
double pop(double t, double a, double b) => span(t, a, b, Curves.easeOutBack);
