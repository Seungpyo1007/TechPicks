import 'dart:async';
import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/dto/smartphone.dart';

import '../data/repository/catalog_repository.dart';
import '../data/repository/tech_api_repository.dart';
import '../data/service/ask_service.dart';
import '../data/service/auth_service.dart';
import '../data/service/device_info_service.dart';
import '../domain/model/ask_answer.dart';
import '../domain/model/device_specs.dart';
import '../domain/model/movers.dart';
import '../domain/model/scan_match.dart';
import '../domain/model/tp_index.dart';
import '../domain/model/processor.dart';
import '../domain/model/ranking.dart';
import '../domain/model/tp_weights.dart';
import '../feature/rank/rank_category.dart';
import '../shared/copy_keys.dart';
import 'locale_controller.dart';

/// 앱에 실린 큐레이션 카탈로그. 랭킹·홈·비교가 여기서 목록을 받는다.
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepository(),
);

/// TechAPI 원격. 카탈로그에 없는 기기를 상세로 열 때 쓴다.
final techApiRepositoryProvider = Provider<TechApiRepository>(
  (ref) => TechApiRepository(),
);

final catalogProvider = FutureProvider<Catalog>(
  (ref) async {
    final result = await ref.watch(catalogRepositoryProvider).load();
    return result.fold(
      (c) => c,
      (f) => throw f,
    );
  },
  // 앱에 같이 실린 파일이라 재시도해도 결과가 달라지지 않는다. Riverpod 3 의
  // 기본 재시도를 켜두면 실패한 뒤에도 상태가 계속 `AsyncLoading` 이라
  // 화면이 영원히 로딩으로 보인다.
  retry: (_, __) => null,
);

/// 사용자 가중치.
///
/// 화면 여러 곳이 이걸 읽는다. You 화면에서 슬라이더를 움직이면 랭킹·홈·상세의
/// 지수가 한꺼번에 다시 계산되어야 하므로 앱 전역 상태다.
class WeightsNotifier extends Notifier<TpWeights> {
  static const String _prefsKey = 'tp_weights';

  @override
  TpWeights build() {
    unawaited(_restore());
    return TpWeights.defaults;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      state = TpWeights.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on FormatException {
      // 저장값이 깨졌으면 기본값을 그대로 둔다.
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(state.toJson()));
  }

  void set(TpWeights next) {
    state = next;
    unawaited(_persist());
  }

  /// 축 하나만 바꾼다. 슬라이더가 이걸 부른다.
  void setAxis(TpAxisKind kind, double value) => set(switch (kind) {
        TpAxisKind.performance => state.copyWith(performance: value),
        TpAxisKind.camera => state.copyWith(camera: value),
        TpAxisKind.display => state.copyWith(display: value),
        TpAxisKind.battery => state.copyWith(battery: value),
        TpAxisKind.value => state.copyWith(value: value),
      });

  void reset() => set(TpWeights.defaults);
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
  return ProcessorRanking.of(
    switch (segment) {
      ProcessorSegment.mobile =>
        catalog.socs.map(Processor.fromSoc).toList(growable: false),
      ProcessorSegment.laptop =>
        catalog.cpus.map(Processor.fromCpu).toList(growable: false),
    },
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
  retry: (_, __) => null,
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

  String? operator [](CompareSide side) =>
      side == CompareSide.a ? a : b;

  bool get isComplete => a != null && b != null;
}

class CompareNotifier extends Notifier<CompareSlots> {
  @override
  CompareSlots build() {
    // 카탈로그가 오면 앞의 둘로 채운다. 빈 비교 화면부터 보여주는 것보다
    // 뭔가 비교하고 있는 상태로 시작하는 편이 낫다.
    final catalog = ref.watch(catalogProvider).value;
    final phones = catalog?.smartphones ?? const <Smartphone>[];
    if (phones.length < 2) return const CompareSlots();
    return CompareSlots(a: phones[0].slug, b: phones[1].slug);
  }

  void pick(CompareSide side, String slug) => state = state.write(side, slug);
}

final compareProvider =
    NotifierProvider<CompareNotifier, CompareSlots>(CompareNotifier.new);

/// 어느 슬롯을 고르는 중인지. picker 가 읽는다.
class PickSlotNotifier extends Notifier<CompareSide> {
  @override
  CompareSide build() => CompareSide.a;

  void set(CompareSide side) => state = side;
}

final pickSlotProvider =
    NotifierProvider<PickSlotNotifier, CompareSide>(PickSlotNotifier.new);

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
    unawaited(_restore());
    return const <String>[];
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getStringList(_prefsKey) ?? const <String>[];
  }

  /// 지금 순위를 다음 실행의 비교 대상으로 남긴다.
  Future<void> save(List<String> slugs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, slugs);
  }
}

