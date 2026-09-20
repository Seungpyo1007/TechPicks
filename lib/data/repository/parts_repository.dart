import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../../core/error_reporter.dart';
import '../../core/failure.dart';
import '../../core/result.dart';
import '../dto/cpu.dart';
import '../dto/gpu.dart';

/// 조립 PC 부품 한 벌.
///
/// 카탈로그의 CPU 40종은 **전부 노트북용**이라 조립에 쓸 수 없다. 견적기가
/// 쓰는 데스크톱 CPU·GPU 는 이 별도 애셋에서 온다.
class DesktopParts {
  const DesktopParts({
    required this.version,
    required this.source,
    required this.cpus,
    required this.gpus,
    this.generated,
  });

  final int version;

  /// 데이터 출처. CC-BY-SA 4.0 상 화면에 표기할 의무가 있다.
  final String source;

  /// 상류에서 받아 구운 날.
  final String? generated;

  final List<Cpu> cpus;
  final List<Gpu> gpus;

  /// 값이 있는 것만. 견적기는 **가격 있는 조합만** 본다 — 값을 모르는 부품을
  /// 예산에 넣으면 합계가 거짓말이 된다.
  List<Cpu> get pricedCpus =>
      cpus.where((c) => c.msrpUsd != null).toList(growable: false);

  List<Gpu> get pricedGpus =>
      gpus.where((g) => g.msrpUsd != null).toList(growable: false);

  Cpu? cpu(String slug) => cpus.where((c) => c.slug == slug).firstOrNull;
  Gpu? gpu(String slug) => gpus.where((g) => g.slug == slug).firstOrNull;

  factory DesktopParts.fromJson(Map<String, dynamic> json) {
    List<T> parse<T>(String key, T Function(Map<String, dynamic>) from) {
      final raw = json[key];
      if (raw is! List) return <T>[];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(from)
          .toList(growable: false);
    }

    return DesktopParts(
      version: (json['version'] as num?)?.toInt() ?? 0,
      source: json['source'] as String? ?? '',
      generated: json['generated'] as String?,
      cpus: parse('cpus', Cpu.fromJson),
      gpus: parse('gpus', Gpu.fromJson),
    );
  }
}

/// 애셋에 실린 데스크톱 부품을 읽는다.
///
/// **원격이 아니라 번들이다.** 견적기가 CPU×GPU 를 전수 탐색하므로 전체가
/// 메모리에 있어야 하고, 쪼개 받을 수 있는 질의가 아니다. 테스트도 실제
/// 애셋을 읽어야 파일이 깨졌을 때 걸린다.
///
/// 고정은 아니다 — 카탈로그와 같은 원격 갱신 경로를 붙일 자리가 있다.
class PartsRepository {
  PartsRepository({AssetBundle? bundle, this.assetPath = _defaultAsset})
    : _bundle = bundle ?? rootBundle;

  static const String _defaultAsset = 'assets/parts/desktop-v1.json';

  final AssetBundle _bundle;
  final String assetPath;

  DesktopParts? _cache;

  /// 한 번 읽고 캐시한다. 236KB 를 화면마다 다시 파싱할 이유가 없다.
  Future<Result<DesktopParts>> load() async {
    final cached = _cache;
    if (cached != null) return Ok(cached);

    try {
      final raw = await _bundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final parts = DesktopParts.fromJson(json);
      _cache = parts;
      return Ok(parts);
    } on Failure catch (f) {
      return Err(f);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'parts.load');
      return Err(ParseFailure('부품 애셋을 읽지 못했다: $assetPath', cause: e));
    }
  }
}
