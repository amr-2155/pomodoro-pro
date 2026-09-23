import 'dart:io';
import 'package:path_provider/path_provider.dart';

class DebugLogger {
  static File? _file;
  static bool _initialized = false;

  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _file = File('${dir.path}/celebration_debug.log');
      // Clear old log
      await _file!.writeAsString('=== Debug Log Started ===\n');
      _initialized = true;
    } catch (_) {}
  }

  static Future<void> log(String tag, String message) async {
    if (!_initialized || _file == null) return;
    try {
      final time = DateTime.now();
      final line =
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}.${time.millisecond.toString().padLeft(3, '0')} [$tag] $message\n';
      await _file!.writeAsString(line, mode: FileMode.append);
    } catch (_) {}
  }
}
