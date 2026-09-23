import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/shell/tp_shell.dart';
import '../../app/shell/tp_tab.dart';
import '../../app/theme/tp_motion.dart';
import '../../app/theme/tp_tokens.dart';
import '../../app/theme/tp_typography.dart';
import '../../data/dto/laptop.dart';
import '../../domain/model/device_specs.dart';
import '../../domain/model/tp_money.dart';
import '../../shared/copy_keys.dart';
import '../../shared/spec_labels.dart';
import '../../shared/widgets/tp_error_state.dart';
import '../../shared/widgets/tp_surface.dart';
import 'category_chips.dart';
import 'rank_category.dart';

/// 노트북.
///
/// **순위를 매기지 않는다.** TechAPI 에 노트북 벤치마크가 없어서 지수를
/// 만들 수 없다. 없는 점수를 지어내면 이 앱의 전제를 배반한다 — 명세가
/// v1 의 잘못으로 꼽은 게 "점수가 설명 없이 나타난다" 였다.
///
/// 그래서 순위 번호도 TP 지수도 막대도 없다. 값을 아는 축이 가격뿐이라
/// 가격순으로 놓고, 머리에 왜 지수가 없는지 적는다.
///
/// 칩은 여태 눌러도 아무 일이 없었다. 화면이 없으니 눌리지 않게 막아뒀고,
/// 그 상태가 "고장 난 앱"처럼 보였다. 아홉 대뿐이어도 진짜 화면이 낫다.
class LaptopScreen extends ConsumerWidget {
  const LaptopScreen({super.key, this.onCategory});

  final ValueChanged<RankCategory>? onCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final laptops = ref.watch(laptopsProvider);
    final money = ref.watch(moneyProvider);
    final motion = context.motion;
    final items = laptops.value?.byPrice ?? const <Laptop>[];

    return TpShell(
      title: K.laptopTitle.tr(),
      tab: TpTab.browse,
      child: Builder(
        builder: (context) => ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 4, 16, 24) +
              tpContentInset(context),
          children: <Widget>[
            CategoryChips(
              current: RankCategory.laptops,
              onSelect: onCategory ?? (_) {},
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: motion.contentSwap.duration,
              switchInCurve: motion.contentSwap.curve,
              switchOutCurve: motion.contentSwap.curve,
              child: laptops.hasError
                  ? const TpCatalogError(key: ValueKey<String>('error'))
                  : items.isEmpty
                  ? TpSurface(
                      key: const ValueKey<String>('empty'),
                      padding: const EdgeInsets.all(20),
                      child: Text(K.noDevices.tr(), style: context.tpText.body),
                    )
                  : Column(
                      key: const ValueKey<String>('rows'),
                      children: <Widget>[
                        for (final l in items)
                          _LaptopCard(laptop: l, money: money),
                      ],
                    ),
            ),
            const SizedBox(height: 18),
            Text(K.laptopNote.tr(), style: context.tpText.caption),
          ],
        ),
      ),
    );
  }
}

/// 노트북 한 장.
///
/// 상세로 안 보낸다. 노트북 상세 화면이 없고, 누를 수 있어 보이는데 아무 데도
/// 안 가는 것보다 안 눌리는 편이 낫다.
class _LaptopCard extends StatelessWidget {
  const _LaptopCard({required this.laptop, required this.money});

  final Laptop laptop;

  /// 위에서 받는다. 카드마다 프로바이더를 읽으면 아홉 번 같은 값을 읽는다.
  final TpMoney money;

  @override
  Widget build(BuildContext context) {
    final type = context.tpText;
    final t = context.tp;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TpSurface(
        padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (laptop.brand?.name case final brand?
                          when brand.isNotEmpty)
                        Text(brand.toUpperCase(), style: type.eyebrow),
                      Text(laptop.name, style: type.cardTitle),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                      money.format(laptop.msrpUsd),
                      style: type.cardTitle,
                      maxLines: 1,
                      softWrap: false,
                    ),
                    if (_tier(laptop.msrpUsd) case final tier?)
                      Text(tier.tr(), style: type.caption),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final row in _rows(laptop))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 72,
                      child: Text(
                        row.$1,
                        style: type.caption.copyWith(color: t.dim),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        style: type.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  /// 값이 있는 줄만. 빈 줄을 대시로 채우면 카드가 모르는 것으로 가득 찬다.
  ///
  /// 라벨은 이미 번역된 문자열이다. 칩셋·화면은 상세·비교와 같은 표를
  /// 쓴다 — 같은 것을 두 이름으로 부르지 않으려는 것이다.
  List<(String, String)> _rows(Laptop l) => <(String, String)>[
    if (l.cpuName case final v? when v.isNotEmpty)
      (SpecLabels.of(SpecKind.chipset), v),
    if (l.gpuName case final v? when v.isNotEmpty) (K.specGpu.tr(), v),
    if (_memory(l) case final v?) (K.specRam.tr(), v),
    if (_storage(l) case final v?) (K.specStorage.tr(), v),
    if (_display(l) case final v?) (SpecLabels.of(SpecKind.screen), v),
  ];

  static String? _memory(Laptop l) => l.ramGb == null ? null : '${l.ramGb}GB';

  /// `1024` 는 `1TB` 로. 1024GB 라고 적힌 노트북은 없다.
  static String? _storage(Laptop l) {
    final gb = l.storageGb;
    if (gb == null) return null;
    if (gb >= 1024 && gb % 1024 == 0) return '${gb ~/ 1024}TB';
    return '${gb}GB';
  }

  static String? _display(Laptop l) {
    final d = l.display;
    if (d == null) return null;
    final parts = <String>[
      if (d.sizeInch != null) '${_trim(d.sizeInch!)}"',
      if (d.resolution != null) d.resolution!,
      if (d.refreshHz != null) '${d.refreshHz}Hz',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  static String _trim(double v) =>
      v == v.roundToDouble() ? v.round().toString() : v.toString();

  /// 가격대. **점수가 아니다** — 값에서 바로 읽히는 구간일 뿐이라 이름도
  /// 지수처럼 안 짓는다.
  static String? _tier(int? usd) => switch (usd) {
    null => null,
    >= 3000 => K.laptopTierHigh,
    >= 1500 => K.laptopTierPerf,
    _ => K.laptopTierMain,
  };
}
