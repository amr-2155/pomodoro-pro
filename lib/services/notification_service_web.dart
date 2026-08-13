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
      web.Notification.requestPermission();
      if (web.Notification.permission == 'granted') {
        _hasPermission = true;
      }
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

  static Future<void> cancelAll() async {
    if (kIsWeb) return;
  }

  static Future<void> scheduleAt(
    DateTime when, {
    String title = 'Pomodoro',
    String body = 'Session complete!',
    int id = 1000,
  }) async {}

  static Future<void> cancel(int id) async {}
}
