import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../shared/tp_haptics.dart';

/// 2.5D 기기 무대. 모델 파일 없이 판 여러 장을 원근으로 쌓는다.
///
/// - 드래그로 돌린다. 놓으면 던진 방향으로 조금 더 가다가 한계 안으로 스프링.
/// - 두 번 탭하면 정면으로 돌아온다.
/// - 부품을 고르면 판들이 벌어지고(분해도) 고른 판만 액센트로 칠해진다.
/// - 아무도 안 만지면 천천히 흔들린다(`motion.loops`). 한 번 만지면 멈춘다.
/// - 동작 줄이기면 회전·흔들림·벌어짐이 없고 강조만 바뀐다.
class ViewerStage extends StatefulWidget {
  const ViewerStage({
    super.key,
    this.part,
    this.interactive = true,
    this.ink = Colors.white,
  });

  /// 고른 부품. [ViewerLayer.part] 와 같은 번호(0 화면, 1 배터리, 2 칩, 3 카메라).
  final int? part;

  /// 드래그·두 번 탭을 받을지. 상세의 그림 자리처럼 스크롤 안에 놓일 때는 끈다 —
  /// 켜 두면 그 위에서 시작한 스크롤을 가로챈다.
  final bool interactive;

  /// 선 색. 뷰어의 어두운 무대는 흰색, 밝은 카드 위에서는 글자색.
  final Color ink;

  /// 기기 크기.
  static const Size device = Size(150, 290);

  /// 드래그 한계. 이 너머는 고무줄처럼 버티다 돌아온다.
  static const double yawLimit = 35 * math.pi / 180;
  static const double pitchLimit = 20 * math.pi / 180;

  /// 분해도의 보는 각도. 옆에서 비스듬히 봐야 판 사이가 보인다.
  static const double explodedYaw = 0.62;
  static const double explodedPitch = -0.32;

  @override
  State<ViewerStage> createState() => ViewerStageState();
}

