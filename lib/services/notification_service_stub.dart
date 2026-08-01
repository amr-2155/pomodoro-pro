class NotificationService {
  static Future<void> init() async {}

  static Future<void> requestPermission() async {}

  static Future<void> show({
    String title = 'Pomodoro',
    String body = 'Session complete!',
    int id = 0,
  }) async {}

  static Future<void> cancelAll() async {}
}
