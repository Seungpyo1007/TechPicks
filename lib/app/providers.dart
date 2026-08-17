import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics.dart';
import '../core/error_reporter.dart';
import '../data/dto/smartphone.dart';

import '../data/repository/catalog_repository.dart';
import '../data/repository/catalog_source.dart';
import '../data/repository/tech_api_repository.dart';
import '../data/service/ask_service.dart';
import '../data/service/auth_service.dart';
import '../data/service/connectivity_service.dart';
import '../data/service/deep_link_service.dart';
import '../data/service/device_info_service.dart';
import '../data/service/link_opener.dart';
import '../data/service/share_service.dart';
import '../data/service/shortlist_sync_service.dart';
import '../domain/model/ask_answer.dart';
import '../domain/model/device_search.dart';
import '../domain/model/device_specs.dart';
import '../domain/model/movers.dart';
import '../domain/model/scan_match.dart';
import '../domain/model/tp_index.dart';
import '../domain/model/processor.dart';
import '../domain/model/ranking.dart';
import '../domain/model/tp_weights.dart';
import '../feature/rank/rank_category.dart';
import '../feature/share/tp_link.dart';
import '../shared/copy_keys.dart';
import 'locale_controller.dart';

/// 카탈로그. 애셋으로 시작하고, 받아둔 것이 있으면 그걸 먼저 읽는다.
///
/// Remote Config 에 `catalog_url` 이 비어 있는 동안은 애셋만 쓴다 — 지금까지와
/// 똑같이 동작한다.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    store: const FileCatalogStore(),
    feed: RemoteConfigCatalogFeed(),
  ),
);

/// TechAPI 원격. 카탈로그에 없는 기기를 상세로 열 때 쓴다.
final techApiRepositoryProvider = Provider<TechApiRepository>(
  (ref) => TechApiRepository(),
);

final catalogProvider = FutureProvider<Catalog>(
  (ref) async {
    final result = await ref.watch(catalogRepositoryProvider).load();
    return result.fold((c) => c, (f) => throw f);
  },
  // 앱에 같이 실린 파일이라 재시도해도 결과가 달라지지 않는다. Riverpod 3 의
  // 기본 재시도를 켜두면 실패한 뒤에도 상태가 계속 `AsyncLoading` 이라
  // 화면이 영원히 로딩으로 보인다.
  retry: (_, _) => null,
);

/// 사용자 가중치.
///
/// 저장값 복원과 사람의 조작이 겹치면 사람이 이긴다.
///
/// 노티파이어들이 `build()` 에서 복원을 비동기로 시작한다. 그 사이에 사람이
/// 먼저 고치면 늦게 도착한 저장값이 그걸 덮는다 — 방금 담은 기기가 화면에서도
/// 디스크에서도 사라진다. 고치는 쪽은 [touch] 를 부르고, 복원은 [touched] 면
/// 아무것도 안 한다.
mixin RestoreGuard {
  bool _touched = false;

  bool get touched => _touched;

  void touch() => _touched = true;
}

/// 화면 여러 곳이 이걸 읽는다. You 화면에서 슬라이더를 움직이면 랭킹·홈·상세의
/// 지수가 한꺼번에 다시 계산되어야 하므로 앱 전역 상태다.
class WeightsNotifier extends Notifier<TpWeights> with RestoreGuard {
  static const String _prefsKey = 'tp_weights';

