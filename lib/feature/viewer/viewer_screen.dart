import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';

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
    HapticFeedback.selectionClick();
    setState(() => _highlighted = _highlighted == i ? null : i);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.tp.isGlass;
    final safe = MediaQuery.viewPaddingOf(context);
    final minTap = glass ? 44.0 : 48.0;

    final close = glass
        ? TpBarButton(
            action: TpBarAction(
              label: K.close.tr(),
              onTap: widget.onBack,
              child: const Icon(
                CupertinoIcons.xmark,
                size: 20,
                color: Colors.white,
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
                child: Center(child: _Stage(highlighted: _highlighted)),
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

/// 모델 자리. 지평선과 바닥 그림자 위에 와이어프레임을 놓는다.
class _Stage extends StatelessWidget {
  const _Stage({this.highlighted});

  final int? highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: 40,
            child: Container(
              width: 200,
              height: 1,
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Container(
              width: 160,
              height: 34,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomPaint(
            size: const Size(140, 250),
            painter: _WireframePainter(highlighted: highlighted),
          ),
        ],
      ),
    );
  }
}

/// 모델이 없으니 기기 윤곽만 선으로 그린다.
class _WireframePainter extends CustomPainter {
  const _WireframePainter({this.highlighted});

  final int? highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = Colors.white.withValues(alpha: 0.35);

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(18),
    );
    canvas.drawRRect(rect, body);

    // 부품 위치. 칩을 누르면 해당 영역만 파랗게 칠한다.
    final regions = <Rect>[
      Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), // Display
      Rect.fromLTWH(18, size.height * 0.45, size.width - 36, size.height * 0.4),
      Rect.fromLTWH(size.width * 0.3, size.height * 0.3, size.width * 0.4, 40),
      const Rect.fromLTWH(14, 14, 52, 52), // Camera module
    ];

    for (var i = 0; i < regions.length; i++) {
      final on = highlighted == i;
      final r = RRect.fromRectAndRadius(regions[i], const Radius.circular(10));
      if (on) {
        canvas.drawRRect(
          r,
          Paint()..color = TpSys.accent.withValues(alpha: 0.30),
        );
      }
      canvas.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 1.5 : 1
          ..color = on ? TpSys.accent : Colors.white.withValues(alpha: 0.14),
      );
    }
  }

  @override
  bool shouldRepaint(_WireframePainter old) => old.highlighted != highlighted;
}
