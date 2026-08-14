import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../core/analytics.dart';
import '../../core/error_reporter.dart';
import '../../core/failure.dart';
import '../../data/service/link_opener.dart';
import '../../shared/copy_keys.dart';
import '../share/share_text.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_score_strip.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';

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

    // 아직 안 왔거나 실패한 기기는 공유할 게 없다.
    final loaded = device.value;

    return TpShell(
      onBack: onBack,
      trailing: loaded == null
          ? null
          : TpShellAction(
              icon: Icons.share,
              label: K.share.tr(),
              onTap: () => unawaited(_share(ref, loaded)),
            ),
      child: AnimatedSwitcher(
        duration: context.motion.contentSwap.duration,
        switchInCurve: context.motion.contentSwap.curve,
        switchOutCurve: context.motion.contentSwap.curve,
        child: device.when(
          loading: () =>
              const _DetailSkeleton(key: ValueKey<String>('skeleton')),
          error: (e, _) =>
              _DetailError(key: const ValueKey<String>('error'), error: e),
          data: (d) => _DetailBody(
            key: ValueKey<String>(d.slug),
            device: d,
            onCompare: onCompare,
            onView3D: onView3D,
          ),
        ),
      ),
    );
  }

  /// 화면이 이미 말하고 있는 것을 그대로 보낸다 — 이름, 지수, 링크.
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
      // 시트를 못 띄운 것으로 화면이 죽지 않는다.
      TpErrors.record(e, s, reason: 'share.device');
    }
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    super.key,
    required this.device,
    this.onCompare,
    this.onView3D,
  });

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
            Expanded(
              child: Text(
                DeviceSpecs.formatPrice(device.msrpUsd),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: type.body,
              ),
            ),
            const SizedBox(width: 12),
            // 지수 숫자는 이미 44px 이다. 손쉬운 사용 배율을 그대로 곱하면
            // 가격과 한 줄에 안 들어간다. 읽는 데 지장이 없는 선까지만 키운다.
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
                    Text(
                      index?.toString() ?? DeviceSpecs.empty,
                      style: type.indexNumeral.copyWith(fontSize: 44),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(K.tpIndex.tr(), style: type.caption),
                    ),
                  ],
                ),
              ),
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
          label: (shortlisted ? K.inShortlist : K.addShortlist).tr(),
          filled: !shortlisted,
          onTap: () => ref.read(shortlistProvider.notifier).toggle(device.slug),
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: K.compareButton.tr(),
          filled: false,
          onTap: onCompare == null ? null : () => onCompare!(device.slug),
        ),
        const SizedBox(height: 10),
        _PrimaryButton(
          label: K.view3d.tr(),
          filled: false,
          onTap: onView3D == null ? null : () => onView3D!(device.slug),
        ),

        _BrandCard(slug: device.brand?.slug),

        if (device.sourceUrls.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          // CC-BY-SA 4.0 상 출처 표기는 선택이 아니고, 표기만으로도 모자란다.
          // 라이선스 본문과 원본에 닿을 수 있어야 한다.
          _LinkLine(
            label: K.dataSource.tr(),
            url: TpUrls.license,
            style: type.caption,
          ),
          for (final url in device.sourceUrls)
            _LinkLine(
              // 원문 주소는 한 줄을 다 먹는다. 보이는 건 도메인만, 열리는
              // 것은 원문 그대로 — 귀속에 필요한 건 링크가 살아 있는 것이다.
              label: Uri.tryParse(url)?.host.isNotEmpty ?? false
                  ? Uri.parse(url).host
                  : url,
              url: Uri.tryParse(url),
              style: type.caption,
              topPadding: 2,
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
  const _PrimaryButton({required this.label, required this.filled, this.onTap});

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final radius = BorderRadius.circular(
      t.isGlass ? TpTokens.rControl : t.rCard,
    );
    final move = context.motion.selection;

    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        // 담기를 누르면 채움색·라벨·그림자가 한꺼번에 즉시 바뀌어서 저장됐다는
        // 느낌이 없었다.
        child: AnimatedContainer(
          duration: move.duration,
          curve: move.curve,
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
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton({super.key});

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

/// 만든 회사 한 조각.
///
/// 기기에 임베드된 brand 는 이름뿐이라 국가·설립연도·설명은 카탈로그의
/// `brands` 에서 찾아온다. 못 찾으면 아무것도 안 그린다 — 옛 카탈로그를
/// 받아둔 기기에는 이 목록이 없다.
class _BrandCard extends ConsumerWidget {
  const _BrandCard({required this.slug});

  final String? slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(catalogProvider).value?.brand(slug);
    if (brand == null) return const SizedBox.shrink();

    final type = context.tpText;
    // `context.locale` 은 EasyLocalization 위젯을 요구한다. 테스트는 그걸
    // 안 올리므로(하네스 주석 참고) Flutter 가 늘 깔아주는 쪽을 본다.
    final ko = Localizations.maybeLocaleOf(context)?.languageCode == 'ko';
    final description = ko
        ? (brand.descriptionKo ?? brand.descriptionEn)
        : (brand.descriptionEn ?? brand.descriptionKo);

    final meta = <String>[
      if (brand.country != null) brand.country!,
      if (brand.foundedYear != null)
        K.brandFounded.tr(args: <String>['${brand.foundedYear}']),
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: TpSurface(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(child: Text(brand.name, style: type.cardTitle)),
                if (meta.isNotEmpty) Text(meta, style: type.caption),
              ],
            ),
            if (description != null && description.isNotEmpty) ...<Widget>[
              const SizedBox(height: 6),
              Text(description, style: type.secondary),
            ],
            if (brand.website != null) ...<Widget>[
              const SizedBox(height: 2),
              _LinkLine(
                label: K.brandSite.tr(),
                url: Uri.tryParse(brand.website!),
                style: type.caption.copyWith(color: TpTokens.blueText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 눌러서 여는 한 줄.
///
/// 밑줄이나 색을 넣지 않는다. 명세에 이 자리의 링크 스타일이 없고, 캡션
/// 크기의 흐린 글자에 파란색을 얹으면 본문보다 눈에 띈다. 대신 히트 영역을
/// 넓히고 스크린 리더에는 링크라고 알린다.
class _LinkLine extends ConsumerWidget {
  const _LinkLine({
    required this.label,
    required this.url,
    required this.style,
    this.topPadding = 0,
  });

  final String label;
  final Uri? url;
  final TextStyle style;
  final double topPadding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Text(label, style: style, maxLines: 1),
    );
    final target = url;
    if (target == null) return text;

    return Align(
      alignment: Alignment.centerLeft,
      child: TpTapTarget(
        link: true,
        minSize: 44,
        onTap: () => unawaited(_open(ref, target)),
        child: text,
      ),
    );
  }

  Future<void> _open(WidgetRef ref, Uri url) async {
    try {
      await ref.read(linkOpenerProvider).open(url);
    } catch (e, s) {
      // 열 앱이 없는 기기도 있다. 화면은 그대로 둔다.
      TpErrors.record(e, s, reason: 'link.open');
    }
  }
}

/// 기기를 못 불러왔다.
///
/// 카탈로그에 있는 기기는 애셋에서 오므로 여기까지 오지 않는다. 여기 오는
/// 것은 전부 TechAPI 를 타는 기기다 — 그래서 인터넷이 끊긴 경우가 실제로
/// 흔하다. 그 경우를 "불러오지 못했습니다"로 뭉뚱그리면 사용자는 앱이 고장
/// 난 줄 안다.
class _DetailError extends ConsumerWidget {
  const _DetailError({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.tpText;

    // 연결 상태를 못 읽으면 지금까지대로 일반 실패다.
    final offline = ref.watch(offlineProvider).value ?? false;
    final unreachable = offline && error is NetworkFailure;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              unreachable ? K.offlineTitle.tr() : K.loadFailed.tr(),
              style: type.cardTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              unreachable ? K.offlineBody.tr() : '$error',
              style: type.caption,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
