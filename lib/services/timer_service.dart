import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import '../utils/debug_logger.dart';
import 'audio_service.dart';
import 'completion_sound.dart';
import 'notification_service.dart';
import 'background_task_service.dart';
import 'database_service.dart';
import 'session_manager.dart';
import '../models/session.dart';
import '../utils/number_formatter.dart';
import '../utils/quote_library.dart';

enum TimerMode { focus, shortBreak, longBreak, stopwatch }

class TimerService extends ChangeNotifier {
  Timer? _timer;
  int _seconds = 1500;
  int _totalSeconds = 1500;
  bool _running = false;
  TimerMode _mode = TimerMode.focus;
  int _sessionCount = 0;
  String? _currentProjectId;
  String? _currentTaskId;
  bool _isMilestone = false;
  String _completionQuote = '';
  String _completionQuoteSource = '';
  TimerMode _completedMode = TimerMode.focus;
  String? _lastCompletedSessionId;
  bool _wasSkipped = false;
  DateTime? _endTime;
  DateTime _lastBackgroundUpdate = DateTime.now();
  DateTime? _startedAt;
  AppLifecycleListener? _lifecycleListener;

  Duration _stopwatchElapsed = Duration.zero;
  DateTime? _stopwatchRunStart;
  DateTime? _stopwatchStartedAt;
  bool _pendingRestorePrompt = false;

  static const int _scheduledNotificationId = 1001;

  // --- Persisted countdown session state (survives process death) ---
  static const String _cdActive = 'countdownActive';
  static const String _cdEndMs = 'countdownEndMs';
  static const String _cdStartMs = 'countdownStartMs';
  static const String _cdRemainingSec = 'countdownRemainingSec';
  static const String _cdTotalSec = 'countdownTotalSec';
  static const String _cdModeIdx = 'countdownModeIdx';
  static const String _cdProjectId = 'countdownProjectId';
  static const String _cdTaskId = 'countdownTaskId';

  bool _completing = false;
  /// True when the OS itself holds a scheduled end-of-session alarm.
  /// When true, _finish() must NOT post an immediate duplicate.
  bool _endNotificationScheduled = false;

  static const String _swActive = 'stopwatchActive';
  static const String _swElapsedMs = 'stopwatchElapsedMs';
  static const String _swRunStartMs = 'swRunStartMs';
  static const String _swStartedAtMs = 'stopwatchStartedAtMs';
  static const String _swProjectId = 'stopwatchProjectId';
  static const String _swTaskId = 'stopwatchTaskId';

  final SessionManager _sessionManager;

  TimerService(this._sessionManager) {
    _sessionCount = DatabaseService.getSetting('sessionCount', defaultValue: 0);
    _seconds = DatabaseService.focusDuration;
    _totalSeconds = DatabaseService.focusDuration;
    _restoreStopwatchIfNeeded();
    unawaited(_restoreCountdownIfNeeded());
    _lifecycleListener = AppLifecycleListener(
      onResume: _onResume,
      onHide: _onHide,
      onPause: _onHide,
    );
  }

  void Function(int breakMinutes)? onBreakStart;

  int get seconds => _seconds;
  int get totalSeconds => _totalSeconds;
  bool get running => _running;
  TimerMode get mode => _mode;
  int get sessionCount => _sessionCount;
  String? get currentProjectId => _currentProjectId;
  String? get lastCompletedSessionId => _lastCompletedSessionId;

  Duration get stopwatchElapsed {
    if (_running && _stopwatchRunStart != null) {
      return _stopwatchElapsed + DateTime.now().difference(_stopwatchRunStart!);
    }
    return _stopwatchElapsed;
  }

  bool get pendingRestorePrompt => _pendingRestorePrompt;

  void stopCompletionLoop() {
    AudioService.stopCompletionLoop();
    notifyListeners();
  }

  bool get stopwatchInProgress =>
      _mode == TimerMode.stopwatch &&
      (_running || _stopwatchElapsed > Duration.zero);

  void consumePendingRestorePrompt() {
    _pendingRestorePrompt = false;
  }

double get progress =>
      _totalSeconds > 0 ? 1.0 - (_seconds / _totalSeconds) : 0.0;

  String get formattedTime {
    final mins = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return toArabicNumerals('$mins:$secs');
  }

