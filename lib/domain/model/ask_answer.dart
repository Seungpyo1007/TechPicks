import 'dart:convert';

/// AI 답변 한 건.
///
/// 명세가 응답 형태를 못박았다. 문단을 그대로 뿌리지 말고 고른 기기 하나,
/// 한 줄 근거, 4줄짜리 표로 나눠 받는다. 마크다운을 렌더링하지 않는다.
class AskAnswer {
  const AskAnswer({
    required this.pick,
    required this.reason,
    required this.rows,
    this.pickSlug,
  });

  /// 고른 기기 이름. 화면 맨 위에 한 줄로 들어간다.
  final String pick;

  /// 왜 그걸 골랐는지 한 문장.
  final String reason;

  /// TP Index / Price / Battery / Camera 네 줄.
  final List<AskRow> rows;

  /// 상세로 넘어갈 slug. 모델이 목록에 없는 이름을 말하면 null 이다.
  final String? pickSlug;

  /// 모델 응답을 파싱한다.
  ///
  /// 모델이 JSON 만 뱉으라고 해도 코드펜스를 두르거나 앞뒤에 말을 붙이는
  /// 일이 흔하다. 첫 `{` 부터 마지막 `}` 까지만 잘라서 읽는다.
  static AskAnswer? tryParse(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;

    final Object? decoded;
    try {
      decoded = jsonDecode(raw.substring(start, end + 1));
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;

    final pick = decoded['pick'];
    final reason = decoded['reason'];
    if (pick is! String || pick.trim().isEmpty) return null;

    final rows = <AskRow>[];
    final rawRows = decoded['rows'];
    if (rawRows is List) {
      for (final r in rawRows) {
        if (r is! Map) continue;
        final label = r['label'];
        final value = r['value'];
        if (label is String && value != null) {
          rows.add(AskRow(label: label, value: value.toString()));
        }
      }
    }

    return AskAnswer(
      pick: pick.trim(),
      reason: reason is String ? reason.trim() : '',
      rows: rows,
      pickSlug: decoded['slug'] is String ? decoded['slug'] as String : null,
    );
  }
}

/// 상담이 돌려주는 답 한 건.
///
/// 두 모양이 있다. 기기를 고른 답([answer])과 **문장뿐인 답**([text])이다.
///
/// 리메이크 뒤에는 앞의 것만 있었다. 카탈로그에서 기기를 못 찾으면 답을
/// 통째로 버렸고 화면은 그걸 실패로 그렸다 — "배터리 수명은 뭘로 정해지나요"
/// 처럼 **고를 기기가 없는 질문**은 전부 실패 말풍선이었다. v1 은 그냥
/// 대답했다.
/// `{"answer":"..."}` 모양의 문장 답을 읽는다.
///
/// 모델에게 두 형태를 줬다 — 기기를 고를 수 있으면 표, 아니면 문장. 어느
/// 쪽이 올지는 질문이 정한다.
String? tryParseSay(String raw) {
  final start = raw.indexOf('{');
  final end = raw.lastIndexOf('}');
  if (start < 0 || end <= start) return null;

  final Object? decoded;
  try {
    decoded = jsonDecode(raw.substring(start, end + 1));
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;

  final say = decoded['answer'];
  if (say is! String || say.trim().isEmpty) return null;
  return say.trim();
}

class AskReply {
  const AskReply.pick(AskAnswer this.answer, {this.fromCatalog = false})
    : text = null;

  const AskReply.say(String this.text, {this.fromCatalog = false})
    : answer = null;

  /// 기기를 고른 답. 화면이 표를 그린다.
  final AskAnswer? answer;

  /// 표 없이 문장만. 화면이 그냥 말풍선으로 그린다.
  final String? text;

  /// 모델을 한 번도 못 부르고 카탈로그만으로 만든 답인가.
  ///
  /// 모델이 죽으면 [FallbackAskService] 가 조용히 로컬 답을 대신 내보낸다.
  /// 답 자체는 쓸 만하지만 모델이 답한 것처럼 보이면 안 된다.
  final bool fromCatalog;
}

class AskRow {
  const AskRow({required this.label, required this.value});

  final String label;
  final String value;
}

/// 화면에 쌓이는 말풍선 하나.
class AskMessage {
  const AskMessage.user(this.text)
    : isUser = true,
      answer = null,
      failed = false,
      fromCatalog = false;

  const AskMessage.ai(
    this.text, {
    this.answer,
    this.failed = false,
    this.fromCatalog = false,
  }) : isUser = false;

  final String text;
  final bool isUser;

  /// 구조화된 답변. null 이면 [text] 만 보여준다.
  final AskAnswer? answer;

  /// 모델 호출이 실패했을 때.
  final bool failed;

  /// 모델 없이 카탈로그만으로 만든 답인가. 말풍선이 그렇다고 밝힌다.
  final bool fromCatalog;
}
