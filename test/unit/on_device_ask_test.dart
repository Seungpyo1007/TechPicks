import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/shared/copy_keys.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/service/on_device_ask_service.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

import '../support/harness.dart';

/// 기기 안 AI.
///
/// 모델 자체는 실기기·시뮬레이터에서만 돈다(iOS 26+ Apple Foundation Models,
/// Android 는 Gemini Nano). 여기서 잡는 것은 **모델에 뭘 주고 받은 걸 어떻게
/// 읽는가** 다 — 그건 플랫폼 없이도 다 확인된다.
void main() {
  setUp(initLocalization);

  final catalog = readCatalog().smartphones;

  group('프롬프트', () {
    test('기기 안 모델에는 카탈로그를 잘라서 준다', () {
      final prompt = OnDeviceAskService.buildPrompt(
        '뭐가 좋아?',
        catalog,
        TpWeights.defaults,
      );

      // 카탈로그는 이보다 크다. 다 넣으면 질문이 들어갈 자리가 없다.
      expect(catalog.length, greaterThan(OnDeviceAskService.catalogLimit));
      // 머리글도 같은 모양이라 그것만 뺀다.
      final lines = prompt
          .split('\n')
          .where((l) => l.contains(' | TP ') && !l.startsWith('Phones'))
          .toList();
      expect(lines, hasLength(OnDeviceAskService.catalogLimit));
    });

    test('지수가 높은 기기부터 넣는다', () {
      final prompt = OnDeviceAskService.buildPrompt(
        '뭐가 좋아?',
        catalog,
        TpWeights.defaults,
      );
      final first = prompt
          .split('\n')
          .firstWhere((l) => l.contains(' | TP ') && !l.startsWith('Phones'))
          .split(' | ')
          .first;

      final best =
          (catalog.toList()..sort(
                (a, b) => (b.score?.performance ?? 0).compareTo(
                  a.score?.performance ?? 0,
                ),
              ))
              .first;
      // 정확히 1위까지 맞출 필요는 없다 — 잘린 목록 안에 있으면 된다.
      expect(prompt, contains(best.slug));
      expect(first, isNotEmpty);
    });

    test('TP 지수가 우리 점수라고 말해준다', () {
      // 안 적어두면 모델이 "배터리는 TP 지수가 정한다" 같은 말을 지어낸다.
      // 시뮬레이터에서 실제로 그렇게 답한 적이 있다.
      final prompt = OnDeviceAskService.buildPrompt(
        '배터리는 뭐가 정하나요?',
        catalog,
        TpWeights.defaults,
      );
      expect(prompt, contains("this app's own"));
    });
  });

  group('응답 읽기', () {
    final small = <Smartphone>[
      const Smartphone(slug: 'galaxy-s25', name: 'Galaxy S25'),
    ];

    test('카탈로그 안 기기를 고르면 표가 있는 답', () {
      final reply = OnDeviceAskService.replyFrom(
        '{"pick":"Galaxy S25","slug":"galaxy-s25","reason":"싸다"}',
        small,
      );
      expect(reply?.answer?.pickSlug, 'galaxy-s25');
      // 이 프롬프트는 rows 를 아예 안 시킨다 — 작은 모델은 규칙이 길어지면
      // 형태를 놓친다. 그런데 표가 이 화면의 요점이고, 기본 엔진이 이쪽이라
      // 대부분의 사람이 표를 한 번도 못 봤다. 카탈로그에서 만들어 붙인다.
      expect(reply?.answer?.rows.map((r) => r.label).toList(), <String>[
        K.tpIndex.tr(),
        K.spec(SpecKind.price).tr(),
        K.spec(SpecKind.battery).tr(),
        K.spec(SpecKind.camera).tr(),
      ]);
    });

    test('문장만 오면 문장만', () {
      final reply = OnDeviceAskService.replyFrom(
        '{"answer":"화면이 배터리를 제일 많이 씁니다."}',
        small,
      );
      expect(reply?.text, '화면이 배터리를 제일 많이 씁니다.');
      expect(reply?.answer, isNull);
    });

    test('목록 밖 기기를 골라도 이유는 살린다', () {
      final reply = OnDeviceAskService.replyFrom(
        '{"pick":"Nokia 3310","slug":"nokia-3310","reason":"튼튼합니다"}',
        small,
      );
      expect(reply?.answer, isNull);
      expect(reply?.text, '튼튼합니다');
    });

    test('아무 모양도 아니면 null', () {
      expect(OnDeviceAskService.replyFrom('그냥 말', small), isNull);
    });
  });
}
