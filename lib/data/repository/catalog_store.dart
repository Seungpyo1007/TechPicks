/// 받아둔 카탈로그를 두는 곳.
///
/// 애셋은 못 덮어쓰므로 내려받은 것은 따로 남긴다. 다음 실행이 이걸 먼저 읽는다.
library;

import 'catalog_store_io.dart' as impl;

abstract class CatalogStore {
  /// 받아둔 것이 없으면 null.
  Future<String?> read();

  Future<void> write(String json);
}

/// 이 플랫폼에 맞는 저장소.
CatalogStore defaultCatalogStore() => impl.makeCatalogStore();
