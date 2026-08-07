import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/movers.dart';
import '../../domain/model/tp_index.dart';
import '../../shared/widgets/tp_score_strip.dart';
import '../../shared/widgets/tp_surface.dart';

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
    final shortlist = ref.watch(shortlistDevicesProvider);
    final verdict = ref.watch(verdictProvider);
    final movers = ref.watch(moversProvider);

    return TpShell(
      // Android 는 large app bar 가 제목을 갖고, iOS 는 콘텐츠 안 큰 제목이
      // 그 역할을 한다. 둘 다 그리면 같은 글자가 두 번 나온다.
      title: t.isGlass ? null : K.homeTitle.tr(),
      tab: TpTab.home,
      onTabSelected: onTabSelected,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          // iOS 는 큰 제목이 콘텐츠 안에 있고, Android 는 large app bar 가
          // 가져간다. 부제는 두 경우 모두 콘텐츠에 남는다.
          if (t.isGlass) ...<Widget>[
            Text(K.homeTitle.tr(), style: type.largeTitle),
            const SizedBox(height: 6),
          ],
          Text(_subtitle(shortlist.length), style: type.secondary),
          const SizedBox(height: 16),

          if (verdict == null)
            _EmptyShortlist(onAdd: onAdd)
          else
            _VerdictCard(
              device: verdict,
              onCompareAll: onCompareAll,
              onAskWhy: onAskWhy,
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
                device: d,
                onTap: onDeviceTap == null ? null : () => onDeviceTap!(d.slug),
                onRemove: () =>
                    ref.read(shortlistProvider.notifier).remove(d.slug),
              ),
          ],

          if (movers.isNotEmpty) ...<Widget>[
            const SizedBox(height: 22),
            _SectionHeader(title: K.movers.tr()),
            const SizedBox(height: 8),
            for (final m in movers)
              _MoverRow(mover: m, onTap: onMoversTap),
          ],
        ],
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
  const _VerdictCard({required this.device, this.onCompareAll, this.onAskWhy});

  final Smartphone device;
  final VoidCallback? onCompareAll;
  final VoidCallback? onAskWhy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tp;
    final type = context.tpText;
    final weights = ref.watch(weightsProvider);
    final index = TpIndex.of(device.score, weights);

    return TpSurface(
      strong: true,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(K.verdict.tr().toUpperCase(), style: type.eyebrow),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                index?.toString() ?? DeviceSpecs.empty,
                style: type.indexNumeral,
                maxLines: 1,
                softWrap: false,
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(K.tpIndex.tr(), style: type.secondary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(_reason(device, index), style: type.body),
          const SizedBox(height: 14),
          TpScoreStrip(axes: TpIndex.axes(device.score)),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Expanded(
                child: _CardButton(
                  label: K.compareAll.tr(),
                  filled: true,
                  onTap: onCompareAll,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CardButton(
                  label: K.askWhy.tr(),
                  filled: false,
                  onTap: onAskWhy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
  const _EmptyShortlist({this.onAdd});

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
          Text(
            K.emptyShortlistBody.tr(),
            style: type.secondary,
          ),
          const SizedBox(height: 14),
          _CardButton(label: K.emptyShortlistCta.tr(), filled: true, onTap: onAdd),
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
          GestureDetector(
            onTap: onAction,
            child: Text(
              action!,
              style: type.body.copyWith(color: TpTokens.blue),
            ),
          ),
      ],
    );
  }
}

class _ShortlistRow extends StatelessWidget {
  const _ShortlistRow({required this.device, this.onTap, this.onRemove});

  final Smartphone device;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final index = TpIndex.of(device.score);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey<String>('shortlist-${device.slug}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove?.call(),
        background: const SizedBox.shrink(),
        child: TpSurface(
          onTap: onTap,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 52,
                child: Text(
                  index?.toString() ?? DeviceSpecs.empty,
                  maxLines: 1,
                  softWrap: false,
                  style: type.cardTitle.copyWith(
                    fontSize: 34,
                    fontWeight:
                        t.isGlass ? FontWeight.w700 : FontWeight.w500,
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
                    _FadedSpecLine(
                      text: <String>[
                        DeviceSpecs.formatPrice(device.msrpUsd),
                        if (device.soc?.name != null) device.soc!.name,
                      ].join('  ·  '),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 오른쪽 끝이 배경으로 사라지는 한 줄.
class _FadedSpecLine extends StatelessWidget {
  const _FadedSpecLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    return SizedBox(
      height: 18,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: <Color>[Colors.black, Colors.black, Colors.transparent],
          stops: <double>[0, 0.85, 1],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: Text(
          text,
          style: type.caption,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
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
    final color = mover.isUp ? TpTokens.blue : TpTokens.graphite;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TpSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 30,
              child: Text('${mover.position}', style: type.cardTitle),
            ),
            Expanded(
              child: Text(
                mover.name,
                style: type.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${mover.isUp ? '▲' : '▼'}${mover.delta.abs()}',
              maxLines: 1,
              softWrap: false,
              style: type.body.copyWith(
                color: color,
                fontWeight: context.tp.boldWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.filled, this.onTap});

  final String label;
  final bool filled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? TpTokens.blue : t.chipBg,
          borderRadius: BorderRadius.circular(
            t.isGlass ? TpTokens.rControl : t.rInner,
          ),
          boxShadow: filled ? t.buttonShadow : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: type.body.copyWith(
            fontWeight: t.boldWeight,
            color: filled ? Colors.white : TpTokens.ink,
          ),
        ),
      ),
    );
  }
}
