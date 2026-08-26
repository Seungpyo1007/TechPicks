import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../copy_keys.dart';
import 'tp_tap_target.dart';

/// 알약 하나짜리 검색 줄.
///
/// 픽커에만 있던 것을 여기로 올렸다. 랭킹에서 기기를 찾을 방법이 스크롤밖에
/// 없었는데, 카탈로그가 200종이고 랭킹은 50행에서 잘린다 — 51위 아래의
/// 기기는 **찾을 방법이 아예 없었다.**
class TpSearchField extends StatelessWidget {
  const TpSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  /// 없으면 공용 "기기 찾기".
  final String? hint;

  /// 명세 Chrome geometry 의 컨트롤 높이.
  static const double height = 48;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final label = hint ?? K.searchHint.tr();

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: t.inputBg,
        borderRadius: BorderRadius.circular(TpTokens.rControl),
        boxShadow: t.inputShadow,
      ),
      child: Semantics(
        label: label,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: type.body,
          decoration: InputDecoration(
            // isDense 를 켜면 히트 영역이 접근성 기준에 못 미친다.
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: InputBorder.none,
            icon: Icon(Icons.search, size: 20, color: t.dim),
            // 이름은 Semantics 가 준다. 힌트까지 들어가면 두 번 읽힌다.
            hint: ExcludeSemantics(
              child: Text(label, style: type.body.copyWith(color: t.dim)),
            ),
            suffixIcon: controller.text.isEmpty
                ? null
                : TpTapTarget(
                    label: K.cancel.tr(),
                    onTap: () {
                      controller.clear();
                      onChanged('');
                    },
                    child: Icon(Icons.close, size: 18, color: t.dim),
                  ),
          ),
        ),
      ),
    );
  }
}
