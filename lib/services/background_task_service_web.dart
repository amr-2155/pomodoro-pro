class BackgroundTaskService {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
  }

  static Future<void> start({
    required String title,
    required String text,
  }) async {}

  static Future<void> update({
    required String title,
    required String text,
  }) async {}

  static Future<void> stop() async {}
}
