import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../core/failure.dart';
import '../../core/network/tech_api_client.dart';

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
