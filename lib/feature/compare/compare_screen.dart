import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_surface.dart';

/// 비교. 두 기기를 한 표에 놓고 줄마다 이긴 쪽을 칠한다.
///
/// v1 은 레이더 차트 하나로 이걸 대신했다. 축 다섯 개를 겹쳐 그리면 어느
/// 쪽이 무엇에서 이겼는지 읽히지 않는다.
///
/// 카피는 아직 하드코딩이다.
class CompareScreen extends ConsumerWidget {
  const CompareScreen({
    super.key,
    this.onTabSelected,
    this.onPick,
    this.onAskWhy,
  });

  final ValueChanged<TpTab>? onTabSelected;

  /// 열 머리를 누르면 어느 슬롯을 고르는지 알려준다.
  final ValueChanged<CompareSide>? onPick;

  final VoidCallback? onAskWhy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.tpText;
    final catalog = ref.watch(catalogProvider).value;
    final slots = ref.watch(compareProvider);
    final pairs = ref.watch(comparisonProvider);

    Smartphone? find(String? slug) {
      if (catalog == null || slug == null) return null;
      final hit = catalog.smartphones.where((d) => d.slug == slug);
      return hit.isEmpty ? null : hit.first;
    }

    final a = find(slots.a);
    final b = find(slots.b);

    return TpShell(
      title: K.compareTitle.tr(),
      tab: TpTab.compare,
      onTabSelected: onTabSelected,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _ColumnHead(
                  device: a,
                  onTap: onPick == null ? null : () => onPick!(CompareSide.a),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ColumnHead(
                  device: b,
                  onTap: onPick == null ? null : () => onPick!(CompareSide.b),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (pairs.isEmpty)
            TpSurface(
              padding: const EdgeInsets.all(20),
              child: Text(K.chooseTwo.tr(), style: type.body),
            )
          else
            TpSurface(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Column(
                children: <Widget>[
                  for (final pair in pairs) _CompareRow(pair: pair),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (pairs.isNotEmpty)
            GestureDetector(
              onTap: onAskWhy,
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.tp.chipBg,
                  borderRadius: BorderRadius.circular(
                    context.tp.isGlass ? TpTokens.rControl : context.tp.rCard,
                  ),
                ),
                child: Text(
                  K.askWhy.tr(),
                  style: type.body.copyWith(fontWeight: context.tp.boldWeight),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ColumnHead extends StatelessWidget {
  const _ColumnHead({required this.device, this.onTap});

  final Smartphone? device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;

    return TpSurface(
      strong: true,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            (device?.brand?.name ?? '').toUpperCase(),
            style: type.eyebrow,
            maxLines: 1,
            softWrap: false,
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: Text(
              device?.name ?? K.choose.tr(),
              style: type.cardTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(K.tapToChange.tr(), style: type.caption.copyWith(color: t.dim)),
        ],
      ),
    );
  }
}

/// 한 줄. 이긴 셀만 파란 틴트로 채우고 굵기를 올린다.
class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.pair});

  final SpecPair pair;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            SpecLabels.of(pair.kind),
            style: type.caption,
            maxLines: 1,
            softWrap: false,
          ),
          const SizedBox(height: 4),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Expanded(
                  child: _Cell(spec: pair.a, won: pair.winner == CompareSide.a),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Cell(spec: pair.b, won: pair.winner == CompareSide.b),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.spec, required this.won});

  final DeviceSpec spec;
  final bool won;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: won ? t.tintFill : Colors.transparent,
        borderRadius: BorderRadius.circular(t.rInner - 6),
      ),
      child: Text(
        spec.value,
        style: type.body.copyWith(
          fontWeight: won ? t.boldWeight : FontWeight.w400,
          color: spec.hasValue ? TpTokens.ink : t.dim,
        ),
      ),
    );
  }
}
