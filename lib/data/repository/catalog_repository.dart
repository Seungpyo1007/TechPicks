import 'dart:async' show unawaited;
import 'dart:convert';

import '../../core/error_reporter.dart';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/failure.dart';
import '../../core/result.dart';
import '../dto/brand.dart';
import '../dto/cpu.dart';
import '../dto/smartphone.dart';
import '../dto/soc.dart';
import 'catalog_source.dart';

/// 앱에 같이 실리는 큐레이션 카탈로그.
///
/// TechAPI 덤프의 목록 인덱스에는 점수가 없고(slug/name/url 뿐), 전체 목록은
/// 19MB 다. 랭킹처럼 정렬이 필요한 화면은 그걸로 못 만든다. 그래서 빌드
/// 시점에 `tool/build_catalog.dart` 가 상세를 받아 애셋으로 굽고, 앱은 그걸
/// 읽는다.
///
/// 상세 화면처럼 기기 하나만 필요한 곳은 카탈로그를 거치지 않고
/// `TechApiRepository` 로 직접 받는다. 카탈로그에 없는 기기도 열려야 한다.
///
/// **애셋이 끝이 아니다.** [store] 와 [feed] 를 주면 내려받은 카탈로그를 먼저
/// 읽고, 뒤에서 새 버전을 받아 다음 실행에 쓴다. 명세가 요구한 "스토어 배포
/// 없이 점수 갱신"이 그 경로다. 둘 다 없으면 지금까지대로 애셋만 읽는다.
class CatalogRepository {
  CatalogRepository({
    AssetBundle? bundle,
    this.assetPath = _defaultAsset,
    CatalogStore? store,
    CatalogFeed? feed,
  }) : _bundle = bundle ?? rootBundle,
       _store = store,
       _feed = feed;

  static const String _defaultAsset = 'assets/catalog/v1.json';

  final AssetBundle _bundle;
  final String assetPath;
  final CatalogStore? _store;
  final CatalogFeed? _feed;

  Catalog? _cache;

  /// 한 번 읽고 캐시한다.
  ///
  /// 받아둔 파일이 애셋보다 **새로울 때만** 그걸 쓴다. 앱을 업데이트하면
  /// 애셋 쪽이 더 새로울 수 있고, 그때 옛날 다운로드가 이기면 안 된다.
  Future<Result<Catalog>> load() async {
    final cached = _cache;
    if (cached != null) return Ok(cached);

    final asset = await _fromAsset();
    final stored = await _fromStore();
    final fromAsset = asset.fold((c) => c, (_) => null);

    final chosen =
        (stored != null &&
            (fromAsset == null || stored.version > fromAsset.version))
        ? stored
        : fromAsset;

    // 애셋도 못 읽고 받아둔 것도 없다. 원래 실패를 그대로 돌려준다.
    if (chosen == null) return asset;

    _cache = chosen;
    unawaited(_refresh(chosen.version));
    return Ok(chosen);
  }

  Future<Result<Catalog>> _fromAsset() async {
    try {
      final raw = await _bundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Ok(Catalog.fromJson(json));
    } on Failure catch (f) {
      return Err(f);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'catalog.load');
      return Err(ParseFailure('카탈로그 애셋을 읽지 못했다: $assetPath', cause: e));
    }
  }

  /// 받아둔 파일. 없거나 깨졌으면 null 이고, 그때는 애셋으로 떨어진다.
  Future<Catalog?> _fromStore() async {
    final store = _store;
    if (store == null) return null;
    try {
      final raw = await store.read();
      if (raw == null) return null;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return Catalog.fromJson(json);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'catalog.stored');
      return null;
    }
  }

  /// 새 카탈로그를 받아 파일에 쓴다. **이번 실행에는 안 쓴다.**
  ///
  /// 보고 있는 화면에서 순위가 갑자기 뒤집히는 것보다 다음에 켤 때 바뀌는
  /// 편이 낫다. 첫 프레임을 네트워크에 걸지 않는 효과도 같이 온다.
  Future<void> _refresh(int current) async {
    final feed = _feed;
    final store = _store;
    if (feed == null || store == null) return;

    try {
      final latest = await feed.latest();
      if (latest == null || latest.version <= current) return;

      final body = await feed.fetch(latest.url);
      if (body == null) return;

      // 깨진 것을 저장하면 다음 실행이 그걸 읽는다. Catalog.fromJson 은
      // 관대해서 던지지 않고 빈 목록을 주므로 여기서 직접 본다.
      if (Catalog.fromJson(body).smartphones.isEmpty) return;

      await store.write(encodeCatalog(body));
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'catalog.refresh');
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
    this.brands = const <Brand>[],
  });

  final int version;

  /// 데이터 출처. CC-BY-SA 4.0 상 화면에 표기할 의무가 있다.
  final String source;

  final List<Smartphone> smartphones;
  final List<Cpu> cpus;
  final List<Soc> socs;

  /// 실린 기기가 참조하는 제조사. 기기에 임베드된 brand 는 이름뿐이라
  /// 국가·설립연도·설명은 여기에만 있다.
  ///
  /// 기본값이 빈 목록인 이유는 받아둔 옛 카탈로그 때문이다. `brands` 가 없던
  /// 시절 파일을 읽어도 화면이 죽으면 안 된다.
  final List<Brand> brands;

  /// 슬러그로 찾는다. 상세 화면이 기기마다 한 번씩 부른다.
  Brand? brand(String? slug) => slug == null
      ? null
      : brands.where((b) => b.slug == slug).firstOrNull;

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
      brands: parse('brands', Brand.fromJson),
    );
  }
}
