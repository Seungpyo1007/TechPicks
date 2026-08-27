import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

void main() {
  testWidgets('한국어로 렌더링된다', (tester) async {
    await initLocalization(locale: const Locale('ko', 'KR'));
    await pumpScreen(tester, const RankScreen());

    expect(find.text('랭킹'), findsWidgets);
    expect(find.text('스마트폰'), findsOneWidget);
    // "정렬 기준" 눈썹은 빠졌다. 그 자리에 브랜드 칩이 있다.
    expect(find.text('브랜드'), findsOneWidget);
    expect(find.text('TP 지수'), findsWidgets);
    // 영어 문구가 남아 있으면 하드코딩이 덜 걷힌 것이다.
    expect(find.text('Rankings'), findsNothing);
    expect(find.text('Rank by'), findsNothing);
  });

  testWidgets('온보딩 제목의 줄바꿈이 한국어에서도 유지된다', (tester) async {
    await initLocalization(locale: const Locale('ko', 'KR'));
    await pumpScreen(tester, const OnboardingScreen());

    final title = K.onboarding.first.title.tr();
    expect(title.contains('\n'), isTrue);
    expect(find.text(title), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
  });

  testWidgets('영어로 돌아온다', (tester) async {
    await initLocalization();
    await pumpScreen(tester, const RankScreen());

    expect(find.text('Rankings'), findsWidgets);
    expect(find.text('랭킹'), findsNothing);
  });
}
