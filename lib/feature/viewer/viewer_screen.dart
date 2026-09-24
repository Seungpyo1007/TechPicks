import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_group.dart';
import 'viewer_stage.dart';
import '../../shared/tp_haptics.dart';

/// 3D 뷰어.
///
/// v1 의 Model3D 는 외부 사이트를 WebView 로 띄우고 JS 로 전체화면 버튼을
/// 눌렀다. 여기는 앱 안에서 그린다.
///
/// 모델 파일이 아직 없다. 명세도 "3D models — Not supplied" 라고 적어두고
/// 와이어프레임 대역으로 그려뒀다. 같은 방식으로 둔다.
class ViewerScreen extends StatefulWidget {
  const ViewerScreen({super.key, required this.deviceName, this.onBack});

  final String deviceName;
  final VoidCallback? onBack;

  static const Color background = Color(0xFF0B0D10);

  /// 하단 부품 칩. 누르면 해당 부위를 강조한다.
  static const List<String> partKeys = <String>[
    K.partDisplay,
    K.partBattery,
    K.partChip,
    K.partCamera,
  ];

  @override
  State<ViewerScreen> createState() => _ViewerScreenState();
}

class _ViewerScreenState extends State<ViewerScreen> {
  int? _highlighted;

  void _pick(int i) {
    TpHaptics.selection();
    setState(() => _highlighted = _highlighted == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.tp.isGlass;
    final safe = MediaQuery.viewPaddingOf(context);
    final minTap = glass ? 44.0 : 48.0;

    // 어두운 무대라 시스템 유리(밝은 스타일)가 회색 덩어리로 떴다. 부품 칩과
    // 같은 반투명 원으로.
    final close = glass
        ? Semantics(
            button: true,
            label: K.close.tr(),
            excludeSemantics: true,
            onTap: widget.onBack,
            child: TpTappable(
              press: true,
              onTap: widget.onBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.xmark,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          )
        : IconButton(
            onPressed: widget.onBack,
            tooltip: K.close.tr(),
            color: Colors.white,
            icon: const Icon(Icons.close),
          );

    // 어두운 바탕이라 상태 바 글자는 흰색. v2 에서는 밝은 화면의 값이 남아
    // 검은 글자가 검은 바탕 위에 떴다.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: ViewerScreen.background,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(16, safe.top + 8, 16, 0),
                child: SizedBox(
                  height: glass ? 44 : 56,
                  child: NavigationToolbar(
                    leading: close,
                    middle: Text(
                      widget.deviceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                // 돌리고 벌리는 무대. 뜻은 기기 이름과 고른 부품으로 읽는다.
                child: Semantics(
                  label: <String>[
                    widget.deviceName,
                    if (_highlighted != null)
                      ViewerScreen.partKeys[_highlighted!].tr(),
                  ].join(', '),
                  excludeSemantics: true,
                  child: ViewerStage(part: _highlighted),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (var i = 0; i < ViewerScreen.partKeys.length; i++)
                      _PartChip(
                        label: ViewerScreen.partKeys[i].tr(),
                        selected: _highlighted == i,
                        minHeight: minTap,
                        onTap: () => _pick(i),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Text(
                  K.viewerNote.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white70,
                  ),
                ),
              ),
              SizedBox(height: safe.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// 부품 칩. 고른 것만 액센트로 채운다.
class _PartChip extends StatelessWidget {
  const _PartChip({
    required this.label,
    required this.selected,
    required this.minHeight,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final double minHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final move = context.motion.selection;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(
        press: true,
        onTap: onTap,
        child: AnimatedContainer(
          duration: move.duration,
          curve: move.curve,
          constraints: BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? TpSys.accent
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(minHeight / 2),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
