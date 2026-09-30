import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../app/theme/tp_sys.dart';
import 'tp_figure.dart';

/// 앱의 코드 일러스트. 전부 [TpFigure] 의 `paint` 로 들어간다.
///
/// 모양은 실제 화면 요소를 단순화한 것이다 — 막대는 점수 막대, 칸은 inset
/// grouped 칸, 말풍선은 질문 시트. 새 그림을 배우지 않아도 읽힌다.
abstract final class TpFigures {
  /// 온보딩 1: 점수 다섯 줄이 자라고 숫자 하나로 모인다.
  static void index(Canvas canvas, Size size, double t, TpSys sys) {
    const widths = <double>[.92, .55, .74, .63, .42];
    const bar = 6.0;
    const gap = 13.0;
    final left = size.width * 0.58;
    final top = (size.height - (widths.length * gap)) / 2 + 2;
    final fold = span(t, .55, .8);
    for (var i = 0; i < widths.length; i++) {
      final grow = span(t, .06 * i, .06 * i + .4);
      final y = top + i * gap;
      final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, y, left, bar),
        const Radius.circular(bar / 2),
      );
      canvas.drawRRect(track, Paint()..color = sys.fill);
      final w = left * widths[i] * grow;
      if (w > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, y, w, bar),
            const Radius.circular(bar / 2),
          ),
          Paint()..color = TpSys.accent.withValues(alpha: 1 - .45 * fold),
        );
      }
      // 막대 끝에서 숫자 쪽으로 가는 선. 모이는 동안만 보인다.
      final reach = span(t, .5 + .04 * i, .78 + .04 * i);
      if (reach > 0 && reach < 1) {
        final from = Offset(w, y + bar / 2);
        final to = Offset(size.width * 0.78, size.height / 2);
        canvas.drawLine(
          from,
          Offset.lerp(from, to, reach)!,
          Paint()
            ..color = TpSys.accent.withValues(alpha: .35 * (1 - reach))
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    final n = pop(t, .62, .92);
    if (n > 0) {
      _text(
        canvas,
        '84',
        Offset(size.width * 0.82, size.height / 2),
        size: 52 * n.clamp(0.0, 1.2),
        color: TpSys.accent.withValues(alpha: n.clamp(0.0, 1.0)),
        weight: FontWeight.w700,
      );
    }
  }

  /// 온보딩 2: 두 칸이 올라오고, 줄마다 이긴 쪽에 불이 들어온다.
  static void compare(Canvas canvas, Size size, double t, TpSys sys) {
    const rows = 4;
    final w = (size.width - 12) / 2;
    const r = Radius.circular(18);
    // 줄마다 이긴 쪽. 왼쪽이 셋, 오른쪽이 하나 — 왼쪽이 이긴다.
    const winner = <int>[0, 1, 0, 0];
    for (var c = 0; c < 2; c++) {
      final rise = span(t, .08 * c, .08 * c + .35);
      final x = c * (w + 12);
      final dy = (1 - rise) * 18;
      final col = Rect.fromLTWH(x, dy, w, size.height - 4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(col, r),
        Paint()..color = sys.cell.withValues(alpha: rise),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(col.deflate(.5), r),
        Paint()
          ..style = PaintingStyle.stroke
          ..color = sys.separator.withValues(alpha: rise),
      );
      final rowH = (col.height - 24) / rows;
      for (var i = 0; i < rows; i++) {
        final y = col.top + 12 + i * rowH;
        final line = Rect.fromLTWH(x + 12, y + rowH / 2 - 4, w - 24, 8);
        canvas.drawRRect(
          RRect.fromRectAndRadius(line, const Radius.circular(4)),
          Paint()..color = sys.fill.withValues(alpha: rise),
        );
        if (winner[i] == c) {
          final on = pop(t, .42 + .12 * i, .6 + .12 * i);
          if (on > 0) {
            final lit = Rect.fromLTWH(
              line.left,
              line.top,
              line.width * on.clamp(0.0, 1.0),
              line.height,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(lit, const Radius.circular(4)),
              Paint()..color = TpSys.accent,
            );
          }
        }
      }
    }
    final check = pop(t, .86, 1);
    if (check > 0) {
      final center = Offset(w - 6, 10);
      canvas.drawCircle(center, 11 * check, Paint()..color = TpSys.accent);
      final p = Path()
        ..moveTo(center.dx - 4.5 * check, center.dy)
        ..lineTo(center.dx - 1 * check, center.dy + 3.5 * check)
        ..lineTo(center.dx + 5 * check, center.dy - 3.5 * check);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFFFFFF),
      );
    }
  }

  /// 온보딩 3: 질문이 올라가고, 점 세 개가 뛰고, 답 카드가 펼쳐진다.
  static void ask(Canvas canvas, Size size, double t, TpSys sys) {
    const h = 34.0;
    const r = Radius.circular(17);
    // 질문. 오른쪽에서 들어온다.
    final q = span(t, 0, .25);
    final qw = size.width * .5;
    final qx = size.width - qw + (1 - q) * 40;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(qx, 0, qw, h), r),
      Paint()..color = TpSys.accent.withValues(alpha: q),
    );
    _line(
      canvas,
      Offset(qx + 14, h / 2),
      qw * .6,
      const Color(0xFFFFFFFF).withValues(alpha: .75 * q),
    );

    // 입력 중.
    final typing = span(t, .28, .34) * (1 - span(t, .6, .66));
    if (typing > 0) {
      final box = RRect.fromRectAndRadius(Rect.fromLTWH(0, h + 12, 64, h), r);
      canvas.drawRRect(
        box,
        Paint()..color = sys.cell.withValues(alpha: typing),
      );
      for (var i = 0; i < 3; i++) {
        final phase = (t * 9 - i * .6) * math.pi;
        final lift = math.max(0.0, math.sin(phase)) * 3;
        canvas.drawCircle(
          Offset(18 + i * 14.0, h + 12 + h / 2 - lift),
          3.2,
          Paint()..color = sys.label3.withValues(alpha: typing),
        );
      }
    }

    // 답. 입력 중 자리에서 커진다.
    final a = span(t, .62, .9);
    if (a > 0) {
      final aw = 64 + (size.width * .72 - 64) * a;
      final ah = h + (size.height - h - 12 - h) * a;
      final card = Rect.fromLTWH(0, h + 12, aw, ah);
      canvas.drawRRect(
        RRect.fromRectAndRadius(card, const Radius.circular(20)),
        Paint()..color = sys.cell,
      );
      final lines = <double>[.55, .8, .65];
      for (var i = 0; i < lines.length; i++) {
        final l = span(t, .72 + .07 * i, .9 + .07 * i);
        if (l <= 0) continue;
        _line(
          canvas,
          Offset(card.left + 14, card.top + 16 + i * 14.0),
          (aw - 28) * lines[i] * l,
          i == 0 ? sys.label.withValues(alpha: .8) : sys.fill,
        );
      }
    }
  }

  /// 관심 목록 빈 상태: 빈 칸 세 줄로 폰 두 대가 미끄러져 들어온다.
  static void shortlist(Canvas canvas, Size size, double t, TpSys sys) {
    const rows = 3;
    final rowH = size.height / rows;
    for (var i = 0; i < rows; i++) {
      final y = i * rowH + rowH / 2;
      _dashed(canvas, Offset(44, y), Offset(size.width, y), sys.separator);
    }
    for (var i = 0; i < 2; i++) {
      final s = pop(t, .1 + .2 * i, .55 + .2 * i);
      if (s <= 0) continue;
      final y = i * rowH + rowH / 2;
      final x = 10 + (1 - s) * size.width * .6;
      final phone = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + 12, y), width: 14, height: 21),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        phone,
        Paint()..color = TpSys.accent.withValues(alpha: .12),
      );
      canvas.drawRRect(
        phone,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = TpSys.accent,
      );
      _line(
        canvas,
        Offset(x + 34, y),
        size.width * .35 * s.clamp(0.0, 1.0),
        sys.fill,
      );
    }
  }

  /// 검색 결과 없음: 돋보기가 빈 줄 위를 한 번 쓸고 가운데서 멈춘다.
  static void search(Canvas canvas, Size size, double t, TpSys sys) {
    final mid = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.3 + .2 * i);
      final w = size.width * (.5 - .08 * i);
      _line(canvas, Offset(mid - w / 2, y), w, sys.fill);
    }
    final sweep = span(t, 0, .7, Curves.easeInOut);
    final settle = span(t, .7, 1, Curves.easeOutBack);
    final from = mid - size.width * .28;
    final to = mid + size.width * .22;
    final x = sweep < 1 ? from + (to - from) * sweep : to + (mid - to) * settle;
    final c = Offset(x, size.height * .45);
    canvas.drawCircle(
      c,
      15,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = sys.label3,
    );
    canvas.drawLine(
      c + const Offset(11, 11),
      c + const Offset(20, 20),
      Paint()
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..color = sys.label3,
    );
  }

  /// 카탈로그 오류: 양쪽 선이 이어지려다 가운데 틈에서 멈춘다.
  static void offline(Canvas canvas, Size size, double t, TpSys sys) {
    final y = size.height / 2;
    final mid = size.width / 2;
    final reach = span(t, 0, .6, Curves.easeInOut);
    final back = span(t, .6, .85, Curves.easeOutBack);
    // 틈은 한 번 좁아졌다가 다시 벌어진다.
    final gap = 22 - 14 * reach + 14 * back;
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = sys.label3;
    canvas.drawLine(Offset(mid - 70, y), Offset(mid - gap / 2, y), paint);
    canvas.drawLine(Offset(mid + gap / 2, y), Offset(mid + 70, y), paint);
    final spark = span(t, .55, .65) * (1 - span(t, .7, .9));
    if (spark > 0) {
      canvas.drawCircle(
        Offset(mid, y),
        4 + 4 * spark,
        Paint()..color = sys.destructive.withValues(alpha: .6 * spark),
      );
    }
  }

  /// 온보딩 4·로그인: 폰에서 담은 카드가 노트북으로 건너가고 체크가 뜬다.
  static void sync(Canvas canvas, Size size, double t, TpSys sys) {
    final h = size.height;
    final rise = span(t, 0, .28);
    final dy = (1 - rise) * 16;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = sys.label3.withValues(alpha: rise);
    final face = Paint()..color = sys.cell.withValues(alpha: rise);

    // 폰.
    final phone = Rect.fromLTWH(
      size.width * .1,
      h * .08 + dy,
      h * .46,
      h * .84,
    );
    final phoneR = RRect.fromRectAndRadius(phone, Radius.circular(h * .09));
    canvas.drawRRect(phoneR, face);
    canvas.drawRRect(phoneR, line);

    // 노트북: 화면 + 받침.
    final screenW = size.width * .44;
    final screen = Rect.fromLTWH(
      size.width * .9 - screenW,
      h * .16 + dy * .6,
      screenW,
      h * .56,
    );
    final screenR = RRect.fromRectAndRadius(screen, Radius.circular(h * .05));
    canvas.drawRRect(screenR, face);
    canvas.drawRRect(screenR, line);
    final base = Path()
      ..moveTo(screen.left - h * .06, screen.bottom + h * .1)
      ..lineTo(screen.right + h * .06, screen.bottom + h * .1)
      ..lineTo(screen.right, screen.bottom + h * .02)
      ..lineTo(screen.left, screen.bottom + h * .02)
      ..close();
    canvas.drawPath(base, face);
    canvas.drawPath(base, line);

    // 폰 안의 목록 세 줄. 첫 줄이 카드가 되어 떠난다.
    for (var i = 0; i < 3; i++) {
      final y = phone.top + phone.height * (.28 + i * .2);
      _line(
        canvas,
        Offset(phone.left + phone.width * .18, y),
        phone.width * (i == 0 ? .64 : .5) * rise,
        i == 0 ? TpSys.accent.withValues(alpha: rise) : sys.fill,
      );
    }

    // 건너가는 길. 점선이 먼저 그어진다.
    final from = Offset(phone.right + 6, phone.top + phone.height * .28);
    final to = Offset(
      screen.left + screen.width * .5,
      screen.top + screen.height * .38,
    );
    final top = Offset((from.dx + to.dx) / 2, h * .02);
    Offset arc(double k) {
      final a = Offset.lerp(from, top, k)!;
      final b = Offset.lerp(top, to, k)!;
      return Offset.lerp(a, b, k)!;
    }

    final trail = span(t, .26, .5);
    if (trail > 0) {
      final dash = Paint()
        ..strokeWidth = 1.4
        ..color = TpSys.accent.withValues(alpha: .35);
      const steps = 22;
      for (var i = 0; i < steps * trail; i += 2) {
        canvas.drawLine(
          arc(i / steps),
          arc(math.min(i + 1, steps) / steps),
          dash,
        );
      }
    }

    // 카드: 뜨고, 호를 따라 건너고, 노트북 화면 안에 내려앉는다.
    final fly = span(t, .34, .74, Curves.easeInOutCubic);
    final land = span(t, .72, .82);
    if (fly > 0) {
      final at = arc(fly);
      final w = phone.width * .7 * (1 + .25 * math.sin(fly * math.pi));
      final card = Rect.fromCenter(center: at, width: w, height: h * .13);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          card.shift(const Offset(0, 4)),
          Radius.circular(h * .04),
        ),
        Paint()..color = const Color(0x22000000),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(card, Radius.circular(h * .04)),
        Paint()..color = TpSys.accent,
      );
      _line(
        canvas,
        Offset(card.left + card.width * .14, card.center.dy),
        card.width * .5,
        const Color(0xCCFFFFFF),
      );
    }

    // 내려앉은 뒤 노트북 목록이 채워진다.
    if (land > 0) {
      for (var i = 0; i < 2; i++) {
        final y = screen.top + screen.height * (.62 + i * .2);
        _line(
          canvas,
          Offset(screen.left + screen.width * .14, y),
          screen.width * (.6 - i * .15) * span(t, .76 + .05 * i, .9 + .05 * i),
          sys.fill,
        );
      }
    }

    final check = pop(t, .84, 1);
    if (check > 0) {
      final c = Offset(screen.right - 4, screen.top + 4);
      canvas.drawCircle(c, h * .085 * check, Paint()..color = TpSys.accent);
      final k = h * .085 * check;
      final p = Path()
        ..moveTo(c.dx - k * .42, c.dy)
        ..lineTo(c.dx - k * .1, c.dy + k * .32)
        ..lineTo(c.dx + k * .45, c.dy - k * .32);
      canvas.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = const Color(0xFFFFFFFF),
      );
    }
  }

  static void _line(Canvas canvas, Offset start, double width, Color color) {
    if (width <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(start.dx, start.dy - 4, width, 8),
        const Radius.circular(4),
      ),
      Paint()..color = color,
    );
  }

  static void _dashed(Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..strokeWidth = 1.2
      ..color = color;
    const dash = 6.0;
    final len = (b - a).distance;
    final dir = (b - a) / len;
    for (var d = 0.0; d < len; d += dash * 2) {
      canvas.drawLine(a + dir * d, a + dir * math.min(d + dash, len), paint);
    }
  }

  static void _text(
    Canvas canvas,
    String text,
    Offset center, {
    required double size,
    required Color color,
    FontWeight weight = FontWeight.w600,
  }) {
    if (size <= 0) return;
    final p = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: size,
          fontWeight: weight,
          color: color,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    p.paint(canvas, center - Offset(p.width / 2, p.height / 2));
    p.dispose();
  }
}
