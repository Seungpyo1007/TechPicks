import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_button.dart';
import '../../shared/widgets/tp_page.dart';

/// 온보딩 세 장(`iOS-Onboarding`, `-2`, `-3`).
///
/// 흰 카드(높이 300, 모서리 32) 안에 그 장의 약속을 **실제 부품**으로 보여준다:
/// 지수 숫자와 막대, 두 기기 비교표, 질문과 답 카드. 장이 들어올 때마다 카드
/// 안이 처음부터 다시 움직인다.
///
/// 끝나면(건너뛰기·시작하기) 로그인 화면으로 간다. 로그인은 선택이라 거기서
/// 뒤로 가면 오늘이다. 되돌릴 수 없다는 경고는 없다(v1 에는 있었다).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;

  static int get _count => K.onboarding.length;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(onboardingDoneProvider.notifier).complete();
    widget.onDone?.call();
  }

  void _next() {
    if (_index == _count - 1) {
      _finish();
      return;
    }
    final move = context.motion.contentSwap;
    _pages.nextPage(duration: move.duration, curve: move.curve);
  }

  double get _page => _pages.hasClients && _pages.position.haveDimensions
      ? (_pages.page ?? _index.toDouble())
      : _index.toDouble();

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final last = _index == _count - 1;

    return Material(
      color: sys.background,
      child: SafeArea(
        child: Column(
          children: <Widget>[
            // 툴바 자리. 오른쪽 위 유리 캡슐 "건너뛰기", 마지막 장에는 없다.
            // 버튼 자리는 로그인 X 와 같다([TpTopBar]).
            TpTopBar(
              safeTop: false,
              trailing: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: context.motion.selection.duration,
                child: IgnorePointer(
                  ignoring: last,
                  // iOS 는 유리 캡슐, Android 는 48 높이 글자 버튼.
                  child: context.tp.isGlass
                      ? TpBarButton(
                          action: TpBarAction(
                            label: K.skip.tr(),
                            text: true,
                            onTap: _finish,
                          ),
                        )
                      : TextButton(
                          onPressed: _finish,
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                          ),
                          child: Text(K.skip.tr()),
                        ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: _count,
                itemBuilder: (context, i) {
                  final pane = K.onboarding[i];
                  return AnimatedBuilder(
                    animation: _pages,
                    builder: (context, child) {
                      // 카드는 손가락보다 조금 느리게 따라온다(시차).
                      final off = (_page - i).clamp(-1.0, 1.0);
                      final w = MediaQuery.sizeOf(context).width;
                      return Transform.translate(
                        offset: Offset(off * w * .18, 0),
                        child: child,
                      );
                    },
                    // 큰 글씨면 한 화면에 안 들어간다. 잘리는 대신 스크롤된다.
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            height: 300,
                            padding: EdgeInsets.all(i == 0 ? 28 : 24),
                            decoration: BoxDecoration(
                              color: sys.cell,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: ExcludeSemantics(
                              child: switch (i) {
                                0 => _IndexPane(active: i == _index),
                                1 => _ComparePane(active: i == _index),
                                _ => _AskPane(active: i == _index),
                              },
                            ),
                          ),
                          const SizedBox(height: 36),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                _Rise(
                                  active: i == _index,
                                  delay: const Duration(milliseconds: 180),
                                  child: Text(
                                    pane.title.tr(),
                                    style: TextStyle(
                                      fontSize: 34,
                                      height: 40 / 34,
                                      fontWeight: FontWeight.w700,
                                      color: sys.label,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _Rise(
                                  active: i == _index,
                                  delay: const Duration(milliseconds: 280),
                                  child: Text(
                                    pane.body.tr(),
                                    style: TextStyle(
                                      fontSize: 17,
                                      height: 24 / 17,
                                      color: sys.label2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Semantics(
                    label: '${_index + 1} / $_count',
                    child: _Dots(index: _index, count: _count),
                  ),
                  const SizedBox(height: 24),
                  TpButton(label: (last ? K.start : K.next).tr(), onTap: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS 페이지 컨트롤: 7pt 원, 간격 9, 지금 것만 진하게.
class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: <Widget>[
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: context.motion.selection.duration,
          curve: context.motion.selection.curve,
          margin: const EdgeInsets.symmetric(horizontal: 4.5),
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: i == index ? context.sys.label : context.sys.label3,
            shape: BoxShape.circle,
          ),
        ),
    ],
  );
}

/// 장이 들어올 때 0→1 로 한 번 도는 시간. 동작 줄이기면 바로 1.
class _Played extends StatefulWidget {
  const _Played({
    required this.active,
    required this.builder,
    this.duration = const Duration(milliseconds: 1400),
  });

  final bool active;
  final Duration duration;
  final Widget Function(BuildContext context, double t) builder;

  @override
  State<_Played> createState() => _PlayedState();
}

class _PlayedState extends State<_Played> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.active) _play();
  }

  @override
  void didUpdateWidget(_Played old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _play();
  }

  void _play() {
    _started = true;
    if (context.motion.isReduced) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (context, _) => widget.builder(context, _started ? _c.value : 0),
  );
}

/// [t] 의 [a]..[b] 구간을 0→1 로.
double _span(
  double t,
  double a,
  double b, [
  Curve curve = Curves.easeOutCubic,
]) {
  if (t <= a) return 0;
  if (t >= b) return 1;
  return curve.transform((t - a) / (b - a));
}

/// 올라오며 나타나기.
Widget _up(double k, Widget child) => Opacity(
  opacity: k,
  child: Transform.translate(offset: Offset(0, (1 - k) * 10), child: child),
);

/// 1장: 96pt 지수 숫자 + 축 다섯의 가는 막대.
class _IndexPane extends StatelessWidget {
  const _IndexPane({required this.active});

  final bool active;

  static const List<double> bars = <double>[.92, .88, .71, .72, .51];

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return _Played(
      active: active,
      builder: (context, t) {
        final count = (79 * _span(t, .1, .7, Curves.easeOutCubic)).round();
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // 큰 글씨에서도 한 줄. 넘치면 줄여서 넣는다.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 96,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -3.8,
                      color: TpSys.accent,
                      fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    K.tpIndex.tr(),
                    style: TextStyle(fontSize: 17, color: sys.label2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                for (var i = 0; i < TpAxisKind.values.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _Bar(
                          value:
                              bars[i] * _span(t, .15 + .07 * i, .65 + .07 * i),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          SpecLabels.axis(TpAxisKind.values[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: sys.label2),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(2),
    child: SizedBox(
      height: 4,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: ColoredBox(color: context.sys.fill)),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            heightFactor: 1,
            child: const ColoredBox(color: TpSys.accent),
          ),
        ],
      ),
    ),
  );
}

/// 이긴 값에 씌우는 옅은 액센트 알약.
class _Win extends StatelessWidget {
  const _Win(this.text, {required this.on});

  final String text;
  final double on;

  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: const Offset(-8, 0),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: TpSys.accent.withValues(alpha: .12 * on),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: on > .5 ? FontWeight.w600 : FontWeight.w400,
          color: Color.lerp(context.sys.label, context.sys.accentText, on),
        ),
      ),
    ),
  );
}

/// 2장: 두 기기 네 줄. 줄마다 이긴 쪽에 알약이 켜진다.
class _ComparePane extends StatelessWidget {
  const _ComparePane({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final rows = <(String, String, String, int)>[
      (SpecLabels.of(SpecKind.tpIndex), '79', '65', 0),
      (SpecLabels.of(SpecKind.price), r'$1,299', r'$1,199', 1),
      (SpecLabels.of(SpecKind.battery), '5,000 mAh', '5,088 mAh', 1),
      (SpecLabels.of(SpecKind.weight), '214 g', '233 g', 0),
    ];
    Widget cell(String text, bool win, double on) => win
        ? Align(
            alignment: Alignment.centerLeft,
            child: _Win(text, on: on),
          )
        : Text(text, style: TextStyle(fontSize: 15, color: sys.label));
    return _Played(
      active: active,
      builder: (context, t) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _up(
            _span(t, 0, .3),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 88),
                  for (final name in <String>[
                    'Galaxy S26 Ultra',
                    'iPhone 17 Pro Max',
                  ])
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: sys.label,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < rows.length; i++)
            _up(
              _span(t, .1 + .1 * i, .4 + .1 * i),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: sys.separator, width: .5),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 88,
                      child: Text(
                        rows[i].$1,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 15, color: sys.label2),
                      ),
                    ),
                    for (var side = 0; side < 2; side++)
                      Expanded(
                        child: cell(
                          side == 0 ? rows[i].$2 : rows[i].$3,
                          rows[i].$4 == side,
                          _span(t, .55 + .1 * i, .75 + .1 * i),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 3장: 질문 말풍선이 오르고, 답 카드가 표로 펼쳐진다.
class _AskPane extends StatelessWidget {
  const _AskPane({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final rows = <(String, String)>[
      (SpecLabels.of(SpecKind.tpIndex), '85'),
      (SpecLabels.of(SpecKind.price), r'$799'),
      (SpecLabels.of(SpecKind.camera), '83'),
    ];
    return _Played(
      active: active,
      duration: const Duration(milliseconds: 1600),
      builder: (context, t) {
        final ask = _span(t, 0, .3);
        final answer = _span(t, .35, .65);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Align(
              alignment: Alignment.centerRight,
              child: _up(
                ask,
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: TpSys.accent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    K.onbAsk.tr(),
                    style: const TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: .82,
                child: _up(
                  answer,
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: sys.background,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Vivo X300s',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: sys.label,
                          ),
                        ),
                        for (var i = 0; i < rows.length; i++)
                          Opacity(
                            opacity: _span(t, .55 + .1 * i, .8 + .1 * i),
                            child: Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.only(top: 5),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: sys.separator,
                                    width: .5,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      rows[i].$1,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: sys.label2,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    rows[i].$2,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: sys.label,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 장이 들어올 때 글자가 조금 올라오며 나타난다. 이미 본 장으로 돌아와도 다시.
class _Rise extends StatefulWidget {
  const _Rise({required this.active, required this.delay, required this.child});

  final bool active;
  final Duration delay;
  final Widget child;

  @override
  State<_Rise> createState() => _RiseState();
}

class _RiseState extends State<_Rise> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  CurvedAnimation? _t;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_t != null) return;
    final move = context.motion.listItem;
    final total = move.duration + widget.delay;
    _c.duration = total;
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(
        total == Duration.zero
            ? 0
            : widget.delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: move.curve,
      ),
    );
    if (widget.active) _play();
  }

  @override
  void didUpdateWidget(_Rise oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  void _play() {
    if (context.motion.isReduced) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _t?.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _t!,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(_t!),
      child: widget.child,
    ),
  );
}
