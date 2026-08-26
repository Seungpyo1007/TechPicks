/// TechAPI 데이터를 어디서 가져올지 결정하는 전략.
///
/// TechAPI는 두 가지 형태로 같은 데이터를 제공한다.
///
/// * **정적 덤프** — `GetTechAPI/TechEngine`의 `app/dump.py`가 실제 FastAPI
///   엔드포인트를 인프로세스로 replay해 생성한 JSON 트리. GitHub Pages로
///   서빙된다. 서버가 필요 없고 지금 유일하게 살아 있는 경로다.
/// * **REST API** — `api.techapi.dev`. 2026-08-07 기준 미배포(DNS 미해결).
///
/// 덤프가 replay로 만들어지기 때문에 **두 경로의 응답 스키마는 동일하다.**
/// 차이는 URL 조립 규칙 하나뿐이므로 그 부분만 여기서 흡수한다.
///
/// ```
/// REST   GET /v1/smartphones/galaxy-s25
/// 덤프   GET /v1/smartphones/galaxy-s25/index.json
/// ```
abstract class TechApiSource {
  const TechApiSource();

  /// 단일 레코드 URI. [collection]은 복수형(`smartphones`, `cpus` …).
  Uri detail(String collection, String slug);

  /// 컬렉션 목록 URI.
  Uri list(String collection);

  /// API 버전 인덱스 — 컬렉션별 레코드 수를 담고 있다.
  Uri index();
}

/// GitHub Pages 정적 덤프. v2의 기본 소스.
class DumpSource extends TechApiSource {
  const DumpSource({this.baseUrl = defaultBaseUrl});

  static const String defaultBaseUrl = 'https://gettechapi.github.io/TechAPI';

  final String baseUrl;

  @override
  Uri detail(String collection, String slug) =>
      Uri.parse('$baseUrl/v1/$collection/$slug/index.json');

  @override
  Uri list(String collection) =>
      Uri.parse('$baseUrl/v1/$collection/index.json');

  @override
  Uri index() => Uri.parse('$baseUrl/v1/index.json');
}

/// `api.techapi.dev` 배포 후 전환할 소스.
///
/// 덤프와 달리 쿼리 파라미터(`?limit`, `?brand`, `/search`, `/compare`)를
/// 지원하지만, 그 기능은 실제 배포 이후에 붙인다.
class RestSource extends TechApiSource {
  const RestSource({this.baseUrl = defaultBaseUrl});

  static const String defaultBaseUrl = 'https://api.techapi.dev';

  final String baseUrl;

  @override
  Uri detail(String collection, String slug) =>
      Uri.parse('$baseUrl/v1/$collection/$slug');

  @override
  Uri list(String collection) => Uri.parse('$baseUrl/v1/$collection');

  @override
  Uri index() => Uri.parse('$baseUrl/v1');
}
