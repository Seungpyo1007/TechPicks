import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/movers.dart';

List<({String slug, String name})> _now(List<String> slugs) =>
    slugs.map((s) => (slug: s, name: s.toUpperCase())).toList();

void main() {
  group('Movers', () {
    test('저장된 순위가 없으면 변동도 없다', () {
      // 처음 실행. 없는 변동을 지어내지 않는다.
      expect(
        Movers.between(previous: const <String>[], current: _now(['a', 'b'])),
        isEmpty,
      );
    });

    test('올라간 만큼 양수, 내려간 만큼 음수', () {
      final movers = Movers.between(
        previous: const <String>['a', 'b', 'c'],
        current: _now(['c', 'a', 'b']),
      );
      final by = <String, Mover>{for (final m in movers) m.slug: m};

      expect(by['c']!.delta, 2);
      expect(by['c']!.isUp, isTrue);
      expect(by['c']!.position, 1);
      expect(by['a']!.delta, -1);
      expect(by['a']!.isUp, isFalse);
    });

    test('자리가 그대로면 목록에 없다', () {
      final movers = Movers.between(
        previous: const <String>['a', 'b', 'c'],
        current: _now(['a', 'c', 'b']),
      );
      expect(movers.map((m) => m.slug), isNot(contains('a')));
    });

    test('새로 들어온 기기는 변동이 아니다', () {
      // 지난 목록에 없던 기기는 신규지 상승이 아니다.
      final movers = Movers.between(
        previous: const <String>['a', 'b'],
        current: _now(['new', 'a', 'b']),
      );
      expect(movers.map((m) => m.slug), isNot(contains('new')));
    });

    test('많이 움직인 순으로 세 개만', () {
      final movers = Movers.between(
        previous: const <String>['a', 'b', 'c', 'd', 'e', 'f'],
        current: _now(['f', 'e', 'd', 'c', 'b', 'a']),
      );
      expect(movers, hasLength(3));
      expect(movers.first.delta.abs(), 5);
      // 내림차순으로 정렬돼 있다.
      for (var i = 1; i < movers.length; i++) {
        expect(
          movers[i - 1].delta.abs(),
          greaterThanOrEqualTo(movers[i].delta.abs()),
        );
      }
    });

    test('목록이 통째로 바뀌어도 터지지 않는다', () {
      expect(
        Movers.between(
          previous: const <String>['x', 'y'],
          current: _now(['a', 'b']),
        ),
        isEmpty,
      );
    });
  });
}