  @override
  TpWeights build() {
    unawaited(_restore());
    // 미뤄둔 쓰기가 있으면 사라지기 전에 내보낸다.
    ref.onDispose(() {
      _saveTimer?.cancel();
      final pending = _unsaved;
      if (pending != null) unawaited(_write(pending));
    });
    return TpWeights.defaults;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = TpWeights.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e, st) {
      // 저장값이 깨졌으면 기본값을 그대로 둔다. FormatException 만 잡으면
      // 배열이나 타입이 다른 필드가 들어왔을 때 TypeError 로 새어 나간다.
      TpErrors.record(e, st, reason: 'weights.restore');
    }
  }

  /// 값을 인자로 받는다. 버려진 뒤에 불릴 수 있어서 state 를 읽으면 터진다.
  Future<void> _write(TpWeights value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(value.toJson()));
  }

  /// 저장을 모아서 한 번에 한다.
  ///
  /// 슬라이더는 끄는 동안 픽셀마다 [set] 을 부른다. 그대로 두면 한 번
  /// 끌 때마다 SharedPreferences 에 백 번 가까이 쓴다. 화면은 즉시
  /// 바뀌어야 하니 state 는 그대로 두고 쓰기만 미룬다.
  static const Duration saveDelay = Duration(milliseconds: 400);
  Timer? _saveTimer;

  /// 아직 안 쓴 값. 버려질 때 이걸 내보낸다 — 그 시점엔 state 를 못 읽는다.
  TpWeights? _unsaved;

  void set(TpWeights next) {
    touch();
    state = next;
    _unsaved = next;
    _saveTimer?.cancel();
    _saveTimer = Timer(saveDelay, () {
      _unsaved = null;
      final axis = _pendingAxis;
      _pendingAxis = null;
      if (axis != null) {
        TpAnalytics.weightChanged(axis.kind.name, axis.value);
      }
      unawaited(_write(next));
    });
  }

  /// 아직 안 보낸 축 변경. 손을 뗀 뒤 한 번만 보낸다.
  ({TpAxisKind kind, double value})? _pendingAxis;

  /// 축 하나만 바꾼다. 슬라이더가 이걸 부른다.
  void setAxis(TpAxisKind kind, double value) {
    // 슬라이더는 끄는 동안 픽셀마다 이걸 부른다. 그대로 보내면 한 번 끌 때
    // 이벤트가 백 개 나가고, 사람이 고른 적 없는 중간값이 분포를 덮는다.
    _pendingAxis = (kind: kind, value: value);
    set(switch (kind) {
      TpAxisKind.performance => state.copyWith(performance: value),
      TpAxisKind.camera => state.copyWith(camera: value),
      TpAxisKind.display => state.copyWith(display: value),
      TpAxisKind.battery => state.copyWith(battery: value),
      TpAxisKind.value => state.copyWith(value: value),
    });
  }

  void reset() {
    TpAnalytics.weightsReset();
    set(TpWeights.defaults);
  }
}

final weightsProvider = NotifierProvider<WeightsNotifier, TpWeights>(
  WeightsNotifier.new,
);

/// 랭킹 화면에서 고른 정렬 축.
class RankAxisNotifier extends Notifier<RankAxis> {
  @override
  RankAxis build() => RankAxis.tpIndex;

  void set(RankAxis axis) {
    TpAnalytics.rankAxisChanged(axis.name);
    state = axis;
  }
}

final rankAxisProvider = NotifierProvider<RankAxisNotifier, RankAxis>(
  RankAxisNotifier.new,
);

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

/// 랭킹 검색어.
///
/// 랭킹은 50행에서 잘린다. 카탈로그가 200종이라 51위 아래의 기기는 스크롤로도
/// 못 찾았다 — 픽커에만 있던 검색을 여기에도 준다.
class RankQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final rankQueryProvider = NotifierProvider<RankQueryNotifier, String>(
  RankQueryNotifier.new,
);

/// 고른 브랜드. null 이면 전부.
class RankBrandNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// 누른 브랜드를 다시 누르면 풀린다.
  void toggle(String brand) => state = state == brand ? null : brand;
}

final rankBrandProvider = NotifierProvider<RankBrandNotifier, String?>(
  RankBrandNotifier.new,
);

/// 카탈로그에 실제로 있는 브랜드. 기기가 많은 순이다.
final rankBrandsProvider = Provider<List<String>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const <String>[];
  return DeviceSearch.brands(catalog.smartphones);
});

/// 검색어와 브랜드로 거른 순위.
///
/// **순위 번호는 거르기 전 것을 그대로 쓴다.** 걸러 놓고 1번부터 다시 매기면
/// "삼성 중 1위"가 "전체 1위"처럼 보인다.
final rankVisibleProvider = Provider<List<RankedDevice>>((ref) {
  final ranked = ref.watch(rankedPhonesProvider);
  final query = ref.watch(rankQueryProvider).trim().toLowerCase();
  final brand = ref.watch(rankBrandProvider);
  if (query.isEmpty && brand == null) return ranked;

  return ranked
      .where(
        (r) =>
            (brand == null || r.device.brand?.name == brand) &&
            (query.isEmpty ||
                r.device.name.toLowerCase().contains(query) ||
                (r.device.brand?.name.toLowerCase().contains(query) ?? false)),
      )
      .toList(growable: false);
});

/// 랭킹 탭 안에서 보고 있는 카테고리.
class RankCategoryNotifier extends Notifier<RankCategory> {
  @override
  RankCategory build() => RankCategory.phones;

  void set(RankCategory category) => state = category;
}

final rankCategoryProvider =
    NotifierProvider<RankCategoryNotifier, RankCategory>(
      RankCategoryNotifier.new,
    );

/// Processors 화면의 세그먼트.
class ProcessorSegmentNotifier extends Notifier<ProcessorSegment> {
  @override
  ProcessorSegment build() => ProcessorSegment.mobile;

