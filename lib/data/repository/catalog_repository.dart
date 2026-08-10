import '../../core/error_reporter.dart';
import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/failure.dart';
import '../../core/result.dart';
import '../dto/cpu.dart';
import '../dto/smartphone.dart';
import '../dto/soc.dart';

/// 앱에 같이 실리는 큐레이션 카탈로그.
///
/// TechAPI 덤프의 목록 인덱스에는 점수가 없고(slug/name/url 뿐), 전체 목록은
/// 19MB 다. 랭킹처럼 정렬이 필요한 화면은 그걸로 못 만든다. 그래서 빌드
/// 시점에 `tool/build_catalog.dart` 가 상세를 받아 애셋으로 굽고, 앱은 그걸
/// 읽는다.
///
/// 상세 화면처럼 기기 하나만 필요한 곳은 카탈로그를 거치지 않고
/// `TechApiRepository` 로 직접 받는다. 카탈로그에 없는 기기도 열려야 한다.
class CatalogRepository {
  CatalogRepository({AssetBundle? bundle, this.assetPath = _defaultAsset})
    : _bundle = bundle ?? rootBundle;

  static const String _defaultAsset = 'assets/catalog/v1.json';

  final AssetBundle _bundle;
  final String assetPath;

  Catalog? _cache;

  /// 한 번 읽고 캐시한다. 애셋이라 갱신될 일이 없다.
  Future<Result<Catalog>> load() async {
    final cached = _cache;
    if (cached != null) return Ok(cached);

    try {
      final raw = await _bundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final catalog = Catalog.fromJson(json);
      _cache = catalog;
      return Ok(catalog);
    } on Failure catch (f) {
      return Err(f);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'catalog.load');
      return Err(ParseFailure('카탈로그 애셋을 읽지 못했다: $assetPath', cause: e));
    }
  }
}

/// 카탈로그 한 벌.
class Catalog {
  const Catalog({
    required this.version,
    required this.source,
    required this.smartphones,
    required this.cpus,
    required this.socs,
  });

  final int version;

  /// 데이터 출처. CC-BY-SA 4.0 상 화면에 표기할 의무가 있다.
  final String source;

  final List<Smartphone> smartphones;
  final List<Cpu> cpus;
  final List<Soc> socs;

  factory Catalog.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) from) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(from)
          .toList(growable: false);
    }

    return Catalog(
      version: (json['version'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
      smartphones: parse('smartphones', Smartphone.fromJson),
      cpus: parse('cpus', Cpu.fromJson),
      socs: parse('socs', Soc.fromJson),
    );
  }
}
