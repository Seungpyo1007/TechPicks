import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../domain/model/scan_match.dart';
import '../../domain/model/tp_index.dart';

/// 스캔.
///
/// 카메라와 OCR 은 아직 붙어 있지 않다. google_ml_kit 은 코드에서 쓰인 적이
/// 없어 의존성 정리 때 걷어냈고, 다시 넣는 건 실제로 인식이 필요한 시점이
/// 맞다. 지금은 [recognizedText] 로 읽힌 글자를 바깥에서 넣어주면 화면이
/// 카탈로그에 맞춰 결과를 띄운다.
///
/// 뒷면 인식 자체는 ScanMatcher 가 하고 테스트도 그쪽에 있다.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({
    super.key,
    this.onBack,
    this.onOpenDevice,
    this.recognizedText,
  });

  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenDevice;

  /// OCR 이 읽은 글자. null 이면 대기 상태로 남는다.
  final String? recognizedText;

  static const Color background = Color(0xFF0B0D10);

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _line = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final catalog = ref.watch(catalogProvider).value;
    final weights = ref.watch(weightsProvider);

    final match = widget.recognizedText == null || catalog == null
        ? null
        : ScanMatcher.match(widget.recognizedText!, catalog.smartphones);

    return TpShell(
      mode: TpChromeMode.takeover,
      child: ColoredBox(
        color: ScanScreen.background,
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 260,
                    height: 160,
                    child: _Viewfinder(progress: _line),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      (match == null ? K.scanHintIdle : K.scanHintDone).tr(),
                      textAlign: TextAlign.center,
                      style: type.secondary.copyWith(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // 상태 바 아래로 콘텐츠가 올라오므로 헤더를 직접 그린다.
            Positioned(
              top: MediaQuery.viewPaddingOf(context).top + 8,
              left: 8,
              right: 16,
              child: Row(
                children: <Widget>[
                  TpTapTarget(
                    onTap: widget.onBack,
                    label: K.back.tr(),
                    child: const Icon(Icons.chevron_left,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    K.scanTitle.tr(),
                    style: type.cardTitle.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),

            if (match != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 16,
                child: _ResultCard(
                  name: match.device.name,
                  index: TpIndex.of(match.device.score, weights),
                  onOpen: widget.onOpenDevice == null
                      ? null
                      : () => widget.onOpenDevice!(match.device.slug),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 모서리 네 개와 위아래로 오가는 스캔 선.
class _Viewfinder extends StatelessWidget {
  const _Viewfinder({required this.progress});

  final Animation<double> progress;

  static const double _bracket = 26;
  static const double _stroke = 3;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        for (final corner in _corners)
          Align(alignment: corner, child: _Corner(corner: corner)),
        AnimatedBuilder(
          animation: progress,
          builder: (context, _) => Align(
            alignment: Alignment(0, progress.value * 2 - 1),
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: TpTokens.blue,
            ),
          ),
        ),
      ],
    );
  }

  static const List<Alignment> _corners = <Alignment>[
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
  ];
}

class _Corner extends StatelessWidget {
  const _Corner({required this.corner});

  final Alignment corner;

  @override
  Widget build(BuildContext context) {
    final top = corner.y < 0;
    final left = corner.x < 0;
    const side = BorderSide(
      color: TpTokens.blue,
      width: _Viewfinder._stroke,
    );

    return SizedBox(
      width: _Viewfinder._bracket,
      height: _Viewfinder._bracket,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: top ? side : BorderSide.none,
            bottom: top ? BorderSide.none : side,
            left: left ? side : BorderSide.none,
            right: left ? BorderSide.none : side,
          ),
        ),
      ),
    );
  }
}

/// 아래에서 올라오는 결과 카드.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.name, required this.index, this.onOpen});

  final String name;
  final int? index;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: const Duration(milliseconds: 240),
      curve: const Cubic(.2, .8, .2, 1),
      builder: (context, t, child) => FractionalTranslation(
        translation: Offset(0, t),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(context.tp.rCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(K.detected.tr().toUpperCase(), style: type.eyebrow),
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    name,
                    style: type.cardTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  index?.toString() ?? '—',
                  maxLines: 1,
                  softWrap: false,
                  style: type.cardTitle.copyWith(fontSize: 24),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onOpen,
              child: Container(
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: TpTokens.blue,
                  borderRadius: BorderRadius.circular(
                    context.tp.isGlass ? TpTokens.rControl : context.tp.rInner,
                  ),
                ),
                child: Text(
                  K.openDevice.tr(),
                  style: type.body.copyWith(
                    color: Colors.white,
                    fontWeight: context.tp.boldWeight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
