import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/account_sync_service.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

import '../support/fake_auth.dart';

/// 계정 쪽. 쓴 것을 기록하고, 다른 기기의 변경을 [push] 로 흘린다.
class _FakeSync implements AccountSyncService {
  _FakeSync({this.shortlist, this.weights, this.recents});

  List<String>? shortlist;
  TpWeights? weights;
  List<String>? recents;

  final List<String> writes = <String>[];
  final List<String> deleted = <String>[];
  final StreamController<AccountState> _remote =
      StreamController<AccountState>.broadcast();

  void push(AccountState state) => _remote.add(state);

  @override
  Future<AccountState> read(String uid) async =>
      AccountState(shortlist: shortlist, weights: weights, recents: recents);

  @override
  Stream<AccountState> watch(String uid) => _remote.stream;

  @override
  Future<void> writeShortlist(String uid, List<String> slugs) async {
    writes.add('shortlist:${slugs.join(',')}');
    shortlist = slugs;
  }

  @override
  Future<void> writeWeights(String uid, TpWeights next) async {
    writes.add('weights:${next.performance}');
    weights = next;
  }

  @override
  Future<void> writeRecents(String uid, List<String> keys) async {
    writes.add('recents:${keys.join(',')}');
    recents = keys;
  }

  @override
  Future<void> delete(String uid) async => deleted.add(uid);
}

/// Firestore 가 없거나 규칙에 막힌 경우.
class _BrokenSync extends _FakeSync {
  @override
  Future<AccountState> read(String uid) async =>
      throw StateError('Firestore 없음');
}

ProviderContainer _container({
  required FakeAuthService auth,
  required AccountSyncService sync,
}) {
  final container = ProviderContainer(
    overrides: <Override>[
      authServiceProvider.overrideWithValue(auth),
      accountSyncServiceProvider.overrideWithValue(sync),
    ],
  );
  addTearDown(container.dispose);
  // 앱에서는 TechPicksRoot 가 이 구독을 연다.
  container.listen(accountSyncProvider, (_, _) {});
  return container;
}

