import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/shared/copy_keys.dart';

import '../support/harness.dart';
import 'package:techpicks/data/dto/smartphone.dart';
import 'package:techpicks/data/service/ask_service.dart';
import 'package:techpicks/domain/model/ask_answer.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

Smartphone _phone(String slug, String name) =>
    Smartphone(slug: slug, name: name);

final _catalog = <Smartphone>[
  _phone('galaxy-s25-ultra', 'Galaxy S25 Ultra'),
  _phone('iphone-16-pro-max', 'iPhone 16 Pro Max'),
];

AskAnswer _answer({String? slug, String pick = 'Galaxy S25 Ultra'}) =>
    AskAnswer(
      pick: pick,
      pickSlug: slug,
      reason: '어쩌구',
      rows: const <AskRow>[AskRow(label: 'TP Index', value: '77')],
    );

void main() {
  // 오프라인 답변이 번역 파일을 읽는다.
  setUp(initLocalization);

  group('카탈로그 대조', () {
    test('slug 가 맞으면 그대로 통과한다', () {
      final r = GeminiAskService.resolveInCatalog(
        _answer(slug: 'galaxy-s25-ultra'),
        _catalog,
      );
      expect(r?.pickSlug, 'galaxy-s25-ultra');
      expect(r?.pick, 'Galaxy S25 Ultra');
      expect(r?.reason, '어쩌구');
      expect(r?.rows.length, 1);
    });

    test('slug 가 없으면 이름으로 찾아 채운다', () {
      final r = GeminiAskService.resolveInCatalog(_answer(), _catalog);
      expect(r?.pickSlug, 'galaxy-s25-ultra');
    });

    test('이름 대소문자와 앞뒤 공백은 무시한다', () {
      final r = GeminiAskService.resolveInCatalog(
        _answer(pick: '  iphone 16 PRO max '),
        _catalog,
      );
      expect(r?.pickSlug, 'iphone-16-pro-max');
      expect(r?.pick, 'iPhone 16 Pro Max');
    });

    test('slug 가 틀려도 이름이 맞으면 살린다', () {
      final r = GeminiAskService.resolveInCatalog(
        _answer(slug: '없는-슬러그', pick: 'iPhone 16 Pro Max'),
        _catalog,
      );
      expect(r?.pickSlug, 'iphone-16-pro-max');
    });

    test('카탈로그 밖의 기기를 고르면 답을 버린다', () {
      final r = GeminiAskService.resolveInCatalog(
        _answer(slug: 'pixel-10-pro', pick: 'Pixel 10 Pro'),
        _catalog,
      );
      expect(r, isNull);
    });

    test('카탈로그가 비면 답이 없다', () {
      expect(
        GeminiAskService.resolveInCatalog(
          _answer(slug: 'galaxy-s25-ultra'),
          const <Smartphone>[],
        ),
        isNull,
      );
    });

    test('표시 이름은 카탈로그 쪽을 쓴다', () {
      // 모델이 `갤럭시 S25 울트라` 처럼 다르게 부르면 상세 화면 제목과
      // 어긋난다.
      final r = GeminiAskService.resolveInCatalog(
        _answer(slug: 'galaxy-s25-ultra', pick: 'Samsung Galaxy S25 Ultra 5G'),
        _catalog,
      );
      expect(r?.pick, 'Galaxy S25 Ultra');
    });
  });

  group('프롬프트', () {
    test('카탈로그 전부와 질문이 들어간다', () {
      final prompt = GeminiAskService.buildPrompt(
        '뭐가 좋아?',
        _catalog,
        TpWeights.defaults,
      );
      expect(prompt, contains('galaxy-s25-ultra'));
      expect(prompt, contains('iphone-16-pro-max'));
      expect(prompt, contains('뭐가 좋아?'));
    });
  });

  group('앞뒤로 물어보기', _fallback);

  // "100만원 이하"를 100달러로 읽어 9만원짜리 폰을 추천하던 버그가 있었다.
  group('예산 읽기', () {
    test('달러는 그대로', () {
      expect(LocalAskService.budgetUsd(r'$900 이하'), 900);
      expect(LocalAskService.budgetUsd('Best camera under \$1,000'), 1000);
    });

    test('만원은 달러로 바꾼다', () {
      expect(LocalAskService.budgetUsd('100만원 이하 카메라 좋은 것'), 714);
      expect(LocalAskService.budgetUsd('70만 원'), 500);
    });

    test('원 단위도 읽는다', () {
      expect(LocalAskService.budgetUsd('1,400,000원 이하'), 1000);
    });

    test('숫자가 없으면 없다', () {
      expect(LocalAskService.budgetUsd('가벼운 거'), isNull);
    });

    // 아무 세 자리 숫자나 예산으로 읽던 때는 저장 용량이 예산이 됐다.
    test('용량과 모델 번호는 예산이 아니다', () {
      expect(LocalAskService.budgetUsd('아이폰 17 Pro 256GB 어때?'), isNull);
      expect(LocalAskService.budgetUsd('Galaxy S25 512GB vs Pixel 10'), isNull);
    });

    test('달러라고 적으면 읽는다', () {
      expect(LocalAskService.budgetUsd('900 달러 이하'), 900);
      expect(LocalAskService.budgetUsd('under 900 dollars'), 900);
      expect(LocalAskService.budgetUsd('900불'), 900);
    });
  });

  group('오프라인 답변', () {
    const service = LocalAskService();

    test('카탈로그가 비면 답이 없다', () async {
      expect(await service.ask('아무거나', const <Smartphone>[]), isNull);
    });

    test('고른 기기는 항상 카탈로그 안에 있다', () async {
      final answer = await service.ask('뭐가 좋아?', _catalog);
      expect(_catalog.map((d) => d.slug), contains(answer!.pickSlug));
    });

    test('명세대로 네 줄을 돌려준다', () async {
      final answer = await service.ask('뭐가 좋아?', _catalog);
      expect(answer!.rows.map((r) => r.label), <String>[
        K.tpIndex.tr(),
        K.spec(SpecKind.price).tr(),
        K.spec(SpecKind.battery).tr(),
        K.spec(SpecKind.camera).tr(),
      ]);
    });
  });
}

