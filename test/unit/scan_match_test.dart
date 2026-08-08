import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/brand.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/domain/model/scan_match.dart';

Smartphone _phone(String slug, String name, {String? brand}) => Smartphone(
  slug: slug,
  name: name,
  brand: brand == null ? null : Brand(slug: brand, name: brand),
);

final _catalog = <Smartphone>[
  _phone('galaxy-s25-ultra', 'Galaxy S25 Ultra', brand: 'Samsung'),
  _phone('galaxy-s25', 'Galaxy S25', brand: 'Samsung'),
  _phone('iphone-16-pro-max', 'iPhone 16 Pro Max', brand: 'Apple'),
  _phone('pixel-9-pro', 'Pixel 9 Pro', brand: 'Google'),
];

void main() {
  group('ScanMatcher', () {
    test('모델명이 그대로 읽히면 그 기기', () {
      final m = ScanMatcher.match('SAMSUNG Galaxy S25 Ultra', _catalog);
      expect(m?.device.slug, 'galaxy-s25-ultra');
      expect(m!.score, 1);
    });

    test('OCR 이 기호를 흘려도 맞춘다', () {
      // 하이픈, 점, 줄바꿈이 섞이는 게 보통이다.
      final m = ScanMatcher.match('iPhone-16.Pro\nMax\nApple', _catalog);
      expect(m?.device.slug, 'iphone-16-pro-max');
    });

    test('대소문자를 가리지 않는다', () {
      expect(
        ScanMatcher.match('pixel 9 pro google', _catalog)?.device.slug,
        'pixel-9-pro',
      );
    });

    test('브랜드만 읽히면 아무것도 고르지 않는다', () {
      // "Galaxy" 만 보고 삼성 폰을 집으면 안 된다.
      expect(ScanMatcher.match('Samsung', _catalog), isNull);
    });

    test('관계없는 글자는 null', () {
      expect(ScanMatcher.match('FCC ID A3LSMS931U', _catalog), isNull);
      expect(ScanMatcher.match('', _catalog), isNull);
    });

    test('빈 카탈로그면 null', () {
      expect(ScanMatcher.match('Galaxy S25', const <Smartphone>[]), isNull);
    });

    test('더 많이 겹치는 쪽을 고른다', () {
      // 두 기기 이름이 서로를 포함한다. Ultra 까지 읽혔으면 Ultra 다.
      final m = ScanMatcher.match('Galaxy S25 Ultra', _catalog);
      expect(m?.device.slug, 'galaxy-s25-ultra');
    });

    test('임계값 아래는 버린다', () {
      final m = ScanMatcher.match('Galaxy', _catalog);
      expect(m, isNull);
      expect(ScanMatcher.threshold, 0.5);
    });
  });
}
