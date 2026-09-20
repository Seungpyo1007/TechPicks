import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/tp_money.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';

import '../support/harness.dart';

/// 원화로 바꿨을 때 넘치는 곳이 없는지.
///
/// `$799` 는 네 글자, `₩1,097,027` 은 열 글자다. 랭킹 행이 제일 빡빡한데,
/// 거기 값 칸은 `_RankRow._valueWidth` 로 110pt 에 묶여 있다 — 예전에
/// 한도가 없어서 `$1,000,000` 이 이름 폭을 0 으로 만든 적이 있다.
///
/// 배율까지 같이 본다. 글자가 1.6배가 되면 열 글자가 열여섯 글자 자리를
/// 먹는다.

/// 시계도 네트워크도 안 보는 고정 환율.
final _rate = FxRate(
  krwPerUsd: 1373,
  asOf: DateTime.utc(2026, 9, 19),
  origin: RateOrigin.live,
);

List<Override> get _krw => <Override>[
  moneyProvider.overrideWithValue(TpMoney.krw(_rate)),
];

Future<void> _pump(
  WidgetTester tester,
  Widget screen, {
  double textScale = 1,
  TpChrome chrome = TpChrome.ios,
}) => pumpScreen(
  tester,
  screen,
  chrome: chrome,
  textScale: textScale,
  size: const Size(402, 3200),
  overrides: _krw,
);

void main() {
  setUp(initLocalization);
  setUp(seedHomeContent);

  for (final scale in <double>[1, 1.3, 1.6]) {
    testWidgets('랭킹이 원화에서 안 넘친다 · ${scale}x', (tester) async {
      await _pump(tester, const RankScreen(), textScale: scale);

      expect(tester.takeException(), isNull);
      expect(find.textContaining('₩'), findsWidgets);
    });

    testWidgets('비교가 원화에서 안 넘친다 · ${scale}x', (tester) async {
      await _pump(tester, const CompareScreen(), textScale: scale);

      expect(tester.takeException(), isNull);
    });

    testWidgets('홈이 원화에서 안 넘친다 · ${scale}x', (tester) async {
      await _pump(tester, const HomeScreen(), textScale: scale);

      expect(tester.takeException(), isNull);
    });

    testWidgets('상세가 원화에서 안 넘친다 · ${scale}x', (tester) async {
      await _pump(
        tester,
        const DetailScreen(slug: 'galaxy-s25'),
        textScale: scale,
      );

      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('두 크롬 모두에서 원화가 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, const RankScreen(), chrome: chrome);
      expect(find.textContaining('₩'), findsWidgets, reason: chrome.name);
    }
  });

  testWidgets('달러로 되돌리면 달러가 나온다', (tester) async {
    await pumpScreen(
      tester,
      const RankScreen(),
      size: const Size(402, 3200),
      overrides: <Override>[
        moneyProvider.overrideWithValue(const TpMoney.usd()),
      ],
    );

    expect(find.textContaining(r'$'), findsWidgets);
    expect(find.textContaining('₩'), findsNothing);
  });
}
