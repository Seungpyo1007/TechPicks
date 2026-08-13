import 'dart:convert';
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/failure.dart';
import '../../core/network/tech_api_client.dart';

/// 받아둔 카탈로그를 두는 곳.
///
/// 애셋은 못 덮어쓰므로 내려받은 것은 파일로 남긴다. 다음 실행이 이걸 먼저
/// 읽는다.
abstract class CatalogStore {
  /// 받아둔 것이 없으면 null.
  Future<String?> read();

  Future<void> write(String json);
}

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

/// 지금 배포된 카탈로그가 무엇인지 알려주는 곳.
///
/// 명세 Data model 이 "스토어 배포 없이 점수 갱신"을 요구했는데 카탈로그가
/// 애셋이라 달성 못 하고 있었다. 이게 그 구멍을 막는다.
abstract class CatalogFeed {
  /// 지금 배포된 버전과 주소. 못 읽거나 배포된 게 없으면 null.
  Future<({int version, Uri url})?> latest();

  /// 본문. 실패하면 null.
  Future<Map<String, dynamic>?> fetch(Uri url);
}

/// Remote Config 가 주소를 주고 본문은 따로 받는다.
///
/// **본문을 Remote Config 에 넣지 않는다.** 값 크기 제한이 있어 카탈로그가
/// 커지면 막힌다. 주소만 두면 카탈로그가 얼마나 커지든 그대로 간다.
class RemoteConfigCatalogFeed implements CatalogFeed {
  RemoteConfigCatalogFeed({FirebaseRemoteConfig? config, TechApiClient? client})
    : _config = config,
      _client = client;

  /// 카탈로그 JSON 주소. 비어 있으면 애셋을 쓴다.
  static const String urlKey = 'catalog_url';

  /// 이 숫자가 지금 것보다 클 때만 받는다.
  static const String versionKey = 'catalog_version';

  FirebaseRemoteConfig? _config;
  TechApiClient? _client;

  @override
  Future<({int version, Uri url})?> latest() async {
    // Firebase 가 초기화되지 않았으면 여기서 던진다. 부르는 쪽이 삼킨다.
    final config = _config ??= FirebaseRemoteConfig.instance;

    await config.setDefaults(<String, dynamic>{urlKey: '', versionKey: 0});
    await config.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 15),
        // 기본값은 12시간이다. 점수를 고친 날 바로 보이지 않는다.
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await config.fetchAndActivate();

    final raw = config.getString(urlKey);
    if (raw.isEmpty) return null;

    final url = Uri.tryParse(raw);
    if (url == null || !url.isAbsolute) return null;

    return (version: config.getInt(versionKey), url: url);
  }

  @override
  Future<Map<String, dynamic>?> fetch(Uri url) async {
    try {
      return await (_client ??= TechApiClient()).getJson(url);
    } on Failure {
      // 못 받으면 지금 것을 계속 쓴다. 다음 실행에 다시 시도한다.
      return null;
    }
  }
}

/// 저장할 때 쓰는 형태. 받은 것을 그대로 문자열로 남긴다.
String encodeCatalog(Map<String, dynamic> json) => jsonEncode(json);
