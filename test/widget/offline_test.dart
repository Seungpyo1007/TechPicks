import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/core/failure.dart';
import 'package:techpicks/core/result.dart';
import 'package:techpicks/data/dto/brand.dart';
import 'package:techpicks/data/dto/collection_page.dart';
import 'package:techpicks/data/dto/cpu.dart';
import 'package:techpicks/data/dto/gpu.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/dto/soc.dart';
import 'package:techpicks/data/repository/tech_api_repository.dart';
import 'package:techpicks/data/service/connectivity_service.dart';
import 'package:techpicks/domain/repository/device_repository.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 연결 상태를 테스트가 정한다.
class _FakeConnectivity implements ConnectivityService {
  _FakeConnectivity(this._offline);

  bool _offline;
  final StreamController<bool> _changes = StreamController<bool>.broadcast();

  void set(bool value) {
    _offline = value;
    _changes.add(value);
  }

  @override
  Future<bool> offline() async => _offline;

  @override
  Stream<bool> changes() => _changes.stream;
}

/// 플러그인이 없는 기기.
class _BrokenConnectivity implements ConnectivityService {
  @override
  Future<bool> offline() async => throw StateError('플러그인 없음');

  @override
  Stream<bool> changes() => const Stream<bool>.empty();
}

/// 카탈로그 밖 기기는 여기로 온다. 실패 종류를 테스트가 고른다.
class _FailingApi implements TechApiRepository {
  _FailingApi(this.failure);

  final Failure failure;

  @override
  Future<Result<Smartphone>> smartphone(String slug) async => Err(failure);

  @override
  Future<Result<Cpu>> cpu(String slug) => throw UnimplementedError();

  @override
  Future<Result<Gpu>> gpu(String slug) => throw UnimplementedError();

  @override
  Future<Result<Soc>> soc(String slug) => throw UnimplementedError();

  @override
  Future<Result<Brand>> brand(String slug) => throw UnimplementedError();

  @override
  Future<Result<CollectionPage>> list(TechApiCollection collection) =>
      throw UnimplementedError();

  @override
  Future<Result<Map<String, dynamic>>> index() => throw UnimplementedError();
}

Future<void> _pump(
  WidgetTester tester, {
  required ConnectivityService connectivity,
  Failure failure = const NetworkFailure('연결 실패'),
}) async {
  await pumpScreen(
    tester,
    const DetailScreen(slug: '카탈로그에-없는-기기'),
    size: const Size(1200, 2000),
    overrides: <Override>[
      connectivityServiceProvider.overrideWithValue(connectivity),
      techApiRepositoryProvider.overrideWithValue(_FailingApi(failure)),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(initLocalization);

  testWidgets('오프라인이면 인터넷 이야기를 한다', (tester) async {
    await _pump(tester, connectivity: _FakeConnectivity(true));

    expect(find.text(K.offlineTitle.tr()), findsOneWidget);
    expect(find.text(K.offlineBody.tr()), findsOneWidget);
    expect(find.text(K.loadFailed.tr()), findsNothing);
  });

  testWidgets('온라인인데 실패한 것은 그대로 실패다', (tester) async {
    await _pump(tester, connectivity: _FakeConnectivity(false));

    expect(find.text(K.loadFailed.tr()), findsOneWidget);
    expect(find.text(K.offlineTitle.tr()), findsNothing);
  });

  testWidgets('오프라인이어도 네트워크 실패가 아니면 문구를 안 바꾼다', (tester) async {
    // 404 는 인터넷이 있어도 없어도 404 다.
    await _pump(
      tester,
      connectivity: _FakeConnectivity(true),
      failure: const NotFoundFailure('smartphones', '없는-기기'),
    );

    expect(find.text(K.loadFailed.tr()), findsOneWidget);
    expect(find.text(K.offlineTitle.tr()), findsNothing);
  });

  testWidgets('연결 상태를 못 읽으면 지금까지대로 보여준다', (tester) async {
    await _pump(tester, connectivity: _BrokenConnectivity());

    expect(find.text(K.loadFailed.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('보는 동안 연결이 끊기면 문구가 바뀐다', (tester) async {
    final connectivity = _FakeConnectivity(false);
    await _pump(tester, connectivity: connectivity);
    expect(find.text(K.loadFailed.tr()), findsOneWidget);

    connectivity.set(true);
    await tester.pumpAndSettle();

    expect(find.text(K.offlineTitle.tr()), findsOneWidget);
  });
}
