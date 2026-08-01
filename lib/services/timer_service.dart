import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'audio_service.dart';
import 'notification_service.dart';
import 'database_service.dart';
import '../models/session.dart';

enum TimerMode { focus, shortBreak, longBreak }

class TimerService extends ChangeNotifier {
  Timer? _timer;
  int _seconds = 1500;
  int _totalSeconds = 1500;
  bool _running = false;
  TimerMode _mode = TimerMode.focus;
  int _sessionCount = 0;
  String? _currentProjectId;
  String? _currentTaskId;
  bool _autoStartBreaks = true;
  bool _autoStartPomodoros = false;
  bool _sessionJustCompleted = false;
  bool _isMilestone = false;
  String _completionQuote = '';
  TimerMode _completedMode = TimerMode.focus;
  String? _lastCompletedSessionId;
  bool _wasSkipped = false;

  TimerService() {
    _sessionCount = DatabaseService.getSetting('sessionCount', defaultValue: 0);
    _seconds = DatabaseService.focusDuration * 60;
    _totalSeconds = DatabaseService.focusDuration * 60;
  }

  void Function()? onSessionComplete;
  void Function(int breakMinutes)? onBreakStart;

  int get seconds => _seconds;
  int get totalSeconds => _totalSeconds;
  bool get running => _running;
  TimerMode get mode => _mode;
  int get sessionCount => _sessionCount;
  String? get currentProjectId => _currentProjectId;
  String? get currentTaskId => _currentTaskId;
  bool get autoStartBreaks => _autoStartBreaks;
  bool get autoStartPomodoros => _autoStartPomodoros;
  bool get sessionJustCompleted => _sessionJustCompleted;
  bool get isMilestone => _isMilestone;
  String get completionQuote => _completionQuote;
  TimerMode get completedMode => _completedMode;
  String? get lastCompletedSessionId => _lastCompletedSessionId;
  bool get wasSkipped => _wasSkipped;

  double get progress =>
      _totalSeconds > 0 ? 1.0 - (_seconds / _totalSeconds) : 0.0;

