// TechAPI 에서 큐레이션한 기기 상세를 받아 `assets/catalog/v1.json` 으로 굽는다.
//
//   dart tool/build_catalog.dart
//
// 왜 필요한가. TechAPI 정적 덤프의 목록 인덱스에는 slug/name/url 만 들어 있고
// 점수가 없다. 랭킹은 점수로 정렬해야 하는데, 상세를 기기마다 받으면 93,396 번
// 요청이고 목록 전체는 19MB 다. 둘 다 앱에서 못 한다.
//
// 명세(`docs/DESIGN_HANDOFF.md` — Data model)도 같은 결론이다.
//   "Long-term this is what the planned TechPicks API should serve;
//    until then ship it as a versioned JSON asset so scores can be updated
//    without a store release."
//
// 그래서 빌드 시점에 한 번 받아 애셋으로 넣는다. 나중에 검색 API 가 생기면
// 이 파일과 여기에 기대는 리포지토리만 걷어내면 된다.
import 'dart:convert';
import 'dart:io';

const String _base = 'https://gettechapi.github.io/TechAPI/v1';

/// 랭킹·홈·비교에 실을 기기. 2025 플래그십 위주.
///
/// 슬러그는 TechAPI 에 실제로 있는 것만 골랐다. 없는 슬러그는 404 로 떨어지고
/// 스크립트가 실패한다 — 조용히 빠지는 것보다 낫다.
const List<String> _phones = <String>[
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

/// Processors 화면의 Laptop 세그먼트. 명세가 5행을 요구한다.
///
/// 데스크톱 CPU 는 뺐다. 명세의 세그먼트는 Mobile / Laptop 둘뿐이라
/// `ryzen-9-9950x3d`, `core-i9-14900k` 는 실을 화면이 없다.
const List<String> _cpus = <String>[
  'core-i9-14900hx',
  'ryzen-9-7945hx',
  'ryzen-ai-9-hx-370',
  'ryzen-ai-9-365',
  'snapdragon-x-elite-x1e-84-100',
];

/// Mobile 세그먼트. 카탈로그 폰들이 쓰는 칩 위주로 골랐다.
const List<String> _socs = <String>[
  'snapdragon-8-elite',
  'dimensity-9400',
  'apple-a18-pro',
  'exynos-2500',
  'snapdragon-8-gen-3',
];

Future<void> main() async {
  final client = HttpClient();
  final catalog = <String, dynamic>{
    'version': 1,
    // 데이터 출처 표기는 CC-BY-SA 4.0 의무 사항이라 애셋에도 박아둔다.
    'source': 'TechAPI (CC-BY-SA 4.0) — https://github.com/GetTechAPI/TechAPI',
  };

  for (final entry in <String, List<String>>{
    'smartphones': _phones,
    'cpus': _cpus,
    'socs': _socs,
  }.entries) {
    final records = <Map<String, dynamic>>[];
    for (final slug in entry.value) {
      final json = await _get(client, '$_base/${entry.key}/$slug/index.json');
      records.add(_trim(json));
      stdout.writeln('  ${entry.key}/$slug');
    }
    catalog[entry.key] = records;
  }

  client.close();

  final out = File('assets/catalog/v1.json');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(catalog)}\n');

  final kb = (out.lengthSync() / 1024).toStringAsFixed(1);
  stdout.writeln('\n${out.path} · ${kb}KB');
}

Future<Map<String, dynamic>> _get(HttpClient client, String url) async {
  final req = await client.getUrl(Uri.parse(url));
  final res = await req.close();
  if (res.statusCode != 200) {
    stderr.writeln('$url -> ${res.statusCode}');
    exit(1);
  }
  final body = await res.transform(utf8.decoder).join();
  return jsonDecode(body) as Map<String, dynamic>;
}

/// 앱이 안 쓰는 필드를 덜어낸다. 애셋이 커질수록 앱 크기가 커진다.
Map<String, dynamic> _trim(Map<String, dynamic> record) {
  const drop = <String>{'id', 'created_at', 'updated_at', 'variant'};
  return <String, dynamic>{
    for (final e in record.entries)
      if (!drop.contains(e.key)) e.key: e.value,
  };
}
