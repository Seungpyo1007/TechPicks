import 'dart:convert';

import 'package:dio/dio.dart';

import '../failure.dart';
import 'tech_api_source.dart';

/// TechAPI에서 JSON을 가져오는 얇은 클라이언트.
///
/// 파싱은 하지 않는다. HTTP 결과를 [Failure]로 번역하는 것까지가 책임이다.
class TechApiClient {
  TechApiClient({TechApiSource? source, Dio? dio})
    : source = source ?? const DumpSource(),
      _dio = dio ?? Dio() {
    _dio.options
      ..connectTimeout = const Duration(seconds: 15)
      ..receiveTimeout = const Duration(seconds: 30)
      // 상태 코드 판단은 아래에서 직접 한다.
      // 람다를 괄호로 감싸지 않으면 뒤따르는 캐스케이드를 람다 본문이 삼킨다.
      ..validateStatus = ((_) => true)
      ..responseType = ResponseType.json;
  }

  final TechApiSource source;
  final Dio _dio;

  /// [uri]에서 JSON 객체를 받아온다.
  ///
  /// [collection]과 [slug]는 404를 [NotFoundFailure]로 만들 때만 쓰인다.
  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    String? collection,
    String? slug,
  }) async {
    final Response<dynamic> response;
    try {
      response = await _dio.getUri<dynamic>(uri);
    } on DioException catch (e) {
      throw NetworkFailure('$uri 요청에 실패했다', cause: e);
    }

    final status = response.statusCode ?? 0;
    if (status == 404) {
      throw NotFoundFailure(collection ?? uri.path, slug ?? '');
    }
    if (status < 200 || status >= 300) {
      throw ServerFailure('$uri 가 $status 를 반환했다', statusCode: status);
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return data;

    // GitHub Pages가 Content-Type을 text/plain으로 줄 때 dio는 문자열을 넘긴다.
    if (data is String) {
      final Object? decoded;
      try {
        decoded = jsonDecode(data);
      } on FormatException catch (e) {
        throw ParseFailure('$uri 응답이 올바른 JSON이 아니다', cause: e);
      }
      if (decoded is Map<String, dynamic>) return decoded;
    }

    throw ParseFailure('$uri 응답이 JSON 객체가 아니다 (${data.runtimeType})');
  }

  void close() => _dio.close();
}
