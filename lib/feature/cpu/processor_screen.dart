import '../../app/theme/tp_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/processor.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_bar.dart';
import '../../shared/widgets/tp_surface.dart';
import '../rank/category_chips.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_press.dart';

/// 프로세서 랭킹. 명세 §5 `cpu`.
///
/// v1 의 `CPU.dart` 를 대체한다. 그 화면은 `device_info_plus` 로 읽은 내 기기
/// 정보를 띄웠고, 그건 You 화면에 있다.
class ProcessorScreen extends ConsumerWidget {
  const ProcessorScreen({super.key, this.onTabSelected});

  final ValueChanged<TpTab>? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final segment = ref.watch(processorSegmentProvider);
    final ranked = ref.watch(rankedProcessorsProvider);
    final catalog = ref.watch(catalogProvider);
    final motion = context.motion;

    return TpShell(
      title: K.cpuTitle.tr(),
      tab: TpTab.rank,
      onTabSelected: onTabSelected,
      child: Builder(
        // 셸의 인셋은 이 자리 아래에 있다. 화면 build 에서 바로 읽으면
        // 크롬이 차지한 자리를 모르는 예전 값이 나온다.
        builder: (context) => ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 24) +
              tpContentInset(context),
          children: <Widget>[
            const CategoryChips(),
            const SizedBox(height: 14),
            _Segmented(
              current: segment,
              onSelected: (s) =>
                  ref.read(processorSegmentProvider.notifier).set(s),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: motion.contentSwap.duration,
              switchInCurve: motion.contentSwap.curve,
              switchOutCurve: motion.contentSwap.curve,
              child: catalog is AsyncLoading && !catalog.hasError
                  ? const _RowSkeletons(key: ValueKey<String>('skeleton'))
                  : catalog.hasError
                  ? const TpCatalogError(key: ValueKey<String>('error'))
                  : ranked.isEmpty
                  ? TpSurface(
                      key: const ValueKey<String>('empty'),
                      padding: const EdgeInsets.all(20),
                      child: Text(K.noDevices.tr(), style: context.tpText.body),
                    )
                  : Column(
                      key: ValueKey<String>('rows-${segment.name}'),
                      children: <Widget>[
                        for (final r in ranked) _ProcessorRow(entry: r),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            Text(K.cpuNote.tr(), style: context.tpText.caption),
          ],
        ),
      ),
    );
  }
}

/// Mobile / Laptop 세그먼트 컨트롤.
///
/// 명세는 "segmented control" 이라고만 적고 지오메트리를 주지 않았다. 랭킹의
/// 축 칩과 같은 알약 위에 두 칸을 얹었다 — 같은 탭 안의 이웃 화면이라
/// 별개 모양을 만들 이유가 없다.
class _Segmented extends StatelessWidget {
  const _Segmented({required this.current, required this.onSelected});

  final ProcessorSegment current;
  final ValueChanged<ProcessorSegment> onSelected;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return Container(
      height: 46,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.chipBg,
        borderRadius: BorderRadius.circular(TpTokens.rControl),
      ),
      child: Row(
        children: <Widget>[
          for (final s in ProcessorSegment.values)
            Expanded(
              child: _SegmentedCell(
                label: s.key.tr(),
                selected: s == current,
                onTap: () => onSelected(s),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentedCell extends StatelessWidget {
  const _SegmentedCell({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: TpPress(
        onTap: onTap,
        semanticsButton: false,
        child: AnimatedContainer(
          duration: context.motion.selection.duration,
          curve: context.motion.selection.curve,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? TpTokens.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(TpTokens.rControl),
          ),
          child: Text(
            label,
            style: type.body.copyWith(
              fontSize: 13.5,
              fontWeight: t.boldWeight,
              color: selected ? Colors.white : t.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// 이름 + sub 줄 + 지수 + 트랙. 랭킹 행과 달리 탭해서 열 상세가 없다 —
/// 명세에 프로세서 상세 화면이 없다.
class _ProcessorRow extends StatelessWidget {
  const _ProcessorRow({required this.entry});

  final RankedProcessor entry;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final p = entry.processor;
    final index = p.index;

    return Semantics(
      container: true,
      label: K.a11yProcessorRow.tr(
        args: <String>[
          '${entry.position}',
          p.name,
          index?.toString() ?? DeviceSpecs.empty,
        ],
      ),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.cardTitle,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: type.caption.copyWith(color: t.dim),
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
                    fontSize: 28,
                    fontWeight: t.isGlass ? FontWeight.w700 : FontWeight.w500,
                    // 랭킹과 같은 규칙 — 1–3 위만 파랗다.
                    color: entry.position <= 3
                        ? TpTokens.blue
                        : t.mutedInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            TpBar(height: 3, radius: 2, fraction: entry.fraction),
          ],
        ),
      ),
    );
  }
}

class _RowSkeletons extends StatelessWidget {
  const _RowSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return Column(
      children: <Widget>[
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: t.track,
                borderRadius: BorderRadius.circular(t.rInner),
              ),
            ),
          ),
      ],
    );
  }
}
