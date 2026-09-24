import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tp_tokens.dart';

/// v3 시스템 색. iOS 는 UIKit semantic color, Android 는 M3 표면.
///
/// 액센트만 우리 색. 나머지는 OS 값을 그대로 따라가서 다크 모드도 따로 정하지 않는다.
@immutable
class TpSys {
  const TpSys({
    required this.background,
    required this.cell,
    required this.label,
    required this.label2,
    required this.label3,
    required this.separator,
    required this.fill,
    required this.fill3,
    required this.accentText,
    required this.tint,
    required this.destructive,
  });

  /// 화면 바탕 (grouped background).
  final Color background;

  /// inset grouped 칸, 카드.
  final Color cell;

  final Color label;
  final Color label2;
  final Color label3;
  final Color separator;

  /// 트랙, 세그먼트 바탕.
  final Color fill;
  final Color fill3;

  /// 작은 글자용 액센트. 회색 바탕 위에서도 4.5:1.
  final Color accentText;

  /// tinted 버튼, 이긴 값.
  final Color tint;

  final Color destructive;

  static const Color accent = TpTokens.blue;

  static TpSys of(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (context.tp.isGlass) {
      Color r(CupertinoDynamicColor c) => c.resolveFrom(context);
      return TpSys(
        background: r(CupertinoColors.systemGroupedBackground),
        cell: r(CupertinoColors.secondarySystemGroupedBackground),
        label: r(CupertinoColors.label),
        // 시스템 값(60%)은 회색 바탕 위 13pt 에서 3.3:1 이라 AA 에 모자란다.
        // 라이트만 77% 로 올린다. 다크는 시스템 값으로 충분하다.
        label2: dark
            ? r(CupertinoColors.secondaryLabel)
            : const Color(0xC43C3C43),
        label3: r(CupertinoColors.tertiaryLabel),
        separator: r(CupertinoColors.separator),
        fill: r(CupertinoColors.systemFill),
        fill3: r(CupertinoColors.tertiarySystemFill),
        accentText: dark ? const Color(0xFF5AA9F2) : const Color(0xFF0A64B4),
        tint: accent.withValues(alpha: dark ? .28 : .12),
        destructive: dark ? const Color(0xFFFF6961) : const Color(0xFFD70015),
      );
    }
    final s = Theme.of(context).colorScheme;
    return TpSys(
      background: s.surface,
      cell: s.surfaceContainer,
      label: s.onSurface,
      label2: s.onSurfaceVariant,
      label3: s.outline,
      separator: s.outlineVariant,
      fill: s.surfaceContainerHighest,
      fill3: s.surfaceContainerHigh,
      accentText: dark ? const Color(0xFF9ECAFF) : const Color(0xFF0A5CA6),
      tint: s.secondaryContainer,
      destructive: s.error,
    );
  }
}

extension TpSysX on BuildContext {
  TpSys get sys => TpSys.of(this);
}