final rankSnapshotProvider =
    NotifierProvider<RankSnapshotNotifier, List<String>>(
  RankSnapshotNotifier.new,
);

/// 이번 주 변동. 저장된 순위가 없으면 빈 목록이라 섹션이 통째로 빠진다.
final moversProvider = Provider<List<Mover>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const <Mover>[];

  // 변동은 기본 가중치 기준이다. 사용자가 슬라이더를 만질 때마다 "이번 주
  // 변동"이 바뀌면 그건 시간 변화가 아니라 취향 변화다.
  final ranked = Ranking.of(catalog.smartphones, RankAxis.tpIndex);
  return Movers.between(
    previous: ref.watch(rankSnapshotProvider),
    current: ranked
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
  final ranked = Ranking.of(picked.toList(growable: false), RankAxis.tpIndex, weights);
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

/// AI 상담. 기본은 로컬 구현이다.
///
/// Gemini 로 바꾸려면 여기만 갈아끼운다. Firebase 설정이 없는 기기에서도
/// 화면이 죽지 않아야 해서 기본값을 로컬로 뒀다.
final askServiceProvider = Provider<AskService>(
  (ref) => LocalAskService(weights: ref.watch(weightsProvider)),
);

/// 대화 내용.
class AskNotifier extends Notifier<List<AskMessage>> {
  @override
  List<AskMessage> build() => <AskMessage>[AskMessage.ai(K.chatSeed.tr())];

  bool _busy = false;
  bool get isBusy => _busy;

  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || _busy) return;

    _busy = true;
    // 사용자 말풍선을 먼저 올린다. 응답을 기다리는 동안 화면이 멈춘 것처럼
    // 보이지 않게 한다.
    state = <AskMessage>[...state, AskMessage.user(text)];

    // 카탈로그를 못 읽으면 답할 근거가 없다. 예외를 그대로 올리면 화면이
    // 멈춘 것처럼 보이고 _busy 도 안 풀린다.
    AskAnswer? answer;
    try {
      final catalog = await ref.read(catalogProvider.future);
      answer = await ref.read(askServiceProvider).ask(text, catalog.smartphones);
    } catch (_) {
      answer = null;
    }

    state = <AskMessage>[
      ...state,
      answer == null
          ? AskMessage.ai(K.askFailed.tr(), failed: true)
          : AskMessage.ai(answer.pick, answer: answer),
    ];
    _busy = false;
  }

  /// 비교 화면에서 넘어올 때 두 기기를 미리 넣어준다.
  void seedWithDevices(String a, String b) {
    state = <AskMessage>[
      ...state,
      AskMessage.user('$a or $b?'),
    ];
  }
}

final askProvider =
    NotifierProvider<AskNotifier, List<AskMessage>>(AskNotifier.new);

/// 인증. 기본은 Firebase 구현이다.
final authServiceProvider = Provider<AuthService>(
  (ref) => FirebaseAuthService(),
);

/// 지금 로그인한 사람. 로그인·로그아웃할 때 갱신한다.
class CurrentUserNotifier extends Notifier<TpUser?> {
  @override
  TpUser? build() => ref.watch(authServiceProvider).current;

  Future<bool> signIn(AuthMethod method, {String? email, String? password}) async {
    final user = await ref
        .read(authServiceProvider)
        .signIn(method, email: email, password: password);
    if (user != null) state = user;
    return user != null;
  }

  Future<bool> signUp(String email, String password) async {
    final user = await ref
        .read(authServiceProvider)
        .signUp(email: email, password: password);
    if (user != null) state = user;
    return user != null;
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = null;
  }
}

final currentUserProvider =
    NotifierProvider<CurrentUserNotifier, TpUser?>(CurrentUserNotifier.new);

/// 온보딩을 봤는지. v1 의 is_tutorial_completed 키를 그대로 쓴다.
class OnboardingNotifier extends Notifier<bool> {
  static const String _prefsKey = 'is_tutorial_completed';

  @override
  bool build() {
    unawaited(_restore());
    return false;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> complete() async {
    state = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }
}

final onboardingDoneProvider =
    NotifierProvider<OnboardingNotifier, bool>(OnboardingNotifier.new);

/// 언어 전환. 앱은 화면에서 context 로 만들어 넣고, 테스트는 가짜를 끼운다.
final localeControllerProvider = Provider<LocaleController?>((ref) => null);

/// 알림 켬/끔. 아직 실제 푸시에 연결돼 있지 않고 설정만 기억한다.
class NotificationsNotifier extends Notifier<bool> {
  static const String _prefsKey = 'notifications_enabled';

  @override
  bool build() {
    unawaited(_restore());
    return true;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefsKey) ?? true;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, bool>(NotificationsNotifier.new);

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
