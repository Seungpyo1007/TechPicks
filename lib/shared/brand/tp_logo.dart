import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 앱 아이콘을 코드로 그린 것. 토글이 켜지는 정도([on], 0–1)를 받는다.
///
/// 시작 장면에서 토글을 켜려고 PNG 대신 그린다. 네이티브 스플래시 PNG 도
/// 이 그림의 `on: 0` 을 그대로 떠서 만든다(`tool/icons/render_splash_test.dart`).
/// 도형은 `tool/icons` 의 아이콘 원본과 같다 — 1024 캔버스, 30° 기울기.
///
/// - iOS: 흰 판 위 유리 막대, 손잡이는 움직이는 동안 가로로 늘어난 렌즈
/// - Android: 원 판 위 평면 막대(M3), 손잡이는 켜지며 커진다
class TpLogo extends StatelessWidget {
  const TpLogo({
    super.key,
    required this.size,
    this.on = 1,
    this.android = false,
    this.dark = false,
  });

  final double size;

  /// 0 은 꺼짐(손잡이가 오른쪽 끝, 채움 없음), 1 은 앱 아이콘과 같은 모양.
  final double on;
  final bool android;
  final bool dark;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: android
          ? _M3Painter(on: on, dark: dark)
          : _GlassPainter(on: on, dark: dark),
    ),
  );
}

// ── 공통 도형 ─────────────────────────────────────────────────

const double _angle = 30 * math.pi / 180;
const double _h = 150;
const Offset _shift = Offset(-10, 12);

/// (가운데, 길이). 위에서부터 토글 막대, 가운데, 아래.
const List<(Offset, double)> _bars = <(Offset, double)>[
  (Offset(551, 270), 569),
  (Offset(510, 510), 607),
  (Offset(553, 796), 304),
];

/// 켜진 손잡이의 막대 축 위 자리(막대 가운데 기준). 원본 로고의 (531, 256).
final double _knobOn = () {
  const d = Offset(531 - 551, 256 - 270);
  return d.dx * math.cos(_angle) + d.dy * math.sin(_angle);
}();

/// 꺼진 손잡이: 오른쪽 끝 캡의 가운데.
double get _knobOff => _bars[0].$2 / 2 - _h / 2;

double _knobAt(double on) => _knobOff + (_knobOn - _knobOff) * on;

RRect _capsule(double length) => RRect.fromRectAndRadius(
  Rect.fromCenter(center: Offset.zero, width: length, height: _h),
  const Radius.circular(_h / 2),
);

/// 막대 좌표계(가운데가 원점, 축이 x)로 옮겨 그린다.
void _inBar(Canvas canvas, int i, void Function() draw) {
  canvas
    ..save()
    ..translate(_bars[i].$1.dx + _shift.dx, _bars[i].$1.dy + _shift.dy)
    ..rotate(_angle);
  draw();
  canvas.restore();
}

// ── iOS 26 유리 ─────────────────────────────────────────────

