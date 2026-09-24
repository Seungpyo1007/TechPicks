import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_icons.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../core/analytics.dart';
import '../../core/error_reporter.dart';
import '../../core/failure.dart';
import '../../data/dto/smartphone.dart';
import '../../data/service/link_opener.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_link_line.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_score_strip.dart';
import '../share/share_text.dart';
import '../../shared/tp_haptics.dart';
import '../../shared/widgets/tp_number.dart';
import '../../shared/widgets/tp_pulse.dart';

/// 기기 상세. 이름이 large title 이고, 스크롤하면 바의 작은 제목이 된다.
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
    final loaded = device.value;
    final name =
        loaded?.name ??
        ref
            .watch(catalogProvider)
            .value
            ?.smartphones
            .where((d) => d.slug == slug)
            .firstOrNull
            ?.name ??
        '';

    return TpPage(
      title: name,
      onBack: onBack,
      actions: <TpBarAction>[
        if (loaded != null)
          TpBarAction(
            label: K.share.tr(),
            icon: context.icons.share,
            onTap: () => unawaited(_share(ref, loaded)),
          ),
      ],
      slivers: <Widget>[
        device.when(
          loading: () => const SliverToBoxAdapter(child: _DetailSkeleton()),
          error: (e, _) => SliverToBoxAdapter(
            child: _DetailError(error: e, slug: slug),
          ),
          data: (d) => SliverToBoxAdapter(
            child: _DetailBody(
              device: d,
              onCompare: onCompare,
              onView3D: onView3D,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _share(WidgetRef ref, Smartphone device) async {
    final index = TpIndex.of(device.score, ref.read(weightsProvider));
    TpAnalytics.shared('device');
    try {
      await ref
          .read(shareServiceProvider)
          .shareText(
            ShareText.device(
              name: device.name,
              index: index,
              slug: device.slug,
            ),
            subject: ShareText.subject(device.name),
          );
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'share.device');
    }
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.device, this.onCompare, this.onView3D});

  final Smartphone device;
  final ValueChanged<String>? onCompare;
  final ValueChanged<String>? onView3D;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sys = context.sys;
    final type = context.tpText;
    final weights = ref.watch(weightsProvider);
    final money = ref.watch(moneyProvider);
    final shortlisted = ref.watch(shortlistProvider).contains(device.slug);
    final index = TpIndex.of(device.score, weights);
    final glass = context.tp.isGlass;

    final line = <String>[
      if (device.brand?.name != null) device.brand!.name,
      money.format(device.msrpUsd),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: _ImageSlot(url: device.imageUrl),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  line,
                  style: TextStyle(fontSize: 15, color: sys.label2),
                ),
              ),
              MediaQuery.withClampedTextScaling(
                maxScaleFactor: 1.3,
                child: Semantics(
                  container: true,
                  label: index == null
                      ? null
                      : K.a11yIndex.tr(args: <String>[index.toString()]),
                  excludeSemantics: index != null,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      TpNumber(
                        index?.toString() ?? DeviceSpecs.empty,
                        style: type.indexNumeral.copyWith(
                          fontSize: 44,
                          color: TpSys.accent,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          K.tpIndex.tr(),
                          style: TextStyle(fontSize: 13, color: sys.label2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            children: <Widget>[
              TpPulse(
                trigger: shortlisted,
                child: TpPill(
                  label: (shortlisted ? K.inShortlist : K.addShortlist).tr(),
                  kind: shortlisted ? TpPillKind.tinted : TpPillKind.filled,
                  icon: shortlisted
                      ? (glass ? CupertinoIcons.check_mark : Icons.check)
                      : (glass ? CupertinoIcons.add : Icons.add),
                  onTap: () {
                    TpHaptics.commit();
                    ref.read(shortlistProvider.notifier).toggle(device.slug);
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TpPill(
                      label: K.compareButton.tr(),
                      kind: TpPillKind.tinted,
                      height: 44,
                      onTap: onCompare == null
                          ? null
                          : () => onCompare!(device.slug),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TpPill(
                      label: K.view3d.tr(),
                      kind: TpPillKind.tinted,
                      height: 44,
                      onTap: onView3D == null
                          ? null
                          : () => onView3D!(device.slug),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        TpGroup(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          children: <Widget>[TpScoreStrip(axes: TpIndex.axes(device.score))],
        ),
        TpGroup(
          children: <Widget>[
            for (final spec in DeviceSpecs.of(device, weights, money))
              TpRow(
                title: SpecLabels.of(spec.kind),
                titleStyle: TextStyle(fontSize: 15, color: sys.label2),
                value: spec.value,
                valueStyle: TextStyle(
                  fontSize: 15,
                  color: spec.hasValue ? sys.label : sys.label3,
                ),
                chevron: false,
              ),
          ],
        ),
        _BrandCard(slug: device.brand?.slug),
        if (device.sourceUrls.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TpLinkLine(
                  label: K.dataSource.tr(),
                  url: TpUrls.license,
                  style: type.caption,
                ),
                for (final url in device.sourceUrls)
                  TpLinkLine(
                    label: TpLinkLine.hostOf(url),
                    url: Uri.tryParse(url),
                    style: type.caption,
                    topPadding: 2,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ImageSlot extends StatelessWidget {
  const _ImageSlot({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final address = url?.trim();
    final placeholder = Icon(context.icons.image, size: 40, color: sys.label3);
    return Container(
      height: 236,
      decoration: BoxDecoration(
        color: sys.cell,
        borderRadius: BorderRadius.circular(TpGroup.radius),
      ),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: address == null || address.isEmpty
          ? placeholder
          : Image.network(
              address,
              fit: BoxFit.contain,
              width: double.infinity,
              height: 236,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: <Widget>[
        for (final h in <double>[236, 40, 110, 220])
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: context.sys.fill3,
                borderRadius: BorderRadius.circular(TpGroup.radius),
              ),
            ),
          ),
      ],
    ),
  );
}

class _BrandCard extends ConsumerWidget {
  const _BrandCard({required this.slug});

  final String? slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(catalogProvider).value?.brand(slug);
    if (brand == null) return const SizedBox.shrink();
    final sys = context.sys;
    final ko = Localizations.maybeLocaleOf(context)?.languageCode == 'ko';
    final description = ko
        ? (brand.descriptionKo ?? brand.descriptionEn)
        : (brand.descriptionEn ?? brand.descriptionKo);
    final meta = <String>[
      if (brand.foundedYear != null)
        K.brandFounded.tr(args: <String>['${brand.foundedYear}']),
      if (brand.country != null) brand.country!,
    ].join(' · ');

    return TpGroup(
      header: K.brand.tr(),
      footer: description,
      children: <Widget>[
        TpRow(
          title: brand.name,
          subtitle: meta.isEmpty ? null : meta,
          leading: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: sys.fill3,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              brand.name.characters.first,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: sys.label2,
              ),
            ),
          ),
          chevron: false,
        ),
        if (brand.website != null)
          TpRow(
            title: K.brandSite.tr(),
            titleStyle: TextStyle(color: sys.accentText),
            value: Uri.tryParse(brand.website!)?.host.replaceFirst('www.', ''),
            onTap: () =>
                ref.read(linkOpenerProvider).open(Uri.parse(brand.website!)),
          ),
      ],
    );
  }
}

class _DetailError extends ConsumerWidget {
  const _DetailError({required this.error, required this.slug});

  final Object error;

  /// 다시 받을 대상.
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 연결 상태를 못 읽으면 지금까지대로 일반 실패다.
    final offline = ref.watch(offlineProvider).value ?? false;
    final unreachable = offline && error is NetworkFailure;

    // 예외를 그대로 찍으면 "NotFoundFailure: smartphones/... 레코드를 찾을
    // 수 없다" 가 화면에 뜬다 — 영어 사용자에게도 한국어로.
    return TpErrorState(
      title: unreachable ? K.offlineTitle.tr() : K.loadFailed.tr(),
      body: unreachable ? K.offlineBody.tr() : K.loadFailedBody.tr(),
      onRetry: unreachable ? null : () => ref.invalidate(deviceProvider(slug)),
    );
  }
}
