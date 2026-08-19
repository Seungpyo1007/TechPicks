import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import 'tp_pressable.dart';

/// 누르는 동안 밝아지는 면.
///
/// 명세는 카드에만 규칙을 줬다(밝기 +4%). 그래서 카드가 아닌 줄 — 랭킹 행,
/// 설정 줄, 언어 시트, 세그먼트 — 은 눌러도 아무 일이 없었다. 같은 줄에
/// 사는 것들이 어떤 건 반응하고 어떤 건 안 하면 고장으로 읽힌다.
///
/// 알약은 [TpButton]·[TpTapTarget] 처럼 줄어들고, 넓은 면은 이렇게 밝아진다.
/// 줄어들기를 넓은 면에 쓰면 목록 전체가 출렁인다.
class TpPress extends StatelessWidget {
  const TpPress({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.semanticsButton = true,
    this.semanticsLabel,
    this.haptic = TpHaptic.selection,
    this.tint = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 바깥에서 이미 시맨틱을 붙였으면 false. 두 번 읽히면 안 된다.
  final bool semanticsButton;

  /// 이 면을 눌러 무엇으로 가는지. 아이콘도 글자도 없는 면은 이게 없으면
  /// 스크린 리더가 "버튼"만 읽는다.
  final String? semanticsLabel;

  final TpHaptic haptic;

  /// 눌린 동안 배경을 깔지.
  ///
  /// 배경이 없는 줄(랭킹 행)에서는 밝기 +4% 가 사실상 안 보인다. 자기 배경이
  /// 있는 면(카드)은 밝아지는 것으로 충분하다.
  final bool tint;

  /// `filter: brightness(1.04)` 와 같다.
  static const double amount = 1.04;

  /// 눌린 정도 [t] (0–1) 만큼 밝힌다.
  static ColorFilter filterAt(double t) {
    final v = 1 + (amount - 1) * t;
    return ColorFilter.matrix(<double>[
      v, 0, 0, 0, 0, //
      0, v, 0, 0, 0, //
      0, 0, v, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tp;

    final Widget gesture = TpPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      haptic: haptic,
      child: child,
      builder: (context, press, child) {
        if (press == 0) return child!;

        // 필터는 한 겹뿐이다. 두 겹이 되면 유리 위에서 saveLayer 가 두 번
        // 뜨고, 테스트도 정확히 한 겹을 못박고 있다.
        final Widget lit = ColorFiltered(
          colorFilter: filterAt(press),
          child: child,
        );
        if (!tint) return lit;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: t.ink.withValues(alpha: 0.05 * press),
            borderRadius: BorderRadius.circular(t.rInner),
          ),
          child: lit,
        );
      },
    );

    return semanticsButton
        ? Semantics(button: true, label: semanticsLabel, child: gesture)
        : gesture;
  }
}

/// 눌림의 감각을 한곳에서 정한다.
///
/// 세 가지가 어색함의 원인이었다.
///
/// 1. **폭에 상관없이 같은 비율로 줄었다.** 0.97 은 칩(80pt)에서는 2pt 지만
///    전체 폭 버튼(342pt)에서는 양쪽이 5pt 씩 움직인다 — 같은 값인데 큰
///    버튼에서만 과장돼 보인다. 그래서 **줄어드는 양을 pt 로 고정**한다.
/// 2. **색이 안 변했다.** 크기만 바뀌면 손가락 밑에서 뭐가 일어났는지 안
///    보인다. 밝은 면은 밝아지고(카드와 같은 +4%), 채운 면은 눌린 만큼
///    어두워진다.
/// 3. **누를 때와 뗄 때가 같은 속도였다.** 실제로 누르는 동작은 빠르고 손을
///    떼면 천천히 돌아온다. 내려갈 때는 [TpMotion.press], 올라올 때는
///    [TpMotion.selection] 을 쓴다.
abstract final class TpPressFeel {
  /// 눌렸을 때 양쪽으로 들어가는 양.
  static const double inset = 3;

  /// 아무리 작아도 이보다 더 줄지는 않는다.
  static const double minScale = 0.96;

  /// 폭 [width] 인 면이 눌렸을 때의 배율.
  static double scaleFor(double width) {
    if (!width.isFinite || width <= 0) return 0.97;
    return (1 - (inset * 2) / width).clamp(minScale, 1);
  }

  /// 눌린 정도 [t] 만큼 어둡게. 채운 면(파란 버튼·고른 칩)에 쓴다.
  ///
  /// 채운 면을 밝히면 색이 바래 비활성처럼 보인다.
  static ColorFilter darken(double t) {
    final v = 1 - 0.08 * t;
    return ColorFilter.matrix(<double>[
      v, 0, 0, 0, 0, //
      0, v, 0, 0, 0, //
      0, 0, v, 0, 0, //
      0, 0, 0, 1, 0, //
    ]);
  }

  /// 누르는 중인지에 따라 시간이 다르다.
  static TpMove move(BuildContext context, {required bool pressed}) =>
      pressed ? context.motion.press : context.motion.selection;
}
