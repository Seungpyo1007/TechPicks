import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;

import '../support/harness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/theme/app_theme.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/domain/model/tp_weights.dart';
import 'package:techpicks/app/locale_controller.dart';
import 'package:techpicks/data/service/device_info_service.dart';
import 'package:techpicks/feature/you/you_screen.dart';

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

void main() {
  setUp(initLocalization);

  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('다섯 축 슬라이더가 있다', (tester) async {
    await _pump(tester);
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

  testWidgets('슬라이더를 움직이면 가중치가 바뀐다', (tester) async {
    await _pump(tester);
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
    await _pump(tester);
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

  testWidgets('설정 줄과 버전 푸터', (tester) async {
    await _pump(tester);
    for (final label in <String>[
      'Language',
      'Dark mode',
      'Notifications',
      'Currency',
      // 계정이 없으면 마지막 줄은 로그인이다.
      'Sign in',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(YouScreen.versionLine), findsOneWidget);
  });

  testWidgets('비밀번호 줄은 메일 주소가 있을 때만 나온다', (tester) async {
    // 재설정 메일을 보낼 곳이 없으면 줄을 보여줄 이유도 없다. 익명과
    // 소셜 로그인이 그렇다.
    await _pump(tester);
    expect(find.text('Change password'), findsNothing);

    await _pump(tester, name: '홍길동', email: 'a@b.com');
    expect(find.text('Change password'), findsOneWidget);
  });

  testWidgets('로그인 전에는 계정 없이 쓰는 상태로 보인다', (tester) async {
    await _pump(tester);
    expect(find.text('Browsing without an account'), findsOneWidget);
    expect(find.text('?'), findsOneWidget);
    // 고칠 프로필이 없다. 열어 봐야 저장이 조용히 실패한다.
    expect(find.text('Edit profile'), findsNothing);
  });

  testWidgets('계정이 있으면 프로필 수정이 나온다', (tester) async {
    await _pump(tester, name: '홍길동', email: 'a@b.com');
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

  testWidgets('알림을 눌러 껐다 켠다', (tester) async {
    await _pump(tester);
    expect(_container!.read(notificationsProvider), isTrue);

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    expect(_container!.read(notificationsProvider), isFalse);
    expect(find.text('Off'), findsWidgets);
  });

  group('내 기기', () {
    testWidgets('카탈로그에 있으면 이름과 지수를 보여준다', (tester) async {
      await _pump(
        tester,
        deviceInfo: const _FakeDeviceInfo(
          ThisDevice(name: 'Galaxy S25 Ultra', brand: 'Samsung'),
        ),
      );

      expect(find.text('YOUR DEVICE'), findsOneWidget);
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
