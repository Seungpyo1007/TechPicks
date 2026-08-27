import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_press.dart';
import '../../shared/widgets/tp_tap_target.dart';

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

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;

    return TpShell(
      mode: TpChromeMode.takeover,
      child: ColoredBox(
        color: ViewerScreen.background,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: Center(child: _Stage(highlighted: _highlighted)),
                  ),
                  SizedBox(
                    height: 46,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: ViewerScreen.partKeys.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final on = _highlighted == i;
                        return Semantics(
                          button: true,
                          selected: on,
                          // decoration: 으로 칠한 상자는 히트 테스트에 안 잡힌다. 이게 없으면
                          // 버튼이 글자 글리프 위에서만 눌린다.
                          child: _PressedChip(
                            onTap: () =>
                                setState(() => _highlighted = on ? null : i),
                            // 다크 인수 화면이라 TpChip 의 밝은 팔레트를 못
                            // 쓴다. 대신 같은 전환 시간을 쓴다.
                            child: AnimatedContainer(
                              duration: context.motion.selection.duration,
                              curve: context.motion.selection.curve,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: on
                                    ? TpTokens.blue
                                    : Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  TpTokens.rControl,
                                ),
                              ),
                              child: Text(
                                ViewerScreen.partKeys[i].tr(),
                                style: type.body.copyWith(
                                  fontSize: 13.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      K.viewerNote.tr(),
                      style: type.caption.copyWith(color: Colors.white54),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.viewPaddingOf(context).bottom + 16,
                  ),
                ],
              ),
            ),
            Positioned(
              top: MediaQuery.viewPaddingOf(context).top + 8,
              left: 8,
              right: 16,
              child: Row(
                children: <Widget>[
                  TpTapTarget(
                    onTap: widget.onBack,
                    label: K.back.tr(),
                    child: const Icon(
                      Icons.chevron_left,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      widget.deviceName,
                      style: type.cardTitle.copyWith(color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      canvas.drawRRect(
        RRect.fromRectAndRadius(regions[i], const Radius.circular(10)),
        Paint()
          ..style = on ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = on
              ? TpTokens.blue.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.14),
      );
    }
  }

  @override
  bool shouldRepaint(_WireframePainter old) => old.highlighted != highlighted;
}

/// 어두운 인수 화면의 칩. 눌리면 알약들과 같은 박자로 줄어든다.
///
/// 여기만 [TpChip] 을 못 쓴다 — 밝은 팔레트가 검은 배경에서 안 맞는다.
/// 그래서 눌림 반응만 [TpPressFeel] 로 맞춘다.
class _PressedChip extends StatefulWidget {
  const _PressedChip({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressedChip> createState() => _PressedChipState();
}

class _PressedChipState extends State<_PressedChip> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final move = TpPressFeel.move(context, pressed: _pressed);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: move.duration,
        curve: move.curve,
        child: widget.child,
      ),
    );
  }
}
