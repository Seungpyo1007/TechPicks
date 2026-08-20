import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/data/repository/catalog_source.dart';
import 'package:techpicks/data/repository/catalog_store.dart';
import 'package:techpicks/data/repository/catalog_store_io.dart';

import '../support/harness.dart';

/// 받아둔 파일.
class _FakeStore implements CatalogStore {
  _FakeStore([this.stored]);

  String? stored;
  int writes = 0;

  @override
  Future<String?> read() async => stored;

  @override
  Future<void> write(String json) async {
    stored = json;
    writes++;
  }
}

/// 못 읽는 저장소. 권한이 없거나 파일이 깨진 경우.
class _BrokenStore implements CatalogStore {
  @override
  Future<String?> read() async => throw StateError('못 읽는다');

  @override
  Future<void> write(String json) async => throw StateError('못 쓴다');
}

class _FakeFeed implements CatalogFeed {
  _FakeFeed({this.version, this.body});

  final int? version;
  final Map<String, dynamic>? body;
  int fetches = 0;

  @override
  Future<({int version, Uri url})?> latest() async => version == null
      ? null
      : (version: version!, url: Uri.parse('https://example.com/catalog.json'));

  @override
  Future<Map<String, dynamic>?> fetch(Uri url) async {
    fetches++;
    return body;
  }
}

/// 원격을 아예 못 부르는 경우. Firebase 가 없는 빌드가 여기다.
class _BrokenFeed implements CatalogFeed {
  @override
  Future<({int version, Uri url})?> latest() async =>
      throw StateError('Firebase 없음');

  @override
  Future<Map<String, dynamic>?> fetch(Uri url) async => null;
}

/// 애셋과 같은 모양의 카탈로그 한 벌.
String _catalog(int version, {String name = 'Galaxy S25'}) =>
    jsonEncode(<String, dynamic>{
      'version': version,
      'source': 'TechAPI',
      'smartphones': <Map<String, dynamic>>[
        <String, dynamic>{'slug': 'galaxy-s25', 'name': name},
      ],
    });

CatalogRepository _repo({CatalogStore? store, CatalogFeed? feed}) =>
    CatalogRepository(
      bundle: FileBundle(),
      assetPath: defaultCatalogAsset,
      store: store,
      feed: feed,
    );

void main() {
  group('플랫폼 저장소', _defaultStore);
  test('받아둔 것이 없으면 애셋을 읽는다', () async {
    final store = _FakeStore();
    final result = await _repo(store: store, feed: _FakeFeed()).load();

    final catalog = result.fold((c) => c, (f) => throw f);
    expect(catalog.smartphones, hasLength(readCatalog().smartphones.length));
  });

  test('받아둔 것이 애셋보다 새로우면 그걸 쓴다', () async {
    final store = _FakeStore(_catalog(99, name: '내려받은 기기'));
    final result = await _repo(store: store, feed: _FakeFeed()).load();

    final catalog = result.fold((c) => c, (f) => throw f);
    expect(catalog.version, 99);
    expect(catalog.smartphones.single.name, '내려받은 기기');
  });

  test('받아둔 것이 애셋보다 낡았으면 애셋을 쓴다', () async {
    // 앱을 업데이트하면 애셋 쪽이 더 새로울 수 있다.
    final store = _FakeStore(_catalog(0));
    final result = await _repo(store: store, feed: _FakeFeed()).load();

    final catalog = result.fold((c) => c, (f) => throw f);
    expect(catalog.smartphones, hasLength(readCatalog().smartphones.length));
  });

  test('받아둔 것이 깨졌으면 애셋으로 떨어진다', () async {
    final store = _FakeStore('{ 이건 JSON 이 아니다');
    final result = await _repo(store: store, feed: _FakeFeed()).load();

    final catalog = result.fold((c) => c, (f) => throw f);
    expect(catalog.smartphones, hasLength(readCatalog().smartphones.length));
  });

  test('원격 버전이 높으면 받아서 저장한다', () async {
    final store = _FakeStore();
    final feed = _FakeFeed(
      version: 99,
      body: jsonDecode(_catalog(99)) as Map<String, dynamic>,
    );

    await _repo(store: store, feed: feed).load();
    // 갱신은 화면을 막지 않고 뒤에서 돈다.
    await Future<void>.delayed(Duration.zero);

    expect(feed.fetches, 1);
    expect(store.writes, 1);
    expect(jsonDecode(store.stored!), containsPair('version', 99));
  });

  test('원격 버전이 같거나 낮으면 안 받는다', () async {
    final store = _FakeStore();
    final feed = _FakeFeed(version: 1);

    await _repo(store: store, feed: feed).load();
    await Future<void>.delayed(Duration.zero);

    expect(feed.fetches, 0);
    expect(store.writes, 0);
  });

  test('빈 카탈로그는 저장하지 않는다', () async {
    // 주소가 살아 있는데 내용이 비었으면 앱이 통째로 빈 화면이 된다.
    final store = _FakeStore();
    final feed = _FakeFeed(
      version: 99,
      body: <String, dynamic>{'version': 99, 'smartphones': <dynamic>[]},
    );

    await _repo(store: store, feed: feed).load();
    await Future<void>.delayed(Duration.zero);

    expect(store.writes, 0);
  });

  test('배포된 카탈로그가 없으면 아무것도 안 한다', () async {
    final store = _FakeStore();
    final feed = _FakeFeed();

    final result = await _repo(store: store, feed: feed).load();
    await Future<void>.delayed(Duration.zero);

    expect(
      result.fold((c) => c.smartphones, (f) => throw f),
      hasLength(readCatalog().smartphones.length),
    );
    expect(feed.fetches, 0);
  });

  test('원격이 죽어도 화면은 카탈로그를 받는다', () async {
    final result = await _repo(store: _FakeStore(), feed: _BrokenFeed()).load();
    await Future<void>.delayed(Duration.zero);

    expect(
      result.fold((c) => c.smartphones, (f) => throw f),
      hasLength(readCatalog().smartphones.length),
    );
  });

  test('저장소가 죽어도 화면은 카탈로그를 받는다', () async {
    final result = await _repo(
      store: _BrokenStore(),
      feed: _FakeFeed(version: 99),
    ).load();
    await Future<void>.delayed(Duration.zero);

    expect(
      result.fold((c) => c.smartphones, (f) => throw f),
      hasLength(readCatalog().smartphones.length),
    );
  });

  test('애셋이 없어도 받아둔 것이 있으면 그걸 쓴다', () async {
    final repo = CatalogRepository(
      bundle: FileBundle(),
      assetPath: missingCatalogAsset,
      store: _FakeStore(_catalog(1)),
      feed: _FakeFeed(),
    );

    final catalog = (await repo.load()).fold((c) => c, (f) => throw f);
    expect(catalog.smartphones.single.slug, 'galaxy-s25');
  });

  test('둘 다 없으면 실패가 그대로 온다', () async {
    final repo = CatalogRepository(
      bundle: FileBundle(),
      assetPath: missingCatalogAsset,
      store: _FakeStore(),
      feed: _FakeFeed(),
    );

    expect((await repo.load()).fold((c) => 'ok', (f) => 'err'), 'err');
  });
}

/// VM 에서는 파일 저장소가 나와야 한다. 조건부 import 의 방향을 뒤집으면
/// 컴파일은 되고 아무 일도 안 한다 — 그걸 여기서 못박는다.
void _defaultStore() {
  test('VM 에서는 파일 저장소를 쓴다', () {
    expect(defaultCatalogStore(), isA<FileCatalogStore>());
  });
}
