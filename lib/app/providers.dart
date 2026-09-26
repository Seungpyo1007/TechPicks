import 'dart:async';
import 'dart:typed_data' show Uint8List;
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_gemma_builtin_ai/flutter_gemma_builtin_ai.dart'
    show BuiltInAiAvailability;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/analytics.dart';
import '../core/error_reporter.dart';
import '../data/dto/cpu.dart';
import '../data/dto/laptop.dart';
import '../data/dto/smartphone.dart';

import '../data/repository/catalog_repository.dart';
import '../data/repository/laptop_repository.dart';
import '../data/service/fx_service.dart';
import '../domain/model/tp_money.dart';
import '../domain/model/build_estimate.dart';
import '../domain/model/search_index.dart';
import '../data/repository/parts_repository.dart';
import '../data/repository/catalog_source.dart';
import '../data/repository/catalog_store.dart';
import '../data/repository/tech_api_repository.dart';
import '../data/service/ask_service.dart';
import '../data/service/on_device_ask_service.dart';
import '../data/service/profile_service.dart';
import '../data/service/auth_service.dart';
import '../data/service/connectivity_service.dart';
import '../data/service/deep_link_service.dart';
import '../data/service/device_info_service.dart';
import '../data/service/link_opener.dart';
import '../data/service/share_service.dart';
import '../data/service/account_sync_service.dart';
import '../domain/model/ask_answer.dart';
import '../domain/model/device_search.dart';
import '../domain/model/device_specs.dart';
import '../domain/model/movers.dart';
import '../domain/model/scan_match.dart';
import '../domain/model/tp_index.dart';
import '../domain/model/processor.dart';
import '../domain/model/ranking.dart';
import '../domain/model/tp_profile.dart';
import '../domain/model/tp_weights.dart';
import '../feature/share/tp_link.dart';
import '../shared/copy_keys.dart';
import 'locale_controller.dart';

/// 카탈로그. 애셋으로 시작하고, 받아둔 것이 있으면 그걸 먼저 읽는다.
///
/// Remote Config 에 `catalog_url` 이 비어 있는 동안은 애셋만 쓴다 — 지금까지와
/// 똑같이 동작한다.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(
    store: defaultCatalogStore(),
    feed: RemoteConfigCatalogFeed(),
  ),
);

/// TechAPI 원격. 카탈로그에 없는 기기를 상세로 열 때 쓴다.
final techApiRepositoryProvider = Provider<TechApiRepository>(
  (ref) => TechApiRepository(),
);

/// 조립 PC 부품. 견적기가 쓴다.
final partsRepositoryProvider = Provider<PartsRepository>(
  (ref) => PartsRepository(),
);

/// 노트북 목록.
final laptopRepositoryProvider = Provider<LaptopRepository>(
  (ref) => LaptopRepository(),
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

/// 데스크톱 부품. 애셋이라 재시도가 의미 없는 것은 카탈로그와 같다.
final partsProvider = FutureProvider<DesktopParts>((ref) async {
  final result = await ref.watch(partsRepositoryProvider).load();
  return result.fold((p) => p, (f) => throw f);
}, retry: (_, _) => null);

final laptopsProvider = FutureProvider<Laptops>((ref) async {
  final result = await ref.watch(laptopRepositoryProvider).load();
  return result.fold((l) => l, (f) => throw f);
}, retry: (_, _) => null);

/// 검색 색인. 세 갈래를 한 목록으로 편다.
///
/// 한 번 짓고 캐시한다. 타건마다 194줄을 다시 만들 이유가 없다 —
/// pickerRankedProvider 가 랭킹을 밖에 둔 것과 같은 이유다.
final searchIndexProvider = Provider<List<SearchHit>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  final laptops = ref.watch(laptopsProvider).value;
  return SearchIndex.of(
    phones: catalog?.smartphones ?? const <Smartphone>[],
    processors: catalog?.cpus ?? const <Cpu>[],
    laptops: laptops?.items ?? const <Laptop>[],
    weights: ref.watch(weightsProvider),
  );
});

/// 견적기가 보고 있는 용도와 예산.
///
/// 둘을 한 덩어리로 든다. 따로 두면 한쪽이 바뀔 때마다 추천이 두 번 돈다.
class BuildQuery {
  const BuildQuery({required this.useCase, required this.budgetUsd});

  final BuildUseCase useCase;
  final int budgetUsd;

  BuildQuery copyWith({BuildUseCase? useCase, int? budgetUsd}) => BuildQuery(
    useCase: useCase ?? this.useCase,
    budgetUsd: budgetUsd ?? this.budgetUsd,
  );

  @override
  bool operator ==(Object other) =>
      other is BuildQuery &&
      other.useCase == useCase &&
      other.budgetUsd == budgetUsd;

  @override
  int get hashCode => Object.hash(useCase, budgetUsd);
}

