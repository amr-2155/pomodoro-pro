import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'data_backup_service_stub.dart'
    if (dart.library.js_interop) 'data_backup_service_web.dart' as impl;

class DataBackupService {
  static bool get isWeb => kIsWeb;

  static void downloadBackup(BuildContext context, String json) {
    impl.downloadBackup(context, json);
  }

  static Future<void> pickAndRestore(BuildContext context) {
    return impl.pickAndRestore(context);
  }
}
