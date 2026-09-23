
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import 'database_service.dart';
import 'vibration_service.dart';

/// Tasbeeh as a first-class activity type reusing the existing
/// Session pipeline (sessionType = 'tasbeeh'). Survives process death
/// via settings snapshots written on every tap.
class TasbeehService extends ChangeNotifier {
  static const _kActive = 'tasbeehActive';
  static const _kCount = 'tasbihCount'; // legacy key, reused
  static const _kStartMs = 'tasbeehStartMs';
  static const _kProjectId = 'tasbeehProjectId';
  static const _kGoalOverride = 'tasbeehGoalOverride';
  static const _kCelebrated = 'tasbeehCelebrated';
  static const _kDhikrIndex = 'tasbeehDhikrIndex';

  /// Generic, unattributed adhkar phrases (AR display / EN fallback).
  static const List<(String, String)> dhikrOptions = [
    ('أستغفر الله', 'Astaghfirullah'),
    ('اللهم صلِّ على محمد', 'Allahumma salli ala Muhammad'),
    ('سبحان الله', 'Subhan Allah'),
    ('الحمد لله', 'Alhamdulillah'),
    ('الله أكبر', 'Allahu Akbar'),
    ('لا إله إلا الله', 'La ilaha illa Allah'),
  ];

  bool _active = false;
  int _count = 0;
  DateTime? _startedAt;
  String _projectId = '';
  bool _celebrated = false;

  bool get isActive => _active;
  int get count => _count;
  DateTime? get startedAt => _startedAt;
  String get projectId => _projectId;

  int get dhikrIndex {
    final v = DatabaseService.getSetting(_kDhikrIndex, defaultValue: 0);
    final i = v is int ? v : 0;
    return (i < 0 || i >= dhikrOptions.length) ? 0 : i;
  }

  String get currentDhikr {
    final isAr =
        DatabaseService.localeNotifier.value.languageCode == 'ar';
    final opt = dhikrOptions[dhikrIndex];
    return isAr ? opt.$1 : opt.$2;
  }

  void setDhikrIndex(int i) {
    DatabaseService.setSetting(
        _kDhikrIndex, i.clamp(0, dhikrOptions.length - 1));
    notifyListeners();
  }

  /// Elapsed session duration in seconds.
  int get elapsedSeconds {
    if (!_active || _startedAt == null) return 0;
    return DateTime.now().difference(_startedAt!).inSeconds;
  }

  /// Effective goal: explicit project goal wins; global override otherwise.
  int goal() {
    if (_projectId.isNotEmpty) {
      final p = DatabaseService.getProject(_projectId);
      if (p != null && p.tasbeehGoal > 0) return p.tasbeehGoal;
    }
    final o = DatabaseService.getSetting(_kGoalOverride, defaultValue: 0);
    return o is int ? o : 0;
  }

  double get progress {
    final g = goal();
    if (g <= 0) return 0;
    return (_count / g).clamp(0.0, 1.0);
  }

  bool get goalReached => goal() > 0 && _count >= goal();

  TasbeehService() {
    _restore();
  }

  void _restore() {
    final active = DatabaseService.getSetting(_kActive, defaultValue: false);
    if (active != true) return;
    final startMs =
        DatabaseService.getSetting(_kStartMs, defaultValue: 0);
    if (startMs is! int || startMs <= 0) {
      _clearPersisted();
      return;
    }
    _active = true;
    _count =
        (DatabaseService.getSetting(_kCount, defaultValue: 0) as int? ?? 0);
    _startedAt = DateTime.fromMillisecondsSinceEpoch(startMs);
    final pid = DatabaseService.getSetting(_kProjectId, defaultValue: '');
    if (pid is String) _projectId = pid;
    _celebrated = DatabaseService.getSetting(_kCelebrated, defaultValue: false) == true;
  }

  void setProject(String? pid) {
    if (_active && _count > 0) {
      // Project changed mid-session: bank what we have first.
      finishAndSave();
      return;
    }
    _projectId = pid ?? '';
    DatabaseService.setSetting(_kProjectId, _projectId);
  }

  void tap() {
    if (!_active) {
      _active = true;
      _count = 0;
      _startedAt = DateTime.now();
      _celebrated = false;
    }
    _count++;
    if (DatabaseService.completionVibrationEnabled) {
      // Maximum-strength native vibration per tap.
      VibrationService.vibrate(duration: 80, amplitude: 255);
    }
    if (!_celebrated && goalReached) {
      _celebrated = true;
      DatabaseService.setSetting(_kCelebrated, true);
      // Maximum-strength triple native vibrate for reaching the goal.
      VibrationService.pattern(
        timings: [0, 500, 200, 500, 200, 600],
        amplitudes: [255, 0, 255, 0, 255, 0],
      );
    }
    _persistSnapshot();
    notifyListeners();
  }

  /// Zeroes the counter; the running session timing is preserved.
  void resetCount() {
    _count = 0;
    _celebrated = false;
    DatabaseService.setSetting(_kCelebrated, false);
    _persistSnapshot();
    notifyListeners();
  }

  /// Saves the current session through the normal Session pipeline.
  /// No-ops safely when nothing meaningful was counted.
  void finishAndSave({bool notifyUi = true}) {
    if (!_active) return;
    final secs = elapsedSeconds;
    final countSnapshot = _count;
    final start = _startedAt;
    final pid = _projectId;
    _deactivate();

    if (countSnapshot <= 0 || secs < 1) return;
    final minutes = (secs / 60).ceil();
    final session = Session(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      projectId: pid,
      durationMinutes: minutes,
      actualMinutes: minutes,
      actualSeconds: secs,
      completed: true,
      sessionType: 'tasbeeh',
      startTime: start,
      endTime: DateTime.now(),
      count: countSnapshot,
      notes: currentDhikr,
    );
    DatabaseService.addSession(session);
    if (notifyUi) notifyListeners();
  }

  void _deactivate() {
    _active = false;
    _count = 0;
    _startedAt = null;
    _celebrated = false;
    _clearPersisted();
    notifyListeners();
  }

  /// Long-press goal selection. Persists on the project when one is
  /// selected so the ring survives across sessions; global override
  /// otherwise. Pass 0 to clear.
  void setGoal(int? value) {
    final v = (value ?? 0).clamp(0, 1000000);
    if (_projectId.isNotEmpty) {
      final p = DatabaseService.getProject(_projectId);
      if (p != null) {
        p.tasbeehGoal = v;
        DatabaseService.updateProject(p);
        notifyListeners();
        return;
      }
    }
    DatabaseService.setSetting(_kGoalOverride, v);
    notifyListeners();
  }

  void _persistSnapshot() {
    DatabaseService.setSetting(_kActive, true);
    DatabaseService.setSetting(_kCount, _count);
    DatabaseService.setSetting(
        _kStartMs, _startedAt?.millisecondsSinceEpoch ?? 0);
    DatabaseService.setSetting(_kProjectId, _projectId);
  }

  void _clearPersisted() {
    DatabaseService.setSetting(_kActive, false);
    DatabaseService.setSetting(_kCount, 0);
    DatabaseService.setSetting(_kStartMs, 0);
  }
}
