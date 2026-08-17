import 'package:flutter/material.dart';

import 'theme/tp_motion.dart';
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
/// 3. **로고가 열리며 앱이 나온다.** 로고는 커지며 옅어지고 그 아래에서
///    첫 화면이 올라온다 — iOS 가 아이콘에서 앱을 여는 것과 같은 방향이다.
class TpLaunch extends StatefulWidget {
  const TpLaunch({super.key, required this.ready, required this.child});

  /// 첫 화면을 정할 수 있는가. false 면 로고를 계속 들고 있는다.
  final bool ready;

  final Widget child;

  /// 네이티브 스플래시의 로고 크기. `LaunchImage@3x.png` 375px ÷ 3.
  static const double logoSize = 125;

  /// 로고가 열리는 시간.
  ///
  /// [TpMotion] 의 어느 역할도 아니다 — 앱을 켜는 것은 화면 안에서 일어나는
  /// 일이 아니라 그 앞의 장면이고, 명세에 값이 없다. iOS 가 아이콘에서 앱을
  /// 열 때와 비슷한 길이로 잡았다.
  static const Duration open = Duration(milliseconds: 420);

  @override
  State<TpLaunch> createState() => _TpLaunchState();
}

class _TpLaunchState extends State<TpLaunch> with TickerProviderStateMixin {
  late final AnimationController _c;

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
    if (widget.ready) _start();
  }

  @override
  void didUpdateWidget(TpLaunch old) {
    super.didUpdateWidget(old);
    if (widget.ready && !old.ready) _start();
  }

  void _start() {
    // 저장값을 이미 들고 있으면(두 번째 실행 등) 한 프레임 안에 준비가 끝난다.
    // 그래도 한 번은 로고를 보여준다 — 켜자마자 화면이 튀는 것보다 낫다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    final t = context.tp;
    // "동작 줄이기" 면 열리는 장면을 건너뛴다. 로고는 여전히 읽는 동안 떠 있다.
    final reduced = MediaQuery.disableAnimationsOf(context);

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // 첫 화면. 로고가 열리는 동안 그 아래에서 자리를 잡는다.
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = Curves.easeOutCubic.transform(_c.value);
            return Opacity(
              opacity: reduced ? _c.value : t,
              child: Transform.scale(scale: 0.98 + 0.02 * t, child: child),
            );
          },
          child: widget.child,
        ),

        // 스플래시 판. 네이티브 것과 같은 색·같은 로고다.
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final v = _c.value;
            if (v == 1) return const SizedBox.shrink();
            // 배경은 먼저 사라지고(60%까지) 로고가 조금 더 남는다. 반대로 하면
            // 로고가 허공에 뜬 것처럼 보인다.
            final plate = (1 - v / 0.6).clamp(0.0, 1.0);
            final logo = (1 - v).clamp(0.0, 1.0);
            return IgnorePointer(
              child: ColoredBox(
                color: t.scrim.withValues(alpha: reduced ? logo : plate),
                child: Center(
                  child: Opacity(
                    opacity: reduced ? logo : Curves.easeIn.transform(logo),
                    child: Transform.scale(
                      // 커지며 열린다. 작아지면 앱이 뒤로 물러나는 것처럼 읽힌다.
                      scale: 1 + 0.35 * Curves.easeInCubic.transform(v),
                      child: child,
                    ),
                  ),
                ),
              ),
            );
          },
          child: Image.asset(
            'assets/logo/logo.png',
            width: TpLaunch.logoSize,
            height: TpLaunch.logoSize,
            // 로고 자체가 둥근 사각형이라 여기서 또 깎지 않는다.
            filterQuality: FilterQuality.medium,
          ),
        ),
      ],
    );
  }
}
