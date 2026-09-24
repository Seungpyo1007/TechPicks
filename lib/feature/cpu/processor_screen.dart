import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_sys.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/processor.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../rank/browse_screen.dart';
import '../rank/rank_category.dart';

/// 둘러보기 · 프로세서. 뼈대는 [BrowseScreen] 이 그린다.
class ProcessorScreen extends StatelessWidget {
  const ProcessorScreen({super.key, this.onCategory, this.onBuild});

  final ValueChanged<RankCategory>? onCategory;
  final VoidCallback? onBuild;

  @override
  Widget build(BuildContext context) => BrowseScreen(
    category: RankCategory.processors,
    onCategory: onCategory,
    onBuild: onBuild,
  );
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
