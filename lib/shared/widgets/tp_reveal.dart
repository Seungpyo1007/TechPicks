import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../brand/tp_logo.dart';

/// 로딩 표시에서 내용으로 넘어가는 장면.
///
/// [loading] 이 참이던 것이 거짓이 되면 ① 로딩 표시가 작아지며 사라지고
/// ② 내용이 아래에서 떠오르며 나타난다. 처음부터 데이터가 있으면(캐시, 두 번째
/// 열기) 그냥 그린다. 로딩 표시는 [child] 로 같이 넘긴다.
///
/// 한 화면에 여럿 두면 [order] 순서로 조금씩 늦게 들어온다. 로딩 표시가 없는
/// 덩어리는 로딩 중에 빈 상자를 넘긴다.
class TpReveal extends StatefulWidget {
  const TpReveal({
    super.key,
    required this.loading,
    required this.child,
    this.order = 0,
  }) : sliver = false;

  /// [child] 가 슬리버일 때. 슬리버는 옮길 수 없어서 흐려지기만 한다.
  const TpReveal.sliver({
    super.key,
    required this.loading,
    required Widget sliver,
    this.order = 0,
  }) : child = sliver,
       sliver = true;

  final bool loading;
  final Widget child;
  final int order;
  final bool sliver;

  /// 로딩 표시가 사라지는 시간.
  static const Duration exit = Duration(milliseconds: 180);

  /// 덩어리 사이 간격.
  static const Duration step = Duration(milliseconds: 70);

  /// 떠오르는 거리.
  static const double rise = 24;

  @override
  State<TpReveal> createState() => _TpRevealState();
}

class _TpRevealState extends State<TpReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
  );

  /// 사라지는 중인 로딩 표시.
  Widget? _previous;

  /// 전체 시간 중 로딩 표시가 사라지는 몫과 내용이 들어오기 시작하는 지점.
  double _exitEnd = 0;
  double _enterStart = 0;
  Curve _curve = Curves.easeOutCubic;

  @override
  void didUpdateWidget(TpReveal old) {
    super.didUpdateWidget(old);
    if (old.loading && !widget.loading) _play(old.child);
  }

  void _play(Widget previous) {
    final move = context.motion.contentSwap;
    if (move.duration == Duration.zero) return;
    final delay = TpReveal.step * widget.order;
    final total = TpReveal.exit + delay + move.duration;
    _previous = previous;
    _exitEnd = TpReveal.exit.inMicroseconds / total.inMicroseconds;
    _enterStart = (TpReveal.exit + delay).inMicroseconds / total.inMicroseconds;
    _curve = move.curve;
    _c
      ..duration = total
      ..forward(from: 0).whenComplete(() {
        if (mounted) setState(() => _previous = null);
      });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) return widget.child;
    // 끝난 뒤에도 감싼 모양을 그대로 둔다. 벗기면 안의 상태가 새로 만들어진다.
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final previous = _previous;
        // ① 로딩 표시가 작아지며 흐려진다.
        if (previous != null && v < _exitEnd) {
          final p = Curves.easeIn.transform(v / _exitEnd);
          return _frame(previous, opacity: 1 - p, dy: 0, scale: 1 - .12 * p);
        }
        // ② 내용이 떠오른다. 앞 덩어리를 기다리는 동안은 안 보인다.
        final p = previous == null
            ? 1.0
            : _curve.transform(
                ((v - _enterStart) / (1 - _enterStart)).clamp(0.0, 1.0),
              );
        return _frame(
          widget.child,
          opacity: p,
          dy: TpReveal.rise * (1 - p),
          scale: 1,
        );
      },
    );
  }

  Widget _frame(
    Widget child, {
    required double opacity,
    required double dy,
    required double scale,
  }) {
    if (widget.sliver) return SliverOpacity(opacity: opacity, sliver: child);
    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(0, dy, 0)
          ..scaleByDouble(scale, scale, 1, 1),
        child: child,
      ),
    );
  }
}

/// 화면을 처음 읽는 동안의 표시. 로고 로더 하나.
class TpLoadingMark extends StatelessWidget {
  const TpLoadingMark({super.key, this.height = 320});

  /// 차지할 높이. 화면 가운데쯤 오게.
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: const Center(child: TpLogoLoader(size: 56)),
  );
}
