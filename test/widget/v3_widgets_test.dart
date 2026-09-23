import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/shared/widgets/tp_group.dart';
import 'package:techpicks/shared/widgets/tp_page.dart';

import '../support/harness.dart';

Widget _host(TpChrome chrome, Widget child) =>
    MaterialApp(theme: AppTheme.of(chrome), home: child);

void main() {
  setUp(initLocalization);

  for (final chrome in TpChrome.values) {
    testWidgets('$chrome — 페이지가 제목과 목록을 그린다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          chrome,
          TpPage(
            title: '둘러보기',
            actions: <TpBarAction>[
              TpBarAction(label: '정렬', icon: Icons.sort, onTap: () => taps++),
            ],
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: TpGroup(
                  header: '모바일',
                  footer: '설명',
                  children: <Widget>[
                    TpRow(title: '첫 줄', onTap: () => taps++),
                    const TpRow(title: '고른 줄', checked: true),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.text('둘러보기'), findsWidgets);
      expect(find.text('모바일'), findsOneWidget);
      await tester.tap(find.text('첫 줄'));
      await tester.tap(
        chrome == TpChrome.ios
            ? find.bySemanticsLabel('정렬')
            : find.byTooltip('정렬'),
      );
      expect(taps, 2);
    });
  }

  testWidgets('고른 줄은 선택 상태를 알린다', (tester) async {
    await tester.pumpWidget(
      _host(
        TpChrome.ios,
        const Material(child: TpRow(title: '한국어', checked: true)),
      ),
    );
    expect(
      tester.getSemantics(find.text('한국어')),
      matchesSemantics(isSelected: true, hasSelectedState: true, label: '한국어'),
    );
  });
}
