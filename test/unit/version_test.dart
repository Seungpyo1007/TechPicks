import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/feature/you/you_screen.dart';

/// 화면에 찍는 버전과 빌드 버전이 어긋나지 않게.
///
/// 명세 §13 이 푸터를 `TechPicks version 2.0.0 · Apache-2.0` 으로 못박았다.
/// 그 문자열은 코드에 상수로 있고 pubspec 은 따로 논다 — 한쪽만 올리면
/// 앱이 거짓말을 한다.
void main() {
  test('pubspec 과 푸터의 버전이 같다', () {
    final line = File('pubspec.yaml')
        .readAsLinesSync()
        .firstWhere((l) => l.startsWith('version:'));
    // `2.0.0+1` 에서 빌드 번호를 뗀다.
    final pubspec = line.split(':')[1].trim().split('+').first;

    expect(YouScreen.version, pubspec);
    expect(YouScreen.versionLine, contains(pubspec));
  });

  test('푸터는 명세 문자열 그대로다', () {
    expect(YouScreen.versionLine, 'TechPicks version 2.0.0 · Apache-2.0');
  });
}
