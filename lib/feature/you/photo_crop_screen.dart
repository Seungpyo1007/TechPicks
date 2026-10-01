import 'dart:async' show Completer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../../shared/brand/tp_logo.dart';
import '../../app/theme/tp_sys.dart';
import '../../app/theme/tp_tokens.dart';
import '../../core/error_reporter.dart';
import '../../shared/copy_keys.dart';
import '../../shared/widgets/tp_group.dart';

/// 프로필 사진 자르기. 두 플랫폼이 같은 Flutter 화면 하나를 쓴다.
///
/// 원 안에 들어온 부분을 512px 정사각 JPEG(품질 85)로 돌려준다. 그만두면
/// null. EXIF 회전은 먼저 굽고 버린다 — 안 그러면 세로 사진이 눕는다.
class PhotoCropScreen extends StatefulWidget {
  const PhotoCropScreen({super.key, required this.bytes});

  /// 카메라·선택기가 준 원본.
  final Uint8List bytes;

  /// 결과 한 변.
  static const int size = 512;
  static const int quality = 85;

  /// 원 좌우 여백 합. 402 폭에서 원이 362.
  static const double inset = 40;

  @override
  State<PhotoCropScreen> createState() => _PhotoCropScreenState();
}

/// 회전을 구운 픽셀. 화면 그림과 자르기가 같은 좌표를 쓴다.
typedef _Pixels = ({int width, int height, Uint8List rgba});

class _PhotoCropScreenState extends State<PhotoCropScreen> {
  final TransformationController _t = TransformationController();
  _Pixels? _pixels;
  ui.Image? _image;
  bool _failed = false;
  bool _busy = false;