  void set(ProcessorSegment segment) => state = segment;
}

final processorSegmentProvider =
    NotifierProvider<ProcessorSegmentNotifier, ProcessorSegment>(
      ProcessorSegmentNotifier.new,
    );

/// 현재 세그먼트의 프로세서 순위.
final rankedProcessorsProvider = Provider<List<RankedProcessor>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const <RankedProcessor>[];
  final segment = ref.watch(processorSegmentProvider);
  return ProcessorRanking.of(switch (segment) {
    ProcessorSegment.mobile =>
      catalog.socs.map(Processor.fromSoc).toList(growable: false),
    ProcessorSegment.laptop =>
      catalog.cpus.map(Processor.fromCpu).toList(growable: false),
  });
});

/// 비교 중인 기기 목록. 홈 화면의 주인공이다.
///
/// 저장은 SharedPreferences 로 한다. 명세는 Firestore 도 후보로 적었지만,
/// 로그인 없이도 쓸 수 있어야 하는 화면이라 로컬이 먼저다.
class ShortlistNotifier extends Notifier<List<String>> with RestoreGuard {
  static const String _prefsKey = 'shortlist_slugs';

  /// 마지막으로 고친 시각. 계정에 올라간 것과 어느 쪽이 새로운지 가린다.
  static const String _stampKey = 'shortlist_updated_at';

  @override
  List<String> build() {
    _restored = _restore();
    return const <String>[];
  }

  /// 복원이 끝났는지. 로그인 병합이 이걸 기다린다 — 안 기다리면 빈 목록을
  /// 계정에 올려 덮을 수 있다.
  Future<void> _restored = Future<void>.value();

  Future<void> get ready => _restored;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    final saved = prefs.getStringList(_prefsKey);
    if (saved != null && saved.isNotEmpty) state = saved;
  }

  Future<void> _persist() async {
    // 쓸 값을 await 앞에서 잡는다. 뒤에서 state 를 읽으면 그 사이에 끼어든
    // 복원이 방금 담은 기기 대신 옛 목록을 디스크에 남긴다.
    final slugs = state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, slugs);
    await prefs.setInt(_stampKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// 이 기기에서 마지막으로 고친 시각. 한 번도 안 건드렸으면 null.
  Future<DateTime?> lastChanged() async {
    final millis = (await SharedPreferences.getInstance()).getInt(_stampKey);
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// 계정에 올라가 있던 것을 그대로 받아 쓴다. 시각도 그쪽 것을 남긴다.
  Future<void> adopt(List<String> slugs, DateTime at) async {
    touch();
    state = List<String>.unmodifiable(slugs);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, slugs);
    await prefs.setInt(_stampKey, at.millisecondsSinceEpoch);
  }

  bool contains(String slug) => state.contains(slug);

  void toggle(String slug) {
    touch();
    final added = !state.contains(slug);
    state = added
        ? <String>[...state, slug]
        : <String>[...state.where((s) => s != slug)];
    TpAnalytics.shortlistChanged(added: added, size: state.length);
    unawaited(_persist());
  }

  void remove(String slug) {
    touch();
    state = <String>[...state.where((s) => s != slug)];
    unawaited(_persist());
  }
}

final shortlistProvider = NotifierProvider<ShortlistNotifier, List<String>>(
  ShortlistNotifier.new,
);

/// 기기 하나. 카탈로그에 있으면 그걸 쓰고, 없으면 TechAPI 에서 받는다.
///
/// 카탈로그는 큐레이션한 일부라 랭킹·홈에 충분하지만, 상세는 그 밖의 기기도
/// 열려야 한다.
final deviceProvider = FutureProvider.family<Smartphone, String>(
  (ref, slug) async {
    final catalog = await ref.watch(catalogProvider.future);
    final local = catalog.smartphones.where((d) => d.slug == slug);
    if (local.isNotEmpty) return local.first;

    final result = await ref.watch(techApiRepositoryProvider).smartphone(slug);
    return result.fold((d) => d, (f) => throw f);
  },
  // 조용히 재시도하면 상태가 계속 `AsyncLoading` 이라 화면이 뼈대만 보인다.
  // 실패는 실패로 보여주고, 다시 받는 건 에러 카드의 버튼이 할 일이다.
  retry: (_, _) => null,
);

/// 비교 화면의 두 슬롯.
///
/// 명세는 cmpA / cmpB 두 상태로 두고 picker 가 pickSlot 에 따라 한쪽만
/// 덮어쓴다. 같은 구조 그대로 간다.
class CompareSlots {
  const CompareSlots({this.a, this.b});

  final String? a;
  final String? b;

