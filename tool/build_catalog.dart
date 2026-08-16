// TechAPI 에서 큐레이션한 기기 상세를 받아 `assets/catalog/v1.json` 으로 굽는다.
//
//   dart tool/build_catalog.dart
//
// 왜 필요한가. TechAPI 정적 덤프의 목록 인덱스에는 slug/name/url 만 들어 있고
// 점수가 없다. 랭킹은 점수로 정렬해야 하는데, 상세를 기기마다 받으면 93,396 번
// 요청이고 목록 전체는 19.8MB 다. 둘 다 앱에서 못 한다.
//
// 명세(`docs/DESIGN_HANDOFF.md` — Data model)도 같은 결론이다.
//   "Long-term this is what the planned TechPicks API should serve;
//    until then ship it as a versioned JSON asset so scores can be updated
//    without a store release."
//
// 그래서 빌드 시점에 한 번 받아 애셋으로 넣는다.
//
// ── 무엇을 싣는가 ────────────────────────────────────────────────
//
// 예전에는 슬러그를 손으로 열 개 적었다. 지금은 목록 인덱스에서 후보를 뽑아
// 상세를 받아보고 거른다. 거르는 규칙은 셋이다.
//
//   1. 정규 레코드      base_model_slug 가 null
//   2. 점수가 있다      score.overall != null
//   3. 최근 것          출시일이 [_maxAgeYears] 년 이내
//
// 1번이 핵심이다. TechAPI 의 스마트폰 93,396건 중 대부분은
// `oneplus-12-aitoolbuzz-7384-24gb-256gb-5g` 같은 판매점 스크랩 변형이고,
// 정규 레코드만 이름·가격·점수가 온전하다.
//
// 노트북은 안 싣는다. 점수가 없고, 표본 120대에서 무게와 가격을 **둘 다**
// 가진 것이 하나도 없었다 (출처 데이터셋이 가격만 주는 쪽과 무게만 주는
// 쪽으로 갈려 있다). 명세 §6 의 4칸 그리드를 채울 수가 없다.
import 'dart:convert';
import 'dart:io';

const String _base = 'https://gettechapi.github.io/TechAPI/v1';

/// 애셋에 실을 최대 개수.
///
/// 폰 200 은 랭킹·비교·픽커가 데이터로 보이기 시작하는 선이다. 더 늘리면
/// 애셋만 커지고 아래쪽은 아무도 안 본다.
const int _phoneLimit = 200;
const int _cpuLimit = 40;
const int _socLimit = 30;

/// 출시가 이보다 오래된 것은 뺀다.
const int _maxAgeYears = 3;

/// 상세를 받아볼 후보의 상한.
///
/// 접두사만으로 거르면 수천 건이 남는다. 정규 슬러그는 짧다는 성질을 이용해
/// 짧은 것부터 이만큼만 받아본다.
///
/// 1,200 으로 돌려보니 최근 3년 안에 드는 것이 115종뿐이었다 — 짧은 슬러그가
/// 곧 최신은 아니라서(`galaxy-s10` 이 `galaxy-s25-ultra` 보다 짧다) 더 넓게
/// 훑어야 한다. 받은 것은 캐시되므로 다시 돌릴 때는 새로 나온 것만 받는다.
const int _phoneProbeLimit = 4500;

/// 동시에 받는 수. GitHub Pages 라 더 올려도 별 이득이 없다.
const int _concurrency = 10;

/// 반드시 들어가야 하는 폰.
///
/// 테스트와 골든이 이 슬러그들에 걸려 있다. 점수가 낮아 상위 200 밖으로
/// 밀려나도 싣는다.
const List<String> _pinnedPhones = <String>[
  'galaxy-s25-ultra',
  'iphone-16-pro-max',
  'pixel-9-pro-xl',
  'oneplus-13',
  'xiaomi-15-ultra',
  'galaxy-s25',
  'iphone-16-pro',
  'pixel-9-pro',
  'galaxy-z-fold-7',
  'oneplus-13r',
];

