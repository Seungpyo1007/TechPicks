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

  /// 컨트롤 사이 간격. 예전에는 12/10/10/8/16 이 섞여 있었다.
  static const double _gap = 12;

  final ValueChanged<TpTab>? onTabSelected;
  final ValueChanged<String>? onDeviceTap;

  /// 뒷면을 찍어 기기를 찾는다. 명세의 chrome geometry 표대로 Android 는
  /// 확장 FAB, iOS 는 콘텐츠 안 인라인 버튼이다.
  final VoidCallback? onScan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final axis = ref.watch(rankAxisProvider);
    final ranked = ref.watch(rankVisibleProvider);
    // 실패했을 때도 스켈레톤을 계속 돌리면 영원히 로딩처럼 보인다.
    final catalog = ref.watch(catalogProvider);
    final motion = context.motion;
    final loading = catalog is AsyncLoading && !catalog.hasError;
    final hasList = !loading && !catalog.hasError && ranked.isNotEmpty;

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
            const SizedBox(height: _gap),
            // 검색과 브랜드가 한 줄이다. 브랜드가 17개짜리 칩 줄이던 때는
            // 컨트롤만으로 화면 절반이 찼고, 카탈로그가 읽힌 뒤에 그 줄이
            // 생겨나면서 목록이 56pt 씩 아래로 밀렸다.
            const _RankControls(),
            const SizedBox(height: _gap),
            // "정렬 기준" 눈썹은 뺐다. 칩 라벨이 이미 정렬이라고 말한다.
            _ChipRow(
              labels: RankAxis.values.map((a) => K.rankAxis(a).tr()).toList(),
              selectedIndex: RankAxis.values.indexOf(axis),
              onSelected: (i) =>
                  ref.read(rankAxisProvider.notifier).set(RankAxis.values[i]),
            ),
            const SizedBox(height: _gap),
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
              const SizedBox(height: _gap),
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
            // 순위를 어떻게 냈는지는 순위가 있을 때 할 말이다. 오류 화면과
            // "맞는 게 없습니다" 아래에도 붙어 있었다.
            if (hasList) ...<Widget>[
              const SizedBox(height: 18),
              Text(K.rankNote.tr(), style: context.tpText.caption),
            ],
          ],
        ),
      ),
    );
  }
}

/// 검색 줄과 브랜드 칩. 한 줄이다.
class _RankControls extends StatelessWidget {
  const _RankControls();

  @override
  Widget build(BuildContext context) => Row(
    children: const <Widget>[
      Expanded(child: _RankSearch()),
      SizedBox(width: 8),
      // 검색 줄과 같은 높이로 늘린다. 칩이 자기 크기(44)로 서면 옆의 48짜리
      // 입력칸과 어긋나고, 누르는 자리도 접근성 기준(48)에 모자란다.
      SizedBox(height: TpSearchField.height, child: _BrandChip()),
    ],
  );
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

/// 브랜드 하나짜리 칩. 누르면 시트가 열린다.
///
/// 열일곱 개를 가로로 늘어놓던 줄을 접은 것이다. 그 줄은 세로로 46pt 를
/// 먹으면서도 화면에 세 개밖에 안 보였고, 나머지는 옆으로 밀어야 나왔다.
class _BrandChip extends ConsumerWidget {
  const _BrandChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brands = ref.watch(rankBrandsProvider);
    final selected = ref.watch(rankBrandProvider);

    return TpChip(
      label: selected ?? K.brand.tr(),
      selected: selected != null,
      // 카탈로그를 읽기 전에도 자리는 잡아둔다. 없다가 생기면 목록이 밀린다.
      onTap: brands.isEmpty
          ? null
          : () => _pickBrand(context, ref, brands, selected),
    );
  }
}

