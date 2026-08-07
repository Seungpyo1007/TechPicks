import 'package:freezed_annotation/freezed_annotation.dart';

import 'brand.dart';
import 'score.dart';

part 'gpu.freezed.dart';
part 'gpu.g.dart';

/// 외장 그래픽카드.
///
/// NVIDIA는 `cudaCores`, AMD는 `streamProcessors`를 쓴다. 둘 중 하나만 채워진다.
@freezed
abstract class Gpu with _$Gpu {
  const factory Gpu({
    required String slug,
    required String name,
    int? id,
    Brand? manufacturer,
    String? architecture,
    String? releaseDate,
    int? msrpUsd,
    int? cudaCores,
    int? streamProcessors,
    int? rtCores,
    int? tensorCores,
    double? memoryGb,
    String? memoryType,
    int? memoryBusBit,
    double? memoryBandwidthGbps,
    int? baseClockMhz,
    int? boostClockMhz,
    int? tdpW,
    String? pcieVersion,
    double? fp32Tflops,
    double? blenderScore,
    GpuScore? score,
    @Default(false) bool verified,
    @Default(<String>[]) List<String> sourceUrls,
    String? url,
  }) = _Gpu;

  factory Gpu.fromJson(Map<String, dynamic> json) => _$GpuFromJson(json);
}