class BuildQueryNotifier extends Notifier<BuildQuery> {
  @override
  BuildQuery build() => const BuildQuery(
    useCase: BuildUseCase.gaming,
    budgetUsd: BuildEstimate.defaultBudget,
  );

  void set(BuildQuery query) => state = query;

  void useCase(BuildUseCase value) => state = state.copyWith(useCase: value);

  /// 공유된 링크가 아무 숫자나 들고 올 수 있다. 여기서 접는다.
  void budget(int usd) =>
      state = state.copyWith(budgetUsd: BuildEstimate.clampBudget(usd));
}

final buildQueryProvider = NotifierProvider<BuildQueryNotifier, BuildQuery>(
  BuildQueryNotifier.new,
);

/// 추천 조합.
///
/// 예산 슬라이더는 드래그 프레임마다 다시 그린다. 여기서 캐시하지 않으면
/// 한 번 끄는 동안 6,969 조합을 수십 번 다시 센다 — pickerRankedProvider 가
/// 같은 이유로 랭킹을 밖에 둔 것과 같다.
final buildPicksProvider = Provider<List<BuildCombo>>((ref) {
  final parts = ref.watch(partsProvider).value;
  if (parts == null) return const <BuildCombo>[];
  final q = ref.watch(buildQueryProvider);
  return BuildEstimate.recommend(
    parts.cpus,
    parts.gpus,
    q.useCase,
    q.budgetUsd,
  );
});

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
    _restored = _restore();
    // 미뤄둔 쓰기가 있으면 사라지기 전에 내보낸다.
    ref.onDispose(() {
      _saveTimer?.cancel();
      final pending = _unsaved;
      if (pending != null) unawaited(_write(pending));
    });
    return TpWeights.defaults;
  }

  Future<void> _restored = Future<void>.value();

  /// 복원이 끝났는지. 계정 병합이 기다린다.
  Future<void> get ready => _restored;

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

  /// 계정의 값을 받아 쓴다. 사람이 고친 게 아니라 분석 이벤트는 없다.
  Future<void> adopt(TpWeights next) async {
    touch();
    _saveTimer?.cancel();
    _unsaved = null;
    _pendingAxis = null;
    state = next;
    await _write(next);
  }

  /// 로그아웃 뒤. 기본값으로 돌리고 저장값을 지운다.
  Future<void> clear() async {
    touch();
    _saveTimer?.cancel();
    _unsaved = null;
    _pendingAxis = null;
    state = TpWeights.defaults;
    await (await SharedPreferences.getInstance()).remove(_prefsKey);
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

  /// 시트에서 고른 것. null 이면 전부.
  void set(String? brand) => state = brand;
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

/// 둘러보기 · 프로세서의 정렬.
enum ProcessorSort { score, name }

class ProcessorSortNotifier extends Notifier<ProcessorSort> {
  @override
  ProcessorSort build() => ProcessorSort.score;

  void set(ProcessorSort value) => state = value;
}

final processorSortProvider =
    NotifierProvider<ProcessorSortNotifier, ProcessorSort>(
      ProcessorSortNotifier.new,
    );

/// 둘러보기 · 노트북의 정렬과 가격대.
enum LaptopSort { priceHigh, priceLow }

class LaptopSortNotifier extends Notifier<LaptopSort> {
  @override
  LaptopSort build() => LaptopSort.priceHigh;

  void set(LaptopSort value) => state = value;
}

final laptopSortProvider = NotifierProvider<LaptopSortNotifier, LaptopSort>(
  LaptopSortNotifier.new,
);

/// 가격대 번역 키. null 이면 전체.
class LaptopTierNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final laptopTierProvider = NotifierProvider<LaptopTierNotifier, String?>(
  LaptopTierNotifier.new,
);

/// 현재 세그먼트의 프로세서 순위.
final rankedProcessorsProvider = Provider<List<RankedProcessor>>(
  (ref) => ref.watch(processorsInProvider(ref.watch(processorSegmentProvider))),
);

/// 구간 하나의 순위. 둘러보기 프로세서 화면이 두 구간을 같이 보여준다.
final processorsInProvider =
    Provider.family<List<RankedProcessor>, ProcessorSegment>((ref, segment) {
      final catalog = ref.watch(catalogProvider).value;
      if (catalog == null) return const <RankedProcessor>[];
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
  }

  /// 계정의 목록을 받아 쓴다.
  Future<void> adopt(List<String> slugs) async {
    touch();
    state = List<String>.unmodifiable(slugs);
    await _persist();
  }

  /// 로그아웃 뒤. 다음 사람에게 섞이지 않게 비운다.
  Future<void> clear() async {
    touch();
    state = const <String>[];
    await (await SharedPreferences.getInstance()).remove(_prefsKey);
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

  /// 되돌리기. 지운 자리([at])에 다시 넣는다.
  void insert(int at, String slug) {
    if (state.contains(slug)) return;
    touch();
    state = <String>[...state]..insert(at.clamp(0, state.length), slug);
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
    // 관심 목록에 둘 이상 있으면 그 둘(지수 높은 순), 모자라면 전체 순위로
    // 채운다. 오늘 화면에서 "전체 비교"를 누르고 들어왔는데 목록에 없는 1·2위가
    // 떠 있으면 무엇을 비교하는지 모른다.
    //
    // watch 로 읽으면 카탈로그가 도착할 때 이 노티파이어가 통째로 다시
    // 만들어져 **그 사이에 고른 것이 지워진다.** 딥링크로 연 비교가 몇
    // 프레임 뒤 기본값으로 덮였다. 그래서 읽기만 하고, 사람이 고르기 전까지만
    // 기본값을 다시 채운다.
    void refill() {
      if (_picked) return;
      state = _defaults(
        ref.read(indexRankingProvider),
        ref.read(shortlistProvider),
      );
    }

    ref
      ..listen(indexRankingProvider, (_, _) => refill())
      ..listen(shortlistProvider, (_, _) => refill());
    return _defaults(
      ref.read(indexRankingProvider),
      ref.read(shortlistProvider),
    );
  }

  /// 사람이 한 칸이라도 골랐는가. 그 뒤로는 기본값이 덮지 않는다.
  bool _picked = false;

  static CompareSlots _defaults(
    List<RankedDevice> ranked,
    List<String> shortlist,
  ) {
    final picks = <String>[
      for (final r in ranked)
        if (shortlist.contains(r.device.slug)) r.device.slug,
    ];
    for (final r in ranked) {
      if (picks.length >= 2) break;
      if (!picks.contains(r.device.slug)) picks.add(r.device.slug);
    }
    return picks.length < 2
        ? const CompareSlots()
        : CompareSlots(a: picks[0], b: picks[1]);
  }

  void pick(CompareSide side, String slug) {
    _picked = true;
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
  return DeviceComparison.of(
    a,
    b,
    ref.watch(weightsProvider),
    ref.watch(moneyProvider),
  );
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

/// 비교 선택 시트의 기본 순서.
///
/// 카탈로그 순서는 TechAPI 원점수 순이라 화면에 찍히는 지수와 어긋난다.
/// 84, 84, 85 가 잇달아 나오면 목록이 고장 난 것처럼 보인다.
///
/// 시트 안에서 하면 **타건마다** 154종을 다시 줄 세운다. 여기 두면
/// Riverpod 이 (카탈로그, 가중치) 단위로 들고 있고, 검색은 그 위에서
/// 거르기만 한다.
final pickerRankedProvider = Provider<List<Smartphone>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const <Smartphone>[];
  return <Smartphone>[
    for (final r in Ranking.of(
      catalog.smartphones,
      RankAxis.tpIndex,
      ref.watch(weightsProvider),
    ))
      r.device,
  ];
});

/// 다음 실행에 남길 순위. 스냅샷과 Movers 가 같은 목록을 봐야 한다.
final rankSnapshotSlugsProvider = Provider<List<String>>(
  (ref) => ref
      .watch(indexRankingProvider)
      .map((r) => r.device.slug)
      .toList(growable: false),
);

/// 이번 주 변동. 저장된 순위가 없으면 빈 목록이다(오늘은 첫 실행 안내 한 줄).
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

/// 어느 AI 로 답할지.
enum TpAiEngine {
  /// 기기 안 → 클라우드 → 카탈로그. 되는 것 중 제일 앞의 것을 쓴다.
  auto,

  /// 기기 밖으로 질문을 안 보낸다. 기기 안 → 카탈로그.
  onDevice,

  /// 클라우드 → 카탈로그.
  cloud;

  String get key => switch (this) {
    TpAiEngine.auto => K.aiEngineAuto,
    TpAiEngine.onDevice => K.aiEngineOnDevice,
    TpAiEngine.cloud => K.aiEngineCloud,
  };
}

class AiEngineNotifier extends Notifier<TpAiEngine> with RestoreGuard {
  static const String _prefsKey = 'ai_engine';

  @override
  TpAiEngine build() {
    unawaited(_restore());
    return TpAiEngine.auto;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    final saved = prefs.getString(_prefsKey);
    state = TpAiEngine.values.firstWhere(
      (e) => e.name == saved,
      orElse: () => TpAiEngine.auto,
    );
  }

  Future<void> set(TpAiEngine value) async {
    touch();
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, value.name);
  }
}

final aiEngineProvider = NotifierProvider<AiEngineNotifier, TpAiEngine>(
  AiEngineNotifier.new,
);

/// 기기 안 AI 를 이 기기에서 쓸 수 있는지.
///
/// 못 쓰는 기기가 대부분이다(iPhone 15 Pro 이상 + Apple Intelligence, 또는
/// Pixel 9 · Galaxy S25 이상). 설정 줄이 그걸 말해줘야 사람이 왜 안 되는지 안다.
final onDeviceAiProvider = FutureProvider<BuiltInAiAvailability>(
  (ref) => TpBuiltInAi.shared.availability(),
);

/// AI 상담.
///
/// 세 구현이 줄지어 있다. 기기 안 모델(질문이 밖으로 안 나간다) → 클라우드
/// Gemini → 카탈로그만으로 답하는 로컬. 앞의 것이 못 답하면 뒤가 받는다.
///
/// 오래 로컬만 쓰다 보니 상담 탭이 모델을 한 번도 부르지 않는 상태였다 —
/// 명세 §12 의 화면은 그대로인데 답이 가짜였다.
final askServiceProvider = Provider<AskService>((ref) {
  final weights = ref.watch(weightsProvider);
  final engine = ref.watch(aiEngineProvider);
  final local = LocalAskService(weights: weights);

  AskService cloudOr(AskService next) => _firebaseReady
      ? FallbackAskService(GeminiAskService(weights: weights), next)
      : next;

  return switch (engine) {
    TpAiEngine.cloud => cloudOr(local),
    TpAiEngine.onDevice => FallbackAskService(
      OnDeviceAskService(weights: weights),
      local,
    ),
    TpAiEngine.auto => FallbackAskService(
      OnDeviceAskService(weights: weights),
      cloudOr(local),
    ),
  };
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

  /// 보낼 때마다 하나씩 는다. 취소한 질문의 답이 늦게 와도 버린다.
  int _turn = 0;

  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || _busy) return;

    _busy = true;
    final turn = ++_turn;
    ref.read(askBusyProvider.notifier).set(true);
    // 사용자 말풍선을 먼저 올린다. 응답을 기다리는 동안 화면이 멈춘 것처럼
    // 보이지 않게 한다.
    state = <AskMessage>[...state, AskMessage.user(text)];

    // 카탈로그를 못 읽으면 답할 근거가 없다. 예외를 그대로 올리면 화면이
    // 멈춘 것처럼 보이고 _busy 도 안 풀린다.
    AskReply? reply;
    try {
      final catalog = await ref.read(catalogProvider.future);
      reply = await ref.read(askServiceProvider).ask(text, catalog.smartphones);
    } catch (e, st) {
      TpErrors.record(e, st, reason: 'ask.send');
      reply = null;
    }

    // 기다리는 동안 취소했다.
    if (turn != _turn) return;
    _busy = false;
    if (ref.mounted) ref.read(askBusyProvider.notifier).set(false);
    TpAnalytics.asked(length: text.length, answered: reply != null);
    // 답이 오는 동안 화면을 떠났을 수 있다.
    if (!ref.mounted) return;

    final answer = reply?.answer;
    state = <AskMessage>[
      ...state,
      if (reply == null)
        AskMessage.ai(K.askFailed.tr(), failed: true)
      else if (answer != null)
        AskMessage.ai(
          answer.pick,
          answer: answer,
          fromCatalog: reply.fromCatalog,
        )
      // 고를 기기가 없는 질문. 표 없이 문장만 그린다.
      else
        AskMessage.ai(reply.text!, fromCatalog: reply.fromCatalog),
    ];
  }

  /// 기다리던 질문을 거둔다. 말풍선도 내리고 그 글을 돌려준다.
  ///
  /// 답이 나중에 와도 [send] 가 차례를 보고 버린다.
  String? cancel() {
    if (!_busy) return null;
    _turn++;
    _busy = false;
    ref.read(askBusyProvider.notifier).set(false);
    final last = state.isEmpty ? null : state.last;
    if (last == null || !last.isUser) return null;
    state = state.sublist(0, state.length - 1);
    return last.text;
  }

  /// 실패한 답을 걷어내고 같은 질문을 다시 보낸다.
  ///
  /// [send] 를 그냥 부르면 같은 질문이 두 번 올라간 것처럼 보인다. 실패한 답과
  /// **그 질문**을 같이 걷어내고 처음부터 다시 태운다.
  Future<void> retry() async {
    if (_busy || state.length < 2) return;
    final failed = state.last;
    final question = state[state.length - 2];
    if (failed.isUser || !failed.failed || !question.isUser) return;

    state = state.sublist(0, state.length - 2);
    await send(question.text);
  }

  /// 비교 화면의 "왜?" 에서 넘어올 때 두 기기를 물어봐 준다.
  ///
  /// 질문만 올려두면 답 없는 말풍선이 남는다. [send] 를 그대로 태워서
  /// 사용자가 직접 친 것과 같은 흐름으로 만든다.
  Future<void> askAbout(String a, String b) {
    ref.read(askTopicProvider.notifier).set('$a vs $b');
    return send('$a or $b?');
  }
}

