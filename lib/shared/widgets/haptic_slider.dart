import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/haptics_service.dart';
import '../utils/ui_actions.dart';

/// A [Slider] that gives one short tactile tick per discrete step.
///
/// Continuous sliders (no [divisions]) are throttled so dragging still feels
/// responsive without flooding the haptic hardware.
class HapticSlider extends ConsumerStatefulWidget {
  const HapticSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticFormatterCallback,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;
  final String Function(double)? semanticFormatterCallback;

  @override
  ConsumerState<HapticSlider> createState() => _HapticSliderState();
}

class _HapticSliderState extends ConsumerState<HapticSlider> {
  static const _continuousInterval = Duration(milliseconds: 60);

  int? _lastStep;
  DateTime? _lastContinuousTick;

  int? _stepFor(double value) {
    final divisions = widget.divisions;
    if (divisions == null || divisions <= 0) return null;
    final span = widget.max - widget.min;
    if (span <= 0) return 0;
    return (((value - widget.min) / span) * divisions).round();
  }

  void _handleStart(double value) {
    _lastStep = _stepFor(value);
    _lastContinuousTick = null;
    widget.onChangeStart?.call(value);
  }

  void _handleChanged(double value) {
    final step = _stepFor(value);
    if (step != null) {
      if (step != _lastStep) {
        _lastStep = step;
        unawaited(triggerHaptic(ref, cue: HapticCue.selection));
      }
    } else {
      final now = DateTime.now();
      final previous = _lastContinuousTick;
      if (previous == null || now.difference(previous) >= _continuousInterval) {
        _lastContinuousTick = now;
        unawaited(triggerHaptic(ref, cue: HapticCue.selection));
      }
    }
    widget.onChanged(value);
  }

  void _handleEnd(double value) {
    _lastStep = null;
    _lastContinuousTick = null;
    widget.onChangeEnd?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    return Slider(
      value: widget.value,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
      label: widget.label,
      semanticFormatterCallback: widget.semanticFormatterCallback,
      onChangeStart: _handleStart,
      onChanged: _handleChanged,
      onChangeEnd: _handleEnd,
    );
  }
}
