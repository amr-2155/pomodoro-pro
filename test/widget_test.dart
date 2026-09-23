import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:pomodoro_app/l10n/app_localizations.dart';
import 'package:pomodoro_app/services/database_service.dart';
import 'package:pomodoro_app/services/goals_service.dart';
import 'package:pomodoro_app/services/session_manager.dart';
import 'package:pomodoro_app/services/timer_service.dart';
import 'package:pomodoro_app/utils/app_keys.dart';
import 'package:pomodoro_app/widgets/completion_celebration.dart';
import 'package:pomodoro_app/widgets/completion_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // audioplayers constructs AudioPlayer statics eagerly when AudioService is
  // touched (e.g. TimerService.dispose). In the test env the plugin channels
  // are absent, so mock them to avoid leaked MissingPluginException errors.
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  for (final channel in const [
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.texture',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(channel),
      (call) async => null,
    );
  }

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('pomodoro_test');
    await DatabaseService.init(hivePath: tempDir.path);
  });

  tearDownAll(() async {
    // Guarded: a testWidgets tears down inside a FakeAsync zone where real
    // file I/O (Hive flush) never completes, so bound every await.
    await Hive.close().timeout(const Duration(seconds: 5), onTimeout: () => <void>[]);
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  // Clears SessionManager persistence so each test sees a clean slate.
  // Called at the START of each session-manager test in the real async zone
  // (testWidgets must wrap this in tester.runAsync — Hive writes never
  // complete inside the FakeAsync zone).
  Future<void> _clearSmState() async {
    await DatabaseService.setSetting('smCompletionPending', false);
    await DatabaseService.setSetting('smCompletionDataJson', '');
  }

  test('Stage toggle completes', () async {
    final goals = GoalsService();
    await goals.setDailyGoal(60);
    await goals.addStage('قراءة', minutes: 25);
    expect(goals.todayStages.length, 1);
    expect(goals.todayStagesDone, 0);

    await goals.toggleStage(goals.todayStages.first.id);
    expect(goals.todayStagesDone, 1);
    expect(goals.allStagesDone, true);

    goals.dispose();
  });

  test('Smart plan generates stages from weekly goal', () async {
    final goals = GoalsService();
    await goals.setWeeklyGoal(60);
    await goals.setDailyGoal(0);
    await goals.generateSmartPlan();
    expect(goals.todayStages.isNotEmpty, true);
    final total = goals.todayStages.fold<int>(
        0, (sum, s) => sum + s.durationMinutes);
    expect(total, lessThanOrEqualTo(60));
    goals.dispose();
  });

  test('Stopwatch start/pause/resume/reset lifecycle', () async {
    final svc = TimerService(SessionManager());
    svc.setMode(TimerMode.stopwatch);
    expect(svc.mode, TimerMode.stopwatch);
    expect(svc.formattedStopwatchTime, '00:00');

    svc.start();
    expect(svc.running, true);

    svc.pause();
    expect(svc.running, false);
    expect(svc.stopwatchElapsed.inMilliseconds, greaterThanOrEqualTo(0));

    svc.start();
    expect(svc.running, true);

    svc.reset();
    expect(svc.running, false);
    expect(svc.stopwatchElapsed, Duration.zero);
    expect(svc.formattedStopwatchTime, '00:00');
    svc.dispose();
  });

  test('Stopwatch finish saves a stopwatch session', () async {
    final svc = TimerService(SessionManager());
    svc.setMode(TimerMode.stopwatch);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(svc.stopwatchElapsed.inSeconds, greaterThanOrEqualTo(1));

    svc.skip();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final saved = DatabaseService.getAllSessions()
        .where((s) => s.sessionType == 'stopwatch')
        .toList();
    expect(saved.isNotEmpty, true);
    final session = saved.last;
    expect(session.completed, true);
    expect(session.actualSeconds, greaterThanOrEqualTo(1));
    expect(svc.running, false);
    expect(svc.stopwatchElapsed, Duration.zero);
    svc.dispose();
  });

  test('Stopwatch restores paused state and finishes with exact seconds',
      () async {
    await DatabaseService.setSetting('stopwatchActive', true);
    await DatabaseService.setSetting('stopwatchElapsedMs', 2538000);
    await DatabaseService.setSetting('stopwatchRunStartMs', 0);
    await DatabaseService.setSetting(
        'stopwatchStartedAtMs',
        DateTime.now()
            .subtract(const Duration(minutes: 42, seconds: 18))
            .millisecondsSinceEpoch);
    await DatabaseService.setSetting('stopwatchProjectId', '');
    await DatabaseService.setSetting('stopwatchTaskId', '');

    final svc = TimerService(SessionManager());
    expect(svc.mode, TimerMode.stopwatch);
    expect(svc.pendingRestorePrompt, true);
    expect(svc.running, false);
    expect(svc.stopwatchElapsed, const Duration(minutes: 42, seconds: 18));
    expect(svc.formattedStopwatchTime, '42:18');

    svc.skip();
    await Future<void>.delayed(const Duration(milliseconds: 200));

    final saved = DatabaseService.getAllSessions()
        .where((s) => s.sessionType == 'stopwatch')
        .toList();
    expect(saved.any((s) => s.actualSeconds == 2538), true);
    expect(
        DatabaseService.getSetting('stopwatchActive', defaultValue: false),
        false);
    svc.dispose();
  });

  test('Stopwatch restores a running session from runStart', () async {
    await DatabaseService.setSetting('stopwatchActive', true);
    await DatabaseService.setSetting('stopwatchElapsedMs', 0);
    await DatabaseService.setSetting('swRunStartMs',
        DateTime.now()
            .subtract(const Duration(seconds: 15))
            .millisecondsSinceEpoch);
    await DatabaseService.setSetting(
        'stopwatchStartedAtMs',
        DateTime.now()
            .subtract(const Duration(seconds: 15))
            .millisecondsSinceEpoch);
    await DatabaseService.setSetting('stopwatchProjectId', '');
    await DatabaseService.setSetting('stopwatchTaskId', '');

    final svc = TimerService(SessionManager());
    expect(svc.mode, TimerMode.stopwatch);
    expect(svc.pendingRestorePrompt, true);
    expect(svc.running, true);
    expect(svc.stopwatchElapsed.inSeconds, greaterThanOrEqualTo(15));

    svc.reset();
    expect(svc.running, false);
    expect(svc.stopwatchElapsed, Duration.zero);
    expect(
        DatabaseService.getSetting('stopwatchActive', defaultValue: false),
        false);
    svc.dispose();
  });

  test('Natural countdown finish marks session completed', () async {
    await _clearSmState();
    final sm = SessionManager();
    final svc = TimerService(sm);
    // Reset countdown persistence in case a prior test left it active.
    svc.reset();
    svc.setMode(TimerMode.focus);
    svc.setDurationSeconds(TimerMode.focus, 2);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 5000));

    expect(svc.running, false, reason: 'timer should have stopped');
    expect(sm.completionPending, true,
        reason: 'natural finish must mark the session completed');
    expect(sm.completionData?['completedMode'], 'focus');
    expect(svc.lastCompletedSessionId, isNotNull);
    svc.dispose();
  });

  test('Natural break finish also shows the completion card', () async {
    await _clearSmState();
    final sm = SessionManager();
    final svc = TimerService(sm);
    svc.reset();
    svc.setMode(TimerMode.shortBreak);
    svc.setDurationSeconds(TimerMode.shortBreak, 2);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 5000));

    expect(svc.running, false, reason: 'break timer should have stopped');
    expect(sm.completionPending, true,
        reason: 'a naturally finished break must show the completion card');
    expect(sm.completionData?['completedMode'], 'shortBreak');
    svc.dispose();
  });

  test('Skip does NOT mark session completed', () async {
    await _clearSmState();
    final sm = SessionManager();
    final svc = TimerService(sm);
    svc.reset();
    svc.setMode(TimerMode.focus);
    svc.setDurationSeconds(TimerMode.focus, 60);
    svc.start();
    await Future<void>.delayed(const Duration(milliseconds: 200));
    svc.skip();
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(svc.running, false);
    expect(sm.completionPending, false,
        reason: 'skipping a session must not show the completion card');
    svc.dispose();
  });

  testWidgets('Completion card appears over any screen when complete', (tester) async {
    // Phone-like surface so the tall card (quote + rating + notes) fits.
    await tester.binding.setSurfaceSize(const Size(600, 1300));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    // Hive writes are real file I/O — they never complete inside the widget
    // test's FakeAsync zone, so force them through the real event loop.
    await tester.runAsync(_clearSmState);

    final sm = SessionManager();
    final timer = TimerService(sm);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: sm),
          ChangeNotifierProvider.value(value: timer),
        ],
        // Mirrors lib/app.dart: completion overlay lives ABOVE the Navigator
        // so it must cover pushed routes too.
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          locale: const Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          builder: (context, child) =>
              CompletionOverlay(child: child!),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Scaffold(
                          body: Center(child: Text('pushed screen')),
                        ),
                      ),
                    );
                  },
                  child: const Text('push'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CompletionCelebration), findsNothing);

    // Cover a pushed route: overlay must still sit on top.
    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('pushed screen'), findsOneWidget);

    sm.markCompleted(
      sessionId: 'test-session',
      completedMode: 'focus',
      sessionCount: 5,
      isMilestone: false,
      completionQuote: 'Great job',
      completionQuoteSource: 'test',
      durationMinutes: 1,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CompletionCelebration), findsOneWidget,
        reason: 'completion card must appear over any screen, incl. pushed routes');

    // Let the entrance animation fully settle so the button is hittable.
    await tester.pump(const Duration(milliseconds: 900));
    await tester.ensureVisible(find.text('متابعة'));
    await tester.pump();

    await tester.tap(find.text('متابعة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(sm.completionPending, false);
    expect(find.byType(CompletionCelebration), findsNothing,
        reason: 'card must close after Continue');

    timer.dispose();
  });
}
