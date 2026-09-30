/// 랭킹 탭 안의 카테고리. 명세 §4 의 칩 행 `Phones · Processors · Laptops`,
/// 탭 맵에서 `rank` / `cpu` / `laptop` 세 화면에 대응한다.
///
/// 셋 다 하단 탭은 Rank 로 남는다. 그래서 탭이 아니라 이 열거형으로 가른다.
enum RankCategory {
  phones('phones'),
  processors('cpus'),
  laptops('laptops');

  const RankCategory(this.key);

  /// `assets/translations/*.json` 의 번역 키. 주소 조각으로도 쓴다 —
  /// `/browse/cpus` 의 `cpus` 가 이 값이다.
  final String key;

  /// 주소에서 온 조각. 모르는 값이면 null 이고, 라우터가 폰으로 떨어뜨린다.
  static RankCategory? parse(String? key) {
    for (final value in values) {
      if (value.key == key) return value;
    }
    return null;
  }
}
