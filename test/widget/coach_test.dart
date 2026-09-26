import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/router.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/shared/coach/tp_coach.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/fake_auth.dart';
import '../support/harness.dart';

Future<void> _pump(WidgetTester tester, {Map<String, Object>? prefs}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'shortlist_slugs': <String>['galaxy-s25', 'pixel-9-pro'],
    ...?prefs,
  });
  await pumpApp(
    tester,
    size: const Size(700, 1600),
    overrides: <Override>[
      authServiceProvider.overrideWithValue(FakeAuthService()),
      askServiceProvider.overrideWithValue(const LocalAskService()),
    ],
  );
}

/// 도착 연출이 끝나고 안내가 뜰 때까지. 먼저 한 프레임 그려야 예약이 잡힌다.
Future<void> _arrive(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  setUp(initLocalization);
  setUp(() => TpCoach.enabled = true);
  tearDown(() {
    TpCoach.dismiss();
    TpCoach.enabled = false;
  });

  testWidgets('오늘에 처음 오면 결론 카드부터 차례로 짚는다', (tester) async {
    await _pump(tester);
    await _arrive(tester);

    expect(find.text(K.coachVerdict.tr()), findsOneWidget);
    expect(find.text('1/5'), findsOneWidget);

    await tester.tap(find.text(K.next.tr()));
    await tester.pumpAndSettle();
    expect(find.text(K.coachWeights.tr()), findsOneWidget);

    // 막 아무 데나 눌러도 다음.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text(K.coachAsk.tr()), findsOneWidget);

    await tester.tap(find.text(K.next.tr()));
    await tester.pumpAndSettle();
    await tester.tap(find.text(K.next.tr()));
    await tester.pumpAndSettle();
    expect(find.text(K.coachSearch.tr()), findsOneWidget);
    await tester.tap(find.text(K.coachDone.tr()));
    await tester.pumpAndSettle();

    expect(TpCoach.showing, isFalse);
    expect(await TpCoach.seen('today'), isTrue);
  });

  testWidgets('한 번 봤으면 다시 안 뜬다', (tester) async {
    await _pump(tester, prefs: <String, Object>{'coach_seen_today': true});
    await _arrive(tester);

    expect(find.text(K.coachVerdict.tr()), findsNothing);
    expect(TpCoach.showing, isFalse);
  });

  testWidgets('관심 목록이 비었으면 결론·가중치 단계는 건너뛴다', (tester) async {
    await _pump(tester, prefs: <String, Object>{'shortlist_slugs': <String>[]});
    await _arrive(tester);

    expect(find.text(K.coachVerdict.tr()), findsNothing);
    expect(find.text(K.coachAsk.tr()), findsOneWidget);
    expect(find.text('1/3'), findsOneWidget);
  });

  testWidgets('다시 보기는 본 표시를 전부 지운다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'coach_seen_today': true,
      'coach_seen_browse': true,
      'shortlist_slugs': <String>['galaxy-s25'],
    });
    await TpCoach.resetAll();

    expect(await TpCoach.seen('today'), isFalse);
    expect(await TpCoach.seen('browse'), isFalse);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('shortlist_slugs'), isNotEmpty);
  });

  testWidgets('둘러보기는 따로, 처음 갈 때 뜬다', (tester) async {
    await _pump(tester, prefs: <String, Object>{'coach_seen_today': true});
    await _arrive(tester);

    final at = tester.element(find.byType(Navigator).first);
    GoRouter.of(at).go(TpRoute.browse);
    await _arrive(tester);

    expect(find.text(K.coachCategory.tr()), findsOneWidget);
    expect(await TpCoach.seen('browse'), isTrue);
  });
}
