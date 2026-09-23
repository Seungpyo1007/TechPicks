import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../domain/model/build_estimate.dart';
import '../../domain/model/device_specs.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_chip.dart';
import '../../shared/widgets/tp_error_state.dart';
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
  const BuildScreen({super.key, this.onTabSelected});

  final ValueChanged<TpTab>? onTabSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.tpText;
    final motion = context.motion;
    final parts = ref.watch(partsProvider);
    final query = ref.watch(buildQueryProvider);
    final picks = ref.watch(buildPicksProvider);

    return TpShell(
      title: K.buildTitle.tr(),
      tab: TpTab.decide,
      onTabSelected: onTabSelected,
      child: Builder(
        builder: (context) => ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 24) +
              tpContentInset(context),
          children: <Widget>[
            _UseCases(
              current: query.useCase,
              onSelect: (u) => ref.read(buildQueryProvider.notifier).useCase(u),
            ),
            const SizedBox(height: 6),
            Text(query.useCase.subKey.tr(), style: type.secondary),
            const SizedBox(height: 16),
            _Budget(
              usd: query.budgetUsd,
              onChanged: (v) => ref.read(buildQueryProvider.notifier).budget(v),
            ),
            const SizedBox(height: 18),

            AnimatedSwitcher(
              duration: motion.contentSwap.duration,
              switchInCurve: motion.contentSwap.curve,
              switchOutCurve: motion.contentSwap.curve,
              child: parts.hasError
                  ? const TpCatalogError(key: ValueKey<String>('error'))
                  : picks.isEmpty
                  ? TpSurface(
                      key: const ValueKey<String>('empty'),
                      padding: const EdgeInsets.all(20),
                      // 오류가 아니다. 예산이 낮아서 후보가 없는 것이고,
                      // "문제가 생겼습니다" 로 쓰면 거짓말이 된다.
                      child: Text(K.buildEmpty.tr(), style: type.body),
                    )
                  : Column(
                      key: ValueKey<String>(
                        '${query.useCase.name}-${query.budgetUsd}',
                      ),
                      children: <Widget>[
                        for (final combo in picks)
                          _ComboCard(
                            combo: combo,
                            useCase: query.useCase,
                            budgetUsd: query.budgetUsd,
                          ),
                      ],
                    ),
            ),

            if (picks.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              _Requirements(combo: picks.first),
            ],

            const SizedBox(height: 18),
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
    );
  }
}

/// 용도 칩.
///
/// **가로 스크롤이 아니라 줄바꿈이다.** 402pt 에서 넷 중 둘만 보이고
/// 나머지가 화면 밖으로 밀렸는데, 용도는 이 화면 전체의 입력이라 절반이
/// 숨으면 고를 수 있다는 것조차 모른다. 랭킹의 축 칩은 스크롤해도 되지만
/// (거기선 하나가 이미 골라져 있고 나머지는 대안이다) 여기선 아니다.
class _UseCases extends StatelessWidget {
  const _UseCases({required this.current, required this.onSelect});

  final BuildUseCase current;
  final ValueChanged<BuildUseCase> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final use in BuildUseCase.values)
          TpChip(
            label: use.key.tr(),
            selected: use == current,
            onTap: () => onSelect(use),
          ),
      ],
    );
  }
}

/// 예산. 프리셋과 슬라이더.
///
/// 슬라이더만 두면 정확한 값을 맞추기 어렵고, 프리셋만 두면 그 사이를 못
/// 고른다. 둘 다 둔다.
class _Budget extends StatelessWidget {
  const _Budget({required this.usd, required this.onChanged});

  final int usd;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;

    return TpSurface(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  K.buildBudget.tr().toUpperCase(),
                  style: type.eyebrow,
                ),
              ),
              Text(DeviceSpecs.formatPrice(usd), style: type.cardTitle),
            ],
          ),
          TpSlider(
            value: usd.toDouble(),
            min: BuildEstimate.minBudget.toDouble(),
            max: BuildEstimate.maxBudget.toDouble(),
            // 50달러 단위. 1달러씩 끌면 추천이 안 바뀌는데도 계속 다시 센다.
            divisions:
                (BuildEstimate.maxBudget - BuildEstimate.minBudget) ~/ 50,
            label: DeviceSpecs.formatPrice(usd),
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
                      label: DeviceSpecs.formatPrice(preset),
                      selected: preset == usd,
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
  });

  final BuildCombo combo;
  final BuildUseCase useCase;
  final int budgetUsd;

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
        ? K.buildHeadroom.tr(args: <String>[DeviceSpecs.formatPrice(headroom)])
        : K.buildTight.tr();
    final psu = K.buildPsu.tr(args: <String>['${combo.psuWatts}']);
    return '$lead · ${DeviceSpecs.formatPrice(combo.priceUsd)} · $rest · $psu';
  }

  static String? _bottleneck(Bottleneck b) => switch (b) {
    Balanced() => null,
    CpuBound(:final gap) => K.buildBottleneckCpu.tr(args: <String>['$gap']),
    GpuBound(:final gap) => K.buildBottleneckGpu.tr(args: <String>['$gap']),
  };
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
