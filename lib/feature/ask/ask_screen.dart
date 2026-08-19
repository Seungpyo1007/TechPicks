import 'dart:async';
import 'dart:math' as math;

import '../../app/theme/tp_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../domain/model/ask_answer.dart';
import '../../shared/widgets/tp_button.dart';
import '../../shared/widgets/tp_chip.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// AI 상담.
///
/// v1 의 ChatAI 는 모델 답을 문단 그대로 뿌렸다. 명세는 고른 기기 하나,
/// 한 줄 근거, 4줄 표로 나눠 받으라고 못박았고 마크다운 렌더링을 금지한다.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.onTabSelected, this.onDeviceTap});

  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;

  /// 기다리는 동안 답 자리에 놓이는 뼈대.
  @visibleForTesting
  static const Key thinkingKey = ValueKey<String>('ask-thinking');

  /// 입력 바 위에 깔리는 제안. 명세의 suggestion chips.
  ///
  /// 처음엔 축 이름(Camera, Battery …)을 재활용했는데, 누르면 그 한 단어가
  /// 그대로 질문으로 나가고 답변 표의 행 이름과도 겹친다. 문장으로 따로 뒀다.
  static List<String> suggestions() =>
      K.askSuggestions.map((k) => k.tr()).toList(growable: false);

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen>
    with WidgetsBindingObserver {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  /// 마지막으로 본 키보드 높이. 올라올 때만 따라 내린다.
  double _keyboard = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    final next = MediaQuery.viewInsetsOf(context).bottom;
    final grew = next > _keyboard;
    _keyboard = next;
    // 키보드가 올라오면 목록이 그만큼 짧아진다. 그대로 두면 방금 읽던 답이
    // 키보드 뒤로 밀린다.
    if (grew) _scrollToEnd();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    // 기다리는 중에는 안 받는다. 여기서 지우면 글자만 사라지고 질문은
    // 노티파이어의 _busy 가드에서 조용히 버려진다 — 톡 치고 나면 아무 일도
    // 안 일어나고 쳤던 것만 없어졌다.
    if (ref.read(askBusyProvider)) return;
    _input.clear();
    await ref.read(askProvider.notifier).send(text);
  }

  /// 마지막 말풍선까지 내린다.
  ///
  /// **다음 프레임에** 내려야 한다. 상태가 바뀐 직후의 `maxScrollExtent` 는
  /// 아직 답이 놓이기 전 값이라, 답이 길수록 아래가 잘린 채로 멈췄다.
  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      final move = context.motion.contentSwap;
      if (move.duration == Duration.zero) {
        _scroll.jumpTo(target);
        return;
      }
      unawaited(
        _scroll.animateTo(target, duration: move.duration, curve: move.curve),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // 말풍선이 붙을 때마다 따라 내린다. 사용자 말풍선, 긴 답, 다시 시도,
    // 비교 화면의 "이유 물어보기"(_send 를 안 거친다)가 전부 이 하나로 걸린다.
    ref.listen<List<AskMessage>>(askProvider, (_, _) => _scrollToEnd());

    final messages = ref.watch(askProvider);
    final busy = ref.watch(askBusyProvider);

    return TpShell(
      title: K.tabAsk.tr(),
      tab: TpTab.ask,
      onTabSelected: widget.onTabSelected,
      // 셸의 인셋은 이 자리 아래에 있다. 화면 build 에서 바로 읽으면 크롬이
      // 차지한 자리를 모르는 예전 값이 나온다.
      child: Builder(
        builder: (context) {
          final motion = context.motion;
          final insets = TpChromeInsets.of(context);
          final keyboard = MediaQuery.viewInsetsOf(context).bottom;
          // 화면 바닥에서 입력 바까지.
          //
          // 키보드가 올라오면 탭 캡슐은 그 뒤로 숨는다 — 유리 크롬이 "알려만
          // 준" 자리를 도로 쓴다. 안 그러면 키보드 위에 122pt 짜리 빈 띠가
          // 남는다. 안드로이드는 그 자리를 이미 패딩으로 비웠으므로 그만큼
          // 뺀다. 두 크롬 다 키보드 바로 위에 붙는다.
          final lift = math.max(
            insets.advisory.bottom,
            keyboard + _keyboardGap - insets.physical.bottom,
          );
          final composer = _Composer.heightOf(context);

          return Stack(
            children: <Widget>[
              ListView.builder(
                controller: _scroll,
                // 입력 바는 이 영역 바닥에 붙는다. 그만큼 아래를 비워둬야
                // 마지막 말풍선이 그 뒤로 숨지 않는다.
                padding: EdgeInsets.fromLTRB(
                  16,
                  8 + insets.advisory.top,
                  16,
                  8 + composer + lift,
                ),
                // 기다리는 동안 답 자리에 뼈대를 놓는다. 아무 표시가 없으면
                // 답이 오는 중인지 실패한 건지 알 수 없다.
                itemCount: messages.length + 1,
                itemBuilder: (context, i) {
                  if (i == messages.length) {
                    return AnimatedSwitcher(
                      duration: motion.contentSwap.duration,
                      switchInCurve: motion.contentSwap.curve,
                      switchOutCurve: motion.contentSwap.curve,
                      child: busy
                          ? const _Thinking(key: AskScreen.thinkingKey)
                          : const SizedBox.shrink(
                              key: ValueKey<String>('idle'),
                            ),
                    );
                  }
                  final bubble = _Bubble(
                    message: messages[i],
                    // 답이 도착한 걸 스크린 리더가 알려줘야 한다. 화면은
                    // 스크롤로 알리지만 그건 눈으로 보는 사람에게만 통한다.
                    announce:
                        !busy &&
                        i == messages.length - 1 &&
                        !messages[i].isUser,
                    onDeviceTap: widget.onDeviceTap,
                    onRetry: !busy && i == messages.length - 1
                        ? () => ref.read(askProvider.notifier).retry()
                        : null,
                  );
                  // 마지막 말풍선만 올라오며 나타난다. 목록을 되감을 때마다
                  // 옛 말풍선이 다시 움직이면 그게 더 산만하다.
                  return i == messages.length - 1
                      ? _Arriving(key: ValueKey<int>(i), child: bubble)
                      : bubble;
                },
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: lift,
                child: _Composer(
                  key: askComposerKey,
                  controller: _input,
                  onSend: _send,
                  busy: busy,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 입력 바와 키보드 사이.
const double _keyboardGap = 8;

/// 컴포저가 실제로 차지한 높이를 재는 자리.
@visibleForTesting
const Key askComposerKey = ValueKey<String>('ask-composer');

/// 답을 기다리는 동안 답 자리에 놓이는 뼈대.
///
/// 예전에는 "생각 중…" 이라고 쓴 **진짜 말풍선**이었다. 명세는 로딩을 카드
/// 자기 반지름의 뼈대로 그리라고 했고(가운데 스피너 금지), 랭킹·비교·상세가
/// 다 그렇게 한다. 글자로 알리면 그게 답인 줄 알고 읽게 된다.
class _Thinking extends StatelessWidget {
  const _Thinking({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    // 답 글자 한 줄과 같은 높이. 배율을 따라간다.
    final line =
        (MediaQuery.textScalerOf(context).scale(type.body.fontSize!) * 1.4)
            .ceilToDouble();

    Widget bar(double factor) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: factor,
      child: Container(
        height: line,
        decoration: BoxDecoration(
          color: t.track,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: K.askThinking.tr(),
      excludeSemantics: true,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TpSurface(
              strong: true,
              radius: t.rInner,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  bar(0.9),
                  const SizedBox(height: 8),
                  bar(0.6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 새 말풍선이 아래에서 올라오며 나타난다.
///
/// 답이 툭 나타나면 방금 온 것인지 원래 있던 것인지 안 읽힌다. 스크롤은
/// 같은 순간에 따로 움직이고 있어서 더 그렇다.
class _Arriving extends StatefulWidget {
  const _Arriving({super.key, required this.child});

  final Widget child;

  @override
  State<_Arriving> createState() => _ArrivingState();
}

class _ArrivingState extends State<_Arriving>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    final move = context.motion.listItem;
    _c.duration = move.duration == Duration.zero
        ? const Duration(milliseconds: 1)
        : move.duration;
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CurvedAnimation 을 여기서 만들면 리빌드마다 하나씩 새고(dispose 를 못
    // 부른다), 누수 추적기가 그걸 잡는다. drive 는 들고 있을 것이 없다.
    final curve = _c.drive(CurveTween(curve: context.motion.listItem.curve));
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) => Opacity(
        opacity: curve.value,
        child: FractionalTranslation(
          // 자기 높이의 12% 만 올라온다. 더 주면 목록 전체가 출렁인다.
          translation: Offset(0, (1 - curve.value) * 0.12),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    this.announce = false,
    this.onDeviceTap,
    this.onRetry,
  });

  final AskMessage message;

  /// 방금 도착한 AI 답. 스크린 리더가 읽어준다.
  final bool announce;

  final ValueChanged<String>? onDeviceTap;

  /// 실패한 답에만 붙는다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final answer = message.answer;

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          alignment: Alignment.centerRight,
          widthFactor: 0.78,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: TpTokens.blue,
              borderRadius: BorderRadius.circular(t.rInner),
            ),
            child: Text(
              message.text,
              style: type.body.copyWith(color: Colors.white),
            ),
          ),
        ),
      );
    }

    return Semantics(
      liveRegion: announce,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TpSurface(
              strong: true,
              radius: t.rInner,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              onTap: answer?.pickSlug == null || onDeviceTap == null
                  ? null
                  : () => onDeviceTap!(answer!.pickSlug!),
              // 누를 수 있는 면인데 이름이 없었다. 스크린 리더가 "버튼"
              // 하나만 읽고 무엇으로 가는지는 안 읽었다.
              semanticsLabel: answer?.pick,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    message.text,
                    style: answer == null ? type.body : type.cardTitle,
                  ),
                  if (answer != null) ...<Widget>[
                    if (answer.reason.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(answer.reason, style: type.secondary),
                    ],
                    if (answer.rows.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 10),
                      for (final row in answer.rows) _AnswerRow(row: row),
                    ],
                  ],
                  // 실패한 답이 성공한 답과 똑같이 생겼었다. failed 는
                  // 세팅만 되고 아무 데서도 안 읽혔다.
                  if (message.failed && onRetry != null) ...<Widget>[
                    const SizedBox(height: 10),
                    TpButton(
                      label: K.retry.tr(),
                      kind: TpButtonKind.secondary,
                      height: 48,
                      expand: false,
                      onTap: onRetry,
                    ),
                  ],
                  // 모델이 못 답해서 카탈로그가 대신 고른 것이다. 모델이
                  // 답한 것처럼 보이면 안 된다.
                  if (message.fromCatalog) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(K.askFromCatalog.tr(), style: type.caption),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({required this.row});

  final AskRow row;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: t.hairline)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(flex: 3, child: Text(row.label, style: type.secondary)),
          const SizedBox(width: 12),
          // softWrap 이 false 면 기본이 clip 이라 글리프 한가운데서 잘린다.
          // 그리고 유연하지 않은 자식이면 폭을 먼저 다 가져가 라벨을 굶긴다.
          Expanded(
            flex: 2,
            child: Text(
              row.value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: type.body.copyWith(fontWeight: t.boldWeight),
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    super.key,
    required this.controller,
    required this.onSend,
    this.busy = false,
  });

  static const double _chipPadV = 9;
  static const double _chipTapPadV = 4;
  static const double _gap = 10;
  static const double _padBottom = 4;

  /// 입력칸 안쪽 위아래 여백. 배율 1.0 에서 알약이 정확히 48 이 되는 값이다.
  static const double _fieldPadV = 13.5;

  /// 접근성 최소 탭 크기. 이 아래로는 안 내려간다.
  static const double _minTap = 48;

  /// 제안 칩 줄의 높이. 13.5pt · height 1.4 가 배율을 그대로 따라간다.
  static double chipsHeightOf(BuildContext context) => math.max(
    46,
    (MediaQuery.textScalerOf(context).scale(13.5) * 1.4 +
            2 * _chipPadV +
            2 * _chipTapPadV)
        .ceilToDouble(),
  );

  /// 입력 알약의 높이.
  static double fieldHeightOf(BuildContext context) => math.max(
    _minTap,
    (MediaQuery.textScalerOf(context).scale(context.tpText.body.fontSize!) *
                1.4 +
            2 * _fieldPadV)
        .ceilToDouble(),
  );

  /// 컴포저가 통째로 먹는 높이.
  ///
  /// **상수로 잡으면 안 된다.** 예전에는 118 이었는데 실제로는 어느 배율에서도
  /// 108 이었다 — 두 상자가 높이로 묶여 있어서 안 자랐고, 1.6배에서 칩 라벨은
  /// 20pt 자리에 30pt 가 들어가고 입력 글자는 48 상자 밖으로 삐져나갔다.
  /// 예외가 안 나서 글자 배율 테스트도 조용했다.
  static double heightOf(BuildContext context) =>
      chipsHeightOf(context) + _gap + fieldHeightOf(context) + _padBottom;

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  /// 답을 기다리는 중. 보내기를 잠근다 — 눌러도 버려질 뿐이었다.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    // 한 프레임에 한 번만 만든다. 예전에는 itemCount·label·onTap 에서 각각
    // 불러서 프레임마다 네 번씩 다시 번역했다. static 으로 캐시하면 안 된다 —
    // 언어가 실시간으로 바뀐다.
    final items = AskScreen.suggestions();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: chipsHeightOf(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => TpChip(
              label: items[i],
              selected: false,
              onTap: () => onSend(items[i]),
            ),
          ),
        ),
        const SizedBox(height: _gap),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, _padBottom),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: fieldHeightOf(context),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.inputBg,
                    borderRadius: BorderRadius.circular(TpTokens.rControl),
                    boxShadow: t.inputShadow,
                  ),
                  // 힌트는 글자를 치면 사라진다. 이름은 남아 있어야 한다.
                  child: Semantics(
                    label: K.askHint.tr(),
                    child: TextField(
                      controller: controller,
                      onSubmitted: onSend,
                      style: type.body,
                      decoration: InputDecoration(
                        // isDense 를 켜면 필드의 히트 영역이 29px 로 줄어
                        // 접근성 기준(48)에 못 미친다.
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: _fieldPadV,
                        ),
                        border: InputBorder.none,
                        // 이름은 Semantics 가 준다. 힌트까지 시맨틱에 들어가면
                        // 두 번 읽힌다.
                        hint: ExcludeSemantics(
                          child: Text(
                            K.askHint.tr(),
                            style: type.body.copyWith(color: t.dim),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TpTapTarget(
                onTap: busy ? null : () => onSend(controller.text),
                // 입력창과 같은 이름을 주면 스크린 리더가 버튼도
                // "무엇이든 물어보세요"라고 읽는다.
                label: K.send.tr(),
                child: Container(
                  width: _minTap,
                  height: _minTap,
                  decoration: BoxDecoration(
                    // 잠긴 동안은 잠긴 것처럼 보여야 한다.
                    color: busy ? t.chipBg : TpTokens.blue,
                    shape: BoxShape.circle,
                    boxShadow: busy ? null : t.buttonShadow,
                  ),
                  child: Icon(
                    Icons.arrow_upward,
                    color: busy ? t.dim : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
