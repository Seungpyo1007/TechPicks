import 'package:shared_preferences/shared_preferences.dart';

import '../../core/error_reporter.dart';
import '../../core/network/tech_api_client.dart';
import '../../domain/model/tp_money.dart';

/// USD → KRW 환율을 구해온다.
///
/// 3단으로 떨어진다.
///
/// 1. 하루 안에 받은 값이 저장돼 있으면 그걸 쓴다.
/// 2. 낡았으면 받아 본다. 받으면 저장하고 그걸 쓴다.
/// 3. 못 받으면 저장된 낡은 값, 그것도 없으면 컴파일에 박힌 값.
///
/// **네트워크를 첫 프레임에 걸지 않는다.** 화면은 [FxRate.fallback] 으로
/// 먼저 그리고, 받아지면 갈아끼운다. 가격이 한 번 바뀌어 보이는 것이
/// 로딩 스피너보다 낫다 — 값이 없는 게 아니라 덜 정확할 뿐이다.
abstract class FxService {
  Future<FxRate> read();
}

/// 키 없는 공개 환율 API.
///
/// `open.er-api.com` 은 키가 없고 하루 한 번 갱신한다. MSRP 자체가
/// 근사치라 분 단위 정확도는 의미가 없다.
class ErApiFxService implements FxService {
  ErApiFxService({TechApiClient? client, SharedPreferences? prefs})
    : _client = client ?? TechApiClient(),
      _prefs = prefs;

  static final Uri endpoint = Uri.parse(
    'https://open.er-api.com/v6/latest/USD',
  );

  /// 저장 키. 다른 저장값들과 같은 상자를 쓴다.
  static const String rateKey = 'usd_krw';
  static const String asOfKey = 'usd_krw_at';

  final TechApiClient _client;
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _store async =>
      _prefs ??= await SharedPreferences.getInstance();

  @override
  Future<FxRate> read() async {
    final stored = await _stored();
    final now = DateTime.now().toUtc();

    // 하루 안의 값이면 더 볼 것 없다.
    if (stored != null && !stored.staleAt(now)) return stored;

    final fetched = await _fetch(now);
    if (fetched != null) {
      await _save(fetched);
      return fetched;
    }

    // 못 받았다. 낡았어도 저장된 값이 박아둔 상수보다 가깝다.
    return stored ?? FxRate.fallback;
  }

  Future<FxRate?> _stored() async {
    try {
      final prefs = await _store;
      final rate = prefs.getDouble(rateKey);
      final at = prefs.getInt(asOfKey);
      if (rate == null || at == null || rate <= 0) return null;
      return FxRate(
        krwPerUsd: rate,
        asOf: DateTime.fromMillisecondsSinceEpoch(at, isUtc: true),
        origin: RateOrigin.cached,
      );
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'fx.stored');
      return null;
    }
  }

  Future<FxRate?> _fetch(DateTime now) async {
    try {
      final json = await _client.getJson(endpoint);
      final rates = json['rates'];
      if (rates is! Map) return null;
      final krw = (rates['KRW'] as num?)?.toDouble();
      // 0 이나 음수가 오면 화면이 전부 ₩0 이 된다. 안 쓰는 게 낫다.
      if (krw == null || krw <= 0) return null;
      return FxRate(krwPerUsd: krw, asOf: now, origin: RateOrigin.live);
    } catch (e, s) {
      // 인터넷이 없는 것은 고장이 아니다. 조용히 아래 단계로 떨어진다.
      TpErrors.record(e, s, reason: 'fx.fetch');
      return null;
    }
  }

  Future<void> _save(FxRate rate) async {
    try {
      final prefs = await _store;
      await prefs.setDouble(rateKey, rate.krwPerUsd);
      await prefs.setInt(asOfKey, rate.asOf.millisecondsSinceEpoch);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'fx.save');
    }
  }
}
