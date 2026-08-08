import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:riverpod/misc.dart' show Override;

import '../support/harness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/shell/tp_tab.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/scan/scan_screen.dart';

class _NoAuth implements AuthService {
  @override
  TpUser? get current => null;

  @override
  Future<TpUser?> signIn(
    AuthMethod m, {
    String? email,
    String? password,
  }) async => null;

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<void> signOut() async {}
}

ProviderContainer? _container;

Future<void> _pump(
  WidgetTester tester, {
  TpChrome chrome = TpChrome.ios,
}) async {
  _container = await pumpScreen(
    tester,
    const TabHost(),
    chrome: chrome,
    size: const Size(1200, 3000),
    overrides: <Override>[
      authServiceProvider.overrideWithValue(_NoAuth()),
      askServiceProvider.overrideWithValue(const LocalAskService()),
    ],
  );
}

void main() {
  group('이번 주 변동', _moversRoundTrip);
  group('비교에서 상담으로', _askFromCompare);
  group('비교 열 고르기', _pickerSlots);

  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('홈으로 시작한다', (tester) async {
    await _pump(tester);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('탭을 눌러 다섯 화면을 오간다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(K.tab(TpTab.rank).tr()));
    await tester.pumpAndSettle();
    expect(find.text('Rankings'), findsOneWidget);

    await tester.tap(find.text(K.tab(TpTab.compare).tr()));
    await tester.pumpAndSettle();
    expect(find.text('Compare'), findsWidgets);

    await tester.tap(find.text(K.tab(TpTab.ask).tr()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Give me a budget'), findsOneWidget);

    await tester.tap(find.text(K.tab(TpTab.you).tr()));
    await tester.pumpAndSettle();
    // 탭 라벨과 화면 제목이 같은 단어다.
    expect(find.text('You'), findsWidgets);
  });

  testWidgets('랭킹에서 기기를 누르면 상세가 올라온다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(K.tab(TpTab.rank).tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galaxy S25 Ultra'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('Add to shortlist'), findsOneWidget);
  });

  testWidgets('상세의 Compare 가 비교 탭으로 보내고 A 슬롯을 채운다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(K.tab(TpTab.rank).tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OnePlus 13'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Compare'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsNothing);
    expect(_container!.read(compareProvider).a, 'oneplus-13');
  });

  testWidgets('비교 열 머리에서 선택 시트가 열린다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(K.tab(TpTab.compare).tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galaxy S25 Ultra'));
    await tester.pumpAndSettle();

    expect(find.byType(PickerScreen), findsOneWidget);
    expect(_container!.read(pickSlotProvider), CompareSide.a);
  });

  testWidgets('랭킹에서 스캔을 연다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(K.tab(TpTab.rank).tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan a device'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ScanScreen), findsOneWidget);
  });

  testWidgets('Android 는 스캔이 FAB 로 나온다', (tester) async {
    await _pump(tester, chrome: TpChrome.android);

    await tester.tap(find.text(K.tab(TpTab.rank).tr()));
    await tester.pumpAndSettle();

    // iOS 인라인 버튼은 없고 FAB 라벨만 있다.
    expect(find.text('Scan a device'), findsNothing);
    expect(find.text('Scan'), findsOneWidget);
  });

  testWidgets('홈의 Ask why 가 상담 탭으로 간다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25'],
    });
    await _pump(tester);

    await tester.tap(find.text('Ask why'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Give me a budget'), findsOneWidget);
  });
}

