import 'package:freezed_annotation/freezed_annotation.dart';

import 'brand.dart';
import 'score.dart';
import 'soc.dart';

part 'smartphone.freezed.dart';
part 'smartphone.g.dart';

@freezed
abstract class Display with _$Display {
  const factory Display({
    double? sizeInch,

    /// `2340x1080` 형태의 문자열. 숫자로 파싱하지 않는다.
    String? resolution,
    int? refreshHz,

    /// 패널 종류 (예: `Dynamic AMOLED 2X`).
    String? type,
    int? ppi,
    int? brightnessNits,
  }) = _Display;

  factory Display.fromJson(Map<String, dynamic> json) =>
      _$DisplayFromJson(json);
}

/// 카메라 하나. 기기당 여러 개가 배열로 온다.
///
/// `type`은 `main` / `ultrawide` / `telephoto` / `selfie` 등이며,
/// 나머지 필드는 카메라 종류에 따라 있기도 없기도 하다.
@freezed
abstract class Camera with _$Camera {
  const factory Camera({
    String? type,

    /// 화소 (메가픽셀).
    double? mp,
    double? aperture,

    /// 광학식 손떨림 보정.
    bool? ois,
    String? sensor,
    double? opticalZoom,
  }) = _Camera;

  factory Camera.fromJson(Map<String, dynamic> json) => _$CameraFromJson(json);
}

@freezed
abstract class Dimensions with _$Dimensions {
  const factory Dimensions({
    double? heightMm,
    double? widthMm,
    double? depthMm,
  }) = _Dimensions;

  factory Dimensions.fromJson(Map<String, dynamic> json) =>
      _$DimensionsFromJson(json);
}

@freezed
abstract class Connectivity with _$Connectivity {
  const factory Connectivity({
    String? wifi,
    String? bluetooth,
    bool? nfc,
    String? usb,
  }) = _Connectivity;

  factory Connectivity.fromJson(Map<String, dynamic> json) =>
      _$ConnectivityFromJson(json);
}

/// 스마트폰. 데이터셋에서 가장 큰 컬렉션(93,000건 이상)이다.
///
/// `brand`와 `soc`가 이미 조인되어 내려오므로 상세 화면을 그리는 데
/// 추가 요청이 필요 없다.
@freezed
abstract class Smartphone with _$Smartphone {
  const factory Smartphone({
    required String slug,
    required String name,
    int? id,

    /// 파생 모델일 때 원본 모델의 slug (예: Plus/Ultra 변형).
    String? baseModelSlug,
    Brand? brand,
    Soc? soc,

    /// `YYYY-MM-DD`. 일자가 불확실하면 월초로 채워져 있다.
    String? releaseDate,
    int? msrpUsd,
    int? ramGb,
    @Default(<int>[]) List<int> storageOptionsGb,

    /// 지역·구성별 변형 정보. 스키마가 고정되어 있지 않아 원본 그대로 둔다.
    @Default(<String, dynamic>{}) Map<String, dynamic> variant,
    Display? display,
    @Default(<Camera>[]) List<Camera> cameras,
    int? batteryMah,
    int? chargingWiredW,
    int? chargingWirelessW,
    double? weightG,
    Dimensions? dimensions,

    /// 방수·방진 등급 (예: `IP68`).
    String? ipRating,
    String? os,
    String? osVersion,
    Connectivity? connectivity,
    String? imageUrl,
    @Default(<String>[]) List<String> images,
    SmartphoneScore? score,
    @Default(false) bool verified,

    /// CC-BY-SA 4.0 조건상 UI에 반드시 노출해야 한다.
    @Default(<String>[]) List<String> sourceUrls,
    String? createdAt,
    String? updatedAt,
  }) = _Smartphone;

  factory Smartphone.fromJson(Map<String, dynamic> json) =>
      _$SmartphoneFromJson(json);
}
