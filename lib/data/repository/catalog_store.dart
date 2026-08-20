/// 받아둔 카탈로그를 두는 곳.
///
/// 애셋은 못 덮어쓰므로 내려받은 것은 따로 남긴다. 다음 실행이 이걸 먼저 읽는다.
///
/// 구현이 플랫폼마다 다르다. `path_provider` 는 **웹 구현이 아예 없어서**
/// `getApplicationSupportDirectory()` 가 던진다 — 삼켜지긴 하지만 매번 던진다.
/// 기본 파일이 웹 쪽이고 `if (dart.library.io)` 가 덮어쓰는 쪽이다. 반대로 쓰면
/// 컴파일은 되고 아무 일도 안 한다.
library;

import 'catalog_store_web.dart'
    if (dart.library.io) 'catalog_store_io.dart'
    as impl;

abstract class CatalogStore {
  /// 받아둔 것이 없으면 null.
  Future<String?> read();

  Future<void> write(String json);
}

/// 이 플랫폼에 맞는 저장소.
CatalogStore defaultCatalogStore() => impl.makeCatalogStore();
