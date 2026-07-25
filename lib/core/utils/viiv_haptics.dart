import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// Vibrations téléphone (scan / trouver montre / connect).
class ViivHaptics {
  static Future<void> scanPulse() async {
    HapticFeedback.heavyImpact();
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 180, amplitude: 180);
      }
    } catch (_) {}
  }

  static Future<void> findWatch() async {
    HapticFeedback.heavyImpact();
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(
          pattern: [0, 200, 120, 200, 120, 400],
          intensities: [0, 200, 0, 200, 0, 255],
        );
      }
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  static Future<void> connected() async {
    HapticFeedback.mediumImpact();
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 80, amplitude: 120);
      }
    } catch (_) {}
  }
}
