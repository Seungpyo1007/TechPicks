import 'package:flutter/material.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import 'tp_group.dart';

/// 알림 버튼 하나.
class TpAlertAction<T> {
  const TpAlertAction({
    required this.label,
    this.value,
    this.destructive = false,
    this.cancel = false,
  });

  final String label;

  /// 누르면 이 값으로 닫힌다. [cancel] 이면 무시하고 null.
  final T? value;
  final bool destructive;
  final bool cancel;
}

/// iOS 26 알림 모양. 모서리 34 카드에 캡슐 버튼 48.
///
/// `CupertinoAlertDialog` 는 iOS 13 의 가는 글자 버튼이다. 시스템 알림
/// (`UIAlertController`)은 입력 칸을 못 받아서, 비밀번호가 필요한 곳은
/// 우리가 그린다.
///
/// 동작 줄이기면 0.6 → 1 없이 바로 뜬다.
Future<T?> showTpAlert<T>({
  required BuildContext context,
  required String title,
  required List<TpAlertAction<T>> actions,
  String? message,
  Widget? content,
}) {
  final reduced = context.motion.isReduced;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: .2),
    transitionDuration: reduced
        ? Duration.zero
        : const Duration(milliseconds: 300),
    pageBuilder: (dialog, _, _) => _TpAlert<T>(
      title: title,
      message: message,
      content: content,
      actions: actions,
    ),
    transitionBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: TpMotion.specCurve,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: .6, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class _TpAlert<T> extends StatelessWidget {
  const _TpAlert({
    required this.title,
    required this.actions,
    this.message,
    this.content,
  });

  final String title;
  final String? message;
  final Widget? content;
  final List<TpAlertAction<T>> actions;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final buttons = <Widget>[
      for (final a in actions)
        _AlertButton(
          label: a.label,
          destructive: a.destructive,
          cancel: a.cancel,
          onTap: () => Navigator.of(context).pop(a.cancel ? null : a.value),
        ),
    ];
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
              decoration: BoxDecoration(
                color: sys.cell,
                borderRadius: BorderRadius.circular(34),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 40,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: sys.label,
                        ),
                      ),
                    ),
                    if (message != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.38,
                          color: sys.label2,
                        ),
                      ),
                    ],
                    if (content != null) ...<Widget>[
                      const SizedBox(height: 10),
                      content!,
                    ],
                    const SizedBox(height: 16),
                    // 둘이면 나란히, 더 많으면 세로로 쌓는다.
                    if (buttons.length == 2)
                      Row(
                        children: <Widget>[
                          Expanded(child: buttons[0]),
                          const SizedBox(width: 10),
                          Expanded(child: buttons[1]),
                        ],
                      )
                    else
                      for (var i = 0; i < buttons.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: 8),
                        buttons[i],
                      ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton({
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.cancel = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool cancel;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final fg = destructive
        ? sys.destructive
        : cancel
        ? sys.label
        : Colors.white;
    final bg = destructive
        ? sys.destructive.withValues(alpha: .15)
        : cancel
        ? sys.fill3
        : TpSys.accent;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(
        onTap: onTap,
        press: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: cancel ? FontWeight.w400 : FontWeight.w600,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}
