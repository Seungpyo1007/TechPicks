import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/data/repository/catalog_repository.dart';
import 'package:techpicks/domain/model/device_specs.dart';

import '../support/harness.dart';

/// 비교 슬롯은 카탈로그가 늦게 와도 안 지워진다.
///
/// 예전에는 `build()` 안에서 순위를 `watch` 했다. 카탈로그가 도착하면
/// 노티파이어가 통째로 다시 만들어져 그 사이에 고른 것이 사라졌다 — 딥링크로
/// 연 비교가 몇 프레임 뒤 기본값으로 덮였다.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ({ProviderContainer container, Completer<Catalog> catalog}) boot() {
    final catalog = Completer<Catalog>();
    final container = ProviderContainer(
      overrides: <Override>[
        catalogProvider.overrideWith((ref) => catalog.future),
      ],
    );
    addTearDown(container.dispose);
    return (container: container, catalog: catalog);
  }

  test('카탈로그가 오기 전에 고른 두 대가 살아남는다', () async {
    final (:container, :catalog) = boot();

    container.read(compareProvider.notifier)
      ..pick(CompareSide.a, 'oneplus-13')
      ..pick(CompareSide.b, 'pixel-9-pro');

    catalog.complete(readCatalog());
    await container.read(catalogProvider.future);
    await Future<void>.delayed(Duration.zero);

    final slots = container.read(compareProvider);
    expect(slots.a, 'oneplus-13');
    expect(slots.b, 'pixel-9-pro');
  });

  test('아무것도 안 골랐으면 지수 1·2위로 채운다', () async {
    final (:container, :catalog) = boot();

    // 먼저 읽어 노티파이어를 만든다. 이 시점에는 카탈로그가 없다.
    expect(container.read(compareProvider).a, isNull);

    catalog.complete(readCatalog());
    await container.read(catalogProvider.future);
    await Future<void>.delayed(Duration.zero);

    final ranked = readRanking();
    final slots = container.read(compareProvider);
    expect(slots.a, ranked[0].device.slug);
    expect(slots.b, ranked[1].device.slug);
  });
}
