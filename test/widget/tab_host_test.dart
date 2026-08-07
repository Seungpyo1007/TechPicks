
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
  Future<TpUser?> signIn(AuthMethod m, {String? email, String? password}) async =>
      null;

  @override
  Future<void> signOut() async {}
}

ProviderContainer? _container;

Future<void> _pump(WidgetTester tester, {TpChrome chrome = TpChrome.ios}) async {
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
