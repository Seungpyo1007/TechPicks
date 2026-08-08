import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/core/failure.dart';
import 'package:techpicks/core/network/tech_api_client.dart';

/// 정해진 응답을 돌려주는 어댑터.
class _Stub implements HttpClientAdapter {
  _Stub(this.body);

  final ResponseBody Function() body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => body();

  @override
  void close({bool force = false}) {}
}

/// 아예 연결이 안 되는 어댑터.
class _Dead implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException.connectionError(
    requestOptions: options,
    reason: '연결 실패',
  );

  @override
  void close({bool force = false}) {}
}

TechApiClient _client(HttpClientAdapter adapter) =>
    TechApiClient(dio: Dio()..httpClientAdapter = adapter);

final _uri = Uri.parse('https://example.test/v1/smartphones/x/index.json');

void main() {
  test('JSON 객체를 그대로 돌려준다', () async {
    final client = _client(
      _Stub(
        () => ResponseBody.fromString(
          jsonEncode(<String, Object>{'slug': 'x'}),
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      ),
    );

    expect(await client.getJson(_uri), <String, Object>{'slug': 'x'});
  });

  test('text/plain 으로 와도 읽는다', () async {
    // GitHub Pages 가 이렇게 준다. dio 는 이때 문자열을 넘긴다.
    final client = _client(
      _Stub(
        () => ResponseBody.fromString(
          jsonEncode(<String, Object>{'slug': 'x'}),
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/plain'],
          },
        ),
      ),
    );

    expect(await client.getJson(_uri), <String, Object>{'slug': 'x'});
  });

  test('404 는 NotFoundFailure', () async {
    final client = _client(
      _Stub(() => ResponseBody.fromString('', 404)),
    );

    expect(
      () => client.getJson(_uri, collection: 'smartphones', slug: 'x'),
      throwsA(isA<NotFoundFailure>()),
    );
  });

  test('5xx 는 ServerFailure 이고 코드를 들고 있다', () async {
    final client = _client(
      _Stub(() => ResponseBody.fromString('', 503)),
    );

    await expectLater(
      client.getJson(_uri),
      throwsA(
        isA<ServerFailure>().having((f) => f.statusCode, 'statusCode', 503),
      ),
    );
  });

  test('연결이 안 되면 NetworkFailure', () async {
    expect(
      () => _client(_Dead()).getJson(_uri),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test('JSON 이 아니면 ParseFailure', () async {
    final client = _client(
      _Stub(
        () => ResponseBody.fromString(
          '이건 JSON 이 아니다',
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>['text/plain'],
          },
        ),
      ),
    );

    expect(() => client.getJson(_uri), throwsA(isA<ParseFailure>()));
  });

  test('JSON 이지만 객체가 아니면 ParseFailure', () async {
    final client = _client(
      _Stub(
        () => ResponseBody.fromString(
          '[1, 2, 3]',
          200,
          headers: <String, List<String>>{
            Headers.contentTypeHeader: <String>[Headers.jsonContentType],
          },
        ),
      ),
    );

    expect(() => client.getJson(_uri), throwsA(isA<ParseFailure>()));
  });
}
