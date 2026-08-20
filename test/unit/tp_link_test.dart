import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/feature/share/tp_link.dart';

/// 링크 문법.
///
/// 만드는 쪽과 받는 쪽이 같은 파일을 쓰므로, 왕복이 맞으면 공유한 링크는
/// 반드시 열린다.
void main() {
  test('기기 링크가 왕복한다', () {
    final uri = TpLink.device('galaxy-s25');
    expect(uri.toString(), 'techpicks://device/galaxy-s25');
    expect(TpLink.parse(uri), const DeviceTarget('galaxy-s25'));
  });

  test('비교 링크가 왕복한다', () {
    final uri = TpLink.compare('galaxy-s25', 'oneplus-13');
    expect(uri.toString(), 'techpicks://compare/galaxy-s25/oneplus-13');
    expect(TpLink.parse(uri), const CompareTarget('galaxy-s25', 'oneplus-13'));
  });

  test('host 없이 경로로만 와도 같은 것으로 본다', () {
    // 안드로이드가 넘겨주는 형태가 기기마다 다르다.
    expect(
      TpLink.parse(Uri.parse('techpicks:/device/galaxy-s25')),
      const DeviceTarget('galaxy-s25'),
    );
  });

  test('스킴이 대문자로 와도 받는다', () {
    // Uri 가 스킴을 소문자로 정규화한다.
    expect(
      TpLink.parse(Uri.parse('TECHPICKS://device/galaxy-s25')),
      const DeviceTarget('galaxy-s25'),
    );
  });

  test('우리 링크가 아니면 null', () {
    for (final raw in <String>[
      'techpicks://',
      'techpicks://device',
      'techpicks://device/a/b',
      'techpicks://compare/a',
      'techpicks://compare/a/b/c',
      'techpicks://알수없음/a',
    ]) {
      expect(TpLink.parse(Uri.parse(raw)), isNull, reason: raw);
    }
  });

  // 브라우저에서는 커스텀 스킴이 죽은 글자다. 같은 문법이 그냥 경로가 된다 —
  // 라우터가 쓰는 것과 여기가 읽는 것이 한 문장으로 맞는다.
  group('웹 주소', () {
    test('https 와 상대 경로를 읽는다', () {
      for (final raw in <String>[
        'https://techpicks.example/device/galaxy-s25',
        'http://localhost:8099/device/galaxy-s25',
        '/device/galaxy-s25',
        'device/galaxy-s25',
      ]) {
        expect(
          TpLink.parse(Uri.parse(raw)),
          const DeviceTarget('galaxy-s25'),
          reason: raw,
        );
      }
      expect(
        TpLink.parse(Uri.parse('https://techpicks.example/compare/a/b')),
        const CompareTarget('a', 'b'),
      );
    });

    test('도메인은 문법이 아니다', () {
      // 커스텀 스킴에서는 host 가 device·compare 지만, http 에서 host 는
      // 도메인이다. 그걸 같이 접으면 techpicks.example 이 device 로 읽힌다.
      for (final raw in <String>[
        'https://device/galaxy-s25',
        'https://techpicks.example/',
        'https://techpicks.example/알수없음/a',
        'mailto:someone@example.com',
      ]) {
        expect(TpLink.parse(Uri.parse(raw)), isNull, reason: raw);
      }
    });

    test('경로를 만들고 다시 읽는다', () {
      const targets = <TpLinkTarget>[
        DeviceTarget('galaxy-s25'),
        CompareTarget('galaxy-s25', 'oneplus-13'),
      ];
      for (final t in targets) {
        final path = TpLink.path(t);
        expect(path.startsWith('/'), isTrue, reason: path);
        expect(TpLink.parse(Uri.parse(path)), t, reason: path);
      }
    });
  });

  test('슬러그의 특수문자가 이스케이프된다', () {
    // 슬러그는 밖에서 온 문자열이다. 그대로 이으면 링크가 깨진다.
    final uri = TpLink.device('a b/c?d');
    expect(uri.pathSegments, <String>['a b/c?d']);
    expect(TpLink.parse(uri), const DeviceTarget('a b/c?d'));
  });
}