  String get formattedStopwatchTime {
    final t = stopwatchElapsed;
    final h = t.inHours;
    final m = (t.inMinutes % 60).toString().padLeft(2, '0');
    final s = (t.inSeconds % 60).toString().padLeft(2, '0');
    if (h > 0) {
      return toArabicNumerals('${h.toString().padLeft(2, '0')}:$m:$s');
    }
    return toArabicNumerals('$m:$s');
  }

  void setDurationSeconds(TimerMode mode, int totalSeconds) {
    if (_running) return;
    _mode = mode;
    _seconds = totalSeconds;
    _totalSeconds = totalSeconds;
    notifyListeners();
  }

  void setProject(String? projectId) {
    _currentProjectId = projectId;
    if (stopwatchInProgress) _persistStopwatch();
    notifyListeners();
  }

  /// Resets the in-memory session counter after "Reset all data" has cleared
  /// its persisted source. Prevents stale milestone schedules after a reset.
  void resetSessionCount() {
    _sessionCount = 0;
    notifyListeners();
  }

  void setTask(String? taskId) {
    _currentTaskId = taskId;
    if (taskId != null) {
      final task = DatabaseService.getTaskById(taskId);
      if (task != null && task.projectId != null) {
        _currentProjectId = task.projectId;
      }
    }
    if (stopwatchInProgress) _persistStopwatch();
    notifyListeners();
  }

  void start() {
    if (_running) return;
    AudioService.stopCompletionLoop();
    if (_mode == TimerMode.stopwatch) {
      _startStopwatchRun();
    } else {
      unawaited(_startCountdownRun());
    }
  }

  bool get _localeIsAr =>
      DatabaseService.localeNotifier.value.languageCode == 'ar';

  String _notifTitle(bool isFocus) => isFocus
      ? (_localeIsAr ? 'اكتملت جلسة التركيز!' : 'Focus Session Complete!')
      : (_localeIsAr ? 'انتهت الاستراحة!' : 'Break Over!');

  String _notifBody(bool isFocus) => isFocus
      ? (_localeIsAr ? 'عمل رائع! حان وقت الاستراحة.' : 'Great work! Time for a break.')
      : (_localeIsAr ? 'مستعد للتركيز من جديد؟' : 'Ready to focus again?');

