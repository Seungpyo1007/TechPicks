import 'dart:convert';
import 'dart:io';

/// 픽스처는 실제 TechAPI 정적 덤프에서 그대로 내려받은 응답이다.
/// 손으로 만든 가짜가 아니므로 스키마가 바뀌면 테스트가 깨지고, 그게 의도다.
///
/// 갱신: `dart run tool/refresh_fixtures.dart`
Map<String, dynamic> loadFixture(String name) {
  final file = File('test/fixtures/$name.json');
  if (!file.existsSync()) {
    throw StateError('픽스처가 없다: ${file.path}');
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}
