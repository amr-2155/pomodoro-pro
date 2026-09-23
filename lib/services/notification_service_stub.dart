import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const _channelId = 'pomodoro_notifications';
  static const _channelName = 'Pomodoro Notifications';
  static const _channelDesc = 'Timer completion notifications';

  // Strong vibration pattern: 1s vibrate, 0.5s pause, 1s vibrate, 0.5s pause,
  // 1.5s vibrate. Fires at OS level even when app is killed.
  static final Int64List _vibrationPattern =
      Int64List.fromList([0, 1000, 500, 1000, 500, 1500]);

  static final NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
      sound: RawResourceAndroidNotificationSound('alarm'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: _vibrationPattern,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      tzdata.initializeTimeZones();
      // Ensure tz.local reflects the device zone before scheduling.
      try {
        final name = DateTime.now().timeZoneName;
        tz.setLocalLocation(tz.getLocation(name));
      } catch (_) {}
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  static Future<void> requestPermission() async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  static Future<void> show({
    String title = 'Pomodoro',
    String body = 'Session complete!',
    int id = 0,
  }) async {
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _details,
      );
    } catch (_) {}
  }

  /// Returns true when an OS-level alarm was actually registered.
  /// Falls back to inexact scheduling when exact alarms are unavailable,
  /// so a session-end notification always exists even under Doze/OEM kills.
  static Future<bool> scheduleAt(
    DateTime when, {
    String title = 'Pomodoro',
    String body = 'Session complete!',
    int id = 1000,
  }) async {
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      var exact = true;
      if (android != null) {
        exact = await android.canScheduleExactNotifications() ?? false;
      }
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(when, tz.local),
        notificationDetails: _details,
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  // ─── Repeating notification for continuous vibration ───
  static Timer? _repeatTimer;
  static const int _repeatId = 9999;

  /// Posts a vibrating notification every [intervalMs] ms.
  /// Continues indefinitely until [cancelRepeatVibration] is called.
  static void startRepeatVibration({
    String title = 'Pomodoro',
    String body = 'Session complete!',
    int intervalMs = 2500,
  }) {
    cancelRepeatVibration();
    _repeatTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      show(title: title, body: body, id: _repeatId);
    });
    // Also fire immediately.
    show(title: title, body: body, id: _repeatId);
  }

  static void cancelRepeatVibration() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    cancel(_repeatId);
  }
}
