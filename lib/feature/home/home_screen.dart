import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_icons.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../core/analytics.dart';
import '../../core/error_reporter.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/movers.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_score_strip.dart';
import '../share/share_text.dart';
import '../../shared/tp_haptics.dart';

/// 오늘. 관심 목록과 그 결론.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onDeviceTap,
    this.onAdd,
    this.onCompareAll,
    this.onAskWhy,
    this.onAsk,
    this.onMoversTap,
    this.onYou,
    this.onWeights,
    this.onCompareDevice,
  });

  final ValueChanged<String>? onDeviceTap;
  final VoidCallback? onAdd;
  final VoidCallback? onCompareAll;
  final VoidCallback? onAskWhy;

  /// 툴바의 질문. 맥락 없이 연다.
  final VoidCallback? onAsk;
  final VoidCallback? onMoversTap;

  /// 내 정보 시트. 오른쪽 위 프로필 버튼.
  final VoidCallback? onYou;

  /// 판정 카드의 가중치. 내 정보 시트를 가중치 자리로 연다.
  final VoidCallback? onWeights;

  /// 관심 목록 컨텍스트 메뉴의 비교.
  final ValueChanged<String>? onCompareDevice;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glass = context.tp.isGlass;
    final shortlist = ref.watch(shortlistDevicesProvider);
    final verdict = ref.watch(verdictProvider);
    final movers = ref.watch(moversProvider);
    final catalog = ref.watch(catalogProvider);
    final loading = catalog is AsyncLoading && !catalog.hasError;

    return TpPage(
      title: K.homeTitle.tr(),
      subtitle: loading || catalog.hasError
          ? null
          : _subtitle(shortlist.length),
      tab: TpTab.today,
      onRefresh: () async {
        ref.invalidate(catalogProvider);
        await ref.read(catalogProvider.future);
      },
      // Android 는 질문을 확장 FAB 가 맡는다.
      floating: glass || onAskWhy == null || verdict == null
          ? null
          : FloatingActionButton.extended(
              heroTag: null,
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor: Theme.of(
                context,
              ).colorScheme.onSecondaryContainer,
              onPressed: onAskWhy,
              icon: const Icon(Icons.auto_awesome),
              label: Text(K.askWhy.tr()),
            ),
      actions: <TpBarAction>[
        if (onAsk != null && glass)
          TpBarAction(
            label: K.askTitle.tr(),
            icon: glass ? CupertinoIcons.sparkles : Icons.auto_awesome,
            onTap: onAsk,
          ),
        if (onYou != null)
          TpBarAction(
            label: K.you.tr(),
            icon: glass
                ? CupertinoIcons.person_crop_circle
                : Icons.account_circle_outlined,
            onTap: onYou,
          ),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AnimatedSwitcher(
              duration: context.motion.contentSwap.duration,
              switchInCurve: context.motion.contentSwap.curve,
              switchOutCurve: context.motion.contentSwap.curve,
              child: loading
                  ? const _HomeSkeleton(key: ValueKey<String>('skeleton'))
                  : catalog.hasError
                  ? const TpCatalogError(key: ValueKey<String>('error'))
                  : verdict == null
                  ? _EmptyShortlist(
                      key: const ValueKey<String>('empty'),
                      onAdd: onAdd,
                    )
                  : _VerdictCard(
                      key: ValueKey<String>(verdict.slug),
                      device: verdict,
                      onCompareAll: onCompareAll,
                      onAskWhy: onAskWhy,
                      onWeights: onWeights,
                    ),
            ),
          ),
        ),
        if (shortlist.isNotEmpty)
          SliverToBoxAdapter(
            child: TpGroup(
              header: K.shortlist.tr(),
              big: true,
              headerAction: onAdd == null
                  ? null
                  : _TextButton(label: K.addDevice.tr(), onTap: onAdd!),
              children: <Widget>[
                for (final d in shortlist)
                  _ShortlistRow(
                    key: ValueKey<String>('slot-${d.slug}'),
                    device: d,
                    onTap: onDeviceTap == null
                        ? null
                        : () => onDeviceTap!(d.slug),
                    onCompare: onCompareDevice == null
                        ? null
                        : () => onCompareDevice!(d.slug),
                    onAskWhy: onAskWhy,
                    onRemove: () =>
                        ref.read(shortlistProvider.notifier).remove(d.slug),
                  ),
              ],
            ),
          ),
        if (movers.isNotEmpty)
          SliverToBoxAdapter(
            child: TpGroup(
              header: K.movers.tr(),
              big: true,
              children: <Widget>[
                for (final m in movers) _MoverRow(mover: m, onTap: onMoversTap),
              ],
            ),
          ),
      ],
    );
  }

  static String _subtitle(int count) => switch (count) {
    0 => K.homeSubNone.tr(),
    1 => K.homeSubOne.tr(),
    _ => K.homeSubMany.tr(args: <String>['$count']),
  };
}

