import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'catalog_store.dart';

/// 앱 지원 디렉터리의 파일 하나.
///
/// 캐시 디렉터리가 아니라 지원 디렉터리다 — OS 가 지우면 앱이 조용히 옛
/// 점수로 돌아간다.
class FileCatalogStore implements CatalogStore {
  const FileCatalogStore();

  static const String fileName = 'catalog.json';

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$fileName');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    if (!file.existsSync()) return null;
    return file.readAsString();
  }

  @override
  Future<void> write(String json) async {
    final file = await _file();
    await file.writeAsString(json, flush: true);
  }
}

CatalogStore makeCatalogStore() => const FileCatalogStore();
