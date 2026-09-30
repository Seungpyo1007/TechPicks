import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';

/// iOS 26 의 밀어 넣기 전환.
///
/// Flutter 의 [CupertinoPageTransitionsBuilder] 는 iOS 18 까지 그대로다.
/// 뒤로 가기는 왼쪽 끝 20pt 에서만 되고, 움직이는 화면은 네모다. iOS 26 은
/// 화면 어디를 밀어도 뒤로 가고(가로로 스크롤되는 것이 먼저), 움직이는 동안
/// 화면 모서리가 기기 모서리처럼 둥글다.
class TpIosPageTransitionsBuilder extends PageTransitionsBuilder {
  const TpIosPageTransitionsBuilder();

  @override
  Duration get transitionDuration =>
      CupertinoRouteTransitionMixin.kTransitionDuration;

  @override
  DelegatedTransitionBuilder? get delegatedTransition =>
      CupertinoPageTransition.delegatedTransition;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // 아래에서 올라오는 전체 화면은 시스템 그대로(밀어서 닫지 않는다).
    if (route.fullscreenDialog) {
      return CupertinoRouteTransitionMixin.buildPageTransitions<T>(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      // 손가락을 따라갈 때는 곡선 없이.
      linearTransition: route.popGestureInProgress,
      child: _BackSwipe<T>(
        route: route,
        child: _MovingCorners(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
      ),
    );
  }
}

/// 움직이는 동안만 모서리를 깎는다. 멈춰 있으면 네모 그대로(클립 비용 없음).
class _MovingCorners extends StatelessWidget {
  const _MovingCorners({
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  /// iPhone 화면 모서리에 가까운 값. 기기마다 조금씩 다르다.
  static const double radius = 48;

  bool get _moving =>
      animation.isAnimating ||
      secondaryAnimation.isAnimating ||
      (animation.value > 0 && animation.value < 1) ||
      (secondaryAnimation.value > 0 && secondaryAnimation.value < 1);

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[animation, secondaryAnimation]),
    child: child,
    builder: (context, child) => _moving
        ? ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: child,
          )
        : child!,
  );
}

/// 화면 어디서나 오른쪽으로 밀면 뒤로. 왼쪽 끝은 예전처럼 무엇보다 먼저.
class _BackSwipe<T> extends StatefulWidget {
  const _BackSwipe({required this.route, required this.child});

  final PageRoute<T> route;
  final Widget child;

  /// 왼쪽 끝. 여기서 시작하면 안쪽 가로 스크롤보다 먼저 잡는다.
  static const double edge = 20;

  @override
  State<_BackSwipe<T>> createState() => _BackSwipeState<T>();
}

class _BackSwipeState<T> extends State<_BackSwipe<T>> {
  late final _RightwardDrag _content = _RightwardDrag(debugOwner: this);
  late final HorizontalDragGestureRecognizer _edge =
      HorizontalDragGestureRecognizer(debugOwner: this);

  _Pop? _pop;

  @override
  void initState() {
    super.initState();
    for (final r in <DragGestureRecognizer>[_content, _edge]) {
      r
        ..onStart = _start
        ..onUpdate = _update
        ..onEnd = _end
        ..onCancel = _cancel;
    }
  }

  @override
  void dispose() {
    _content.dispose();
    _edge.dispose();
    // 끄는 중에 사라지면 내비게이터에 끝났다고 알려야 한다.
    final pop = _pop;
    if (pop != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (pop.navigator.mounted) pop.navigator.didStopUserGesture();
      });
      _pop = null;
    }
    super.dispose();
  }

  bool get _enabled => widget.route.popGestureEnabled;

  double _logical(double v) =>
      Directionality.of(context) == TextDirection.rtl ? -v : v;

  void _start(DragStartDetails _) {
    if (_pop != null) return;
    _pop = _Pop(
      navigator: widget.route.navigator!,
      // ignore: invalid_use_of_protected_member
      controller: widget.route.controller!,
      isCurrent: () => widget.route.isCurrent,
      isActive: () => widget.route.isActive,
    );
  }

  void _update(DragUpdateDetails d) =>
      _pop?.update(_logical(d.primaryDelta! / context.size!.width));

  void _end(DragEndDetails d) {
    _pop?.end(_logical(d.velocity.pixelsPerSecond.dx / context.size!.width));
    _pop = null;
  }

  void _cancel() {
    _pop?.end(0);
    _pop = null;
  }

  @override
  Widget build(BuildContext context) {
    final inset = math.max(
      Directionality.of(context) == TextDirection.rtl
          ? MediaQuery.paddingOf(context).right
          : MediaQuery.paddingOf(context).left,
      _BackSwipe.edge,
    );
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        // 내용 전체. 안쪽 가로 스크롤이 먼저 이기고, 왼쪽으로 밀면 빠진다.
        Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            if (_enabled) _content.addPointer(e);
          },
          child: widget.child,
        ),
        PositionedDirectional(
          start: 0,
          width: inset,
          top: 0,
          bottom: 0,
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (e) {
              if (_enabled) _edge.addPointer(e);
            },
          ),
        ),
      ],
    );
  }
}

/// 오른쪽(읽는 방향의 뒤)으로 움직일 때만 잡는 가로 끌기.
///
/// 왼쪽으로 먼저 움직이면 바로 빠져서, 안쪽의 밀어서 지우기 같은 것에 넘긴다.
class _RightwardDrag extends HorizontalDragGestureRecognizer {
  _RightwardDrag({super.debugOwner});

  final Map<int, Offset> _downs = <int, Offset>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _downs[event.pointer] = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    final start = _downs[event.pointer];
    if (start != null && event is PointerMoveEvent) {
      final dx = event.position.dx - start.dx;
      // 뒤가 아닌 쪽으로 슬롭의 절반을 넘으면 포기.
      if (dx < -kTouchSlop / 2) {
        _downs.remove(event.pointer);
        resolvePointer(event.pointer, GestureDisposition.rejected);
        stopTrackingPointer(event.pointer);
        return;
      }
    }
    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _downs.remove(event.pointer);
    }
    super.handleEvent(event);
  }

  @override
  void rejectGesture(int pointer) {
    _downs.remove(pointer);
    super.rejectGesture(pointer);
  }
}

/// 끌기 한 번. 전환 컨트롤러를 손가락에 붙였다가 놓으면 마저 보낸다.
///
/// Flutter 의 `_CupertinoBackGestureController` 와 같은 규칙이다.
class _Pop {
  _Pop({
    required this.navigator,
    required this.controller,
    required this.isCurrent,
    required this.isActive,
  }) {
    navigator.didStartUserGesture();
  }

  final NavigatorState navigator;
  final AnimationController controller;
  final ValueGetter<bool> isCurrent;
  final ValueGetter<bool> isActive;

  /// 화면 폭 / 초. 이보다 빠르면 놓은 자리와 상관없이 방향을 따른다.
  static const double fling = 1;
  static const Duration settle = Duration(milliseconds: 350);

  void update(double delta) => controller.value -= delta;

  void end(double velocity) {
    const curve = Curves.fastEaseInToSlowEaseOut;
    final current = isCurrent();
    final bool stay;
    if (!current) {
      stay = isActive();
    } else if (velocity.abs() >= fling) {
      stay = velocity <= 0;
    } else {
      stay = controller.value > .5;
    }

    if (stay) {
      controller.animateTo(1, duration: settle, curve: curve);
    } else {
      if (current) navigator.pop();
      if (controller.isAnimating) {
        controller.animateBack(0, duration: settle, curve: curve);
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener done;
      done = (_) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(done);
      };
      controller.addStatusListener(done);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
