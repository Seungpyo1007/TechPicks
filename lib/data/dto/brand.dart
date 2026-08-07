import 'package:freezed_annotation/freezed_annotation.dart';

part 'brand.freezed.dart';
part 'brand.g.dart';

/// 제조사.
///
/// 같은 구조가 두 자리에서 쓰이는데 채워지는 필드가 다르다.
///
/// * `/v1/brands/{slug}` 상세 — 모든 필드
/// * 다른 레코드에 임베드될 때 — `slug`/`name`/`url` 정도만.
///   SoC의 `manufacturer`는 `id`조차 없다.
///
/// 그래서 `slug`와 `name`을 제외한 전부가 nullable이다.
@freezed
abstract class Brand with _$Brand {
  const factory Brand({
    required String slug,
    required String name,
    int? id,

    /// ISO 3166-1 alpha-2 (예: `KR`).
    String? country,
    int? foundedYear,
    String? logoUrl,
    String? website,

    /// 설명은 언어별로 따로 온다. `?lang=` 파라미터가 아니라 별도 필드다.
    String? descriptionEn,
    String? descriptionKo,

    /// API 내부 상대 경로 (예: `/v1/brands/samsung`).
    String? url,
    @Default(<String>[]) List<String> sourceUrls,
  }) = _Brand;

  factory Brand.fromJson(Map<String, dynamic> json) => _$BrandFromJson(json);
}