  CompareSlots write(CompareSide side, String slug) => side == CompareSide.a
      ? CompareSlots(a: slug, b: b)
      : CompareSlots(a: a, b: slug);

  String? operator [](CompareSide side) => side == CompareSide.a ? a : b;

  bool get isComplete => a != null && b != null;
}

class CompareNotifier extends Notifier<CompareSlots> {
  @override
  CompareSlots build() {
    // 카탈로그가 오면 지수 1·2위로 채운다. 빈 비교 화면부터 보여주는 것보다
    // 뭔가 비교하고 있는 상태로 시작하는 편이 낫다. 애셋 순서(원점수)로
    // 채우면 화면에 찍히는 지수와 어긋난 둘이 올라온다.
    //
    // watch 로 읽으면 카탈로그가 도착할 때 이 노티파이어가 통째로 다시
    // 만들어져 **그 사이에 고른 것이 지워진다.** 딥링크로 연 비교가 몇
    // 프레임 뒤 기본값으로 덮였다. 그래서 읽기만 하고, 나중 도착은 아직
    // 아무것도 안 골랐을 때만 채운다.
    ref.listen(indexRankingProvider, (_, next) {
      if (state.isComplete) return;
      state = _defaults(next);
    });
    return _defaults(ref.read(indexRankingProvider));
  }

  static CompareSlots _defaults(List<RankedDevice> ranked) => ranked.length < 2
      ? const CompareSlots()
      : CompareSlots(a: ranked[0].device.slug, b: ranked[1].device.slug);

  void pick(CompareSide side, String slug) {
    final other = side == CompareSide.a ? CompareSide.b : CompareSide.a;
    // 비교가 실제로 쓰이는지 세는 유일한 자리다. 이벤트만 만들어 두고
    // 아무 데서도 안 불러서 사용량이 영원히 0 으로 보고되고 있었다.
    final counterpart = state[other];
    if (counterpart != null && counterpart != slug) {
      TpAnalytics.compared(
        side == CompareSide.a ? slug : counterpart,
        side == CompareSide.a ? counterpart : slug,
      );
    }
    // 같은 기기를 두 열에 놓으면 모든 줄이 같아 비교가 아니게 된다.
    // 반대쪽에 있던 걸 다시 고른 것이므로 둘을 맞바꾼다.
    if (state[other] == slug) {
      state = CompareSlots(a: state.b, b: state.a);
      return;
    }
    state = state.write(side, slug);
  }
}

final compareProvider = NotifierProvider<CompareNotifier, CompareSlots>(
  CompareNotifier.new,
);

/// 어느 슬롯을 고르는 중인지. picker 가 읽는다.
class PickSlotNotifier extends Notifier<CompareSide> {
  @override
  CompareSide build() => CompareSide.a;

  void set(CompareSide side) => state = side;
}

final pickSlotProvider = NotifierProvider<PickSlotNotifier, CompareSide>(
  PickSlotNotifier.new,
);

/// 현재 두 슬롯의 비교 결과.
final comparisonProvider = Provider<List<SpecPair>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  final slots = ref.watch(compareProvider);
  if (catalog == null || !slots.isComplete) return const <SpecPair>[];

  Smartphone? find(String? slug) {
    final hit = catalog.smartphones.where((d) => d.slug == slug);
    return hit.isEmpty ? null : hit.first;
  }

  final a = find(slots.a);
  final b = find(slots.b);
  if (a == null || b == null) return const <SpecPair>[];
  return DeviceComparison.of(a, b, ref.watch(weightsProvider));
});

/// 지난번에 본 TP Index 순위. Movers 를 내려면 비교 대상이 필요하다.
class RankSnapshotNotifier extends Notifier<List<String>> {
  static const String _prefsKey = 'rank_snapshot_slugs';

  @override
  List<String> build() {
    // 리스너가 잠깐 없어도 살려 둔다. TabHost 가 initState 에서 read 로
    // 먼저 만드는데, 그때 버려졌다가 다시 만들어지면 복원이 저장 뒤로
    // 밀려 이번 실행의 변동이 항상 0 이 된다.
    ref.keepAlive();
    _restored = _restore();
    return const <String>[];
  }

  /// 복원이 끝났는지. 저장은 이걸 기다린다.
  late Future<void> _restored;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = prefs.getStringList(_prefsKey) ?? const <String>[];
  }

  bool _saved = false;

  /// 지금 순위를 다음 실행의 비교 대상으로 남긴다.
  ///
  /// state 는 건드리지 않는다. 이번 실행의 Movers 는 복원해둔 지난 순위와
  /// 비교해야 하는데, 여기서 state 까지 덮으면 변동이 항상 0 이 된다.
  Future<void> save(List<String> slugs) async {
    // 복원보다 먼저 쓰면 지난 순위를 지우고 그걸 읽는다.
    await _restored;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, slugs);
  }

  /// 실행당 한 번만 남긴다.
  ///
  /// 카탈로그가 늦게 오거나 화면을 오갈 때 여러 번 불릴 수 있는데, 두 번째
  /// 부터는 쓸 이유가 없다.
  Future<void> saveOnce(List<String> slugs) async {
    if (_saved || slugs.isEmpty) return;
    _saved = true;
    await save(slugs);
  }
}