/// 네이티브 검색창(iOS 26 탭 바가 펼친 것)에 친 글자.
///
/// 검색창이 Flutter 밖에 있어서 화면이 컨트롤러를 못 쥔다. 탭 바가 받아서
/// 여기에 넣고, 검색 화면이 읽는다.
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// 네이티브 검색창 키보드의 최종 높이. 키보드가 움직이기 **시작할 때** 온다.
class SearchKeyboardHeightNotifier extends Notifier<double> {
  @override
  double build() => 0;

  void set(double value) => state = value;
}

final searchKeyboardHeightProvider =
    NotifierProvider<SearchKeyboardHeightNotifier, double>(
      SearchKeyboardHeightNotifier.new,
    );

/// 네이티브 검색창에 보내는 명령. 토큰이 바뀔 때마다 탭 바가 그대로 한다.
typedef SearchCommand = ({String text, int textToken, int focusToken});

class SearchCommandNotifier extends Notifier<SearchCommand> {
  @override
  SearchCommand build() => (text: '', textToken: 0, focusToken: 0);

  /// 검색창 글자를 바꾼다(예시 검색어). 결과도 같이 바뀌도록 검색어도 넣는다.
  void setText(String text) {
    state = (
      text: text,
      textToken: state.textToken + 1,
      focusToken: state.focusToken,
    );
    ref.read(searchQueryProvider.notifier).set(text);
  }