class _TextButton extends StatelessWidget {
  const _TextButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = context.sys.accentText;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: TpTappable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: 17, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerdictCard extends ConsumerWidget {
  const _VerdictCard({
    super.key,
    required this.device,
    this.onCompareAll,
    this.onAskWhy,
    this.onWeights,
  });

  final Smartphone device;
  final VoidCallback? onCompareAll;
  final VoidCallback? onAskWhy;
  final VoidCallback? onWeights;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sys = context.sys;
    final type = context.tpText;
    final glass = context.tp.isGlass;
    final weights = ref.watch(weightsProvider);
    final index = TpIndex.of(device.score, weights);
    final reason = _reason(device, index);

    return TpGroup(
      padding: const EdgeInsets.fromLTRB(18, 8, 12, 18),
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    K.verdict.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: sys.label2,
                    ),
                  ),
                ),
                if (onWeights != null && glass)
                  _TextButton(
                    label: K.weights.tr(),
                    icon: glass
                        ? CupertinoIcons.slider_horizontal_3
                        : Icons.tune,
                    onTap: onWeights!,
                  ),
                Semantics(
                  button: true,
                  label: K.share.tr(),
                  excludeSemantics: true,
                  onTap: () => unawaited(_share(ref, index, reason)),
                  child: TpTappable(
                    onTap: () => unawaited(_share(ref, index, reason)),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Icon(
                        context.icons.share,
                        size: 20,
                        color: sys.accentText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          device.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: sys.label,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Semantics(
                        container: true,
                        label: index == null
                            ? K.verdictNoData.tr()
                            : K.a11yIndex.tr(args: <String>[index.toString()]),
                        excludeSemantics: true,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.3,
                          child: Text(
                            index?.toString() ?? DeviceSpecs.empty,
                            style: type.indexNumeral.copyWith(
                              fontSize: 44,
                              color: TpSys.accent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      color: sys.label2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TpScoreStrip(axes: TpIndex.axes(device.score)),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TpPill(
                          label: K.compareAll.tr(),
                          height: 44,
                          onTap: onCompareAll,
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Android 는 질문이 FAB 로 빠지고 그 자리에 가중치.
                      Expanded(
                        child: glass
                            ? TpPill(
                                label: K.askWhy.tr(),
                                kind: TpPillKind.tinted,
                                height: 44,
                                icon: CupertinoIcons.sparkles,
                                onTap: onAskWhy,
                              )
                            : TpPill(
                                label: K.weights.tr(),
                                kind: TpPillKind.tinted,
                                height: 44,
                                icon: Icons.tune,
                                onTap: onWeights,
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _share(WidgetRef ref, int? index, String reason) async {
    TpAnalytics.shared('verdict');
    try {
      await ref
          .read(shareServiceProvider)
          .shareText(
            ShareText.verdict(
              name: device.name,
              index: index,
              reason: reason,
              slug: device.slug,
            ),
            subject: ShareText.subject(device.name),
          );
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'share.verdict');
    }
  }

  static String _reason(Smartphone device, int? index) {
    final scored = TpIndex.axes(device.score).where((a) => a.hasData).toList()
      ..sort((a, b) => b.score!.compareTo(a.score!));
    if (index == null || scored.isEmpty) {
      return K.verdictNoData.tr();
    }
    final label = SpecLabels.axis(scored.first.kind);
    return K.verdictReason.tr(args: <String>[label.toLowerCase()]);
  }
}

class _EmptyShortlist extends StatelessWidget {
  const _EmptyShortlist({super.key, this.onAdd});

  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return TpGroup(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              K.emptyShortlist.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: sys.label,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              K.emptyShortlistBody.tr(),
              style: TextStyle(fontSize: 15, height: 1.4, color: sys.label2),
            ),
            const SizedBox(height: 14),
            TpPill(
              label: K.emptyShortlistCta.tr(),
              height: 44,
              expand: false,
              icon: context.tp.isGlass ? CupertinoIcons.add : Icons.add,
              onTap: onAdd,
            ),
          ],
        ),
      ],
    );
  }
}

class _ShortlistRow extends ConsumerWidget {
  const _ShortlistRow({
    super.key,
    required this.device,
    this.onTap,
    this.onCompare,
    this.onAskWhy,
    this.onRemove,
  });

  final Smartphone device;
  final VoidCallback? onTap;
  final VoidCallback? onCompare;
  final VoidCallback? onAskWhy;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sys = context.sys;
    final money = ref.watch(moneyProvider);
    final index = TpIndex.of(device.score, ref.watch(weightsProvider));
    final glass = context.tp.isGlass;

    final row = TpRow(
      title: device.name,
      subtitle: <String>[
        money.format(device.msrpUsd),
        if (device.soc?.name != null) device.soc!.name,
      ].join(' · '),
      value: index?.toString() ?? DeviceSpecs.empty,
      valueStyle: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: sys.label,
      ),
      onTap: onTap,
      semanticsLabel: <String>[
        device.name,
        if (index != null) K.a11yIndex.tr(args: <String>['$index']),
      ].join(', '),
    );

    final swipeable = Dismissible(
      key: ValueKey<String>('shortlist-${device.slug}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove?.call(),
      onUpdate: (d) {
        if (d.reached && !d.previousReached) TpHaptics.impact();
      },
      background: ColoredBox(
        color: sys.destructive,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(end: 20),
            child: Text(
              K.remove.tr(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
      child: ColoredBox(color: sys.cell, child: row),
    );

    if (!glass) return swipeable;

    // 길게 누르면 iOS 컨텍스트 메뉴. 지우기는 메뉴 안에서, 빨간 글자로.
    return CupertinoContextMenu.builder(
      enableHapticFeedback: true,
      actions: <Widget>[
        if (onCompare != null)
          CupertinoContextMenuAction(
            trailingIcon: CupertinoIcons.arrow_right_arrow_left,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              onCompare!();
            },
            child: Text(K.compareButton.tr()),
          ),
        if (onAskWhy != null)
          CupertinoContextMenuAction(
            trailingIcon: CupertinoIcons.sparkles,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              onAskWhy!();
            },
            child: Text(K.askWhy.tr()),
          ),
        CupertinoContextMenuAction(
          isDestructiveAction: true,
          trailingIcon: CupertinoIcons.delete,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            onRemove?.call();
          },
          child: Text(K.removeShort.tr()),
        ),
      ],
      builder: (context, animation) => animation.value > 0
          ? FittedBox(
              fit: BoxFit.scaleDown,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TpGroup.radius),
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width - 32,
                  child: Material(color: sys.cell, child: row),
                ),
              ),
            )
          : swipeable,
    );
  }
}

class _MoverRow extends StatelessWidget {
  const _MoverRow({required this.mover, this.onTap});

  final Mover mover;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    return TpRow(
      title: mover.name,
      leading: SizedBox(
        width: 28,
        child: Text(
          '${mover.position}',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: sys.label2),
        ),
      ),
      value: '${mover.isUp ? '▲' : '▼'}${mover.delta.abs()}',
      valueStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: mover.isUp ? sys.accentText : sys.label2,
      ),
      chevron: false,
      onTap: onTap,
      semanticsLabel: (mover.isUp ? K.a11yMoverRow : K.a11yMoverDown).tr(
        args: <String>['${mover.position}', mover.name, '${mover.delta.abs()}'],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: <Widget>[
        for (final height in <double>[260, 60, 60, 60])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: height,
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
