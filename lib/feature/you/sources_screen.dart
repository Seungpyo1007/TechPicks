import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/repository/catalog_repository.dart';
import '../../data/service/link_opener.dart';
import '../../domain/model/tp_weights.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_link_line.dart';
import '../../shared/widgets/tp_surface.dart';

/// 데이터 출처.
///
/// **이 화면은 선택이 아니다.** 카탈로그가 CC-BY-SA 4.0 이라 출처 표기와
/// 라이선스 접근이 의무다 (`docs/REBUILD_PLAN.md` §5.3).
///
/// 상세 화면은 기기마다의 원문 주소를 이미 내보이고 있었다. 빠져 있던 건
/// **데이터셋 전체에 대한 귀속**이다 — 랭킹·비교·홈은 전부 이 자료에서
/// 파생된 숫자를 보여주면서 어디서 왔는지 말하는 곳이 없었다.
///
/// 실린 것의 수를 같이 적는다. "TechAPI 에서 왔습니다" 한 줄보다, 무엇이
/// 얼마나 실려 있는지 보이는 쪽이 정직하다 — 154종이 전부라는 것도 정보다.
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = context.tpText;
    final catalog = ref.watch(catalogProvider).value;
    final weights = ref.watch(weightsProvider);

    // 밀려 들어온 화면이다. 뒤로 버튼은 다른 푸시 화면처럼 헤더 왼쪽에 둔다.
    return TpShell(
      onBack: onBack,
      child: Builder(
        builder: (context) => ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 24) +
              tpContentInset(context),
          children: <Widget>[
            Text(K.sources.tr(), style: type.largeTitle),
            const SizedBox(height: 10),
            Text(K.sourcesIntro.tr(), style: type.secondary),
            const SizedBox(height: 18),

            TpSurface(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    K.sourcesDataset.tr().toUpperCase(),
                    style: type.eyebrow,
                  ),
                  const SizedBox(height: 6),
                  // 카탈로그가 스스로 들고 온 출처 문자열. 손으로 적지 않는다
                  // — 카탈로그를 다시 구우면 이 줄도 따라간다.
                  Text(
                    catalog?.source ?? K.dataSource.tr(),
                    style: type.body,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TpLinkLine(
                    label: K.sourcesLicense.tr(),
                    url: TpUrls.license,
                    style: type.caption,
                  ),
                  TpLinkLine(
                    label: K.sourcesRepo.tr(),
                    url: TpUrls.techApi,
                    style: type.caption,
                    topPadding: 2,
                  ),
                ],
              ),
            ),

            if (catalog != null) ...<Widget>[
              const SizedBox(height: 14),
              TpSurface(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      K.sourcesContents.tr().toUpperCase(),
                      style: type.eyebrow,
                    ),
                    const SizedBox(height: 6),
                    for (final line in _contents(catalog))
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(line, style: type.body),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      K.sourcesVersion.tr(args: <String>['${catalog.version}']),
                      style: type.caption,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),
            // 자료가 어디서 왔는지 옆에 숫자가 어떻게 만들어지는지를 둔다.
            // 출처를 밝히는 화면에서 제일 궁금한 다음 질문이다.
            //
            // **기본 가중치일 때만** 확정 문구를 쓴다. 그 문구가
            // 25/25/20/20/10 을 못박는데 You 에서 바꿀 수 있어서, 슬라이더를
            // 움직인 사람에게 그대로 보이면 거짓말이 된다.
            Text(
              weights == TpWeights.defaults
                  ? K.indexNote.tr()
                  : K.indexNoteCustom.tr(),
              style: type.caption,
            ),
            const SizedBox(height: 14),
            Text(K.sourcesPerDevice.tr(), style: type.caption),
            const SizedBox(height: 14),
            TpLinkLine(
              label: K.sourcesAppCode.tr(),
              url: TpUrls.appLicense,
              style: type.caption,
            ),
          ],
        ),
      ),
    );
  }

  /// 비어 있는 갈래는 줄을 만들지 않는다. "브랜드 0곳"은 정보가 아니라 잡음이다.
  List<String> _contents(Catalog catalog) => <String>[
    if (catalog.smartphones.isNotEmpty)
      K.sourcesPhones.tr(args: <String>['${catalog.smartphones.length}']),
    if (catalog.cpus.isNotEmpty)
      K.sourcesCpus.tr(args: <String>['${catalog.cpus.length}']),
    if (catalog.socs.isNotEmpty)
      K.sourcesSocs.tr(args: <String>['${catalog.socs.length}']),
    if (catalog.brands.isNotEmpty)
      K.sourcesBrands.tr(args: <String>['${catalog.brands.length}']),
  ];
}
