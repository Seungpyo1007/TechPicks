/// 제품 가설을 재는 곳.
///
/// 이 앱의 전제는 "TP Index 는 고정값이 아니라 사용자가 정한 비중"이다.
/// 그런데 **사람들이 슬라이더를 실제로 만지는지 모른다.** 안 만지면 이 앱은
/// 그냥 고정 점수 랭킹 앱이고 전제가 무너진다.
///
/// 재는 것은 그 가설과 그걸 둘러싼 행동뿐이다. 화면 조회 수 같은 건 안 센다.
abstract class AnalyticsSink {
  void log(String event, Map<String, Object> params);
}

/// 아무 데도 안 보낸다. 테스트와 Firebase 없는 빌드의 기본값.
class SilentAnalyticsSink implements AnalyticsSink {
  const SilentAnalyticsSink();

  @override
  void log(String event, Map<String, Object> params) {}
}

/// 앱 전역의 기록 지점.
abstract final class TpAnalytics {
  static AnalyticsSink _sink = const SilentAnalyticsSink();

  /// 앱 시작 때 한 번 갈아 끼운다. 테스트가 되돌릴 수 있게 이전 것을 돌려준다.
  static AnalyticsSink use(AnalyticsSink sink) {
    final previous = _sink;
    _sink = sink;
    return previous;
  }

  /// 가중치를 바꿨다. **가장 중요한 이벤트다.**
  ///
  /// 축 이름과 값만 보낸다. 어느 축을 올리고 내리는지가 제품 결정에 직결된다.
  static void weightChanged(String axis, double value) =>
      _sink.log('weight_changed', <String, Object>{
        'axis': axis,
        // 0–100 정수로 보낸다. 소수는 집계에서 쪼개지기만 한다.
        'value': (value * 100).round(),
      });

  /// 가중치를 기본값으로 되돌렸다. 슬라이더가 어렵다는 신호일 수 있다.
  static void weightsReset() =>
      _sink.log('weights_reset', const <String, Object>{});

  /// 관심 목록에 담거나 뺐다.
  static void shortlistChanged({required bool added, required int size}) =>
      _sink.log('shortlist_changed', <String, Object>{
        'added': added,
        'size': size,
      });

  /// 두 기기를 비교했다.
  static void compared(String a, String b) =>
      _sink.log('compared', <String, Object>{'a': a, 'b': b});

  /// 상담에 질문했다. **질문 원문은 보내지 않는다** — 개인정보일 수 있다.
  /// 길이와 답을 얻었는지만 본다.
  static void asked({required int length, required bool answered}) =>
      _sink.log('asked', <String, Object>{
        'length': length,
        'answered': answered,
      });

  /// 랭킹 축을 바꿨다. 다섯 축이 다 쓰이는지 본다.
  static void rankAxisChanged(String axis) =>
      _sink.log('rank_axis_changed', <String, Object>{'axis': axis});

  /// 남에게 보냈다. [kind] 는 `verdict` 아니면 `device`.
  ///
  /// 공유는 명세에 없던 것을 우리가 넣은 것이다. 결론을 보내는지 기기를
  /// 보내는지가 다르면 다음에 붙일 자리도 달라진다.
  static void shared(String kind) =>
      _sink.log('shared', <String, Object>{'kind': kind});

  /// 링크를 눌러 들어왔다. 공유가 실제로 사람을 데려오는지 본다.
  static void linkOpened(String kind) =>
      _sink.log('link_opened', <String, Object>{'kind': kind});
}
