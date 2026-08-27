import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';

import '../support/harness.dart';

/// 구워둔 카탈로그가 지켜야 하는 것들.
///
/// `tool/build_catalog.dart` 는 TechAPI 93,396건에서 골라 담는다. 규칙을
/// 잘못 건드리면 판매점 스크랩 변형이나 점수 없는 레코드가 섞여 들어오는데,
/// 154종을 눈으로 훑을 수는 없다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final catalog = readCatalog();

  test('정규 레코드만 들어 있다', () {
    // 변형은 base_model_slug 가 채워져 있다 —
    // `oneplus-12-aitoolbuzz-7384-24gb-256gb-5g` 같은 것들.
    for (final phone in catalog.smartphones) {
      expect(phone.baseModelSlug, isNull, reason: phone.slug);
    }
  });

  test('전부 점수와 이름을 갖고 있다', () {
    for (final phone in catalog.smartphones) {
      expect(phone.score?.overall, isNotNull, reason: phone.slug);
      expect(phone.name.trim(), isNotEmpty, reason: phone.slug);
    }
  });

  test('점수 내림차순으로 실려 있다', () {
    // 비교 화면의 기본 두 대가 이 순서에서 나온다. 흔들리면 화면이 흔들린다.
    final scores = catalog.smartphones
        .map((p) => p.score!.overall!)
        .toList(growable: false);
    for (var i = 1; i < scores.length; i++) {
      expect(scores[i], lessThanOrEqualTo(scores[i - 1]));
    }
  });

  test('슬러그가 겹치지 않는다', () {
    final slugs = catalog.smartphones.map((p) => p.slug).toSet();
    expect(slugs, hasLength(catalog.smartphones.length));
  });

  test('테스트가 기대는 기기들이 들어 있다', () {
    // 이 슬러그들은 다른 테스트와 골든이 이름으로 찾는다.
    for (final slug in <String>[
      'galaxy-s25',
      'galaxy-s25-ultra',
      'iphone-16-pro-max',
      'oneplus-13',
      'pixel-9-pro-xl',
    ]) {
      expect(
        catalog.smartphones.any((p) => p.slug == slug),
        isTrue,
        reason: slug,
      );
    }
  });

  test('브랜드 참조가 전부 풀린다', () {
    // 상세의 브랜드 카드가 슬러그로 찾는다. 못 찾으면 조용히 빈다.
    final known = catalog.brands.map((b) => b.slug).toSet();
    for (final phone in catalog.smartphones) {
      final slug = phone.brand?.slug;
      if (slug == null) continue;
      expect(known, contains(slug), reason: phone.slug);
    }
  });

  test('랭킹 화면 상한보다 카탈로그가 크다', () {
    // 상한이 카탈로그보다 크면 상한을 둔 의미가 없다.
    expect(catalog.smartphones.length, greaterThan(RankScreen.maxRows));
  });

  test('프로세서는 화면 세그먼트와 짝이 맞는다', () {
    expect(catalog.socs, isNotEmpty);
    expect(catalog.cpus, isNotEmpty);
    for (final cpu in catalog.cpus) {
      expect(cpu.segment, 'laptop', reason: cpu.slug);
    }
  });
}
