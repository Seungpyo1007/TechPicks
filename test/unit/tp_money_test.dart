import 'package:flutter_test/flutter_test.dart';
import 'package:techpicks/domain/model/device_specs.dart';
import 'package:techpicks/domain/model/tp_money.dart';
import 'package:techpicks/domain/model/tp_weights.dart';

import '../support/harness.dart';

/// 고정 환율. 테스트가 시계나 네트워크를 안 본다.
final _rate = FxRate(
  krwPerUsd: 1373,
  asOf: DateTime.utc(2026, 9, 19),
  origin: RateOrigin.live,
);

void main() {
  group('표시', () {
    test('달러는 예전과 글자 하나 안 다르다', () {
      // 기존 골든 서른 장이 이 형식에 물려 있다.
      const money = TpMoney.usd();

      expect(money.format(599), r'$599');
      expect(money.format(1299), r'$1,299');
      expect(money.format(1000000), r'$1,000,000');
      expect(money.format(null), TpMoney.empty);
    });

    test('DeviceSpecs.formatPrice 와 같은 결과다', () {
      // 두 길이 갈라지면 한 화면에 두 형식이 생긴다.
      const money = TpMoney.usd();
      for (final usd in <int?>[null, 0, 599, 1299, 1000000]) {
        expect(money.format(usd), DeviceSpecs.formatPrice(usd), reason: '$usd');
      }
    });

    test('원화는 환산하고 원 단위로 반올림한다', () {
      final money = TpMoney.krw(_rate);

      expect(money.format(799), '₩1,097,027');
      expect(money.format(null), TpMoney.empty);
    });

    test('원화에는 소수점이 없다', () {
      final money = TpMoney.krw(_rate);

      expect(money.format(1), isNot(contains('.')));
      expect(money.format(1299), isNot(contains('.')));
    });
  });

  group('환율', () {
    test('하루가 지나면 낡은 것으로 본다', () {
      final now = DateTime.utc(2026, 9, 21);

      expect(
        FxRate(
          krwPerUsd: 1300,
          asOf: now.subtract(const Duration(hours: 23)),
          origin: RateOrigin.live,
        ).staleAt(now),
        isFalse,
      );
      expect(
        FxRate(
          krwPerUsd: 1300,
          asOf: now.subtract(const Duration(days: 2)),
          origin: RateOrigin.cached,
        ).staleAt(now),
        isTrue,
      );
    });

    test('박아둔 값은 날짜를 들고 있다', () {
      // 화면이 "언제 기준"인지 말할 수 있어야 하고, 이 상수가 낡았다는
      // 것도 그 날짜로 드러난다.
      expect(FxRate.fallback.origin, RateOrigin.fallback);
      expect(FxRate.fallback.krwPerUsd, greaterThan(0));
      expect(FxRate.fallback.asOf.year, greaterThanOrEqualTo(2026));
    });
  });

  group('모델은 USD 로 남는다', () {
    test('환산해도 비교 대상 수치는 안 바뀐다', () {
      // 환율이 움직여도 어느 쪽이 싼지는 안 바뀌어야 한다. 화면 글자만
      // 바뀌고 comparable 은 USD 그대로여야 한다.
      final phone = readCatalog().smartphones.firstWhere(
        (d) => d.msrpUsd != null,
      );

      DeviceSpec priceWith(TpMoney money) => DeviceSpecs.of(
        phone,
        TpWeights.defaults,
        money,
      ).firstWhere((s) => s.kind == SpecKind.price);

      final usd = priceWith(const TpMoney.usd());
      final krw = priceWith(TpMoney.krw(_rate));

      expect(usd.comparable, krw.comparable);
      expect(usd.value, isNot(krw.value));
      expect(krw.value, startsWith('₩'));
    });
  });
}
