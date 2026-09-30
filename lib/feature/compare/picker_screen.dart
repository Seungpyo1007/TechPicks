import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_sys.dart';
import '../../domain/model/device_search.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_glass_search.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';

/// 비교 열 하나에 넣을 기기를 고르는 시트.
class PickerScreen extends ConsumerStatefulWidget {
  const PickerScreen({super.key, this.onDone});

  final VoidCallback? onDone;

  @override
  ConsumerState<PickerScreen> createState() => _PickerScreenState();
}

class _PickerScreenState extends ConsumerState<PickerScreen> {
  final TextEditingController _input = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final weights = ref.watch(weightsProvider);
    final money = ref.watch(moneyProvider);
    final side = ref.watch(pickSlotProvider);
    final slots = ref.watch(compareProvider);
    final current = side == CompareSide.a ? slots.a : slots.b;
    final devices = DeviceSearch.filter(
      ref.watch(pickerRankedProvider),
      _query,
    );
    final searching = _query.trim().isNotEmpty;

    return TpPage(
      title: K.choose.tr(),
      largeTitle: false,
      leading: TpBarAction(
        label: K.cancel.tr(),
        role: TpBarRole.close,
        text: true,
        onTap: widget.onDone,
      ),
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TpGlassSearch(
              placeholder: K.searchHint.tr(),
              controller: _input,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
        if (ref.watch(catalogProvider).hasError)
          const SliverToBoxAdapter(child: TpCatalogError())
        else if (devices.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 0),
              child: Text(
                (searching ? K.noMatches : K.noDevices).tr(),
                style: TextStyle(color: sys.label2),
              ),
            ),
          )
        else
          TpGroupSliver(
            count: devices.length,
            header: searching
                ? K.searchCount.tr(args: <String>['${devices.length}'])
                : null,
            builder: (context, i) {
              final d = devices[i];
              final index = TpIndex.of(d.score, weights);
              return TpRow(
                title: d.name,
                subtitle: money.format(d.msrpUsd),
                value: index?.toString() ?? DeviceSpecs.empty,
                checked: d.slug == current,
                chevron: false,
                onTap: () {
                  ref.read(compareProvider.notifier).pick(side, d.slug);
                  widget.onDone?.call();
                },
              );
            },
          ),
      ],
    );
  }
}
