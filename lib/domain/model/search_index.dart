import '../../data/dto/cpu.dart';
import '../../data/dto/laptop.dart';
import '../../data/dto/smartphone.dart';
import 'tp_index.dart';
import 'tp_weights.dart';

/// 검색 결과 하나가 가리키는 것.
enum SearchKind { phone, processor, laptop }

/// 검색 목록의 한 줄.
///
/// 세 갈래를 한 타입으로 편다. 탭마다 검색을 따로 두면 "무엇을 찾는지" 를
/// 먼저 정해야 하는데, 이름만 아는 사람은 그걸 모른다 — 9950X3D 가 폰인지
/// 프로세서인지 알면 이미 찾은 셈이다.
class SearchHit {
  const SearchHit({
    required this.kind,
    required this.slug,
    required this.name,
    this.meta,
    this.index,
  });

  final SearchKind kind;

  /// 목적지를 만드는 데 쓴다. 노트북은 상세 화면이 없어 목록으로만 보낸다.
  final String slug;

  final String name;

  /// 이름 아래 한 줄. 브랜드·칩셋 같은 것.
  final String? meta;

  /// 행 오른쪽 숫자. 폰은 TP Index, 프로세서는 TechAPI 점수, 노트북은 없다.
  final int? index;

  /// 걸러낼 때 보는 문자열. 이름과 부제 어느 쪽에 걸려도 남는다.
  String get haystack => '$name ${meta ?? ''}'.toLowerCase();
}

abstract final class SearchIndex {
  /// 세 갈래를 한 목록으로.
  ///
  /// 순서는 폰·프로세서·노트북이다. 폰이 이 앱의 본업이라 먼저 오고, 같은
  /// 글자에 여럿이 걸릴 때 위에 있는 쪽이 눈에 먼저 든다.
  ///
  /// 폰 지수는 [weights] 로 낸다. 다른 화면과 같은 숫자여야 한다.
  static List<SearchHit> of({
    List<Smartphone> phones = const <Smartphone>[],
    List<Cpu> processors = const <Cpu>[],
    List<Laptop> laptops = const <Laptop>[],
    TpWeights weights = TpWeights.defaults,
  }) => <SearchHit>[
    for (final p in phones)
      SearchHit(
        kind: SearchKind.phone,
        slug: p.slug,
        name: p.name,
        meta: _join(<String?>[p.brand?.name, p.soc?.name]),
        index: TpIndex.of(p.score, weights),
      ),
    for (final c in processors)
      SearchHit(
        kind: SearchKind.processor,
        slug: c.slug,
        name: c.name,
        meta: _join(<String?>[c.manufacturer?.name, c.architecture]),
        index: c.score?.overall?.round(),
      ),
    for (final l in laptops)
      SearchHit(
        kind: SearchKind.laptop,
        slug: l.slug,
        name: l.name,
        meta: _join(<String?>[l.brand?.name, l.cpuName]),
      ),
  ];

  /// [query] 로 거른다. 비면 **빈 목록**이다.
  ///
  /// [DeviceSearch.filter] 는 빈 질의에 전체를 돌려준다 — 거기선 목록이
  /// 먼저 있고 검색이 좁히는 것이라 그게 맞다. 여기선 반대다. 검색 화면이
  /// 열리자마자 194줄을 쏟아내면 그건 검색 결과가 아니라 목록이다.
  ///
  /// 관련도 순이다: 이름이 같음 → 이름이 질의로 시작 → 이름 속 낱말이 질의로
  /// 시작 → 이름 어딘가 → 부제에만. 같은 칸이면 지수 높은 쪽, 그다음 원래 순서.
  static List<SearchHit> filter(List<SearchHit> index, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const <SearchHit>[];
    final word = RegExp('(^|[\\s(/-])${RegExp.escape(q)}');
    int rank(SearchHit h) {
      final name = h.name.toLowerCase();
      if (name == q) return 0;
      if (name.startsWith(q)) return 1;
      if (word.hasMatch(name)) return 2;
      if (name.contains(q)) return 3;
      return 4;
    }

    final found = <(SearchHit, int, int)>[
      for (var i = 0; i < index.length; i++)
        if (index[i].haystack.contains(q)) (index[i], rank(index[i]), i),
    ];
    found.sort((a, b) {
      final byRank = a.$2.compareTo(b.$2);
      if (byRank != 0) return byRank;
      final byIndex = (b.$1.index ?? -1).compareTo(a.$1.index ?? -1);
      if (byIndex != 0) return byIndex;
      return a.$3.compareTo(b.$3);
    });
    return <SearchHit>[for (final f in found) f.$1];
  }

  static String? _join(List<String?> parts) {
    final kept = parts
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim());
    return kept.isEmpty ? null : kept.join(' · ');
  }
}
