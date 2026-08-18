import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/dto/score.dart';
import '../../data/dto/smartphone.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_index.dart';
import '../../domain/model/tp_weights.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_bar.dart';
import '../../shared/widgets/tp_button.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_surface.dart';

/// [style] 로 [lines] 줄이 차지하는 높이.
///
/// 상수로 잡으면 안 된다. 열 머리가 `SizedBox(height: 44)` 였는데, 손쉬운
/// 사용에서 글자를 1.6배로 키우면 17pt 두 줄이 54pt 라 상자를 넘어 아래
/// 캡션 위를 덮었다. 넘침 **예외**는 안 나서 테스트도 조용했다.
double _lines(BuildContext context, TextStyle style, int lines) =>
    MediaQuery.textScalerOf(context).scale(style.fontSize!) *
    (style.height ?? 1.25) *
    lines;

/// 비교. 두 기기를 한 표에 놓고 줄마다 이긴 쪽을 표시한다.
///
/// v1 은 레이더 차트 하나로 이걸 대신했다. 축 다섯 개를 겹쳐 그리면 어느
/// 쪽이 무엇에서 이겼는지 읽히지 않는다.
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

  /// 바닥에 붙인 버튼이 먹는 자리. 목록 패딩에 더해 마지막 줄이 안 숨는다.
  static const double _actionBand = 68;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);
    final slots = ref.watch(compareProvider);
    final pairs = ref.watch(comparisonProvider);
    final weights = ref.watch(weightsProvider);

    Smartphone? find(String? slug) {
      final devices = catalog.value?.smartphones;
      if (devices == null || slug == null) return null;
      final hit = devices.where((d) => d.slug == slug);
      return hit.isEmpty ? null : hit.first;
    }

    final a = find(slots.a);
    final b = find(slots.b);

    // 슬롯은 카탈로그가 온 뒤에 지수 1·2위로 채워진다. 그때까지를 "안 고른
    // 것"으로 그리면 앱을 켤 때마다 "두 대를 고르세요"가 한 번 번쩍인다.
    final loading = catalog is AsyncLoading && !catalog.hasError;

    return TpShell(
      title: K.compareTitle.tr(),
      tab: TpTab.compare,
      onTabSelected: onTabSelected,
      child: Builder(
        // 셸의 인셋은 이 자리 아래에 있다. 화면 build 에서 바로 읽으면
        // 크롬이 차지한 자리를 모르는 예전 값이 나온다.
        builder: (context) {
          final type = context.tpText;
          final motion = context.motion;
          final inset = tpContentInset(context);
          final showAction = pairs.isNotEmpty;

          return Stack(
            children: <Widget>[
              ListView(
                padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 24) +
                    inset +
                    EdgeInsets.only(bottom: showAction ? _actionBand : 0),
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: _ColumnHead(
                          device: a,
                          weights: weights,
                          onTap: onPick == null
                              ? null
                              : () => onPick!(CompareSide.a),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ColumnHead(
                          device: b,
                          weights: weights,
                          onTap: onPick == null
                              ? null
                              : () => onPick!(CompareSide.b),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // 스켈레톤에서 표로 하드컷이면 화면이 튄다. 랭킹과 같은 갈래다.
                  AnimatedSwitcher(
                    duration: motion.contentSwap.duration,
                    switchInCurve: motion.contentSwap.curve,
                    switchOutCurve: motion.contentSwap.curve,
                    child: loading
                        ? const _TableSkeleton(key: ValueKey<String>('skeleton'))
                        // 못 읽은 것과 안 고른 것은 다른 일이다. 카탈로그가
                        // 없으면 고를 수도 없으니 "두 대를 고르세요"는 막다른
                        // 안내가 된다.
                        : catalog.hasError
                        ? const TpCatalogError(key: ValueKey<String>('error'))
                        : pairs.isEmpty
                        ? TpSurface(
                            key: const ValueKey<String>('empty'),
                            padding: const EdgeInsets.all(20),
                            child: Text(K.chooseTwo.tr(), style: type.body),
                          )
                        : _CompareTable(
                            key: const ValueKey<String>('table'),
                            pairs: pairs,
                            nameA: a?.name ?? '',
                            nameB: b?.name ?? '',
                            scoreA: a?.score,
                            scoreB: b?.score,
                          ),
                  ),
                ],
              ),

              // 이 화면의 유일한 행동인데 열 줄짜리 표 **아래**에 있었다.
              // 402×874 에서는 스크롤해야 나왔다. 크롬 바로 위에 붙인다.
              if (showAction)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: inset.bottom + 8,
                  child: TpButton(label: K.askWhy.tr(), onTap: onAskWhy),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ColumnHead extends StatelessWidget {
  const _ColumnHead({required this.device, required this.weights, this.onTap});

  final Smartphone? device;
  final TpWeights weights;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;
    // 이름은 한 줄일 수도 두 줄일 수도 있다. 두 줄 자리를 늘 비워 두면 두
    // 머리의 높이가 저절로 맞는다 — IntrinsicHeight 로 재지 않아도 된다.
    // (유리 표면은 플랫폼 뷰라 자기 높이를 못 재준다.)
    final nameStyle = type.cardTitle.copyWith(height: 1.25);
    final index = device == null ? null : TpIndex.of(device!.score, weights);

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
            // softWrap 이 false 면 기본이 clip 이라 글리프 한가운데서 잘린다.
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: _lines(context, nameStyle, 2),
            ),
            child: Text(
              device?.name ?? K.choose.tr(),
              style: nameStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          // 지수 숫자에 `TP Index` 캡션을 달지 않는다. 표 첫 줄이 이미 그
          // 라벨을 쓰고 있어서 같은 글자가 화면에 둘이 된다.
          //
          // 스크린 리더에도 안 읽힌다 — 표 첫 줄이 두 기기의 지수를 이미
          // 문장으로 읽어준다. 여기 것은 그 값을 눈으로 먼저 보여줄 뿐이다.
          ExcludeSemantics(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                MediaQuery.withClampedTextScaling(
                  // 30px 숫자를 배율 그대로 곱하면 좁은 열에서 두 줄이 된다.
                  maxScaleFactor: 1.3,
                  child: Text(
                    index?.toString() ?? DeviceSpecs.empty,
                    maxLines: 1,
                    softWrap: false,
                    style: type.indexNumeral.copyWith(
                      fontSize: 30,
                      color: index == null ? t.dim : t.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TpBar(fraction: (index ?? 0) / 100, height: 4, radius: 2),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            K.tapToChange.tr(),
            style: type.caption.copyWith(color: t.dim),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _CompareTable extends StatelessWidget {
  const _CompareTable({
    super.key,
    required this.pairs,
    required this.nameA,
    required this.nameB,
    this.scoreA,
    this.scoreB,
  });

  final List<SpecPair> pairs;
  final String nameA;
  final String nameB;
  final SmartphoneScore? scoreA;
  final SmartphoneScore? scoreB;

  @override
  Widget build(BuildContext context) => TpSurface(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Column(
      children: <Widget>[
        for (final (i, pair) in pairs.indexed)
          _CompareRow(
            pair: pair,
            nameA: nameA,
            nameB: nameB,
            scoreA: scoreA,
            scoreB: scoreB,
            // 마지막 줄에도 선을 그으면 카드 안쪽에 선이 하나 떠 있다.
            last: i == pairs.length - 1,
          ),
      ],
    ),
  );
}

/// 한 줄. 이긴 셀만 파란 알약을 두르고 굵기를 올린다.
class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.pair,
    required this.nameA,
    required this.nameB,
    required this.last,
    this.scoreA,
    this.scoreB,
  });

  final SpecPair pair;
  final String nameA;
  final String nameB;
  final bool last;
  final SmartphoneScore? scoreA;
  final SmartphoneScore? scoreB;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final axis = pair.kind.scoreAxis;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: last
          ? null
          : BoxDecoration(border: Border(bottom: BorderSide(color: t.hairline))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            SpecLabels.of(pair.kind),
            style: type.caption,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: _Cell(
                  spec: pair.a,
                  won: pair.winner == CompareSide.a,
                  device: nameA,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Cell(
                  spec: pair.b,
                  won: pair.winner == CompareSide.b,
                  device: nameB,
                ),
              ),
            ],
          ),
          if (axis != null) ...<Widget>[
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Expanded(child: _AxisBar(kind: axis, score: scoreA)),
                const SizedBox(width: 8),
                Expanded(child: _AxisBar(kind: axis, score: scoreB)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 승자를 못 가리는 줄이 대신 까는 점수 막대.
///
/// 축 **이름은 안 그린다.** `axCam`·`axBatt` 는 행 라벨(`detailSpecCamera`·
/// `detailSpecBattery`)과 영어에서도 한국어에서도 같은 문자열이라, 화면에
/// 찍는 순간 같은 글자가 둘이 된다. 이름은 스크린 리더에만 준다.
class _AxisBar extends StatelessWidget {
  const _AxisBar({required this.kind, required this.score});

  final TpAxisKind kind;
  final SmartphoneScore? score;

  @override
  Widget build(BuildContext context) {
    // 축 하나만 쓰지만 목록을 거쳐 가져온다. 따로 매핑을 두면 TpIndex 쪽
    // 축이 바뀔 때 여기만 남는다.
    final axis = TpIndex.axes(score).firstWhere((a) => a.kind == kind);

    return Semantics(
      container: true,
      // 막대만 있으면 못 읽는다. 점수 스트립과 같은 문장을 쓴다.
      label: axis.hasData
          ? K.a11yAxis.tr(
              args: <String>[
                SpecLabels.axis(axis.kind),
                axis.score!.round().toString(),
              ],
            )
          : K.a11yAxisMissing.tr(args: <String>[SpecLabels.axis(axis.kind)]),
      excludeSemantics: true,
      child: TpBar(fraction: axis.fraction),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.spec, required this.won, required this.device});

  final DeviceSpec spec;
  final bool won;

  /// 어느 기기의 값인지. 셀만 읽으면 알 수 없다.
  final String device;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    final motion = context.motion;

    return Semantics(
      container: true,
      // 승패는 색으로만 표시된다. 색을 못 보면 알 수 없으니 읽어준다.
      // 잘린 값이 아니라 **온전한 값**을 읽는다.
      label: (won ? K.a11yWinner : K.a11yCompareCell).tr(
        args: <String>[device, spec.value],
      ),
      excludeSemantics: true,
      // 값 길이가 제각각이라 행 높이가 한 줄에서 네 줄까지 널뛰었다
      // (`200MP + 50MP + 50MP + 12MP` 는 153pt 폭에서 네 줄이다).
      // 두 줄 자리를 늘 비워 두고 그 이상은 자른다 — 카탈로그에서 두 줄에
      // 안 들어가는 값은 화면 설명의 꼬리뿐이다.
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: _lines(context, type.body, 2)),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          // 목록 안이라 세로가 무한이다. 이게 없으면 Align 이 무한을 채운다.
          heightFactor: 1,
          child: AnimatedContainer(
            duration: motion.valueChange.duration,
            curve: motion.valueChange.curve,
            // 이긴 표시가 셀을 통째로 칠하던 것을 글자에 맞는 알약으로
            // 줄인다. 안드로이드 토큰의 tintFill 은 불투명이라 셀 전체가
            // 파란 덩어리로 앉았다. 색은 그대로 둔다 — 대비가 증명된 짝이다.
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: won ? t.tintFill : Colors.transparent,
              borderRadius: BorderRadius.circular(t.rInner - 8),
            ),
            child: AnimatedDefaultTextStyle(
              duration: motion.valueChange.duration,
              curve: motion.valueChange.curve,
              style: type.body.copyWith(
                fontWeight: won ? t.boldWeight : FontWeight.w400,
                color: spec.hasValue ? t.ink : t.dim,
              ),
              child: Text(
                spec.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TableSkeleton extends StatelessWidget {
  const _TableSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return Column(
      children: <Widget>[
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: t.track,
                borderRadius: BorderRadius.circular(t.rInner),
              ),
            ),
          ),
      ],
    );
  }
}
