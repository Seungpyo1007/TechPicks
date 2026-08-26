import '../../data/dto/smartphone.dart';

/// 스캔 결과 하나.
class ScanMatch {
  const ScanMatch({required this.device, required this.score});

  final Smartphone device;

  /// 0–1. 높을수록 확신이 크다.
  final double score;
}

/// 카메라가 읽은 글자를 카탈로그의 기기에 맞춘다.
///
/// 명세가 "the OCR result should be matched against the catalogue, not shown
/// raw" 라고 했다. v1 은 모델이 뱉은 문장을 그대로 화면에 찍었다.
abstract final class ScanMatcher {
  /// 이 아래는 맞췄다고 보지 않는다.
  ///
  /// 기기 이름의 절반 이상이 읽힌 글자에 들어 있어야 한다. 더 낮추면
  /// "Galaxy" 만 읽고 아무 삼성 폰이나 집는다.
  static const double threshold = 0.5;

  /// 가장 그럴듯한 기기. 확신이 [threshold] 아래면 null.
  static ScanMatch? match(String recognized, List<Smartphone> catalog) {
    final haystack = _normalize(recognized);
    if (haystack.isEmpty || catalog.isEmpty) return null;

    ScanMatch? best;
    for (final device in catalog) {
      final score = _score(haystack, device);
      if (score > (best?.score ?? 0)) {
        best = ScanMatch(device: device, score: score);
      }
    }
    return best != null && best.score >= threshold ? best : null;
  }

  static double _score(String haystack, Smartphone device) {
    final tokens = _tokens(device);
    if (tokens.isEmpty) return 0;

    // 낱말 단위로 센다. 부분 문자열로 세면 iOS 의 모델 식별자 `iPhone17,3` 이
    // `iphone17` 한 덩어리가 되는데 그 안에서 `iphone` 과 `17` 이 둘 다 잡혀
    // **iPhone 17 이 확신 1.0 으로 걸렸다.** 실제로 내 정보 화면이 iPhone 17
    // Pro 를 iPhone 17 이라고 말하고 있었다.
    final words = haystack.split(' ').toSet();
    var hit = 0;
    for (final token in tokens) {
      if (words.contains(token)) hit++;
    }
    var score = hit / tokens.length;

    // 모델명이 통째로 들어 있으면 확실하다.
    final whole = _normalize(device.name);
    if (whole.isNotEmpty && haystack.contains(whole)) score = 1;

    return score;
  }

  /// 이름을 비교 단위로 쪼갠다. 브랜드는 빼지 않는다 — 뒷면에 같이 찍혀 있다.
  static List<String> _tokens(Smartphone device) {
    final raw = <String>[
      device.name,
      if (device.brand?.name != null) device.brand!.name,
    ].join(' ');
    return _normalize(
      raw,
    ).split(' ').where((t) => t.length >= 2).toSet().toList(growable: false);
  }

  /// 소문자로 낮추고 기호를 공백으로. OCR 이 하이픈이나 점을 흘리는 일이 많다.
  ///
  /// `+` 만 낱말로 남긴다. 기호째 지우면 `Galaxy S25+` 와 `Galaxy S25` 가 같은
  /// 글자가 되어 어느 쪽을 집을지 카탈로그 순서가 정한다.
  static String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('+', ' plus ')
      .replaceAll(RegExp(r'[^a-z0-9가-힣]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
