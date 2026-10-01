import 'dart:math' as math;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../shared/brand/tp_logo.dart';
import '../shared/copy_keys.dart';
import '../shared/tp_haptics.dart';
import 'theme/tp_motion.dart';
import 'theme/tp_sys.dart';
import 'theme/tp_tokens.dart';

/// 네이티브 스플래시에서 앱으로 넘어오는 장면.
///
/// 지금까지는 이 자리가 **끊겨 있었다.** 네이티브 스플래시가 첫 프레임에서
/// 사라지고, 앱은 저장값(온보딩 여부·로그인)을 읽는 동안 빈 화면을 그린 뒤,
/// 첫 화면이 툭 나타났다. 켤 때마다 흰 화면이 한 번 깜빡였다.
///
/// 그래서 세 가지를 한다.
///
/// 1. **같은 그림에서 이어받는다.** 네이티브 스플래시와 같은 로고를 같은
///    크기(125pt — `LaunchImage@3x` 가 375px)로 같은 자리에 그린다. 넘어오는
///    순간이 화면에서는 안 보인다.
/// 2. **읽는 동안 로고를 들고 있는다.** 빈 화면 대신 로고가 그대로 있다.
/// 3. **토글이 켜진다.** 로고가 토글이라 앱을 켜는 장면으로 쓴다. 스플래시는
///    꺼진 로고이고, 첫 프레임부터 손잡이가 미끄러지며 지나간 자리가 파랗게
///    남는다. 다 켜지면 틱 한 번.
/// 4. **로고가 열리며 앱이 나온다.** 로고는 커지며 옅어지고 그 아래에서
///    첫 화면이 올라온다 — iOS 가 아이콘에서 앱을 여는 것과 같은 방향이다.
class TpLaunch extends StatefulWidget {
  const TpLaunch({super.key, required this.ready, required this.child});

  /// 첫 화면을 정할 수 있는가. false 면 로고를 계속 들고 있는다.
  final bool ready;

  final Widget child;

  /// 네이티브 스플래시의 로고 크기. `LaunchImage@3x.png` 375px ÷ 3.
  static const double logoSize = 125;

  /// Android 12 부터는 시스템이 스플래시를 그리고, 아이콘 바탕 원이 160dp 다.
  /// 그 원과 같은 크기로 이어받는다(pubspec 의 android_12).
  static const double androidLogoSize = 160;

  /// 판이 다 커졌을 때의 모서리. 요즘 iPhone 화면 모서리에 가까운 값이라
  /// 다 커지면 화면 테두리와 겹쳐 안 보인다.
  static const double screenCorner = 55;

  /// 확인용: `--dart-define=LAUNCH_HOLD_MS=3000` 이면 준비를 그만큼 늦춰
  /// 기다리는 모습(손잡이 숨)을 볼 수 있다. 기본 0.
  static const int holdMs = int.fromEnvironment('LAUNCH_HOLD_MS');

  /// 기다리는 동안 손잡이가 한 번 숨 쉬는 시간.
  static const Duration breath = Duration(milliseconds: 1600);

  /// 토글이 켜지는 시간. 저장값을 읽는 동안 같이 돌아서 켜는 시간을 늘리지
  /// 않는다. 준비가 먼저 끝나도 이것만은 끝까지 본다.
  static const Duration toggle = Duration(milliseconds: 620);

  /// 로고가 열리는 시간.
  ///
  /// [TpMotion] 의 어느 역할도 아니다 — 앱을 켜는 것은 화면 안에서 일어나는
  /// 일이 아니라 그 앞의 장면이고, 명세에 값이 없다. iOS 가 아이콘에서 앱을
  /// 열 때와 비슷한 길이로 잡았다.
  static const Duration open = Duration(milliseconds: 560);

  @override
  State<TpLaunch> createState() => _TpLaunchState();
}

class _TpLaunchState extends State<TpLaunch> with TickerProviderStateMixin {
  late final AnimationController _c;
  late final AnimationController _on = AnimationController(
    vsync: this,
    duration: TpLaunch.toggle,
  );

