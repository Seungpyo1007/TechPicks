/// 공유 링크의 문법.
///
/// 만드는 쪽과 받는 쪽이 같은 파일을 본다. `app_links` 나 `share_plus` 에
/// 기대지 않아 유닛 테스트가 왕복을 전부 덮는다.
///
/// ```
/// techpicks://device/galaxy-s25
/// techpicks://compare/galaxy-s25/oneplus-13
/// ```
///
/// 라우터 경로는 같은 문법에서 스킴만 뺀 것이다 (`/device/galaxy-s25`).
library;

/// 링크가 가리키는 곳.
sealed class TpLinkTarget {
  const TpLinkTarget();
}

/// 기기 하나. 상세로 연다.
class DeviceTarget extends TpLinkTarget {
  const DeviceTarget(this.slug);

  final String slug;

  @override
  bool operator ==(Object other) => other is DeviceTarget && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;

  @override
  String toString() => 'DeviceTarget($slug)';
}

/// 기기 둘. 비교 탭의 두 슬롯을 채운다.
class CompareTarget extends TpLinkTarget {
  const CompareTarget(this.a, this.b);

  final String a;
  final String b;

  @override
  bool operator ==(Object other) =>
      other is CompareTarget && other.a == a && other.b == b;

  @override
  int get hashCode => Object.hash(a, b);

  @override
  String toString() => 'CompareTarget($a, $b)';
}

abstract final class TpLink {
  static const String scheme = 'techpicks';

  static const String _device = 'device';
  static const String _compare = 'compare';

  static Uri device(String slug) =>
      Uri(scheme: scheme, host: _device, pathSegments: <String>[slug]);

  static Uri compare(String a, String b) =>
      Uri(scheme: scheme, host: _compare, pathSegments: <String>[a, b]);

  /// 라우터가 쓰는 경로. 주소창에 찍히는 것과 같은 문자열이다.
  static String path(TpLinkTarget target) => switch (target) {
    DeviceTarget(:final slug) => '/$_device/$slug',
    CompareTarget(:final a, :final b) => '/$_compare/$a/$b',
  };

  /// 우리 링크가 아니거나 형태가 안 맞으면 null.
  ///
  /// 밖에서 들어오는 값이다. 모르는 것은 조용히 버리고 앱은 평소대로 뜬다.
  static TpLinkTarget? parse(Uri uri) {
    // Uri 가 스킴을 소문자로 정규화한다.
    final parts = switch (uri.scheme) {
      // `techpicks://device/x` 는 host 에, `techpicks:/device/x` 는 경로에
      // 들어온다. 둘 다 같은 것으로 본다.
      scheme => <String>[
        if (uri.host.isNotEmpty) uri.host,
        ...uri.pathSegments.where((s) => s.isNotEmpty),
      ],
      // 브라우저에서 오는 것. 여기서 host 는 도메인이지 우리 문법이 아니다.
      'http' || 'https' || '' => <String>[
        ...uri.pathSegments.where((s) => s.isNotEmpty),
      ],
      _ => const <String>[],
    };
    if (parts.length == 2 && parts.first == _device) {
      return DeviceTarget(parts[1]);
    }
    if (parts.length == 3 && parts.first == _compare) {
      return CompareTarget(parts[1], parts[2]);
    }
    return null;
  }
}
