import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techpicks/app/providers.dart';
import 'package:techpicks/core/analytics.dart';
import 'package:techpicks/domain/model/ranking.dart';
import 'package:techpicks/domain/model/tp_index.dart';

/// 제품 가설을 재는 이벤트.
///
/// 이 앱의 전제는 "지수는 사용자가 정한 비중"이다. 사람들이 슬라이더를 실제로
/// 만지는지 모르면 그 전제를 검증할 수 없다.
class _Recording implements AnalyticsSink {
  final List<({String event, Map<String, Object> params})> logs = [];

  @override
  void log(String event, Map<String, Object> params) {
    logs.add((event: event, params: params));
  }

  Iterable<String> get events => logs.map((l) => l.event);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Recording sink;
  late AnalyticsSink previous;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    sink = _Recording();
    previous = TpAnalytics.use(sink);
  });

  tearDown(() => TpAnalytics.use(previous));

  ProviderContainer container() {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    return c;
  }

  test('기본값은 아무 데도 안 보낸다', () {
    TpAnalytics.use(previous);
    TpAnalytics.weightsReset();
  });

  test('가중치를 바꾸면 축과 값이 남는다', () {
    container().read(weightsProvider.notifier).setAxis(TpAxisKind.camera, 0.4);

    final log = sink.logs.single;
    expect(log.event, 'weight_changed');
    expect(log.params['axis'], 'camera');
    // 0–100 정수로 보낸다. 소수는 집계에서 쪼개지기만 한다.
    expect(log.params['value'], 40);
  });

  test('되돌리기도 따로 센다', () {
    container().read(weightsProvider.notifier).reset();
    expect(sink.events, contains('weights_reset'));
  });

  test('관심 목록은 담았는지 뺐는지와 크기를 남긴다', () {
    final c = container();
    c.read(shortlistProvider.notifier).toggle('galaxy-s25-ultra');
    c.read(shortlistProvider.notifier).toggle('iphone-16-pro-max');
    c.read(shortlistProvider.notifier).toggle('galaxy-s25-ultra');

    final logs = sink.logs
        .where((l) => l.event == 'shortlist_changed')
        .toList();
    expect(logs.map((l) => l.params['added']), <int>[1, 1, 0]);
    expect(logs.map((l) => l.params['size']), <int>[1, 2, 1]);
  });

  test('랭킹 축 전환을 센다', () {
    container().read(rankAxisProvider.notifier).set(RankAxis.battery);

    final log = sink.logs.single;
    expect(log.event, 'rank_axis_changed');
    expect(log.params['axis'], 'battery');
  });

  // Firebase Analytics 는 문자열과 숫자만 받는다. bool 을 넣었더니 어서션이
  // 터져 화면에 빨간 오류가 났다.
  test('값은 문자열 아니면 숫자다', () {
    final c = container();
    c.read(shortlistProvider.notifier).toggle('galaxy-s25-ultra');
    c.read(weightsProvider.notifier).setAxis(TpAxisKind.battery, 0.4);
    c.read(rankAxisProvider.notifier).set(RankAxis.camera);
    TpAnalytics.asked(length: 3, answered: false);
    TpAnalytics.shared('device');
    TpAnalytics.linkOpened('device');

    for (final log in sink.logs) {
      for (final entry in log.params.entries) {
        expect(
          entry.value is String || entry.value is num,
          isTrue,
          reason: '${log.event}.${entry.key} = ${entry.value}',
        );
      }
    }
  });

  test('질문은 원문을 안 보낸다', () {
    TpAnalytics.asked(length: 12, answered: true);

    final log = sink.logs.single;
    expect(log.params.keys, <String>['length', 'answered']);
    // 개인정보일 수 있어 본문은 절대 안 실린다.
    expect(log.params.values.whereType<String>(), isEmpty);
  });
}