  /// 검색창에 초점(키보드).
  void focus() => state = (
    text: state.text,
    textToken: state.textToken,
    focusToken: state.focusToken + 1,
  );
}

final searchCommandProvider =
    NotifierProvider<SearchCommandNotifier, SearchCommand>(
      SearchCommandNotifier.new,
    );

/// 올릴 때마다 네이티브 검색창 키보드가 내려간다.
class SearchKeyboardNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void dismiss() => state++;
}

final searchKeyboardProvider = NotifierProvider<SearchKeyboardNotifier, int>(
  SearchKeyboardNotifier.new,
);

/// 검색에서 열어 본 것. 최근 것이 앞, 최대 10개. `kind:slug` 로 저장한다.
class RecentHitsNotifier extends Notifier<List<String>> with RestoreGuard {
  static const String _prefsKey = 'recent_hits';
  static const int cap = 10;

  @override
  List<String> build() {
    _restored = _restore();
    return const <String>[];
  }

  Future<void> _restored = Future<void>.value();

  /// 복원이 끝났는지. 계정 병합이 기다린다.
  Future<void> get ready => _restored;

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || touched) return;
    state = prefs.getStringList(_prefsKey) ?? const <String>[];
  }

  /// 계정의 목록을 받아 쓴다.
  Future<void> adopt(List<String> keys) async {
    touch();
    state = List<String>.unmodifiable(keys.take(cap));
    await (await SharedPreferences.getInstance()).setStringList(
      _prefsKey,
      state,
    );
  }

  /// 로그아웃 뒤.
  Future<void> clear() async {
    touch();
    state = const <String>[];
    await (await SharedPreferences.getInstance()).remove(_prefsKey);
  }

  static String keyOf(SearchHit hit) => '${hit.kind.name}:${hit.slug}';

  Future<void> add(SearchHit hit) async {
    touch();
    final key = keyOf(hit);
    state = <String>[key, ...state.where((k) => k != key)].take(cap).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, state);
  }
}