@visibleForTesting
class ViewerStageState extends State<ViewerStage>
    with TickerProviderStateMixin {
  late final AnimationController _yaw = AnimationController.unbounded(
    vsync: this,
  );
  late final AnimationController _pitch = AnimationController.unbounded(
    vsync: this,
  );

  /// 0 합쳐짐 → 1 벌어짐.
  late final AnimationController _explode = AnimationController.unbounded(
    vsync: this,
  );

  /// 대기 흔들림 시계.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );

  bool _touched = false;

  double get yaw => _yaw.value;
  double get pitch => _pitch.value;
  double get explode => _explode.value;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.motion.loops && !_touched) {
      if (!_idle.isAnimating) _idle.repeat();
    } else {
      _idle.stop();
    }
    if (widget.part != null &&
        _explode.value == 0 &&
        !context.motion.isReduced) {
      _explode.value = _rest();
    }
  }

  @override
  void didUpdateWidget(ViewerStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.part == null) == (oldWidget.part == null)) return;
    if (widget.part != null) TpHaptics.impact();
    _go(_explode, _rest(), bouncy: true);
    // 벌어지면 비스듬히, 합쳐지면 정면으로.
    _go(_yaw, widget.part == null ? 0 : ViewerStage.explodedYaw);
    _go(_pitch, widget.part == null ? 0 : ViewerStage.explodedPitch);
  }

  double _rest() => widget.part == null ? 0 : 1;

  void _go(
    AnimationController c,
    double target, {
    double velocity = 0,
    bool bouncy = false,
  }) {
    final motion = context.motion;
    // 동작 줄이기: 돌지도 벌어지지도 않는다. 강조는 페인터가 따로 칠한다.
    if (motion.isReduced) {
      c.value = 0;
      return;
    }
    final spring = bouncy ? motion.bouncy : motion.smooth;
    c.animateWith(
      spring.createSimulation(start: c.value, end: target, velocity: velocity),
    );
  }

  void _stopIdle() {
    if (_touched) return;
    _touched = true;
    // 흔들리던 각도를 그대로 이어받는다. 끊기면 튄다.
    final sway = _sway();
    _idle.stop();
    _yaw.value += sway;
  }

  double _sway() => _idle.isAnimating || _idle.value > 0
      ? math.sin(_idle.value * 2 * math.pi) * 0.22
      : 0;

  /// 한계 밖에서는 손가락을 덜 따라온다.
  static double _rubber(double value, double delta, double limit) {
    final over = value.abs() - limit;
    if (over <= 0 || value.sign != delta.sign) return value + delta;
    return value + delta / (1 + over * 6);
  }

  void _panStart(DragStartDetails _) {
    _stopIdle();
    _yaw.stop();
    _pitch.stop();
  }

  void _panUpdate(DragUpdateDetails d) {
    if (context.motion.isReduced) return;
    _yaw.value = _rubber(_yaw.value, d.delta.dx * 0.01, ViewerStage.yawLimit);
    _pitch.value = _rubber(
      _pitch.value,
      -d.delta.dy * 0.01,
      ViewerStage.pitchLimit,
    );
  }

  void _panEnd(DragEndDetails d) {
    if (context.motion.isReduced) return;
    final v = d.velocity.pixelsPerSecond * 0.01;
    // 던진 만큼 조금 더 가되 한계 안에서 멈춘다.
    final yaw = (_yaw.value + v.dx * 0.12).clamp(
      -ViewerStage.yawLimit,
      ViewerStage.yawLimit,
    );
    final pitch = (_pitch.value - v.dy * 0.12).clamp(
      -ViewerStage.pitchLimit,
      ViewerStage.pitchLimit,
    );
    _go(_yaw, yaw, velocity: v.dx);
    _go(_pitch, pitch, velocity: -v.dy);
  }

  void _reset() {
    _stopIdle();
    _go(_yaw, widget.part == null ? 0 : ViewerStage.explodedYaw);
    _go(_pitch, widget.part == null ? 0 : ViewerStage.explodedPitch);
  }

  @override
  void dispose() {
    _yaw.dispose();
    _pitch.dispose();
    _explode.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.interactive;
    return GestureDetector(
      behavior: interactive
          ? HitTestBehavior.opaque
          : HitTestBehavior.deferToChild,
      onPanStart: interactive ? _panStart : null,
      onPanUpdate: interactive ? _panUpdate : null,
      onPanEnd: interactive ? _panEnd : null,
      onDoubleTap: interactive ? _reset : null,
      child: AnimatedBuilder(
        animation: Listenable.merge(<Listenable>[
          _yaw,
          _pitch,
          _explode,
          _idle,
        ]),
        builder: (context, _) {
          final yaw = _yaw.value + (_touched ? 0 : _sway());
          final pitch = _pitch.value;
          final spread = _explode.value;
          return Center(
            child: SizedBox(
              width: ViewerStage.device.width * 1.9,
              height: ViewerStage.device.height * 1.25,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // 바닥 그림자. 벌어질수록 넓고 옅다.
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: 170 + 60 * spread,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: <Color>[
                            widget.ink.withValues(alpha: .09 - .03 * spread),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // 뒤에서 앞으로.
                  for (final layer in ViewerLayer.backToFront)
                    Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0012)
                        ..rotateX(pitch)
                        ..rotateY(yaw)
                        ..translateByDouble(
                          0,
                          0,
                          layer.depth * (4 + 26 * spread),
                          1,
                        ),
                      child: CustomPaint(
                        size: ViewerStage.device,
                        painter: _LayerPainter(
                          layer: layer,
                          ink: widget.ink,
                          selected:
                              widget.part != null && layer.part == widget.part,
                          dim: widget.part != null && layer.part != widget.part
                              ? spread.clamp(0.0, 1.0)
                              : 0,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 기기를 이루는 판. [depth] 가 클수록 뒤(화면에서 먼 쪽)다.
enum ViewerLayer {
  back(3, null),
  camera(2.4, 3),
  board(1.4, 2),
  battery(0.6, 1),
  frame(0, null),
  display(-1, 0),
  glass(-1.8, null);

  const ViewerLayer(this.depth, this.part);

  final double depth;

  /// 부품 칩 번호. 칩이 없는 판은 null.
  final int? part;

  static List<ViewerLayer> get backToFront => values;
}

class _LayerPainter extends CustomPainter {
  _LayerPainter({
    required this.layer,
    required this.selected,
    required this.dim,
    required this.ink,
  });

  final ViewerLayer layer;
  final Color ink;
  final bool selected;

  /// 고르지 않은 판이 흐려지는 정도.
  final double dim;

  @override
  void paint(Canvas canvas, Size size) {
    final a = 1 - 0.6 * dim;
    Paint stroke(double alpha, [double w = 1.2]) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 1.6 : w
      ..color = selected ? TpSys.accent : ink.withValues(alpha: alpha * a);
    Paint fill(double alpha) => Paint()
      ..color = selected
          ? TpSys.accent.withValues(alpha: .30)
          : ink.withValues(alpha: alpha * a);

    final body = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    switch (layer) {
      case ViewerLayer.back:
        canvas
          ..drawRRect(body, fill(.05))
          ..drawRRect(body, stroke(.22));
      case ViewerLayer.frame:
        canvas.drawRRect(body.deflate(1), stroke(.32, 2));
      case ViewerLayer.glass:
        canvas
          ..drawRRect(body, fill(.03))
          ..drawRRect(body, stroke(.18));
      case ViewerLayer.display:
        final r = body.deflate(7);
        canvas
          ..drawRRect(r, fill(.07))
          ..drawRRect(r, stroke(.16));
      case ViewerLayer.battery:
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            18,
            size.height * .38,
            size.width - 36,
            size.height * .5,
          ),
          const Radius.circular(10),
        );
        canvas
          ..drawRRect(r, fill(.06))
          ..drawRRect(r, stroke(.3));
      case ViewerLayer.board:
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(14, 14, size.width - 28, size.height * .3),
          const Radius.circular(8),
        );
        final chip = RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width / 2 + 12, 14 + size.height * .15),
            width: 34,
            height: 34,
          ),
          const Radius.circular(6),
        );
        canvas
          ..drawRRect(r, fill(.04))
          ..drawRRect(r, stroke(.26))
          ..drawRRect(chip, fill(.1))
          ..drawRRect(chip, stroke(.4));
      case ViewerLayer.camera:
        final module = RRect.fromRectAndRadius(
          const Rect.fromLTWH(14, 14, 58, 58),
          const Radius.circular(16),
        );
        canvas
          ..drawRRect(module, fill(.06))
          ..drawRRect(module, stroke(.34));
        for (final c in const <Offset>[
          Offset(30, 30),
          Offset(56, 30),
          Offset(30, 56),
        ]) {
          canvas.drawCircle(c, 9, stroke(.4));
        }
    }
  }

  @override
  bool shouldRepaint(_LayerPainter old) =>
      old.layer != layer ||
      old.selected != selected ||
      old.dim != dim ||
      old.ink != ink;
}
