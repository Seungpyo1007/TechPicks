import 'package:flutter/material.dart';

/// 지속 시간과 커브 한 쌍.
///
/// 둘을 따로 두면 호출부에서 한쪽만 넘기고 다른 쪽을 빠뜨린다. 실제로 그랬다 —
/// `tp_chip` 과 온보딩 도트가 커브를 안 넘겨 `linear` 로 돌고 있었다.
@immutable
class TpMove {
  const TpMove(this.duration, this.curve);

  final Duration duration;
  final Curve curve;

  /// 손쉬운 사용의 "동작 줄이기" 용. 커브는 그대로 두고 시간만 없앤다.
  TpMove get instant => TpMove(Duration.zero, curve);

  @override
  bool operator ==(Object other) =>
      other is TpMove && other.duration == duration && other.curve == curve;

  @override
  int get hashCode => Object.hash(duration, curve);

  @override
  String toString() => 'TpMove(${duration.inMilliseconds}ms, $curve)';
}

/// 앱의 모션 토큰.
///
/// 색·반지름과 같은 취급이다. 화면은 숫자를 안 들고 역할 이름만 부른다 —
/// `motion.selection`, `motion.valueChange` 처럼.
///
/// **명세가 값을 준 모션은 두 플랫폼이 같다.** 랭킹 재정렬 220ms, 스캔 카드
/// 240ms, 칩 누름 90ms 는 디자인 결정이지 플랫폼 관례가 아니다.
///
/// 명세가 침묵한 자리만 갈린다. Android 는 Flutter 가 들고 있는 M3 토큰
/// ([Durations], [Easing]) 을 그대로 쓴다 — 숫자를 지어내지 않는다.
/// iOS 는 Apple 관례대로 더 짧고 감속 위주다.
///
/// Flutter 는 M3 의 `emphasized` 를 그 이름으로 내놓지 않는다. 대신
/// [Easing.standard] 가 `cubic-bezier(0.2, 0, 0, 1)` 로 같은 곡선이다.
/// 들어오는 내용에는 [Easing.emphasizedDecelerate] 를 쓴다.
@immutable
class TpMotion extends ThemeExtension<TpMotion> {
  const TpMotion({
    required this.press,
    required this.selection,
    required this.reorder,
    required this.reveal,
    required this.valueChange,
    required this.contentSwap,
    required this.listItem,
  });

  /// 명세 Interactions 의 재정렬·등장 커브. 두 곳에 리터럴로 박혀 있던 값이다.
  static const Curve specCurve = Cubic(.2, .8, .2, 1);

  /// 누르는 동안의 피드백. 명세: 칩은 0.97 로 90ms.
  final TpMove press;

  /// 골라진 상태로 바뀔 때 — 칩·세그먼트·탭 캡슐.
  /// 명세가 iOS 알약을 180ms 로 못박았다.
  final TpMove selection;

  /// 랭킹 행이 새 자리로 미끄러진다. **명세 고정값.**
  final TpMove reorder;

  /// 스캔 결과 카드가 아래에서 올라온다. **명세 고정값.**
  final TpMove reveal;

  /// 숫자나 막대가 다른 값이 될 때. 가중치 슬라이더가 이걸 타고 번진다.
  final TpMove valueChange;

  /// 내용이 통째로 갈릴 때 — 탭 본문, 로딩에서 콘텐츠로.
  final TpMove contentSwap;

  /// 목록에 항목이 들어오고 나갈 때.
  final TpMove listItem;

  /// iOS. 짧고 감속 위주.
  factory TpMotion.ios() => const TpMotion(
    press: TpMove(Duration(milliseconds: 90), Curves.easeOutCubic),
    selection: TpMove(Duration(milliseconds: 180), Curves.easeOutCubic),
    reorder: TpMove(Duration(milliseconds: 220), specCurve),
    reveal: TpMove(Duration(milliseconds: 240), specCurve),
    valueChange: TpMove(Duration(milliseconds: 220), Curves.easeOutCubic),
    contentSwap: TpMove(Duration(milliseconds: 200), Curves.easeInOut),
    listItem: TpMove(Duration(milliseconds: 250), Curves.easeOutCubic),
  );

  /// Android Material 3.
  factory TpMotion.android() => const TpMotion(
    press: TpMove(Duration(milliseconds: 90), Easing.standard),
    selection: TpMove(Durations.short4, Easing.standard),
    reorder: TpMove(Duration(milliseconds: 220), specCurve),
    reveal: TpMove(Duration(milliseconds: 240), specCurve),
    valueChange: TpMove(Durations.medium1, Easing.standard),
    contentSwap: TpMove(Durations.medium2, Easing.emphasizedDecelerate),
    listItem: TpMove(Durations.medium1, Easing.emphasizedDecelerate),
  );

  /// 모든 시간을 0 으로. 손쉬운 사용에서 동작을 줄였을 때.
  TpMotion get reduced => TpMotion(
    press: press.instant,
    selection: selection.instant,
    reorder: reorder.instant,
    reveal: reveal.instant,
    valueChange: valueChange.instant,
    contentSwap: contentSwap.instant,
    listItem: listItem.instant,
  );

  /// 시간이 다 0 이면 줄이기가 켜진 것이다. 무한 반복을 멈출지 판단하는 데 쓴다.
  bool get isReduced => reorder.duration == Duration.zero;

  @override
  TpMotion copyWith({
    TpMove? press,
    TpMove? selection,
    TpMove? reorder,
    TpMove? reveal,
    TpMove? valueChange,
    TpMove? contentSwap,
    TpMove? listItem,
  }) => TpMotion(
    press: press ?? this.press,
    selection: selection ?? this.selection,
    reorder: reorder ?? this.reorder,
    reveal: reveal ?? this.reveal,
    valueChange: valueChange ?? this.valueChange,
    contentSwap: contentSwap ?? this.contentSwap,
    listItem: listItem ?? this.listItem,
  );

  /// 두 모션 집합 사이를 애니메이션할 일이 없다. 중간값 대신 한쪽을 고른다.
  @override
  TpMotion lerp(ThemeExtension<TpMotion>? other, double t) {
    if (other is! TpMotion) return this;
    return t < 0.5 ? this : other;
  }
}

/// 화면이 모션을 꺼내 쓰는 자리.
///
/// **동작 줄이기가 여기서 처리된다.** 켜져 있으면 시간이 0 인 사본을 돌려주므로
/// 호출부는 그 존재를 몰라도 된다.
extension TpMotionX on BuildContext {
  TpMotion get motion {
    final base = Theme.of(this).extension<TpMotion>()!;
    return MediaQuery.disableAnimationsOf(this) ? base.reduced : base;
  }
}