/// 브랜드 시트. 설정의 언어·AI 엔진 시트와 같은 모양이다.
Future<void> _pickBrand(
  BuildContext context,
  WidgetRef ref,
  List<String> brands,
  String? current,
) async {
  final type = context.tpText;
  final t = context.tp;
  // 열일곱 개가 넘어서 시트가 화면을 넘는다.
  final maxHeight = MediaQuery.sizeOf(context).height * 0.6;

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => TpSurface(
      strong: true,
      // 랭킹 오십 줄 위에 뜬다. 비치면 못 읽는다.
      opaque: true,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(K.brand.tr(), style: type.cardTitle),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                for (final option in <String?>[null, ...brands])
                  TpPress(
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ref.read(rankBrandProvider.notifier).set(option);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              option ?? K.allBrands.tr(),
                              style: type.body,
                            ),
                          ),
                          if (option == current)
                            Icon(Icons.check, size: 18, color: t.link)
                          else
                            const SizedBox(width: 18, height: 18),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
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

  final List<RankedDevice> ranked;
  final RankAxis axis;
  final ValueChanged<String>? onDeviceTap;

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;
    final rowHeight = _RankRow.heightOf(context);

    return SizedBox(
      height: ranked.length * rowHeight,
      child: Stack(
        children: <Widget>[
          for (final (i, r) in ranked.indexed)
            AnimatedPositioned(
              key: ValueKey<String>(r.device.slug),
              duration: motion.reorder.duration,
              curve: motion.reorder.curve,
              // **보이는 목록에서의 자리**에 놓는다. 전역 순위로 놓으면 필터를
              // 켠 순간 행 사이가 순위 차이만큼 벌어지고, 담는 상자보다 아래로
              // 나간 기기는 통째로 잘려 사라진다 — 삼성만 걸러 보면 갤럭시가
              // 몇 대 안 보이던 게 그거였다.
              //
              // 화면에 찍는 숫자는 그대로 전역 순위다(r.position). 걸러 놓고
              // 1번부터 다시 매기면 "삼성 중 1위"가 "전체 1위"로 읽힌다.
              top: i * rowHeight,
              left: 0,
              right: 0,
              height: rowHeight,
              child: _RankRow(
                entry: r,
                axis: axis,
                last: i == ranked.length - 1,
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
  const _RankRow({
    required this.entry,
    required this.axis,
    required this.last,
    this.onTap,
  });

  final RankedDevice entry;
  final RankAxis axis;
  final bool last;
  final VoidCallback? onTap;

  /// 값이 아무리 길어도 이름을 밀어내지 못하는 한도.
  ///
  /// 예전에는 한도가 없어서 `$1,000,000` 이 이름 폭을 0 으로 만들었다.
  static const double _valueWidth = 110;

  static const double _padV = 10;
  static const double _barGap = 8;

  /// 행 하나의 높이.
  ///
  /// **상수로 잡으면 안 된다.** 이름과 그 아래 줄이 손쉬운 사용 배율을 그대로
  /// 따라간다 — 1.6배면 두 줄이 60pt 라 74pt 짜리 고정 행을 넘는다.
  /// 목록이 `Stack` 이라 넘친 만큼이 다음 행 위에 겹쳐 그려진다.
  static double heightOf(BuildContext context) {
    final type = context.tpText;
    final scale = MediaQuery.textScalerOf(context);
    final block =
        scale.scale(type.cardTitle.fontSize!) * 1.25 +
        2 +
        scale.scale(type.caption.fontSize!) * 1.3;
    // 순위 쪽이 더 클 수도 있다. 배지는 지름이 고정이고, 큰 숫자는 1.3배에서
    // 묶여 있다(_Position). 둘 다 재서 큰 쪽을 쓴다 — 여기서 0.8pt 만 모자라도
    // 목록이 Stack 이라 다음 행 위에 겹쳐 그려진다.
    final lead = <double>[
      _Position.badge,
      scale.scale(_Position.numeral).clamp(0, _Position.numeral * 1.3) *
          _Position.numeralHeight,
    ].reduce((a, b) => a > b ? a : b);
    // 정수로 올린다. 소수점이 남으면 행마다 안쪽 글자가 다른 서브픽셀에
    // 떨어져서, 자리는 일정한데 글자 간격이 0.5pt 씩 어긋나 보인다.
    return (_padV * 2 + (block > lead ? block : lead) + _barGap + 3 + 1)
        .ceilToDouble();
  }

  /// 이름 아래 줄. 브랜드와 가격이다.
  ///
  /// 명세의 행은 한 줄이었는데, 순위·이름·점수만 있으면 목록이 숫자 표처럼
  /// 읽혔다. 값을 하나 더 얹는 대신 **이미 아는 것**을 놓는다.
  String get _sub {
    final price = DeviceSpecs.formatPrice(entry.device.msrpUsd);
    return <String>[
      if (entry.device.brand?.name != null) entry.device.brand!.name,
      if (price != DeviceSpecs.empty) price,
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: _padV),
          decoration: last
              ? null
              : BoxDecoration(
                  border: Border(bottom: BorderSide(color: t.hairline)),
                ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  SizedBox(
                    width: 46,
                    child: _Position(position: entry.position),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          entry.device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.cardTitle.copyWith(height: 1.25),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.caption.copyWith(height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _valueWidth),
                    child: Text(
                      formatAxisValue(axis, entry.axisValue),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      style: type.cardTitle.copyWith(
                        color: entry.axisValue == null ? t.dim : t.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _barGap),
              TpBar(height: 3, radius: 2, fraction: entry.fraction),
            ],
          ),
        ),
      ),
    );
  }
}

/// 순위 숫자. 1–3 위는 파란 원 안에 들어간다.
///
/// **명세와 다른 자리다.** §4 는 행 전체를 "숫자 · 이름 · 값 · 3px 막대"로
/// 못박고 1–3 위를 파란 **글자**로 준다. 파란 28pt 숫자는 4위의 회색 28pt
/// 숫자와 크기가 같아서, 스크롤하다 보면 어디까지가 위쪽인지 안 보였다.
class _Position extends StatelessWidget {
  const _Position({required this.position});

  final int position;

  /// 배지 지름. 큰 숫자와 자리를 맞춘다.
  static const double badge = 34;

  /// 4위 아래의 큰 숫자.
  static const double numeral = 28;

  /// 그 숫자의 줄 높이. 기본값(폰트 메트릭)에 맡기면 행 높이를 미리 못 잰다.
  static const double numeralHeight = 1.1;

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final type = context.tpText;

    // 배지는 지름이 고정이라 안의 숫자도 같이 묶어야 한다. 큰 숫자는
    // 28pt 라 배율을 그대로 곱하면 두 줄이 된다.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: position <= 3
          ? Container(
              width: badge,
              height: badge,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: TpTokens.blue,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$position',
                maxLines: 1,
                softWrap: false,
                style: type.cardTitle.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            )
          : Text(
              '$position',
              maxLines: 1,
              softWrap: false,
              style: type.cardTitle.copyWith(
                fontSize: numeral,
                height: numeralHeight,
                fontWeight: t.isGlass ? FontWeight.w700 : FontWeight.w500,
                color: t.mutedInk,
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
    // 나타날 목록과 보폭이 같아야 예고가 된다. 52+10 이던 때는 뼈대가
    // 사라지면서 아래 것들이 한 번 튀었다.
    final stride = _RankRow.heightOf(context);

    return Column(
      children: <Widget>[
        for (var i = 0; i < 5; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              height: stride - 8,
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
