import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_gemma_builtin_ai/flutter_gemma_builtin_ai.dart';

import '../../core/error_reporter.dart';
import '../../domain/model/ask_answer.dart';
import '../../domain/model/tp_index.dart';
import '../../domain/model/tp_weights.dart';
import '../dto/smartphone.dart';
import 'ask_service.dart';

/// 기기 안에서 도는 AI 로 상담한다.
///
/// **모델을 내려받지 않는다.** OS 가 이미 들고 있는 것을 부른다 — iOS 는 Apple
/// Foundation Models, Android 는 ML Kit GenAI 의 Gemini Nano. 그래서 앱 용량이
/// 안 늘고, 질문이 기기 밖으로 안 나간다.
///
/// 쓸 수 있는 자리가 좁다: iPhone 15 Pro 이상 + Apple Intelligence 켜짐,
/// Android 는 Pixel 9 · Galaxy S25 이상. **시뮬레이터에서는 안 돈다.** 못 쓰면
/// 조용히 null 을 돌려주고 [FallbackAskService] 가 다음 구현으로 넘긴다.
class OnDeviceAskService implements AskService {
  OnDeviceAskService({this.weights = TpWeights.defaults, TpBuiltInAi? runtime})
    : _runtime = runtime ?? TpBuiltInAi.shared;

  final TpWeights weights;
  final TpBuiltInAi _runtime;

  /// 기기 안 모델을 기다리는 한도.
  ///
  /// 클라우드보다 느리다. 그래도 무한정 세워 둘 수는 없어서, 지나면 다음
  /// 구현이 받는다.
  static const Duration timeout = Duration(seconds: 30);

  /// 프롬프트에 넣는 기기 수.
  ///
  /// 기기 안 모델의 컨텍스트는 클라우드보다 훨씬 좁다. 카탈로그 200종을 그대로
  /// 넣으면 질문이 들어갈 자리가 없다. 지수 상위만 넣고, 열도 넷으로 줄인다.
  static const int catalogLimit = 40;

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) async {
    final chat = await _runtime.chat();
    if (chat == null) return null;

    try {
      await chat.addQueryChunk(
        Message.text(
          text: buildPrompt(question, catalog, weights),
          isUser: true,
        ),
      );
      final res = await chat.generateChatResponse().timeout(timeout);
      if (res is! TextResponse) return null;
      return replyFrom(res.token, catalog, weights: weights);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'ask.onDevice');
      return null;
    }
  }

  /// 모델이 뱉은 글자를 답으로 바꾼다. [GeminiAskService] 와 규칙이 같다.
  @visibleForTesting
  static AskReply? replyFrom(
    String raw,
    List<Smartphone> catalog, {
    TpWeights weights = TpWeights.defaults,
  }) {
    final parsed = AskAnswer.tryParse(raw);
    if (parsed != null) {
      // 이 프롬프트는 rows 를 아예 안 시킨다 — 작은 모델은 규칙이 길어지면
      // 형태를 놓친다. 표는 resolveInCatalog 가 카탈로그에서 만들어 붙인다.
      final resolved = GeminiAskService.resolveInCatalog(
        parsed,
        catalog,
        weights: weights,
      );
      if (resolved != null) return AskReply.pick(resolved);
      if (parsed.reason.isNotEmpty) return AskReply.say(parsed.reason);
      return null;
    }
    final say = tryParseSay(raw);
    return say == null ? null : AskReply.say(say);
  }

  /// 기기 안 모델용 프롬프트.
  ///
  /// 클라우드용보다 짧다. 규칙을 길게 적을수록 작은 모델이 형태를 놓친다.
  @visibleForTesting
  static String buildPrompt(
    String question,
    List<Smartphone> catalog,
    TpWeights weights,
  ) {
    final ranked = catalog.toList()
      ..sort(
        (a, b) => (TpIndex.of(b.score, weights) ?? -1).compareTo(
          TpIndex.of(a.score, weights) ?? -1,
        ),
      );

    final lines = ranked
        .take(catalogLimit)
        .map(
          (d) =>
              '${d.slug} | ${d.name} | '
              'TP ${TpIndex.of(d.score, weights) ?? '-'} | '
              '\$${d.msrpUsd ?? '-'}',
        )
        .join('\n');

    return '''
Answer the question about phones. JSON only, no markdown.
Use the language of the question.

The TP index below is this app's own 0-100 score. It only ranks these phones
against each other — never explain anything with it, and never cite it as a
fact about how phones work.

If one of the phones below answers it:
{"pick":"<name>","slug":"<slug>","reason":"<one sentence>"}

Otherwise answer in two sentences:
{"answer":"<two sentences>"}

Phones (slug | name | TP index | price):
$lines

Question: $question
''';
  }
}

/// OS 가 들고 있는 모델을 부를 준비를 한다.
///
/// 준비는 세 걸음이다 — 엔진 등록, 모델 등록(내려받는 파일은 없고 이름만
/// 기록한다), OS 기능이 켜져 있는지 확인. 셋 다 한 번만 하고 결과를 들고 있는다.
///
/// **어느 걸음에서 실패해도 던지지 않는다.** 상담은 이게 없어도 돌아가야 한다.
class TpBuiltInAi {
  TpBuiltInAi();

  static final TpBuiltInAi shared = TpBuiltInAi();

  Future<BuiltInAiAvailability>? _probe;
  Future<InferenceModel?>? _model;
  bool _registered = false;

  /// 이 기기에서 쓸 수 있는지. 결과는 한 번만 묻고 들고 있는다.
  Future<BuiltInAiAvailability> availability() =>
      _probe ??= _checkAvailability();

  Future<BuiltInAiAvailability> _checkAvailability() async {
    // 테스트에는 OS 모델도 플랫폼 채널도 없다. 물어보면 답이 영영 안 와서
    // 20초짜리 타이머만 남는다 — 위젯 테스트는 그걸 실패로 잡는다.
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return BuiltInAiAvailability.unavailableOther;
    }
    try {
      _register();
      return await BuiltInAi.availability();
    } catch (e, s) {
      // 플러그인이 아예 없는 환경(테스트·웹)은 조회 자체가 던진다.
      TpErrors.record(e, s, reason: 'onDeviceAi.availability');
      return BuiltInAiAvailability.unavailableOther;
    }
  }

  /// 준비된 대화. 못 쓰면 null.
  Future<InferenceChat?> chat() async {
    final model = await (_model ??= _open());
    if (model == null) return null;
    try {
      return await model.createChat();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'onDeviceAi.chat');
      return null;
    }
  }

  Future<InferenceModel?> _open() async {
    if (await availability() != BuiltInAiAvailability.available) return null;
    try {
      final spec = defaultTargetPlatform == TargetPlatform.android
          ? BuiltInAiModels.geminiNano
          : BuiltInAiModels.appleFoundationModels;
      await FlutterGemma.installModel(
        modelType: ModelType.general,
        fileType: ModelFileType.builtIn,
      ).fromBundled(spec.name).install();
      return await FlutterGemma.getActiveModel(maxTokens: 4096);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'onDeviceAi.open');
      return null;
    }
  }

  void _register() {
    if (_registered) return;
    _registered = true;
    // 엔진은 전부 opt-in 이다. 이걸 안 부르면 첫 호출에서 "엔진 패키지를
    // 넣으라"고 던진다.
    unawaited(
      FlutterGemma.initialize(inferenceEngines: const [BuiltInAiEngine()]),
    );
  }
}
