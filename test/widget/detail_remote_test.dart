import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/core/failure.dart';
import 'package:techpicks/core/result.dart';
import 'package:techpicks/data/dto/brand.dart';
import 'package:techpicks/data/dto/cpu.dart';
import 'package:techpicks/data/dto/gpu.dart';
import 'package:techpicks/data/dto/collection_page.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/dto/soc.dart';
import 'package:techpicks/data/repository/tech_api_repository.dart';
import 'package:techpicks/domain/repository/device_repository.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 카탈로그에 없는 기기를 상세로 여는 경로.
///
/// 카탈로그는 큐레이션한 10종뿐이다. 스캔 결과나 나중의 검색은 그 밖의 기기를
/// 열 수 있어야 하고, 그때는 TechAPI 로 직접 간다.
class _FakeApi implements TechApiRepository {
  _FakeApi(this.answer);

  final Result<Smartphone> answer;
  int calls = 0;

  @override
  Future<Result<Smartphone>> smartphone(String slug) async {
    calls++;
    return answer;
  }

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

void main() {
  setUp(initLocalization);

  testWidgets('카탈로그에 있으면 원격을 안 부른다', (tester) async {
    final api = _FakeApi(Err(const NotFoundFailure('smartphones', 'x')));
    await pumpScreen(
      tester,
      const DetailScreen(slug: 'galaxy-s25-ultra'),
      size: const Size(1200, 3200),
      overrides: <Override>[techApiRepositoryProvider.overrideWithValue(api)],
    );

    expect(find.text('Galaxy S25 Ultra'), findsWidgets);
    expect(api.calls, 0);
  });

  testWidgets('없으면 원격에서 받아 그린다', (tester) async {
    final api = _FakeApi(
      Ok(const Smartphone(slug: 'pixel-10-pro', name: 'Pixel 10 Pro')),
    );
    await pumpScreen(
      tester,
      const DetailScreen(slug: 'pixel-10-pro'),
      size: const Size(1200, 3200),
      overrides: <Override>[techApiRepositoryProvider.overrideWithValue(api)],
    );

    expect(api.calls, 1);
    expect(find.text('Pixel 10 Pro'), findsWidgets);
  });

  testWidgets('원격도 없으면 못 불러왔다고 알린다', (tester) async {
    final api = _FakeApi(
      Err(const NotFoundFailure('smartphones', 'pixel-10-pro')),
    );
    await pumpScreen(
      tester,
      const DetailScreen(slug: 'pixel-10-pro'),
      size: const Size(1200, 3200),
      overrides: <Override>[techApiRepositoryProvider.overrideWithValue(api)],
    );

    expect(find.text(K.loadFailed.tr()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('점수도 가격도 없는 기기가 와도 안 터진다', (tester) async {
    final api = _FakeApi(Ok(const Smartphone(slug: '이름만', name: '이름만 있는 기기')));
    await pumpScreen(
      tester,
      const DetailScreen(slug: '이름만'),
      size: const Size(1200, 3200),
      overrides: <Override>[techApiRepositoryProvider.overrideWithValue(api)],
    );

    expect(find.text('이름만 있는 기기'), findsWidgets);
    // 없는 값은 전부 대시로 떨어진다.
    expect(find.text('—'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
