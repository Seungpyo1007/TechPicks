import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gemma_builtin_ai/flutter_gemma_builtin_ai.dart'
    show BuiltInAiAvailability;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import '../support/harness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/shared/spec_labels.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/domain/model/tp_weights.dart';
import 'package:techpicks/app/locale_controller.dart';
import 'package:techpicks/data/service/device_info_service.dart';
import 'package:techpicks/feature/you/you_screen.dart';
import 'package:techpicks/shared/widgets/tp_switch.dart';
import 'package:techpicks/shared/copy_keys.dart';

ProviderContainer? _container;

Future<void> _pump(
  WidgetTester tester, {
  TpChrome chrome = TpChrome.ios,
  String? name,
  String? email,
  LocaleController? locale,
  DeviceInfoService? deviceInfo,
}) async {
  _container = await pumpScreen(
    tester,
    YouScreen(name: name, email: email),
    chrome: chrome,
    size: const Size(1200, 3600),
    overrides: <Override>[
      if (locale != null) localeControllerProvider.overrideWithValue(locale),
      if (deviceInfo != null)
        deviceInfoServiceProvider.overrideWithValue(deviceInfo),
    ],
  );
}

Future<void> _pumpPriorities(WidgetTester tester) async {
  _container = await pumpScreen(
    tester,
    const PrioritiesScreen(),
    size: const Size(1200, 3600),
  );
}

