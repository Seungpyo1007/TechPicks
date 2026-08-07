import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_score_strip.dart';
import '../../shared/widgets/tp_surface.dart';

/// 기기 상세.
///
/// 카피는 아직 하드코딩이다. 번역 파일 이관은 따로 한다.
class DetailScreen extends ConsumerWidget {
  const DetailScreen({
    super.key,
    required this.slug,
    this.onBack,
    this.onCompare,
    this.onView3D,
  });

  final String slug;
  final VoidCallback? onBack;
  final ValueChanged<String>? onCompare;
  final ValueChanged<String>? onView3D;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceProvider(slug));

    return TpShell(
      onBack: onBack,
      child: device.when(
        loading: () => const _DetailSkeleton(),
        error: (e, _) => _DetailError(message: '$e'),
        data: (d) => _DetailBody(
          device: d,
          onCompare: onCompare,
          onView3D: onView3D,
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.device, this.onCompare, this.onView3D});

  final Smartphone device;
  final ValueChanged<String>? onCompare;
  final ValueChanged<String>? onView3D;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tp;
    final type = context.tpText;
    final weights = ref.watch(weightsProvider);
    final shortlisted = ref.watch(shortlistProvider).contains(device.slug);
    final index = TpIndex.of(device.score, weights);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        const _ImageSlot(),
        const SizedBox(height: 16),

        Text((device.brand?.name ?? '').toUpperCase(), style: type.eyebrow),
        const SizedBox(height: 4),
        Text(
          device.name,
          style: type.cardTitle.copyWith(
            fontSize: 28,
            fontWeight: t.isGlass ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(DeviceSpecs.formatPrice(device.msrpUsd), style: type.body),
            const Spacer(),
            Text(
              index?.toString() ?? DeviceSpecs.empty,
              style: type.indexNumeral.copyWith(fontSize: 44),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('TP Index', style: type.caption),
            ),
          ],
        ),
        const SizedBox(height: 16),

        TpSurface(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: <Widget>[
              for (final spec in DeviceSpecs.of(device, weights))
                _SpecRow(spec: spec),
            ],
          ),
        ),
        const SizedBox(height: 14),

        TpSurface(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: TpScoreStrip(axes: TpIndex.axes(device.score)),
        ),
        const SizedBox(height: 16),

        _PrimaryButton(
          label: shortlisted ? 'On your shortlist' : 'Add to shortlist',
          filled: !shortlisted,
          onTap: () =>
              ref.read(shortlistProvider.notifier).toggle(device.slug),
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: 'Compare',
          filled: false,
          onTap: onCompare == null ? null : () => onCompare!(device.slug),
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: 'View in 3D',
          filled: false,
          onTap: onView3D == null ? null : () => onView3D!(device.slug),
        ),

        if (device.sourceUrls.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          // CC-BY-SA 4.0 상 출처 표기는 선택이 아니다.
          Text('Data from TechAPI · CC-BY-SA 4.0', style: type.caption),
          for (final url in device.sourceUrls)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(url, style: type.caption, maxLines: 1),
            ),
        ],
      ],
    );
  }
}

/// 제품 사진 자리. 명세대로 196px 이고, 사진은 아직 없다.
class _ImageSlot extends StatelessWidget {
  const _ImageSlot();

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return Container(
      height: 196,
      decoration: BoxDecoration(
        color: t.slotBg,
        borderRadius: BorderRadius.circular(t.rCard),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, size: 34, color: t.dim),
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.spec});

  final DeviceSpec spec;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: t.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 96,
            child: Text(SpecLabels.of(spec.kind), style: type.secondary),
          ),
          Expanded(
            child: Text(
              spec.value,
              textAlign: TextAlign.right,
              style: type.body.copyWith(
                color: spec.hasValue ? TpTokens.ink : t.dim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.filled,
    this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final radius = BorderRadius.circular(t.isGlass ? TpTokens.rControl : t.rCard);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? TpTokens.blue : t.chipBg,
          borderRadius: radius,
          boxShadow: filled ? t.buttonShadow : null,
        ),
        child: Text(
          label,
          style: type.body.copyWith(
            fontWeight: t.boldWeight,
            color: filled ? Colors.white : TpTokens.ink,
          ),
        ),
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: <Widget>[
        for (final h in <double>[196, 40, 220, 160])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: t.track,
                borderRadius: BorderRadius.circular(t.rCard),
              ),
            ),
          ),
      ],
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('Could not load this device.', style: type.cardTitle),
            const SizedBox(height: 6),
            Text(message, style: type.caption, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
