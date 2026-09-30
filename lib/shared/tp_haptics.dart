import 'package:flutter/services.dart';

/// 촉각 신호 종류. 명세 §14 의 목록이 이 넷으로 갈린다.
enum TpHaptic {
  /// 없음. 목록 안에서 수십 번 울릴 자리에 쓴다.
  none,

  /// 고르는 것 — 칩, 탭, 세그먼트, 슬라이더 칸, 부품.
  selection,

  /// 무언가 일어나는 것 — 버튼, 스와이프 문턱, 분해도.
  impact,

  /// 결과가 남는 것 — 관심 목록에 담기·빼기, 로그인 성공.
  commit,

  /// 안 됐다 — 로그인 실패.
  error,
}

/// 앱의 모든 촉각 신호가 지나는 곳. 화면은 `HapticFeedback` 을 직접 부르지 않는다.
abstract final class TpHaptics {
  static void play(TpHaptic kind) {
    switch (kind) {
      case TpHaptic.none:
        break;
      case TpHaptic.selection:
        HapticFeedback.selectionClick();
      case TpHaptic.impact:
        HapticFeedback.lightImpact();
      case TpHaptic.commit:
        HapticFeedback.mediumImpact();
      case TpHaptic.error:
        HapticFeedback.heavyImpact();
    }
  }

  static void selection() => play(TpHaptic.selection);
  static void impact() => play(TpHaptic.impact);
  static void commit() => play(TpHaptic.commit);
  static void error() => play(TpHaptic.error);
}