final rankSnapshotProvider =
    NotifierProvider<RankSnapshotNotifier, List<String>>(
      RankSnapshotNotifier.new,
    );

/// 기본 가중치 기준 TP Index 순위.
///
/// 변동은 이 기준이다. 사용자가 슬라이더를 만질 때마다 "이번 주 변동"이
/// 바뀌면 그건 시간 변화가 아니라 취향 변화다.
final indexRankingProvider = Provider<List<RankedDevice>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const <RankedDevice>[];
  return Ranking.of(catalog.smartphones, RankAxis.tpIndex);
});

/// 다음 실행에 남길 순위. 스냅샷과 Movers 가 같은 목록을 봐야 한다.
final rankSnapshotSlugsProvider = Provider<List<String>>(
  (ref) => ref
      .watch(indexRankingProvider)
      .map((r) => r.device.slug)
      .toList(growable: false),
);

/// 이번 주 변동. 저장된 순위가 없으면 빈 목록이라 섹션이 통째로 빠진다.
final moversProvider = Provider<List<Mover>>((ref) {
  return Movers.between(
    previous: ref.watch(rankSnapshotProvider),
    current: ref
        .watch(indexRankingProvider)
        .map((r) => (slug: r.device.slug, name: r.device.name))
        .toList(growable: false),
  );
});

/// shortlist 에 담긴 기기 중 지수가 가장 높은 것. 홈의 결론 카드가 쓴다.
final verdictProvider = Provider<Smartphone?>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  final slugs = ref.watch(shortlistProvider);
  if (catalog == null || slugs.isEmpty) return null;

  final picked = catalog.smartphones.where((d) => slugs.contains(d.slug));
  if (picked.isEmpty) return null;

  final weights = ref.watch(weightsProvider);
  final ranked = Ranking.of(
    picked.toList(growable: false),
    RankAxis.tpIndex,
    weights,
  );
  return ranked.first.device;
});

/// shortlist 순서대로의 기기 목록.
final shortlistDevicesProvider = Provider<List<Smartphone>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  final slugs = ref.watch(shortlistProvider);
  if (catalog == null) return const <Smartphone>[];

  final by = <String, Smartphone>{
    for (final d in catalog.smartphones) d.slug: d,
  };
  return <Smartphone>[
    for (final slug in slugs)
      if (by[slug] != null) by[slug]!,
  ];
});

/// AI 상담.
///
/// Firebase 가 떠 있으면 Gemini 에게 먼저 묻고, 못 부르면 카탈로그만으로
/// 답하는 로컬 구현이 받는다. 오래 로컬만 쓰다 보니 상담 탭이 모델을 한 번도
/// 부르지 않는 상태였다 — 명세 §12 의 화면은 그대로인데 답이 가짜였다.
final askServiceProvider = Provider<AskService>((ref) {
  final local = LocalAskService(weights: ref.watch(weightsProvider));
  if (!_firebaseReady) return local;
  return FallbackAskService(
    GeminiAskService(weights: ref.watch(weightsProvider)),
    local,
  );
});

/// Firebase 가 초기화됐는지.
///
/// 안 떠 있으면 `FirebaseAI` 를 만드는 순간 던진다. 위젯 테스트처럼 플러그인이
/// 아예 없는 환경에서는 조회 자체가 던지므로 그것도 없는 것으로 본다.
bool get _firebaseReady {
  try {
    return Firebase.apps.isNotEmpty;
  } catch (_) {
    return false;
  }
}

/// 대화 내용.
/// 답을 기다리는 중인지.
///
/// 노티파이어 안의 필드로만 두면 화면이 못 읽는다. 그래서 기다리는 동안
/// 아무 표시가 없었고, 그 사이에 보낸 두 번째 질문은 조용히 버려졌다.
class AskBusyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final askBusyProvider = NotifierProvider<AskBusyNotifier, bool>(
  AskBusyNotifier.new,
);

class AskNotifier extends Notifier<List<AskMessage>> {
  @override
  List<AskMessage> build() => <AskMessage>[AskMessage.ai(K.chatSeed.tr())];