  Future<void> _startCountdownRun() async {
    _running = true;
    _startedAt ??= DateTime.now();
    // sessionEndTime is the single source of truth for completion.
    _endTime = DateTime.now().add(Duration(seconds: _seconds));
    _lastBackgroundUpdate = DateTime.now();
    _endNotificationScheduled = await NotificationService.scheduleAt(
      _endTime!,
      title: _mode == TimerMode.focus ? _notifTitle(true) : _notifTitle(false),
      body: _mode == TimerMode.focus ? _notifBody(true) : _notifBody(false),
      id: _scheduledNotificationId,
    );
    unawaited(BackgroundTaskService.start(
      title: _mode == TimerMode.focus ? 'Focus Session' : 'Break',
      text: formattedTime,
    ));
    _persistCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      // Completion is decided by wall-clock time, never by tick count.
      if (DateTime.now().isBefore(_endTime!)) {
        final remaining = _endTime!.difference(DateTime.now()).inSeconds;
        if (remaining != _seconds) {
          _seconds = remaining < 0 ? 0 : remaining;
          final countdownSec = DatabaseService.countdownSeconds;
          if (DatabaseService.countdownSoundEnabled &&
              _seconds > 0 &&
              _seconds <= countdownSec) {
            AudioService.playCountdownTick(
              countdownSoundFromKey(DatabaseService.countdownSoundType),
            );
          }
        }
        _maybeUpdateBackgroundNotification();
        notifyListeners();
      } else {
        _finish();
      }
    });
    notifyListeners();
  }

  void _persistCountdown() {
    DatabaseService.setSetting(_cdActive, true);
    DatabaseService.setSetting(
        _cdEndMs, _endTime?.millisecondsSinceEpoch ?? 0);
    DatabaseService.setSetting(
        _cdStartMs, _startedAt?.millisecondsSinceEpoch ?? 0);
    DatabaseService.setSetting(_cdRemainingSec, _seconds);
    DatabaseService.setSetting(_cdTotalSec, _totalSeconds);
    DatabaseService.setSetting(_cdModeIdx, _mode.index);
    DatabaseService.setSetting(_cdProjectId, _currentProjectId ?? '');
    DatabaseService.setSetting(_cdTaskId, _currentTaskId ?? '');
  }

  void _clearPersistedCountdown() {
    DatabaseService.setSetting(_cdActive, false);
    DatabaseService.setSetting(_cdEndMs, 0);
    DatabaseService.setSetting(_cdStartMs, 0);
    DatabaseService.setSetting(_cdRemainingSec, 0);
    DatabaseService.setSetting(_cdTotalSec, 0);
    DatabaseService.setSetting(_cdModeIdx, 0);
    DatabaseService.setSetting(_cdProjectId, '');
    DatabaseService.setSetting(_cdTaskId, '');
  }

  /// Rebuilds a running countdown session after the process was killed.
  /// Completion is derived from the persisted sessionEndTime against real
  /// time — no reliance on any timer having kept running in the background.
  Future<void> _restoreCountdownIfNeeded() async {
    final active = DatabaseService.getSetting(_cdActive, defaultValue: false);
    final endMs = DatabaseService.getSetting(_cdEndMs, defaultValue: 0);
    DebugLogger.log('RESTORE', 'active=$active, endMs=$endMs, now=${DateTime.now().millisecondsSinceEpoch}');
    if (active != true) return;
    if (endMs is! int || endMs <= 0) {
      _clearPersistedCountdown();
      return;
    }
    final modeIdx =
        DatabaseService.getSetting(_cdModeIdx, defaultValue: 0);
    _mode = modeIdx is int && modeIdx >= 0 && modeIdx < TimerMode.values.length
        ? TimerMode.values[modeIdx]
        : TimerMode.focus;
    print('RESTORE| mode=${_mode.name} active=true endMs=$endMs');
    _totalSeconds =
        DatabaseService.getSetting(_cdTotalSec, defaultValue: _totalSeconds)
            as int;
    _currentProjectId = null;
    final projectId = DatabaseService.getSetting(_cdProjectId, defaultValue: '');
    if (projectId is String && projectId.isNotEmpty) {
      _currentProjectId = projectId;
    }
    final taskId = DatabaseService.getSetting(_cdTaskId, defaultValue: '');
    if (taskId is String && taskId.isNotEmpty) {
      _currentTaskId = taskId;
    }

    final end = DateTime.fromMillisecondsSinceEpoch(endMs);
    final remaining = end.difference(DateTime.now()).inSeconds;
    DebugLogger.log('RESTORE', 'end=$end, remaining=$remaining');
    if (remaining > 0) {
      // Session still running: resync from wall clock and continue.
      final startMs = DatabaseService.getSetting(_cdStartMs, defaultValue: 0);
      if (startMs is int && startMs > 0) {
        _startedAt = DateTime.fromMillisecondsSinceEpoch(startMs);
      }
      _seconds = remaining;
      _running = true;
      _endTime = end;
      _endNotificationScheduled = await NotificationService.scheduleAt(
        _endTime!,
        title: _notifTitle(_mode == TimerMode.focus),
        body: _notifBody(_mode == TimerMode.focus),
        id: _scheduledNotificationId,
      );
      unawaited(BackgroundTaskService.start(
        title: _mode == TimerMode.focus ? 'Focus Session' : 'Break',
        text: formattedTime,
      ));
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (DateTime.now().isBefore(_endTime!)) {
          final rem = _endTime!.difference(DateTime.now()).inSeconds;
          if (rem >= 0 && rem != _seconds) {
            _seconds = rem;
            notifyListeners();
          }
        } else {
          _finish();
        }
      });
    } else {
      // Session already ended while the app was closed/backgrounded.
      DebugLogger.log('RESTORE', 'session already ended, calling _completeSession(false)');
      print('RESTORE| already ended, completing mode=${_mode.name}');
      _seconds = 0;
      _running = false;
      _endTime = null;
      _completing = true;
      _completeSession(showNotification: false);
      DebugLogger.log('RESTORE', 'AFTER _completeSession');
      notifyListeners();
    }
  }

  void _maybeUpdateBackgroundNotification() {
    final now = DateTime.now();
    if (now.difference(_lastBackgroundUpdate).inSeconds >= 5) {
      _lastBackgroundUpdate = now;
      unawaited(BackgroundTaskService.update(
        title: _mode == TimerMode.focus ? 'Focus Session' : 'Break',
        text: formattedTime,
      ));
    }
  }

  void pause() {
    if (_mode == TimerMode.stopwatch) {
      if (!_running) return;
      _stopwatchElapsed = stopwatchElapsed;
      _stopwatchRunStart = null;
      _timer?.cancel();
      _running = false;
      _persistStopwatch();
      unawaited(BackgroundTaskService.stop());
      notifyListeners();
      return;
    }
_timer?.cancel();
    _running = false;
    _endTime = null;
    _endNotificationScheduled = false;
    NotificationService.cancel(_scheduledNotificationId);
    _clearPersistedCountdown();
    _startedAt = null;
    unawaited(BackgroundTaskService.stop());
    AudioService.stopAllSounds();
    notifyListeners();
    return;
  }

  void reset() {
    if (_mode == TimerMode.stopwatch) {
      _timer?.cancel();
      _running = false;
      _stopwatchElapsed = Duration.zero;
      _stopwatchRunStart = null;
      _stopwatchStartedAt = null;
      _clearPersistedStopwatch();
      unawaited(BackgroundTaskService.stop());
      notifyListeners();
      return;
    }
    _timer?.cancel();
    _running = false;
    _endTime = null;
    _endNotificationScheduled = false;
    NotificationService.cancel(_scheduledNotificationId);
    _clearPersistedCountdown();
    _startedAt = null;
    unawaited(BackgroundTaskService.stop());
    AudioService.stopAllSounds();
    _seconds = _totalSeconds;
    notifyListeners();
  }

  void _onHide() {
    if (stopwatchInProgress) {
      _persistStopwatch();
    }
    // Persist countdown session state so a full process kill can still
    // resync against sessionEndTime on next launch.
    if (_running && _mode != TimerMode.stopwatch) {
      _persistCountdown();
    }
  }

  void _onResume() {
    DebugLogger.log('ONRESUME', '_completing=$_completing, _running=$_running, _endTime=$_endTime');
    if (_completing || _running && _endTime != null) {
      final remaining = _endTime?.difference(DateTime.now()).inSeconds;
      if (_running && remaining != null) {
        if (remaining <= 0) {
          _finish();
        } else {
          _seconds = remaining;
          notifyListeners();
        }
      }
    }
    if (_mode == TimerMode.stopwatch && _running) {
      notifyListeners();
    }
  }

  void skip() {
    if (_mode == TimerMode.stopwatch) {
      _finishStopwatch();
      return;
    }
    _timer?.cancel();
    _running = false;
    AudioService.stopAllSounds();
    _endTime = null;
    _endNotificationScheduled = false;
    // A skipped session must not fire the scheduled completion notification.
    NotificationService.cancel(_scheduledNotificationId);
    _clearPersistedCountdown();
    unawaited(BackgroundTaskService.stop());
    _wasSkipped = true;
    _completing = true;
    _completeSession(showNotification: false);
  }

  void setMode(TimerMode mode) {
    if (_running) return;
    _mode = mode;
    if (mode == TimerMode.stopwatch) {
      _seconds = 0;
      _totalSeconds = 0;
      _stopwatchElapsed = Duration.zero;
      _stopwatchRunStart = null;
      _stopwatchStartedAt = null;
      _clearPersistedStopwatch();
    } else {
      _updateDurationForMode();
    }
    notifyListeners();
  }

  String get _swTitle => DatabaseService.localeNotifier.value.languageCode == 'ar'
      ? 'ساعة إيقاف'
      : 'Stopwatch';

  void _startStopwatchRun() {
    _stopwatchRunStart ??= DateTime.now();
    _stopwatchStartedAt ??= DateTime.now();
    _running = true;
    unawaited(BackgroundTaskService.start(
      title: _swTitle,
      text: formattedStopwatchTime,
    ));
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      _maybeUpdateStopwatchBackground();
      notifyListeners();
    });
    _persistStopwatch();
    notifyListeners();
  }

  void _maybeUpdateStopwatchBackground() {
    final now = DateTime.now();
    if (now.difference(_lastBackgroundUpdate).inSeconds >= 5) {
      _lastBackgroundUpdate = now;
      unawaited(BackgroundTaskService.update(
        title: _swTitle,
        text: formattedStopwatchTime,
      ));
    }
  }

  void _finishStopwatch() {
    final elapsed = stopwatchElapsed;
    _timer?.cancel();
    _running = false;
    _stopwatchElapsed = Duration.zero;
    _stopwatchRunStart = null;
    _clearPersistedStopwatch();
    notifyListeners();

    if (elapsed.inSeconds < 1) return;

    final totalSeconds = elapsed.inSeconds;
    final minutes = (totalSeconds / 60).ceil();
    final session = Session(
      id: const Uuid().v4(),
      projectId: _currentProjectId ?? '',
      durationMinutes: minutes,
      actualMinutes: minutes,
      actualSeconds: totalSeconds,
      completed: true,
      sessionType: 'stopwatch',
      startTime: _stopwatchStartedAt,
      endTime: DateTime.now(),
      taskId: _currentTaskId,
    );
    _stopwatchStartedAt = null;
    DatabaseService.addSession(session);
    _lastCompletedSessionId = session.id;
    final projectName = _currentProjectId != null
        ? DatabaseService.getProject(_currentProjectId!)?.name
        : null;
    _sessionManager.markCompleted(
      sessionId: session.id,
      completedMode: 'stopwatch',
      sessionCount: _sessionCount,
      isMilestone: false,
      completionQuote: '',
      completionQuoteSource: '',
      durationMinutes: minutes,
      projectId: _currentProjectId,
      projectName: projectName,
    );
  }

  void _persistStopwatch() {
    DatabaseService.setSetting(_swActive, true);
    DatabaseService.setSetting(_swElapsedMs, _stopwatchElapsed.inMilliseconds);
    DatabaseService.setSetting(
        _swRunStartMs, _stopwatchRunStart?.millisecondsSinceEpoch ?? 0);
    DatabaseService.setSetting(
        _swStartedAtMs, _stopwatchStartedAt?.millisecondsSinceEpoch ?? 0);
    DatabaseService.setSetting(_swProjectId, _currentProjectId ?? '');
    DatabaseService.setSetting(_swTaskId, _currentTaskId ?? '');
  }

  void _clearPersistedStopwatch() {
    DatabaseService.setSetting(_swActive, false);
    DatabaseService.setSetting(_swElapsedMs, 0);
    DatabaseService.setSetting(_swRunStartMs, 0);
    DatabaseService.setSetting(_swStartedAtMs, 0);
    DatabaseService.setSetting(_swProjectId, '');
    DatabaseService.setSetting(_swTaskId, '');
  }

  void _restoreStopwatchIfNeeded() {
    final active = DatabaseService.getSetting(_swActive, defaultValue: false);
    if (active != true) return;
    _mode = TimerMode.stopwatch;
    _stopwatchElapsed = Duration(
        milliseconds: DatabaseService.getSetting(_swElapsedMs, defaultValue: 0));
    final runStartMs = DatabaseService.getSetting(_swRunStartMs, defaultValue: 0);
    if (runStartMs is int && runStartMs > 0) {
      _stopwatchRunStart = DateTime.fromMillisecondsSinceEpoch(runStartMs);
      _running = true;
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        _maybeUpdateStopwatchBackground();
        notifyListeners();
      });
    }
    final startedAtMs =
        DatabaseService.getSetting(_swStartedAtMs, defaultValue: 0);
    if (startedAtMs is int && startedAtMs > 0) {
      _stopwatchStartedAt = DateTime.fromMillisecondsSinceEpoch(startedAtMs);
    }
    final projectId = DatabaseService.getSetting(_swProjectId, defaultValue: '');
    if (projectId is String && projectId.isNotEmpty) {
      _currentProjectId = projectId;
    }
    final taskId = DatabaseService.getSetting(_swTaskId, defaultValue: '');
    if (taskId is String && taskId.isNotEmpty) {
      _currentTaskId = taskId;
    }
    _pendingRestorePrompt = true;
  }

  void _finish() {
    DebugLogger.log('FINISH', '_completing=$_completing, _mode=$_mode');
    print('COMPLETE|_finish entering completing=$_completing mode=$_mode');
    if (_completing) return; // dedupe: one completion per session
    _completing = true;
    _completeSession(showNotification: true);
  }

  /// Single completion path for a countdown session. [showNotification] is
  /// false only for Skip — an intentionally-ended session never notifies.
  void _completeSession({required bool showNotification}) {
    print('COMPLETE|_completeSession showNotification=$showNotification '
        'skipped=$_wasSkipped mode=$_mode');
    _timer?.cancel();
    _running = false;
    // Always cancel any still-pending OS-scheduled notification: on
    // foreground expiry it hasn't fired yet and must not double-notify;
    // when the app was closed/backgrounded it already fired and cancelling
    // a delivered id is a harmless no-op.
    NotificationService.cancel(_scheduledNotificationId);
    _endTime = null;
    _clearPersistedCountdown();
    unawaited(BackgroundTaskService.stop());

    if (showNotification) {
      AudioService.startCompletionLoop(
        DatabaseService.completionSoundEnabled
            ? completionSoundFromKey(DatabaseService.completionSoundType)
            : null,
      );

      // Dedup: when the OS-scheduled end alarm exists it fires exactly at
      // sessionEndTime — an immediate notification here would duplicate it.
      // Only post one directly when scheduling previously failed.
      if (!_endNotificationScheduled) {
        NotificationService.show(
          title: _notifTitle(_mode == TimerMode.focus),
          body: _notifBody(_mode == TimerMode.focus),
        );
      }
    }
    _endNotificationScheduled = false;

    if (_mode == TimerMode.focus) {
      _completedMode = _mode;
      _sessionCount++;
      DatabaseService.setSetting('sessionCount', _sessionCount);
      _isMilestone = _sessionCount % DatabaseService.longBreakInterval == 0;
      final projectName = _currentProjectId != null
          ? DatabaseService.getProject(_currentProjectId!)?.name
          : null;
      final quote = QuoteLibrary.getCompletionQuote(
        _sessionCount,
        isMilestone: _isMilestone,
        projectName: projectName,
      );
      _completionQuote = QuoteLibrary.quoteText(quote);
      _completionQuoteSource = quote['source'] ?? '';

      final actualElapsed = _startedAt != null
          ? DateTime.now().difference(_startedAt!).inSeconds
          : _totalSeconds - _seconds;
      _startedAt = null;
      final session = Session(
        id: const Uuid().v4(),
        projectId: _currentProjectId ?? '',
        durationMinutes: _totalSeconds ~/ 60,
        actualMinutes: actualElapsed ~/ 60,
        completed: !_wasSkipped,
        sessionType: 'focus',
        taskId: _currentTaskId,
      );
      DatabaseService.addSession(session);
      if (!_wasSkipped) {
        _lastCompletedSessionId = session.id;
        _checkProjectCompletion();
      }

      if (!_wasSkipped && _currentTaskId != null) {
        final task = DatabaseService.getTaskById(_currentTaskId!);
        if (task != null) {
          task.completedPomodoros++;
          DatabaseService.updateTask(task);
        }
      }

      if (!_wasSkipped) {
        if (!showNotification) {
          // Session ended while the app was closed/backgrounded (restore
          // path). Start the continuous vibration now so the user feels it
          // as soon as they reopen the app, until they dismiss the card.
          print('COMPLETE|restore starting background vibration');
          AudioService.startVibrationOnly();
        }
        print('COMPLETE|focus markCompleted session=${session.id} '
            'project=${_currentProjectId}');
        _sessionManager.markCompleted(
          sessionId: session.id,
          completedMode: _completedMode.name,
          sessionCount: _sessionCount,
          isMilestone: _isMilestone,
          completionQuote: _completionQuote,
          completionQuoteSource: _completionQuoteSource,
          durationMinutes: _totalSeconds ~/ 60,
          projectId: _currentProjectId,
          projectName: projectName,
        );
      } else {
        print('COMPLETE|skip acknowledged - no completion card');
      }
    } else if (_mode == TimerMode.shortBreak ||
        _mode == TimerMode.longBreak) {
      // A finished break shows the same immediate completion card as a
      // finished focus session — whether the app is open (tick path) or was
      // closed for the whole break (restore path -> showNotification=false).
      _completedMode = _mode;
      if (!_wasSkipped) {
        if (!showNotification) {
          // Break finished while the app was closed/backgrounded (restore
          // path). Start continuous vibration until the user dismisses.
          print('COMPLETE|restore starting background vibration (break)');
          AudioService.startVibrationOnly();
        }
        final quote = QuoteLibrary.getCompletionQuote(
          _sessionCount,
          isMilestone: false,
          projectName: null,
        );
        print('COMPLETE|break markCompleted mode=${_mode.name}');
        _sessionManager.markCompleted(
          sessionId: const Uuid().v4(),
          completedMode: _mode.name,
          sessionCount: _sessionCount,
          isMilestone: false,
          completionQuote: QuoteLibrary.quoteText(quote),
          completionQuoteSource: quote['source'] ?? '',
          durationMinutes: _totalSeconds ~/ 60,
        );
      } else {
        print('COMPLETE|skip acknowledged - no completion card');
      }
    }

    _switchMode();

    _wasSkipped = false;
    _completing = false; // ready for the next session

    notifyListeners();
  }

  // ─── Project weekly-goal completion ───
  String? _pendingCompletionProjectId;
  String? get pendingCompletionProjectId => _pendingCompletionProjectId;
  void consumeCompletion() => _pendingCompletionProjectId = null;

  /// Fires once per project per week when the weekly goal is reached.
  /// Overtime keeps counting as real minutes; the celebration triggers at
  /// the goal line only.
  void _checkProjectCompletion() {
    final pid = _currentProjectId;
    if (pid == null || pid.isEmpty) return;
    final project = DatabaseService.getProject(pid);
    if (project == null || project.weeklyGoalMinutes <= 0) return;

    final now = DateTime.now();
    final weekStart =
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: (now.weekday + 1) % 7));
    final weekMin = DatabaseService.getSessionsForWeek()
        .where((s) =>
            s.completed && s.projectId == pid && s.sessionType != 'tasbeeh')
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
    if (weekMin < project.weeklyGoalMinutes) return;

    final key =
        'projCompleted_${pid}_${weekStart.year}-${weekStart.month}-${weekStart.day}';
    if (DatabaseService.getSetting(key, defaultValue: false) == true) return;
    DatabaseService.setSetting(key, true);
    _pendingCompletionProjectId = pid;
  }

  void _switchMode() {
    final interval = DatabaseService.longBreakInterval;
    switch (_mode) {
      case TimerMode.focus:
        if (_sessionCount % interval == 0) {
          _mode = TimerMode.longBreak;
        } else {
          _mode = TimerMode.shortBreak;
        }        _updateDurationForMode();
        break;
      case TimerMode.shortBreak:
      case TimerMode.longBreak:
        _mode = TimerMode.focus;
        _updateDurationForMode();
        break;
      case TimerMode.stopwatch:
        break;
    }
  }

  void _updateDurationForMode() {
    switch (_mode) {
      case TimerMode.focus:
        _seconds = DatabaseService.focusDuration;
        _totalSeconds = DatabaseService.focusDuration;
        break;
      case TimerMode.shortBreak:
        _seconds = DatabaseService.shortBreakDuration;
        _totalSeconds = DatabaseService.shortBreakDuration;
        break;
      case TimerMode.longBreak:
        _seconds = DatabaseService.longBreakDuration;
        _totalSeconds = DatabaseService.longBreakDuration;
        break;
      case TimerMode.stopwatch:
        break;
    }
  }

  void setFocusDuration(int seconds) {
    if (!_running && _mode == TimerMode.focus) {
      _seconds = seconds;
      _totalSeconds = seconds;
      notifyListeners();
    }
  }

  void setShortBreakDuration(int seconds) {
    if (!_running && _mode == TimerMode.shortBreak) {
      _seconds = seconds;
      _totalSeconds = seconds;
      notifyListeners();
    }
  }

  void setLongBreakDuration(int seconds) {
    if (!_running && _mode == TimerMode.longBreak) {
      _seconds = seconds;
      _totalSeconds = seconds;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _timer?.cancel();
    if (stopwatchInProgress) _persistStopwatch();
    AudioService.stopAllSounds();
    unawaited(BackgroundTaskService.stop());
    super.dispose();
  }
}
