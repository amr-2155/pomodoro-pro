import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

class NotificationService {
  static bool _initialized = false;
  static bool _hasPermission = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    if (kIsWeb) {
      try {
        if (web.Notification.permission == 'granted') {
          _hasPermission = true;
        }
      } catch (_) {}
    }
  }

  static Future<void> requestPermission() async {
    if (!kIsWeb) return;
    try {
      // requestPermission() returns a Promise; reading the state on the very
      // next line would always sample the pre-grant value. Await it instead.
      final result = await web.Notification.requestPermission().toDart;
      _hasPermission = (result.toDart == 'granted') ||
          (web.Notification.permission == 'granted');
    } catch (_) {}
  }

  static Future<void> show({
    String title = 'Pomodoro',
    String body = 'Session complete!',
    int id = 0,
  }) async {
    if (!kIsWeb) return;

    if (!_initialized) await init();
    if (!_hasPermission) {
      await requestPermission();
    }
    if (!_hasPermission) return;

    try {
      web.Notification(
        title,
        web.NotificationOptions(body: body),
      );
    } catch (_) {}
  }

  /// No-op on web: browser notifications cannot be cancelled programmatically.
  /// (The previous `if (kIsWeb) return;` guard made this permanently unreachable.)
  static Future<void> cancelAll() async {}

  static Future<bool> scheduleAt(
    DateTime when, {
    String title = 'Pomodoro',
    String body = 'Session complete!',
    int id = 1000,
  }) async => false;

  static Future<void> cancel(int id) async {}
}
