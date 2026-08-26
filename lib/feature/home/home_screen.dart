import 'dart:async' show unawaited;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../core/analytics.dart';
import '../../core/error_reporter.dart';
import '../share/share_text.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/movers.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/widgets/tp_score_strip.dart';
import '../../shared/widgets/tp_faded_line.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_button.dart';

/// 홈.
///
/// v1 은 원형 아이콘 8개와 지도 템플릿에서 남은 "Where to?" 검색바였다.
/// 여기는 지금 고르는 중인 기기와 그에 대한 결론을 보여준다.
///
/// 카피는 아직 하드코딩이다.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({
    super.key,
    this.onTabSelected,
    this.onDeviceTap,
    this.onAdd,
    this.onCompareAll,
    this.onAskWhy,
    this.onMoversTap,
  });

  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;
  final VoidCallback? onAdd;
  final VoidCallback? onCompareAll;
  final VoidCallback? onAskWhy;
  final VoidCallback? onMoversTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tp;
    final type = context.tpText;
    final motion = context.motion;
    final shortlist = ref.watch(shortlistDevicesProvider);
    final verdict = ref.watch(verdictProvider);
    final movers = ref.watch(moversProvider);
    final catalog = ref.watch(catalogProvider);
    // 카탈로그가 오기 전에는 관심목록도 결론도 비어 있다. 그걸 "아직 담은 게
    // 없다"로 그리면, 담아둔 사람에게도 켤 때마다 빈 카드가 한 번 번쩍인다.
    final loading = catalog is AsyncLoading && !catalog.hasError;

    return TpShell(
      // Android 는 large app bar 가 제목을 갖고, iOS 는 콘텐츠 안 큰 제목이
      // 그 역할을 한다. 둘 다 그리면 같은 글자가 두 번 나온다.
      title: t.isGlass ? null : K.homeTitle.tr(),
      tab: TpTab.home,
      onTabSelected: onTabSelected,
      child: Builder(
        // 셸의 인셋은 이 자리 아래에 있다. 화면 build 에서 바로 읽으면
        // 크롬이 차지한 자리를 모르는 예전 값이 나온다.
        builder: (context) => ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 24) +
              tpContentInset(context),
          children: <Widget>[
            // iOS 는 큰 제목이 콘텐츠 안에 있고, Android 는 large app bar 가
            // 가져간다. 부제는 두 경우 모두 콘텐츠에 남는다.
            if (t.isGlass) ...<Widget>[
              Text(K.homeTitle.tr(), style: type.largeTitle),
              const SizedBox(height: 6),
            ],
            // 목록을 못 읽었으면 "아직 결정할 것이 없습니다"도 거짓말이다.
            // 읽는 중일 때도 마찬가지다.
            if (!catalog.hasError) ...<Widget>[
              Text(
                loading ? '' : _subtitle(shortlist.length),
                style: type.secondary,
              ),
              const SizedBox(height: 16),
            ],

            // 첫 기기를 담는 순간이 이 앱에서 가장 중요한 상태 변화다.
            // 하드컷으로 갈리면 담긴 걸 놓친다. 페이드만 걸면 높이가 툭 바뀌어
            // 아래 목록이 튀므로 크기도 같이 움직인다.
            AnimatedSize(
              duration: motion.contentSwap.duration,
              curve: motion.contentSwap.curve,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: motion.contentSwap.duration,
                switchInCurve: motion.contentSwap.curve,
                switchOutCurve: motion.contentSwap.curve,
                child: loading
                    ? const _HomeSkeleton(key: ValueKey<String>('skeleton'))
                    : catalog.hasError
                    // 목록을 못 읽은 것을 "관심 목록이 비었다"로 그리면, 담아둔
                    // 기기가 있는 사람에게도 비었다고 말하게 된다.
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
                      ),
              ),
            ),

            if (shortlist.isNotEmpty) ...<Widget>[
              const SizedBox(height: 22),
              _SectionHeader(
                title: K.shortlist.tr(),
                action: K.addDevice.tr(),
                onAction: onAdd,
              ),
              const SizedBox(height: 8),
              for (final d in shortlist)
                _ShortlistRow(
                  key: ValueKey<String>('slot-${d.slug}'),
                  device: d,
                  onTap: onDeviceTap == null
                      ? null
                      : () => onDeviceTap!(d.slug),
                  onRemove: () =>
                      ref.read(shortlistProvider.notifier).remove(d.slug),
                ),
            ],

            if (movers.isNotEmpty) ...<Widget>[
              const SizedBox(height: 22),
              _SectionHeader(title: K.movers.tr()),
              const SizedBox(height: 8),
              for (final m in movers) _MoverRow(mover: m, onTap: onMoversTap),
            ],
          ],
        ),
      ),
    );
  }

  static String _subtitle(int count) => switch (count) {
    0 => K.homeSubNone.tr(),
    1 => K.homeSubOne.tr(),
    _ => K.homeSubMany.tr(args: <String>['$count']),
  };
}

