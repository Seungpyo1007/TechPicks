// 이미 구운 애셋에 이름 규칙만 다시 먹인다.
//
// `build_catalog.dart` 를 통째로 다시 돌리면 TechAPI 를 수백 번 다시 받는다.
// 이름만 손보면 되는 날에는 이걸 돌린다.
import 'dart:convert';
import 'dart:io';

import 'build_catalog.dart' show canonicalName;

void main() {
  var changed = 0;
  changed += _catalog();
  changed += _laptops();
  stdout.writeln('$changed 개 고침');
}

/// 스마트폰 카탈로그 — 브랜드 표기만.
int _catalog() {
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

  _write(file, json);
  return changed;
}

/// 노트북 — 이어붙이기 사고를 되돌린다.
///
/// 상류가 브랜드·계열·변형을 그냥 이어붙여서 이런 값들이 온다:
///
///     Apple M4 M4 Max
///     Apple Apple GPU Apple 32-Core GPU
///     NVIDIA GeForce RTX RTX 5090
///     Intel Arc Arc Graphics
///
/// 런타임에 고치지 않고 여기서 굽는다. 화면마다 고치면 한 화면만 빠뜨렸을 때
/// 같은 기기가 두 이름으로 보인다.
int _laptops() {
  final file = File('assets/laptops/v1.json');
  if (!file.existsSync()) return 0;
  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  var changed = 0;

  for (final laptop in json['laptops'] as List<dynamic>) {
    final map = laptop as Map<String, dynamic>;
    for (final key in const <String>['cpu_name', 'gpu_name']) {
      final was = map[key] as String?;
      if (was == null) continue;
      final now = undupe(was);
      if (now == was) continue;
      map[key] = now;
      changed++;
      stdout.writeln('$was → $now');
    }

    // 이름 뒤 괄호는 사양을 통째로 이어붙인 것이다 — 램·저장·GPU·OS 가
    // 이미 제 필드에 있고, 거기 든 `M4 MaxMax` 는 위와 같은 사고다.
    final was = map['name'] as String?;
    if (was == null) continue;
    final now = was.replaceAll(RegExp(r'\s*\(.*\)\s*$'), '').trim();
    if (now == was || now.isEmpty) continue;
    map['name'] = now;
    changed++;
    stdout.writeln('$was → $now');
  }

  _write(file, json);
  return changed;
}

/// 이어붙이기로 생긴 중복 낱말을 접는다.
///
/// 규칙 둘로 끝난다.
///
/// 1. 첫 낱말이 뒤에서 다시 나오면 **거기서부터** 쓴다. 브랜드를 앞에 또
///    붙이며 이어붙인 경우다 — `Apple Apple GPU Apple 32-Core GPU` 에서
///    마지막 `Apple` 부터가 그 자체로 온전한 이름이다.
/// 2. 붙어 있는 같은 낱말은 하나로 접는다 — `RTX RTX 5090`, `M4 M4 Max`.
///
/// 떨어져 있는 중복은 **안 건드린다**. `Intel Core Ultra 9 275HX` 처럼
/// 멀쩡한 이름을 망가뜨리지 않기 위한 것이다.
String undupe(String name) {
  final words = name.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
  if (words.isEmpty) return name;

  final first = words.first;
  var start = 0;
  for (var i = words.length - 1; i > 0; i--) {
    if (words[i] == first) {
      start = i;
      break;
    }
  }

  final out = <String>[words[start]];
  for (final word in words.skip(start + 1)) {
    if (word != out.last) out.add(word);
  }
  return out.join(' ');
}

/// 굽는 도구와 같은 모양으로 쓴다. 안 그러면 다음 재생성이 파일 전체를 다시
/// 쓴 것처럼 보인다.
void _write(File file, Map<String, dynamic> json) {
  file.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(json)}\n',
  );
}