final recentHitsProvider = NotifierProvider<RecentHitsNotifier, List<String>>(
  RecentHitsNotifier.new,
);

/// 질문 시트 위의 맥락 알약. 비교에서 넘어오면 두 기기, 오늘 툴바에서 열면 없다.
class AskTopicNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
}

final askTopicProvider = NotifierProvider<AskTopicNotifier, String?>(
  AskTopicNotifier.new,
);

final askProvider = NotifierProvider<AskNotifier, List<AskMessage>>(
  AskNotifier.new,
);

/// 인증. 기본은 Firebase 구현이다.
final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(),
);

/// 프로필 저장소. 테스트는 이걸 갈아끼운다.
final profileServiceProvider = Provider<ProfileService>(
  (ref) => FirebaseProfileService(),
);

/// 지금 로그인한 사람의 프로필.
///
/// 로그인 안 했으면 빈 프로필이다 — 계정 없이 쓰는 사람에게는 올릴 곳이 없다.
class ProfileNotifier extends AsyncNotifier<TpProfile> {
  @override
  Future<TpProfile> build() async {
    final uid = ref.watch(currentUserProvider)?.uid;
    if (uid == null) return const TpProfile();
    return ref.watch(profileServiceProvider).load(uid);
  }

  /// 저장하고 화면에 바로 반영한다. 실패하면 false 고 상태는 그대로다.
  Future<bool> save(TpProfile profile) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return false;

