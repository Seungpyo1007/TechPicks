import 'dart:convert';

import 'package:firebase_vertexai/firebase_vertexai.dart';

import '../../domain/model/ask_answer.dart';
import '../dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../domain/model/tp_weights.dart';

/// AI 상담.
///
/// 화면은 이 인터페이스만 본다. 테스트가 모델을 부르지 않아도 되게 하려는
/// 것이고, 나중에 모델을 갈아끼울 때 화면을 건드리지 않으려는 것이다.
abstract class AskService {
  Future<AskAnswer?> ask(String question, List<Smartphone> catalog);
}

/// Firebase Vertex AI 를 쓰는 구현.
class GeminiAskService implements AskService {
  GeminiAskService({GenerativeModel? model, this.weights = TpWeights.defaults})
      : _model = model;

  /// v1 은 'gemini-flash-experimental' 을 넣었는데 그런 모델 ID 는 없다.
  static const String modelId = 'gemini-2.0-flash';

  final TpWeights weights;
  GenerativeModel? _model;

  GenerativeModel get _resolved =>
      _model ??= FirebaseVertexAI.instance.generativeModel(
        model: modelId,
        generationConfig: GenerationConfig(responseMimeType: 'application/json'),
      );

  @override
  Future<AskAnswer?> ask(String question, List<Smartphone> catalog) async {
    final prompt = buildPrompt(question, catalog, weights);
    try {
      final res = await _resolved.generateContent(<Content>[Content.text(prompt)]);
      final text = res.text;
      if (text == null) return null;
      final parsed = AskAnswer.tryParse(text);
      if (parsed == null) return null;
      return resolveInCatalog(parsed, catalog);
    } catch (_) {
      // 화면이 실패 말풍선을 띄운다. 원문 예외를 사용자에게 보이지 않는다.
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
You help someone choose a phone. Pick exactly one device from the catalogue below.

Rules:
- Answer with JSON only. No prose, no markdown, no code fences.
- The device you pick MUST be one of the catalogue entries. Use its slug.
- "reason" is one sentence, under 140 characters.
- "rows" has exactly these four labels in this order:
  TP Index, Price, Battery, Camera.

Shape:
{"pick":"<name>","slug":"<slug>","reason":"<one sentence>",
 "rows":[{"label":"TP Index","value":"..."},{"label":"Price","value":"..."},
         {"label":"Battery","value":"..."},{"label":"Camera","value":"..."}]}

Catalogue:
${jsonEncode(rows)}

Question: $question
''';
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
  Future<AskAnswer?> ask(String question, List<Smartphone> catalog) async {
    if (catalog.isEmpty) return null;

    final budget = _budget(question);
    var pool = catalog;
    if (budget != null) {
      final affordable =
          catalog.where((d) => (d.msrpUsd ?? 1 << 30) <= budget).toList();
      if (affordable.isNotEmpty) pool = affordable;
    }

    final sorted = pool.toList()
      ..sort((a, b) => (TpIndex.of(b.score, weights) ?? -1)
          .compareTo(TpIndex.of(a.score, weights) ?? -1));
    final best = sorted.first;

    return AskAnswer(
      pick: best.name,
      pickSlug: best.slug,
      reason: budget == null
          ? 'Highest index in the catalogue on your current weights.'
          : 'Best index under \$$budget on your current weights.',
      rows: <AskRow>[
        AskRow(
          label: 'TP Index',
          value: TpIndex.of(best.score, weights)?.toString() ??
              DeviceSpecs.empty,
        ),
        AskRow(label: 'Price', value: DeviceSpecs.formatPrice(best.msrpUsd)),
        AskRow(
          label: 'Battery',
          value: best.batteryMah == null
              ? DeviceSpecs.empty
              : '${best.batteryMah}mAh',
        ),
        AskRow(
          label: 'Camera',
          value: best.score?.camera?.round().toString() ?? DeviceSpecs.empty,
        ),
      ],
    );
  }

  /// `$900`, `900 dollars`, `900불` 같은 표현에서 숫자만 뽑는다.
  static int? _budget(String question) {
    final match = RegExp(r'(\d[\d,]{2,})').firstMatch(question);
    if (match == null) return null;
    return int.tryParse(match.group(1)!.replaceAll(',', ''));
  }
}
