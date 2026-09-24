import 'dart:async';
import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_icons.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../domain/model/ask_answer.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// 질문 시트.
///
/// v1 의 ChatAI 는 모델 답을 문단 그대로 뿌렸다. 명세는 고른 기기 하나,
/// 한 줄 근거, 4줄 표로 나눠 받으라고 못박았고 마크다운 렌더링을 금지한다.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.onDeviceTap, this.onClose});

  final ValueChanged<String>? onDeviceTap;

  /// 시트 닫기.
  final VoidCallback? onClose;

  /// 기다리는 동안 답 자리에 놓이는 뼈대.
  @visibleForTesting
  static const Key thinkingKey = ValueKey<String>('ask-thinking');

  /// 입력 줄 위의 제안.
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
    // 노티파이어의 _busy 가드에서 조용히 버려진다.
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
    // 말풍선이 붙을 때마다 따라 내린다. 비교 화면의 "이유 물어보기"는
    // _send 를 안 거치므로 여기서 같이 걸린다.
    ref.listen<List<AskMessage>>(askProvider, (_, _) => _scrollToEnd());

    final sys = context.sys;
    final motion = context.motion;
    final messages = ref.watch(askProvider);
    final busy = ref.watch(askBusyProvider);
    final topic = ref.watch(askTopicProvider);
    // 첫 안내 말풍선만 있을 때. 제안을 전부 펼쳐 보인다.
    final fresh = messages.length <= 1 && !busy;

    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safe = MediaQuery.viewPaddingOf(context).bottom;
    // 키보드가 있으면 그 위 8, 없으면 홈 인디케이터 위.
    final lift = math.max(safe, keyboard + _keyboardGap);
    final composer = _Composer.heightOf(context, fresh: fresh);

    return ColoredBox(
      color: sys.background,
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: <Widget>[
            _Header(onClose: widget.onClose),
            Expanded(
              child: Stack(
                children: <Widget>[
                  ListView.builder(
                    controller: _scroll,
                    // 대화를 거슬러 올리면 키보드가 내려간다. iOS 메시지와 같다.
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      12 + composer + lift,
                    ),
                    itemCount: messages.length + 2,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return topic == null
                            ? const SizedBox.shrink()
                            : _Topic(label: topic);
                      }
                      final m = i - 1;
                      if (m == messages.length) {
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
                      final last = m == messages.length - 1;
                      final bubble = _Bubble(
                        message: messages[m],
                        // 답이 도착한 걸 스크린 리더가 알려줘야 한다.
                        announce: !busy && last && !messages[m].isUser,
                        onDeviceTap: widget.onDeviceTap,
                        onRetry: !busy && last
                            ? () => ref.read(askProvider.notifier).retry()
                            : null,
                      );
                      // 마지막 말풍선만 올라오며 나타난다.
                      return last
                          ? _Arriving(key: ValueKey<int>(m), child: bubble)
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
                      fresh: fresh,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 입력 줄과 키보드 사이.
const double _keyboardGap = 8;

/// 말풍선 모서리.
const double _bubbleRadius = 20;

/// 컴포저가 실제로 차지한 높이를 재는 자리.
@visibleForTesting
const Key askComposerKey = ValueKey<String>('ask-composer');

/// 시트 머리. 가운데 제목, 오른쪽 닫기.
class _Header extends StatelessWidget {
  const _Header({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final title = Text(
      K.askTitle.tr(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: sys.label,
      ),
    );
    if (!context.tp.isGlass) {
      return AppBar(
        automaticallyImplyLeading: false,
        title: title,
        actions: <Widget>[
          if (onClose != null)
            IconButton(
              onPressed: onClose,
              tooltip: K.close.tr(),
              icon: const Icon(Icons.close),
            ),
          const SizedBox(width: 4),
        ],
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 8,
        16,
        4,
      ),
      child: SizedBox(
        height: 44,
        child: NavigationToolbar(
          middle: title,
          trailing: onClose == null
              ? null
              : TpBarButton(
                  action: TpBarAction(
                    label: K.close.tr(),
                    icon: CupertinoIcons.xmark,
                    onTap: onClose,
                  ),
                ),
        ),
      ),
    );
  }
}

/// 들고 온 기기. 대화 맨 위 가운데.
class _Topic extends StatelessWidget {
  const _Topic({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: glass ? sys.fill3 : null,
            border: glass ? null : Border.all(color: sys.separator),
            borderRadius: BorderRadius.circular(glass ? 16 : 8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                glass
                    ? CupertinoIcons.arrow_right_arrow_left
                    : Icons.compare_arrows,
                size: 14,
                color: sys.label2,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: sys.label2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 답 말풍선 모양. 카드색, 왼쪽, 최대 78%.
class _AiShape extends StatelessWidget {
  const _AiShape({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: 0.78,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.sys.cell,
            borderRadius: BorderRadius.circular(_bubbleRadius),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: child,
          ),
        ),
      ),
    ),
  );
}

/// 답을 기다리는 동안 답 자리에 놓이는 뼈대.
///
/// 글자로 "생각 중…" 이라고 쓰면 그게 답인 줄 알고 읽게 된다.
class _Thinking extends StatelessWidget {
  const _Thinking({super.key});

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    // 답 글자 한 줄과 같은 높이. 배율을 따라간다.
    final line = (MediaQuery.textScalerOf(context).scale(17) * 1.3)
        .ceilToDouble();

    Widget bar(double factor) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: factor,
      child: Container(
        height: line,
        decoration: BoxDecoration(
          color: sys.fill3,
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: K.askThinking.tr(),
      excludeSemantics: true,
      child: _AiShape(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[bar(0.9), const SizedBox(height: 8), bar(0.6)],
        ),
      ),
    );
  }
}

/// 새 말풍선이 아래에서 올라오며 나타난다.
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
    // CurvedAnimation 을 여기서 만들면 리빌드마다 하나씩 샌다.
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

  /// 방금 도착한 답. 스크린 리더가 읽어준다.
  final bool announce;

  final ValueChanged<String>? onDeviceTap;

  /// 실패한 답에만 붙는다.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final answer = message.answer;
    final body = TextStyle(fontSize: 17, height: 1.3, color: sys.label);

    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: FractionallySizedBox(
          alignment: Alignment.centerRight,
          widthFactor: 0.78,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: TpSys.accent,
                borderRadius: BorderRadius.circular(_bubbleRadius),
              ),
              child: Text(
                message.text,
                style: body.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
      );
    }

    final slug = answer?.pickSlug;
    return Semantics(
      liveRegion: announce,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AiShape(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  message.text,
                  style: answer == null
                      ? body
                      : body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (answer != null) ...<Widget>[
                  if (answer.reason.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      answer.reason,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.33,
                        color: sys.label2,
                      ),
                    ),
                  ],
                  if (answer.rows.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    for (final row in answer.rows) _AnswerRow(row: row),
                  ],
                  if (slug != null && onDeviceTap != null)
                    _OpenLink(
                      label: K.openDevice.tr(),
                      semanticsLabel: '${K.openDevice.tr()}, ${answer.pick}',
                      onTap: () => onDeviceTap!(slug),
                    ),
                ],
                // 실패한 답이 성공한 답과 똑같이 생겼었다.
                if (message.failed && onRetry != null) ...<Widget>[
                  const SizedBox(height: 10),
                  TpPill(
                    label: K.retry.tr(),
                    kind: TpPillKind.tinted,
                    height: 44,
                    expand: false,
                    onTap: onRetry,
                  ),
                ],
              ],
            ),
          ),
          // 모델이 못 답해서 카탈로그가 대신 고른 것이다. 모델이 답한 것처럼
          // 보이면 안 된다.
          if (message.fromCatalog)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Text(
                K.askFromCatalog.tr(),
                style: TextStyle(fontSize: 13, color: sys.label2),
              ),
            ),
        ],
      ),
    );
  }
}

