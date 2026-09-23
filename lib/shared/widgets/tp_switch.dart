import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';

class TpSwitch extends StatelessWidget {
  const TpSwitch({super.key, required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => context.tp.isGlass
      ? CupertinoSwitch(value: value, onChanged: onChanged)
      : Switch(value: value, onChanged: onChanged);
}
