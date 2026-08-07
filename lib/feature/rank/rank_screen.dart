import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../domain/model/ranking.dart';
import '../../shared/widgets/tp_chip.dart';
import '../../shared/widgets/tp_surface.dart';

/// 랭킹. v1 의 `RankingCPU/Phone/Laptop.dart` 웹뷰 세 개를 대체한다.
///
/// 그 화면들은 nanoreview.net 을 띄우고 JS 로 헤더를 지웠고, 그 과정에서
/// 필요도 없는 위치 권한을 요청했다. 셋 다 사라진다.
///
/// 카피는 아직 하드코딩이다. 명세에 EN/KO 표가 통째로 있어서 화면마다 조금씩
/// 옮기는 것보다 한 번에 번역 파일로 넘기는 편이 낫다. 그 작업은 따로 한다.
class RankScreen extends ConsumerWidget {
  const RankScreen({
    super.key,
    this.onTabSelected,
    this.onDeviceTap,
    this.onScan,
  });

  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;

  /// 뒷면을 찍어 기기를 찾는다. 명세의 chrome geometry 표대로 Android 는
  /// 확장 FAB, iOS 는 콘텐츠 안 인라인 버튼이다.
  final VoidCallback? onScan;

  static const Map<RankAxis, String> axisLabels = <RankAxis, String>{
    RankAxis.tpIndex: 'TP Index',
    RankAxis.battery: 'Battery',
    RankAxis.camera: 'Camera',
    RankAxis.value: 'Value',
    RankAxis.price: 'Price',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axis = ref.watch(rankAxisProvider);
    final ranked = ref.watch(rankedPhonesProvider);
    final loading = ref.watch(catalogProvider).isLoading;

    return TpShell(
      title: 'Rankings',
      tab: TpTab.rank,
      onTabSelected: onTabSelected,
      floatingAction: onScan == null ? null : _ScanFab(onTap: onScan!),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: <Widget>[
          const _ChipRow(
            labels: <String>['Phones', 'Processors', 'Laptops'],
            // 카탈로그에 폰만 충분히 들어 있다. 나머지 두 카테고리는 화면이
            // 생길 때 연결한다.
            selectedIndex: 0,
          ),
          const SizedBox(height: 14),
          const _EyebrowText('Rank by'),
          const SizedBox(height: 8),
          _ChipRow(
            labels: RankAxis.values.map((a) => axisLabels[a]!).toList(),
            selectedIndex: RankAxis.values.indexOf(axis),
            onSelected: (i) =>
                ref.read(rankAxisProvider.notifier).set(RankAxis.values[i]),
          ),
          const SizedBox(height: 16),
          if (loading)
            const _RowSkeletons()
          else
            _RankList(ranked: ranked, axis: axis, onDeviceTap: onDeviceTap),
          if (onScan != null && context.tp.isGlass) ...<Widget>[
            const SizedBox(height: 16),
            _ScanInlineButton(onTap: onScan!),
          ],
          const SizedBox(height: 18),
          Text(
            'Ranked in-app from the TechPicks dataset — no webview, no handoff.',
            style: context.tpText.caption,
          ),
        ],
      ),
    );
  }
}

class _EyebrowText extends StatelessWidget {
  const _EyebrowText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: context.tpText.eyebrow);
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({
    required this.labels,
    required this.selectedIndex,
    this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => TpChip(
          label: labels[i],
          selected: i == selectedIndex,
          onTap: onSelected == null ? null : () => onSelected!(i),
        ),
      ),
    );
  }
}

/// 순위 목록.
///
/// 축을 바꾸면 행이 새 자리로 220ms 동안 미끄러진다. Flutter 에 목록 재정렬
/// 애니메이션이 없어서 행 높이를 고정하고 [Stack] + [AnimatedPositioned] 로
/// 자리를 옮긴다. 키는 slug 라 같은 기기가 같은 위젯을 유지한다.
class _RankList extends StatelessWidget {
  const _RankList({required this.ranked, required this.axis, this.onDeviceTap});

