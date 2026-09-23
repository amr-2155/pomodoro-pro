import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundTaskService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      FlutterForegroundTask.init(
        androidNotificationOptions: AndroidNotificationOptions(
          channelId: 'pomodoro_timer_service',
          channelName: 'Pomodoro Timer',
          channelDescription:
              'Keeps your pomodoro timer running in the background',
          channelImportance: NotificationChannelImportance.LOW,
          priority: NotificationPriority.LOW,
          playSound: false,
          enableVibration: false,
          onlyAlertOnce: true,
        ),
        iosNotificationOptions: const IOSNotificationOptions(
          showNotification: false,
          playSound: false,
        ),
        foregroundTaskOptions: ForegroundTaskOptions(
          eventAction: ForegroundTaskEventAction.repeat(60000),
          autoRunOnBoot: false,
          autoRunOnMyPackageReplaced: false,
          allowWakeLock: true,
          allowWifiLock: false,
          allowAutoRestart: true,
        ),
      );
    } catch (_) {}
  }

  static Future<void> start({
    required String title,
    required String text,
  }) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.restartService();
        return;
      }
      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: title,
        notificationText: text,
        serviceTypes: const [ForegroundServiceTypes.mediaPlayback],
        callback: _serviceCallback,
      );
    } catch (_) {}
  }

  static Future<void> update({
    required String title,
    required String text,
  }) async {
    try {
      await FlutterForegroundTask.updateService(
        notificationTitle: title,
        notificationText: text,
      );
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await FlutterForegroundTask.stopService();
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
void _serviceCallback() {
  FlutterForegroundTask.setTaskHandler(_TimerTaskHandler());
}

class _TimerTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}
}
