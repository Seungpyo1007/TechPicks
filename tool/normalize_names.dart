// 이미 구운 카탈로그에 브랜드 표기 규칙만 다시 먹인다.
//
// `build_catalog.dart` 를 통째로 다시 돌리면 TechAPI 를 수백 번 다시 받는다.
// 이름만 손보면 되는 날에는 이걸 돌린다.
import 'dart:convert';
import 'dart:io';

import 'build_catalog.dart' show canonicalName;

void main() {
  final file = File('assets/catalog/v1.json');
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  var changed = 0;

  for (final phone in json['smartphones'] as List<dynamic>) {
    final map = phone as Map<String, dynamic>;
    final was = map['name'] as String;
    final now = canonicalName(was);
    if (now == was) continue;
    map['name'] = now;
    changed++;
    stdout.writeln('$was → $now');
  }

  // build_catalog 와 같은 모양으로 쓴다. 안 그러면 다음 재생성이 파일
  // 전체를 다시 쓴 것처럼 보인다.
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
  stdout.writeln('$changed 개 고침');
}
