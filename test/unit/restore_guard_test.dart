import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';

/// 복원과 사람의 조작이 겹치면 사람이 이긴다.
///
/// 노티파이어들이 build() 에서 복원을 비동기로 시작한다. 그 사이에 담은 기기를
/// 늦게 온 저장값이 덮으면 화면에서도 디스크에서도 사라진다.
ProviderContainer _app() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('복원 도착 전에 담은 기기가 살아남는다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['iphone-17-pro'],
    });
    final container = _app();

    // 복원을 기다리지 않고 바로 담는다.
    container.read(shortlistProvider.notifier).toggle('galaxy-s25');
    expect(container.read(shortlistProvider), <String>['galaxy-s25']);

    // 복원이 도착할 시간을 준다.
    await container.read(shortlistProvider.notifier).ready;
    await Future<void>.delayed(Duration.zero);

    expect(container.read(shortlistProvider), <String>['galaxy-s25']);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('shortlist_slugs'), <String>['galaxy-s25']);
  });

  test('아무도 안 건드리면 저장값이 복원된다', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'shortlist_slugs': <String>['iphone-17-pro'],
    });
    final container = _app();

    container.read(shortlistProvider);
    await container.read(shortlistProvider.notifier).ready;

    expect(container.read(shortlistProvider), <String>['iphone-17-pro']);
  });
}
