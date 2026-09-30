import 'dart:async' show Timer, unawaited;

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
import '../../shared/widgets/tp_pop_in.dart';
import '../../shared/widgets/tp_pulse.dart';
import '../viewer/viewer_stage.dart';

/// 기기 상세. 이름이 large title 이고, 스크롤하면 바의 작은 제목이 된다.
class DetailScreen extends ConsumerStatefulWidget {
  const DetailScreen({
    super.key,
    required this.slug,
    this.onBack,
    this.onCompare,
    this.onView3D,
    this.onSignIn,
  });

  final String slug;
  final VoidCallback? onBack;
  final ValueChanged<String>? onCompare;
  final ValueChanged<String>? onView3D;

  /// 첫 담기 뒤 로그인 권유에서.
  final VoidCallback? onSignIn;

  /// 공유 실패 안내가 떠 있는 시간.
  static const Duration noticeFor = Duration(seconds: 4);

  @override
  ConsumerState<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends ConsumerState<DetailScreen> {
  /// 공유 시트를 못 띄웠다는 안내. 잠깐 떠 있다가 사라진다.
  bool _shareFailed = false;
  Timer? _noticeTimer;

  @override
  void dispose() {
    _noticeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slug = widget.slug;
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
      onBack: widget.onBack,
      actions: <TpBarAction>[
        if (loaded != null)
          TpBarAction(
            label: K.share.tr(),
            icon: context.icons.share,
            symbol: 'square.and.arrow.up',
            onTap: () => unawaited(_share(loaded)),
          ),
      ],
      floating: _shareFailed ? const _Notice(key: _Notice.shareKey) : null,
      slivers: <Widget>[
        device.when(
          loading: () => const SliverToBoxAdapter(child: _DetailSkeleton()),
          error: (e, _) => SliverToBoxAdapter(
            child: _DetailError(error: e, slug: slug),
          ),
          data: (d) => SliverToBoxAdapter(
            child: _DetailBody(
              device: d,
              onCompare: widget.onCompare,
              onView3D: widget.onView3D,
              onSignIn: widget.onSignIn,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _share(Smartphone device) async {
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
      // 아무 일도 안 일어난 것처럼 보이면 또 누른다. 안 됐다고 말해 준다.
      if (!mounted) return;
      setState(() => _shareFailed = true);
      _noticeTimer?.cancel();
      _noticeTimer = Timer(DetailScreen.noticeFor, () {
        if (mounted) setState(() => _shareFailed = false);
      });
    }
  }
}

/// 공유 실패 한 줄. 바닥에 잠깐 뜬다.
class _Notice extends StatelessWidget {
  const _Notice({super.key});

  static const Key shareKey = ValueKey<String>('detail-share-failed');

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return TpPopIn(
      from: 0.9,
      child: Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: sys.label,
            borderRadius: BorderRadius.circular(context.tp.isGlass ? 22 : 8),
          ),
          child: Text(
            K.shareFailed.tr(),
            style: TextStyle(fontSize: 15, color: sys.background),
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.device,
    this.onCompare,
    this.onView3D,
    this.onSignIn,
  });

  final Smartphone device;
  final ValueChanged<String>? onCompare;
  final ValueChanged<String>? onView3D;
  final VoidCallback? onSignIn;

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
                    if (!shortlisted) {
                      unawaited(
                        ref
                            .read(loginPromptProvider.notifier)
                            .offer(device.slug),
                      );
                    }
                  },
                ),
              ),
              if (ref.watch(loginPromptProvider) == device.slug)
                _LoginPrompt(
                  onSignIn: () {
                    ref.read(loginPromptProvider.notifier).dismiss();
                    onSignIn?.call();
                  },
                  onLater: () =>
                      ref.read(loginPromptProvider.notifier).dismiss(),
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
            // iOS 는 묶음 글자와 같은 32, Android 는 카드가 없어 16.
            padding: EdgeInsets.symmetric(horizontal: glass ? 32 : 16),
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

/// 첫 담기 뒤 한 번. "다른 기기에서도" + 로그인·나중에.
class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onSignIn, required this.onLater});

  final VoidCallback onSignIn;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    return TpPopIn(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
        decoration: BoxDecoration(
          color: sys.cell,
          borderRadius: BorderRadius.circular(glass ? 18 : 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  glass ? CupertinoIcons.cloud : Icons.cloud_outlined,
                  size: 20,
                  color: TpSys.accent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      K.promptTitle.tr(),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.35,
                        color: sys.label,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton(
                  onPressed: onLater,
                  child: Text(
                    K.notNow.tr(),
                    style: TextStyle(color: sys.label2),
                  ),
                ),
                TextButton(
                  onPressed: onSignIn,
                  child: Text(
                    K.signIn.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: sys.accentText,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
    // 사진이 없거나 못 받으면(카탈로그 주소가 지금 전부 404 다) 빈 사진 아이콘
    // 대신 뷰어의 기기 그림을 천천히 흔들어 둔다.
    final placeholder = Padding(
      padding: const EdgeInsets.all(12),
      child: FittedBox(
        child: SizedBox(
          width: 300,
          height: 380,
          child: ViewerStage(interactive: false, ink: sys.label),
        ),
      ),
    );
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
    // 다시 연결되면 사용자가 누르기 전에 다시 받는다.
    ref.listen<AsyncValue<bool>>(offlineProvider, (prev, next) {
      if (prev?.value == true && next.value == false) {
        ref.invalidate(deviceProvider(slug));
      }
    });

    // 연결 상태를 못 읽으면 지금까지대로 일반 실패다.
    final offline = ref.watch(offlineProvider).value ?? false;
    final unreachable = offline && error is NetworkFailure;

    // 예외를 그대로 찍으면 "NotFoundFailure: smartphones/... 레코드를 찾을
    // 수 없다" 가 화면에 뜬다 — 영어 사용자에게도 한국어로.
    return TpErrorState(
      title: unreachable ? K.offlineTitle.tr() : K.loadFailed.tr(),
      body: unreachable ? K.offlineBody.tr() : K.loadFailedBody.tr(),
      // 끊긴 채로도 누를 수 있다. 연결 표시가 틀릴 때가 있다.
      onRetry: () => ref.invalidate(deviceProvider(slug)),
    );
  }
}