  static const double rowHeight = 62;

  final List<RankedDevice> ranked;
  final RankAxis axis;
  final ValueChanged<String>? onDeviceTap;

  @override
  Widget build(BuildContext context) {
    if (ranked.isEmpty) {
      return TpSurface(
        padding: const EdgeInsets.all(20),
        child: Text('No devices yet.', style: context.tpText.body),
      );
    }

    return SizedBox(
      height: ranked.length * rowHeight,
      child: Stack(
        children: <Widget>[
          for (final r in ranked)
            AnimatedPositioned(
              key: ValueKey<String>(r.device.slug),
              duration: const Duration(milliseconds: 220),
              curve: const Cubic(.2, .8, .2, 1),
              top: (r.position - 1) * rowHeight,
              left: 0,
              right: 0,
              height: rowHeight,
              child: _RankRow(
                entry: r,
                axis: axis,
                onTap: onDeviceTap == null
                    ? null
                    : () => onDeviceTap!(r.device.slug),
              ),
            ),
        ],
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.entry, required this.axis, this.onTap});

  final RankedDevice entry;
  final RankAxis axis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    // 1–3 위만 파란 숫자.
    final leading = entry.position <= 3 ? TpTokens.blue : TpTokens.graphite;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              // 행 높이가 고정이라 안쪽도 고정한다. 숫자가 두 자리가 되면서
              // 줄바꿈되면 Column 이 넘친다.
              height: 34,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 46,
                    child: Text(
                      '${entry.position}',
                      maxLines: 1,
                      softWrap: false,
                      style: type.cardTitle.copyWith(
                        fontSize: 28,
                        fontWeight: t.isGlass
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: leading,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.device.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: type.cardTitle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatAxisValue(axis, entry.axisValue),
                    maxLines: 1,
                    softWrap: false,
                    style: type.cardTitle.copyWith(
                      color: entry.axisValue == null ? t.dim : TpTokens.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            _Track(fraction: entry.fraction),
          ],
        ),
      ),
    );
  }
}

/// 3px 진행 트랙. 명세의 두께 그대로.
class _Track extends StatelessWidget {
  const _Track({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: t.track,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction,
          child: DecoratedBox(
            decoration: BoxDecoration(gradient: t.barFill),
            child: const SizedBox(height: 3),
          ),
        ),
      ),
    );
  }
}

/// 로딩 중에는 카드 반지름 그대로의 뼈대를 보여준다. 명세가 가운데 스피너를
/// 금지한다 — v1 이 빈 화면에 `CircularProgressIndicator` 를 띄웠다.
class _RowSkeletons extends StatelessWidget {
  const _RowSkeletons();

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    return Column(
      children: <Widget>[
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 52,
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

/// 축에 맞는 표시 형식. 가격만 통화이고 나머지는 0–100 점수다.
String formatAxisValue(RankAxis axis, double? value) {
  if (value == null) return '—';
  if (axis == RankAxis.price) {
    final s = value.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return '\$$buf';
  }
  return value.round().toString();
}


/// Android 확장 FAB.
class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: TpTokens.blue,
          borderRadius: BorderRadius.circular(16),
          boxShadow: TpTokens.fabShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              'Scan',
              style: type.body.copyWith(
                color: Colors.white,
                fontWeight: t.boldWeight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// iOS 는 FAB 가 없다. 콘텐츠 안에 버튼으로 둔다.
class _ScanInlineButton extends StatelessWidget {
  const _ScanInlineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.chipBg,
          borderRadius: BorderRadius.circular(TpTokens.rControl),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.qr_code_scanner, size: 18),
            const SizedBox(width: 8),
            Text(
              'Scan a device',
              style: type.body.copyWith(fontWeight: t.boldWeight),
            ),
          ],
        ),
      ),
    );
  }
}
