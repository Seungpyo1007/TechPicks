import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/data/service/shortlist_sync_service.dart';

/// 로그인을 테스트가 정한다.
class _StubAuth implements AuthService {
  TpUser? _current;

  @override
  TpUser? get current => _current;

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async => _current = TpUser(
    uid: method == AuthMethod.anonymous ? 'anon' : 'u1',
    isAnonymous: method == AuthMethod.anonymous,
  );

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<bool> sendPasswordReset(String email) async => false;

  @override
  Future<TpUser?> updateName(String name) async => null;

  @override
  Future<void> signOut() async => _current = null;
}

class _FakeSync implements ShortlistSyncService {
  _FakeSync([this.stored]);

  RemoteShortlist? stored;
  final List<List<String>> writes = <List<String>>[];

  @override
  Future<RemoteShortlist?> read(String uid) async => stored;

  @override
  Future<void> write(String uid, List<String> slugs, DateTime updatedAt) async {
    writes.add(slugs);
    stored = RemoteShortlist(slugs: slugs, updatedAt: updatedAt);
  }
}

/// Firestore 가 없거나 규칙에 막힌 경우.
class _BrokenSync implements ShortlistSyncService {
  @override
  Future<RemoteShortlist?> read(String uid) async =>
      throw StateError('Firestore 없음');

  @override
  Future<void> write(
    String uid,
    List<String> slugs,
    DateTime updatedAt,
  ) async => throw StateError('Firestore 없음');
}

ProviderContainer _container({
  required AuthService auth,
  required ShortlistSyncService sync,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      authServiceProvider.overrideWithValue(auth),
      shortlistSyncServiceProvider.overrideWithValue(sync),
    ],
  );
  addTearDown(container.dispose);
  // 앱에서는 TechPicksRoot 가 이 구독을 연다.
  container.listen(shortlistSyncProvider, (_, _) {});
  return container;
}

/// 비동기 병합이 끝날 때까지 돌린다.
Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

final DateTime _old = DateTime(2026, 1, 1);
final DateTime _new = DateTime(2026, 8, 1);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('올라간 게 없으면 로컬을 올린다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25'],
      'shortlist_updated_at': _new.millisecondsSinceEpoch,
    });
    final sync = _FakeSync();
    final container = _container(auth: _StubAuth(), sync: sync);
    await _settle();

    await container.read(currentUserProvider.notifier).signIn(AuthMethod.email);
    await _settle();

    expect(sync.writes, <List<String>>[
      <String>['galaxy-s25'],
    ]);
  });

  test('올라간 것이 더 새로우면 그걸 받는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25'],
      'shortlist_updated_at': _old.millisecondsSinceEpoch,
    });
    final sync = _FakeSync(
      RemoteShortlist(slugs: <String>['oneplus-13'], updatedAt: _new),
    );
    final container = _container(auth: _StubAuth(), sync: sync);
    await _settle();

    await container.read(currentUserProvider.notifier).signIn(AuthMethod.email);
    await _settle();

    expect(container.read(shortlistProvider), <String>['oneplus-13']);
    expect(sync.writes, isEmpty);
  });

  test('로컬이 더 새로우면 지운 것이 되살아나지 않는다', () async {
    // 여기서 galaxy-s25 를 지웠고, 그게 아직 안 올라갔다.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['oneplus-13'],
      'shortlist_updated_at': _new.millisecondsSinceEpoch,
    });
    final sync = _FakeSync(
      RemoteShortlist(
        slugs: <String>['galaxy-s25', 'oneplus-13'],
        updatedAt: _old,
      ),
    );
    final container = _container(auth: _StubAuth(), sync: sync);
    await _settle();

    await container.read(currentUserProvider.notifier).signIn(AuthMethod.email);
    await _settle();

    expect(container.read(shortlistProvider), <String>['oneplus-13']);
    expect(sync.stored!.slugs, <String>['oneplus-13']);
  });

  test('로그인한 뒤 목록을 바꾸면 올라간다', () async {
    final sync = _FakeSync();
    final container = _container(auth: _StubAuth(), sync: sync);
    await _settle();

    await container.read(currentUserProvider.notifier).signIn(AuthMethod.email);
    await _settle();
    sync.writes.clear();

    container.read(shortlistProvider.notifier).toggle('pixel-9-pro');
    await _settle();

    expect(sync.writes, <List<String>>[
      <String>['pixel-9-pro'],
    ]);
  });

  test('익명 로그인은 계정에 안 올린다', () async {
    // 익명 uid 는 설치마다 달라 올려도 다시 못 찾는다.
    final sync = _FakeSync();
    final container = _container(auth: _StubAuth(), sync: sync);
    await _settle();

    await container
        .read(currentUserProvider.notifier)
        .signIn(AuthMethod.anonymous);
    await _settle();
    container.read(shortlistProvider.notifier).toggle('pixel-9-pro');
    await _settle();

    expect(sync.writes, isEmpty);
  });

  test('로그인하지 않으면 아무 일도 없다', () async {
    final sync = _FakeSync();
    final container = _container(auth: _StubAuth(), sync: sync);
    await _settle();

    container.read(shortlistProvider.notifier).toggle('galaxy-s25');
    await _settle();

    expect(sync.writes, isEmpty);
    expect(container.read(shortlistProvider), <String>['galaxy-s25']);
  });

  test('로그아웃해도 로컬은 남는다', () async {
    final sync = _FakeSync();
    final container = _container(auth: _StubAuth(), sync: sync);
    await _settle();

    await container.read(currentUserProvider.notifier).signIn(AuthMethod.email);
    await _settle();
    container.read(shortlistProvider.notifier).toggle('galaxy-s25');
    await _settle();

    await container.read(currentUserProvider.notifier).signOut();
    await _settle();

    expect(container.read(shortlistProvider), <String>['galaxy-s25']);
  });

  test('Firestore 가 죽어도 로컬은 돈다', () async {
    final container = _container(auth: _StubAuth(), sync: _BrokenSync());
    await _settle();

    await container.read(currentUserProvider.notifier).signIn(AuthMethod.email);
    await _settle();
    container.read(shortlistProvider.notifier).toggle('galaxy-s25');
    await _settle();

    expect(container.read(shortlistProvider), <String>['galaxy-s25']);
  });
}
