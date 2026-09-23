import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';

/// 앱의 공용 선택 시트.
Future<T?> showTpSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: isScrollControlled,
  useSafeArea: true,
  builder: (context) => TpSheet(child: Builder(builder: builder)),
);

class TpSheet extends StatelessWidget {
  const TpSheet({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final glass = t.isGlass;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final sheet = Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: glass ? t.cardStrong : t.card,
          // iOS 는 떠 있어서 네 모서리가 다 둥글다. Android 는 화면 바닥에
          // 붙으니 위만 둥글다.
          borderRadius: glass
              ? BorderRadius.circular(36)
              : BorderRadius.vertical(top: Radius.circular(t.rCard)),
          border: glass ? Border.all(color: t.hairline) : null,
          boxShadow: t.cardShadow,
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            glass ? 10 : 16,
            16,
            glass ? 16 : 16 + bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (glass) ...<Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: t.dim.withValues(alpha: .55),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
    if (!glass) return sheet;
    return Padding(
      padding: EdgeInsets.fromLTRB(8, 0, 8, bottom > 8 ? bottom : 8),
      child: sheet,
    );
  }
}