class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.on, required this.dark});

  final double on;
  final bool dark;

  static const List<List<Color>> _light = <List<Color>>[
    <Color>[Color(0xFF3C66A6), Color(0xFF2F5A99)],
    <Color>[Color(0xFF4C7FC2), Color(0xFF3A6BB0)],
    <Color>[Color(0xFF6AA2E6), Color(0xFF4F86CC)],
  ];
  static const List<List<Color>> _dark = <List<Color>>[
    <Color>[Color(0xFF9CC3F5), Color(0xFF7EAAE6)],
    <Color>[Color(0xFF7FA9E3), Color(0xFF628FCF)],
    <Color>[Color(0xFF5E88C6), Color(0xFF4A73B0)],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024);
    const full = Rect.fromLTWH(0, 0, 1024, 1024);
    final plate = RRect.fromRectAndRadius(
      full,
      const Radius.circular(1024 * .2237),
    );
    canvas
      ..save()
      ..clipRRect(plate)
      ..drawRect(
        full,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const <Color>[Color(0xFF1A2638), Color(0xFF0B111B)]
                : const <Color>[Color(0xFFFFFFFF), Color(0xFFE6EDF7)],
          ).createShader(full),
      );

    final colors = dark ? _dark : _light;
    final shadow = Paint()
      ..color = (dark ? const Color(0xFF000000) : const Color(0xFF16335E))
          .withValues(alpha: dark ? .5 : .22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final highlight = dark ? .35 : .45;

    for (final i in <int>[2, 1, 0]) {
      final length = _bars[i].$2;
      final shape = _capsule(length);
      final rect = shape.outerRect;
      _inBar(canvas, i, () {
        canvas
          ..drawRRect(shape.shift(const Offset(0, 16)), shadow)
          ..drawRRect(
            shape,
            Paint()
              ..shader = LinearGradient(
                colors: <Color>[
                  for (final c in colors[i])
                    c.withValues(alpha: dark ? .9 : .92),
                ],
              ).createShader(rect),
          );
        if (i == 0) _fill(canvas, shape);
        canvas
          ..drawRRect(
            shape,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  const Color(0xFFFFFFFF).withValues(alpha: highlight),
                  const Color(0x00FFFFFF),
                  const Color(0xFFFFFFFF).withValues(alpha: highlight * .35),
                ],
                stops: const <double>[0, .5, 1],
              ).createShader(rect),
          )
          ..save()
          ..clipRRect(shape)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                rect.left + _h * .35,
                rect.top + 10,
                length - _h * .7,
                10,
              ),
              const Radius.circular(5),
            ),
            Paint()
              ..color = const Color(
                0xFFFFFFFF,
              ).withValues(alpha: dark ? .45 : .55),
          )
          ..restore()
          ..drawRRect(
            shape.deflate(2.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: const Alignment(-.3, 1),
                colors: const <Color>[
                  Color(0xF2FFFFFF),
                  Color(0x1FFFFFFF),
                  Color(0x8CFFFFFF),
                ],
                stops: const <double>[0, .5, 1],
              ).createShader(rect),
          );
        if (i == 0) _knob(canvas, shadow);
      });
    }
    canvas.restore();
  }

  /// 손잡이가 지나간 자리(손잡이부터 오른쪽 끝까지)가 파랗게 남는다.
  void _fill(Canvas canvas, RRect shape) {
    final x = _knobAt(on);
    final rect = Rect.fromLTRB(x, -_h / 2, shape.right, _h / 2);
    if (rect.width <= 0) return;
    canvas
      ..save()
      ..clipRRect(shape)
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            colors: <Color>[Color(0xF23FA9FF), Color(0xF20A84FF)],
          ).createShader(rect),
      )
      ..restore();
  }

  /// 동그란 흰 유리 구슬. 움직이는 동안은 iOS 26 스위치처럼 가로로 늘어나
  /// 속이 비치는 렌즈가 된다.
  void _knob(Canvas canvas, Paint shadow) {
    const r = 76.0;
    final moving = math.sin(math.pi * on.clamp(0, 1));
    final w = r * 2 * (1 + .55 * moving);
    final h = r * 2 * (1 + .08 * moving);
    final c = Offset(_knobAt(on), 0);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: w, height: h),
      Radius.circular(h / 2),
    );
    final rect = body.outerRect;
    // 가만히 있으면 불투명한 흰색, 움직일수록 투명해진다.
    final solid = 1 - .7 * moving;
    canvas
      ..drawRRect(body.shift(const Offset(0, 14)), shadow)
      ..drawRRect(
        body,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.3, -.4),
            radius: .8,
            colors: <Color>[
              const Color(0xFFFFFFFF).withValues(alpha: solid),
              (dark ? const Color(0xFFC9D1DC) : const Color(0xFFE7ECF3))
                  .withValues(alpha: solid * .96),
            ],
          ).createShader(rect),
      )
      ..drawOval(
        Rect.fromCenter(
          center: c.translate(-20 - w * .06, -34),
          width: 76 + w * .12,
          height: 34,
        ),
        Paint()..color = const Color(0xD9FFFFFF),
      )
      ..drawRRect(
        body.deflate(2.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment(-.2, 1),
            colors: <Color>[
              Color(0xFFFFFFFF),
              Color(0x26FFFFFF),
              Color(0xB3FFFFFF),
            ],
            stops: <double>[0, .55, 1],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.on != on || old.dark != dark;
}

// ── Android Material 3 ──────────────────────────────────────

class _M3Painter extends CustomPainter {
  _M3Painter({required this.on, required this.dark});

  final double on;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 1024);
    final bg = dark ? const Color(0xFF1A2A45) : const Color(0xFFD8E2FF);
    final track = dark ? const Color(0xFF3C5680) : const Color(0xFF9DB5E0);
    final middle = dark ? const Color(0xFFA9C7FF) : const Color(0xFF3D64A3);
    final bottom = dark ? const Color(0xFF7E9FD6) : const Color(0xFF5A7FBF);
    final primary = dark ? const Color(0xFFA9C7FF) : const Color(0xFF2A5CAA);
    final thumbOn = dark ? const Color(0xFF0A2A5A) : const Color(0xFFFFFFFF);
    // M3 스위치의 꺼진 손잡이: 작고 outline 색.
    final thumbOff = dark ? const Color(0xFF8E9099) : const Color(0xFF5C6B8A);

    canvas.drawCircle(const Offset(512, 512), 512, Paint()..color = bg);
    // 적응형 아이콘 안전 영역 안으로(0.74).
    canvas
      ..translate(512, 512)
      ..scale(.74)
      ..translate(-512, -512);

    for (final (i, color) in <(int, Color)>[(2, bottom), (1, middle)]) {
      _inBar(canvas, i, () {
        canvas.drawRRect(_capsule(_bars[i].$2), Paint()..color = color);
      });
    }
    _inBar(canvas, 0, () {
      final shape = _capsule(_bars[0].$2);
      final x = _knobAt(on);
      canvas
        ..drawRRect(shape, Paint()..color = track)
        ..save()
        ..clipRRect(shape);
      final fill = Rect.fromLTRB(x - _h / 2, -_h / 2, shape.right, _h / 2);
      if (on > 0) {
        canvas.drawRect(
          fill,
          Paint()..color = primary.withValues(alpha: on.clamp(0, 1)),
        );
      }
      canvas
        ..restore()
        // 켜지며 커지고 색이 바뀐다(M3 스위치 16 → 24dp).
        ..drawCircle(
          Offset(x, 0),
          _h * (.24 + .12 * on),
          Paint()..color = Color.lerp(thumbOff, thumbOn, on)!,
        );
    });
  }

  @override
  bool shouldRepaint(_M3Painter old) => old.on != on || old.dark != dark;
}
