import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/database_service.dart';
import 'services/timer_service.dart';
import 'services/session_manager.dart';
import 'services/goals_service.dart';
import 'services/tasbeeh_service.dart';
import 'services/notification_service.dart';
import 'services/pwa_service.dart';
import 'services/background_task_service.dart';
import 'utils/debug_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DebugLogger.init();

  await DatabaseService.init();
  await NotificationService.init();
  await NotificationService.requestPermission();
  await BackgroundTaskService.init();
  PwaService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final sessionManager = SessionManager();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GoalsService()),
        ChangeNotifierProvider.value(value: sessionManager),
        ChangeNotifierProvider(create: (_) => TimerService(sessionManager)),
        ChangeNotifierProvider(create: (_) => TasbeehService()),
      ],
      child: const PomodoroApp(),
    ),
  );
}
