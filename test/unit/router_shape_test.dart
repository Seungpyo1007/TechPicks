import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/router.dart';
import 'package:techpicks/app/shell/tp_tab.dart';

/// 라우터의 **모양**을 지킨다.
///
/// 여기서 보는 것들은 어긋나도 오류를 안 낸다. 브랜치 순서가 틀어지면 홈을
/// 눌렀는데 내 정보가 열리고, 자식 라우트 순서가 틀어지면 `/compare/pick/a`
/// 가 a='pick' 인 비교로 잡힌다 — 둘 다 조용히 잘못 동작한다. 그래서 화면을
/// 띄우지 않고 구조만 본다.

/// 셸 브랜치를 꺼낸다.
List<StatefulShellBranch> _branches(GoRouter router) {
  final shell = router.configuration.routes
      .whereType<StatefulShellRoute>()
      .single;
  return shell.branches;
}

/// 브랜치가 처음 여는 자리. 첫 자식 GoRoute 의 경로다.
String _initial(StatefulShellBranch branch) =>
    branch.routes.whereType<GoRoute>().first.path;

/// 화면을 띄우지 않고 라우터만 만든다. 구조만 보면 되므로 위젯이 필요 없다.
GoRouter _router() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container.read(routerProvider);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test('브랜치 수와 순서가 TpTab.values 와 같다', () {
    // TabHost 가 `TpTab.values[shell.currentIndex]` 로 지금 탭을 읽는다.
    // 이 둘이 어긋나면 탭을 눌렀을 때 **다른 탭이 열리고**, 아무 오류도
    // 안 난다.
    final branches = _branches(_router());

    expect(branches, hasLength(TpTab.values.length));
    for (var i = 0; i < TpTab.values.length; i++) {
      expect(
        _initial(branches[i]),
        TpRoute.of(TpTab.values[i]),
        reason: '$i번 브랜치는 ${TpTab.values[i].name} 이어야 한다',
      );
    }
  });

  test('모든 브랜치를 미리 짓는다', () {
    // 게을리 지으면 각 탭의 **첫 방문에만** 본문이 옅게 들어오는 전환이
    // 빠진다. 한 브랜치만 빠뜨려도 그 탭에서만 그렇다 — 눈으로 잡기 어렵다.
    expect(_branches(_router()).every((b) => b.preload), isTrue);
  });

  test('TpRoute.of 가 모든 탭을 다룬다', () {
    // switch 가 exhaustive 라 컴파일이 막아주지만, 값이 겹치는 것은 못 막는다.
    final paths = TpTab.values.map(TpRoute.of).toList();

    expect(paths.toSet(), hasLength(TpTab.values.length));
    expect(paths.every((p) => p.startsWith('/')), isTrue);
  });
}