/// 모델을 못 부르면 로컬이 받는다.
///
/// 상담 탭이 오래 로컬만 쓰고 있었다. Gemini 를 앞에 두되, 설정이 없거나
/// 네트워크가 없을 때 화면이 실패 말풍선만 띄우면 안 된다.
class _NullAsk implements AskService {
  int calls = 0;

  @override
  Future<AskAnswer?> ask(String question, List<Smartphone> catalog) async {
    calls++;
    return null;
  }
}

class _FixedAsk implements AskService {
  _FixedAsk(this.answer);

  final AskAnswer answer;
  int calls = 0;

  @override
  Future<AskAnswer?> ask(String question, List<Smartphone> catalog) async {
    calls++;
    return answer;
  }
}

void _fallback() {
  test('앞이 답하면 뒤는 안 부른다', () async {
    final primary = _FixedAsk(_answer());
    final fallback = _NullAsk();

    final got = await FallbackAskService(
      primary,
      fallback,
    ).ask('뭐가 좋아', _catalog);

    expect(got?.pick, 'Galaxy S25 Ultra');
    expect(fallback.calls, 0);
  });

  test('앞이 못 답하면 뒤가 받는다', () async {
    final primary = _NullAsk();
    final fallback = _FixedAsk(_answer(slug: 'iphone-16-pro-max'));

    final got = await FallbackAskService(
      primary,
      fallback,
    ).ask('뭐가 좋아', _catalog);

    expect(got?.pickSlug, 'iphone-16-pro-max');
    expect(primary.calls, 1);
  });
}