  bool _busy = false;

  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || _busy) return;

    _busy = true;
    ref.read(askBusyProvider.notifier).set(true);
    // 사용자 말풍선을 먼저 올린다. 응답을 기다리는 동안 화면이 멈춘 것처럼
    // 보이지 않게 한다.
    state = <AskMessage>[...state, AskMessage.user(text)];

    // 카탈로그를 못 읽으면 답할 근거가 없다. 예외를 그대로 올리면 화면이
    // 멈춘 것처럼 보이고 _busy 도 안 풀린다.
    AskAnswer? answer;
    try {
      final catalog = await ref.read(catalogProvider.future);
      answer = await ref
          .read(askServiceProvider)
          .ask(text, catalog.smartphones);
    } catch (e, st) {
      TpErrors.record(e, st, reason: 'ask.send');
      answer = null;
    }

    _busy = false;
    if (ref.mounted) ref.read(askBusyProvider.notifier).set(false);
    TpAnalytics.asked(length: text.length, answered: answer != null);
    // 답이 오는 동안 화면을 떠났을 수 있다.
    if (!ref.mounted) return;
    state = <AskMessage>[
      ...state,
      answer == null
          ? AskMessage.ai(K.askFailed.tr(), failed: true)
          : AskMessage.ai(answer.pick, answer: answer),
    ];
  }

  /// 비교 화면의 "왜?" 에서 넘어올 때 두 기기를 물어봐 준다.
  ///
  /// 질문만 올려두면 답 없는 말풍선이 남는다. [send] 를 그대로 태워서
  /// 사용자가 직접 친 것과 같은 흐름으로 만든다.
  Future<void> askAbout(String a, String b) => send('$a or $b?');
}

final askProvider = NotifierProvider<AskNotifier, List<AskMessage>>(
  AskNotifier.new,
);

/// 인증. 기본은 Firebase 구현이다.
final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(),
);

/// 지금 로그인한 사람. 로그인·로그아웃할 때 갱신한다.
class CurrentUserNotifier extends Notifier<TpUser?> {
  @override
  TpUser? build() {
    final auth = ref.watch(authServiceProvider);
    // 켠 순간의 값만 읽으면, 저장된 세션이 늦게 복원되는 동안 로그인 화면이
    // 뜨고 관심 목록 동기화도 안 붙는다. 다른 기기에서 로그아웃한 것도
    // 다음 실행까지 모른다.
    final sub = auth.changes().listen((user) {
      if (ref.mounted) state = user;
    });
    ref.onDispose(sub.cancel);
    return auth.current;
  }

