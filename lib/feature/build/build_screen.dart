import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_sys.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_menu.dart';
import '../../shared/widgets/tp_page.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../domain/model/build_estimate.dart';
import '../../domain/model/tp_money.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_chip.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_shimmer.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_slider.dart';

/// 조립 PC 견적.
///
/// 용도와 예산을 주면 예산 안의 모든 CPU×GPU 조합을 점수 매겨 셋을 고른다.
/// 계산은 [BuildEstimate] 가 하고 여기서는 그리기만 한다.
///
/// **없는 제품을 지어내지 않는다.** TechAPI 에 메인보드·메모리·저장장치·
/// 파워·케이스가 없어서 실제 제품으로 고르는 건 CPU 와 GPU 뿐이다. 나머지는
/// 두 부품에서 도출되는 요구사양으로만 내놓고, 예산이 완제품 값이 아니라는
/// 것도 화면에 적는다 — 안 적으면 "$1,500 짜리 PC" 로 읽힌다.
class BuildScreen extends ConsumerWidget {
  const BuildScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.tpText;
    final motion = context.motion;
    final parts = ref.watch(partsProvider);
    final query = ref.watch(buildQueryProvider);
    final picks = ref.watch(buildPicksProvider);
    final money = ref.watch(moneyProvider);
    final loading = parts.isLoading && !parts.hasError;
    final cheapest = switch (parts.value) {
      final p? => BuildEstimate.cheapestUsd(p.cpus, p.gpus),
      null => null,
    };

    final sys = context.sys;
    return TpPage(
      title: K.buildTitle.tr(),
      tab: TpTab.browse,
      onBack: onBack,
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 8),
              TpGroup(
                footer: query.useCase.subKey.tr(),
                children: <Widget>[
                  TpMenu(
                    items: <TpMenuItem>[
                      for (final use in BuildUseCase.values)
                        TpMenuItem(
                          label: use.key.tr(),
                          checked: use == query.useCase,
                          onTap: () => ref
                              .read(buildQueryProvider.notifier)
                              .useCase(use),
                        ),
                    ],
                    builder: (context, open) => TpRow(
                      title: K.buildUse.tr(),
                      value: query.useCase.key.tr(),
                      chevron: false,
                      onTap: open,
                      trailing: Icon(
                        context.tp.isGlass
                            ? CupertinoIcons.chevron_up_chevron_down
                            : Icons.unfold_more,
                        size: 16,
                        color: sys.label3,
                      ),
                    ),
                  ),
                  _Budget(
                    usd: query.budgetUsd,
                    money: money,
                    onChanged: (v) =>
                        ref.read(buildQueryProvider.notifier).budget(v),
                  ),
                ],
              ),
              AnimatedSwitcher(
                duration: motion.contentSwap.duration,
                switchInCurve: motion.contentSwap.curve,
                switchOutCurve: motion.contentSwap.curve,
                child: parts.hasError
                    ? TpCatalogError(
                        key: const ValueKey<String>('error'),
                        also: partsProvider,
                      )
                    // 읽는 동안 "맞는 조합 없음"이 잠깐 비치지 않게.
                    : loading
                    ? const _ComboSkeleton(key: ValueKey<String>('loading'))
                    : picks.isEmpty
                    ? Padding(
                        key: const ValueKey<String>('empty'),
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                        child: Text(
                          <String>[
                            K.buildEmpty.tr(),
                            if (cheapest != null)
                              K.buildEmptyFrom.tr(
                                args: <String>[money.format(cheapest)],
                              ),
                          ].join(' '),
                          style: TextStyle(fontSize: 15, color: sys.label2),
                        ),
                      )
                    : Padding(
                        key: ValueKey<String>(
                          '${query.useCase.name}-${query.budgetUsd}',
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: <Widget>[
                            for (final combo in picks)
                              _ComboCard(
                                combo: combo,
                                useCase: query.useCase,
                                budgetUsd: query.budgetUsd,
                                money: money,
                              ),
                          ],
                        ),
                      ),
              ),
              if (picks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: _Requirements(combo: picks.first),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 18, 32, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(K.buildScope.tr(), style: type.caption),
                    const SizedBox(height: 8),
                    Text(
                      K.buildPsuNote.tr(
                        args: <String>['${BuildEstimate.platformWatts}'],
                      ),
                      style: type.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Budget extends StatelessWidget {
  const _Budget({
    required this.usd,
    required this.money,
    required this.onChanged,
  });

  final int usd;
  final TpMoney money;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    // iOS 칩 바탕(흰색 70%)은 흰 셀 위에서 사라진다. 채움색으로 모양을 낸다.
    final chipColor = context.tp.isGlass ? context.sys.fill3 : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(K.buildBudget.tr(), style: type.body)),
              Text(money.format(usd), style: type.cardTitle),
            ],
          ),
          TpSlider(
            value: usd.toDouble(),
            min: BuildEstimate.minBudget.toDouble(),
            max: BuildEstimate.maxBudget.toDouble(),
            // 50달러 단위. 1달러씩 끌면 추천이 안 바뀌는데도 계속 다시 센다.
            divisions:
                (BuildEstimate.maxBudget - BuildEstimate.minBudget) ~/ 50,
            label: money.format(usd),
            onChanged: (v) => onChanged(v.round()),
          ),
          // 프리셋은 넘칠 수 있다 — 원화로 바뀌면 자릿수가 길어진다.
          // 줄바꿈 대신 가로 스크롤로 둔다. 위 칩 행과 같은 몸짓이다.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                for (final preset in BuildEstimate.budgetPresets)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: TpChip(
                      label: money.format(preset),
                      selected: preset == usd,
                      color: chipColor,
                      onTap: () => onChanged(preset),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 조합 한 장.
class _ComboCard extends StatelessWidget {
  const _ComboCard({
    required this.combo,
    required this.useCase,
    required this.budgetUsd,
    required this.money,
  });