    final ok = await ref.read(profileServiceProvider).save(uid, profile);
    if (ok && ref.mounted) state = AsyncData(profile);
    return ok;
  }

  /// 사진을 올리고 프로필에 붙인다. 주소를 돌려주고, 실패하면 null.
  Future<String?> uploadPhoto(Uint8List bytes) async {
    final uid = ref.read(currentUserProvider)?.uid;
    if (uid == null) return null;

    final url = await ref.read(profileServiceProvider).uploadPhoto(uid, bytes);
    if (url == null) return null;

    final next = (state.value ?? const TpProfile()).copyWith(photoUrl: url);
    return await save(next) ? url : null;
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, TpProfile>(
  ProfileNotifier.new,
);

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

  /// 로그인. 실패면 까닭을 돌려준다(취소도 [AuthFailure.canceled] 로).
  Future<AuthResult> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async {
    final result = await ref
        .read(authServiceProvider)
        .signIn(method, email: email, password: password);
    if (result.user != null && ref.mounted) state = result.user;
    return result;
  }

  Future<AuthResult> signUp(String email, String password) async {
    final result = await ref
        .read(authServiceProvider)
        .signUp(email: email, password: password);
    if (result.user != null && ref.mounted) state = result.user;
    return result;
  }

  /// 비밀번호 재설정 메일. 로그인 전(비밀번호 찾기)에도 쓴다. 보냈으면 null.
  Future<AuthFailure?> sendPasswordReset(String email) =>
      ref.read(authServiceProvider).sendPasswordReset(email);

  /// 메일 확인 메일을 다시 보낸다.
  Future<AuthFailure?> resendVerification() =>
      ref.read(authServiceProvider).sendEmailVerification();

  /// 표시 이름을 바꾼다.
  Future<bool> updateName(String name) async {
    final user = await ref.read(authServiceProvider).updateName(name.trim());
    if (user == null) return false;
    if (ref.mounted) state = user;
    return true;
  }

  /// 계정을 지운다. 계정의 데이터는 [accountCleanupProvider] 가 지운다.
  /// 성공하면 기기의 계정 데이터도 기본값으로 돌린다.
  Future<AuthFailure?> deleteAccount({String? password}) async {
    final cleanup = ref.read(accountCleanupProvider);
    final failure = await ref
        .read(authServiceProvider)
        .deleteAccount(password: password, cleanup: cleanup);
    if (failure != null) return failure;
    if (ref.mounted) {
      state = null;
      await ref.read(localAccountResetProvider)();
    }
    return null;
  }

  Future<void> signOut() async {
    // 화면을 먼저 되돌린다.
    //
    // Firebase 를 기다렸다가 비우면, 그쪽이 안 돌아오는 설정에서 로그아웃을
    // 눌러도 아무 일이 안 일어난다. 시뮬레이터에서 실제로 그랬다. 누른 대로
    // 나가는 것이 먼저다 — 실패하면 다음 실행에 세션이 복원될 뿐이다.
    state = null;
    // 이 기기에 남은 계정 데이터(관심 목록·가중치·최근)를 기본값으로. 안 비우면
    // 다음에 로그인한 사람에게 섞인다.
    await ref.read(localAccountResetProvider)();
    await ref.read(authServiceProvider).signOut();
  }
}

/// 계정의 서버 데이터를 지운다(계정 삭제 때).
final accountCleanupProvider = Provider<Future<void> Function(String uid)>(
  (ref) => ref.read(accountSyncServiceProvider).delete,
);

/// 이 기기의 계정 데이터를 기본값으로(로그아웃·삭제 뒤).
final localAccountResetProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    await Future.wait(<Future<void>>[
      ref.read(shortlistProvider.notifier).clear(),
      ref.read(weightsProvider.notifier).clear(),
      ref.read(recentHitsProvider.notifier).clear(),
    ]);
  },
);

final currentUserProvider = NotifierProvider<CurrentUserNotifier, TpUser?>(
  CurrentUserNotifier.new,
);

/// 로그인 안 한 사람이 처음 관심 목록에 담았을 때 **한 번만** 권한다.
///
/// 상태는 권한 기기의 slug. 그 상세 화면에만 뜬다. 닫거나 로그인하면 null.
class LoginPromptNotifier extends Notifier<String?> {
  static const String _prefsKey = 'login_prompt_seen';

  @override
  String? build() {
    ref.listen(currentUserProvider, (_, next) {
      if (next != null) state = null;
    });
    return null;
  }

  Future<void> offer(String slug) async {
    if (ref.read(currentUserProvider) != null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) ?? false) return;
    await prefs.setBool(_prefsKey, true);
    if (ref.mounted) state = slug;
  }

  void dismiss() => state = null;
}

