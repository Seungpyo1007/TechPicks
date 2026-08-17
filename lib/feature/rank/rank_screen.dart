import '../../app/theme/tp_motion.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../shared/copy_keys.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/ranking.dart';
import '../../shared/widgets/tp_bar.dart';
import '../../shared/widgets/tp_chip.dart';
import 'category_chips.dart';
import '../../shared/widgets/tp_search_field.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_button.dart';
import '../../shared/widgets/tp_press.dart';

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

  /// 화면에 그리는 최대 행 수.
  ///
  /// 목록은 `Stack` + `AnimatedPositioned` 라 **모든 행을 한 번에 만든다**.
  /// 순위가 바뀌면 행마다 있는 막대가 동시에 트윈되는데, 카탈로그가 154종이
  /// 되면서 가중치 슬라이더 한 번에 애니메이션이 백 개 넘게 돈다.
  ///
  /// 카탈로그 전체는 비교·픽커·상세·이번 주 변동이 그대로 다 쓴다. 상한은
  /// 이 화면에만 있다.
  static const int maxRows = 50;

  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;

  /// 뒷면을 찍어 기기를 찾는다. 명세의 chrome geometry 표대로 Android 는
  /// 확장 FAB, iOS 는 콘텐츠 안 인라인 버튼이다.
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axis = ref.watch(rankAxisProvider);
    final ranked = ref.watch(rankVisibleProvider);
    final brands = ref.watch(rankBrandsProvider);
    final brand = ref.watch(rankBrandProvider);
    // 실패했을 때도 스켈레톤을 계속 돌리면 영원히 로딩처럼 보인다.
    final catalog = ref.watch(catalogProvider);
    final motion = context.motion;
    final loading = catalog is AsyncLoading && !catalog.hasError;

    return TpShell(
      title: K.rankTitle.tr(),
      tab: TpTab.rank,
      onTabSelected: onTabSelected,
      floatingAction: onScan == null ? null : _ScanFab(onTap: onScan!),
      child: Builder(
        // 셸의 인셋은 이 자리 아래에 있다. 화면 build 에서 바로 읽으면
        // 크롬이 차지한 자리를 모르는 예전 값이 나온다.
        builder: (context) => ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 24) +
              tpContentInset(context),
          children: <Widget>[
            const CategoryChips(),
            const SizedBox(height: 12),
            const _RankSearch(),
            // 브랜드 줄에는 눈썹 글자를 안 붙인다. 검색 · 브랜드 · 정렬이
            // 각자 제목을 달면 목록이 시작되기 전에 화면 절반이 찬다.
            if (brands.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              _BrandChips(brands: brands, selected: brand),
            ],
            const SizedBox(height: 10),
            _EyebrowText(K.rankBy.tr()),
            const SizedBox(height: 8),
            _ChipRow(
              labels: RankAxis.values.map((a) => K.rankAxis(a).tr()).toList(),
              selectedIndex: RankAxis.values.indexOf(axis),
              onSelected: (i) =>
                  ref.read(rankAxisProvider.notifier).set(RankAxis.values[i]),
            ),
            const SizedBox(height: 16),
            // 스켈레톤에서 목록으로 하드컷이면 화면이 튄다.
            AnimatedSwitcher(
              duration: motion.contentSwap.duration,
              switchInCurve: motion.contentSwap.curve,
              switchOutCurve: motion.contentSwap.curve,
              child: loading
                  ? const _RowSkeletons(key: ValueKey<String>('skeleton'))
                  // 못 읽은 것을 "기기가 없다"로 그리면 사용자가 할 수 있는 게
                  // 없다. 다시 시도할 자리를 준다.
                  : catalog.hasError
                  ? const TpCatalogError(key: ValueKey<String>('error'))
                  // 걸러서 아무것도 안 남으면 빈 목록 대신 그렇게 말한다.
                  : ranked.isEmpty
                  ? Padding(
                      key: const ValueKey<String>('empty'),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        K.noMatches.tr(),
                        style: context.tpText.secondary,
                      ),
                    )
                  : _RankList(
                      key: const ValueKey<String>('list'),
                      ranked: ranked.take(maxRows).toList(growable: false),
                      axis: axis,
                      onDeviceTap: onDeviceTap,
                    ),
            ),
            // 잘린 것을 말해준다. 랭킹이 조용히 끊기면 가격순으로 봤을 때
            // 제일 싼 기기가 왜 없는지 알 방법이 없다.
            if (ranked.length > maxRows) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                K.rankCapped.tr(
                  args: <String>['$maxRows', '${ranked.length - maxRows}'],
                ),
                style: context.tpText.caption,
              ),
            ],
            if (onScan != null && context.tp.isGlass) ...<Widget>[
              const SizedBox(height: 16),
              _ScanInlineButton(onTap: onScan!),
            ],
            const SizedBox(height: 18),
            Text(K.rankNote.tr(), style: context.tpText.caption),
          ],
        ),
      ),
    );
  }
}

