import 'package:freezed_annotation/freezed_annotation.dart';

part 'collection_page.freezed.dart';
part 'collection_page.g.dart';

/// 목록에 실리는 최소 정보.
///
/// 상세를 받으려면 [slug]로 다시 요청해야 한다.
@freezed
abstract class ResourceRef with _$ResourceRef {
  const factory ResourceRef({
    required String slug,
    required String name,
    String? url,
  }) = _ResourceRef;

  factory ResourceRef.fromJson(Map<String, dynamic> json) =>
      _$ResourceRefFromJson(json);
}

/// 컬렉션 목록 응답.
///
/// 정적 덤프는 **한 파일에 전체 목록**을 담는다. REST의 `?limit`/`?offset`
/// 페이지네이션과 달리 [next]/[previous]가 항상 null이다.
///
/// 스마트폰은 93,000건이 넘으므로 이 응답을 통째로 메모리에 올리기 전에
/// 크기를 반드시 계측할 것 (issue #8).
@freezed
abstract class CollectionPage with _$CollectionPage {
  const factory CollectionPage({
    @Default(0) int count,
    @Default(<ResourceRef>[]) List<ResourceRef> results,
    String? next,
    String? previous,
  }) = _CollectionPage;

  factory CollectionPage.fromJson(Map<String, dynamic> json) =>
      _$CollectionPageFromJson(json);
}
