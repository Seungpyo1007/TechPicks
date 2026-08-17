import '../../data/dto/smartphone.dart';

/// 이름과 브랜드로 기기를 거른다.
///
/// 픽커 안에 있던 규칙을 여기로 올렸다 — 랭킹도 같은 것을 쓴다. 검색이 두
/// 화면에서 다르게 동작하면 "삼성"으로 한쪽에서는 찾히고 한쪽에서는 안 찾힌다.
abstract final class DeviceSearch {
  /// [query] 로 거른다. 비면 그대로 돌려준다.
  ///
  /// 대소문자와 앞뒤 공백을 무시하고, 이름과 브랜드 이름 어느 쪽에 걸려도
  /// 남긴다.
  static List<Smartphone> filter(List<Smartphone> devices, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return devices;
    return devices
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              (d.brand?.name.toLowerCase().contains(q) ?? false),
        )
        .toList(growable: false);
  }

  /// 카탈로그에 실제로 있는 브랜드를 기기 수가 많은 순으로.
  ///
  /// 목록을 손으로 적어두면 카탈로그를 다시 구울 때마다 어긋난다. 브랜드가
  /// 없는 기기는 셈에서 빠진다.
  static List<String> brands(List<Smartphone> devices) {
    final counts = <String, int>{};
    for (final d in devices) {
      final name = d.brand?.name.trim();
      if (name == null || name.isEmpty) continue;
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final names = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        // 같은 수면 이름순. 카탈로그를 다시 구울 때마다 칩 순서가 흔들리면
        // 어제 눌렀던 자리가 오늘 다른 브랜드다.
        return byCount != 0 ? byCount : a.compareTo(b);
      });
    return names;
  }

  /// 브랜드 이름 [brand] 인 기기만. null 이면 그대로.
  static List<Smartphone> byBrand(List<Smartphone> devices, String? brand) {
    if (brand == null) return devices;
    return devices
        .where((d) => d.brand?.name == brand)
        .toList(growable: false);
  }
}
