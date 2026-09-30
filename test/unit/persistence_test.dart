import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/domain/model/tp_index.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

/// 앱을 껐다 켰을 때 남아 있어야 하는 것들.
///
/// 프로바이더는 전부 `build()` 에서 기본값을 돌려주고 뒤늦게 저장값을 덮어쓴다.
/// 복원이 조용히 실패해도 화면은 기본값으로 멀쩡히 뜨기 때문에 눈으로는
/// 안 잡힌다.

/// 가중치 저장은 [WeightsNotifier.saveDelay] 만큼 미뤄진다.
Future<void> _afterSave() => Future<void>.delayed(
  WeightsNotifier.saveDelay + const Duration(milliseconds: 50),
);

/// 복원은 SharedPreferences 채널을 한 번 왕복한 뒤에 끝난다.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

/// 다시 켠 앱.
ProviderContainer _restart() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

/// 다시 켠 앱에서 프로바이더 하나를 읽는다.
///
/// 프로바이더는 처음 읽힐 때 마운트되고 그때 복원이 시작된다. 컨테이너만
/// 만들어놓고 기다리면 아무 일도 일어나지 않는다.
Future<T> _readAfterRestart<T>(T Function(ProviderContainer) read) async {
  final container = _restart();
  read(container);
  await _settle();
  return read(container);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('가중치', () {
    test('바꾼 값이 다음 실행에 남는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = _restart();
      first.read(weightsProvider.notifier).setAxis(TpAxisKind.camera, 0.5);
      await _afterSave();

      expect(
        (await _readAfterRestart((c) => c.read(weightsProvider))).camera,
        0.5,
      );
    });

    test('되돌리기도 남는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tp_weights': jsonEncode(
          TpWeights.defaults.copyWith(battery: 0.9).toJson(),
        ),
      });
      final first = _restart();
      first.read(weightsProvider);
      await _settle();
      expect(first.read(weightsProvider).battery, 0.9);

      first.read(weightsProvider.notifier).reset();
      await _afterSave();

      expect(
        await _readAfterRestart((c) => c.read(weightsProvider)),
        TpWeights.defaults,
      );
    });

    test('저장값이 JSON 이 아니면 기본값으로 뜬다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tp_weights': '{성능만 100',
      });
      expect(
        await _readAfterRestart((c) => c.read(weightsProvider)),
        TpWeights.defaults,
      );
    });

    test('저장값이 객체가 아니면 기본값으로 뜬다', () async {
      // 예전 버전이 배열로 저장했거나 키를 잘못 쓴 경우.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tp_weights': '[0.25, 0.25, 0.2, 0.2, 0.1]',
      });
      expect(
        await _readAfterRestart((c) => c.read(weightsProvider)),
        TpWeights.defaults,
      );
    });

    test('필드 타입이 다르면 기본값으로 뜬다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'tp_weights': '{"performance": "높게"}',
      });
      expect(
        await _readAfterRestart((c) => c.read(weightsProvider)),
        TpWeights.defaults,
      );
    });
  });

  group('가중치 저장 미루기', () {
    test('끄는 동안에는 안 쓰고 마지막 값만 남는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = _restart();
      final notifier = container.read(weightsProvider.notifier);

      // 슬라이더를 끄는 흉내.
      for (var i = 1; i <= 20; i++) {
        notifier.setAxis(TpAxisKind.display, i / 20);
      }

      final prefs = await SharedPreferences.getInstance();
      // 아직 아무것도 안 썼다.
      expect(prefs.getString('tp_weights'), isNull);

      await _afterSave();
      expect(
        (await _readAfterRestart((c) => c.read(weightsProvider))).display,
        1.0,
      );
    });

    test('미뤄둔 쓰기는 버려지기 전에 나간다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer();
      container.read(weightsProvider.notifier).setAxis(TpAxisKind.value, 0.7);
      // 타이머가 울리기 전에 앱이 내려간다.
      container.dispose();
      await _settle();

      expect(
        (await _readAfterRestart((c) => c.read(weightsProvider))).value,
        0.7,
      );
    });
  });

  group('관심 목록', () {
    test('담은 기기가 다음 실행에 남는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = _restart();
      first.read(shortlistProvider.notifier).toggle('galaxy-s25-ultra');
      first.read(shortlistProvider.notifier).toggle('iphone-16-pro-max');
      await _settle();

      expect(
        await _readAfterRestart((c) => c.read(shortlistProvider)),
        <String>['galaxy-s25-ultra', 'iphone-16-pro-max'],
      );
    });

    test('뺀 기기는 안 남는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'shortlist_slugs': <String>['galaxy-s25-ultra', 'pixel-9-pro'],
      });
      final first = _restart();
      first.read(shortlistProvider);
      await _settle();
      first.read(shortlistProvider.notifier).remove('pixel-9-pro');
      await _settle();

      expect(
        await _readAfterRestart((c) => c.read(shortlistProvider)),
        <String>['galaxy-s25-ultra'],
      );
    });
  });

  group('지난 순위', () {
    test('저장한 순위가 다음 실행에 남는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = _restart();
      await first.read(rankSnapshotProvider.notifier).save(<String>[
        'a',
        'b',
        'c',
      ]);

      expect(
        await _readAfterRestart((c) => c.read(rankSnapshotProvider)),
        <String>['a', 'b', 'c'],
      );
    });

    test('처음 실행이면 비어 있다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      expect(
        await _readAfterRestart((c) => c.read(rankSnapshotProvider)),
        isEmpty,
      );
    });
  });

  group('복원 도중 종료', _disposeRace);

  group('알림 설정', () {
    test('끈 상태가 다음 실행에 남는다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = _restart();
      first.read(notificationsProvider);
      await _settle();
      expect(first.read(notificationsProvider), isTrue);

      await first.read(notificationsProvider.notifier).set(false);

      expect(
        await _readAfterRestart((c) => c.read(notificationsProvider)),
        isFalse,
      );
    });
  });

  group('온보딩', () {
    test('한 번 보면 다시 안 나온다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final first = _restart();
      first.read(onboardingDoneProvider);
      await _settle();
      expect(first.read(onboardingDoneProvider), isFalse);

      await first.read(onboardingDoneProvider.notifier).complete();

      expect(
        await _readAfterRestart((c) => c.read(onboardingDoneProvider)),
        isTrue,
      );
    });

    test('v1 의 키를 그대로 읽는다', () async {
      // v1 을 쓰던 사용자가 업데이트하면 온보딩을 다시 보지 않아야 한다.
      SharedPreferences.setMockInitialValues(<String, Object>{
        'is_tutorial_completed': true,
      });
      expect(
        await _readAfterRestart((c) => c.read(onboardingDoneProvider)),
        isTrue,
      );
    });
  });
}

/// 복원이 끝나기 전에 화면을 떠난 경우.
///
/// `build()` 가 시작한 복원은 SharedPreferences 를 한 번 왕복한 뒤에 state 를
/// 쓴다. 그 사이에 프로바이더가 버려지면 Riverpod 이 throw 하고, 그 예외는
/// unawaited 라 아무 데도 안 잡힌다.
void _disposeRace() {
  for (final entry in <String, void Function(ProviderContainer)>{
    '가중치': (c) => c.read(weightsProvider),
    '관심 목록': (c) => c.read(shortlistProvider),
    '지난 순위': (c) => c.read(rankSnapshotProvider),
    '온보딩': (c) => c.read(onboardingDoneProvider),
    '알림 설정': (c) => c.read(notificationsProvider),
  }.entries) {
    test('${entry.key} — 복원 도중에 버려도 안 터진다', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final container = ProviderContainer();
      entry.value(container);
      // 복원이 착지하기 전에 버린다.
      container.dispose();
      await _settle();
    });
  }
}
