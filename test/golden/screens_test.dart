import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/data/service/auth_service.dart';
import 'package:techpicks/domain/model/ask_answer.dart';
import 'package:techpicks/feature/ask/ask_screen.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/cpu/processor_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';
import 'package:techpicks/feature/home/home_screen.dart';
import 'package:techpicks/feature/login/login_screen.dart';
import 'package:techpicks/feature/onboarding/onboarding_screen.dart';
import 'package:techpicks/feature/rank/rank_screen.dart';
import 'package:techpicks/feature/you/you_screen.dart';

import '../support/harness.dart';
import 'golden_harness.dart';

/// 화면을 기기 프레임 크기로 굽는다.
///
/// 다른 위젯 테스트는 세로를 3000px 로 늘려 스크롤 없이 전부 보이게 하지만,
/// 골든은 실제로 사람이 보는 것과 같아야 의미가 있다. 첫 화면만 찍는다.
void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  goldenScenario('home_empty', '홈 — shortlist 비었을 때', (tester, chrome) async {
    await pumpScreen(
      tester,
      const HomeScreen(),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });

  goldenScenario('home', '홈 — 결론 카드', (tester, chrome) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['galaxy-s25', 'oneplus-13'],
    });
    await pumpScreen(
      tester,
      const HomeScreen(),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });

  goldenScenario('rank', '랭킹', (tester, chrome) async {
    await pumpScreen(
      tester,
      const RankScreen(),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });

  goldenScenario('processor', '프로세서', (tester, chrome) async {
    await pumpScreen(
      tester,
      const ProcessorScreen(),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });

  goldenScenario('detail', '상세', (tester, chrome) async {
    await pumpScreen(
      tester,
      const DetailScreen(slug: 'galaxy-s25'),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });

  goldenScenario('compare', '비교', (tester, chrome) async {
    await pumpScreen(
      tester,
      const CompareScreen(),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });

  goldenScenario('you', 'You — 가중치', (tester, chrome) async {
    await pumpScreen(
      tester,
      const YouScreen(name: 'Seungpyo', email: 'you@techpicks.app'),
      chrome: chrome,
      size: frameOf(chrome),
    );
  });

  goldenScenario('ask_empty', 'Ask — 안내와 제안 칩', (tester, chrome) async {
    await pumpScreen(
      tester,
      const AskScreen(),
      chrome: chrome,
      size: frameOf(chrome),
      overrides: <Override>[
        askServiceProvider.overrideWithValue(_StubAsk(_answer)),
      ],
    );
  });

  goldenScenario('ask_answer', 'Ask — 답변 표', (tester, chrome) async {
    await pumpScreen(
      tester,
      const AskScreen(),
      chrome: chrome,
      size: frameOf(chrome),
      overrides: <Override>[
        askServiceProvider.overrideWithValue(_StubAsk(_answer)),
      ],
    );
    await tester.enterText(find.byType(TextField), 'Best camera under \$900?');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
  });

  goldenScenario('onboarding', '온보딩 첫 장', (tester, chrome) async {
    await pumpScreen(
      tester,
      const OnboardingScreen(),
      chrome: chrome,
      size: frameOf(chrome),
      overrides: <Override>[authServiceProvider.overrideWithValue(_StubAuth())],
    );
  });

  goldenScenario('login', '로그인', (tester, chrome) async {
    await pumpScreen(
      tester,
      const LoginScreen(),
      chrome: chrome,
      size: frameOf(chrome),
      overrides: <Override>[authServiceProvider.overrideWithValue(_StubAuth())],
    );
  });
}

/// 모델을 부르지 않는 가짜. 답은 고정이라 골든이 흔들리지 않는다.
class _StubAsk implements AskService {
  _StubAsk(this.answer);

  final AskAnswer answer;

  @override
  Future<AskAnswer?> ask(String question, List<Smartphone> catalog) async =>
      answer;
}

const _answer = AskAnswer(
  pick: 'OnePlus 13',
  pickSlug: 'oneplus-13',
  reason: 'Cheapest flagship on your weights.',
  rows: <AskRow>[
    AskRow(label: 'TP Index', value: '74'),
    AskRow(label: 'Price', value: r'$899'),
    AskRow(label: 'Battery', value: '6000mAh'),
    AskRow(label: 'Camera', value: '36'),
  ],
);

/// Firebase 를 띄우지 않는 가짜. 화면은 로그아웃 상태로만 그린다.
class _StubAuth implements AuthService {
  @override
  Stream<TpUser?> changes() => const Stream<TpUser?>.empty();
  @override
  TpUser? get current => null;

  @override
  Future<TpUser?> signIn(
    AuthMethod method, {
    String? email,
    String? password,
  }) async => null;

  @override
  Future<TpUser?> signUp({
    required String email,
    required String password,
  }) async => null;

  @override
  Future<bool> sendPasswordReset(String email) async => false;

  @override
  Future<TpUser?> updateName(String name) async => null;

  @override
  Future<void> signOut() async {}
}
