import 'dart:io';
import 'package:flutter/services.dart';

/// Maximum-strength vibration via native Android Vibrator API.
/// Falls back to HapticFeedback on other platforms.
class VibrationService {
  static const _channel = MethodChannel('com.pomodoro.vibration');
  static bool _available = Platform.isAndroid;

  /// Strong single vibration pulse.
  static Future<void> vibrate({int duration = 500, int amplitude = 255}) async {
    if (!_available) {
      HapticFeedback.vibrate();
      return;
    }
    try {
      await _channel.invokeMethod('vibrate', {
        'duration': duration,
        'amplitude': amplitude,
      });
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  /// Custom vibration pattern (timings in ms, amplitudes 0-255).
  static Future<void> pattern({
    required List<int> timings,
    List<int>? amplitudes,
  }) async {
    if (!_available) {
      HapticFeedback.vibrate();
      return;
    }
    try {
      await _channel.invokeMethod('pattern', {
        'timings': timings,
        'amplitudes': amplitudes,
      });
    } catch (_) {
      HapticFeedback.vibrate();
    }
  }

  /// Cancel any ongoing vibration.
  static Future<void> cancel() async {
    if (!_available) return;
    try {
      await _channel.invokeMethod('cancel');
    } catch (_) {}
  }
}