/// 결론 카드. 홈의 주인공이다.
class _VerdictCard extends ConsumerWidget {
  const _VerdictCard({
    super.key,
    required this.device,
    this.onCompareAll,
    this.onAskWhy,
  });

  final Smartphone device;
  final VoidCallback? onCompareAll;
  final VoidCallback? onAskWhy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tp;
    final type = context.tpText;
    final weights = ref.watch(weightsProvider);
    final index = TpIndex.of(device.score, weights);

    final reason = _reason(device, index);

    return TpSurface(
      strong: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(K.verdict.tr().toUpperCase(), style: type.eyebrow),
              ),
              // 명세에 공유 UI 가 없다. 결론 카드가 그대로 공유 문구라서
              // 눈에 띄되 Compare all·Ask why 를 밀어내지 않는 자리에 둔다.
              TpTapTarget(
                onTap: () => unawaited(_share(ref, index, reason)),
                label: K.share.tr(),
                // 44 로 좁혀 뒀는데 안드로이드 탭 타깃 기준은 48 이다. 링크가
                // 아니라 버튼이라 기준에서 빠지지도 않는다.
                child: const Icon(Icons.share, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            device.name,
            style: type.cardTitle.copyWith(
              fontSize: 22,
              fontWeight: t.isGlass ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Semantics(
            container: true,
            // 값이 없으면 대시를 그대로 읽는다. 라벨을 주는 쪽이 낫다.
            label: index == null
                ? K.verdictNoData.tr()
                : K.a11yIndex.tr(args: <String>[index.toString()]),
            excludeSemantics: true,
            // 62pt 숫자에 배율을 그대로 곱하면 1.6배에서 라벨과 합쳐 카드
            // 폭을 넘는다. 상세 화면과 같은 한도를 **줄 전체에** 건다 —
            // 숫자만 묶으면 라벨이 대신 잘린다.
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    index?.toString() ?? DeviceSpecs.empty,
                    style: type.indexNumeral,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(width: 10),
                  // 유연한 자식이 하나도 없어서 넘칠 자리였다.
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        K.tpIndex.tr(),
                        style: type.secondary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(reason, style: type.body),
          const SizedBox(height: 14),
          TpScoreStrip(axes: TpIndex.axes(device.score)),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: TpButton(
                  label: K.compareAll.tr(),
                  height: 46,
                  onTap: onCompareAll,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TpButton(
                  label: K.askWhy.tr(),
                  kind: TpButtonKind.secondary,
                  height: 46,
                  onTap: onAskWhy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 결론을 그대로 보낸다. 화면에 있는 세 줄이 그대로 문구가 된다.
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

  /// 한 문장짜리 근거. 가장 높은 축을 짚어준다.
  ///
  /// 명세는 문장을 확정해두지 않았다. 지수만 던지지 말고 왜 그 점수인지
  /// 한 줄로 설명하라는 요구라서, 데이터에서 뽑을 수 있는 가장 단순한
  /// 형태로 만든다.
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
    final type = context.tpText;
    return TpSurface(
      strong: true,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(K.emptyShortlist.tr(), style: type.cardTitle),
          const SizedBox(height: 6),
          Text(K.emptyShortlistBody.tr(), style: type.secondary),
          const SizedBox(height: 14),
          TpButton(label: K.emptyShortlistCta.tr(), height: 46, onTap: onAdd),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    return Row(
      children: <Widget>[
        Expanded(child: Text(title, style: type.cardTitle)),
        if (action != null)
          TpTapTarget(
            onTap: onAction,
            child: Text(
              action!,
              style: type.body.copyWith(color: context.tp.link),
            ),
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
    this.onRemove,
  });

  final Smartphone device;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tp;
    final type = context.tpText;
    // 결론 카드와 같은 가중치로 센다. 기본값으로 세던 때는 같은 기기가 한
    // 화면에서 85 와 92 로 보였다.
    final index = TpIndex.of(device.score, ref.watch(weightsProvider));

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey<String>('shortlist-${device.slug}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove?.call(),
        background: const SizedBox.shrink(),
        child: TpSurface(
          onTap: onTap,
          // 명세 §3 은 스와이프와 길게 누르기 둘 다 지우기다. 스와이프는
          // 스크린 리더로 못 하니 길게 누르기가 유일한 경로가 된다.
          onLongPress: onRemove,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              // 폭을 52 로 못박아 뒀는데 34pt 두 자리는 68pt 다 — 배율을
              // 올리기도 전에 이미 글리프 한가운데서 잘리고 있었다. 자리는
              // 맞추되(최소 폭) 넘치면 늘어난다.
              // 숫자만 있으면 "72 Galaxy S25 $799 · Dimensity 9500" 으로
              // 읽힌다. 어느 게 지수인지 알 수 없다.
              Semantics(
                label: index == null
                    ? null
                    : K.a11yIndex.tr(args: <String>[index.toString()]),
                excludeSemantics: index != null,
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 52),
                    child: Text(
                      index?.toString() ?? DeviceSpecs.empty,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: type.cardTitle.copyWith(
                        fontSize: 34,
                        fontWeight: t.isGlass
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      device.name,
                      style: type.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // 스펙 줄은 길어지면 오른쪽으로 흐려지며 잘린다.
                    TpFadedLine(
                      text: <String>[
                        DeviceSpecs.formatPrice(device.msrpUsd),
                        if (device.soc?.name != null) device.soc!.name,
                      ].join('  ·  '),
                    ),
                  ],
                ),
              ),
              // 지우는 길이 스와이프와 길게 누르기뿐이었다. 스와이프는 배경이
              // `SizedBox.shrink()` 라 **아무 표시도 없고**, 길게 누르기는
              // 마우스로 알아낼 방법이 없다. 키보드로는 아예 못 지웠다.
              if (onRemove != null)
                TpTapTarget(
                  onTap: onRemove,
                  label: K.remove.tr(),
                  child: Icon(Icons.close, size: 18, color: t.dim),
                ),
            ],
          ),
        ),
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
    final type = context.tpText;
    // 상승은 파랑, 하락은 그래파이트. 명세에 빨강은 없다.
    final color = mover.isUp ? TpTokens.blue : context.tp.mutedInk;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        container: true,
        button: onTap != null,
        // 숫자 둘과 화살표가 따로 읽히면 "10 Galaxy S25 검은색 위쪽 삼각형 2"
        // 가 된다. 글리프는 글자 그대로 읽힌다.
        label: (mover.isUp ? K.a11yMoverRow : K.a11yMoverDown).tr(
          args: <String>[
            '${mover.position}',
            mover.name,
            '${mover.delta.abs()}',
          ],
        ),
        // excludeSemantics 는 안쪽 글자와 함께 탭 액션도 지운다.
        onTap: onTap,
        excludeSemantics: true,
        child: TpSurface(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              // 30pt 상자에 maxLines 도 overflow 도 없었다. 두 자리 순위는
              // 세로로 쪼개져 "1" / "0" 두 줄이 됐다.
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 30),
                child: Text(
                  '${mover.position}',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: type.cardTitle,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  mover.name,
                  style: type.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${mover.isUp ? '▲' : '▼'}${mover.delta.abs()}',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: type.body.copyWith(
                  color: color,
                  fontWeight: context.tp.boldWeight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 카탈로그를 읽는 동안의 뼈대.
///
/// 명세는 로딩을 카드 자기 반지름의 뼈대로 그리라고 했고(가운데 스피너 금지),
/// 랭킹·비교·상세가 다 그렇게 한다. 홈만 없어서, 담아둔 기기가 있는 사람도
/// 켤 때마다 "관심 목록이 비어 있습니다" 를 한 번 보고 지나갔다.
class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return Column(
      children: <Widget>[
        for (final height in <double>[188, 74, 74])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: height,
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
