import 'dart:async';
import 'dart:convert';

import '../../core/error_reporter.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_ai/firebase_ai.dart';

import '../../domain/model/ask_answer.dart';
import '../dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../domain/model/tp_weights.dart';
import '../../shared/copy_keys.dart';

/// AI 상담.
///
/// 화면은 이 인터페이스만 본다. 테스트가 모델을 부르지 않아도 되게 하려는
/// 것이고, 나중에 모델을 갈아끼울 때 화면을 건드리지 않으려는 것이다.
abstract class AskService {
  /// 답 한 건. null 이면 못 답한 것이고, 화면이 실패 말풍선을 띄운다.
  Future<AskReply?> ask(String question, List<Smartphone> catalog);
}

/// Firebase AI Logic 을 쓰는 구현.
class GeminiAskService implements AskService {
  GeminiAskService({GenerativeModel? model, this.weights = TpWeights.defaults})
    : _model = model;

  /// v1 은 'gemini-flash-experimental' 을 넣었는데 그런 모델 ID 는 없다.
  ///
  /// 2.x 계열은 2026-10 에 내려간다. 현행 권장은 3.6-flash 다.
  static const String modelId = 'gemini-3.6-flash';

  final TpWeights weights;
  GenerativeModel? _model;

  GenerativeModel get _resolved =>
      _model ??= FirebaseAI.googleAI().generativeModel(
        model: modelId,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );

  /// 모델을 기다리는 한도.
  ///
  /// 안 돌아오는 호출 뒤에는 로컬 답이 기다린다. 사람을 무한정 세워 두느니
  /// 몇 초 뒤에 카탈로그로 답하는 편이 낫다.
  static const Duration timeout = Duration(seconds: 12);

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) async {
    final prompt = buildPrompt(question, catalog, weights);
    try {
      final res = await _resolved
          .generateContent(<Content>[Content.text(prompt)])
          .timeout(timeout);
      final text = res.text;
      if (text == null) return null;

      final parsed = AskAnswer.tryParse(text);
      if (parsed != null) {
        final resolved = resolveInCatalog(parsed, catalog);
        // 목록 밖 기기를 골랐다. 표는 못 그리지만 이유는 말이 된다 —
        // 여기서 버리면 사람은 아무것도 못 듣는다.
        if (resolved != null) return AskReply.pick(resolved);
        if (parsed.reason.isNotEmpty) return AskReply.say(parsed.reason);
        return null;
      }

      // 고를 기기가 없는 질문. 문장으로 답한다.
      final say = tryParseSay(text);
      return say == null ? null : AskReply.say(say);
    } catch (e, s) {
      // 화면이 실패 말풍선을 띄운다. 원문 예외를 사용자에게 보이지 않는다.
      TpErrors.record(e, s, reason: 'ask.gemini');
      return null;
    }
  }

  /// 고른 기기를 카탈로그에서 찾는다. 없으면 답을 버린다.
  ///
  /// 프롬프트가 "목록 안에서만 고르라"고 하지만 모델은 지킬 때도 있고 아닐
  /// 때도 있다. 지키지 않은 답을 그대로 띄우면 slug 가 상세 화면에서
  /// 404 로 떨어지고, 사용자는 앱이 아는 기기인 줄 알고 눌렀다가 실패를 본다.
  ///
  /// slug 가 맞으면 그걸 쓰고, 없거나 틀렸으면 이름으로 한 번 더 찾는다.
  /// 둘 다 실패하면 null 이라 화면이 실패 말풍선을 띄운다.
  static AskAnswer? resolveInCatalog(
    AskAnswer answer,
    List<Smartphone> catalog,
  ) {
    Smartphone? bySlug;
    for (final d in catalog) {
      if (d.slug == answer.pickSlug) {
        bySlug = d;
        break;
      }
    }

    final picked = bySlug ?? _byName(answer.pick, catalog);
    if (picked == null) return null;

    return AskAnswer(
      // 표시 이름은 카탈로그 쪽을 쓴다. 상세 화면 제목과 어긋나면 안 된다.
      pick: picked.name,
      reason: answer.reason,
      rows: answer.rows,
      pickSlug: picked.slug,
    );
  }

  static Smartphone? _byName(String name, List<Smartphone> catalog) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final d in catalog) {
      if (d.name.trim().toLowerCase() == needle) return d;
    }
    return null;
  }

  /// 카탈로그를 컨텍스트로 넣고 응답 형태를 못박는다.
  ///
  /// v1 의 ChatAI 는 질문만 던지고 답을 그대로 뿌렸다. 그러면 UI 가 표를
  /// 그릴 수 없고, 모델이 카탈로그에 없는 기기를 추천해도 막을 방법이 없다.
  ///
  /// 그렇다고 **모든** 질문에 기기를 하나 고르라고 하면, "배터리 수명은 뭘로
  /// 정해지나" 같은 질문에도 폰 하나를 억지로 끼워 답한다. 형태를 둘 주고
  /// 질문이 고르게 한다.
  static String buildPrompt(
    String question,
    List<Smartphone> catalog,
    TpWeights weights,
  ) {
    final rows = catalog.map((d) {
      return <String, Object?>{
        'slug': d.slug,
        'name': d.name,
        'brand': d.brand?.name,
        'usd': d.msrpUsd,
        'tp_index': TpIndex.of(d.score, weights),
        'battery_mah': d.batteryMah,
        'camera': d.score?.camera?.round(),
        'soc': d.soc?.name,
      };
    }).toList();

    return '''
You help someone decide about phones. Answer their question.

Answer with JSON only. No prose, no markdown, no code fences.
Answer in the same language the question is written in.

If the question asks which device to get, or can be settled by naming one,
use shape A. The device you pick MUST be one of the catalogue entries below;
use its slug.

Shape A:
{"pick":"<name>","slug":"<slug>","reason":"<one sentence, under 140 chars>",
 "rows":[{"label":"TP Index","value":"..."},{"label":"Price","value":"..."},
         {"label":"Battery","value":"..."},{"label":"Camera","value":"..."}]}

If the question is not about picking a device — how something works, what a
spec means, whether an idea is sound — answer it plainly in shape B, in two or
three sentences. Do not force a device into the answer.

Shape B:
{"answer":"<two or three sentences>"}

Catalogue:
${jsonEncode(rows)}

Question: $question
''';
  }
}

