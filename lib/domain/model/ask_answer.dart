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
      failed = false;

  const AskMessage.ai(this.text, {this.answer, this.failed = false})
    : isUser = false;

  final String text;
  final bool isUser;

  /// 구조화된 답변. null 이면 [text] 만 보여준다.
  final AskAnswer? answer;

  /// 모델 호출이 실패했을 때.
  final bool failed;
}
