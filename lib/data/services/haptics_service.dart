import 'package:flutter/services.dart';

import '../../app/settings/app_settings.dart';

/// Maps the user's vibration preference to platform haptic feedback. Devices
/// may ignore haptics; the app never relies on them for confirmation.
class HapticsService {
  const HapticsService();

  Future<void> trigger(VibrationIntensity intensity) async {
    switch (intensity) {
      case VibrationIntensity.off:
        return;
      case VibrationIntensity.light:
        await HapticFeedback.selectionClick();
      case VibrationIntensity.medium:
        await HapticFeedback.lightImpact();
      case VibrationIntensity.strong:
        await HapticFeedback.mediumImpact();
    }
  }
}
