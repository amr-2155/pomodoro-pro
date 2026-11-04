import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DebugLogger.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Database startup (and the rest of the one-time init) runs inside
  // AppBootstrap so a failure shows a recoverable screen instead of a blank
  // window.
  runApp(const AppBootstrap());
}
