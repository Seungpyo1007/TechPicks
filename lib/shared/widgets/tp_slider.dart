import 'package:flutter/material.dart';

import '../../app/theme/tp_tokens.dart';
import '../tp_haptics.dart';

/// 모양과 눈금 햅틱을 통일한 Material 슬라이더.
class TpSlider extends StatefulWidget {
  const TpSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.semanticFormatterCallback,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final SemanticFormatterCallback? semanticFormatterCallback;

  @override
  State<TpSlider> createState() => _TpSliderState();
}

class _TpSliderState extends State<TpSlider> {
  int? _lastDivision;

  @override
  void initState() {
    super.initState();
    _lastDivision = _divisionFor(widget.value);
  }

  int? _divisionFor(double value) {
    final divisions = widget.divisions;
    if (divisions == null || divisions <= 0 || widget.max <= widget.min) {
      return null;
    }
    return ((value - widget.min) / (widget.max - widget.min) * divisions)
        .round();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tp;
    final divisions = widget.divisions;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: t.isGlass ? 2 : 4,
        activeTrackColor: t.isGlass ? t.link : null,
        inactiveTrackColor: t.track,
        thumbColor: Colors.white,
        thumbShape: t.isGlass
            ? const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 3)
            : null,
        overlayShape: SliderComponentShape.noOverlay,
        showValueIndicator: ShowValueIndicator.never,
        tickMarkShape: SliderTickMarkShape.noTickMark,
      ),
      child: Slider(
        value: widget.value.clamp(widget.min, widget.max),
        min: widget.min,
        max: widget.max,
        divisions: divisions,
        label: widget.label,
        semanticFormatterCallback: widget.semanticFormatterCallback,
        onChanged: (value) {
          if (divisions != null && divisions > 0) {
            final division = _divisionFor(value)!;
            if (_lastDivision != null && division != _lastDivision) {
              TpHaptics.selection();
            }
            _lastDivision = division;
          }
          widget.onChanged(value);
        },
      ),
    );
  }
}
