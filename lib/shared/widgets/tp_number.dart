import 'package:flutter/widgets.dart';

import '../../app/theme/tp_motion.dart';
import 'tp_arrive.dart';

/// 바뀐 자리만 굴러가는 숫자. SwiftUI 의 `.contentTransition(.numericText())`.
///
/// 값이 커지면 새 숫자가 아래에서 올라오고, 작아지면 위에서 내려온다. 가만히
/// 있을 때는 평범한 [Text] 하나다 — 스크린 리더와 테스트는 차이를 모른다.
///
/// [text] 는 이미 모양을 갖춘 글자다(`74`, `$899`, `35%`). 자리는 오른쪽
/// 끝부터 맞춘다. 숫자 폭이 흔들리지 않게 tabular figures 를 강제한다.
class TpNumber extends StatefulWidget {
  const TpNumber(
    this.text, {
    super.key,
    required this.style,
    this.textAlign,
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final TextAlign? textAlign;
  final int? maxLines;

  @override
  State<TpNumber> createState() => _TpNumberState();
}

class _TpNumberState extends State<TpNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(
    vsync: this,
  );

  late String _from = widget.text;
  late String _to = widget.text;

  /// 값이 커졌는가. 굴러가는 방향.
  bool _up = true;

  DateTime? _arrived;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 나타나면 같은 자릿수의 0 에서 굴러 올라온다.
    final at = TpArriveScope.freshOf(context);
    if (at == null || at == _arrived) return;
    _arrived = at;
    final zeros = widget.text.replaceAll(RegExp('[0-9]'), '0');
    if (zeros == widget.text) return;
    _from = zeros;
    _to = widget.text;
    _up = true;
    _c
      ..value = 0
      ..animateWith(context.motion.smooth.createSimulation());
  }

  @override
  void didUpdateWidget(TpNumber old) {
    super.didUpdateWidget(old);
    if (widget.text == _to) return;
    // 도는 중에 또 바뀌면(슬라이더) 지금 목표에서 새로 출발한다.
    _from = _to;
    _to = widget.text;
    final a = _valueOf(_from);
    final b = _valueOf(_to);
    _up = a == null || b == null || b >= a;
    _c
      ..value = 0
      ..animateWith(context.motion.smooth.createSimulation());
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  static double? _valueOf(String s) =>
      double.tryParse(s.replaceAll(RegExp(r'[^0-9.\-]'), ''));

  TextStyle get _style => widget.style.copyWith(
    fontFeatures: <FontFeature>[
      ...?widget.style.fontFeatures,
      const FontFeature.tabularFigures(),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final still = Text(
      _to,
      style: style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        if (_from == _to || !_c.isAnimating || t >= 1) return still;
        return Semantics(
          label: _to,
          excludeSemantics: true,
          child: _Rolling(from: _from, to: _to, t: t, up: _up, style: style),
        );
      },
    );
  }
}

/// 도는 중의 한 장면. 오른쪽 끝부터 자리를 맞춰 바뀐 자리만 굴린다.
class _Rolling extends StatelessWidget {
  const _Rolling({
    required this.from,
    required this.to,
    required this.t,
    required this.up,
    required this.style,
  });

  final String from;
  final String to;
  final double t;
  final bool up;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final a = from.characters.toList();
    final b = to.characters.toList();
    final n = a.length > b.length ? a.length : b.length;
    String at(List<String> s, int i) {
      final k = i - (n - s.length);
      return k < 0 ? '' : s[k];
    }

    // 나가는 쪽은 자기 높이만큼 밀려나고 들어오는 쪽은 반대편에서 온다.
    final out = up ? -t : t;
    final into = up ? 1 - t : t - 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (var i = 0; i < n; i++)
          if (at(a, i) == at(b, i))
            Text(at(b, i), style: style)
          else
            ClipRect(
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // 들어오는 글자가 자리 크기를 정한다. 빈 자리면 폭이 0 이다.
                  FractionalTranslation(
                    translation: Offset(0, into),
                    child: Opacity(
                      opacity: t.clamp(0.0, 1.0),
                      child: Text(at(b, i), style: style),
                    ),
                  ),
                  if (at(a, i).isNotEmpty)
                    Positioned.fill(
                      child: FractionalTranslation(
                        translation: Offset(0, out),
                        child: Opacity(
                          opacity: (1 - t).clamp(0.0, 1.0),
                          child: Center(
                            child: Text(
                              at(a, i),
                              style: style,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
      ],
    );
  }
}
