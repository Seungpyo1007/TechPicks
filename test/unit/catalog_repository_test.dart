import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/core/failure.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/domain/model/processor.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/domain/model/tp_index.dart';

/// 실제 애셋 파일을 그대로 읽는 번들. `tool/build_catalog.dart` 가 구운
/// 결과물이 앱에서 파싱되는지 확인하려면 진짜 파일이어야 한다.
class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = File(key).readAsBytesSync();
    return ByteData.view(bytes.buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode(File(key).readAsBytesSync());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('구워둔 카탈로그 애셋이 파싱된다', () async {
    final repo = CatalogRepository(bundle: _FileBundle());
    final result = await repo.load();

    expect(result.isOk, isTrue, reason: '${result.failureOrNull}');
    final catalog = result.valueOrNull!;

    expect(catalog.version, greaterThanOrEqualTo(2));
    // CC-BY-SA 4.0 귀속 표기에 쓸 출처 문자열이 반드시 있어야 한다.
    expect(catalog.source, contains('TechAPI'));
    expect(catalog.smartphones, isNotEmpty);
    expect(catalog.cpus, isNotEmpty);
    expect(catalog.socs, isNotEmpty);
  });

  test('Processors 화면이 요구하는 5행이 세그먼트마다 있다', () async {
    final repo = CatalogRepository(bundle: _FileBundle());
    final catalog = (await repo.load()).valueOrNull!;

    // 명세 §5 가 세그먼트당 5행이다. 모자라면 화면이 빈다.
    expect(catalog.socs.length, greaterThanOrEqualTo(5));
    expect(catalog.cpus.length, greaterThanOrEqualTo(5));
    // 브랜드 설명은 상세 화면이 쓴다.
    expect(catalog.brands, isNotEmpty);

    for (final soc in catalog.socs) {
      expect(soc.score?.overall, isNotNull, reason: soc.slug);
      expect(Processor.fromSoc(soc).sub, isNotEmpty, reason: soc.slug);
    }
    for (final cpu in catalog.cpus) {
      expect(cpu.score?.overall, isNotNull, reason: cpu.slug);
      // 데스크톱 칩은 실을 화면이 없다.
      expect(cpu.segment, 'laptop', reason: cpu.slug);
      expect(Processor.fromCpu(cpu).sub, isNotEmpty, reason: cpu.slug);
    }
  });

  test('모든 기기가 랭킹에 쓸 점수를 갖고 있다', () async {
    final repo = CatalogRepository(bundle: _FileBundle());
    final catalog = (await repo.load()).valueOrNull!;

    for (final phone in catalog.smartphones) {
      expect(
        TpIndex.of(phone.score),
        isNotNull,
        reason: '${phone.slug} 에 점수가 없다. 카탈로그에 넣을 이유가 없는 기기.',
      );
      expect(phone.brand?.name, isNotNull, reason: phone.slug);
    }
  });

  test('카탈로그로 바로 정렬할 수 있다', () async {
    final repo = CatalogRepository(bundle: _FileBundle());
    final catalog = (await repo.load()).valueOrNull!;

    final ranked = Ranking.of(catalog.smartphones, RankAxis.tpIndex);
    expect(ranked, hasLength(catalog.smartphones.length));
    expect(ranked.first.position, 1);

    // 내림차순이 실제로 지켜지는지.
    for (var i = 1; i < ranked.length; i++) {
      final prev = ranked[i - 1].axisValue;
      final cur = ranked[i].axisValue;
      if (prev != null && cur != null) {
        expect(prev, greaterThanOrEqualTo(cur));
      }
    }
  });

  test('두 번 읽어도 같은 인스턴스를 준다', () async {
    final repo = CatalogRepository(bundle: _FileBundle());
    final a = (await repo.load()).valueOrNull;
    final b = (await repo.load()).valueOrNull;
    expect(identical(a, b), isTrue);
  });

  test('애셋이 없으면 ParseFailure', () async {
    final repo = CatalogRepository(
      bundle: _FileBundle(),
      assetPath: 'assets/catalog/없는파일.json',
    );
    final result = await repo.load();
    expect(result.failureOrNull, isA<ParseFailure>());
  });
}