/// 후보로 볼 슬러그 접두사. 한국에서 실제로 고민 대상이 되는 브랜드들이다.
const List<String> _phonePrefixes = <String>[
  'galaxy-',
  'iphone-',
  'pixel-',
  'oneplus-',
  'xiaomi-',
  'redmi-',
  'poco-',
  'oppo-',
  'vivo-',
  'realme-',
  'honor-',
  'moto-',
  'motorola-',
  'nothing-',
  'cmf-',
  'xperia-',
  'zenfone-',
  'rog-phone-',
  'iqoo-',
  'huawei-',
  'mate-',
  'nova-',
  'nubia-',
  'zte-',
  'tcl-',
  'infinix-',
  'tecno-',
  'fairphone-',
];

/// 노트북 CPU 후보. 최근 세대만 본다.
final List<RegExp> _cpuPatterns = <RegExp>[
  RegExp(r'^(intel-)?core-(ultra-)?i?[3579]-1[2-5]\d{2,3}[a-z]*$'),
  RegExp(r'^(intel-)?core-ultra-[3579]-\d{3}[a-z]*$'),
  RegExp(r'^ryzen-(ai-)?[3579]-\w+$'),
  RegExp(r'^snapdragon-x-'),
  RegExp(r'^apple-m[1-5](-(pro|max|ultra))?$'),
];

/// 모바일 SoC 후보.
final List<RegExp> _socPatterns = <RegExp>[
  RegExp(r'^snapdragon-8'),
  RegExp(r'^snapdragon-7'),
  RegExp(r'^dimensity-[89]'),
  RegExp(r'^apple-a1[5-9]'),
  RegExp(r'^exynos-2'),
  RegExp(r'^tensor-g'),
];

/// 변형 레코드 냄새. 상세를 받기 전에 걸러 요청 수를 줄인다.
///
/// 판정은 어디까지나 상세의 `base_model_slug` 가 한다. 여기서는 확실한
/// 것만 쳐낸다 — 용량 표기와 판매점이 붙인 긴 숫자 꼬리.
final RegExp _looksVariant = RegExp(r'(\d+gb)|(-\d{4,})|(dual-sim)');

Future<void> main() async {
  final client = HttpClient();
  final cache = Directory('.dart_tool/techapi_cache');

  stdout.writeln('TechAPI → assets/catalog/v1.json');

  final phones = await _collectPhones(client, cache);
  final cpus = await _collectScored(
    client,
    cache,
    collection: 'cpus',
    patterns: _cpuPatterns,
    limit: _cpuLimit,
    // 데스크톱 칩은 실을 화면이 없다. 명세 §5 의 세그먼트는 Mobile/Laptop 뿐.
    keep: (r) => r['segment'] == 'laptop',
  );
  final socs = await _collectScored(
    client,
    cache,
    collection: 'socs',
    patterns: _socPatterns,
    limit: _socLimit,
  );
  final brands = await _collectBrands(client, cache, phones);

  client.close();

  final catalog = <String, dynamic>{
    // 받아둔 파일이 애셋보다 새로울 때만 이기므로, 굽는 쪽이 올려야 한다.
    'version': 2,
    // 데이터 출처 표기는 CC-BY-SA 4.0 의무 사항이라 애셋에도 박아둔다.
    'source': 'TechAPI (CC-BY-SA 4.0) — https://github.com/GetTechAPI/TechAPI',
    'smartphones': phones,
    'cpus': cpus,
    'socs': socs,
    'brands': brands,
  };

  final out = File('assets/catalog/v1.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(
    '${const JsonEncoder.withIndent('  ').convert(catalog)}\n',
  );

  final kb = (out.lengthSync() / 1024).toStringAsFixed(1);
  stdout.writeln(
    '\n${out.path} · ${kb}KB · '
    '폰 ${phones.length} · CPU ${cpus.length} · SoC ${socs.length} · '
    '브랜드 ${brands.length}',
  );
}