  /// 토글이 다 켜졌는데 준비가 아직이면 손잡이가 숨을 쉰다(1.6초 주기).
  /// 준비되면 주기를 기다리지 않고 0.2초에 제자리로 돌아와 열린다.
  late final AnimationController _wait = AnimationController(
    vsync: this,
    duration: TpLaunch.breath,
  );
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  double _settleFrom = 0;

  /// [TpLaunch.holdMs] 가 지났는가.
  bool _held = TpLaunch.holdMs <= 0;
  bool get _ready => widget.ready && _held;

  static double _wave(double v) => (1 - math.cos(2 * math.pi * v)) / 2;

  double get _breath => _settle.isAnimating || _settle.isCompleted
      ? _settleFrom * (1 - Curves.easeOut.transform(_settle.value))
      : _wait.isAnimating
      ? _wave(_wait.value)
      : 0;

  /// 로고가 다 열렸는가. 그 뒤로는 이 위젯이 아무것도 안 얹는다.
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: TpLaunch.open)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _done = true);
        }
      });
    if (!_held) {
      Future<void>.delayed(const Duration(milliseconds: TpLaunch.holdMs), () {
        if (!mounted) return;
        final was = _ready;
        _held = true;
        if (!was && _ready) _readied();
      });
    }
    _on.addStatusListener((status) {
      if (status != AnimationStatus.completed) return;
      TpHaptics.selection();
      if (_ready) {
        _start();
      } else if (mounted && context.motion.loops) {
        _wait.repeat();
      }
    });
    // 첫 프레임은 스플래시와 같은 꺼진 로고. 그다음부터 켠다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _on.value = 1;
        if (_ready) _start();
      } else {
        _on.forward();
      }
    });
  }

  @override
  void didUpdateWidget(TpLaunch old) {
    super.didUpdateWidget(old);
    if (_ready && !(old.ready && _held)) _readied();
  }

  /// 준비가 끝났다. 토글이 아직 켜지는 중이면 그게 끝날 때 연다.
  void _readied() {
    if (_settle.isAnimating || _c.isAnimating || _c.isCompleted) return;
    if (_on.isCompleted) {
      if (_wait.isAnimating) {
        _settleFrom = _wave(_wait.value);
        _wait.stop();
        _settle.forward(from: 0).whenComplete(() {
          if (mounted) _start();
        });
      } else {
        _start();
      }
    }
  }

  void _start() {
    // 저장값을 이미 들고 있으면(두 번째 실행 등) 한 프레임 안에 준비가 끝난다.
    // 그래도 한 번은 로고를 보여준다 — 켜자마자 화면이 튀는 것보다 낫다.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) {
        if (mounted) _c.forward();
      })
      ..scheduleFrame();
  }

  @override
  void dispose() {
    _wait.dispose();
    _settle.dispose();
    _on.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    final t = context.tp;
    final android = defaultTargetPlatform == TargetPlatform.android;
    // 스플래시는 크롬이 아니라 진짜 OS 와 시스템 다크 모드를 따른다.
    final dark = MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    // "동작 줄이기" 면 크기 변화 없이 페이드만 한다. 로고는 여전히 읽는 동안 떠 있다.
    final reduced = MediaQuery.disableAnimationsOf(context);
    final screen = MediaQuery.sizeOf(context);
    final end = context.sys.background;
    final from = TpLogo.plateColors(android: android, dark: dark);
    final size = android ? TpLaunch.androidLogoSize : TpLaunch.logoSize;

    // 막대: 판 위에 따로. 토글이 켜지고, 열릴 때는 먼저 빠진다.
    final mark = AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_on, _wait, _settle]),
      builder: (context, _) => Semantics(
        liveRegion: _wait.isAnimating,
        label: _wait.isAnimating ? K.launchWaiting.tr() : null,
        child: TpLogo(
          size: size,
          on: Curves.easeInOutCubic.transform(_on.value),
          android: android,
          dark: dark,
          plate: false,
          breath: _breath,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, app) {
        final v = _c.value;
        double part(double a, double b, [Curve curve = Curves.linear]) =>
            curve.transform(((v - a) / (b - a)).clamp(0.0, 1.0));

        if (reduced) {
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Opacity(opacity: v, child: app),
              IgnorePointer(
                child: Opacity(
                  opacity: 1 - v,
                  child: ColoredBox(
                    color: t.scrim,
                    child: Center(
                      child: TpLogo(size: size, android: android, dark: dark),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // 판이 화면만큼 커진다(iOS 는 앱이 열리듯 네모, Android 는 원형 리빌).
        // 처음에 빠르게, 끝에서 부드럽게(iOS 앱 열기와 같은 쪽).
        final grow = part(0, .62, Curves.fastEaseInToSlowEaseOut);
        // 판 색은 아이콘 색에서 앱 바탕색으로. 다 커지면 첫 화면과 같은 색이다.
        final tint = part(.05, .62);
        final colors = <Color>[for (final c in from) Color.lerp(c, end, tint)!];
        final gone = part(0, .3, Curves.easeIn);
        final appIn = part(.42, .95, Curves.easeOut);

        final Widget plate;
        if (android) {
          // 아이콘이 원이라 창도 원 그대로 화면 끝까지 퍼진다(원형 리빌).
          final open = part(0, .62, Curves.easeInOutCubicEmphasized);
          final reach =
              math.sqrt(
                screen.width * screen.width + screen.height * screen.height,
              ) /
              2;
          final r = size / 2 + (reach - size / 2) * open;
          // 상자는 화면 폭을 못 넘으니 원을 직접 그린다.
          plate = CustomPaint(
            painter: _Disc(radius: r, color: colors.first),
          );
        } else {
          // 세로가 먼저 자라 폰 화면 모양을 닮아 가고, 모서리는 아이콘 곡선에서
          // 화면 모서리 곡선으로 이어진다. 네모난 상자로 보이는 순간이 없다.
          plate = Center(
            child: Container(
              width: size + (screen.width - size) * grow,
              height: size + (screen.height - size) * math.pow(grow, .75),
              decoration: ShapeDecoration(
                shape: RoundedSuperellipseBorder(
                  borderRadius: BorderRadius.circular(
                    size * TpLogo.cornerRatio +
                        (TpLaunch.screenCorner - size * TpLogo.cornerRatio) *
                            grow,
                  ),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
            ),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 스플래시 바탕. 판이 화면을 다 덮으면 할 일이 없다.
            if (grow < 1) IgnorePointer(child: ColoredBox(color: t.scrim)),
            IgnorePointer(child: plate),
            if (gone < 1)
              IgnorePointer(
                child: Center(
                  child: Opacity(
                    opacity: 1 - gone,
                    // 판과 같이 커지며 빠진다.
                    child: Transform.scale(scale: 1 + .6 * grow, child: mark),
                  ),
                ),
              ),
            // 첫 화면. 처음부터 그려 두고(자리 잡기), 판이 앱 바탕색이 된 뒤에
            // 그 위로 떠오른다.
            // 완전히 투명하면 Flutter 가 아예 안 그려서, 떠오르는 순간 첫 그리기로
            // 한 번 멈칫한다. 보이지 않을 만큼 옅게라도 미리 그려 둔다.
            Opacity(
              opacity: math.max(appIn, .001),
              child: Transform.scale(scale: .985 + .015 * appIn, child: app),
            ),
          ],
        );
      },
    );
  }
}

/// 화면 가운데 원. 화면보다 커질 수 있다.
class _Disc extends CustomPainter {
  _Disc({required this.radius, required this.color});

  final double radius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawCircle(
    size.center(Offset.zero),
    radius,
    Paint()..color = color,
  );

  @override
  bool shouldRepaint(_Disc old) => old.radius != radius || old.color != color;
}