  final BuildCombo combo;
  final BuildUseCase useCase;
  final int budgetUsd;
  final TpMoney money;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;
    final warning = _bottleneck(combo.bottleneck);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TpSurface(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
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
                      Text(combo.cpu.name, style: type.cardTitle),
                      Text(combo.gpu.name, style: type.cardTitle),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  combo.score.toStringAsFixed(1),
                  style: type.cardTitle,
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(_reason(context), style: type.caption),
            if (warning != null) ...<Widget>[
              const SizedBox(height: 6),
              // 병목은 경고지 실패가 아니다. 붉게 칠하지 않고 한 줄로 적는다.
              Text(warning, style: type.caption.copyWith(color: t.dim)),
            ],
          ],
        ),
      ),
    );
  }

  /// 왜 이걸 골랐는지 한 줄. 점수·가격·전력만 근거로 쓴다.
  String _reason(BuildContext context) {
    final (cpuLed, value) = BuildEstimate.lead(combo, useCase);
    final lead = (cpuLed ? K.buildReasonCpu : K.buildReasonGpu).tr(
      args: <String>['$value'],
    );
    final headroom = budgetUsd - combo.priceUsd;
    final rest = headroom > 100
        ? K.buildHeadroom.tr(args: <String>[money.format(headroom)])
        : K.buildTight.tr();
    final psu = K.buildPsu.tr(args: <String>['${combo.psuWatts}']);
    return '$lead · ${money.format(combo.priceUsd)} · $rest · $psu';
  }

  static String? _bottleneck(Bottleneck b) => switch (b) {
    Balanced() => null,
    CpuBound(:final gap) => K.buildBottleneckCpu.tr(args: <String>['$gap']),
    GpuBound(:final gap) => K.buildBottleneckGpu.tr(args: <String>['$gap']),
  };
}

/// 부품을 읽는 동안. 조합 카드 세 장 자리.
class _ComboSkeleton extends StatelessWidget {
  const _ComboSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: TpShimmer(
      child: Column(
        children: <Widget>[
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TpSurface(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    for (final width in <double>[0.6, 0.5, 0.8])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: FractionallySizedBox(
                          widthFactor: width,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              color: context.sys.fill3,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// 나머지 부품 요구사양. 1등 조합 기준이다.
class _Requirements extends StatelessWidget {
  const _Requirements({required this.combo});

  final BuildCombo combo;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;
    final rows = BuildEstimate.requirements(combo.cpu, combo.gpu);

    return TpSurface(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(K.buildReq.tr().toUpperCase(), style: type.eyebrow),
          const SizedBox(height: 6),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: Text(
                      row.kind.key.tr(),
                      style: type.caption.copyWith(color: t.dim),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      _value(row),
                      style: type.caption,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 값이 없을 때의 문구는 종류마다 다르다.
  ///
  /// 내장 그래픽이 없는 것은 "안 적혔다"가 아니라 **"없다"** 이고, 그러면
  /// 외장 GPU 가 필수라는 뜻이다. 둘을 같은 말로 쓰면 정보가 사라진다.
  static String _value(Requirement row) {
    final value = row.value;
    if (value == null) {
      return row.kind == RequirementKind.integratedGraphics
          ? K.buildReqNoIgpu.tr()
          : K.buildReqNone.tr();
    }
    return switch (row.kind) {
      RequirementKind.psu => K.buildWatts.tr(args: <String>[value]),
      RequirementKind.gpuDraw => '${value}W',
      _ => value,
    };
  }
}
