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

    return TpShell(
      title: K.tabAsk.tr(),
      tab: TpTab.ask,
      onTabSelected: widget.onTabSelected,
      child: Stack(
        children: <Widget>[
          ListView.builder(
            controller: _scroll,
            // 입력 바는 이 영역 바닥에 붙는다. 그만큼 아래를 비워둬야 마지막
            // 말풍선이 그 뒤로 숨지 않는다. 셸에 여백을 더하면 입력 바가
            // 탭 바에서 그만큼 떠서 빈 공간이 생긴다.
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8 + _Composer.height),
            itemCount: messages.length,
            itemBuilder: (context, i) => _Bubble(
              message: messages[i],
              // 답이 도착한 걸 스크린 리더가 알려줘야 한다. 화면은 스크롤로
              // 알리지만 그건 눈으로 보는 사람에게만 통한다.
              announce: i == messages.length - 1 && !messages[i].isUser,
              onDeviceTap: widget.onDeviceTap,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Composer(controller: _input, onSend: _send),
          ),
        ],
      ),
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
  const _Composer({required this.controller, required this.onSend});

  /// 제안 칩 38 + 사이 10 + 입력 48 + 위아래 여백.
  static const double height = 110;

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 38,
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
                onTap: () => onSend(controller.text),
                // 입력창과 같은 이름을 주면 스크린 리더가 버튼도
                // "무엇이든 물어보세요"라고 읽는다.
                label: K.send.tr(),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: TpTokens.blue,
                    shape: BoxShape.circle,
                    boxShadow: t.buttonShadow,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
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
