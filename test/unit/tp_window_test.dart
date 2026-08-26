import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/shell/tp_window.dart';

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
}
