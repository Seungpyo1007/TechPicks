import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';

/// 풀다운 메뉴 한 줄.
class TpMenuItem {
  const TpMenuItem({
    required this.label,
    required this.onTap,
    this.checked = false,
    this.destructive = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool checked;
  final bool destructive;
  final IconData? icon;
}

/// 아무 위젯에나 풀다운 메뉴를 붙인다. [builder] 가 받은 함수를 부르면 열린다.
///
/// iOS 는 `CupertinoMenuAnchor`(유리 메뉴, 체크는 앞), Android 는 `MenuAnchor`.
class TpMenu extends StatelessWidget {
  const TpMenu({super.key, required this.items, required this.builder});

  final List<TpMenuItem> items;
  final Widget Function(BuildContext context, VoidCallback open) builder;

  @override
  Widget build(BuildContext context) {
    if (context.tp.isGlass) {
      final sys = context.sys;
      return CupertinoMenuAnchor(
        menuChildren: <Widget>[
          for (final item in items)
            CupertinoMenuItem(
              onPressed: item.onTap,
              isDestructiveAction: item.destructive,
              leading: item.checked
                  ? Icon(CupertinoIcons.check_mark, size: 18, color: sys.label)
                  : null,
              trailing: item.icon == null ? null : Icon(item.icon, size: 18),
              child: Text(item.label),
            ),
        ],
        builder: (context, controller, _) => builder(
          context,
          () => controller.isOpen ? controller.close() : controller.open(),
        ),
      );
    }
    return MenuAnchor(
      menuChildren: <Widget>[
        for (final item in items)
          MenuItemButton(
            onPressed: item.onTap,
            leadingIcon: item.checked
                ? const Icon(Icons.check, size: 18)
                : const SizedBox(width: 18),
            trailingIcon: item.icon == null ? null : Icon(item.icon, size: 18),
            child: Text(
              item.label,
              style: item.destructive
                  ? TextStyle(color: context.sys.destructive)
                  : null,
            ),
          ),
      ],
      builder: (context, controller, _) => builder(
        context,
        () => controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
