import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Web vibration via the Vibration API; falls back to HapticFeedback.
/// Same static API as the mobile implementation so callers stay unchanged.
class VibrationService {
  static Future<void> vibrate({int duration = 500, int amplitude = 255}) async {
    try {
      if (!web.window.navigator.vibrate(duration.toJS)) {
        await HapticFeedback.vibrate();
      }
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  static Future<void> pattern({
    required List<int> timings,
    List<int>? amplitudes,
  }) async {
    try {
      if (!web.window.navigator.vibrate(timings.map((e) => e.toJS).toList().toJS)) {
        await HapticFeedback.vibrate();
      }
    } catch (_) {
      try {
        await HapticFeedback.vibrate();
      } catch (_) {}
    }
  }

  static Future<void> cancel() async {}
}
