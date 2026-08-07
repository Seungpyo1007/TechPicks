import 'package:freezed_annotation/freezed_annotation.dart';

import 'brand.dart';
import 'score.dart';

part 'soc.freezed.dart';
part 'soc.g.dart';

/// SoC의 CPU 클러스터 구성.
@freezed
abstract class CpuConfig with _$CpuConfig {
  const factory CpuConfig({
    /// 고성능 코어 수.
    int? performance,

    /// 효율 코어 수.
    int? efficiency,
    String? architecture,

    /// 클러스터별 최대 클럭. 길이는 고정이 아니다.
    @Default(<double>[]) List<double> clocksGhz,
  }) = _CpuConfig;

  factory CpuConfig.fromJson(Map<String, dynamic> json) =>
      _$CpuConfigFromJson(json);
}

/// 모바일 SoC.
///
/// 스마트폰 레코드에 임베드될 때는 `manufacturer`/`process_nm`/`gpu_name`
/// 정도만 채워져 온다.
@freezed
abstract class Soc with _$Soc {
  const factory Soc({
    required String slug,
    required String name,
    int? id,
    Brand? manufacturer,
    String? releaseDate,

    /// 공정 (나노미터).
    double? processNm,
    double? transistorsBillion,
    CpuConfig? cpuConfig,
    String? gpuName,
    int? gpuCores,
    int? gpuClockMhz,

    /// NPU 연산 성능 (TOPS).
    double? npuTops,
    String? modem,
    SocScore? score,

    /// 큐레이터가 출처를 검증했는지. 데이터셋 상당수가 false다.
    @Default(false) bool verified,
    @Default(<String>[]) List<String> sourceUrls,
    String? url,
  }) = _Soc;

  factory Soc.fromJson(Map<String, dynamic> json) => _$SocFromJson(json);
}
