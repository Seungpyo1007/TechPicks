part of 'you_screen.dart';

/// 가중치 줄에 붙는 한 마디. 가장 큰 축, 고르면 "고르게".
String _weightsSummary(TpWeights w) {
  final values = <TpAxisKind, double>{
    for (final k in TpAxisKind.values) k: k.weightIn(w),
  };
  final top = values.entries.reduce((a, b) => b.value > a.value ? b : a);
  final low = values.values.reduce(math.min);
  if (top.value - low < .05) return K.weightsBalanced.tr();
  return K.weightsLead.tr(args: <String>[SpecLabels.axis(top.key)]);
}

/// 중요하게 보는 것. 모양 그림 + 축마다 슬라이더.
class PrioritiesScreen extends ConsumerWidget {
  const PrioritiesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weights = ref.watch(weightsProvider);
    return TpPage(
      title: K.priorities.tr(),
      largeTitle: false,
      onBack: onBack,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 12),
              TpGroup(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ExcludeSemantics(child: _Radar(weights: weights)),
                  ),
                ],
              ),
              TpGroup(
                footer: K.prioritiesNote.tr(),
                headerAction: _Link(
                  label: K.reset.tr(),
                  onTap: () => ref.read(weightsProvider.notifier).reset(),
                ),
                header: _weightsSummary(weights),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                children: <Widget>[
                  for (final kind in TpAxisKind.values)
                    _WeightSlider(
                      kind: kind,
                      value: kind.weightIn(weights),
                      onChanged: (v) =>
                          ref.read(weightsProvider.notifier).setAxis(kind, v),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 다섯 축을 꼭짓점으로 한 모양. 슬라이더를 끄는 대로 늘고 준다.
class _Radar extends StatelessWidget {
  const _Radar({required this.weights});

  final TpWeights weights;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final labels = <String>[
      for (final k in TpAxisKind.values) SpecLabels.axis(k),
    ];
    // 가장 큰 축을 끝까지 편다. 비중은 합이 아니라 서로의 비율이라, 그대로
    // 그리면 기본값에서 가운데 작은 점으로만 보인다.
    final raw = <double>[
      for (final k in TpAxisKind.values) k.weightIn(weights).clamp(0.0, 1.0),
    ];
    final top = raw.reduce(math.max);
    final values = <double>[for (final v in raw) top <= 0 ? 0 : v / top];
    return SizedBox(
      height: 210,
      child: TweenAnimationBuilder<List<double>>(
        tween: _ListTween(end: values),
        duration: context.motion.valueChange.duration,
        curve: context.motion.valueChange.curve,
        builder: (context, v, _) => CustomPaint(
          size: Size.infinite,
          painter: _RadarPainter(values: v, labels: labels, sys: sys),
        ),
      ),
    );
  }
}

class _ListTween extends Tween<List<double>> {
  _ListTween({required List<double> end}) : super(begin: end, end: end);

  @override
  List<double> lerp(double t) => <double>[
    for (var i = 0; i < end!.length; i++)
      begin == null || begin!.length != end!.length
          ? end![i]
          : begin![i] + (end![i] - begin![i]) * t,
  ];
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.values,
    required this.labels,
    required this.sys,
  });

  final List<double> values;
  final List<String> labels;
  final TpSys sys;

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    final c = Offset(size.width / 2, size.height / 2 + 6);
    final r = math.min(size.width, size.height) / 2 - 28;
    Offset at(int i, double k) {
      final a = -math.pi / 2 + i * 2 * math.pi / n;
      return c + Offset(math.cos(a), math.sin(a)) * r * k;
    }

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = sys.separator;
    for (final k in <double>[1 / 3, 2 / 3, 1]) {
      final ring = Path()..moveTo(at(0, k).dx, at(0, k).dy);
      for (var i = 1; i < n; i++) {
        ring.lineTo(at(i, k).dx, at(i, k).dy);
      }
      canvas.drawPath(ring..close(), grid);
    }
    for (var i = 0; i < n; i++) {
      canvas.drawLine(c, at(i, 1), grid);
    }

    // 값이 0 이어도 점 하나로 사라지지 않게 조금 띄운다.
    final shape = Path();
    for (var i = 0; i < n; i++) {
      final p = at(i, .08 + .92 * values[i]);
      i == 0 ? shape.moveTo(p.dx, p.dy) : shape.lineTo(p.dx, p.dy);
    }
    shape.close();
    canvas.drawPath(
      shape,
      Paint()..color = TpSys.accent.withValues(alpha: .18),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..color = TpSys.accent,
    );
    for (var i = 0; i < n; i++) {
      canvas.drawCircle(
        at(i, .08 + .92 * values[i]),
        3.5,
        Paint()..color = TpSys.accent,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: TextStyle(fontSize: 12, color: sys.label2),
        ),
        textDirection: ui.TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 90);
      final p = at(i, 1.18);
      tp.paint(canvas, p - Offset(tp.width / 2, tp.height / 2));
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.sys != sys ||
      old.labels.join() != labels.join() ||
      old.values.join() != values.join();
}
