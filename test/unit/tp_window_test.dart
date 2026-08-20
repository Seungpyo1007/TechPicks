import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/shell/tp_window.dart';
import 'package:techpicks/app/theme/app_theme.dart';

/// 창 등급의 경계.
///
/// 이 앱은 폰 프레임만 보고 만들어졌다. 경계를 잘못 잡으면 폰에서 데스크톱
/// 레이아웃이 나오거나 그 반대가 된다.
void main() {
  Future<TpWindowClass> classAt(WidgetTester tester, double width) async {
    late TpWindowClass seen;
    await tester.pumpWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Builder(
          builder: (context) {
            seen = tpWindowClass(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return seen;
  }

  testWidgets('경계값', (tester) async {
    expect(await classAt(tester, 599), TpWindowClass.compact);
    expect(await classAt(tester, 600), TpWindowClass.medium);
    expect(await classAt(tester, 1023), TpWindowClass.medium);
    expect(await classAt(tester, 1024), TpWindowClass.expanded);
  });

  // 오래 주석은 "데스크톱·웹은 M3 로 떨어진다"고 적어놨는데 사실이 아니었다.
  // 웹에서 defaultTargetPlatform 은 브라우저 UA 에서 나온다.
  test('웹은 UA 가 뭐라 하든 M3 다', () {
    for (final p in TargetPlatform.values) {
      expect(TpChrome.forPlatform(p, true), TpChrome.android, reason: p.name);
    }
  });
}
