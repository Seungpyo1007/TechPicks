import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/service/link_opener.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/feature/you/you_screen.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';

/// 실제 기기 크기에서 화면 아래쪽이 눌리는지.
///
/// 다른 위젯 테스트는 세로를 3000px 로 늘려 스크롤을 없앤다. 화면에 다 들어가
/// 있으면 탭 바 아래로 밀려난 요소나 잘린 히트 영역을 못 잡는다. 여기서는
/// 기기 크기 그대로 올리고, 스크롤을 끝까지 내린 뒤 마지막 줄을 누른다.
///
/// 시뮬레이터에서 로그아웃이 안 눌리는 것처럼 보인 적이 있다. 실제로는 누른
/// 자리가 줄 아래였는데, 그때 이 크기의 테스트가 없어서 코드 문제인지
/// 아닌지를 바로 못 갈랐다.
void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  /// (프레임, 안전 영역 위, 안전 영역 아래).
  const List<(String, Size, double, double)> devices =
      <(String, Size, double, double)>[
        ('iPhone 17 Pro', Size(402, 874), 59, 34),
        ('iPhone 17 Pro Max', Size(440, 956), 62, 34),
        ('iPhone SE', Size(375, 667), 20, 0),
      ];

  for (final (name, frame, top, bottom) in devices) {
    testWidgets('$name — 목록 끝의 줄이 눌린다', (tester) async {
      var logouts = 0;
      var licenses = 0;

      tester.view.physicalSize = frame;
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = FakeViewPadding(top: top, bottom: bottom);
      tester.view.padding = FakeViewPadding(top: top, bottom: bottom);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: <Override>[
            linkOpenerProvider.overrideWithValue(
              _CountingOpener(() => licenses++),
            ),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.of(TpChrome.ios),
            home: YouScreen(onLogout: () => logouts++),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 끝까지 내린다.
      await tester.fling(find.byType(ListView), const Offset(0, -600), 2000);
      await tester.pumpAndSettle();

      // 화면 좌표로 누른다. find.text 로 누르면 위젯이 화면 밖이어도 통과한다.
      final logout = tester.getRect(find.text(K.logout.tr()));
      expect(
        logout.bottom,
        lessThan(frame.height),
        reason: '$name 로그아웃 줄이 화면 밖',
      );
      await tester.tapAt(logout.center);
      await tester.pump();
      expect(logouts, 1, reason: '$name 로그아웃');

      final version = tester.getRect(find.text(YouScreen.versionLine));
      expect(
        version.bottom,
        lessThan(frame.height),
        reason: '$name 버전 줄이 화면 밖',
      );
      await tester.tapAt(version.center);
      await tester.pump();
      expect(licenses, 1, reason: '$name 라이선스 링크');
    });
  }
}

class _CountingOpener implements LinkOpener {
  _CountingOpener(this.onOpen);

  final void Function() onOpen;

  @override
  Future<bool> open(Uri url) async {
    onOpen();
    return true;
  }
}
