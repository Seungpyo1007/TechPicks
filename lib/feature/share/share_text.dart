import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../shared/copy_keys.dart';
import 'tp_link.dart';

/// 공유 시트에 실어 보낼 문구.
///
/// 명세에 공유 문구가 없다. 화면이 이미 말하고 있는 것 — 이름, 지수,
/// 한 줄 근거 — 을 그대로 옮기고 링크를 붙인다.
///
/// 줄을 코드에서 잇는 이유는 지수가 없는 기기 때문이다. 번역 파일에
/// `\n` 을 넣어두면 그런 기기에서 "TP Index —" 같은 빈 줄이 남는다.
abstract final class ShareText {
  /// 기기 하나. 상세 화면이 쓴다.
  static String device({
    required String name,
    required int? index,
    required String slug,
  }) => _lines(name: name, index: index, slug: slug);

  /// 결론 카드. 근거 한 줄이 더 붙는다.
  static String verdict({
    required String name,
    required int? index,
    required String reason,
    required String slug,
  }) => _lines(name: name, index: index, slug: slug, reason: reason);

  /// 메일처럼 제목이 있는 앱만 쓴다.
  static String subject(String name) => K.shareSubject.tr(args: <String>[name]);

  static String _lines({
    required String name,
    required int? index,
    required String slug,
    String? reason,
  }) => <String>[
    if (index == null)
      name
    else
      K.shareDevice.tr(args: <String>[name, '$index']),
    ?reason,
    link(DeviceTarget(slug)),
  ].join('\n');

  /// 문구 마지막 줄에 붙는 링크.
  ///
  /// 커스텀 스킴은 앱이 깔린 기기에서만 열린다. 브라우저에 붙여넣으면 그냥
  /// 죽은 글자였다 — 지금 보고 있는 곳의 주소로 내보낸다. 도메인을 안 사도
  /// 프리뷰 배포에서 바로 동작한다.
  static String link(TpLinkTarget target) => kIsWeb
      ? '\${Uri.base.origin}\${TpLink.path(target)}'
      : switch (target) {
          DeviceTarget(:final slug) => TpLink.device(slug).toString(),
          CompareTarget(:final a, :final b) => TpLink.compare(a, b).toString(),
        };
}