/// 폰: 후보 → 상세 → 세 조건 → 점수순 → 상한.
Future<List<Map<String, dynamic>>> _collectPhones(
  HttpClient client,
  Directory cache,
) async {
  final index = await _index(client, cache, 'smartphones');
  stdout.writeln('  smartphones 인덱스 ${index.length}건');

  final candidates =
      index
          .map((e) => e['slug'] as String)
          .where((s) => _phonePrefixes.any(s.startsWith))
          .where((s) => !_looksVariant.hasMatch(s))
          .toList()
        // 정규 슬러그는 짧다. `galaxy-s25` vs `galaxy-s25-...-256gb-5g`.
        ..sort(
          (a, b) => a.length == b.length ? a.compareTo(b) : a.length - b.length,
        );

  final probe = <String>{
    ..._pinnedPhones,
    ...candidates.take(_phoneProbeLimit),
  }.toList(growable: false);

  stdout.writeln('  후보 ${probe.length}건 받는 중…');
  final records = await _fetchAll(client, cache, 'smartphones', probe);

  final cutoff = DateTime.now().subtract(
    const Duration(days: 365 * _maxAgeYears),
  );
  final kept = records.where((r) {
    if (_pinnedPhones.contains(r['slug'])) return _score(r) != null;
    return r['base_model_slug'] == null &&
        _score(r) != null &&
        _released(r) != null &&
        _released(r)!.isAfter(cutoff);
  }).toList();

  _sortByScore(kept);
  final top = kept.take(_phoneLimit).toList();

  // 상한 밖으로 밀린 고정 기기를 되살린다.
  for (final slug in _pinnedPhones) {
    if (top.any((r) => r['slug'] == slug)) continue;
    final found = kept.where((r) => r['slug'] == slug).firstOrNull;
    if (found != null) top.add(found);
  }
  _sortByScore(top);

  stdout.writeln('  → 폰 ${top.length}종');
  return top.map(_trim).toList(growable: false);
}

/// CPU·SoC: 패턴에 맞는 것만 받아 점수 있는 것을 점수순으로.
Future<List<Map<String, dynamic>>> _collectScored(
  HttpClient client,
  Directory cache, {
  required String collection,
  required List<RegExp> patterns,
  required int limit,
  bool Function(Map<String, dynamic> record)? keep,
}) async {
  final index = await _index(client, cache, collection);
  final probe = index
      .map((e) => e['slug'] as String)
      .where((s) => patterns.any((p) => p.hasMatch(s)))
      .toList(growable: false);

  stdout.writeln('  $collection 후보 ${probe.length}건 받는 중…');
  final records = await _fetchAll(client, cache, collection, probe);

  final scored = records
      .where((r) => _score(r) != null && (keep?.call(r) ?? true))
      .toList();
  _sortByScore(scored);

  final top = scored.take(limit).toList();
  stdout.writeln('  → $collection ${top.length}건');
  return top.map(_trim).toList(growable: false);
}

/// 실린 폰이 참조하는 브랜드만.
Future<List<Map<String, dynamic>>> _collectBrands(
  HttpClient client,
  Directory cache,
  List<Map<String, dynamic>> phones,
) async {
  final slugs = <String>{
    for (final p in phones)
      if ((p['brand'] as Map<String, dynamic>?)?['slug'] case final String s) s,
  }.toList(growable: false);

  stdout.writeln('  brands ${slugs.length}건 받는 중…');
  final records = await _fetchAll(client, cache, 'brands', slugs);
  records.sort((a, b) => (a['slug'] as String).compareTo(b['slug'] as String));
  return records.map(_trim).toList(growable: false);
}

double? _score(Map<String, dynamic> r) =>
    ((r['score'] as Map<String, dynamic>?)?['overall'] as num?)?.toDouble();

DateTime? _released(Map<String, dynamic> r) =>
    DateTime.tryParse(r['release_date'] as String? ?? '');

void _sortByScore(List<Map<String, dynamic>> records) {
  records.sort((a, b) {
    final byScore = (_score(b) ?? 0).compareTo(_score(a) ?? 0);
    // 동점이면 슬러그로. 순서가 흔들리면 골든과 비교 화면 기본값이 흔들린다.
    return byScore != 0
        ? byScore
        : (a['slug'] as String).compareTo(b['slug'] as String);
  });
}

