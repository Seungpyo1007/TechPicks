import 'package:flutter/widgets.dart';

import '../../app/theme/tp_motion.dart';

/// 화면 등장 신호. 이 아래의 행·막대·숫자가 이 시각에 맞춰 들어온다.
///
/// [TpPage] 가 화면이 보이게 된 순간(탭이 켜지거나 push 가 끝났을 때)을 찍고,
/// 정렬·카테고리를 바꾼 화면은 그 안에서 다시 찍는다. 받는 쪽은 [freshOf] 로
/// "방금 찍혔는가"를 묻는다 — 스크롤로 나중에 지어진 행은 가만히 있어야 한다.
class TpArriveScope extends InheritedWidget {
  const TpArriveScope({
    super.key,
    required this.at,
    required super.child,
    this.from = up,
  });

  /// 마지막으로 찍은 시각. null 이면 등장 연출이 없다.
  final DateTime? at;

  /// 어디서 들어오는가(자기 크기 비율). 기본은 조금 아래에서.
  final Offset from;

  static const Offset up = Offset(0, 0.25);

  static Offset fromOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpArriveScope>()?.from ?? up;

  /// 이만큼 안에 지어진 것만 등장한다.
  static const Duration window = Duration(milliseconds: 350);

  static DateTime? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TpArriveScope>()?.at;

  /// 방금 찍힌 시각. 오래됐거나 없으면 null.
  static DateTime? freshOf(BuildContext context) {
    final at = of(context);
    if (at == null) return null;
    return DateTime.now().difference(at) < window ? at : null;
  }

  /// 둘 중 늦은 시각. 안쪽 화면이 바깥 신호를 이어받을 때 쓴다.
  static DateTime? latest(DateTime? a, DateTime? b) {
    if (a == null) return b;
    if (b == null) return a;
    return a.isAfter(b) ? a : b;
  }

  @override
  bool updateShouldNotify(TpArriveScope oldWidget) =>
      oldWidget.at != at || oldWidget.from != from;
}

/// 등장 신호가 오면 [index] 번째 순서로 조금씩 늦게 올라온다.
///
/// 위 [rows] 개만 움직인다. 행 사이 18ms, 한 행은 `motion.reorder`(220ms).
/// 동작 줄이기면 아무것도 안 한다.
class TpArrive extends StatefulWidget {
  const TpArrive({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  static const int rows = 12;
  static const Duration step = Duration(milliseconds: 18);

  @override
  State<TpArrive> createState() => _TpArriveState();
}

class _TpArriveState extends State<TpArrive>
    with SingleTickerProviderStateMixin {
  AnimationController? _c;
  CurvedAnimation? _t;
  DateTime? _played;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final at = TpArriveScope.freshOf(context);
    if (at == null || at == _played || widget.index >= TpArrive.rows) return;
    final move = context.motion.reorder;
    if (move.duration == Duration.zero) return;
    _played = at;
    final delay = TpArrive.step * widget.index;
    final total = move.duration + delay;
    final c = _c ??= AnimationController(vsync: this);
    c.duration = total;
    _t?.dispose();
    _t = CurvedAnimation(
      parent: c,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: move.curve,
      ),
    );
    c.forward(from: 0);
    setState(() {});
  }

  @override
  void dispose() {
    _t?.dispose();
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    if (t == null) return widget.child;
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: TpArriveScope.fromOf(context),
          end: Offset.zero,
        ).animate(t),
        child: widget.child,
      ),
    );
  }
}
