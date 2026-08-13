import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/app/tab_host.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/data/service/deep_link_service.dart';
import 'package:techpicks/feature/compare/compare_screen.dart';
import 'package:techpicks/feature/detail/detail_screen.dart';

import '../support/harness.dart';

/// 플랫폼 채널 없이 링크를 넣는다.
class _FakeLinks implements DeepLinkService {
  _FakeLinks({this.first});

  final Uri? first;
  final StreamController<Uri> _later = StreamController<Uri>.broadcast();

  /// 앱이 떠 있는 동안 들어온 링크.
  void arrive(Uri uri) => _later.add(uri);

  @override
  Future<Uri?> initial() async => first;

  @override
  Stream<Uri> stream() => _later.stream;
}

/// 플러그인이 아예 없는 기기.
class _BrokenLinks implements DeepLinkService {
  @override
  Future<Uri?> initial() async => throw StateError('플러그인 없음');

  @override
  Stream<Uri> stream() => const Stream<Uri>.empty();
}

Future<void> _pump(WidgetTester tester, DeepLinkService links) => pumpScreen(
  tester,
  const TabHost(),
  size: const Size(1200, 3000),
  overrides: <Override>[
    deepLinkServiceProvider.overrideWithValue(links),
    askServiceProvider.overrideWithValue(const LocalAskService()),
  ],
);

void main() {
  setUp(initLocalization);
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('앱이 꺼져 있을 때 눌린 기기 링크가 상세를 연다', (tester) async {
    await _pump(
      tester,
      _FakeLinks(first: Uri.parse('techpicks://device/oneplus-13')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
    expect(find.text('OnePlus 13'), findsWidgets);
  });

  testWidgets('떠 있는 동안 들어온 링크도 연다', (tester) async {
    final links = _FakeLinks();
    await _pump(tester, links);
    expect(find.byType(DetailScreen), findsNothing);

    links.arrive(Uri.parse('techpicks://device/galaxy-s25'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('비교 링크는 두 슬롯을 채우고 비교 탭으로 간다', (tester) async {
    final container = await pumpScreen(
      tester,
      const TabHost(),
      size: const Size(1200, 3000),
      overrides: <Override>[
        deepLinkServiceProvider.overrideWithValue(
          _FakeLinks(
            first: Uri.parse('techpicks://compare/oneplus-13/pixel-9-pro'),
          ),
        ),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    final slots = container.read(compareProvider);
    expect(slots.a, 'oneplus-13');
    expect(slots.b, 'pixel-9-pro');
    expect(find.byType(CompareScreen), findsOneWidget);
  });

  testWidgets('같은 링크가 두 번 와도 한 번만 연다', (tester) async {
    // 초기 링크를 스트림으로 한 번 더 주는 플랫폼이 있다.
    final links = _FakeLinks(first: Uri.parse('techpicks://device/galaxy-s25'));
    await _pump(tester, links);
    await tester.pumpAndSettle();

    links.arrive(Uri.parse('techpicks://device/galaxy-s25'));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsOneWidget);
  });

  testWidgets('모르는 링크는 무시한다', (tester) async {
    await _pump(tester, _FakeLinks(first: Uri.parse('https://example.com/x')));
    await tester.pumpAndSettle();

    expect(find.byType(DetailScreen), findsNothing);
    expect(find.byType(TabHost), findsOneWidget);
  });

  testWidgets('링크 플러그인이 죽어도 앱은 뜬다', (tester) async {
    await _pump(tester, _BrokenLinks());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(TabHost), findsOneWidget);
  });

  testWidgets('연 링크는 다시 열리지 않는다', (tester) async {
    final container = await pumpScreen(
      tester,
      const TabHost(),
      size: const Size(1200, 3000),
      overrides: <Override>[
        deepLinkServiceProvider.overrideWithValue(
          _FakeLinks(first: Uri.parse('techpicks://device/galaxy-s25')),
        ),
        askServiceProvider.overrideWithValue(const LocalAskService()),
      ],
    );
    await tester.pumpAndSettle();

    expect(container.read(pendingLinkProvider), isNull);
  });
}
