import 'dart:async' show Timer, unawaited;

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
import '../../shared/coach/tp_coach.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_score_strip.dart';
import '../share/share_text.dart';
import '../../shared/tp_haptics.dart';
import '../../shared/widgets/tp_number.dart';
import '../../shared/figures/tp_figure.dart';
import '../../shared/figures/tp_figures.dart';
import '../../shared/widgets/tp_shimmer.dart';
import '../../shared/widgets/tp_surface.dart';

/// 오늘. 관심 목록과 그 결론.
class HomeScreen extends ConsumerStatefulWidget {
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

  /// 지운 뒤 되돌리기가 떠 있는 시간.
  static const Duration undoHold = Duration(seconds: 4);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();

  static String _subtitle(int count) => switch (count) {
    0 => K.homeSubNone.tr(),
    1 => K.homeSubOne.tr(),
    _ => K.homeSubMany.tr(args: <String>['$count']),
  };
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  /// 방금 지운 기기와 원래 자리. 되돌리기가 이걸 다시 넣는다.
  ({String slug, String name, int at, int seq})? _removed;
  Timer? _undoTimer;
  int _seq = 0;

  ValueChanged<String>? get onDeviceTap => widget.onDeviceTap;
  VoidCallback? get onAdd => widget.onAdd;
  VoidCallback? get onCompareAll => widget.onCompareAll;
  VoidCallback? get onAskWhy => widget.onAskWhy;
  VoidCallback? get onAsk => widget.onAsk;
  VoidCallback? get onMoversTap => widget.onMoversTap;
  VoidCallback? get onYou => widget.onYou;
  VoidCallback? get onWeights => widget.onWeights;
  ValueChanged<String>? get onCompareDevice => widget.onCompareDevice;

  @override
  void dispose() {
    _undoTimer?.cancel();
    super.dispose();
  }

  void _remove(Smartphone device) {
    final at = ref.read(shortlistProvider).indexOf(device.slug);
    ref.read(shortlistProvider.notifier).remove(device.slug);
    _undoTimer?.cancel();
    setState(
      () => _removed = (
        slug: device.slug,
        name: device.name,
        at: at,
        seq: ++_seq,
      ),
    );
    _undoTimer = Timer(HomeScreen.undoHold, () {
      if (mounted) setState(() => _removed = null);
    });
  }

  void _undo() {
    final r = _removed;
    if (r == null) return;
    _undoTimer?.cancel();
    TpHaptics.selection();
    ref.read(shortlistProvider.notifier).insert(r.at, r.slug);
    setState(() => _removed = null);
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.tp.isGlass;
    final shortlist = ref.watch(shortlistDevicesProvider);
    final verdict = ref.watch(verdictProvider);
    final movers = ref.watch(moversProvider);
    final catalog = ref.watch(catalogProvider);
    final loading = catalog is AsyncLoading && !catalog.hasError;
    // 지난 순위가 없으면(첫 실행) 변동을 지어내지 않고 다음부터 보인다고 말한다.
    final firstRun =
        movers.isEmpty &&
        !loading &&
        !catalog.hasError &&
        ref.watch(rankSnapshotProvider).isEmpty;
    final removed = _removed;

    return TpPage(
      title: K.homeTitle.tr(),
      subtitle: loading || catalog.hasError
          ? null
          : HomeScreen._subtitle(shortlist.length),
      tab: TpTab.today,
      floating: removed == null
          ? null
          : _UndoToast(
              key: ValueKey<int>(removed.seq),
              message: K.shortlistRemoved.tr(args: <String>[removed.name]),
              onUndo: _undo,
            ),
      // 불러오는 중엔 비워 둔다. 결론 카드가 뜨기 전에 안내가 시작되면 앞의
      // 두 단계를 건너뛴다(시뮬레이터에서 1/3 으로 떴다).
      coach: loading
          ? const <TpCoachStep>[]
          : <TpCoachStep>[
              if (verdict != null) ...const <TpCoachStep>[
                TpCoachStep(
                  target: 'verdict',
                  title: K.coachVerdict,
                  body: K.coachVerdictBody,
                ),
                TpCoachStep(
                  target: 'weights',
                  title: K.coachWeights,
                  body: K.coachWeightsBody,
                ),
              ],
              const TpCoachStep(
                target: 'ask',
                title: K.coachAsk,
                body: K.coachAskBody,
              ),
              const TpCoachStep(
                target: 'you',
                title: K.coachYou,
                body: K.coachYouBody,
              ),
              const TpCoachStep(
                target: 'search',
                title: K.coachSearch,
                body: K.coachSearchBody,
              ),
            ],
      onRefresh: () async {
        ref.invalidate(catalogProvider);
        await ref.read(catalogProvider.future);
      },
      actions: <TpBarAction>[
        if (onAsk != null)
          TpBarAction(
            label: K.askTitle.tr(),
            icon: glass ? CupertinoIcons.sparkles : Icons.auto_awesome,
            symbol: 'sparkles',
            coach: 'ask',
            onTap: onAsk,
          ),
        if (onYou != null)
          TpBarAction(
            label: K.you.tr(),
            icon: glass
                ? CupertinoIcons.person_crop_circle
                : Icons.account_circle_outlined,
            symbol: 'person.crop.circle',
            coach: 'you',
            onTap: onYou,
          ),
      ],
      slivers: <Widget>[
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TpCoachTarget(
              id: 'verdict',
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
                    // 판정 기기가 바뀌어도 카드는 그대로 두고 안의 값만 움직인다.
                    : _VerdictCard(
                        key: const ValueKey<String>('verdict'),
                        device: verdict,
                        onCompareAll: onCompareAll,
                        onAskWhy: onAskWhy,
                        onWeights: onWeights,
                      ),
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
                    onRemove: () => _remove(d),
                  ),
              ],
            ),
          ),
        if (movers.isNotEmpty || firstRun)
          SliverToBoxAdapter(
            child: TpGroup(
              header: K.movers.tr(),
              big: true,
              children: <Widget>[
                for (final m in movers) _MoverRow(mover: m, onTap: onMoversTap),
                if (firstRun) const _MoversLater(),
              ],
            ),
          ),
      ],
    );
  }
}

