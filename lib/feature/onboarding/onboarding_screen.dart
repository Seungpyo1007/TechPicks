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

/// 온보딩 세 장.
///
/// v1 의 FirstTutorial / SecondTutorial 을 대체한다. 그쪽은 건너뛰면 다시 볼
/// 수 없다는 경고 다이얼로그를 띄웠는데, 되돌릴 수 없는 선택을 만들 이유가
/// 없어 없앴다. Skip 은 그냥 넘어간다.
///
/// 문구는 명세에 확정돼 있다. 제목의 줄바꿈도 지정된 위치 그대로다.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  /// 문구는 번역 파일에 있다. 제목의 하드 브레이크도 거기 그대로 들어 있다.

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;

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
    if (_index == K.onboarding.length - 1) {
      _finish();
      return;
    }
    // 리터럴이던 때는 바로 아래 점(selection)과 박자가 어긋났고 "동작 줄이기"도
    // 안 먹었다.
    final move = context.motion.contentSwap;
    _pages.nextPage(duration: move.duration, curve: move.curve);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final last = _index == K.onboarding.length - 1;

    return TpShell(
      mode: TpChromeMode.plain,
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 16, 0),
              child: TpTapTarget(
                onTap: _finish,
                child: Text(
                  K.skip.tr(),
                  style: type.body.copyWith(color: t.link),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pages,
              onPageChanged: (i) => setState(() => _index = i),
              itemCount: K.onboarding.length,
              itemBuilder: (context, i) {
                final pane = K.onboarding[i];
                // 글자 크기를 키우면 한 화면에 안 들어간다. 잘리는 대신
                // 스크롤되게 둔다.
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _Figure(index: i, active: i == _index),
                      const SizedBox(height: 32),
                      // 그림이 먼저, 제목과 본문이 조금씩 늦게 올라온다.
                      _Rise(
                        active: i == _index,
                        delay: const Duration(milliseconds: 180),
                        child: Text(pane.title.tr(), style: type.largeTitle),
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
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (var i = 0; i < K.onboarding.length; i++)
                // iOS 페이지 컨트롤: 7pt 원, 간격 9, 지금 것만 진하게.
                AnimatedContainer(
                  duration: context.motion.selection.duration,
                  curve: context.motion.selection.curve,
                  margin: const EdgeInsets.symmetric(horizontal: 4.5),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: i == _index ? context.sys.label : context.sys.label3,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
            child: TpButton(
              label: (last ? K.start : K.next).tr(),
              onTap: _next,
            ),
          ),
        ],
      ),
    );
  }
}

/// 각 장의 개념도. 실제 화면 요소를 단순화한 모양이 움직인다.
///
/// 그 장이 화면에 들어올 때마다 처음부터 다시 튼다([active]).
class _Figure extends StatelessWidget {
  const _Figure({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) => TpFigure(
    height: 120,
    active: active,
    delay: const Duration(milliseconds: 120),
    duration: const Duration(milliseconds: 2000),
    paint: switch (index) {
      0 => TpFigures.index,
      1 => TpFigures.compare,
      _ => TpFigures.ask,
    },
  );
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