final loginPromptProvider = NotifierProvider<LoginPromptNotifier, String?>(
  LoginPromptNotifier.new,
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

  /// "안내 다시 보기". 라우터 게이트가 곧바로 온보딩으로 보낸다.
  Future<void> replay() async {
    touch();
    state = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, false);
  }
}

final onboardingDoneProvider = NotifierProvider<OnboardingNotifier, bool?>(
  OnboardingNotifier.new,
);

/// 언어 전환. 앱은 화면에서 context 로 만들어 넣고, 테스트는 가짜를 끼운다.
final localeControllerProvider = Provider<LocaleController?>((ref) => null);

/// 가격을 어느 통화로 보여줄지.
///
/// `auto` 는 언어를 따라간다 — 한국어면 원, 아니면 달러. 언어 하나만 바꾸고
/// 통화가 안 따라오면 한국어 화면에 달러가 남아 두 가지가 어긋난다.
///
/// 그래도 고를 수 있게 둔다. 국제 기준가로 보고 싶은 사람이 있고, 명세가
/// 뺐던 통화 줄을 되살리는 자리이기도 하다.
enum TpCurrency { auto, usd, krw }

class CurrencyNotifier extends Notifier<TpCurrency> {
  static const String key = 'currency_mode';

  @override
  TpCurrency build() {
    unawaited(_restore());
    return TpCurrency.auto;
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(key);
      if (saved == null) return;
      for (final c in TpCurrency.values) {
        if (c.name == saved) {
          state = c;
          return;
        }
      }
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'currency.restore');
    }
  }

  Future<void> set(TpCurrency next) async {
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, next.name);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'currency.save');
    }
  }
}

final currencyProvider = NotifierProvider<CurrencyNotifier, TpCurrency>(
  CurrencyNotifier.new,
);

final fxServiceProvider = Provider<FxService>((ref) => ErApiFxService());

/// 환율. **첫 프레임을 네트워크에 걸지 않는다.**
///
/// 박아둔 값으로 먼저 그리고 받아지면 갈아끼운다. 가격이 한 번 바뀌어
/// 보이는 것이 로딩 스피너보다 낫다 — 값이 없는 게 아니라 덜 정확할 뿐이다.
final fxRateProvider = FutureProvider<FxRate>(
  (ref) => ref.watch(fxServiceProvider).read(),
);

/// 지금 쓸 통화. 화면이 이걸 [DeviceSpecs.of] 에 넘긴다.
///
/// 로케일은 easy_localization 이 들고 있어서 Riverpod 밖이다. 셸이
/// [localeControllerProvider] 를 채워주므로 그걸 통해 읽는다.
final moneyProvider = Provider<TpMoney>((ref) {
  final mode = ref.watch(currencyProvider);
  final krw = switch (mode) {
    TpCurrency.usd => false,
    TpCurrency.krw => true,
    TpCurrency.auto =>
      ref.watch(localeControllerProvider)?.current == TpLocale.ko,
  };
  if (!krw) return const TpMoney.usd();
  // 아직 못 받았으면 박아둔 값으로 먼저 그린다.
  return TpMoney.krw(ref.watch(fxRateProvider).value ?? FxRate.fallback);
});

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

/// 계정 데이터를 올리고 내리는 곳.
final accountSyncServiceProvider = Provider<AccountSyncService>(
  (ref) => FirestoreAccountSync(),
);

/// 로그인한 사람의 관심 목록·가중치·최근 검색을 기기 사이에서 맞춘다.
///
/// **계정 없이 쓰는 사람은 이 경로를 안 탄다.**
///
/// 로그인하는 순간 한 번 합친다.
/// - 관심 목록: 합집합. 계정 순서 먼저, 이 기기에만 있던 것을 뒤에.
/// - 가중치: 계정에 있으면 계정 것, 없으면 이 기기 것을 올린다.
/// - 최근 검색: 합집합. 이 기기 것이 더 최근이라 앞에, 최대 10.
///
/// 합집합이 지운 것을 되살리지 않는 건 로그아웃이 기기를 비우기 때문이다.
/// 로그인한 동안은 snapshot 으로 계속 맞춰져 있다.
class AccountSync extends Notifier<void> {
  /// 병합이 끝난 계정. 끝나기 전에 올리면 원격을 낡은 것으로 덮는다.
  String? _merged;
  StreamSubscription<AccountState>? _watch;

  /// 가중치는 슬라이더가 픽셀마다 바꾼다. 손을 뗀 뒤 한 번 올린다.
  static const Duration weightsDelay = Duration(milliseconds: 800);
  Timer? _weightsTimer;

  // 마지막으로 계정과 맞춘 값. 같은 걸 다시 올리거나 받지 않는다.
  List<String>? _shortlist;
  TpWeights? _weights;
  List<String>? _recents;

  AccountSyncService get _service => ref.read(accountSyncServiceProvider);

