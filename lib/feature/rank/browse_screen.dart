import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../data/dto/laptop.dart';
import '../../domain/model/processor.dart';
import '../../domain/model/ranking.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_arrive.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_menu.dart';
import '../../shared/widgets/tp_page.dart';
import '../cpu/processor_screen.dart';
import 'category_chips.dart';
import 'laptop_screen.dart';
import 'rank_category.dart';
import 'rank_screen.dart';

/// 둘러보기. 스마트폰 · 프로세서 · 노트북이 **한 화면**이다.
///
/// 셋이 따로 된 화면이던 때는 세그먼트를 누르면 새 화면이 밀려 들어왔고,
/// 카테고리마다 툴바·상태 줄·목록 모양이 달랐다. 이제 뼈대는 하나다:
/// 툴바에 필터와 정렬, 세그먼트 아래 상태 줄(정렬 · 필터 · 개수), 그 아래
/// 순위 목록. 카테고리는 그 안의 내용만 바꾼다. 세그먼트도 같은 것이 남아서
/// 고른 칸이 미끄러진다.
class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({
    super.key,
    required this.category,
    this.onDeviceTap,
    this.onCategory,
    this.onBuild,
  });

  final RankCategory category;
  final ValueChanged<String>? onDeviceTap;
  final ValueChanged<RankCategory>? onCategory;
  final VoidCallback? onBuild;

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

/// 카테고리 하나가 뼈대에 채우는 것.
class _Parts {
  const _Parts({
    required this.filter,
    required this.sort,
    required this.status,
    required this.list,
    this.onClear,
    this.top = const <Widget>[],
  });

  final TpBarAction filter;
  final List<TpMenuItem> sort;
  final String status;
  final Widget list;

  /// 필터를 기본값으로. null 이면 "지우기"가 없다.
  final VoidCallback? onClear;

  /// 상태 줄 위에 얹는 것(프로세서의 조립 견적).
  final List<Widget> top;
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  /// 정렬·필터·카테고리가 바뀐 시각. 이때 위쪽 행이 다시 들어온다.
  DateTime? _changedAt;

  void _changed() => setState(() => _changedAt = DateTime.now());

  @override
  void didUpdateWidget(BrowseScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) _changedAt = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen(rankAxisProvider, (_, _) => _changed())
      ..listen(rankBrandProvider, (_, _) => _changed())
      ..listen(processorSegmentProvider, (_, _) => _changed())
      ..listen(processorSortProvider, (_, _) => _changed())
      ..listen(laptopSortProvider, (_, _) => _changed())
      ..listen(laptopTierProvider, (_, _) => _changed());

    final glass = context.tp.isGlass;
    final sys = context.sys;
    final parts = switch (widget.category) {
      RankCategory.phones => _phones(context),
      RankCategory.processors => _processors(context),
      RankCategory.laptops => _laptops(context),
    };

