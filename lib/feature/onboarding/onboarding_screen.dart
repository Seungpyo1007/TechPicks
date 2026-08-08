import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_tap_target.dart';

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
    _pages.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
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
                  style: type.body.copyWith(color: TpTokens.blueText),
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
                      _Figure(index: i),
                      const SizedBox(height: 32),
                      Text(pane.title.tr(), style: type.largeTitle),
                      const SizedBox(height: 12),
                      Text(
                        pane.body.tr(),
                        style: type.body.copyWith(height: 1.5),
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _index ? TpTokens.blue : t.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
            child: GestureDetector(
              onTap: _next,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TpTokens.blue,
                  borderRadius: BorderRadius.circular(
                    t.isGlass ? TpTokens.rControl : t.rCard,
                  ),
                  boxShadow: t.buttonShadow,
                ),
                child: Text(
                  (last ? K.start : K.next).tr(),
                  style: type.body.copyWith(
                    color: Colors.white,
                    fontWeight: t.boldWeight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 각 장의 개념도. 실제 화면 요소를 단순화한 모양이다.
class _Figure extends StatelessWidget {
  const _Figure({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return SizedBox(
      height: 120,
      child: switch (index) {
        // 점수 다섯 줄이 숫자 하나로 접히는 그림.
        0 => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final f in <double>[.9, .5, .7, .6, .4])
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: FractionallySizedBox(
                    widthFactor: f,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        gradient: t.barFill,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        // 두 열이 나란히 선 그림.
        1 => Row(
            children: <Widget>[
              for (var i = 0; i < 2; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    height: 96,
                    decoration: BoxDecoration(
                      color: i == 0 ? t.tintFill : t.track,
                      borderRadius: BorderRadius.circular(t.rInner),
                    ),
                  ),
                ),
              ],
            ],
          ),
        // 말풍선 두 개.
        _ => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FractionallySizedBox(
                widthFactor: .55,
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: t.track,
                    borderRadius: BorderRadius.circular(t.rInner),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: .45,
                  alignment: Alignment.centerRight,
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      color: TpTokens.blue,
                      borderRadius: BorderRadius.circular(t.rInner),
                    ),
                  ),
                ),
              ),
            ],
          ),
      },
    );
  }
}
