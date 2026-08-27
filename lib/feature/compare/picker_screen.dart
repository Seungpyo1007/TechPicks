import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/model/device_search.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/widgets/tp_search_field.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../shared/widgets/tp_error_state.dart';

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
    final weights = ref.watch(weightsProvider);
    // 줄 세우는 건 프로바이더가 한 번만 한다. 여기서는 거르기만 한다 —
    // 예전에는 한 글자 칠 때마다 154종을 다시 세웠다.
    final devices = DeviceSearch.filter(
      ref.watch(pickerRankedProvider),
      _query.text,
    );
    final searching = _query.text.trim().isNotEmpty;

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
                    style: type.body.copyWith(color: t.link),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TpSearchField(
              controller: _query,
              onChanged: (_) => setState(() {}),
            ),
          ),

          Expanded(
            child: ref.watch(catalogProvider).hasError
                ? const TpCatalogError()
                : devices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    // 검색해서 안 나온 것과 카탈로그가 빈 것은 다른 일이다.
                    // "기기가 없습니다"는 검색어를 지워도 소용없다고 들린다.
                    child: Text(
                      (searching ? K.noMatches : K.noDevices).tr(),
                      style: type.secondary,
                    ),
                  )
                : ListView.separated(
                    // 키보드가 올라오면 그만큼 더 비운다. 안 그러면 마지막
                    // 기기들이 키보드 뒤에 깔려 못 고른다.
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
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
                                color: index == null ? t.dim : t.ink,
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
