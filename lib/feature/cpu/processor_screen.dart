import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/processor.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../rank/category_chips.dart';
import '../rank/rank_category.dart';

/// 둘러보기 · 프로세서. 맨 위에 조립 견적, 그 아래 모바일·노트북 상위 몇 개.
///
/// 구간을 세그먼트로 가르지 않는다. 카테고리 세그먼트 안에 세그먼트가 또 있으면
/// 어느 줄이 무엇을 바꾸는지 헷갈린다.
class ProcessorScreen extends ConsumerWidget {
  const ProcessorScreen({super.key, this.onCategory, this.onBuild, this.onAll});

  final ValueChanged<RankCategory>? onCategory;
  final VoidCallback? onBuild;
  final ValueChanged<ProcessorSegment>? onAll;

  static const int _top = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final glass = context.tp.isGlass;

    Widget section(ProcessorSegment s) {
      final ranked = ref.watch(processorsInProvider(s));
      return TpGroup(
        header: s.key.tr(),
        children: <Widget>[
          for (final r in ranked.take(_top)) ProcessorRow(entry: r),
          if (ranked.length > _top)
            TpRow(
              title: K.seeAll.tr(),
              value: '${ranked.length}',
              titleStyle: TextStyle(color: context.sys.accentText),
              onTap: onAll == null ? null : () => onAll!(s),
            ),
        ],
      );
    }

    return TpPage(
      title: K.tab(TpTab.browse).tr(),
      tab: TpTab.browse,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: CategoryChips(
              current: RankCategory.processors,
              onSelect: onCategory ?? (_) {},
            ),
          ),
        ),
        if (onBuild != null)
          SliverToBoxAdapter(
            child: TpGroup(
              children: <Widget>[
                TpRow(
                  title: K.buildTitle.tr(),
                  subtitle: K.buildRowSub.tr(),
                  leading: TpIconTile(
                    icon: glass ? CupertinoIcons.wrench : Icons.build_outlined,
                  ),
                  onTap: onBuild,
                ),
              ],
            ),
          ),
        if (catalog is AsyncLoading && !catalog.hasError)
          const SliverToBoxAdapter(child: SizedBox(height: 200))
        else if (catalog.hasError)
          const SliverToBoxAdapter(child: TpCatalogError())
        else ...<Widget>[
          SliverToBoxAdapter(child: section(ProcessorSegment.mobile)),
          SliverToBoxAdapter(child: section(ProcessorSegment.laptop)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: Text(
                K.cpuNote.tr(),
                style: TextStyle(fontSize: 13, color: context.sys.label2),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// 한 구간 전체. "모두 보기"에서 push.
class ProcessorListScreen extends ConsumerWidget {
  const ProcessorListScreen({super.key, required this.segment, this.onBack});

  final ProcessorSegment segment;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ranked = ref.watch(processorsInProvider(segment));
    return TpPage(
      title: segment.key.tr(),
      tab: TpTab.browse,
      onBack: onBack,
      slivers: <Widget>[
        TpGroupSliver(
          count: ranked.length,
          footer: K.cpuNote.tr(),
          builder: (context, i) => ProcessorRow(entry: ranked[i]),
        ),
      ],
    );
  }
}

class ProcessorRow extends StatelessWidget {
  const ProcessorRow({super.key, required this.entry});

  final RankedProcessor entry;

  @override
  Widget build(BuildContext context) {
    final p = entry.processor;
    return TpRow(
      title: p.name,
      subtitle: p.sub,
      leading: TpRankBadge(rank: entry.position),
      value: p.index?.toString() ?? DeviceSpecs.empty,
      valueStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: context.sys.label,
      ),
      chevron: false,
      semanticsLabel: K.a11yProcessorRow.tr(
        args: <String>[
          '${entry.position}',
          p.name,
          p.index?.toString() ?? DeviceSpecs.empty,
        ],
      ),
      below: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TpTrack(value: entry.fraction),
      ),
    );
  }
}
