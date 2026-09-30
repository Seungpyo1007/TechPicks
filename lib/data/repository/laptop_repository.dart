import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/error_reporter.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../dto/laptop.dart';

/// 노트북 목록 한 벌.
///
/// **아홉 대뿐이다.** 상류에 노트북이 1,951종 있지만 점수가 없고 사양도
/// 성글어서, 웹이 쓸 만한 것만 골라 스냅샷으로 남긴 게 이만큼이다. 적다는
/// 사실을 화면이 숨기지 않는다.
class Laptops {
  const Laptops({
    required this.version,
    required this.source,
    required this.items,
    this.generated,
  });

  final int version;

  /// 데이터 출처. CC-BY-SA 4.0 상 화면에 표기할 의무가 있다.
  final String source;

  final String? generated;
  final List<Laptop> items;

  /// 비싼 것부터. **점수가 없어서 지수로 못 줄 세운다** — 값을 아는 축이
  /// 가격뿐이다. 없는 점수를 지어내느니 가격순이라고 밝히는 쪽이 낫다.
  List<Laptop> get byPrice {
    final priced = items.where((l) => l.msrpUsd != null).toList()
      ..sort((a, b) => b.msrpUsd!.compareTo(a.msrpUsd!));
    final rest = items.where((l) => l.msrpUsd == null).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return <Laptop>[...priced, ...rest];
  }

  Laptop? bySlug(String slug) => items.where((l) => l.slug == slug).firstOrNull;

  factory Laptops.fromJson(Map<String, dynamic> json) {
    final raw = json['laptops'];
    return Laptops(
      version: (json['version'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
      generated: json['generated'] as String?,
      items: raw is! List
          ? const <Laptop>[]
          : raw
                .whereType<Map<String, dynamic>>()
                .map(Laptop.fromJson)
                .toList(growable: false),
    );
  }
}

/// 애셋에 실린 노트북을 읽는다.
class LaptopRepository {
  LaptopRepository({AssetBundle? bundle, this.assetPath = _defaultAsset})
    : _bundle = bundle ?? rootBundle;

  static const String _defaultAsset = 'assets/laptops/v1.json';

  final AssetBundle _bundle;
  final String assetPath;

  Laptops? _cache;

  Future<Result<Laptops>> load() async {
    final cached = _cache;
    if (cached != null) return Ok(cached);

    try {
      final raw = await _bundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final laptops = Laptops.fromJson(json);
      _cache = laptops;
      return Ok(laptops);
    } on Failure catch (f) {
      return Err(f);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'laptops.load');
      return Err(ParseFailure('노트북 애셋을 읽지 못했다: $assetPath', cause: e));
    }
  }
}