Future<List<Map<String, dynamic>>> _index(
  HttpClient client,
  Directory cache,
  String collection,
) async {
  final json = await _get(
    client,
    cache,
    '$collection/index',
    '$_base/$collection/index.json',
  );
  return (json['results'] as List<dynamic>).cast<Map<String, dynamic>>();
}

/// 상세를 [_concurrency] 개씩 나눠 받는다. 실패한 것은 조용히 버린다 —
/// 인덱스에 있는데 상세가 없는 슬러그가 실제로 있다.
Future<List<Map<String, dynamic>>> _fetchAll(
  HttpClient client,
  Directory cache,
  String collection,
  List<String> slugs,
) async {
  final out = <Map<String, dynamic>>[];
  for (var i = 0; i < slugs.length; i += _concurrency) {
    final chunk = slugs.skip(i).take(_concurrency);
    final batch = await Future.wait(
      chunk.map(
        (slug) => _get(
          client,
          cache,
          '$collection/$slug',
          '$_base/$collection/$slug/index.json',
        ).then<Map<String, dynamic>?>((j) => j).catchError((_) => null),
      ),
    );
    out.addAll(batch.whereType<Map<String, dynamic>>());
    if (slugs.length > 200 && (i ~/ _concurrency) % 20 == 0) {
      stdout.write('.');
    }
  }
  if (slugs.length > 200) stdout.writeln();
  return out;
}

/// 받은 것은 캐시한다. 규칙을 고쳐 다시 돌릴 때 네트워크를 안 탄다.
Future<Map<String, dynamic>> _get(
  HttpClient client,
  Directory cache,
  String key,
  String url,
) async {
  final file = File('${cache.path}/$key.json');
  if (file.existsSync()) {
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close();
  if (res.statusCode != 200) {
    await res.drain<void>();
    throw HttpException('$url -> ${res.statusCode}');
  }
  final body = await res.transform(utf8.decoder).join();

  file.parent.createSync(recursive: true);
  file.writeAsStringSync(body);
  return jsonDecode(body) as Map<String, dynamic>;
}

/// 앱이 안 쓰는 필드를 덜어낸다. 애셋이 커질수록 앱 크기가 커진다.
Map<String, dynamic> _trim(Map<String, dynamic> record) {
  const drop = <String>{'id', 'created_at', 'updated_at', 'variant'};
  return <String, dynamic>{
    for (final e in record.entries)
      if (!drop.contains(e.key))
        e.key: e.key == 'name' && e.value is String
            ? canonicalName(e.value as String)
            : e.value,
  };
}

/// 브랜드 표기를 하나로 맞춘다.
///
/// TechAPI 는 같은 브랜드를 `Vivo` 와 `vivo`, `Oppo` 와 `OPPO` 로 섞어 준다.
/// 랭킹처럼 한 목록에 나란히 서면 고장 난 것처럼 보인다. 브랜드로 시작하는
/// 이름만 첫 낱말을 바꾸고, `iPhone`·`iQOO` 처럼 소문자로 시작하는 게 맞는
/// 표기는 그대로 둔다.
String canonicalName(String name) {
  const brands = <String, String>{
    'vivo': 'Vivo',
    'oppo': 'Oppo',
    'honor': 'Honor',
    'realme': 'Realme',
    'poco': 'POCO',
    'redmi': 'Redmi',
    'xiaomi': 'Xiaomi',
    'oneplus': 'OnePlus',
    'motorola': 'Motorola',
    'moto': 'Moto',
    'huawei': 'Huawei',
    'nothing': 'Nothing',
    'google': 'Google',
    'samsung': 'Samsung',
  };

  final space = name.indexOf(' ');
  if (space <= 0) return name;
  final head = name.substring(0, space);
  final fixed = brands[head.toLowerCase()];
  return fixed == null || fixed == head
      ? name
      : '$fixed${name.substring(space)}';
}