/// 비동기 병합이 끝날 때까지 돌린다.
Future<void> _settle() async {
  for (var i = 0; i < 12; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Future<ProviderContainer> _signedIn(_FakeSync sync) async {
  final container = _container(auth: FakeAuthService(), sync: sync);
  await _settle();
  await container.read(currentUserProvider.notifier).signIn(AuthMethod.email);
  await _settle();
  return container;
}

const TpWeights _camera = TpWeights(
  performance: 1,
  camera: 5,
  display: 1,
  battery: 1,
  value: 1,
);

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('로그인 순간 합치기', () {
    test('계정이 비었으면 이 기기 것을 올린다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'shortlist_slugs': <String>['galaxy-s25'],
        'recent_hits': <String>['phone:pixel-9'],
      });
      final sync = _FakeSync();
      await _signedIn(sync);

      expect(sync.shortlist, <String>['galaxy-s25']);
      expect(sync.weights, TpWeights.defaults);
      expect(sync.recents, <String>['phone:pixel-9']);
    });

    test('관심 목록은 합집합, 계정 순서 먼저', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'shortlist_slugs': <String>['oneplus-13', 'pixel-9-pro'],
      });
      final sync = _FakeSync(shortlist: <String>['galaxy-s25', 'oneplus-13']);
      final container = await _signedIn(sync);

      const merged = <String>['galaxy-s25', 'oneplus-13', 'pixel-9-pro'];
      expect(container.read(shortlistProvider), merged);
      expect(sync.shortlist, merged);
    });

    test('가중치는 계정에 있으면 계정 것', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tp_weights': jsonEncode(TpWeights.defaults.toJson()),
      });
      final sync = _FakeSync(weights: _camera);
      final container = await _signedIn(sync);

      expect(container.read(weightsProvider), _camera);
      expect(sync.writes.where((w) => w.startsWith('weights')), isEmpty);
    });

    test('최근 검색은 이 기기 것이 앞, 최대 10', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'recent_hits': <String>['phone:a', 'phone:b'],
      });
      final sync = _FakeSync(
        recents: <String>[for (var i = 0; i < 10; i++) 'phone:r$i', 'phone:a'],
      );
      final container = await _signedIn(sync);

      final recents = container.read(recentHitsProvider);
      expect(recents.take(3), <String>['phone:a', 'phone:b', 'phone:r0']);
      expect(recents, hasLength(RecentHitsNotifier.cap));
    });

    test('같으면 다시 쓰지 않는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'shortlist_slugs': <String>['galaxy-s25'],
      });
      final sync = _FakeSync(
        shortlist: <String>['galaxy-s25'],
        weights: TpWeights.defaults,
        recents: <String>[],
      );
      await _signedIn(sync);

      expect(sync.writes, isEmpty);
    });
  });

  group('로그인한 동안', () {
    test('관심 목록을 바꾸면 올라간다', () async {
      final sync = _FakeSync();
      final container = await _signedIn(sync);
      sync.writes.clear();

      container.read(shortlistProvider.notifier).toggle('pixel-9-pro');
      await _settle();

      expect(sync.writes, <String>['shortlist:pixel-9-pro']);
    });

    test('가중치는 손을 뗀 뒤 한 번 올라간다', () async {
      final sync = _FakeSync();
      final container = await _signedIn(sync);
      sync.writes.clear();

      final weights = container.read(weightsProvider.notifier);
      for (final v in <double>[1.5, 2, 2.5, 3]) {
        weights.setAxis(TpAxisKind.performance, v);
      }
      await Future<void>.delayed(
        AccountSync.weightsDelay + const Duration(milliseconds: 50),
      );

      expect(sync.writes, <String>['weights:3.0']);
    });

    test('다른 기기에서 바뀐 것을 받고, 되올리지 않는다', () async {
      final sync = _FakeSync();
      final container = await _signedIn(sync);
      sync.writes.clear();

      sync.push(const AccountState(shortlist: <String>['oneplus-13']));
      sync.push(const AccountState(weights: _camera));
      await _settle();

      expect(container.read(shortlistProvider), <String>['oneplus-13']);
      expect(container.read(weightsProvider), _camera);
      await Future<void>.delayed(
        AccountSync.weightsDelay + const Duration(milliseconds: 50),
      );
      expect(sync.writes, isEmpty);
    });

    test('끄는 중에 온 가중치는 사람이 이긴다', () async {
      final sync = _FakeSync();
      final container = await _signedIn(sync);

      container
          .read(weightsProvider.notifier)
          .setAxis(TpAxisKind.performance, 3);
      sync.push(const AccountState(weights: _camera));
      await _settle();

      expect(container.read(weightsProvider).performance, 3);
    });
  });

  test('로그인하지 않으면 아무 일도 없다', () async {
    final sync = _FakeSync();
    final container = _container(auth: FakeAuthService(), sync: sync);
    await _settle();

    container.read(shortlistProvider.notifier).toggle('galaxy-s25');
    await _settle();

    expect(sync.writes, isEmpty);
    expect(container.read(shortlistProvider), <String>['galaxy-s25']);
  });

  test('로그아웃하면 이 기기의 계정 데이터가 빈다', () async {
    final sync = _FakeSync(
      shortlist: <String>['galaxy-s25'],
      weights: _camera,
      recents: <String>['phone:pixel-9'],
    );
    final container = await _signedIn(sync);
    expect(container.read(shortlistProvider), isNotEmpty);

    await container.read(currentUserProvider.notifier).signOut();
    await _settle();

    expect(container.read(shortlistProvider), isEmpty);
    expect(container.read(weightsProvider), TpWeights.defaults);
    expect(container.read(recentHitsProvider), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('shortlist_slugs'), isNull);
    expect(prefs.getString('tp_weights'), isNull);
    // 비운 것을 계정에 올려 덮지 않는다.
    expect(sync.shortlist, <String>['galaxy-s25']);

    // 로그아웃 뒤에 늦게 온 변경은 받지 않는다.
    sync.push(const AccountState(shortlist: <String>['oneplus-13']));
    await _settle();
    expect(container.read(shortlistProvider), isEmpty);
  });

  test('계정을 지우면 계정 데이터를 지우고 기기도 비운다', () async {
    final sync = _FakeSync(shortlist: <String>['galaxy-s25']);
    final container = await _signedIn(sync);

    final failure = await container
        .read(currentUserProvider.notifier)
        .deleteAccount(password: 'longenough');
    await _settle();

    expect(failure, isNull);
    expect(sync.deleted, <String>['u1']);
    expect(container.read(currentUserProvider), isNull);
    expect(container.read(shortlistProvider), isEmpty);
  });

  test('Firestore 가 죽어도 로컬은 돈다', () async {
    final container = await _signedIn(_BrokenSync());

    container.read(shortlistProvider.notifier).toggle('galaxy-s25');
    await _settle();

    expect(container.read(shortlistProvider), <String>['galaxy-s25']);
  });
}
