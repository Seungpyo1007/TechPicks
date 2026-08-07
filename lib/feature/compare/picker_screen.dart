import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// 비교할 기기를 고르는 시트.
///
/// 어느 열을 채울지는 [pickSlotProvider] 가 들고 있다. 명세의 `pickSlot` 과
/// 같은 역할이다.
class PickerScreen extends ConsumerWidget {
  const PickerScreen({super.key, this.onDone});

  /// 고르고 나면 호출된다. 라우팅은 바깥에서 한다.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.tpText;
    final t = context.tp;
    final catalog = ref.watch(catalogProvider).value;
    final weights = ref.watch(weightsProvider);
    final devices = catalog?.smartphones ?? const [];

    return TpShell(
      mode: TpChromeMode.plain,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(K.choose.tr(), style: type.largeTitle),
                ),
                TpTapTarget(
                  onTap: onDone,
                  child: Text(
                    K.cancel.tr(),
                    style: type.body.copyWith(color: TpTokens.blueText),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                    onDone?.call();
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
