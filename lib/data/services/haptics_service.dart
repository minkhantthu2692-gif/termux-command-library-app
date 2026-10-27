import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../app/settings/app_settings.dart';

/// The semantic reason for a haptic cue.
///
/// Cues have distinct rhythms, so a light selection tick is distinguishable
/// from a completed action or a failure even at the same intensity.
enum HapticCue { selection, tap, toggle, success, warning, error }

/// A platform-agnostic vibration pattern in Android waveform format.
///
/// [timings] alternates off/on durations and starts with an off segment.
/// [amplitudes] has the same length as [timings]; off segments use zero.
@immutable
class HapticPattern {
  const HapticPattern({required this.timings, required this.amplitudes});

  final List<int> timings;
  final List<int> amplitudes;

  bool get isEmpty => timings.isEmpty || amplitudes.isEmpty;
}

/// Maps the user's vibration preference to platform haptic feedback.
///
/// Android receives an explicit waveform over a small native channel so the
/// Light/Medium/Strong choice changes both duration and amplitude. Devices
/// without amplitude control still get the duration differences. Other
/// platforms, and tests without a channel handler, fall back to Flutter's
/// standard haptic API. Haptics are always best-effort and never block or
/// fail the action that triggered them.
class HapticsService {
  const HapticsService();

  static const _channel = MethodChannel('dev.termuxlibrary/haptics');

  /// Builds the waveform for [intensity] and [cue].
  ///
  /// Kept pure so the feel of each level is testable without a device.
  static HapticPattern patternFor(VibrationIntensity intensity, HapticCue cue) {
    if (intensity == VibrationIntensity.off) {
      return const HapticPattern(timings: [], amplitudes: []);
    }

    final (baseDuration, gap, pulses) = switch (cue) {
      HapticCue.selection => (9, 0, 1),
      HapticCue.tap => (13, 0, 1),
      HapticCue.toggle => (17, 0, 1),
      HapticCue.success => (12, 45, 2),
      HapticCue.warning => (22, 50, 2),
      HapticCue.error => (18, 40, 3),
    };
    final (scale, amplitude) = switch (intensity) {
      VibrationIntensity.off => (0.0, 0),
      VibrationIntensity.light => (0.7, 70),
      VibrationIntensity.medium => (1.0, 150),
      VibrationIntensity.strong => (1.5, 255),
    };

    final onDuration = math.max(4, (baseDuration * scale).round());
    final offDuration = math.max(0, (gap * scale).round());
    final timings = <int>[];
    final amplitudes = <int>[];
    for (var pulse = 0; pulse < pulses; pulse++) {
      timings
        ..add(pulse == 0 ? 0 : offDuration)
        ..add(onDuration);
      amplitudes
        ..add(0)
        ..add(amplitude);
    }
    return HapticPattern(
      timings: List.unmodifiable(timings),
      amplitudes: List.unmodifiable(amplitudes),
    );
  }

  Future<void> trigger(
    VibrationIntensity intensity, {
    HapticCue cue = HapticCue.tap,
  }) async {
    final pattern = patternFor(intensity, cue);
    if (pattern.isEmpty) return;
    try {
      await _channel.invokeMethod<void>('perform', {
        'timings': pattern.timings,
        'amplitudes': pattern.amplitudes,
      });
    } on MissingPluginException {
      await _fallback(intensity, cue);
    } on PlatformException {
      await _fallback(intensity, cue);
    } catch (_) {
      // A channel or codec failure must never surface as an app error.
      await _fallback(intensity, cue);
    }
  }

  /// Used on non-Android platforms and in tests. The native Android path is
  /// preferred because standard haptic constants vary wildly across devices.
  Future<void> _fallback(VibrationIntensity intensity, HapticCue cue) async {
    try {
      switch (intensity) {
        case VibrationIntensity.off:
          return;
        case VibrationIntensity.light:
          await HapticFeedback.selectionClick();
        case VibrationIntensity.medium:
          if (cue == HapticCue.selection ||
              cue == HapticCue.tap ||
              cue == HapticCue.toggle) {
            await HapticFeedback.lightImpact();
          } else {
            await HapticFeedback.mediumImpact();
          }
        case VibrationIntensity.strong:
          if (cue == HapticCue.warning || cue == HapticCue.error) {
            await HapticFeedback.vibrate();
          } else if (cue == HapticCue.success || cue == HapticCue.toggle) {
            await HapticFeedback.heavyImpact();
          } else {
            await HapticFeedback.mediumImpact();
          }
      }
    } catch (_) {
      // Haptic hardware is optional; never surface its failure.
    }
  }
}