/// 모델을 먼저 부르고, 못 부르면 다른 구현에 넘긴다.
///
/// Gemini 는 설정이 없거나 네트워크가 없거나 응답 형태가 깨지면 null 을
/// 돌려준다. 그때 화면에 실패 말풍선만 띄우면 상담 탭이 통째로 쓸모없어진다 —
/// 카탈로그만으로도 답할 수 있는 질문이 대부분이다.
class FallbackAskService implements AskService {
  const FallbackAskService(this.primary, this.fallback);

  final AskService primary;
  final AskService fallback;

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) async {
    final answer = await primary.ask(question, catalog);
    if (answer != null) return answer;
    return fallback.ask(question, catalog);
  }
}

/// 모델을 부르지 않고 카탈로그만으로 답하는 구현.
///
/// 오프라인이거나 Firebase 설정이 없을 때 화면이 죽지 않게 한다. 예산과
/// 관심 축을 질문에서 대충 뽑아 지수가 가장 높은 기기를 고른다.
class LocalAskService implements AskService {
  const LocalAskService({this.weights = TpWeights.defaults});

  final TpWeights weights;

  @override
  Future<AskReply?> ask(String question, List<Smartphone> catalog) async {
    if (catalog.isEmpty) return null;

    final budget = budgetUsd(question);
    var pool = catalog;
    if (budget != null) {
      final affordable = catalog
          .where((d) => (d.msrpUsd ?? 1 << 30) <= budget)
          .toList();
      if (affordable.isNotEmpty) pool = affordable;
    }

    final sorted = pool.toList()
      ..sort(
        (a, b) => (TpIndex.of(b.score, weights) ?? -1).compareTo(
          TpIndex.of(a.score, weights) ?? -1,
        ),
      );
    final best = sorted.first;

    return AskReply.pick(
      AskAnswer(
        pick: best.name,
        pickSlug: best.slug,
        reason: budget == null
            ? K.askLocalTop.tr()
            : K.askLocalBudget.tr(
                args: <String>[DeviceSpecs.formatPrice(budget)],
              ),
        // 표 라벨은 비교·상세와 같은 걸 쓴다. 여기만 영어로 남으면 한국어에서
        // 한 화면 안에 두 언어가 섞인다.
        rows: <AskRow>[
          AskRow(
            label: K.tpIndex.tr(),
            value:
                TpIndex.of(best.score, weights)?.toString() ??
                DeviceSpecs.empty,
          ),
          AskRow(
            label: K.spec(SpecKind.price).tr(),
            value: DeviceSpecs.formatPrice(best.msrpUsd),
          ),
          AskRow(
            label: K.spec(SpecKind.battery).tr(),
            value: best.batteryMah == null
                ? DeviceSpecs.empty
                : '${best.batteryMah}mAh',
          ),
          AskRow(
            label: K.spec(SpecKind.camera).tr(),
            value: best.score?.camera?.round().toString() ?? DeviceSpecs.empty,
          ),
        ],
      ),
    );
  }

  /// 카탈로그 가격이 달러뿐이라 원화는 어림해서 바꾼다.
  ///
  /// P4 에서 원화 가격이 들어오면 이 상수도 이 변환도 없어진다.
  static const int krwPerUsd = 1400;

  /// 질문에서 예산을 달러로 뽑는다.
  ///
  /// `$900`, `900 dollars`, `900불` 은 그대로 달러다. 한국어로는 대부분
  /// **만원**으로 쓴다 — "100만원 이하"를 100달러로 읽어 9만원짜리 폰을
  /// 추천하던 버그가 있었다.
  static int? budgetUsd(String question) {
    // "100만원", "100만 원", "100만"
    final man = RegExp(r'(\d[\d,]*)\s*만\s*원?').firstMatch(question);
    if (man != null) {
      final n = int.tryParse(man.group(1)!.replaceAll(',', ''));
      if (n != null && n > 0) return (n * 10000 / krwPerUsd).round();
    }

    // "1,200,000원"
    final won = RegExp(r'(\d[\d,]{2,})\s*원').firstMatch(question);
    if (won != null) {
      final n = int.tryParse(won.group(1)!.replaceAll(',', ''));
      if (n != null && n > 0) return (n / krwPerUsd).round();
    }

    // 통화 표시가 있을 때만 달러로 읽는다. 아무 세 자리 숫자나 받던 때는
    // "아이폰 17 Pro 256GB 어때?" 가 예산 $256 이 돼서 싸구려를 추천했다.
    final usd = RegExp(
      r'(?:\$|usd\s*)(\d[\d,]*)|(\d[\d,]*)\s*(?:달러|불|dollars?|usd)',
      caseSensitive: false,
    ).firstMatch(question);
    if (usd == null) return null;
    final digits = usd.group(1) ?? usd.group(2)!;
    return int.tryParse(digits.replaceAll(',', ''));
  }
}
