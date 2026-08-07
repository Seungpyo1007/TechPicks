import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dto/smartphone.dart';

import '../data/repository/catalog_repository.dart';
import '../data/repository/tech_api_repository.dart';
import '../domain/model/ranking.dart';
import '../domain/model/tp_weights.dart';

/// 앱에 실린 큐레이션 카탈로그. 랭킹·홈·비교가 여기서 목록을 받는다.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(),
);

/// TechAPI 원격. 카탈로그에 없는 기기를 상세로 열 때 쓴다.
final techApiRepositoryProvider = Provider<TechApiRepository>(
  (ref) => TechApiRepository(),
);

final catalogProvider = FutureProvider<Catalog>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).load();
  return result.fold(
    (c) => c,
    (f) => throw f,
  );
});

/// 사용자 가중치.
///
/// 화면 여러 곳이 이걸 읽는다. You 화면에서 슬라이더를 움직이면 랭킹·홈·상세의
/// 지수가 한꺼번에 다시 계산되어야 하므로 앱 전역 상태다.
///
/// 아직 저장은 붙이지 않았다. You 화면을 만들 때 SharedPreferences 로 잇는다.
class WeightsNotifier extends Notifier<TpWeights> {
  @override
  TpWeights build() => TpWeights.defaults;

  void set(TpWeights next) => state = next;

  void reset() => state = TpWeights.defaults;
}

final weightsProvider =
    NotifierProvider<WeightsNotifier, TpWeights>(WeightsNotifier.new);

/// 랭킹 화면에서 고른 정렬 축.
class RankAxisNotifier extends Notifier<RankAxis> {
  @override
  RankAxis build() => RankAxis.tpIndex;

  void set(RankAxis axis) => state = axis;
}

final rankAxisProvider =
    NotifierProvider<RankAxisNotifier, RankAxis>(RankAxisNotifier.new);

/// 현재 축과 가중치로 세운 순위.
final rankedPhonesProvider = Provider<List<RankedDevice>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const <RankedDevice>[];
  return Ranking.of(
    catalog.smartphones,
    ref.watch(rankAxisProvider),
    ref.watch(weightsProvider),
  );
});

/// 비교 중인 기기 목록. 홈 화면의 주인공이다.
///
/// 저장은 SharedPreferences 로 한다. 명세는 Firestore 도 후보로 적었지만,
/// 로그인 없이도 쓸 수 있어야 하는 화면이라 로컬이 먼저다.
class ShortlistNotifier extends Notifier<List<String>> {
  static const String _prefsKey = 'shortlist_slugs';

  @override
  List<String> build() {
    unawaited(_restore());
    return const <String>[];
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null && saved.isNotEmpty) state = saved;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state);
  }

  bool contains(String slug) => state.contains(slug);

  void toggle(String slug) {
    state = state.contains(slug)
        ? <String>[...state.where((s) => s != slug)]
        : <String>[...state, slug];
    unawaited(_persist());
  }

  void remove(String slug) {
    state = <String>[...state.where((s) => s != slug)];
    unawaited(_persist());
  }
}

final shortlistProvider =
    NotifierProvider<ShortlistNotifier, List<String>>(ShortlistNotifier.new);

/// 기기 하나. 카탈로그에 있으면 그걸 쓰고, 없으면 TechAPI 에서 받는다.
///
/// 카탈로그는 큐레이션한 일부라 랭킹·홈에 충분하지만, 상세는 그 밖의 기기도
/// 열려야 한다.
final deviceProvider = FutureProvider.family<Smartphone, String>((ref, slug) async {
  final catalog = await ref.watch(catalogProvider.future);
  final local = catalog.smartphones.where((d) => d.slug == slug);
  if (local.isNotEmpty) return local.first;

  final result = await ref.watch(techApiRepositoryProvider).smartphone(slug);
  return result.fold((d) => d, (f) => throw f);
});
