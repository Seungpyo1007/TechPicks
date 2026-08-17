import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../domain/model/scan_match.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/widgets/tp_button.dart';

/// 이름으로 기기 찾기.
///
/// 명세 §11 은 카메라로 뒷면 모델명을 읽는 화면이다. 카메라도 OCR 도 붙어
/// 있지 않아 실기기에서는 검은 화면에 조준틀만 돌았다 — 안 되는 기능을
/// 되는 것처럼 보여주는 화면이었다. 그래서 읽는 대신 **받아 적게** 했다.
///
/// 맞추는 일은 그대로 [ScanMatcher] 가 한다. 카메라가 붙는 날 [recognizedText]
/// 로 읽은 글자를 넣어주면 이 화면이 그대로 결과를 띄운다.
///
/// 받는 것은 **모델 번호가 아니라 기기 이름**이다. 카탈로그에 `SM-S931B` 같은
/// 코드가 없어서 그걸로는 영영 못 찾는다 — 안내 문구도 그렇게 적었다.
class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({
    super.key,
    this.onBack,
    this.onOpenDevice,
    this.recognizedText,
  });

  final VoidCallback? onBack;
  final ValueChanged<String>? onOpenDevice;

  /// 미리 채워둘 글자. 카메라가 붙으면 OCR 결과가 여기로 들어온다.
  final String? recognizedText;

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  late final TextEditingController _text = TextEditingController(
    text: widget.recognizedText ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final catalog = ref.watch(catalogProvider).value;
    final weights = ref.watch(weightsProvider);

    final query = _text.text.trim();
    final match = query.isEmpty || catalog == null
        ? null
        : ScanMatcher.match(query, catalog.smartphones);

    return TpShell(
      mode: TpChromeMode.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(K.scanTitle.tr(), style: type.largeTitle)),
                TpTapTarget(
                  onTap: widget.onBack,
                  label: K.back.tr(),
                  child: Text(
                    K.cancel.tr(),
                    style: type.body.copyWith(color: t.link),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: t.inputBg,
                borderRadius: BorderRadius.circular(TpTokens.rControl),
                boxShadow: t.inputShadow,
              ),
              child: Semantics(
                label: K.scanFieldLabel.tr(),
                child: TextField(
                  controller: _text,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  textCapitalization: TextCapitalization.words,
                  style: type.body,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, size: 20, color: t.dim),
                    hint: ExcludeSemantics(
                      child: Text(
                        K.scanFieldHint.tr(),
                        style: type.body.copyWith(color: t.dim),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: switch ((query.isEmpty, match)) {
                (true, _) => Text(K.scanHintIdle.tr(), style: type.secondary),
                (false, null) => Text(
                  K.scanNoMatch.tr(),
                  style: type.secondary,
                ),
                (false, final m?) => _ResultCard(
                  name: m.device.name,
                  index: TpIndex.of(m.device.score, weights),
                  onOpen: widget.onOpenDevice == null
                      ? null
                      : () => widget.onOpenDevice!(m.device.slug),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 찾은 기기 한 대.
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.name, required this.index, this.onOpen});

  final String name;
  final int? index;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final motion = context.motion;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 1, end: 0),
      duration: motion.reveal.duration,
      curve: motion.reveal.curve,
      builder: (context, v, child) =>
          FractionalTranslation(translation: Offset(0, v * 0.1), child: child),
      child: Align(
        alignment: Alignment.topCenter,
        child: TpSurface(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
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
              const SizedBox(height: 6),
              Text(K.scanHintDone.tr(), style: type.caption),
              const SizedBox(height: 12),
              TpButton(label: K.openDevice.tr(), height: 46, onTap: onOpen),
            ],
          ),
        ),
      ),
    );
  }
}
