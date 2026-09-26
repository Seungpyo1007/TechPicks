import '../../app/theme/tp_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../shared/figures/tp_figure.dart';
import '../../shared/figures/tp_figures.dart';
import '../../shared/widgets/tp_button.dart';

/// 온보딩 네 장. 그림이 주인공이다.
///
/// 넘길 때 그림은 손가락보다 느리게, 글자는 조금 빠르게 밀린다(시차). 뒤의
/// 액센트 빛은 장마다 자리를 옮긴다.
///
/// 마지막 장에서 로그인하고 시작하거나 그냥 시작한다. 건너뛰기는 1–3장에만.
/// 되돌릴 수 없다는 경고는 없다(v1 에는 있었다).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onDone, this.onSignIn});

  /// 로그인 없이 끝.
  final VoidCallback? onDone;

  /// 마지막 장 "로그인하고 시작". 완료 표시는 여기서 이미 남긴다.
  final VoidCallback? onSignIn;

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

  void _finish({bool signIn = false}) {
    ref.read(onboardingDoneProvider.notifier).complete();
    if (signIn && widget.onSignIn != null) {
      widget.onSignIn!();
    } else {
      widget.onDone?.call();
    }
  }

  void _next() {
    final move = context.motion.contentSwap;
    _pages.nextPage(duration: move.duration, curve: move.curve);
  }

  /// 지금 페이지 위치(소수). 넘기는 중에도 움직인다.
  double get _page => _pages.hasClients && _pages.position.haveDimensions
      ? (_pages.page ?? _index.toDouble())
      : _index.toDouble();

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final last = _index == _count - 1;

    return TpShell(
      mode: TpChromeMode.plain,
      child: Stack(
        children: <Widget>[
          // 장마다 자리를 옮기는 옅은 빛.
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _pages,
                builder: (context, _) => CustomPaint(
                  painter: _Glow(page: _page, count: _count),
                ),
              ),
            ),
          ),
          Column(
            children: <Widget>[
              SizedBox(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedOpacity(
                    opacity: last ? 0 : 1,
                    duration: context.motion.selection.duration,
                    child: IgnorePointer(
                      ignoring: last,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 2, 12, 0),
                        child: TpTapTarget(
                          onTap: _finish,
                          child: Text(
                            K.skip.tr(),
                            style: type.body.copyWith(color: t.link),
                          ),
                        ),
                      ),
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
                        // 이 장이 가운데서 얼마나 벗어났는지. -1..1.
                        final off = (_page - i).clamp(-1.0, 1.0);
                        final w = MediaQuery.sizeOf(context).width;
                        return Opacity(
                          opacity: (1 - off.abs() * .7).clamp(0.0, 1.0),
                          // 글자를 키우면 한 화면에 안 들어간다. 잘리는 대신
                          // 스크롤된다. 들어가면 가운데 정렬.
                          child: LayoutBuilder(
                            builder: (context, box) => SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: box.maxHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    children: <Widget>[
                                      const Spacer(),
                                      Transform.translate(
                                        offset: Offset(off * w * .35, 0),
                                        child: Transform.scale(
                                          scale: 1 - off.abs() * .08,
                                          child: _FigureCard(
                                            index: i,
                                            active: i == _index,
                                            height: (box.maxHeight * .42).clamp(
                                              150.0,
                                              280.0,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 36),
                                      Transform.translate(
                                        offset: Offset(off * -w * .12, 0),
                                        child: child,
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _Rise(
                              active: i == _index,
                              delay: const Duration(milliseconds: 180),
                              child: Text(
                                pane.title.tr(),
                                style: type.largeTitle,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _Rise(
                              active: i == _index,
                              delay: const Duration(milliseconds: 280),
                              child: Text(
                                pane.body.tr(),
                                style: type.body.copyWith(height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              _Dots(index: _index, count: _count),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
                child: AnimatedSwitcher(
                  duration: context.motion.contentSwap.duration,
                  child: last
                      ? TpButton(
                          key: const ValueKey<String>('sign-in'),
                          label: K.startSignIn.tr(),
                          onTap: () => _finish(signIn: true),
                        )
                      : TpButton(
                          key: const ValueKey<String>('next'),
                          label: K.next.tr(),
                          onTap: _next,
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: AnimatedOpacity(
                  opacity: last ? 1 : 0,
                  duration: context.motion.selection.duration,
                  child: IgnorePointer(
                    ignoring: !last,
                    child: Center(
                      child: TpTapTarget(
                        onTap: _finish,
                        child: Text(
                          K.startGuest.tr(),
                          style: type.body.copyWith(color: t.link),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
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

/// 흰 카드 안의 그림. 그 장이 들어올 때마다 처음부터 다시 튼다.
class _FigureCard extends StatelessWidget {
  const _FigureCard({
    required this.index,
    required this.active,
    required this.height,
  });

  final int index;
  final bool active;
  final double height;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 24),
    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
    decoration: BoxDecoration(
      color: context.sys.cell,
      borderRadius: BorderRadius.circular(32),
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
    ),
    child: TpFigure(
      height: height - 64,
      active: active,
      delay: const Duration(milliseconds: 120),
      duration: const Duration(milliseconds: 2200),
      paint: switch (index) {
        0 => TpFigures.index,
        1 => TpFigures.compare,
        2 => TpFigures.ask,
        _ => TpFigures.sync,
      },
    ),
  );
}

/// 뒤의 옅은 액센트 빛. 장이 넘어가는 만큼 옆으로 흐른다.
class _Glow extends CustomPainter {
  const _Glow({required this.page, required this.count});

  final double page;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    final k = count <= 1 ? 0.0 : page / (count - 1);
    final center = Offset(
      size.width * (.2 + .6 * k),
      size.height * (.28 + .06 * (k - .5).abs()),
    );
    final r = size.width * .9;
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            TpSys.accent.withValues(alpha: .14),
            TpSys.accent.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: r)),
    );
  }

  @override
  bool shouldRepaint(_Glow old) => old.page != page || old.count != count;
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