    return TpPage(
      title: K.tab(TpTab.browse).tr(),
      tab: TpTab.browse,
      actions: <TpBarAction>[
        parts.filter,
        // Android 는 정렬을 칩 줄로 보여준다(M3 에서는 칩이 표준).
        if (glass)
          TpBarAction(
            label: K.sort.tr(),
            icon: CupertinoIcons.arrow_up_arrow_down,
            menu: parts.sort,
          ),
      ],
      slivers: <Widget>[
        // 맨 앞에 두어야 카테고리가 바뀌어도 같은 세그먼트가 남는다.
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: CategoryChips(
              current: widget.category,
              onSelect: widget.onCategory ?? (_) {},
            ),
          ),
        ),
        if (!glass) SliverToBoxAdapter(child: _SortChips(items: parts.sort)),
        ...parts.top,
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 24, 7),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    parts.status,
                    style: TextStyle(fontSize: 13, color: sys.label2),
                  ),
                ),
                if (parts.onClear != null)
                  GestureDetector(
                    onTap: parts.onClear,
                    child: Text(
                      K.clear.tr(),
                      style: TextStyle(fontSize: 13, color: sys.accentText),
                    ),
                  ),
              ],
            ),
          ),
        ),
        TpArriveScope(
          at: TpArriveScope.latest(TpArriveScope.of(context), _changedAt),
          child: parts.list,
        ),
      ],
    );
  }

  /// 필터가 걸려 있으면 그 값이 채운 캡슐로, 아니면 아이콘.
  TpBarAction _filterAction({
    required String? active,
    String? label,
    List<TpMenuItem>? menu,
    VoidCallback? onTap,
  }) {
    if (active != null) {
      return TpBarAction(
        label: active,
        text: true,
        filled: true,
        menu: menu,
        onTap: onTap,
      );
    }
    return TpBarAction(
      label: label ?? K.filter.tr(),
      icon: context.tp.isGlass
          ? CupertinoIcons.line_horizontal_3_decrease
          : Icons.filter_list,
      menu: menu,
      onTap: onTap,
    );
  }

  Widget _message(String text) => SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(text, style: TextStyle(color: context.sys.label2)),
    ),
  );

  _Parts _phones(BuildContext context) {
    final money = ref.watch(moneyProvider);
    final axis = ref.watch(rankAxisProvider);
    final ranked = ref.watch(rankVisibleProvider);
    final catalog = ref.watch(catalogProvider);
    final brands = ref.watch(rankBrandsProvider);
    final brand = ref.watch(rankBrandProvider);
    final loading = catalog is AsyncLoading && !catalog.hasError;
    final onDeviceTap = widget.onDeviceTap;

    final Widget list;
    if (loading) {
      list = const SliverToBoxAdapter(child: RankSkeleton());
    } else if (catalog.hasError) {
      list = const SliverToBoxAdapter(child: TpCatalogError());
    } else if (ranked.isEmpty) {
      list = _message(K.noMatches.tr());
    } else {
      list = TpGroupSliver(
        count: ranked.length,
        footer: K.rankNote.tr(),
        builder: (context, i) => RankRow(
          entry: ranked[i],
          axis: axis,
          money: money,
          onTap: onDeviceTap == null
              ? null
              : () => onDeviceTap(ranked[i].device.slug),
        ),
      );
    }

    return _Parts(
      filter: _filterAction(
        active: brand,
        label: K.brand.tr(),
        onTap: brands.isEmpty
            ? null
            : () => pickBrand(context, ref, brands, brand),
      ),
      sort: <TpMenuItem>[
        for (final a in RankAxis.values)
          TpMenuItem(
            label: K.rankAxis(a).tr(),
            checked: a == axis,
            onTap: () => ref.read(rankAxisProvider.notifier).set(a),
          ),
      ],
      status: K.rankStatus.tr(
        args: <String>[
          K.rankAxis(axis).tr(),
          brand ?? K.allBrands.tr(),
          '${ranked.length}',
        ],
      ),
      onClear: brand == null
          ? null
          : () => ref.read(rankBrandProvider.notifier).set(null),
      list: list,
    );
  }

  _Parts _processors(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final segment = ref.watch(processorSegmentProvider);
    final sort = ref.watch(processorSortProvider);
    final glass = context.tp.isGlass;
    final ranked = <RankedProcessor>[
      ...ref.watch(processorsInProvider(segment)),
    ];
    if (sort == ProcessorSort.name) {
      ranked.sort((a, b) => a.processor.name.compareTo(b.processor.name));
    }

    final Widget list;
    if (catalog is AsyncLoading && !catalog.hasError) {
      list = const SliverToBoxAdapter(child: RankSkeleton());
    } else if (catalog.hasError) {
      list = const SliverToBoxAdapter(child: TpCatalogError());
    } else if (ranked.isEmpty) {
      list = _message(K.noDevices.tr());
    } else {
      list = TpGroupSliver(
        count: ranked.length,
        footer: K.cpuNote.tr(),
        builder: (context, i) => ProcessorRow(entry: ranked[i]),
      );
    }

    return _Parts(
      filter: _filterAction(
        active: segment == ProcessorSegment.mobile ? null : segment.key.tr(),
        menu: <TpMenuItem>[
          for (final s in ProcessorSegment.values)
            TpMenuItem(
              label: s.key.tr(),
              checked: s == segment,
              onTap: () => ref.read(processorSegmentProvider.notifier).set(s),
            ),
        ],
      ),
      sort: <TpMenuItem>[
        for (final s in ProcessorSort.values)
          TpMenuItem(
            label: _processorSortKey(s).tr(),
            checked: s == sort,
            onTap: () => ref.read(processorSortProvider.notifier).set(s),
          ),
      ],
      status: K.cpuStatus.tr(
        args: <String>[
          _processorSortKey(sort).tr(),
          segment.key.tr(),
          '${ranked.length}',
        ],
      ),
      onClear: segment == ProcessorSegment.mobile
          ? null
          : () => ref
                .read(processorSegmentProvider.notifier)
                .set(ProcessorSegment.mobile),
      top: <Widget>[
        if (widget.onBuild != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: TpGroup(
                children: <Widget>[
                  TpRow(
                    title: K.buildTitle.tr(),
                    subtitle: K.buildRowSub.tr(),
                    leading: TpIconTile(
                      icon: glass
                          ? CupertinoIcons.wrench
                          : Icons.build_outlined,
                    ),
                    onTap: widget.onBuild,
                  ),
                ],
              ),
            ),
          ),
      ],
      list: list,
    );
  }

  static String _processorSortKey(ProcessorSort s) => switch (s) {
    ProcessorSort.score => K.sortScore,
    ProcessorSort.name => K.sortName,
  };

  static String _laptopSortKey(LaptopSort s) => switch (s) {
    LaptopSort.priceHigh => K.sortPriceHigh,
    LaptopSort.priceLow => K.sortPriceLow,
  };

  static const List<String> _tiers = <String>[
    K.laptopTierHigh,
    K.laptopTierPerf,
    K.laptopTierMain,
  ];

  _Parts _laptops(BuildContext context) {
    final laptops = ref.watch(laptopsProvider);
    final money = ref.watch(moneyProvider);
    final sort = ref.watch(laptopSortProvider);
    final tier = ref.watch(laptopTierProvider);
    final all = laptops.value?.byPrice ?? const <Laptop>[];
    final items = <Laptop>[
      for (final l in all)
        if (tier == null || LaptopScreen.tierOf(l.msrpUsd) == tier) l,
    ];
    if (sort == LaptopSort.priceLow) {
      items.sort(
        (a, b) => (a.msrpUsd ?? 1 << 30).compareTo(b.msrpUsd ?? 1 << 30),
      );
    }
    final top = all.fold<int>(
      0,
      (m, l) => (l.msrpUsd ?? 0) > m ? l.msrpUsd! : m,
    );

    final Widget list;
    if (laptops.hasError) {
      list = const SliverToBoxAdapter(child: TpCatalogError());
    } else if (laptops.isLoading && all.isEmpty) {
      list = const SliverToBoxAdapter(child: RankSkeleton());
    } else if (items.isEmpty) {
      list = _message(K.noDevices.tr());
    } else {
      list = TpGroupSliver(
        count: items.length,
        footer: K.laptopNote.tr(),
        builder: (context, i) => LaptopRow(
          laptop: items[i],
          position: i + 1,
          fraction: top <= 0 ? 0 : (items[i].msrpUsd ?? 0) / top,
          money: money,
        ),
      );
    }

    return _Parts(
      filter: _filterAction(
        active: tier?.tr(),
        menu: <TpMenuItem>[
          TpMenuItem(
            label: K.allPrices.tr(),
            checked: tier == null,
            onTap: () => ref.read(laptopTierProvider.notifier).set(null),
          ),
          for (final t in _tiers)
            TpMenuItem(
              label: t.tr(),
              checked: t == tier,
              onTap: () => ref.read(laptopTierProvider.notifier).set(t),
            ),
        ],
      ),
      sort: <TpMenuItem>[
        for (final s in LaptopSort.values)
          TpMenuItem(
            label: _laptopSortKey(s).tr(),
            checked: s == sort,
            onTap: () => ref.read(laptopSortProvider.notifier).set(s),
          ),
      ],
      status: K.laptopStatus.tr(
        args: <String>[
          _laptopSortKey(sort).tr(),
          tier?.tr() ?? K.allPrices.tr(),
          '${items.length}',
        ],
      ),
      onClear: tier == null
          ? null
          : () => ref.read(laptopTierProvider.notifier).set(null),
      list: list,
    );
  }
}

/// Android 의 정렬 칩 한 줄.
class _SortChips extends StatelessWidget {
  const _SortChips({required this.items});

  final List<TpMenuItem> items;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 56,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) => FilterChip(
        label: Text(items[i].label),
        selected: items[i].checked,
        onSelected: (_) => items[i].onTap(),
      ),
    ),
  );
}