  String get formattedTime {
    final mins = (_seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get modeLabel {
    switch (_mode) {
      case TimerMode.focus:
        return 'Focus';
      case TimerMode.shortBreak:
        return 'Short Break';
      case TimerMode.longBreak:
        return 'Long Break';
    }
  }

  String get motivationalQuote {
    final quotes = [
      "Stay focused, stay powerful!",
      "Every minute counts!",
      "You're doing great!",
      "Deep work, deep results.",
      "One session at a time.",
      "Progress, not perfection.",
      "Your future self will thank you.",
      "Discipline is freedom.",
      "Focus is your superpower.",
      "Keep going, you're almost there!",
      "Small steps lead to big results.",
      "Consistency is key!",
      "Make this session count!",
      "You've got this!",
      "Stay in the zone.",
    ];
    final index = _sessionCount % quotes.length;
    return quotes[index];
  }

  String get completionMessage {
    final messages = [
      "Brilliant focus! Your dedication is paying off. Keep this momentum!",
      "Another one in the bag! You're building something amazing, one session at a time.",
      "That was intense! You gave it your all. Now recharge and come back stronger.",
      "Champion mindset! Every session makes you sharper and more unstoppable.",
      "Focused mind, powerful results. You just proved what you're capable of!",
      "Incredible work! Your discipline today is building tomorrow's success.",
      "You showed up and delivered. That's what separates winners from the rest.",
      "Peak performance! You're in the zone and nothing can stop you.",
      "Outstanding effort! Your consistency is your greatest weapon.",
      "One step closer to your goals. Every session is a victory!",
    ];
    return messages[_sessionCount % messages.length];
  }

  String get milestoneMessage {
    final messages = [
      "4 sessions crushed! You're on a legendary streak!",
      "Milestone reached! Your dedication is truly inspiring!",
      "4 in a row! You're building unstoppable momentum!",
      "Incredible milestone! Your hard work is paying off big time!",
      "4 sessions strong! You're operating at an elite level!",
    ];
    return messages[(_sessionCount ~/ 4) % messages.length];
  }

  void consumeSessionJustCompleted() {
    _sessionJustCompleted = false;
    _isMilestone = false;
  }

  void setDuration(TimerMode mode, int minutes) {
    if (_running) return;
    _mode = mode;
    _seconds = minutes * 60;
    _totalSeconds = minutes * 60;
    notifyListeners();
  }

  void setProject(String? projectId) {
    _currentProjectId = projectId;
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
    notifyListeners();
  }

  void setAutoStartBreaks(bool value) {
    _autoStartBreaks = value;
    notifyListeners();
  }

  void setAutoStartPomodoros(bool value) {
    _autoStartPomodoros = value;
    notifyListeners();
  }

  void start() {
    if (_running) return;
    AudioService.stopAlarm();
    _running = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds > 0) {
        _seconds--;
        if (_seconds <= 10 && _seconds > 0 && DatabaseService.tickSoundEnabled) {
          AudioService.playTick();
        }
        notifyListeners();
      } else {
        _finish();
      }
    });
    notifyListeners();
  }

  void pause() {
    _timer?.cancel();
    _running = false;
    AudioService.stopAlarm();
    notifyListeners();
  }

  void reset() {
    _timer?.cancel();
    _running = false;
    AudioService.stopAlarm();
    _seconds = _totalSeconds;
    notifyListeners();
  }

  void skip() {
    _timer?.cancel();
    _running = false;
    AudioService.stopAlarm();
    _wasSkipped = true;
    _finish();
  }

  void stopAlarm() {
    AudioService.stopAlarm();
    notifyListeners();
  }

  void _finish() {
    _timer?.cancel();
    _running = false;

    if (DatabaseService.soundEnabled) {
      AudioService.playFinish();
      Future.delayed(const Duration(milliseconds: 1500), () {
        AudioService.startAlarm();
        notifyListeners();
      });
    }

    NotificationService.show(
      title: _mode == TimerMode.focus ? 'Focus Session Complete!' : 'Break Over!',
      body: _mode == TimerMode.focus
          ? 'Great work! Time for a break.'
          : 'Ready to focus again?',
    );

    if (_mode == TimerMode.focus) {
      _completedMode = _mode;
      _sessionCount++;
      DatabaseService.setSetting('sessionCount', _sessionCount);
      _isMilestone = _sessionCount % DatabaseService.longBreakInterval == 0;
      _completionQuote = _isMilestone ? milestoneMessage : completionMessage;
      _sessionJustCompleted = true;

      final session = Session(
        id: const Uuid().v4(),
        projectId: _currentProjectId ?? '',
        durationMinutes: _totalSeconds ~/ 60,
        completed: !_wasSkipped,
        sessionType: 'focus',
        taskId: _currentTaskId,
      );
      DatabaseService.addSession(session);
      _lastCompletedSessionId = session.id;

      if (!_wasSkipped && _currentTaskId != null) {
        final task = DatabaseService.getTaskById(_currentTaskId!);
        if (task != null) {
          task.completedPomodoros++;
          DatabaseService.updateTask(task);
        }
      }

      onSessionComplete?.call();
    }

    _switchMode();

    _wasSkipped = false;

    notifyListeners();
  }

  void _switchMode() {
    final interval = DatabaseService.longBreakInterval;
    switch (_mode) {
      case TimerMode.focus:
        if (_sessionCount % interval == 0) {
          _mode = TimerMode.longBreak;
        } else {
          _mode = TimerMode.shortBreak;
        }
        _updateDurationForMode();
        break;
      case TimerMode.shortBreak:
      case TimerMode.longBreak:
        _mode = TimerMode.focus;
        _updateDurationForMode();
        break;
    }
  }

  void _updateDurationForMode() {
    switch (_mode) {
      case TimerMode.focus:
        _seconds = DatabaseService.focusDuration * 60;
        _totalSeconds = DatabaseService.focusDuration * 60;
        break;
      case TimerMode.shortBreak:
        _seconds = DatabaseService.shortBreakDuration * 60;
        _totalSeconds = DatabaseService.shortBreakDuration * 60;
        break;
      case TimerMode.longBreak:
        _seconds = DatabaseService.longBreakDuration * 60;
        _totalSeconds = DatabaseService.longBreakDuration * 60;
        break;
    }
  }

  void setFocusDuration(int minutes) {
    if (!_running && _mode == TimerMode.focus) {
      _seconds = minutes * 60;
      _totalSeconds = minutes * 60;
      notifyListeners();
    }
  }

  void setShortBreakDuration(int minutes) {
    if (!_running && _mode == TimerMode.shortBreak) {
      _seconds = minutes * 60;
      _totalSeconds = minutes * 60;
      notifyListeners();
    }
  }

  void setLongBreakDuration(int minutes) {
    if (!_running && _mode == TimerMode.longBreak) {
      _seconds = minutes * 60;
      _totalSeconds = minutes * 60;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.stopAlarm();
    super.dispose();
  }
}
