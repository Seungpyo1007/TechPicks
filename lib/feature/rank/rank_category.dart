/// 랭킹 탭 안의 카테고리. 명세 §4 의 칩 행 `Phones · Processors · Laptops`,
/// 탭 맵에서 `rank` / `cpu` / `laptop` 세 화면에 대응한다.
///
/// 셋 다 하단 탭은 Rank 로 남는다. 그래서 탭이 아니라 이 열거형으로 가른다.
enum RankCategory {
  phones('phones'),
  processors('cpus'),
  laptops('laptops');

  const RankCategory(this.key);

  /// `assets/translations/*.json` 의 번역 키.
  final String key;
}