  @override
  void build() {
    ref.onDispose(_stop);

    ref.listen(currentUserProvider, (previous, next) {
      if (next?.uid == _merged && next != null) return;
      _stop();
      if (next != null) unawaited(_merge(next.uid));
    }, fireImmediately: true);

    ref.listen(shortlistProvider, (_, next) {
      final uid = _merged;
      if (uid == null || _same(next, _shortlist)) return;
      _shortlist = next;
      unawaited(_push('shortlist', () => _service.writeShortlist(uid, next)));
    });

    ref.listen(weightsProvider, (_, next) {
      final uid = _merged;
      if (uid == null || next == _weights) return;
      _weightsTimer?.cancel();
      _weightsTimer = Timer(weightsDelay, () {
        _weights = next;
        unawaited(_push('weights', () => _service.writeWeights(uid, next)));
      });
    });

    ref.listen(recentHitsProvider, (_, next) {
      final uid = _merged;
      if (uid == null || _same(next, _recents)) return;
      _recents = next;
      unawaited(_push('recents', () => _service.writeRecents(uid, next)));
    });
  }

  void _stop() {
    _merged = null;
    _weightsTimer?.cancel();
    _weightsTimer = null;
    unawaited(_watch?.cancel());
    _watch = null;
    _shortlist = null;
    _weights = null;
    _recents = null;
  }

  static bool _same(List<String> a, List<String>? b) {
    if (b == null || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static List<String> _union(List<String> first, List<String> then) => <String>[
    ...first,
    ...then.where((s) => !first.contains(s)),
  ];

  Future<void> _merge(String uid) async {
    final shortlist = ref.read(shortlistProvider.notifier);
    final weights = ref.read(weightsProvider.notifier);
    final recents = ref.read(recentHitsProvider.notifier);
    try {
      // 복원 전에 읽으면 빈 목록을 이 기기의 상태로 착각한다.
      await Future.wait(<Future<void>>[
        shortlist.ready,
        weights.ready,
        recents.ready,
      ]);
      final remote = await _service.read(uid);
      if (!ref.mounted || ref.read(currentUserProvider)?.uid != uid) return;

      final nextShortlist = _union(
        remote.shortlist ?? const <String>[],
        ref.read(shortlistProvider),
      );
      final TpWeights nextWeights = remote.weights ?? ref.read(weightsProvider);
      final nextRecents = _union(
        ref.read(recentHitsProvider),
        remote.recents ?? const <String>[],
      ).take(RecentHitsNotifier.cap).toList(growable: false);

      _shortlist = nextShortlist;
      _weights = nextWeights;
      _recents = nextRecents;
      await Future.wait(<Future<void>>[
        shortlist.adopt(nextShortlist),
        if (remote.weights != null) weights.adopt(nextWeights),
        recents.adopt(nextRecents),
        if (!_same(nextShortlist, remote.shortlist))
          _service.writeShortlist(uid, nextShortlist),
        if (remote.weights == null) _service.writeWeights(uid, nextWeights),
        if (!_same(nextRecents, remote.recents))
          _service.writeRecents(uid, nextRecents),
      ]);
      if (!ref.mounted || ref.read(currentUserProvider)?.uid != uid) return;
      _merged = uid;
      _watch = _service.watch(uid).listen(_onRemote, onError: _onWatchError);
    } catch (e, s) {
      // 못 맞춰도 로컬은 그대로 돈다. 다음 로그인에 다시 시도한다.
      TpErrors.record(e, s, reason: 'account.merge');
    }
  }

  /// 다른 기기에서 바뀐 것.
  void _onRemote(AccountState remote) {
    if (!ref.mounted || _merged == null) return;
    final shortlist = remote.shortlist;
    if (shortlist != null && !_same(shortlist, ref.read(shortlistProvider))) {
      _shortlist = shortlist;
      unawaited(ref.read(shortlistProvider.notifier).adopt(shortlist));
    }
    final weights = remote.weights;
    // 끄는 중이면 사람이 이긴다. 손을 떼면 그 값이 올라간다.
    if (weights != null &&
        _weightsTimer?.isActive != true &&
        weights != ref.read(weightsProvider)) {
      _weights = weights;
      unawaited(ref.read(weightsProvider.notifier).adopt(weights));
    }
    final recents = remote.recents;
    if (recents != null && !_same(recents, ref.read(recentHitsProvider))) {
      _recents = recents;
      unawaited(ref.read(recentHitsProvider.notifier).adopt(recents));
    }
  }

  void _onWatchError(Object e, StackTrace s) =>
      TpErrors.record(e, s, reason: 'account.watch');

  Future<void> _push(String what, Future<void> Function() write) async {
    try {
      await write();
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'account.push.$what');
    }
  }
}

final accountSyncProvider = NotifierProvider<AccountSync, void>(
  AccountSync.new,
);