/// 첫 실행의 변동 자리. 비교할 지난 순위가 아직 없다.
class _MoversLater extends StatelessWidget {
  const _MoversLater();

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minHeight: 48),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.tp.isGlass ? 16 : 0,
        vertical: 12,
      ),
      child: Text(
        K.moversFirstRun.tr(),
        style: TextStyle(fontSize: 15, height: 1.33, color: context.sys.label2),
      ),
    ),
  );
}

/// 지운 뒤 잠깐 뜨는 되돌리기. iOS 는 유리 캡슐 토스트, Android 는 M3 스낵바.
///
/// 문구 하나("{} 지움 · 되돌리기")의 마지막 조각이 버튼이다.
class _UndoToast extends StatelessWidget {
  const _UndoToast({super.key, required this.message, required this.onUndo});

  final String message;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final cut = message.lastIndexOf(' · ');
    final text = cut < 0 ? message : message.substring(0, cut);
    final action = cut < 0 ? K.reset.tr() : message.substring(cut + 3);
    final scheme = Theme.of(context).colorScheme;
    final fg = glass ? sys.label : scheme.onInverseSurface;
    final button = Semantics(
      button: true,
      label: action,
      excludeSemantics: true,
      onTap: onUndo,
      child: TpTappable(
        onTap: onUndo,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: glass ? 44 : 48,
            minWidth: glass ? 44 : 48,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              widthFactor: 1,
              child: Text(
                action,
                style: TextStyle(
                  fontSize: glass ? 15 : 14,
                  fontWeight: glass ? FontWeight.w600 : FontWeight.w500,
                  color: glass ? sys.accentText : scheme.inversePrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final row = Row(
      mainAxisSize: glass ? MainAxisSize.min : MainAxisSize.max,
      children: <Widget>[
        Flexible(
          fit: glass ? FlexFit.loose : FlexFit.tight,
          child: Padding(
            padding: EdgeInsetsDirectional.only(start: glass ? 20 : 16),
            child: Semantics(
              liveRegion: true,
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: glass ? 15 : 14, color: fg),
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.only(end: glass ? 6 : 4),
          child: button,
        ),
      ],
    );
    final face = glass
        ? ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: TpSurface.chrome(radius: 25, child: row),
          )
        : SizedBox(
            width: double.infinity,
            child: Material(
              color: scheme.inverseSurface,
              elevation: 3,
              borderRadius: BorderRadius.circular(4),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: row,
              ),
            ),
          );
    final move = context.motion.contentSwap;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: move.duration,
      curve: move.curve,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 12),
          child: child,
        ),
      ),
      child: face,
    );
  }
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

    const inset = EdgeInsets.fromLTRB(18, 8, 12, 18);
    final card = Column(
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
              TpCoachTarget(
                id: 'weights',
                child: _TextButton(
                  label: K.weights.tr(),
                  icon: glass ? CupertinoIcons.slider_horizontal_3 : Icons.tune,
                  onTap: onWeights!,
                ),
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
                    child: AnimatedSwitcher(
                      duration: context.motion.contentSwap.duration,
                      switchInCurve: context.motion.contentSwap.curve,
                      switchOutCurve: context.motion.contentSwap.curve,
                      layoutBuilder: (current, previous) => Stack(
                        alignment: AlignmentDirectional.centerStart,
                        children: <Widget>[...previous, ?current],
                      ),
                      child: Text(
                        device.name,
                        key: ValueKey<String>(device.slug),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: sys.label,
                        ),
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
                      child: TpNumber(
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
                style: TextStyle(fontSize: 15, height: 1.35, color: sys.label2),
              ),
              const SizedBox(height: 14),
              TpScoreStrip(axes: TpIndex.axes(device.score)),
              const SizedBox(height: 8),
              // 질문은 툴바의 반짝이 버튼이 맡는다. 여기에는 비교와(Android 는)
              // 가중치만.
              Row(
                children: <Widget>[
                  Expanded(
                    child: TpPill(
                      label: K.compareAll.tr(),
                      height: 44,
                      onTap: onCompareAll,
                    ),
                  ),
                  if (!glass) ...<Widget>[
                    const SizedBox(width: 10),
                    Expanded(
                      child: TpCoachTarget(
                        id: 'weights',
                        child: TpPill(
                          label: K.weights.tr(),
                          kind: TpPillKind.tinted,
                          height: 44,
                          icon: Icons.tune,
                          onTap: onWeights,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
    // Android 는 M3 채운 카드. 배경과 같은 평면이면 결론이 어디까지인지 안 보인다.
    return TpGroup(
      padding: glass ? inset : null,
      children: <Widget>[
        if (glass)
          card
        else
          Container(
            padding: inset,
            decoration: BoxDecoration(
              color: sys.cell,
              borderRadius: BorderRadius.circular(12),
            ),
            child: card,
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
            const TpFigure(height: 84, paint: TpFigures.shortlist),
            const SizedBox(height: 14),
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

/// 접히고 나서 빠지는 행. [builder] 가 받은 함수를 부르면 접기 시작한다.
class _Collapsing extends StatefulWidget {
  const _Collapsing({required this.builder, this.onRemoved});

  final Widget Function(BuildContext context, VoidCallback collapse) builder;
  final VoidCallback? onRemoved;

  @override
  State<_Collapsing> createState() => _CollapsingState();
}

class _CollapsingState extends State<_Collapsing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    value: 1,
  );

  Future<void> _collapse() async {
    final move = context.motion.listItem;
    if (move.duration > Duration.zero) {
      await _c.animateTo(0, duration: move.duration, curve: move.curve);
    }
    if (mounted) widget.onRemoved?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizeTransition(
    sizeFactor: _c,
    child: FadeTransition(
      opacity: _c,
      child: widget.builder(context, _collapse),
    ),
  );
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
      numeric: true,
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

    // Android 는 길게 누르면 M3 메뉴. 행이 눌린 색으로 남고 아래에 뜬다.
    if (!glass) {
      return _Collapsing(
        onRemoved: onRemove,
        builder: (context, collapse) => MenuAnchor(
          alignmentOffset: const Offset(16, 0),
          menuChildren: <Widget>[
            if (onCompare != null)
              MenuItemButton(
                leadingIcon: const Icon(Icons.compare_arrows),
                onPressed: onCompare,
                child: Text(K.compareButton.tr()),
              ),
            MenuItemButton(
              leadingIcon: Icon(Icons.delete_outline, color: sys.destructive),
              onPressed: collapse,
              child: Text(
                K.removeShort.tr(),
                style: TextStyle(color: sys.destructive),
              ),
            ),
          ],
          builder: (context, controller, _) => GestureDetector(
            onLongPress: () {
              TpHaptics.impact();
              controller.open();
            },
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                color: controller.isOpen
                    ? sys.label.withValues(alpha: .1)
                    : Colors.transparent,
              ),
              child: swipeable,
            ),
          ),
        ),
      );
    }

    // 길게 누르면 iOS 컨텍스트 메뉴. 지우기는 메뉴 안에서, 빨간 글자로.
    // 메뉴로 지우면 행이 접힌 뒤에 빠진다. 밀어서 지우기는 Dismissible 이 접는다.
    return _Collapsing(
      onRemoved: onRemove,
      builder: (context, collapse) => CupertinoContextMenu.builder(
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
          CupertinoContextMenuAction(
            isDestructiveAction: true,
            trailingIcon: CupertinoIcons.delete,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop();
              collapse();
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
      ),
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
    child: TpShimmer(
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
    ),
  );
}
