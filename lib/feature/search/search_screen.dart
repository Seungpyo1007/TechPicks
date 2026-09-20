import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../domain/model/search_index.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_search_field.dart';
import '../../shared/widgets/tp_surface.dart';
import '../../shared/widgets/tp_tap_target.dart';

/// 통합 검색.
///
/// 폰·프로세서·노트북을 한 상자에서 찾는다. 탭마다 검색을 따로 두면
/// "무엇을 찾는지" 를 먼저 정해야 하는데, 이름만 아는 사람은 그걸 모른다 —
/// 9950X3D 가 폰인지 프로세서인지 알면 이미 찾은 셈이다.
///
/// 화면이 열네 개로 늘면서 탭 다섯으로는 다 못 닿는다. 웹은 사이드바를
/// 아홉 칸으로 늘리고도 검색을 따로 뒀다. 이게 그 조각이다.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.onBack, this.onHit});

  final VoidCallback? onBack;

  /// 결과를 누르면. 라우팅은 바깥에서 한다.
  final ValueChanged<SearchHit>? onHit;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;
    // 색인은 프로바이더가 한 번만 짓는다. 여기서는 거르기만 한다.
    final hits = SearchIndex.filter(
      ref.watch(searchIndexProvider),
      _query.text,
    );
    final typing = _query.text.trim().isNotEmpty;

    return TpShell(
      mode: TpChromeMode.plain,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(K.searchTitle.tr(), style: type.largeTitle),
                ),
                if (widget.onBack != null)
                  TpTapTarget(
                    onTap: widget.onBack,
                    label: K.back.tr(),
                    child: Text(
                      K.cancel.tr(),
                      style: type.body.copyWith(color: t.link),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TpSearchField(
              controller: _query,
              hint: K.searchAllHint.tr(),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (typing)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                K.searchCount.tr(args: <String>['${hits.length}']),
                style: type.caption,
              ),
            ),
          Expanded(
            child: !typing
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    // 열자마자 194줄을 쏟으면 그건 검색 결과가 아니라 목록이다.
                    child: Text(K.searchEmpty.tr(), style: type.secondary),
                  )
                : hits.isEmpty
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(K.noMatches.tr(), style: type.secondary),
                  )
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      24 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    itemCount: hits.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _HitRow(
                      hit: hits[i],
                      onTap: widget.onHit == null
                          ? null
                          : () => widget.onHit!(hits[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _HitRow extends StatelessWidget {
  const _HitRow({required this.hit, this.onTap});

  final SearchHit hit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;

    return TpSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  hit.name,
                  style: type.cardTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hit.meta case final meta?)
                  Text(
                    meta,
                    style: type.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // 무엇인지 밝힌다. 같은 이름의 폰과 칩셋이 나란히 걸리는 일이 있다.
          Text(
            K.searchKind(hit.kind).tr(),
            style: type.caption.copyWith(color: t.dim),
            maxLines: 1,
            softWrap: false,
          ),
        ],
      ),
    );
  }
}
