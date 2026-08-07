import 'package:freezed_annotation/freezed_annotation.dart';

import 'brand.dart';
import 'score.dart';

part 'cpu.freezed.dart';
part 'cpu.g.dart';

/// 데스크톱·노트북 CPU.
@freezed
abstract class Cpu with _$Cpu {
  const factory Cpu({
    required String slug,
    required String name,
    int? id,
    Brand? manufacturer,
    String? releaseDate,

    /// `desktop` / `laptop` / `server` 등.
    String? segment,
    String? architecture,
    String? socket,

    /// 공정. CPU는 `TSMC N4` 같은 문자열이라 SoC의 `processNm`과 타입이 다르다.
    String? processNode,
    int? cores,
    int? threads,

    /// 하이브리드 구조에서만 채워진다.
    int? pCores,
    int? eCores,
    double? baseClockGhz,
    double? boostClockGhz,
    double? l3CacheMb,
    int? tdpW,
    int? maxTdpW,
    String? integratedGraphics,
    String? memorySupport,
    int? msrpUsd,
    CpuScore? score,
    @Default(false) bool verified,
    @Default(<String>[]) List<String> sourceUrls,
    String? url,
  }) = _Cpu;

  factory Cpu.fromJson(Map<String, dynamic> json) => _$CpuFromJson(json);
}
