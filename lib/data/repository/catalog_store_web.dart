import 'catalog_store.dart';

/// 웹에서는 아무것도 안 둔다. **빠뜨린 게 아니라 정한 것이다.**
///
/// 웹에서 카탈로그는 HTTP 로 받는 490KB JSON 이고, [FileCatalogStore] 가 하려던
/// 일 — "애셋은 못 덮어쓰니 받은 것을 따로 남긴다" — 을 **브라우저 HTTP 캐시가
/// 이미 한다.** `shared_preferences` 는 웹에서 localStorage 라 5MB 한도에 메인
/// 스레드를 막는다. 맞는 도구가 아니다.
///
/// 서버가 `Cache-Control`/ETag 를 붙여 카탈로그를 내주기 시작하면 "받아둔
/// 카탈로그"라는 개념 자체가 없어진다. 그 전에 오프라인이 필요해지면
/// IndexedDB 다.
class NoCatalogStore implements CatalogStore {
  const NoCatalogStore();

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String json) async {}
}

CatalogStore makeCatalogStore() => const NoCatalogStore();
