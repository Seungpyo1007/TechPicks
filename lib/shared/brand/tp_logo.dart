import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';

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
    this.plate = true,
  });

  final double size;

  /// 0 은 꺼짐(손잡이가 오른쪽 끝, 채움 없음), 1 은 앱 아이콘과 같은 모양.
  final double on;
  final bool android;
  final bool dark;

  /// 판(흰 둥근 네모·원)까지 그리는가. 시작 장면은 판만 따로 키우려고 끈다.
  final bool plate;

  /// 판의 색. 시작 장면이 이 색에서 앱 바탕색으로 넘어간다.
  static List<Color> plateColors({required bool android, required bool dark}) =>
      android
      ? <Color>[
          dark ? const Color(0xFF1A2A45) : const Color(0xFFD8E2FF),
          dark ? const Color(0xFF1A2A45) : const Color(0xFFD8E2FF),
        ]
      : dark
      ? const <Color>[Color(0xFF1A2638), Color(0xFF0B111B)]
      : const <Color>[Color(0xFFFFFFFF), Color(0xFFE6EDF7)];

  /// iOS 판 모서리(아이콘 한 변에 대한 비).
  static const double cornerRatio = .2237;

  /// Android 막대가 원 안에서 줄어드는 비(적응형 아이콘 안전 영역).
  static const double safeZone = .74;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: android
          ? _M3Painter(on: on, dark: dark, plate: plate)
          : _GlassPainter(on: on, dark: dark, plate: plate),
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
  _GlassPainter({required this.on, required this.dark, required this.plate});

  final double on;
  final bool dark;
  final bool plate;

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
    canvas.save();
    if (plate) {
      // iOS 아이콘처럼 연속 곡률 모서리. 시작 장면의 판도 같은 모양으로 커진다.
      canvas
        ..clipRSuperellipse(
          RSuperellipse.fromRectAndRadius(
            full,
            const Radius.circular(1024 * TpLogo.cornerRatio),
          ),
        )
        ..drawRect(
          full,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: TpLogo.plateColors(android: false, dark: dark),
            ).createShader(full),
        );
    }

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
  bool shouldRepaint(_GlassPainter old) =>
      old.on != on || old.dark != dark || old.plate != plate;
}

// ── Android Material 3 ──────────────────────────────────────

class _M3Painter extends CustomPainter {
  _M3Painter({required this.on, required this.dark, required this.plate});

  final double on;
  final bool dark;
  final bool plate;

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

    if (plate) {
      canvas.drawCircle(const Offset(512, 512), 512, Paint()..color = bg);
    }
    // 적응형 아이콘 안전 영역 안으로.
    canvas
      ..translate(512, 512)
      ..scale(TpLogo.safeZone)
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
  bool shouldRepaint(_M3Painter old) =>
      old.on != on || old.dark != dark || old.plate != plate;
}

// ── 로딩 표시 ──────────────────────────────────────────────

/// 앱의 모든 기다림에 쓰는 표시. 디자인 캔버스 "로딩" G 줄.
///
/// - iOS(G2 선 그리기): 막대 테두리가 아래부터 그려지고 유리로 채워진 뒤
///   손잡이가 톡 튀어나온다. 옅은 막대 자리는 늘 남는다.
/// - Android(G1 M3 모양 변형): 톤 컨테이너가 M3 Expressive 일곱 모양으로
///   바뀌며 돌고 안에서 로고 막대가 물결로 차오른다. 32 보다 작으면 컨테이너
///   없이 막대만.
/// - 채운 버튼 안([TpLogoLoader.mono]): 한 색 물결.
///
/// `motion.loops` 가 꺼져 있으면(동작 줄이기, 테스트) 꽉 찬 로고로 멈춘다.
class TpLogoLoader extends StatefulWidget {
  const TpLogoLoader({super.key, this.size = 24}) : mono = null, knob = null;

  /// 채운 버튼 안: 막대는 [mono] 한 색, 손잡이는 [knob](버튼 바탕색).
  const TpLogoLoader.mono({
    super.key,
    this.size = 16,
    required Color this.mono,
    required Color this.knob,
  });

  /// 16 버튼·글 옆, 24 목록·말풍선, 48 화면 가운데.
  final double size;
  final Color? mono;
  final Color? knob;

  static const Duration period = Duration(milliseconds: 1800);

  /// 한 막대의 차오른 정도. 0.55 까지 차고, 0.8 까지 머물고, 끝에서 비운다.
  static double fillAt(double t) {
    const curve = Cubic(.45, 0, .2, 1);
    final p = t % 1;
    if (p < .55) return .06 + .94 * curve.transform(p / .55);
    if (p < .8) return 1;
    return 1 - .94 * curve.transform((p - .8) / .2);
  }