/// 답 아래 "기기 열기".
class _OpenLink extends StatelessWidget {
  const _OpenLink({
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: context.tp.isGlass ? 44 : 48),
          child: Row(
            children: <Widget>[
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: sys.accentText,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                context.tp.isGlass
                    ? CupertinoIcons.chevron_forward
                    : Icons.chevron_right,
                size: 15,
                color: sys.accentText,
              ),
            ],
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
    final sys = context.sys;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: sys.separator, width: .5)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Text(
              row.label,
              style: TextStyle(fontSize: 15, color: sys.label2),
            ),
          ),
          const SizedBox(width: 12),
          // softWrap 이 false 면 기본이 clip 이라 글리프 한가운데서 잘린다.
          Expanded(
            flex: 2,
            child: Text(
              row.value,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: sys.label,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 제안 칩 하나. iOS 는 회색 캡슐, Android 는 테두리 칩.
class _Suggestion extends StatelessWidget {
  const _Suggestion({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(
        press: true,
        onTap: onTap,
        child: Container(
          constraints: BoxConstraints(minHeight: _Composer.minTap(context)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: glass ? sys.cell : null,
            border: glass ? null : Border.all(color: sys.separator),
            borderRadius: BorderRadius.circular(glass ? 22 : 8),
          ),
          // Container 에 alignment 를 주면 Wrap 안에서 한 줄을 다 먹는다.
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(fontSize: 15, height: 1.3, color: sys.label),
            ),
          ),
        ),
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
    this.fresh = false,
  });

  static const double _chipPadV = 8;
  static const double _gap = 10;
  static const double _padBottom = 4;

  /// 칩 줄 사이.
  static const double _runGap = 8;

  /// 탭 크기 하한. iOS 44, Android 48.
  static double minTap(BuildContext context) => context.tp.isGlass ? 44 : 48;

  /// 입력 필드 높이 하한. iOS 캡슐 44, Android 56.
  static double _fieldMin(BuildContext context) => context.tp.isGlass ? 44 : 56;

  /// 제안 칩 하나의 높이. 배율을 그대로 따라간다.
  static double chipHeightOf(BuildContext context) => math.max(
    minTap(context),
    (MediaQuery.textScalerOf(context).scale(15) * 1.3 + 2 * _chipPadV)
        .ceilToDouble(),
  );

  /// 입력 필드 높이.
  static double fieldHeightOf(BuildContext context) => math.max(
    _fieldMin(context),
    (MediaQuery.textScalerOf(context).scale(17) * 1.3 + 2 * 11).ceilToDouble(),
  );

  /// 컴포저가 통째로 먹는 높이. 처음 화면에서는 칩이 줄바꿈해서 더 크다.
  ///
  /// **상수로 잡으면 안 된다.** 예전에는 118 이었는데 실제로는 108 이었고,
  /// 1.6배에서 글자가 상자 밖으로 나갔다. 줄바꿈한 칩 높이는 실제로 그린 뒤에야
  /// 알 수 있어서 넉넉히 두 줄로 잡는다. 목록 아래 여백에만 쓰인다.
  static double heightOf(BuildContext context, {bool fresh = false}) =>
      chipHeightOf(context) * (fresh ? 2 : 1) +
      (fresh ? _runGap : 0) +
      _gap +
      fieldHeightOf(context) +
      _padBottom;

  final TextEditingController controller;
  final ValueChanged<String> onSend;

  /// 답을 기다리는 중. 보내기를 잠근다.
  final bool busy;

  /// 대화 전. 제안이 줄바꿈으로 전부 보인다.
  final bool fresh;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    // 한 프레임에 한 번만 만든다. static 으로 캐시하면 안 된다 — 언어가
    // 실시간으로 바뀐다.
    final items = AskScreen.suggestions();
    final chips = <Widget>[
      for (final s in items) _Suggestion(label: s, onTap: () => onSend(s)),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (fresh)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(spacing: 8, runSpacing: _runGap, children: chips),
          )
        else
          SizedBox(
            height: chipHeightOf(context),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chips.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => Center(child: chips[i]),
            ),
          ),
        const SizedBox(height: _gap),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, _padBottom),
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final ready = !busy && value.text.trim().isNotEmpty;
              final field = fieldHeightOf(context);
              final send = _fieldMin(context);
              return Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: field,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: glass ? sys.cell : sys.fill3,
                        borderRadius: BorderRadius.circular(
                          glass ? field / 2 : 28,
                        ),
                      ),
                      // 힌트는 글자를 치면 사라진다. 이름은 남아 있어야 한다.
                      child: Semantics(
                        label: K.askHint.tr(),
                        child: TextField(
                          controller: controller,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          onSubmitted: onSend,
                          // 한 줄짜리 입력이라 Enter 가 곧 보내기다.
                          textInputAction: TextInputAction.send,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.3,
                            color: sys.label,
                          ),
                          cursorColor: TpSys.accent,
                          decoration: InputDecoration(
                            // isDense 를 켜면 히트 영역이 29px 로 줄어든다.
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 11,
                            ),
                            border: InputBorder.none,
                            // 자리표시는 무엇을 칠지 말한다. 이름은 Semantics
                            // 가 주므로 여기서는 시맨틱에서 뺀다.
                            hint: ExcludeSemantics(
                              child: Text(
                                K.askPlaceholder.tr(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 17,
                                  color: sys.label3,
                                ),
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
                    // 입력창과 같은 이름을 주면 버튼도 "무엇이든
                    // 물어보세요"라고 읽는다.
                    label: K.send.tr(),
                    minSize: minTap(context),
                    child: Container(
                      width: send,
                      height: send,
                      decoration: BoxDecoration(
                        color: ready ? TpSys.accent : sys.fill3,
                        shape: glass ? BoxShape.circle : BoxShape.rectangle,
                        borderRadius: glass ? null : BorderRadius.circular(16),
                      ),
                      child: Icon(
                        glass ? CupertinoIcons.arrow_up : context.icons.send,
                        color: ready ? Colors.white : sys.label3,
                        size: glass ? 20 : 24,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
