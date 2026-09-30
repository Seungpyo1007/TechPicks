import 'package:freezed_annotation/freezed_annotation.dart';

import 'brand.dart';
// Display 는 smartphone.dart 가 들고 있다. `show Display` 로 좁히면
// freezed 가 만든 $DisplayCopyWith 가 안 보여 생성 코드가 안 붙는다.
import 'smartphone.dart';

part 'laptop.freezed.dart';
part 'laptop.g.dart';

/// 노트북 한 대.
///
/// **점수가 없다.** TechAPI 의 노트북에는 벤치마크가 실려 있지 않아
/// `score` 필드 자체가 없다 — 그래서 이 DTO 에도 없다. 폰·CPU 와 나란히
/// 두고 지수로 줄 세울 수 없다는 뜻이고, 화면이 그걸 숨기지 않는다.
///
/// `cpu` · `gpu` 객체도 상류에서 전부 null 로 온다. 쓸 수 있는 건
/// [cpuName] · [gpuName] 문자열뿐인데, 그마저 브랜드·계열·변형을 이어붙인
/// 것이라 `Apple M4 M4 Max` 같은 값이 왔다. `tool/normalize_names.dart` 가
/// 구울 때 접는다 — 런타임에 고치지 않는다.
@freezed
abstract class Laptop with _$Laptop {
  const factory Laptop({
    required String slug,
    required String name,

    /// 변형을 걷어낸 기본 모델. 같은 기기의 사양이 다른 변형이 여러 줄로 올 때
    /// 묶는 데 쓴다.
    String? baseModelSlug,
    Brand? brand,
    String? releaseDate,
    int? msrpUsd,

    /// `Gaming` · `General` 등. 상류 분류를 그대로 옮긴다.
    String? deviceCategory,
    String? cpuName,
    String? gpuName,

    /// `Integrated` · `Dedicated`.
    String? gpuType,
    int? ramGb,
    int? storageGb,
    Display? display,
    int? weightG,
    String? os,
    String? osVersion,
    String? imageUrl,
    @Default(false) bool verified,
    @Default(<String>[]) List<String> sourceUrls,
    String? url,
  }) = _Laptop;

  factory Laptop.fromJson(Map<String, dynamic> json) => _$LaptopFromJson(json);
}
