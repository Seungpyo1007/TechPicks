import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/brand/tp_logo.dart';
import '../../app/providers.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/shell/tp_tab_bar.dart';
import '../../app/theme/tp_icons.dart';
import '../../app/theme/tp_native_glass.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../domain/model/search_index.dart';
import '../../shared/coach/tp_coach.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_glass_search.dart';
import '../../shared/widgets/tp_group.dart';
import '../../shared/widgets/tp_page.dart';
import '../../shared/widgets/tp_tap_target.dart';
import '../rank/rank_category.dart';
import '../../shared/figures/tp_figure.dart';
import '../../shared/figures/tp_figures.dart';

/// 검색 탭. 폰·프로세서·노트북을 한 상자에서 찾는다.
///
/// iOS 는 탭 바가 접히고 필드가 그 자리(화면 아래)에 뜬다. Android 는 위.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.onHit, this.onKind});

  final ValueChanged<SearchHit>? onHit;
  final ValueChanged<RankCategory>? onKind;

  /// 빈 화면의 예시 검색어. 이름·칩·브랜드로 찾을 수 있다는 걸 보여준다.
  static const List<String> examples = <String>[
    'Galaxy S26',
    'iPhone 17',
    'Snapdragon',
    'MacBook',
  ];

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _input = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _set(String v) => setState(() => _query = v);

  /// 예시 검색어를 눌렀을 때. 검색창에 그 글자를 넣고 결과를 보여준다.
  void _try(String q, {required bool native}) {
    if (native) {
      ref.read(searchCommandProvider.notifier).setText(q);
      return;
    }
    _input.text = q;
    _set(q);
  }

  /// 결과 미리보기 한 줄. 앞의 두 개와 나머지 개수.
  static String _preview(List<SearchHit> found) {
    final names = found.take(2).map((h) => h.name).join(', ');
    return found.length > 2
        ? K.searchTryMore.tr(args: <String>[names, '${found.length - 2}'])
        : names;
  }

  @override
  Widget build(BuildContext context) {
    final sys = context.sys;
    final glass = context.tp.isGlass;
    final catalogAsync = ref.watch(catalogProvider);
    final catalog = catalogAsync.value;
    final laptops = ref.watch(laptopsProvider);
    // iOS 26 은 검색창이 시스템 탭 바 안에 있다. 글자는 탭 바가 넣어준다.
    final native = glass && TpNativeGlass.enabled;
    final query = native ? ref.watch(searchQueryProvider) : _query;
    final hits = SearchIndex.filter(ref.watch(searchIndexProvider), query);
    final typing = query.trim().isNotEmpty;
    final index = ref.watch(searchIndexProvider);
    // 카탈로그를 읽는 중. 빈 색인으로 "없음"이나 0 을 말하지 않는다.
    final loading =
        catalog == null && catalogAsync.isLoading && !catalogAsync.hasError;
    final recent = <SearchHit>[
      for (final key in ref.watch(recentHitsProvider))
        ?index.where((h) => RecentHitsNotifier.keyOf(h) == key).firstOrNull,
    ].take(3).toList();

    void open(SearchHit hit) {
      unawaited(ref.read(recentHitsProvider.notifier).add(hit));
      widget.onHit?.call(hit);
    }

    final field = TpCoachTarget(
      id: 'search-field',
      child: TpGlassSearch(
        placeholder: K.searchAllHint.tr(),
        controller: _input,
        onChanged: _set,
      ),
    );

    final slivers = <Widget>[
      if (!glass)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: field,
          ),
        ),
      if (loading)
        const SliverToBoxAdapter(child: _Loading())
      else if (!typing && recent.isNotEmpty)
        SliverToBoxAdapter(
          child: TpGroup(
            header: K.recent.tr(),
            headerAction: _ClearButton(
              onTap: () =>
                  unawaited(ref.read(recentHitsProvider.notifier).clear()),
            ),
            children: <Widget>[
              for (final hit in recent)
                TpRow(
                  title: hit.name,
                  subtitle: K.searchKind(hit.kind).tr(),
                  leading: TpIconTile(
                    icon: glass ? CupertinoIcons.clock : Icons.history,
                  ),
                  onTap: widget.onHit == null ? null : () => open(hit),
                ),
            ],
          ),
        ),
      if (!typing && !loading)
        SliverToBoxAdapter(
          child: TpGroup(
            header: K.searchTry.tr(),
            children: <Widget>[
              for (final q in SearchScreen.examples)
                if (SearchIndex.filter(index, q) case final found
                    when found.isNotEmpty)
                  TpRow(
                    title: q,
                    subtitle: _preview(found),
                    value: '${found.length}',
                    leading: TpIconTile(
                      icon: glass ? CupertinoIcons.search : Icons.search,
                      color: const Color(0xFF8E8E93),
                    ),
                    onTap: () => _try(q, native: native),
                  ),
            ],
          ),
        ),
      if (!typing)
        SliverToBoxAdapter(
          child: TpCoachTarget(
            id: 'search-kinds',
            child: TpGroup(
              header: K.browseByKind.tr(),
              children: <Widget>[
                TpRow(
                  title: K.phones.tr(),
                  value: catalog == null
                      ? null
                      : '${catalog.smartphones.length}',
                  leading: TpIconTile(
                    icon: glass
                        ? CupertinoIcons.device_phone_portrait
                        : Icons.smartphone,
                  ),
                  onTap: widget.onKind == null
                      ? null
                      : () => widget.onKind!(RankCategory.phones),
                ),
                TpRow(
                  title: K.cpus.tr(),
                  value: catalog == null
                      ? null
                      : '${catalog.socs.length + catalog.cpus.length}',
                  leading: TpIconTile(icon: Icons.memory),
                  onTap: widget.onKind == null
                      ? null
                      : () => widget.onKind!(RankCategory.processors),
                ),
                TpRow(
                  title: K.laptops.tr(),
                  value: laptops.value == null
                      ? null
                      : '${laptops.value!.byPrice.length}',
                  leading: TpIconTile(
                    icon: glass ? CupertinoIcons.device_laptop : Icons.laptop,
                  ),
                  onTap: widget.onKind == null
                      ? null
                      : () => widget.onKind!(RankCategory.laptops),
                ),
              ],
            ),
          ),
        )
      else if (loading)
        const SliverToBoxAdapter(child: SizedBox.shrink())
      else if (hits.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 60, 40, 0),
            child: Column(
              children: <Widget>[
                const TpFigure(height: 64, paint: TpFigures.search),
                const SizedBox(height: 12),
                Text(
                  K.noMatches.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: sys.label2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  K.scanHintIdle.tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: sys.label2,
                  ),
                ),
              ],
            ),
          ),
        )
      else
        for (final kind in SearchKind.values)
          if (hits.where((h) => h.kind == kind).toList() case final group
              when group.isNotEmpty)
            TpGroupSliver(
              header: '${K.searchKind(kind).tr()} · ${group.length}',
              count: group.length,
              builder: (context, i) => TpRow(
                title: group[i].name,
                subtitle: group[i].meta,
                value: group[i].index?.toString(),
                numeric: true,
                onTap: widget.onHit == null ? null : () => open(group[i]),
                semanticsLabel: group[i].index == null
                    ? null
                    : <String>[
                        group[i].name,
                        ?group[i].meta,
                        K.a11yIndex.tr(args: <String>['${group[i].index}']),
                      ].join(', '),
              ),
            ),
    ];

    final page = TpPage(
      title: K.searchTitle.tr(),
      tab: TpTab.search,
      // 첫 방문 안내. iOS 26 네이티브 검색창은 Flutter 밖이라 잴 수 없으면 건너뛴다.
      coach: const <TpCoachStep>[
        TpCoachStep(
          target: 'search-field',
          title: K.coachSearch,
          body: K.coachSearchBody,
        ),
        TpCoachStep(
          target: 'search-kinds',
          title: K.coachKinds,
          body: K.coachKindsBody,
        ),
      ],
      slivers: slivers,
    );
    if (!glass) return page;
    if (native) {
      // 결과를 끌어 올리면 키보드가 내려간다. 검색창이 Flutter 밖이라 직접 알린다.
      return NotificationListener<ScrollStartNotification>(
        onNotification: (n) {
          if (n.dragDetails != null) {
            ref.read(searchKeyboardProvider.notifier).dismiss();
          }
          return false;
        },
        child: page,
      );
    }

    // 접힌 탭 바: 돌아갈 탭 원 + 유리 필드가 한 줄.
    final back = TpSearchReturn.maybeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return Stack(
      children: <Widget>[
        Positioned.fill(child: page),
        Positioned(
          left: 21,
          right: 21,
          bottom: keyboard > 0 ? keyboard + 8 : TpTabBar.searchBottom(context),
          child: Row(
            children: <Widget>[
              if (back != null) ...<Widget>[
                TpGlassCircle(
                  size: TpGlassSearch.height,
                  label: K.tab(back.tab).tr(),
                  icon: TpIcons.iosTab(back.tab, active: false),
                  onTap: back.onReturn,
                ),
                const SizedBox(width: 10),
              ],
              Expanded(child: field),
            ],
          ),
        ),
      ],
    );
  }
}

/// 카탈로그를 읽는 동안. 최근·예시 자리에 돌림 표시와 한 줄.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(40, 28, 40, 28),
    child: Semantics(
      liveRegion: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const TpLogoLoader(size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              K.searchLoading.tr(),
              style: TextStyle(fontSize: 15, color: context.sys.label2),
            ),
          ),
        ],
      ),
    ),
  );
}

/// 최근 그룹 머리의 "지우기".
class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = context.tp.isGlass;
    return TpTapTarget(
      onTap: onTap,
      label: K.recentClear.tr(),
      minSize: glass ? 44 : 48,
      pressScale: 1,
      child: Text(
        K.recentClear.tr(),
        style: TextStyle(
          fontSize: glass ? 13 : 14,
          fontWeight: glass ? FontWeight.w400 : FontWeight.w500,
          color: context.sys.accentText,
        ),
      ),
    );
  }
}