/// 맨 위 카드를 눌러 계정 화면으로.
Future<void> _openAccount(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

void main() {
  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('다섯 축 슬라이더가 있다', (tester) async {
    await _pumpPriorities(tester);
    expect(find.byType(Slider), findsNWidgets(5));
    for (final label in <String>[
      'Performance',
      'Camera',
      'Display',
      'Battery',
      'Value',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  // 연속 슬라이더는 손가락이 지나는 픽셀마다 onChanged 를 울린다. 그때마다
  // 카탈로그 154종이 다시 줄 세워지고, 탭 다섯이 IndexedStack 안에 다 살아
  // 있어서 랭킹·비교·홈이 같이 돈다. 한 번 끄는 데 300번쯤이었다.
  testWidgets('슬라이더가 걸음으로 움직인다', (tester) async {
    await _pumpPriorities(tester);

    for (final slider in tester.widgetList<Slider>(find.byType(Slider))) {
      expect(slider.divisions, isNotNull);
    }
  });

  // 축 이름은 옆줄에 따로 있어서 스크린 리더는 퍼센트만 읽었다 — 어느 축을
  // 만지는지 알 수 없었다.
  testWidgets('슬라이더가 어느 축인지 읽어준다', (tester) async {
    await _pumpPriorities(tester);

    final slider = tester.widget<Slider>(find.byType(Slider).first);
    expect(
      slider.semanticFormatterCallback!(0.25),
      contains(SpecLabels.axis(TpAxisKind.performance)),
    );
  });

  testWidgets('슬라이더를 움직이면 가중치가 바뀐다', (tester) async {
    await _pumpPriorities(tester);
    final before = _container!.read(weightsProvider);

    // 첫 슬라이더(성능)를 오른쪽 끝으로.
    await tester.drag(find.byType(Slider).first, const Offset(500, 0));
    await tester.pumpAndSettle();

    final after = _container!.read(weightsProvider);
    expect(after.performance, greaterThan(before.performance));
    // 다른 축은 그대로.
    expect(after.camera, before.camera);
  });

  testWidgets('가중치가 바뀌면 지수가 따라 바뀐다', (tester) async {
    await _pump(tester);
    final container = _container!;

    // You 화면은 카탈로그를 보지 않으므로 여기서 직접 불러온다.
    final catalog = await container.read(catalogProvider.future);

    int? indexOf(String slug) {
      final d = catalog.smartphones.firstWhere((e) => e.slug == slug);
      return TpIndex.of(d.score, container.read(weightsProvider));
    }

    // 기본 가중치에서 galaxy-s25 는 61.
    expect(indexOf('galaxy-s25'), 61);

    container
        .read(weightsProvider.notifier)
        .set(
          const TpWeights(
            performance: 1,
            camera: 0,
            display: 0,
            battery: 0,
            value: 0,
          ),
        );
    await tester.pumpAndSettle();

    // 성능만 보면 그 축 점수(88.9)가 그대로 지수가 된다.
    expect(indexOf('galaxy-s25'), 89);
  });

  testWidgets('Reset 이 기본값으로 돌린다', (tester) async {
    await _pumpPriorities(tester);
    final container = _container!;

    container
        .read(weightsProvider.notifier)
        .setAxis(TpAxisKind.performance, 0.9);
    await tester.pumpAndSettle();
    expect(container.read(weightsProvider).performance, 0.9);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(container.read(weightsProvider), TpWeights.defaults);
  });

  testWidgets('저장된 가중치를 다시 읽는다', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'tp_weights': jsonEncode(<String, dynamic>{
        'performance': 0.5,
        'camera': 0.1,
        'display': 0.1,
        'battery': 0.2,
        'value': 0.1,
      }),
    });
    await _pump(tester);
    expect(_container!.read(weightsProvider).performance, 0.5);
  });

  testWidgets('설정 줄, 정보 안의 버전 줄', (tester) async {
    await _pump(tester);
    for (final label in <String>[
      'Language',
      'Dark mode',
      'AI engine',
      // 통화 줄은 한때 뺐었다 — 'USD' 가 못박혀 있고 핸들러도 없었다.
      // 원화가 들어오면서 고를 것이 생겼다.
      'Currency',
      'Notifications',
      'About',
      // 계정이 없으면 맨 위 카드에 로그인이 있다.
      'Sign in',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    // 버전·안내 다시 보기·데이터 출처는 정보 안에 있다.
    expect(find.text(YouScreen.versionLine), findsNothing);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(find.text(YouScreen.versionLine), findsOneWidget);
    expect(find.text(K.coachReplay.tr()), findsOneWidget);
    expect(find.text(K.sources.tr()), findsOneWidget);
  });

  testWidgets('통화를 고르면 그 값이 남는다', (tester) async {
    await _pump(tester);
    final container = _container!;

    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Korean won'));
    await tester.pumpAndSettle();

    expect(container.read(currencyProvider), TpCurrency.krw);
  });

  testWidgets('통화 시트가 환율이 어디서 왔는지 밝힌다', (tester) async {
    // 명세는 환율 환산을 금지했다. 그걸 뒤집는 것이라, 무슨 값을 언제
    // 받아 쓰는지 안 보이면 지어낸 숫자와 구분이 안 된다.
    await _pump(tester);

    await tester.tap(find.text('Currency'));
    await tester.pumpAndSettle();

    expect(find.textContaining('1 USD = ₩'), findsOneWidget);
  });

  testWidgets('비밀번호 줄은 메일 주소가 있을 때만 나온다', (tester) async {
    // 재설정 메일을 보낼 곳이 없으면 줄을 보여줄 이유도 없다. 익명과
    // 소셜 로그인이 그렇다.
    await _pump(tester);
    expect(find.text('Change password'), findsNothing);

    await _pump(tester, name: '홍길동', email: 'a@b.com');
    // 루트에는 없고 계정 화면에 있다.
    expect(find.text('Change password'), findsNothing);
    await _openAccount(tester, '홍길동');
    expect(find.text('Change password'), findsOneWidget);
  });

  testWidgets('로그인 전에는 계정 없이 쓰는 상태로 보인다', (tester) async {
    await _pump(tester);
    expect(find.text(K.guestTitle.tr()), findsOneWidget);
    expect(find.text(K.guestBody.tr()), findsOneWidget);
    // 계정 묶음이 없다.
    expect(find.text(K.deleteAccount.tr()), findsNothing);
    expect(find.text(K.logout.tr()), findsNothing);
    // "?" 가 아니라 회색 원에 사람 모양.
    expect(find.text('?'), findsNothing);
    expect(find.byIcon(CupertinoIcons.person_fill), findsOneWidget);
    // 고칠 프로필이 없다. 열어 봐야 저장이 조용히 실패한다.
    expect(find.text('Edit profile'), findsNothing);
  });

  testWidgets('계정이 있으면 프로필 수정이 나온다', (tester) async {
    await _pump(tester, name: '홍길동', email: 'a@b.com');
    await _openAccount(tester, '홍길동');
    expect(find.text('Edit profile'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('이름이 있으면 이니셜을 만든다', (tester) async {
    await _pump(tester, name: 'Seungpyo Park', email: 'a@b.com');
    expect(find.text('SP'), findsOneWidget);
    expect(find.text('Seungpyo Park'), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
  });

  testWidgets('언어 줄이 현재 언어를 보여준다', (tester) async {
    await _pump(tester, locale: _FakeLocale(TpLocale.ko));
    expect(find.text('한국어'), findsOneWidget);
  });

  testWidgets('언어를 고르면 즉시 바뀐다', (tester) async {
    // v1 은 여기서 앱을 재시작했다. 명세가 그 안내를 없애라고 했다.
    final locale = _FakeLocale();
    await _pump(tester, locale: locale);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // 시트가 열리고 두 언어가 나온다.
    expect(find.text('한국어'), findsOneWidget);

    await tester.tap(find.text('한국어'));
    await tester.pumpAndSettle();

    expect(locale.set_, <TpLocale>[TpLocale.ko]);
    expect(find.byType(AlertDialog), findsNothing);
  });

  // 리메이크 뒤 이 줄은 "끔"이라고 적힌 채 눌러도 아무 일이 없었다.
  testWidgets('다크 모드를 골라 바꾼다', (tester) async {
    await _pump(tester);
    expect(_container!.read(themeModeProvider), ThemeMode.system);
    expect(find.text('System'), findsOneWidget);

    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(_container!.read(themeModeProvider), ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('알림을 눌러 껐다 켠다', (tester) async {
    await _pump(tester);
    expect(_container!.read(notificationsProvider), isTrue);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(_container!.read(notificationsProvider), isFalse);
    expect(find.byType(TpSwitch), findsOneWidget);
    expect(tester.widget<TpSwitch>(find.byType(TpSwitch)).value, isFalse);
  });

  group('내 기기', () {
    testWidgets('카탈로그에 있으면 이름과 지수를 보여준다', (tester) async {
      await _pump(
        tester,
        deviceInfo: const _FakeDeviceInfo(
          ThisDevice(name: 'Galaxy S25 Ultra', brand: 'Samsung'),
        ),
      );

      expect(find.text('Galaxy S25 Ultra'), findsOneWidget);
      // 기본 가중치에서 77.
      expect(find.text('77'), findsOneWidget);
      expect(find.text('Not in the catalogue yet'), findsNothing);
    });

    testWidgets('모델 코드만 읽히면 못 찾는다고 알린다', (tester) async {
      // 실제로는 대부분 이쪽이다.
      await _pump(
        tester,
        deviceInfo: const _FakeDeviceInfo(
          ThisDevice(name: 'SM-S931B', brand: 'samsung'),
        ),
      );

      expect(find.text('SM-S931B'), findsOneWidget);
      expect(find.text('Not in the catalogue yet'), findsOneWidget);
    });

    testWidgets('못 읽으면 그렇다고 알린다', (tester) async {
      await _pump(tester, deviceInfo: const _FakeDeviceInfo(null));
      expect(find.text('Could not read this device.'), findsOneWidget);
    });

    testWidgets('누르면 상세로 보낼 slug 를 준다', (tester) async {
      String? tapped;
      _container = await pumpScreen(
        tester,
        YouScreen(onDeviceTap: (s) => tapped = s),
        size: const Size(1200, 3600),
        overrides: <Override>[
          deviceInfoServiceProvider.overrideWithValue(
            const _FakeDeviceInfo(
              ThisDevice(name: 'OnePlus 13', brand: 'OnePlus'),
            ),
          ),
        ],
      );

      await tester.tap(find.text('OnePlus 13'));
      await tester.pumpAndSettle();
      expect(tapped, 'oneplus-13');
    });
  });

  testWidgets('두 크롬 모두에서 그려진다', (tester) async {
    for (final chrome in TpChrome.values) {
      await _pump(tester, chrome: chrome);
      // 탭 라벨과 화면 제목이 같은 단어라 둘 다 잡힌다.
      expect(find.text('You'), findsWidgets);
    }
  });

  testWidgets('로그아웃은 시트에서 한 번 더 묻는다', (tester) async {
    var logouts = 0;
    await pumpScreen(
      tester,
      YouScreen(email: 'a@b.c', onLogout: () => logouts++),
      size: const Size(1200, 3600),
    );
    await _openAccount(tester, 'a@b.c');

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    expect(logouts, 0);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(logouts, 0);

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out').last);
    await tester.pumpAndSettle();
    expect(logouts, 1);
  });

  group('AI 엔진', () {
    Future<void> open(WidgetTester tester, TpChrome chrome) async {
      await pumpScreen(
        tester,
        const YouScreen(),
        chrome: chrome,
        size: const Size(1200, 3600),
        overrides: <Override>[
          onDeviceAiProvider.overrideWith(
            (ref) async => BuiltInAiAvailability.unavailableDisabled,
          ),
        ],
      );
      await tester.tap(find.text(K.aiEngine.tr()));
      await tester.pumpAndSettle();
    }

    testWidgets('선택지마다 부제가 있다', (tester) async {
      await open(tester, TpChrome.ios);
      for (final key in <String>[
        K.aiEngineAutoBody,
        K.aiEngineOnDeviceBody,
        K.aiEngineCloudBody,
      ]) {
        expect(find.text(key.tr()), findsOneWidget, reason: key);
      }
      expect(find.text(K.aiEngineDisabled.tr()), findsOneWidget);
    });

    testWidgets('Android 각주는 Apple Intelligence 를 말하지 않는다', (tester) async {
      await open(tester, TpChrome.android);
      expect(find.text(K.aiEngineDisabled.tr()), findsNothing);
      expect(find.text(K.aiEngineUnavailable.tr()), findsOneWidget);
    });
  });

  group('나눈 화면', () {
    testWidgets('루트는 짧다: 슬라이더와 계정 줄은 하위 화면에', (tester) async {
      await _pump(tester, name: '홍길동', email: 'a@b.com');
      expect(find.byType(Slider), findsNothing);
      expect(find.text('Log out'), findsNothing);
      expect(find.text(K.weights.tr()), findsOneWidget);
    });

    testWidgets('가중치 줄은 가장 큰 축을 말하고 누르면 슬라이더로', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tp_weights': jsonEncode(<String, dynamic>{
          'performance': 0.1,
          'camera': 0.6,
          'display': 0.1,
          'battery': 0.1,
          'value': 0.1,
        }),
      });
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(
        find.text(
          K.weightsLead.tr(args: <String>[SpecLabels.axis(TpAxisKind.camera)]),
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(K.weights.tr()));
      await tester.pumpAndSettle();
      expect(find.byType(Slider), findsNWidgets(5));
    });

    testWidgets('고르면 고르게라고 한다', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tp_weights': jsonEncode(<String, dynamic>{
          'performance': 0.2,
          'camera': 0.2,
          'display': 0.2,
          'battery': 0.2,
          'value': 0.2,
        }),
      });
      await _pump(tester);
      await tester.pumpAndSettle();
      expect(find.text(K.weightsBalanced.tr()), findsOneWidget);
    });

    testWidgets('안내 다시 보기는 본 표시를 지운다', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'coach_seen_today': true,
      });
      await _pump(tester);

      await tester.tap(find.text(K.about.tr()));
      await tester.pumpAndSettle();
      await tester.tap(find.text(K.coachReplay.tr()));
      await tester.pumpAndSettle();

      expect(find.text(K.coachReplayed.tr()), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('coach_seen_today'), isNull);
      // 소개 화면도 다시(라우터가 온보딩으로 보낸다).
      expect(_container!.read(onboardingDoneProvider), isFalse);
    });
  });
}

/// 기기 정보를 정해서 넣는 가짜.
class _FakeDeviceInfo implements DeviceInfoService {
  const _FakeDeviceInfo(this.device);

  final ThisDevice? device;

  @override
  Future<ThisDevice?> read() async => device;
}

/// 언어 전환을 검사하기 위한 가짜 컨트롤러.
class _FakeLocale implements LocaleController {
  _FakeLocale([this._current = TpLocale.en]);

  TpLocale _current;
  final List<TpLocale> set_ = <TpLocale>[];

  @override
  TpLocale get current => _current;

  @override
  Future<void> set(TpLocale next) async {
    set_.add(next);
    _current = next;
  }
}
