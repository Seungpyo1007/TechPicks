import 'package:flutter/material.dart';

/// M3 shared axis X. 명세 Interactions 의 Android 푸시 전환.
///
/// Flutter 가 Android 에 기본으로 주는 건 [ZoomPageTransitionsBuilder] 라
/// 명세와 다르다. shared axis 는 `animations` 패키지에 있지만, 전환 하나
/// 때문에 의존성을 늘리는 대신 여기서 그린다.
///
/// 값은 M3 모션 정의 그대로다 — 300ms, 30dp 이동, 나가는 쪽은 앞 30% 동안
/// 사라지고 들어오는 쪽은 뒤 70% 동안 나타난다.
class SharedAxisXPageTransitionsBuilder extends PageTransitionsBuilder {
  const SharedAxisXPageTransitionsBuilder();

  static const double _shift = 30;
  static const Duration duration = Duration(milliseconds: 300);

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _Outgoing(
      animation: secondaryAnimation,
      child: _Incoming(animation: animation, child: child),
    );
  }
}

/// 들어오는 화면. +30dp 에서 제자리로, 뒤 70% 동안 나타난다.
class _Incoming extends StatelessWidget {
  const _Incoming({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final slide = Tween<double>(
      begin: SharedAxisXPageTransitionsBuilder._shift,
      end: 0,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));

    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1, curve: Curves.easeIn),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform.translate(
        offset: Offset(slide.value, 0),
        child: Opacity(opacity: fade.value, child: child),
      ),
      child: child,
    );
  }
}

/// 나가는 화면. -30dp 로 밀리며 앞 30% 동안 사라진다.
class _Outgoing extends StatelessWidget {
  const _Outgoing({required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final slide = Tween<double>(
      begin: 0,
      end: -SharedAxisXPageTransitionsBuilder._shift,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOutCubic));

    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.3, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) => Transform.translate(
        offset: Offset(slide.value, 0),
        child: Opacity(opacity: 1 - fade.value, child: child),
      ),
      child: child,
    );
  }
}
