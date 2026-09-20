import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/tp_tokens.dart';
import '../../core/error_reporter.dart';
import 'tp_tap_target.dart';

/// 앱 밖으로 나가는 한 줄.
///
/// 출처 표기가 쓰는 줄이다. CC-BY-SA 4.0 은 표기만으로 안 되고 라이선스
/// 본문과 원본에 **닿을 수 있어야** 해서, 이 줄은 반드시 눌려야 한다.
///
/// 상세 화면 안에만 있던 것을 올렸다. 출처 화면이 같은 줄을 쓰는데, 둘이
/// 따로 있으면 한쪽만 링크 색을 잃거나 한쪽만 탭 영역이 작아진다.
class TpLinkLine extends ConsumerWidget {
  const TpLinkLine({
    super.key,
    required this.label,
    required this.url,
    required this.style,
    this.topPadding = 0,
    this.maxLines = 1,
  });

  final String label;

  /// null 이면 누를 수 없는 문구로 떨어진다. 주소가 깨진 출처를 숨기지 않고
  /// 글자는 남기기 위한 것이다 — 귀속은 링크가 죽어도 유지해야 한다.
  final Uri? url;

  final TextStyle style;
  final double topPadding;
  final int maxLines;

  /// 주소에서 사람이 읽을 부분만. 원문 주소는 한 줄을 다 먹는다.
  ///
  /// 보이는 건 도메인, 열리는 것은 원문 그대로다.
  static String hostOf(String url) {
    final parsed = Uri.tryParse(url);
    final host = parsed?.host ?? '';
    return host.isEmpty ? url : host;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tp;
    final target = url;
    // 눌리는 줄은 링크 색으로 둔다. 출처 줄이 본문과 같은 회색이던 때는
    // 눌리는 줄인지 알 방법이 없었다.
    final text = Padding(
      padding: EdgeInsets.only(top: topPadding),
      child: Text(
        label,
        style: target == null ? style : style.copyWith(color: t.link),
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      ),
    );
    if (target == null) return text;

    return Align(
      alignment: Alignment.centerLeft,
      child: TpTapTarget(
        link: true,
        minSize: 44,
        onTap: () => unawaited(_open(ref, target)),
        child: text,
      ),
    );
  }

  Future<void> _open(WidgetRef ref, Uri url) async {
    try {
      await ref.read(linkOpenerProvider).open(url);
    } catch (e, s) {
      // 열 앱이 없는 기기도 있다. 화면은 그대로 둔다.
      TpErrors.record(e, s, reason: 'link.open');
    }
  }
}