/// 홈의 "이번 주 변동".
///
/// 변동은 지난 실행의 순위와 비교해서 나온다. 앱이 지금 순위를 남기지 않으면
/// 스냅샷이 영영 비어 있고 섹션이 한 번도 안 뜬다.
void _moversRoundTrip() {
  testWidgets('앱을 켜면 지금 순위를 다음 실행용으로 남긴다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await initLocalization();

    await pumpScreen(
      tester,
      const TabHost(),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('rank_snapshot_slugs');
    expect(saved, isNotNull);
    expect(saved, isNotEmpty);
    // 카탈로그 10종이 전부 들어간다.
    expect(saved!.length, 10);
    expect(saved.first, 'galaxy-s25-ultra');
  });

  testWidgets('지난 순위가 다르면 변동이 잡힌다', (tester) async {
    // 지난 실행에서는 iPhone 이 1위였다고 둔다.
    await initLocalization();
    // initLocalization 이 prefs 목을 비운다. 그 뒤에 심어야 한다.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'rank_snapshot_slugs': <String>['iphone-16-pro-max', 'galaxy-s25-ultra'],
    });

    final container = await pumpScreen(
      tester,
      const TabHost(),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    final movers = container.read(moversProvider);
    expect(movers, isNotEmpty);
    expect(find.text(K.movers.tr()), findsOneWidget);
  });

  testWidgets('스냅샷을 남겨도 이번 실행의 변동은 그대로다', (tester) async {
    // 남기면서 state 까지 덮으면 변동이 항상 0 이 된다.
    await initLocalization();
    // initLocalization 이 prefs 목을 비운다. 그 뒤에 심어야 한다.
    SharedPreferences.setMockInitialValues(<String, Object>{
      'rank_snapshot_slugs': <String>['oneplus-13r', 'galaxy-s25-ultra'],
    });

    final container = await pumpScreen(
      tester,
      const TabHost(),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    expect(container.read(rankSnapshotProvider), <String>[
      'oneplus-13r',
      'galaxy-s25-ultra',
    ]);
    expect(container.read(moversProvider), isNotEmpty);
  });
}

/// 비교 화면의 "왜?".
void _askFromCompare() {
  testWidgets('비교 중인 두 기기를 상담이 물어본다', (tester) async {
    await initLocalization();
    final container = await pumpScreen(
      tester,
      const TabHost(initialTab: TpTab.compare),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(K.askWhy.tr()));
    await tester.pumpAndSettle();

    final messages = container.read(askProvider);
    // 씨앗 인사 + 질문 + 답.
    expect(messages.length, 3);
    expect(messages[1].text, 'Galaxy S25 Ultra or iPhone 16 Pro Max?');
    expect(messages[2].answer, isNotNull);
  });

  testWidgets('비교할 게 없으면 물어볼 버튼도 없다', (tester) async {
    await initLocalization();
    final container = await pumpScreen(
      tester,
      const TabHost(initialTab: TpTab.compare),
      catalogAsset: missingCatalogAsset,
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text(K.askWhy.tr()), findsNothing);
    expect(container.read(askProvider).length, 1);
    expect(tester.takeException(), isNull);
  });
}

/// 명세 §7·§8 — 열 머리를 누르면 picker 가 그 열에 쓴다.
void _pickerSlots() {
  Future<void> pick(
    WidgetTester tester,
    String columnName,
    String pickName,
  ) async {
    await tester.tap(find.text(columnName).first);
    await tester.pumpAndSettle();
    expect(find.byType(PickerScreen), findsOneWidget);

    await tester.tap(find.text(pickName).first);
    await tester.pumpAndSettle();
  }

  testWidgets('왼쪽 머리를 누르면 A 에 쓴다', (tester) async {
    await initLocalization();
    final container = await pumpScreen(
      tester,
      const TabHost(initialTab: TpTab.compare),
      size: const Size(1200, 3200),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );

    expect(container.read(compareProvider).a, 'galaxy-s25-ultra');
    await pick(tester, 'Galaxy S25 Ultra', 'Pixel 9 Pro XL');

    expect(container.read(compareProvider).a, 'pixel-9-pro-xl');
    expect(container.read(compareProvider).b, 'iphone-16-pro-max');
  });

  testWidgets('오른쪽 머리를 누르면 B 에 쓴다', (tester) async {
    await initLocalization();
    final container = await pumpScreen(
      tester,
      const TabHost(initialTab: TpTab.compare),
      size: const Size(1200, 3200),
      overrides: <Override>[
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );

    await pick(tester, 'iPhone 16 Pro Max', 'OnePlus 13');

    expect(container.read(compareProvider).a, 'galaxy-s25-ultra');
    expect(container.read(compareProvider).b, 'oneplus-13');
  });
}
