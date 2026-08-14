import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// 비교할 기기를 고르는 시트.
///
/// 어느 열을 채울지는 [pickSlotProvider] 가 들고 있다. 명세의 `pickSlot` 과
/// 같은 역할이다.
///
/// 카탈로그가 10종이던 때는 목록만 있으면 됐다. 154종이 되면서 원하는 기기를
/// 손으로 굴려 찾는 게 일이 됐다 — 그래서 검색이 붙었다. 명세에는 없는
/// 요소지만 명세의 카탈로그도 10종이었다.
class PickerScreen extends ConsumerStatefulWidget {
  const PickerScreen({super.key, this.onDone});

  /// 고르고 나면 호출된다. 라우팅은 바깥에서 한다.
  final VoidCallback? onDone;

  /// 이름과 브랜드로 거른다.
  ///
  /// 순수 함수로 떼어둔 이유는 규칙을 테스트로 못박기 위해서다 — 대소문자,
  /// 공백, 브랜드 이름으로 찾기.
  static List<Smartphone> filter(List<Smartphone> devices, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return devices;
    return devices
        .where(
          (d) =>
              d.name.toLowerCase().contains(q) ||
              (d.brand?.name.toLowerCase().contains(q) ?? false),
        )
        .toList(growable: false);
  }

  @override
  ConsumerState<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends ConsumerState<PickerScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;
    final catalog = ref.watch(catalogProvider).value;
    final weights = ref.watch(weightsProvider);
    final devices = PickerScreen.filter(
      catalog?.smartphones ?? const <Smartphone>[],
      _query.text,
    );

    return TpShell(
      mode: TpChromeMode.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(K.choose.tr(), style: type.largeTitle)),
                TpTapTarget(
                  onTap: widget.onDone,
                  child: Text(
                    K.cancel.tr(),
                    style: type.body.copyWith(color: TpTokens.blueText),
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
                label: K.searchHint.tr(),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  style: type.body,
                  decoration: InputDecoration(
                    // isDense 를 켜면 히트 영역이 접근성 기준에 못 미친다.
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, size: 20, color: t.dim),
                    // 이름은 Semantics 가 준다. 힌트까지 들어가면 두 번 읽힌다.
                    hint: ExcludeSemantics(
                      child: Text(
                        K.searchHint.tr(),
                        style: type.body.copyWith(color: t.dim),
                      ),
                    ),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : TpTapTarget(
                            label: K.cancel.tr(),
                            onTap: () => setState(_query.clear),
                            child: Icon(Icons.close, size: 18, color: t.dim),
                          ),
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: devices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(K.noDevices.tr(), style: type.secondary),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: devices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final d = devices[i];
                      final index = TpIndex.of(d.score, weights);
                      return TpSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        onTap: () {
                          ref
                              .read(compareProvider.notifier)
                              .pick(ref.read(pickSlotProvider), d.slug);
                          widget.onDone?.call();
                        },
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    d.name,
                                    style: type.cardTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DeviceSpecs.formatPrice(d.msrpUsd),
                                    style: type.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              index?.toString() ?? DeviceSpecs.empty,
                              maxLines: 1,
                              softWrap: false,
                              style: type.cardTitle.copyWith(
                                color: index == null ? t.dim : TpTokens.ink,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
