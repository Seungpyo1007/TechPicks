import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/shell/tp_tab.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/feature/compare/picker_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/scan/scan_screen.dart';

class _FileBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async =>
      ByteData.view(File(key).readAsBytesSync().buffer);

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      utf8.decode(File(key).readAsBytesSync());
}

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
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        catalogRepositoryProvider.overrideWithValue(
          CatalogRepository(bundle: _FileBundle()),
        ),
        authServiceProvider.overrideWithValue(_NoAuth()),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
      child: MaterialApp(
        theme: AppTheme.of(chrome),
        home: const TabHost(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  _container =
      ProviderScope.containerOf(tester.element(find.byType(MaterialApp)));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('홈으로 시작한다', (tester) async {
    await _pump(tester);
    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('탭을 눌러 다섯 화면을 오간다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(TpTab.rank.key));
    await tester.pumpAndSettle();
    expect(find.text('Rankings'), findsOneWidget);

    await tester.tap(find.text(TpTab.compare.key));
    await tester.pumpAndSettle();
    expect(find.text('Compare'), findsWidgets);

    await tester.tap(find.text(TpTab.ask.key));
    await tester.pumpAndSettle();
    expect(find.textContaining('Give me a budget'), findsOneWidget);

    await tester.tap(find.text(TpTab.you.key));
    await tester.pumpAndSettle();
    expect(find.text('You'), findsOneWidget);
  });

  testWidgets('랭킹에서 기기를 누르면 상세가 올라온다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(TpTab.rank.key));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galaxy S25 Ultra'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('Add to shortlist'), findsOneWidget);
  });

  testWidgets('상세의 Compare 가 비교 탭으로 보내고 A 슬롯을 채운다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(TpTab.rank.key));
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

    await tester.tap(find.text(TpTab.compare.key));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Galaxy S25 Ultra'));
    await tester.pumpAndSettle();

    expect(find.byType(PickerScreen), findsOneWidget);
    expect(_container!.read(pickSlotProvider), CompareSide.a);
  });

  testWidgets('랭킹에서 스캔을 연다', (tester) async {
    await _pump(tester);

    await tester.tap(find.text(TpTab.rank.key));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Scan a device'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ScanScreen), findsOneWidget);
  });

  testWidgets('Android 는 스캔이 FAB 로 나온다', (tester) async {
    await _pump(tester, chrome: TpChrome.android);

    await tester.tap(find.text(TpTab.rank.key));
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
