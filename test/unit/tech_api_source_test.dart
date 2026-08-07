import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/core/network/tech_api_source.dart';

void main() {
  group('DumpSource', () {
    const source = DumpSource();

    test('상세 경로 끝에 /index.json이 붙는다', () {
      expect(
        source.detail('smartphones', 'galaxy-s25').toString(),
        'https://gettechapi.github.io/TechAPI/v1/smartphones/galaxy-s25/index.json',
      );
    });

    test('목록과 인덱스도 디렉터리 형태다', () {
      expect(
        source.list('cpus').toString(),
        'https://gettechapi.github.io/TechAPI/v1/cpus/index.json',
      );
      expect(
        source.index().toString(),
        'https://gettechapi.github.io/TechAPI/v1/index.json',
      );
    });

    test('baseUrl을 바꾸면 로컬 덤프도 가리킬 수 있다', () {
      const local = DumpSource(baseUrl: 'http://localhost:4321');
      expect(
        local.detail('gpus', 'geforce-rtx-5090').toString(),
        'http://localhost:4321/v1/gpus/geforce-rtx-5090/index.json',
      );
    });
  });

  group('RestSource', () {
    const source = RestSource();

    test('덤프와 달리 /index.json이 없다', () {
      expect(
        source.detail('smartphones', 'galaxy-s25').toString(),
        'https://api.techapi.dev/v1/smartphones/galaxy-s25',
      );
      expect(source.list('cpus').toString(), 'https://api.techapi.dev/v1/cpus');
    });
  });

  test('두 소스의 차이는 /index.json 접미사뿐이다', () {
    // 덤프가 실제 엔드포인트를 replay해 만들어지므로 응답 스키마는 동일하다.
    // 전환 시 바뀌는 지점이 URL 조립 하나뿐임을 고정한다.
    //
    // 기본 DumpSource는 GitHub Pages 하위 경로(/TechAPI)를 갖기 때문에
    // 규칙만 비교하려고 같은 호스트 기준으로 맞춘다.
    const dump = DumpSource(baseUrl: 'https://api.techapi.dev');
    const rest = RestSource();

    for (final (collection, slug) in const [
      ('socs', 'snapdragon-8-elite'),
      ('smartphones', 'galaxy-s25'),
      ('cpus', 'ryzen-9-9950x3d'),
    ]) {
      expect(
        dump.detail(collection, slug).toString(),
        '${rest.detail(collection, slug)}/index.json',
      );
    }
    expect(dump.list('gpus').toString(), '${rest.list('gpus')}/index.json');
  });

  test('기본 덤프 주소는 GitHub Pages 하위 경로를 포함한다', () {
    // 리포지토리가 이 경로를 그대로 쓰므로 회귀를 막는다.
    expect(DumpSource.defaultBaseUrl, 'https://gettechapi.github.io/TechAPI');
    expect(const DumpSource().index().path, '/TechAPI/v1/index.json');
  });
}