  /// 원을 꽉 채우는 배율과 그때의 변환. 되돌리기가 여기로 간다.
  double _minScale = 1;
  Matrix4? _initial;
  Size? _laidOut;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pixels = await compute(_decode, widget.bytes);
      if (pixels == null) throw const FormatException('decode');
      final image = await _toUiImage(pixels);
      if (!mounted) {
        image.dispose();
        return;
      }
      setState(() {
        _pixels = pixels;
        _image = image;
      });
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.crop');
      if (mounted) setState(() => _failed = true);
    }
  }

  static Future<ui.Image> _toUiImage(_Pixels p) {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      p.rgba,
      p.width,
      p.height,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }

  @override
  void dispose() {
    _t.dispose();
    _image?.dispose();
    super.dispose();
  }

  /// 화면 크기가 정해지면 원을 꽉 채우고 가운데 둔다.
  void _fit(Size viewport) {
    final image = _image;
    if (image == null || _laidOut == viewport) return;
    _laidOut = viewport;
    final d = _diameter(viewport);
    final w = image.width.toDouble();
    final h = image.height.toDouble();
    _minScale = d / math.min(w, h);
    final dx = (viewport.width - w * _minScale) / 2;
    final dy = (viewport.height - h * _minScale) / 2;
    _initial = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(_minScale, _minScale, 1, 1);
    _t.value = _initial!.clone();
  }

  static double _diameter(Size viewport) => math.max(
    0,
    math.min(viewport.width - PhotoCropScreen.inset, viewport.height - 40),
  );

  void _reset() {
    if (_initial != null) _t.value = _initial!.clone();
  }

  Future<void> _choose() async {
    final pixels = _pixels;
    final viewport = _laidOut;
    if (pixels == null || viewport == null || _busy) return;
    setState(() => _busy = true);
    final d = _diameter(viewport);
    final square = Rect.fromCenter(
      center: viewport.center(Offset.zero),
      width: d,
      height: d,
    );
    final a = _t.toScene(square.topLeft);
    final b = _t.toScene(square.bottomRight);
    final crop = Rect.fromPoints(
      a,
      b,
    ).intersect(Offset.zero & Size(pixels.width * 1.0, pixels.height * 1.0));
    try {
      final jpeg = await compute(_encode, (pixels: pixels, crop: crop));
      if (mounted) Navigator.of(context).pop(jpeg);
    } catch (e, s) {
      TpErrors.record(e, s, reason: 'profile.crop');
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final glass = context.tp.isGlass;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final image = _image;

    final stage = LayoutBuilder(
      builder: (context, box) {
        final viewport = box.biggest;
        if (image == null) {
          return Center(
            child: _failed
                ? Text(
                    K.photoFailed.tr(),
                    style: const TextStyle(color: Colors.white),
                  )
                : const TpLogoLoader.mono(
                    size: 32,
                    mono: Colors.white,
                    knob: Colors.black,
                  ),
          );
        }
        _fit(viewport);
        final d = _diameter(viewport);
        final margin = EdgeInsets.symmetric(
          horizontal: (viewport.width - d) / 2,
          vertical: (viewport.height - d) / 2,
        );
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 원을 넘지 않는 데까지만 끌린다. 여백이 곧 원 바깥이다.
            InteractiveViewer(
              transformationController: _t,
              constrained: false,
              minScale: _minScale,
              maxScale: _minScale * 6,
              boundaryMargin: margin,
              clipBehavior: Clip.none,
              child: SizedBox(
                width: image.width.toDouble(),
                height: image.height.toDouble(),
                child: RawImage(image: image, fit: BoxFit.fill),
              ),
            ),
            IgnorePointer(
              child: CustomPaint(painter: _CircleMask(diameter: d)),
            ),
          ],
        );
      },
    );

    final choose = _Pill(
      label: glass ? K.cropChoose.tr() : K.done.tr(),
      filled: true,
      onTap: image == null || _busy ? null : _choose,
    );

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      child: ColoredBox(
        color: Colors.black,
        child: Column(
          children: <Widget>[
            SizedBox(height: top),
            if (glass)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 20),
                child: Column(
                  children: <Widget>[
                    Semantics(
                      header: true,
                      child: Text(
                        K.moveAndScale.tr(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      K.moveAndScaleHint.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0x99FFFFFF),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 64,
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 4),
                    IconButton(
                      tooltip: K.cancel.tr(),
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          K.moveAndScale.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    choose,
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            Expanded(child: ClipRect(child: stage)),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, bottom + 16),
              child: glass
                  ? Row(
                      children: <Widget>[
                        _Pill(
                          label: K.cancel.tr(),
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        _RoundButton(
                          label: K.reset.tr(),
                          icon: CupertinoIcons.arrow_counterclockwise,
                          onTap: _reset,
                        ),
                        const Spacer(),
                        choose,
                      ],
                    )
                  : Center(
                      child: _Pill(label: K.reset.tr(), onTap: _reset),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 원 바깥을 어둡게, 가장자리에 가는 흰 선.
class _CircleMask extends CustomPainter {
  const _CircleMask({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: diameter,
      height: diameter,
    );
    final shade = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(circle);
    canvas.drawPath(shade, Paint()..color = const Color(0x99000000));
    canvas.drawOval(
      circle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xCCFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_CircleMask old) => old.diameter != diameter;
}

/// 검은 바탕 위 알약 버튼. 채우면 액센트.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap, this.filled = false});

  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onTap != null,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: TpTappable(
      onTap: onTap,
      press: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44, minWidth: 64),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? TpSys.accent.withValues(alpha: onTap == null ? .5 : 1)
              : const Color(0x33FFFFFF),
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}

/// 되돌리기 원 버튼.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    onTap: onTap,
    child: TpTappable(
      onTap: onTap,
      press: true,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: Color(0x33FFFFFF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    ),
  );
}

/// 원본을 풀고 EXIF 회전을 굽는다. 화면과 자르기가 같은 좌표를 쓰게.
///
/// 카메라 원본은 4000px 이 넘는다. 긴 변 2048 로 먼저 줄여 둔다 — 결과는
/// 512 라 모자라지 않다.
_Pixels? _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var baked = img.bakeOrientation(decoded);
  const cap = 2048;
  if (math.max(baked.width, baked.height) > cap) {
    baked = baked.width >= baked.height
        ? img.copyResize(baked, width: cap)
        : img.copyResize(baked, height: cap);
  }
  final rgba = baked.convert(numChannels: 4);
  return (
    width: rgba.width,
    height: rgba.height,
    rgba: rgba.getBytes(order: img.ChannelOrder.rgba),
  );
}

/// 원 안의 정사각을 512 JPEG 로.
Uint8List _encode(({_Pixels pixels, Rect crop}) job) {
  final p = job.pixels;
  final source = img.Image.fromBytes(
    width: p.width,
    height: p.height,
    bytes: p.rgba.buffer,
    numChannels: 4,
  );
  final r = job.crop;
  final side = math.max(1, math.min(r.width, r.height).round());
  final cut = img.copyCrop(
    source,
    x: r.left.round().clamp(0, p.width - 1),
    y: r.top.round().clamp(0, p.height - 1),
    width: side,
    height: side,
  );
  final out = img.copyResize(
    cut,
    width: PhotoCropScreen.size,
    height: PhotoCropScreen.size,
    interpolation: img.Interpolation.cubic,
  );
  return img.encodeJpg(out, quality: PhotoCropScreen.quality);
}
