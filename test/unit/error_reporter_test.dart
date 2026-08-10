import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/core/error_reporter.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/data/service/auth_service.dart';

import '../support/harness.dart';

/// 삼킨 실패가 기록되는지.
///
/// 이 앱은 예외를 일부러 삼킨다. 삼키는 동작은 그대로 두되, 무엇이 얼마나
/// 실패하는지는 남아야 한다. 남지 않으면 프로덕션에서 아무것도 안 보인다.
class _Recording implements ErrorSink {
  final List<({Object error, String? reason})> entries = [];

  @override
  void record(Object error, StackTrace? stack, {String? reason}) {
    entries.add((error: error, reason: reason));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Recording sink;
  late ErrorSink previous;

  setUp(() {
    sink = _Recording();
    previous = TpErrors.use(sink);
  });

  tearDown(() => TpErrors.use(previous));

  test('기본값은 아무 데도 안 보낸다', () {
    TpErrors.use(previous);
    // 기록기를 안 끼운 상태에서 불러도 터지지 않는다.
    TpErrors.record(Exception('아무거나'), StackTrace.current);
  });

  test('카탈로그를 못 읽으면 남는다', () async {
    final repo = CatalogRepository(
      bundle: FileBundle(),
      assetPath: missingCatalogAsset,
    );
    final result = await repo.load();

    // 삼키는 동작은 그대로다.
    expect(result.isErr, isTrue);
    // 그리고 기록이 남았다.
    expect(sink.entries.map((e) => e.reason), contains('catalog.load'));
  });

  test('Firebase 없는 빌드의 인증 실패가 남는다', () async {
    final service = FirebaseAuthService();

    service.current;
    await service.signIn(AuthMethod.anonymous);
    await service.signUp(email: 'a@b.com', password: '123456');

    final reasons = sink.entries.map((e) => e.reason).toSet();
    // 어느 경로든 조용히 null 로 떨어지지만 이유는 남는다.
    expect(reasons.any((r) => r != null && r.startsWith('auth.')), isTrue);
  });

  test('이유가 어디서 삼켰는지 알려준다', () {
    TpErrors.record(Exception('x'), StackTrace.current, reason: 'ask.gemini');
    expect(sink.entries.single.reason, 'ask.gemini');
  });

  test('조용한 기록기는 아무것도 안 모은다', () {
    const silent = SilentErrorSink();
    silent.record(Exception('x'), null, reason: 'y');
    // 예외 없이 지나가면 된다.
  });
}