  @override
  State<TpLogoLoader> createState() => _TpLogoLoaderState();
}

class _TpLogoLoaderState extends State<TpLogoLoader>
    with SingleTickerProviderStateMixin {
  // 주기가 셋이라(물결 1.8초, 선 그리기 2.6초, 모양 변형 4.55초) 한 시간짜리
  // 시계 하나에서 초를 읽어 각자 나눈다.
  static const Duration _clock = Duration(hours: 1);
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _clock,
  );
  bool _loops = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loops = context.motion.loops;
    if (_loops) {
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
    final glass = context.tp.isGlass;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _LoaderPainter(
              t: _c,
              seconds: _clock.inSeconds.toDouble(),
              loops: _loops,
              glass: glass,
              dark: dark,
              mono: widget.mono,
              knob: widget.knob,
            ),
          ),
        ),
      ),
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({
    required this.t,
    required this.seconds,
    required this.loops,
    required this.glass,
    required this.dark,
    this.mono,
    this.knob,
  }) : super(repaint: t);

  final Animation<double> t;

  /// [t] 한 바퀴의 초.
  final double seconds;
  final bool loops;
  final bool glass;
  final bool dark;
  final Color? mono;
  final Color? knob;

  /// 지금까지 흐른 초.
  double get _s => t.value * seconds;

  /// 이보다 작으면 Android 는 컨테이너 없이(M3: 버튼 안 표시는 맨 모양).
  static const double containerMin = 32;

  @override
  void paint(Canvas canvas, Size size) {
    if (mono != null) {
      _fitLogo(canvas, size);
      _paintMono(canvas);
    } else if (glass) {
      _fitLogo(canvas, size);
      _paintDraw(canvas, size);
    } else {
      _paintMorph(canvas, size);
    }
  }

  /// 로고가 차지하는 자리(1024 중 가운데 860)를 상자에 꽉 채운다.
  void _fitLogo(Canvas canvas, Size size) => canvas
    ..scale(size.width / 860)
    ..translate(-(517.0 - 430), -(510.0 - 430));

  /// 물결: 막대 i 의 차오른 정도. 아래 막대부터 0.18초씩 어긋난다.
  double _wave(int i) =>
      loops ? TpLogoLoader.fillAt(_s / 1.8 - .1 * (2 - i)) : 1.0;

  /// 토글 막대 채움의 왼쪽 끝. 다 차면 로고의 켜진 손잡이 자리.
  double _left(RRect shape, double f) =>
      shape.right - (shape.right - _knobOn) * f;

  Rect _fillRect(int i, RRect shape, double f) => i == 0
      ? Rect.fromLTRB(_left(shape, f), -_h / 2, shape.right, _h / 2)
      : Rect.fromLTRB(
          shape.left,
          -_h / 2,
          shape.left + shape.width * f,
          _h / 2,
        );

  // ── 한 색(채운 버튼 안): 물결 ──
  void _paintMono(Canvas canvas) {
    for (final i in <int>[2, 1, 0]) {
      final f = _wave(i);
      final shape = _capsule(_bars[i].$2);
      _inBar(canvas, i, () {
        canvas
          ..drawRRect(shape, Paint()..color = mono!.withValues(alpha: .22))
          ..save()
          ..clipRRect(shape)
          ..drawRect(_fillRect(i, shape, f), Paint()..color = mono!)
          ..restore();
        if (i == 0) {
          final x = math.min(_left(shape, f), shape.right - _h / 2);
          canvas.drawCircle(Offset(x, 0), _h * .36, Paint()..color = knob!);
        }
      });
    }
  }

  // ── iOS: 선 그리기 (디자인 캔버스 G2) ──
  //
  // 3.2초 한 바퀴. 막대마다 아래부터 0.25초씩 늦게: 테두리가 그려지고(0–45%)
  // → 다 그린 뒤 유리로 채워지고(45–58%) → 손잡이가 톡 튀어나오고(60–70%)
  // → 머물다(–88%) → 비운다. 빈 순간에도 옅은 막대 자리는 남는다.
  // 선은 화면에서 2.4 보다 가늘어지지 않게 크기에 맞춰 굵힌다.
  static const double _drawPeriod = 3.2;

  void _paintDraw(Canvas canvas, Size size) {
    final colors = dark ? _GlassPainter._dark : _GlassPainter._light;
    final p = loops ? (_s / _drawPeriod) % 1 : .75;
    final width = math.max(22.0, 2.4 * 860 / size.width);
    for (final i in <int>[2, 1, 0]) {
      final length = _bars[i].$2;
      final shape = _capsule(length);
      final q = loops ? (p - (2 - i) * .25 / _drawPeriod) % 1 : .75;
      final stroke = i == 0 ? const Color(0xFF0A84FF) : colors[i][0];
      final draw = Curves.easeInOutCubic.transform((q / .45).clamp(0, 1));
      final strokeAlpha = q < .55 ? 1.0 : 1 - ((q - .55) / .13).clamp(0, 1);
      final fill = q < .45
          ? 0.0
          : q < .58
          ? (q - .45) / .13
          : q < .88
          ? 1.0
          : 1 - (q - .88) / .12;
      _inBar(canvas, i, () {
        // 늘 남는 옅은 자리.
        canvas.drawRRect(
          shape,
          Paint()..color = stroke.withValues(alpha: dark ? .14 : .1),
        );
        if (fill > 0) {
          canvas.saveLayer(
            shape.outerRect.inflate(40),
            Paint()..color = Color.fromRGBO(0, 0, 0, fill.toDouble()),
          );
          _glassBar(canvas, i, shape, colors);
          canvas.restore();
        }
        if (strokeAlpha > 0 && draw > 0) {
          final path = Path()..addRRect(shape.deflate(width / 2));
          final metric = path.computeMetrics().first;
          canvas.drawPath(
            metric.extractPath(0, metric.length * draw),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = width
              ..strokeCap = StrokeCap.round
              ..color = stroke.withValues(alpha: strokeAlpha.toDouble()),
          );
        }
        if (i == 0) {
          // 0.6 부터 스프링으로 튀어나와 0.88 까지, 0.97 에 들어간다.
          final pop = q < .6
              ? 0.0
              : q < .7
              ? Curves.easeOutBack.transform((q - .6) / .1)
              : q < .88
              ? 1.0
              : q < .97
              ? 1 - Curves.easeIn.transform((q - .88) / .09)
              : 0.0;
          if (pop > 0) {
            canvas
              ..save()
              ..translate(_knobOn, 0)
              ..scale(pop)
              ..translate(-_knobOn, 0);
            _glassKnob(canvas, Offset(_knobOn, 0));
            canvas.restore();
          }
        }
      });
    }
  }

  /// 아이콘([_GlassPainter])과 같은 유리 막대 한 개. 토글 막대는 켜진 모양.
  void _glassBar(Canvas canvas, int i, RRect shape, List<List<Color>> colors) {
    final rect = shape.outerRect;
    final length = rect.width;
    final highlight = dark ? .35 : .45;
    canvas
      ..drawRRect(
        shape.shift(const Offset(0, 16)),
        Paint()
          ..color = (dark ? const Color(0xFF000000) : const Color(0xFF16335E))
              .withValues(alpha: dark ? .45 : .18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      )
      ..drawRRect(
        shape,
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              for (final c in colors[i]) c.withValues(alpha: dark ? .9 : .92),
            ],
          ).createShader(rect),
      );
    if (i == 0) {
      canvas
        ..save()
        ..clipRRect(shape)
        ..drawRect(
          Rect.fromLTRB(_knobOn, -_h / 2, shape.right, _h / 2),
          Paint()
            ..shader = const LinearGradient(
              colors: <Color>[Color(0xF23FA9FF), Color(0xF20A84FF)],
            ).createShader(rect),
        )
        ..restore();
    }
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
          ..color = const Color(0xFFFFFFFF).withValues(alpha: dark ? .45 : .55),
      )
      ..restore()
      ..drawRRect(
        shape.deflate(2.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment(-.3, 1),
            colors: <Color>[
              Color(0xF2FFFFFF),
              Color(0x1FFFFFFF),
              Color(0x8CFFFFFF),
            ],
            stops: <double>[0, .5, 1],
          ).createShader(rect),
      );
  }

  void _glassKnob(Canvas canvas, Offset c) {
    const r = 76.0;
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas
      ..drawCircle(
        c.translate(0, 12),
        r,
        Paint()
          ..color = const Color(0x3316335E)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      )
      ..drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-.3, -.4),
            radius: .8,
            colors: <Color>[
              const Color(0xFFFFFFFF),
              dark ? const Color(0xFFC9D1DC) : const Color(0xFFE7ECF3),
            ],
          ).createShader(rect),
      )
      ..drawOval(
        Rect.fromCenter(center: c.translate(-24, -34), width: 80, height: 34),
        Paint()..color = const Color(0xD9FFFFFF),
      );
  }

  // ── Android: M3 Expressive 모양 변형 (디자인 캔버스 G1) ──
  //
  // 톤 컨테이너가 일곱 모양을 0.65초씩 돌아가며 바뀌고 천천히 돈다. 안에서는
  // M3 로고 막대가 물결로 차오른다. 작은 크기(버튼 안)는 컨테이너 없이.
  static const double _morphStep = .65;

  /// 극좌표 반지름(1 이 기준 원). 별·쿠키9·오각·알약·해·쿠키4·타원.
  static double _shapeR(int k, double a) => switch (k % 7) {
    0 => .93 + .09 * math.cos(8 * a),
    1 => .94 + .07 * math.cos(9 * a),
    2 => .95 + .06 * math.cos(5 * a - math.pi / 2),
    3 => _ellipse(a - math.pi / 4, 1, .66),
    4 => .96 + .045 * math.cos(12 * a),
    5 => .9 + .1 * math.cos(4 * a),
    _ => _ellipse(a, 1, .8),
  };

  static double _ellipse(double a, double w, double h) =>
      1 /
      math.sqrt(math.pow(math.cos(a) / w, 2) + math.pow(math.sin(a) / h, 2));

  void _paintMorph(Canvas canvas, Size size) {
    final contained = size.width >= containerMin;
    if (contained) {
      final step = loops ? _s / _morphStep : 6.0;
      final k = step.floor();
      final e = const Cubic(.2, 0, 0, 1).transform(step - k);
      final spin = loops ? (_s / 6) * 2 * math.pi : 0.0;
      final c = size.center(Offset.zero);
      final big = size.width / 2;
      final path = Path();
      const n = 72;
      for (var j = 0; j < n; j++) {
        final a = 2 * math.pi * j / n;
        final r =
            big *
            .98 *
            (_shapeR(k, a) + (_shapeR(k + 1, a) - _shapeR(k, a)) * e);
        final pt = c + Offset(math.cos(a + spin), math.sin(a + spin)) * r;
        j == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = dark ? const Color(0xFF284777) : const Color(0xFFD8E2FF),
      );
      // 로고는 컨테이너의 절반 크기로 가운데.
      canvas
        ..translate(c.dx, c.dy)
        ..scale(.52)
        ..translate(-c.dx, -c.dy);
    }
    _fitLogo(canvas, size);
    _paintM3Bars(canvas);
  }

  void _paintM3Bars(Canvas canvas) {
    final track = dark ? const Color(0xFF3C5680) : const Color(0xFF9DB5E0);
    final middle = dark ? const Color(0xFFA9C7FF) : const Color(0xFF3D64A3);
    final bottom = dark ? const Color(0xFF7E9FD6) : const Color(0xFF5A7FBF);
    final primary = dark ? const Color(0xFFA9C7FF) : const Color(0xFF2A5CAA);
    final thumbOn = dark ? const Color(0xFF0A2A5A) : const Color(0xFFFFFFFF);
    final thumbOff = dark ? const Color(0xFF8E9099) : const Color(0xFF5C6B8A);

    for (final (i, color) in <(int, Color)>[(2, bottom), (1, middle)]) {
      final f = _wave(i);
      final shape = _capsule(_bars[i].$2);
      _inBar(canvas, i, () {
        canvas
          ..drawRRect(shape, Paint()..color = color.withValues(alpha: .28))
          ..save()
          ..clipRRect(shape)
          ..drawRect(_fillRect(i, shape, f), Paint()..color = color)
          ..restore();
      });
    }
    final f = _wave(0);
    _inBar(canvas, 0, () {
      final shape = _capsule(_bars[0].$2);
      final left = _left(shape, f);
      final x = math.min(left, shape.right - _h / 2);
      canvas
        ..drawRRect(shape, Paint()..color = track)
        ..save()
        ..clipRRect(shape)
        ..drawRect(
          Rect.fromLTRB(left - _h / 2, -_h / 2, shape.right, _h / 2),
          Paint()..color = primary,
        )
        ..restore()
        // 차오를수록 손잡이가 커지고 색이 바뀐다(M3 스위치 16 → 24dp).
        ..drawCircle(
          Offset(x, 0),
          _h * (.24 + .12 * f),
          Paint()..color = Color.lerp(thumbOff, thumbOn, f)!,
        );
    });
  }

  @override
  bool shouldRepaint(_LoaderPainter old) =>
      old.loops != loops ||
      old.glass != glass ||
      old.dark != dark ||
      old.mono != mono ||
      old.knob != knob;
}
