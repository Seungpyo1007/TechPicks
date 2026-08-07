/// 지난 순위 대비 이동.
class Mover {
  const Mover({
    required this.slug,
    required this.name,
    required this.position,
    required this.delta,
  });

  final String slug;
  final String name;

  /// 현재 순위. 1부터.
  final int position;

  /// 올라간 칸 수. 양수면 상승, 음수면 하락.
  final int delta;

  bool get isUp => delta > 0;
}

abstract final class Movers {
  /// 저장해둔 순위와 지금 순위를 견줘 움직인 기기를 뽑는다.
  ///
  /// TechAPI 에는 과거 순위가 없다. 명세의 `prevPos` 를 채울 데이터가
  /// 어디에도 없어서, 지난번에 본 순위를 앱이 직접 저장해두고 그것과 비교한다.
  /// 처음 실행하면 비교 대상이 없으니 빈 목록이고, 그러면 화면에서 섹션이
  /// 통째로 빠진다. 없는 변동을 지어내는 것보다 낫다.
  ///
  /// [limit] 은 명세의 3줄.
  static List<Mover> between({
    required List<String> previous,
    required List<({String slug, String name})> current,
    int limit = 3,
  }) {
    if (previous.isEmpty) return const <Mover>[];

    final was = <String, int>{
      for (var i = 0; i < previous.length; i++) previous[i]: i,
    };

    final moved = <Mover>[];
    for (var i = 0; i < current.length; i++) {
      final before = was[current[i].slug];
      // 지난 목록에 없던 기기는 변동이 아니라 신규다. 순위 이동으로 치지 않는다.
      if (before == null || before == i) continue;
      moved.add(Mover(
        slug: current[i].slug,
        name: current[i].name,
        position: i + 1,
        delta: before - i,
      ));
    }

    moved.sort((a, b) => b.delta.abs().compareTo(a.delta.abs()));
    return moved.take(limit).toList(growable: false);
  }
}