/// 랭킹의 검색 줄.
///
/// 컨트롤러 하나 때문에 화면 전체를 stateful 로 만들지 않는다. 검색어 자체는
/// 프로바이더에 있어서 화면을 떠났다 와도 남는다.
class _RankSearch extends ConsumerStatefulWidget {
  const _RankSearch();

  @override
  ConsumerState<_RankSearch> createState() => _RankSearchState();
}

class _RankSearchState extends ConsumerState<_RankSearch> {
  late final TextEditingController _query = TextEditingController(
    text: ref.read(rankQueryProvider),
  );

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TpSearchField(
    controller: _query,
    onChanged: (value) {
      ref.read(rankQueryProvider.notifier).set(value);
      // 지우기 버튼이 붙었다 떨어지는 것은 이 위젯이 그린다.
      setState(() {});
    },
  );
}

/// 브랜드 칩 행. 고른 걸 다시 누르면 풀린다.
class _BrandChips extends ConsumerWidget {
  const _BrandChips({required this.brands, required this.selected});

  final List<String> brands;
  final String? selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(rankBrandProvider.notifier);
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: brands.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return TpChip(
              label: K.allBrands.tr(),
              selected: selected == null,
              onTap: selected == null
                  ? null
                  : () => notifier.toggle(selected!),
            );
          }
          final brand = brands[i - 1];
          return TpChip(
            label: brand,
            selected: brand == selected,
            onTap: () => notifier.toggle(brand),
          );
        },
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
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
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
  const _RankList({
    super.key,
    required this.ranked,
    required this.axis,
    this.onDeviceTap,
  });

  static const double rowHeight = 62;

  final List<RankedDevice> ranked;
  final RankAxis axis;
  final ValueChanged<String>? onDeviceTap;

  @override
  Widget build(BuildContext context) {
    if (ranked.isEmpty) {
      return TpSurface(
        padding: const EdgeInsets.all(20),
        child: Text(K.noDevices.tr(), style: context.tpText.body),
      );
    }

    final motion = context.motion;
    return SizedBox(
      height: ranked.length * rowHeight,
      child: Stack(
        children: <Widget>[
          for (final r in ranked)
            AnimatedPositioned(
              key: ValueKey<String>(r.device.slug),
              duration: motion.reorder.duration,
              curve: motion.reorder.curve,
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
    final leading = entry.position <= 3 ? TpTokens.blue : t.mutedInk;

    return Semantics(
      // container 를 켜야 행마다 별개 노드가 된다. 안 켜면 목록 전체가
      // 하나로 합쳐져 스크린 리더가 한 번에 다 읽는다.
      container: true,
      button: onTap != null,
      // 숫자 세 개가 따로 읽히면 어느 게 순위이고 어느 게 점수인지 모른다.
      label: K.a11yRankRow.tr(
        args: <String>[
          '${entry.position}',
          entry.device.name,
          entry.index?.toString() ?? DeviceSpecs.empty,
        ],
      ),
      excludeSemantics: true,
      child: TpPress(
        onTap: onTap,
        semanticsButton: false,
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
                        color: entry.axisValue == null ? t.dim : t.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              TpBar(height: 3, radius: 2, fraction: entry.fraction),
            ],
          ),
        ),
      ),
    );
  }
}

/// 로딩 중에는 카드 반지름 그대로의 뼈대를 보여준다. 명세가 가운데 스피너를
/// 금지한다 — v1 이 빈 화면에 `CircularProgressIndicator` 를 띄웠다.
class _RowSkeletons extends StatelessWidget {
  const _RowSkeletons({super.key});

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
/// Android 확장 FAB. 랭킹에서 기기 찾기로 간다.
class _ScanFab extends StatelessWidget {
  const _ScanFab({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TpButton(
    label: K.scanShort.tr(),
    height: 56,
    expand: false,
    icon: const Icon(Icons.search, color: Colors.white, size: 20),
    onTap: onTap,
  );
}

/// iOS 는 FAB 가 없다. 콘텐츠 안에 버튼으로 둔다.
class _ScanInlineButton extends StatelessWidget {
  const _ScanInlineButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TpButton(
    label: K.scanCta.tr(),
    kind: TpButtonKind.secondary,
    icon: const Icon(Icons.search, size: 18),
    onTap: onTap,
  );
}
