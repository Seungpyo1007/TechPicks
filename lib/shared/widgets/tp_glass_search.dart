import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import 'tp_surface.dart';

/// 검색 필드. iOS 는 Liquid Glass 캡슐, Android 는 M3 SearchBar.
///
/// iOS 26 에서는 OS 가 그리는 유리 검색 바(`LiquidGlassSearchBar`)다. 플랫폼
/// 뷰라서 화면당 하나만 둔다.
class TpGlassSearch extends StatelessWidget {
  const TpGlassSearch({
    super.key,
    required this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.controller,
    this.autofocus = false,
  });

  final String placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// 26 미만·Android 경로의 입력 상자. 네이티브 바는 자기 글자를 들고 있다.
  final TextEditingController? controller;
  final bool autofocus;

  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    if (!context.tp.isGlass) {
      return SearchBar(
        controller: controller,
        hintText: placeholder,
        autoFocus: autofocus,
        leading: const Icon(Icons.search),
        elevation: const WidgetStatePropertyAll<double>(0),
        onChanged: onChanged,
        onSubmitted: onSubmitted,
      );
    }
    if (TpNativeGlass.enabled) {
      return SizedBox(
        height: height,
        child: TpNativeSearchBar(
          placeholder: placeholder,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          height: height,
          tint: TpSys.accent,
          textColor: sys.label,
          placeholderColor: sys.label3,
          iconColor: sys.label2,
        ),
      );
    }
    return SizedBox(
      height: height,
      child: TpSurface.chrome(
        radius: TpTokens.rControl,
        child: CupertinoSearchTextField(
          controller: controller,
          placeholder: placeholder,
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          backgroundColor: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 12, 12),
          style: TextStyle(fontSize: 17, color: sys.label),
        ),
      ),
    );
  }
}
