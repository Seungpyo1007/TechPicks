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
import '../../shared/widgets/tp_chip.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// AI 상담.
///
/// v1 의 ChatAI 는 모델 답을 문단 그대로 뿌렸다. 명세는 고른 기기 하나,
/// 한 줄 근거, 4줄 표로 나눠 받으라고 못박았고 마크다운 렌더링을 금지한다.
///
/// 카피는 아직 하드코딩이다.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.onTabSelected, this.onDeviceTap});

  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;

  /// 입력 바 위에 깔리는 제안. 명세의 suggestion chips.
  ///
  /// 처음엔 축 이름(Camera, Battery …)을 재활용했는데, 누르면 그 한 단어가
  /// 그대로 질문으로 나가고 답변 표의 행 이름과도 겹친다. 문장으로 따로 뒀다.
  static List<String> suggestions() =>
      K.askSuggestions.map((k) => k.tr()).toList(growable: false);

  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref.read(askProvider.notifier).send(text);
    if (!mounted || !_scroll.hasClients) return;
    final motion = context.motion;
    await _scroll.animateTo(
      _scroll.position.maxScrollExtent,
      duration: motion.contentSwap.duration,
      curve: motion.contentSwap.curve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(askProvider);
    final busy = ref.watch(askBusyProvider);
    // 앱에 Scaffold 가 없어 아무도 키보드를 안 피한다. 입력 바가 화면 바닥에
    // 붙어 있어서, 누르면 키보드가 입력 바와 제안 칩을 통째로 덮었다.
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return TpShell(
      title: K.tabAsk.tr(),
      tab: TpTab.ask,
      onTabSelected: widget.onTabSelected,
      // 셸의 인셋은 이 자리 아래에 있다. 화면 build 에서 바로 읽으면 크롬이
      // 차지한 자리를 모르는 예전 값이 나온다.
      child: Builder(
        builder: (context) => Stack(
          children: <Widget>[
            ListView.builder(
              controller: _scroll,
              // 입력 바는 이 영역 바닥에 붙는다. 그만큼 아래를 비워둬야 마지막
              // 말풍선이 그 뒤로 숨지 않는다. 셸에 여백을 더하면 입력 바가
              // 탭 바에서 그만큼 떠서 빈 공간이 생긴다.
              padding:
                  EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    8 + _Composer.height + keyboard,
                  ) +
                  tpContentInset(context),
              // 기다리는 동안 말풍선 하나를 더 놓는다. 아무 표시가 없으면
              // 답이 오는 중인지 실패한 건지 알 수 없다.
              itemCount: messages.length + (busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == messages.length) {
                  return _Arriving(
                    child: _Bubble(message: AskMessage.ai(K.askThinking.tr())),
                  );
                }
                final bubble = _Bubble(
                  message: messages[i],
                  // 답이 도착한 걸 스크린 리더가 알려줘야 한다. 화면은
                  // 스크롤로 알리지만 그건 눈으로 보는 사람에게만 통한다.
                  announce:
                      !busy && i == messages.length - 1 && !messages[i].isUser,
                  onDeviceTap: widget.onDeviceTap,
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
              // 콘텐츠가 탭 바 아래로 흐르므로 입력 바는 그만큼 위에 붙어야
              // 한다. 안 그러면 제안 칩과 입력창이 탭 캡슐 뒤로 숨는다.
              bottom: keyboard + tpContentInset(context).bottom,
              child: _Composer(controller: _input, onSend: _send, busy: busy),
            ),
          ],
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
    final curve = CurvedAnimation(
      parent: _c,
      curve: context.motion.listItem.curve,
    );
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
  });

  final AskMessage message;

  /// 방금 도착한 AI 답. 스크린 리더가 읽어준다.
  final bool announce;

  final ValueChanged<String>? onDeviceTap;

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
          Expanded(child: Text(row.label, style: type.secondary)),
          Text(
            row.value,
            maxLines: 1,
            softWrap: false,
            style: type.body.copyWith(fontWeight: t.boldWeight),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.onSend,
    this.busy = false,
  });

  /// 제안 칩 46 + 사이 10 + 입력 48 + 위아래 여백.
  static const double height = 118;

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  /// 답을 기다리는 중. 보내기를 잠근다 — 눌러도 버려질 뿐이었다.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 46,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: AskScreen.suggestions().length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => TpChip(
              label: AskScreen.suggestions()[i],
              selected: false,
              onTap: () => onSend(AskScreen.suggestions()[i]),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  height: 48,
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
                          vertical: 14,
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
                  width: 48,
                  height: 48,
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
