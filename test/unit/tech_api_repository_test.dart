import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/core/failure.dart';
import 'package:techpicks/core/network/tech_api_client.dart';
import 'package:techpicks/core/network/tech_api_source.dart';
import 'package:techpicks/core/result.dart';
import 'package:techpicks/data/repository/tech_api_repository.dart';
import 'package:techpicks/domain/repository/device_repository.dart';

import '../fixtures/fixtures.dart';

/// 네트워크를 타지 않고 정해진 응답을 돌려주는 어댑터.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
  final List<String> requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requested.add(options.uri.toString());
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object data, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  },
);

TechApiRepository _repoWith(_StubAdapter adapter) {
  final dio = Dio()..httpClientAdapter = adapter;
  return TechApiRepository(
    client: TechApiClient(source: const DumpSource(), dio: dio),
  );
}

void main() {
  test('상세를 요청하면 덤프 URL을 치고 DTO로 돌려준다', () async {
    final adapter = _StubAdapter(
      (_) => _json(loadFixture('smartphone_galaxy_s25')),
    );
    final result = await _repoWith(adapter).smartphone('galaxy-s25');

    expect(result.isOk, isTrue);
    expect(result.valueOrNull?.name, 'Galaxy S25');
    expect(
      adapter.requested.single,
      'https://gettechapi.github.io/TechAPI/v1/smartphones/galaxy-s25/index.json',
    );
  });

  test('404는 NotFoundFailure가 된다 — 큐레이션이 덜 된 slug', () async {
    final adapter = _StubAdapter((_) => _json({}, status: 404));
    final result = await _repoWith(adapter).smartphone('없는-기기');

    expect(result.isErr, isTrue);
    final failure = result.failureOrNull;
    expect(failure, isA<NotFoundFailure>());
    expect((failure! as NotFoundFailure).slug, '없는-기기');
  });

  test('5xx는 ServerFailure로 상태 코드를 보존한다', () async {
    final adapter = _StubAdapter((_) => _json({}, status: 503));
    final result = await _repoWith(adapter).cpu('ryzen-9-9950x3d');

    expect(result.failureOrNull, isA<ServerFailure>());
    expect((result.failureOrNull! as ServerFailure).statusCode, 503);
  });

  test('연결 실패는 NetworkFailure가 된다', () async {
    final adapter = _StubAdapter((options) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: '연결 거부',
      );
    });
    final result = await _repoWith(adapter).gpu('geforce-rtx-5090');

    expect(result.failureOrNull, isA<NetworkFailure>());
  });

  test('스키마가 어긋나면 예외 대신 ParseFailure로 접힌다', () async {
    // slug가 없는 응답 — 필수 필드 위반
    final adapter = _StubAdapter((_) => _json({'name': '이름만 있음'}));
    final result = await _repoWith(adapter).smartphone('galaxy-s25');

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ParseFailure>());
  });

  test('목록은 컬렉션 enum으로 경로를 만든다', () async {
    final adapter = _StubAdapter((_) => _json(loadFixture('brands_list')));
    final result = await _repoWith(adapter).list(TechApiCollection.brands);

    expect(result.valueOrNull?.count, 207);
    expect(
      adapter.requested.single,
      'https://gettechapi.github.io/TechAPI/v1/brands/index.json',
    );
  });

  test('인덱스는 컬렉션별 레코드 수를 담는다', () async {
    final adapter = _StubAdapter((_) => _json(loadFixture('v1_index')));
    final result = await _repoWith(adapter).index();

    final collections =
        result.valueOrNull?['collections'] as Map<String, dynamic>?;
    expect(collections, isNotNull);
    expect(collections!['smartphones']['count'], greaterThan(90000));
  });

  group('Result', () {
    test('fold로 두 갈래를 하나로 접는다', () {
      const ok = Ok<int>(3);
      const err = Err<int>(NetworkFailure('끊김'));

      expect(ok.fold((v) => '값 $v', (f) => '실패'), '값 3');
      expect(err.fold((v) => '값 $v', (f) => '실패 ${f.message}'), '실패 끊김');
    });

    test('map은 성공만 변환하고 실패는 통과시킨다', () {
      const ok = Ok<int>(3);
      const err = Err<int>(NetworkFailure('끊김'));

      expect(ok.map((v) => v * 2).valueOrNull, 6);
      expect(err.map((v) => v * 2).failureOrNull, isA<NetworkFailure>());
    });
  });
}