  Future<SignInOutcome> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    final TpUser? user;
    try {
      user = await ref
          .read(authServiceProvider)
          .signIn(method, email: email, password: password);
    } on AuthCanceled {
      return SignInOutcome.canceled;
    }
    if (user != null && ref.mounted) state = user;
    return user == null ? SignInOutcome.failed : SignInOutcome.ok;
  }

  Future<bool> signUp(String email, String password) async {
    final user = await ref
        .read(authServiceProvider)
        .signUp(email: email, password: password);
    if (user != null && ref.mounted) state = user;
    return user != null;
  }

  /// 비밀번호 재설정 메일. 로그인한 사람의 주소로만 보낸다.
  Future<bool> sendPasswordReset() async {
    final email = state?.email;
    if (email == null || email.isEmpty) return false;
    return ref.read(authServiceProvider).sendPasswordReset(email);
  }

  /// 표시 이름을 바꾼다.
  Future<bool> updateName(String name) async {
    final user = await ref.read(authServiceProvider).updateName(name.trim());
    if (user == null) return false;
    if (ref.mounted) state = user;
    return true;
  }

  Future<void> signOut() async {
    // 화면을 먼저 되돌린다.
    //
    // Firebase 를 기다렸다가 비우면, 그쪽이 안 돌아오는 설정에서 로그아웃을
    // 눌러도 아무 일이 안 일어난다. 시뮬레이터에서 실제로 그랬다. 누른 대로
    // 나가는 것이 먼저다 — 실패하면 다음 실행에 세션이 복원될 뿐이다.
    state = null;
    await ref.read(authServiceProvider).signOut();
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, TpUser?>(
  CurrentUserNotifier.new,
);

/// 온보딩을 봤는지. v1 의 is_tutorial_completed 키를 그대로 쓴다.
class OnboardingNotifier extends Notifier<bool?> with RestoreGuard {
  static const String _prefsKey = 'is_tutorial_completed';

  /// null 은 "아직 안 읽었다" 다.
  ///
  /// false 로 시작하면 앱을 켤 때마다 온보딩이 한 프레임 스쳐 지나간다.
  /// 저장값은 뒤늦게 오고, 그때 화면이 갈린다.
  @override
  bool? build() {
    unawaited(_restore());
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> complete() async {
    touch();
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingNotifier, bool?>(
  OnboardingNotifier.new,
);

/// 계정 없이 쓰기로 한 사람.
///
/// 이걸 안 남기면 `Browse without an account` 를 고른 사람이 앱을 켤 때마다
/// 로그인 화면을 다시 본다. 관심 목록도 온보딩도 남는데 이것만 안 남을
/// 이유가 없다.
class GuestNotifier extends Notifier<bool> with RestoreGuard {
  static const String _prefsKey = 'browsing_as_guest';

  @override
  bool build() {
    unawaited(_restore());
    return false;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> stay() async {
    touch();
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// 로그아웃하면 다시 로그인 화면으로 보낸다.
  Future<void> clear() async {
    touch();
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }
}

final guestProvider = NotifierProvider<GuestNotifier, bool>(GuestNotifier.new);

/// 언어 전환. 앱은 화면에서 context 로 만들어 넣고, 테스트는 가짜를 끼운다.
final localeControllerProvider = Provider<LocaleController?>((ref) => null);

/// 알림 켬/끔. 아직 실제 푸시에 연결돼 있지 않고 설정만 기억한다.
class NotificationsNotifier extends Notifier<bool> with RestoreGuard {
  static const String _prefsKey = 'notifications_enabled';

  @override
  bool build() {
    unawaited(_restore());
    return true;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    state = prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> set(bool value) async {
    touch();
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, bool>(
  NotificationsNotifier.new,
);

/// 밝게 / 어둡게 / 시스템.
///
/// 리메이크 전에는 전 화면이 다크를 지원했고 토글이 저장까지 됐다. 리메이크
/// 뒤에는 밝기가 코드에 못박혀 있었고 설정의 "다크 모드" 줄은 눌러도 아무 일이
/// 없었다 — 명세에 다크 토큰 표가 없다는 게 이유였는데, 그렇다고 기능을
/// 없앨 이유는 아니다. 색은 [TpTokens] 가 규칙으로 뒤집는다.
class ThemeModeNotifier extends Notifier<ThemeMode> with RestoreGuard {
  static const String _prefsKey = 'theme_mode';

  @override
  ThemeMode build() {
    unawaited(_restore());
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    state = _parse(prefs.getString(_prefsKey));
  }

  static ThemeMode _parse(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };

  Future<void> set(ThemeMode value) async {
    touch();
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// 내 기기.
final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => PlatformDeviceInfoService(),
);

final thisDeviceProvider = FutureProvider<ThisDevice?>(
  (ref) => ref.watch(deviceInfoServiceProvider).read(),
);

/// 내 기기가 카탈로그에 있으면 그 레코드.
///
/// 스캔과 같은 매칭을 쓴다. 모델 코드(SM-S931B)만 읽히는 경우가 많아 대부분
/// 못 찾는데, 그때는 화면이 "아직 카탈로그에 없습니다"로 떨어진다.
final thisDeviceMatchProvider = Provider<ScanMatch?>((ref) {
  final device = ref.watch(thisDeviceProvider).value;
  final catalog = ref.watch(catalogProvider).value;
  if (device == null || catalog == null) return null;
  return ScanMatcher.match(device.searchable, catalog.smartphones);
});

/// 시스템 공유 시트.
final shareServiceProvider = Provider<ShareService>(
  (ref) => const SharePlusService(),
);

/// 밖으로 나가는 링크. 출처·라이선스 표기가 실제로 열려야 한다.
final linkOpenerProvider = Provider<LinkOpener>(
  (ref) => const UrlLauncherOpener(),
);

/// 밖에서 들어온 링크의 출처.
final deepLinkServiceProvider = Provider<DeepLinkService>(
  (ref) => AppLinksService(),
);

/// 아직 안 연 딥링크.
///
/// 링크는 온보딩·로그인 중에도 들어온다. 그때는 열 화면이 없으므로 여기
/// 들고 있다가 [TabHost] 가 뜰 때 넘긴다.
class PendingLinkNotifier extends Notifier<TpLinkTarget?> {
  StreamSubscription<Uri>? _sub;
  Uri? _last;

  @override
  TpLinkTarget? build() {
    unawaited(_watch());
    ref.onDispose(() => unawaited(_sub?.cancel()));
    return null;
  }

  Future<void> _watch() async {
    final service = ref.read(deepLinkServiceProvider);
    try {
      final first = await service.initial();
      if (!ref.mounted) return;
      if (first != null) _offer(first);
      _sub = service.stream().listen(
        _offer,
        onError: (Object e, StackTrace s) =>
            TpErrors.record(e, s, reason: 'deeplink.stream'),
      );
    } catch (e, s) {
      // 플러그인이 없는 환경(테스트·데스크톱)에서도 앱은 떠야 한다.
      TpErrors.record(e, s, reason: 'deeplink.watch');
    }
  }

  /// 초기 링크가 스트림으로 한 번 더 오는 플랫폼이 있다. 같은 URI 가 연달아
  /// 오면 화면이 두 번 밀려 올라간다.
  void _offer(Uri uri) {
    if (uri == _last) return;
    _last = uri;
    final target = TpLink.parse(uri);
    if (target != null) state = target;
  }

  /// 한 번만 연다. 읽은 쪽이 비우는 책임을 갖는다.
  TpLinkTarget? take() {
    final target = state;
    state = null;
    return target;
  }
}

final pendingLinkProvider =
    NotifierProvider<PendingLinkNotifier, TpLinkTarget?>(
      PendingLinkNotifier.new,
    );

/// 연결 상태.
final connectivityServiceProvider = Provider<ConnectivityService>(
  (ref) => ConnectivityPlusService(),
);

/// 지금 끊겨 있는가.
///
/// 실패 화면이 이걸 보고 문구를 고른다. 못 읽으면(플러그인 없음, 권한 없음)
/// 값이 안 오고, 그때는 지금까지대로 일반 실패로 보여준다.
final offlineProvider = StreamProvider<bool>(
  (ref) async* {
    final service = ref.watch(connectivityServiceProvider);
    yield await service.offline();
    yield* service.changes();
  },
  // 못 읽는 환경에서 조용히 재시도하면 계속 깨어난다. 한 번 실패면 그만.
  retry: (_, _) => null,
);

/// 관심 목록을 계정에 올리고 내리는 곳.
final shortlistSyncServiceProvider = Provider<ShortlistSyncService>(
  (ref) => FirestoreShortlistSync(),
);

/// 로그인한 사람의 관심 목록을 기기 사이에서 맞춘다.
///
/// **계정 없이 쓰는 사람은 이 경로를 안 탄다.** 익명 로그인도 마찬가지다 —
/// 익명 uid 는 설치마다 다르라 올려봐야 다시 못 찾는다.
///
/// 합집합으로 병합하지 않는다. 그러면 한 기기에서 지운 것이 다른 기기에서
/// 되살아난다. 문서 하나를 통째로 놓고 **마지막에 고친 쪽이 이긴다.**
class ShortlistSync extends Notifier<void> {
  /// 병합이 끝난 계정. 끝나기 전에 올리면 원격을 낡은 것으로 덮는다.
  final Set<String> _merged = <String>{};

  @override
  void build() {
    ref.listen(currentUserProvider, (previous, next) {
      if (next == null || next.isAnonymous) return;
      if (next.uid == previous?.uid) return;
      unawaited(_merge(next.uid));
    }, fireImmediately: true);

    ref.listen(shortlistProvider, (previous, next) {
      // 첫 값은 저장값을 복원한 것이다. 사람이 고친 게 아니다.
      if (previous == null) return;
      final user = ref.read(currentUserProvider);
      if (user == null || user.isAnonymous) return;
      if (!_merged.contains(user.uid)) return;
      unawaited(_push(user.uid, next));
    });
  }

  Future<void> _merge(String uid) async {
    final service = ref.read(shortlistSyncServiceProvider);
    final shortlist = ref.read(shortlistProvider.notifier);
    try {
      // 복원 전에 읽으면 빈 목록을 이 기기의 최신 상태로 착각해 계정을 덮는다.
      await shortlist.ready;
      final remote = await service.read(uid);
      final localAt = await shortlist.lastChanged();
      if (!ref.mounted) return;

      if (remote != null &&
          (localAt == null || remote.updatedAt.isAfter(localAt))) {
        await shortlist.adopt(remote.slugs, remote.updatedAt);
      } else {
        await service.write(
          uid,
          ref.read(shortlistProvider),
          localAt ?? DateTime.now(),
        );
      }
      _merged.add(uid);
    } catch (e, s) {
      // 못 맞춰도 로컬은 그대로 돈다. 다음 로그인에 다시 시도한다.
      TpErrors.record(e, s, reason: 'shortlist.merge');
    }
  }

  Future<void> _push(String uid, List<String> slugs) async {
    try {
      await ref
          .read(shortlistSyncServiceProvider)
          .write(uid, slugs, DateTime.now());
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'shortlist.push');
    }
  }
}

final shortlistSyncProvider = NotifierProvider<ShortlistSync, void>(
  ShortlistSync.new,
);
