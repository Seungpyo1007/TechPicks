import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/data/dto/score.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/domain/model/ask_answer.dart';

Smartphone _phone(String slug, {int? usd, double? perf, int? mah}) => Smartphone(
      slug: slug,
      name: slug,
      msrpUsd: usd,
      batteryMah: mah,
      score: SmartphoneScore(
        performance: perf,
        camera: 50,
        display: 50,
        battery: 50,
        value: 50,
      ),
    );

void main() {
  group('AskAnswer.tryParse', () {
    test('깨끗한 JSON', () {
      final a = AskAnswer.tryParse(
        '{"pick":"Galaxy S25","slug":"galaxy-s25","reason":"Balanced.",'
        '"rows":[{"label":"TP Index","value":"61"},'
        '{"label":"Price","value":"\$799"}]}',
      );

      expect(a, isNotNull);
      expect(a!.pick, 'Galaxy S25');
      expect(a.pickSlug, 'galaxy-s25');
      expect(a.reason, 'Balanced.');
      expect(a.rows, hasLength(2));
      expect(a.rows.first.label, 'TP Index');
    });

    test('코드펜스와 앞뒤 말이 붙어도 읽는다', () {
      // JSON 만 뱉으라고 해도 모델이 이러는 일이 흔하다.
      final a = AskAnswer.tryParse('''
Sure! Here you go:
```json
{"pick":"OnePlus 13","reason":"Cheapest flagship.","rows":[]}
```
Hope that helps.
''');
      expect(a?.pick, 'OnePlus 13');
    });

    test('숫자 value 도 문자열로 받는다', () {
      final a = AskAnswer.tryParse(
        '{"pick":"X","rows":[{"label":"TP Index","value":61}]}',
      );
      expect(a!.rows.single.value, '61');
    });

    test('망가진 응답은 null', () {
      expect(AskAnswer.tryParse(''), isNull);
      expect(AskAnswer.tryParse('그냥 문장입니다'), isNull);
      expect(AskAnswer.tryParse('{"pick":}'), isNull);
      // pick 이 없으면 화면이 그릴 게 없다.
      expect(AskAnswer.tryParse('{"reason":"..."}'), isNull);
      expect(AskAnswer.tryParse('{"pick":"  "}'), isNull);
    });

    test('rows 가 이상해도 나머지는 살린다', () {
      final a = AskAnswer.tryParse(
        '{"pick":"X","rows":["nope",{"label":"OK","value":"1"},{"value":"2"}]}',
      );
      expect(a!.rows, hasLength(1));
      expect(a.rows.single.label, 'OK');
    });
  });

  group('LocalAskService', () {
    final catalog = <Smartphone>[
      _phone('cheap', usd: 500, perf: 40, mah: 4000),
      _phone('mid', usd: 900, perf: 70, mah: 4500),
      _phone('flagship', usd: 1400, perf: 95, mah: 5000),
    ];

    test('지수가 가장 높은 기기를 고른다', () async {
      final a = await const LocalAskService().ask('뭐가 좋아?', catalog);
      expect(a!.pickSlug, 'flagship');
      expect(a.rows.map((r) => r.label), <String>[
        'TP Index',
        'Price',
        'Battery',
        'Camera',
      ]);
    });

    test('예산을 말하면 그 안에서 고른다', () async {
      final a = await const LocalAskService().ask('\$1,000 이하로', catalog);
      expect(a!.pickSlug, 'mid');
      expect(a.reason, contains('1000'));
    });

    test('예산 안에 아무것도 없으면 전체에서 고른다', () async {
      final a = await const LocalAskService().ask('100 달러', catalog);
      expect(a!.pickSlug, 'flagship');
    });

    test('빈 카탈로그면 null', () async {
      expect(
        await const LocalAskService().ask('뭐든', const <Smartphone>[]),
        isNull,
      );
    });
  });

  group('GeminiAskService', () {
    test('유효한 모델 ID 를 쓴다', () {
      // v1 은 'gemini-flash-experimental' 이었는데 그런 ID 는 없다.
      expect(GeminiAskService.modelId, isNot(contains('experimental')));
    });

    test('프롬프트에 카탈로그와 응답 형태가 들어간다', () {
      final prompt = GeminiAskService.buildPrompt(
        '카메라 좋은 거',
        <Smartphone>[_phone('galaxy-s25', usd: 799, perf: 88)],
        const LocalAskService().weights,
      );

      expect(prompt, contains('galaxy-s25'));
      expect(prompt, contains('JSON only'));
      expect(prompt, contains('MUST be one of the catalogue entries'));
      expect(prompt, contains('카메라 좋은 거'));
    });
  });
}
