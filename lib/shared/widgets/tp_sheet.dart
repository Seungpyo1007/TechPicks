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
          borderRadius: BorderRadius.circular(glass ? 36 : t.rCard),
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
