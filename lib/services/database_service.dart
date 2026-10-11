import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../models/day_goal.dart';
import '../models/stage_item.dart';
import '../utils/constants.dart';
import '../utils/productivity_quotes.dart';

class DatabaseService {
  static const String _projectsBox = 'projects';
  static const String _sessionsBox = 'sessions';
  static const String _tasksBox = 'tasks';
  static const String _settingsBox = 'settings';
  static const String _dayGoalsBox = 'dayGoals';
  static const String _customQuotesBox = 'customQuotes';

  static late Box<Project> _projects;
  static late Box<Session> _sessions;
  static late Box<Task> _tasks;
  static late Box _settings;
  static late Box<DayGoal> _dayGoals;
  static late Box _customQuotes;

  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
  static final ValueNotifier<double> zoomNotifier = ValueNotifier(1.0);
  static final ValueNotifier<int> goalsRevision = ValueNotifier(0);
  static final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('ar'));

  /// True only when the settings box was completely empty at startup,
  /// i.e. the app has never run on this device (true fresh install).
  /// Captured BEFORE migrations write their flags, so existing installs
  /// (which always carry keys) are never mistaken for fresh ones.
  static bool _isFreshInstall = false;
  static bool get isFreshInstall => _isFreshInstall;

  static Future<void> init({String? hivePath}) async {
    if (hivePath != null) {
      Hive.init(hivePath);
    } else {
      await Hive.initFlutter();
    }

    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(SessionAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(DayGoalAdapter());
    Hive.registerAdapter(StageItemAdapter());

    _projects = await Hive.openBox<Project>(_projectsBox);
    _sessions = await Hive.openBox<Session>(_sessionsBox);
    _tasks = await Hive.openBox<Task>(_tasksBox);
    _settings = await Hive.openBox(_settingsBox);
    _dayGoals = await Hive.openBox<DayGoal>(_dayGoalsBox);
    _customQuotes = await Hive.openBox(_customQuotesBox);

    _isFreshInstall = _settings.isEmpty;

    await _migrateDurationsToSeconds();
    await _migrateProjectDurationsToSeconds();
    await _migrateSoundSettings();

    darkModeNotifier.value = darkMode;
    zoomNotifier.value = appZoom;
    final langCode = getSetting('language', defaultValue: 'ar');
    localeNotifier.value = Locale(langCode is String ? langCode : 'ar');
  }

  static Future<void> _migrateDurationsToSeconds() async {
    if (getSetting('durationsInSeconds', defaultValue: false) == true) return;
    final focus = getSetting('focusDuration');
    final short = getSetting('shortBreakDuration');
    final long = getSetting('longBreakDuration');
    if (focus is int) {
      await _settings.put('focusDuration', focus * 60);
    }
    if (short is int) {
      await _settings.put('shortBreakDuration', short * 60);
    }
    if (long is int) {
      await _settings.put('longBreakDuration', long * 60);
    }
    await _settings.put('durationsInSeconds', true);
  }

  static Future<void> _migrateProjectDurationsToSeconds() async {
    if (getSetting('projectDurationsInSeconds', defaultValue: false) == true) {
      return;
    }
    for (final project in _projects.values) {
      if (project.defaultDuration <= 120) {
        project.defaultDuration = project.defaultDuration * 60;
        await project.save();
      }
    }
    await _settings.put('projectDurationsInSeconds', true);
  }

  // Projects
  static List<Project> getAllProjects() {
    return _projects.values.where((p) => !p.isArchived).toList();
  }

  static List<Project> getArchivedProjects() {
    return _projects.values.where((p) => p.isArchived).toList();
  }

  static Project? getProject(String id) {
    return _projects.get(id);
  }

  static Future<void> addProject(Project project) async {
    await _projects.put(project.id, project);
  }

  static Future<void> updateProject(Project project) async {
    await _projects.put(project.id, project);
  }

  static Future<void> deleteProject(String id) async {
    await _projects.delete(id);
  }

  static Future<void> deleteProjectCompletely(String id) async {
    final sessionsToDelete = _sessions.values
        .where((s) => s.projectId == id)
        .toList();
    for (final s in sessionsToDelete) {
      await _sessions.delete(s.id);
    }
    final tasksToDelete = _tasks.values
        .where((t) => t.projectId == id)
        .toList();
    for (final t in tasksToDelete) {
      await _tasks.delete(t.id);
    }
    await _projects.delete(id);
  }

  static Future<void> archiveProject(String id) async {
    final project = _projects.get(id);
    if (project != null) {
      project.isArchived = true;
      await project.save();
    }
  }

  // Sessions
  /// Calendar-day offset. `DateTime.add(Duration(days: n))` adds 24 absolute
  /// hours, so across a DST fall-back midnight lands on 23:00 of the *same*
  /// calendar date — which duplicated one day and skipped the next in every
  /// weekly chart and the heat map. Building the date components directly is
  /// always calendar-correct.
  static DateTime _dayOffset(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);

  /// Today at midnight. Anchoring week maths here also normalises the
  /// time-of-day, which `now.subtract(...)` never did.
  static DateTime get _todayMidnight {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Midnight of the current week. The week starts on **Saturday**.
  static DateTime get _startOfWeekMidnight =>
      _dayOffset(_todayMidnight, -((_todayMidnight.weekday + 1) % 7));

  static List<Session> getAllSessions() {
    return _sessions.values.toList();
  }

  static List<Session> getSessionsForProject(String projectId) {
    return _sessions.values
        .where((s) => s.projectId == projectId)
        .toList();
  }

  static List<Session> getSessionsForDate(DateTime date) {
    return _sessions.values.where((s) {
      return s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day;
    }).toList();
  }

  static List<Session> getSessionsForWeek() {
    final startOfWeek = _startOfWeekMidnight;
    return _sessions.values.where((s) {
      return !s.date.isBefore(startOfWeek);
    }).toList();
  }

  static List<Session> getSessionsForMonth() {
    final now = DateTime.now();
    return _sessions.values.where((s) {
      return s.date.year == now.year && s.date.month == now.month;
    }).toList();
  }

  /// Serialises the read-modify-write of project counters so two sessions
/// completing back-to-back cannot interleave `get -> ++ -> save` and lose an
/// increment.
  static Future<void> _counterQueue = Future<void>.value();

  static Future<T> _withCounterLock<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    final previous = _counterQueue;
    _counterQueue = () async {
      try {
        await previous;
      } catch (_) {}
      try {
        completer.complete(await action());
      } catch (error, stack) {
        completer.completeError(error, stack);
      }
    }();
    return completer.future;
  }

  static Future<void> addSession(Session session) async {
    await _sessions.put(session.id, session);

    // Use the same predicate as every read-side aggregate, otherwise tasbeeh
    // and stopwatch rounds inflate the project counters that the detail screen
    // (which filters them out) then disagrees with.
    if (_isTimerSession(session)) {
      await _withCounterLock(() async {
        final project = _projects.get(session.projectId);
        if (project != null) {
          project.totalSessions++;
          project.totalMinutes +=
              (session.actualMinutes ?? session.durationMinutes);
          await project.save();
        }
      });
    }
    goalsRevision.value++;
  }

  static Future<void> deleteSession(String id) async {
    final session = _sessions.get(id);
    if (session == null) return;
    if (_isTimerSession(session)) {
      await _withCounterLock(() async {
        final project = _projects.get(session.projectId);
        if (project != null) {
          // Clamp: the counters can already be out of sync with the session
          // set (e.g. after a backup restore), and must never go negative.
          project.totalSessions = (project.totalSessions - 1).clamp(0, 1 << 30);
          project.totalMinutes =
              (project.totalMinutes - (session.actualMinutes ?? session.durationMinutes))
                  .clamp(0, 1 << 31);
          await project.save();
        }
      });
    }
    await _sessions.delete(id);
    goalsRevision.value++;
  }

  // Day Goals
  static String dateKeyOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DayGoal? getDayGoal(String dateKey) => _dayGoals.get(dateKey);

  static DayGoal getOrCreateDayGoal(String dateKey) {
    return _dayGoals.get(dateKey) ??
        DayGoal(dateKey: dateKey, goalMinutes: 0);
  }

  static Future<void> saveDayGoal(DayGoal goal) async {
    await _dayGoals.put(goal.dateKey, goal);
    goalsRevision.value++;
  }

  static Future<void> deleteDayGoal(String dateKey) async {
    await _dayGoals.delete(dateKey);
    goalsRevision.value++;
  }

  /// Timer-minute predicate: tasbeeh sessions carry repetitions, not
  /// focus minutes, so they are excluded from every minute/streak
  /// aggregate while remaining fully visible in history & timelines.
  static bool _isTimerSession(Session s) =>
      s.completed && s.sessionType != 'tasbeeh';

  /// Sum of today's tasbeeh repetitions (repetitions, not minutes).
  static int getTasbeehCountForDay(DateTime date) {
    return _sessions.values
        .where((s) =>
            s.completed &&
            s.sessionType == 'tasbeeh' &&
            s.date.year == date.year &&
            s.date.month == date.month &&
            s.date.day == date.day)
        .fold(0, (sum, s) => sum + (s.count ?? 0));
  }

  /// All-time tasbeeh repetitions.
  static int getTasbeehTotalCount() {
    return _sessions.values
        .where((s) => s.completed && s.sessionType == 'tasbeeh')
        .fold(0, (sum, s) => sum + (s.count ?? 0));
  }

  static int getCompletedMinutesForDay(DateTime date,
      {bool onlyInWeeklyGoal = false}) {
    final sessions = getSessionsForDate(date).where(_isTimerSession);
    int total = 0;
    for (final s in sessions) {
      if (onlyInWeeklyGoal) {
        final project = _projects.get(s.projectId);
        if (project == null || !project.includeInWeeklyGoal) continue;
      }
      total += (s.actualMinutes ?? s.durationMinutes);
    }
    return total;
  }

  static int getCompletedMinutesForWeek({bool onlyInWeeklyGoal = false}) {
    final sessions = getSessionsForWeek().where(_isTimerSession);
    int total = 0;
    for (final s in sessions) {
      if (onlyInWeeklyGoal) {
        final project = _projects.get(s.projectId);
        if (project == null || !project.includeInWeeklyGoal) continue;
      }
      total += (s.actualMinutes ?? s.durationMinutes);
    }
    return total;
  }

  static List<int> getDailyCompletedMinutesThisWeek({bool onlyInWeeklyGoal = false}) {
    final startOfWeek = _startOfWeekMidnight;
    final list = <int>[];
    for (int i = 0; i < 7; i++) {
      final day = _dayOffset(startOfWeek, i);
      list.add(getCompletedMinutesForDay(day, onlyInWeeklyGoal: onlyInWeeklyGoal));
    }
    return list;
  }

  static Future<void> setDailyGoalMinutes(int minutes) async {
    await setSetting('dailyGoalMinutes', minutes);
    goalsRevision.value++;
  }

  static Future<void> setWeeklyGoalMinutes(int minutes) async {
    await setSetting('weeklyGoalMinutes', minutes);
    goalsRevision.value++;
  }

  // Statistics
  static int getTodayMinutes() {
    final sessions = getSessionsForDate(DateTime.now());
    return sessions
        .where(_isTimerSession)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  static int getWeekMinutes() {
    final sessions = getSessionsForWeek();
    return sessions
        .where(_isTimerSession)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  static int getMonthMinutes() {
    final sessions = getSessionsForMonth();
    return sessions
        .where(_isTimerSession)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  static int getTodaySessions() {
    return getSessionsForDate(DateTime.now())
        .where(_isTimerSession)
        .length;
  }

  static int getWeekSessions() {
    return getSessionsForWeek()
        .where(_isTimerSession)
        .length;
  }

  static Map<String, int> getProjectMinutesThisWeek() {
    final sessions = getSessionsForWeek().where(_isTimerSession);
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.projectId] = (map[s.projectId] ?? 0) + (s.actualMinutes ?? s.durationMinutes);
    }
    return map;
  }

  static List<double> getDailyMinutesThisWeek() {
    final startOfWeek = _startOfWeekMidnight;
    final dailyMinutes = List<double>.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final day = _dayOffset(startOfWeek, i);
      final daySessions = getSessionsForDate(day).where(_isTimerSession);
      dailyMinutes[i] =
          daySessions.fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes)).toDouble();
    }
    return dailyMinutes;
  }

  static String? getBestProjectThisWeek() {
    final map = getProjectMinutesThisWeek();
    if (map.isEmpty) return null;
    final bestId = map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return _projects.get(bestId)?.name;
  }

  static double getAverageSessionDuration() {
    final sessions = _sessions.values.where(_isTimerSession).toList();
    if (sessions.isEmpty) return 0;
    final total = sessions.fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
    return total / sessions.length;
  }

  static int getProjectTodayMinutes(String projectId) {
    return getSessionsForDate(DateTime.now())
        .where((s) => _isTimerSession(s) && s.projectId == projectId)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  static int getProjectWeekMinutes(String projectId) {
    return getSessionsForWeek()
        .where((s) => _isTimerSession(s) && s.projectId == projectId)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  static int getProjectWeekSessions(String projectId) {
    return getSessionsForWeek()
        .where((s) => _isTimerSession(s) && s.projectId == projectId)
        .length;
  }

  static int getProjectStreak(String projectId) {
    int streak = 0;
    final today = _todayMidnight;
    for (int i = 0; i < 365; i++) {
      final day = _dayOffset(today, -i);
      final daySessions = getSessionsForDate(day)
          .where((s) => _isTimerSession(s) && s.projectId == projectId);
      if (daySessions.isNotEmpty) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  static List<double> getProjectDailyMinutesThisWeek(String projectId) {
    final startOfWeek = _startOfWeekMidnight;
    final dailyMinutes = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final day = _dayOffset(startOfWeek, i);
      final daySessions = getSessionsForDate(day)
          .where((s) => _isTimerSession(s) && s.projectId == projectId);
      dailyMinutes[i] =
          daySessions.fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes)).toDouble();
    }
    return dailyMinutes;
  }

  static List<Session> getRecentSessionsForProject(String projectId,
      {int limit = 10}) {
    final sessions = _sessions.values
        .where((s) => s.projectId == projectId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sessions.take(limit).toList();
  }

  static List<Map<String, dynamic>> getProjectBreakdown() {
    final sessions = getSessionsForWeek().where(_isTimerSession);
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.projectId] = (map[s.projectId] ?? 0) + (s.actualMinutes ?? s.durationMinutes);
    }
    final list = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final project = _projects.get(entry.key);
      if (project != null) {
        list.add({
          'name': project.name,
          'color': Color(project.colorValue),
          'minutes': entry.value,
          'icon': project.icon,
        });
      }
    }
    list.sort((a, b) => (b['minutes'] as int) - (a['minutes'] as int));
    return list;
  }

  static int getOverallStreak() {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final daySessions =
          getSessionsForDate(day).where(_isTimerSession);
      if (daySessions.isNotEmpty) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  static int getTotalAllTimeMinutes() {
    return _sessions.values
        .where(_isTimerSession)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  static int getTotalAllTimeSessions() {
    return _sessions.values.where(_isTimerSession).length;
  }

  static List<Session> getRecentSessions({int limit = 50}) {
    final sessions = _sessions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sessions.take(limit).toList();
  }

  static List<List<int>> getHeatMapData({int weeks = 16}) {
    final today = _todayMidnight;
    final startDay =
        _dayOffset(today, -((today.weekday + 1) % 7 + (weeks - 1) * 7));
    final data = <List<int>>[];
    for (int w = 0; w < weeks; w++) {
      final week = <int>[];
      for (int d = 0; d < 7; d++) {
        final day = _dayOffset(startDay, w * 7 + d);
        if (day.isAfter(today)) {
          week.add(-1);
        } else {
          final mins = getSessionsForDate(day)
              .where(_isTimerSession)
              .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
          week.add(mins);
        }
      }
      data.add(week);
    }
    return data;
  }

  // Tasks
  static List<Task> getAllTasks() {
    return _tasks.values.toList();
  }

  static List<Task> getTodayTasks() {
    final now = DateTime.now();
    return _tasks.values.where((t) {
      return t.createdAt.year == now.year &&
          t.createdAt.month == now.month &&
          t.createdAt.day == now.day;
    }).toList()
      ..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  static Task? getTaskById(String id) {
    return _tasks.get(id);
  }

  static Future<void> addTask(Task task) async {
    await _tasks.put(task.id, task);
  }

  static Future<void> updateTask(Task task) async {
    await _tasks.put(task.id, task);
  }

  static Future<void> deleteTask(String id) async {
    await _tasks.delete(id);
  }

  static Future<void> toggleTask(String id) async {
    final task = _tasks.get(id);
    if (task != null) {
      task.isDone = !task.isDone;
      await task.save();
    }
  }

  static int get todayTasksCompleted {
    return getTodayTasks().where((t) => t.isDone).length;
  }

  static int get todayTasksTotal {
    return getTodayTasks().length;
  }

  // Session Rating
  static Future<void> rateSession(String sessionId, int rating, {String? notes}) async {
    final session = _sessions.get(sessionId);
    if (session != null) {
      session.rating = rating;
      session.notes = notes;
      await session.save();
    }
  }

  // Settings
  static Future<void> setSetting(String key, dynamic value) async {
    await _settings.put(key, value);
    if (key == 'darkMode') {
      darkModeNotifier.value = value as bool;
    } else if (key == 'appZoom') {
      zoomNotifier.value = (value as num).toDouble();
    }
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue);
  }

  static int get focusDuration => getSetting('focusDuration', defaultValue: 1500);
  static int get shortBreakDuration =>
      getSetting('shortBreakDuration', defaultValue: 300);
  static int get longBreakDuration =>
      getSetting('longBreakDuration', defaultValue: 900);
  static bool get darkMode => getSetting('darkMode', defaultValue: false);
  static bool get autoStartBreaks =>
      getSetting('autoStartBreaks', defaultValue: true);
  static bool get autoStartPomodoros =>
      getSetting('autoStartPomodoros', defaultValue: false);
  static bool get completionSoundEnabled =>
      getSetting('completionSoundEnabled', defaultValue: true);
  static String get completionSoundType =>
      getSetting('completionSoundType', defaultValue: 'wind_chime');
  static bool get countdownSoundEnabled =>
      getSetting('countdownSoundEnabled', defaultValue: true);
  static String get countdownSoundType =>
      getSetting('countdownSoundType', defaultValue: 'water_drops');
  static int get countdownSeconds =>
      getSetting('countdownSeconds', defaultValue: 10);
  static double get ambientVolume => getSetting('ambientVolume', defaultValue: 0.4);

  static Future<void> _migrateSoundSettings() async {
    if (getSetting('soundSettingsMigrated', defaultValue: false) == true) return;

    final oldTickEnabled = getSetting('tickSoundEnabled', defaultValue: true);
    final oldSoundEnabled = getSetting('soundEnabled', defaultValue: true);
    final oldCompletionSound = getSetting('completionSound', defaultValue: 'soft_bell');

    await _settings.put('completionSoundEnabled', oldSoundEnabled);
    await _settings.put('completionSoundType', oldCompletionSound);
    await _settings.put('countdownSoundEnabled', oldTickEnabled);
    await _settings.put('countdownSoundType', 'water_drops');
    await _settings.put('countdownSeconds', 10);

    await _settings.delete('soundEnabled');
    await _settings.delete('tickSoundEnabled');
    await _settings.delete('completionSound');
    await _settings.put('soundSettingsMigrated', true);
  }

  static int get dailyGoal => getSetting('dailyGoal', defaultValue: AppConstants.dailyGoalDefault);
  static int get dailyGoalMinutes => getSetting('dailyGoalMinutes', defaultValue: 0);
  static int get weeklyGoalMinutes => getSetting('weeklyGoalMinutes', defaultValue: 0);

  /// Single source of truth for the daily target in minutes.
  /// Prefers the minutes-based setting; falls back to legacy hours-based.
  static int get dailyTargetMinutes {
    final m = dailyGoalMinutes;
    if (m > 0) return m;
    return dailyGoal * 60;
  }
  static double get appZoom => getSetting('appZoom', defaultValue: 1.0);
  static int get longBreakInterval {
    final v = getSetting('longBreakInterval', defaultValue: 4);
    // Guard against corrupted/restored values of 0 or 1, which would crash
    // the `% interval` calls in TimerService.
    return v is int && v >= 2 ? v : 4;
  }

  static bool get completionVibrationEnabled =>
      getSetting('completionVibrationEnabled', defaultValue: true);

  // ------- Quote favorites -------
  static Set<String> get favoriteQuotes {
    final raw = (getSetting('favoriteQuotes', defaultValue: '') as String?) ?? '';
    return raw.split(',').where((s) => s.isNotEmpty).toSet();
  }

  static Future<void> toggleFavoriteQuote(String id) async {
    final favs = favoriteQuotes;
    if (!favs.add(id)) favs.remove(id);
    await setSetting('favoriteQuotes', favs.join(','));
    quoteFavoritesNotifier.value = favs;
  }

  static final ValueNotifier<Set<String>> quoteFavoritesNotifier =
      ValueNotifier(favoriteQuotes);

  static Future<void> deleteAllData() async {
    await _sessions.clear();
    await _projects.clear();
    await _tasks.clear();
    // Daily goals, carry-over minutes and stage plans live in their own box.
    // Leaving them behind meant a "reset" still showed the old goal rings.
    await _dayGoals.clear();
    await _settings.clear();
    darkModeNotifier.value = false;
    zoomNotifier.value = 1.0;
    // Reset the language notifier too: _settings.clear() deleted the
    // 'language' key, so leaving this set would keep the old language on
    // screen until relaunch and then silently revert.
    localeNotifier.value = const Locale('ar');
    quoteFavoritesNotifier.value = <String>{};
    // GoalsService only listens to this notifier; without the bump the goal
    // ring keeps rendering the pre-reset state until a manual refresh.
    goalsRevision.value++;
  }

  static String createBackup() {
    final data = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'projects': _projects.toMap().map((k, v) => MapEntry(k, v.toMap())),
      'sessions': _sessions.toMap().map((k, v) => MapEntry(k, {
        'id': v.id,
        'projectId': v.projectId,
        'date': v.date.toIso8601String(),
        'durationMinutes': v.durationMinutes,
        'completed': v.completed,
        'sessionType': v.sessionType,
        'rating': v.rating,
        'notes': v.notes,
        'taskId': v.taskId,
        'actualMinutes': v.actualMinutes,
        'actualSeconds': v.actualSeconds,
        'startTime': v.startTime?.toIso8601String(),
        'endTime': v.endTime?.toIso8601String(),
        // Tasbeeh repetition count. Omitting it silently reset every
        // tasbeeh total to zero after a backup round-trip.
        'count': v.count,
      })),
      'tasks': _tasks.toMap().map((k, v) => MapEntry(k, {
        'id': v.id,
        'title': v.title,
        'isDone': v.isDone,
        'createdAt': v.createdAt.toIso8601String(),
        'estimatedPomodoros': v.estimatedPomodoros,
        'completedPomodoros': v.completedPomodoros,
        'projectId': v.projectId,
        'priority': v.priority,
        'description': v.description,
      })),
      'settings': _settings.toMap(),
      'dayGoals': _dayGoals.toMap().map((k, v) => MapEntry(k, v.toMap())),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Restores a backup. Every record is parsed and validated *before* any
  /// write, so a malformed field cannot leave the store half-overwritten.
  /// Returns the number of restored records.
  static Future<int> restoreBackup(String jsonString) async {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException catch (e) {
      throw FormatException('Backup file is not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Backup file must contain a JSON object at the top level.');
    }

    final projectRecords = <MapEntry<String, Project>>[];
    final projects = decoded['projects'];
    if (projects is Map) {
      for (final entry in projects.entries) {
        if (entry.value is! Map) continue;
        try {
          projectRecords.add(MapEntry(
            entry.key.toString(),
            Project.fromMap(Map<String, dynamic>.from(entry.value as Map)),
          ));
        } catch (_) {
          // Skip an unreadable project rather than aborting the restore.
        }
      }
    }

    final sessionRecords = <MapEntry<String, Session>>[];
    final sessions = decoded['sessions'];
    if (sessions is Map) {
      for (final entry in sessions.entries) {
        final s = entry.value;
        if (s is! Map) continue;
        try {
          sessionRecords.add(MapEntry(
            entry.key.toString(),
            Session(
              id: s['id'] ?? entry.key,
              projectId: s['projectId'] ?? '',
              date: s['date'] != null ? _parseLocal(s['date']) : DateTime.now(),
              durationMinutes: (s['durationMinutes'] as num?)?.toInt() ?? 0,
              completed: s['completed'] == true,
              sessionType: s['sessionType'] ?? 'focus',
              rating: (s['rating'] as num?)?.toInt(),
              notes: s['notes'],
              taskId: s['taskId'],
              actualMinutes: (s['actualMinutes'] as num?)?.toInt(),
              actualSeconds: (s['actualSeconds'] as num?)?.toInt(),
              count: (s['count'] as num?)?.toInt(),
              startTime:
                  s['startTime'] != null ? _parseLocal(s['startTime']) : null,
              endTime: s['endTime'] != null ? _parseLocal(s['endTime']) : null,
            ),
          ));
        } catch (_) {
          // Skip a malformed session instead of aborting the whole restore.
        }
      }
    }

    final taskRecords = <MapEntry<String, Task>>[];
    final tasks = decoded['tasks'];
    if (tasks is Map) {
      for (final entry in tasks.entries) {
        final t = entry.value;
        if (t is! Map) continue;
        try {
          taskRecords.add(MapEntry(
            entry.key.toString(),
            Task(
              id: t['id'] ?? entry.key,
              title: t['title'] ?? '',
              isDone: t['isDone'] == true,
              createdAt: t['createdAt'] != null
                  ? _parseLocal(t['createdAt'])
                  : DateTime.now(),
              estimatedPomodoros:
                  (t['estimatedPomodoros'] as num?)?.toInt() ?? 1,
              completedPomodoros:
                  (t['completedPomodoros'] as num?)?.toInt() ?? 0,
              projectId: t['projectId'],
              priority: (t['priority'] as num?)?.toInt() ?? 0,
              description: t['description'],
            ),
          ));
        } catch (_) {}
      }
    }

    final dayGoalRecords = <MapEntry<String, DayGoal>>[];
    final goals = decoded['dayGoals'];
    if (goals is Map) {
      for (final entry in goals.entries) {
        if (entry.value is! Map) continue;
        try {
          dayGoalRecords.add(MapEntry(
            entry.key.toString(),
            DayGoal.fromMap(Map<String, dynamic>.from(entry.value as Map)),
          ));
        } catch (_) {}
      }
    }

    // Everything parsed: now write.
    for (final e in projectRecords) {
      await _projects.put(e.key, e.value);
    }
    for (final e in sessionRecords) {
      await _sessions.put(e.key, e.value);
    }
    for (final e in taskRecords) {
      await _tasks.put(e.key, e.value);
    }
    for (final e in dayGoalRecords) {
      await _dayGoals.put(e.key, e.value);
    }

    final settings = decoded['settings'];
    if (settings is Map) {
      for (final entry in settings.entries) {
        await _settings.put(entry.key.toString(), entry.value);
      }
    }

    // Refresh every notifier that mirrors settings, reading through the
    // guarded getters rather than the raw map, so the UI updates in place.
    darkModeNotifier.value = darkMode;
    zoomNotifier.value = appZoom;
    final langCode = getSetting('language', defaultValue: 'ar');
    localeNotifier.value = Locale(langCode is String ? langCode : 'ar');
    quoteFavoritesNotifier.value = favoriteQuotes;
    goalsRevision.value++;

    return projectRecords.length +
        sessionRecords.length +
        taskRecords.length +
        dayGoalRecords.length;
  }

  /// Parses an ISO timestamp into local time. `DateTime.parse` keeps a UTC
  /// offset, which would file restored sessions under the wrong calendar day
  /// when compared against local y/m/d everywhere else.
  static DateTime _parseLocal(dynamic value) {
    final parsed = DateTime.parse(value.toString());
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  // ─── Custom Quotes CRUD ───
  static final ValueNotifier<int> customQuotesRevision = ValueNotifier(0);

  static List<Map<String, String>> getCustomQuotes() {
    final list = <Map<String, String>>[];
    for (final key in _customQuotes.keys) {
      final raw = _customQuotes.get(key);
      if (raw is Map) {
        final q = <String, String>{};
        raw.forEach((k, v) => q[k.toString()] = v.toString());
        if (q.containsKey('ar') && q['ar']!.isNotEmpty) {
          list.add(q);
        }
      }
    }
    return list;
  }

  /// Returns a set of built-in quote IDs that the user has hidden/deleted.
  static Set<String> getHiddenQuoteIds() {
    final raw = getSetting('hiddenQuoteIds', defaultValue: <String>[]);
    if (raw is List) return raw.map((e) => e.toString()).toSet();
    return {};
  }

  static Future<void> hideQuote(String id) async {
    final hidden = getHiddenQuoteIds();
    hidden.add(id);
    await setSetting('hiddenQuoteIds', hidden.toList());
    customQuotesRevision.value++;
  }

  static Future<void> unhideQuote(String id) async {
    final hidden = getHiddenQuoteIds();
    hidden.remove(id);
    await setSetting('hiddenQuoteIds', hidden.toList());
    customQuotesRevision.value++;
  }

  static Future<void> addCustomQuote({
    required String ar,
    required String en,
    required String cat,
    String author = '',
  }) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    await _customQuotes.put(id, {
      'id': id,
      'ar': ar,
      'en': en,
      'cat': cat,
      'author': author,
    });
    customQuotesRevision.value++;
  }

  /// Save/override a quote (works for both built-in and custom).
  static Future<void> saveQuote({
    required String id,
    required String ar,
    required String en,
    required String cat,
    String author = '',
  }) async {
    await _customQuotes.put(id, {
      'id': id,
      'ar': ar,
      'en': en,
      'cat': cat,
      'author': author,
    });
    customQuotesRevision.value++;
  }

  static Future<void> updateCustomQuote({
    required String id,
    required String ar,
    required String en,
    required String cat,
    String author = '',
  }) async {
    await _customQuotes.put(id, {
      'id': id,
      'ar': ar,
      'en': en,
      'cat': cat,
      'author': author,
    });
    customQuotesRevision.value++;
  }

  static Future<void> deleteCustomQuote(String id) async {
    await _customQuotes.delete(id);
    customQuotesRevision.value++;
  }

  /// Merged quote list: custom overrides built-in by ID, hidden ones removed.
  static List<Map<String, String>> getMergedQuotes({
    String? category,
  }) {
    final custom = getCustomQuotes();
    final customMap = {for (final q in custom) q['id']!: q};
    final hidden = getHiddenQuoteIds();

    final result = <Map<String, String>>[];
    for (final q in ProductivityQuotes.all) {
      if (hidden.contains(q['id'])) continue;
      if (customMap.containsKey(q['id'])) {
        result.add(customMap[q['id']]!);
      } else {
        result.add(q);
      }
    }
    // Add any truly new custom quotes (not overrides).
    for (final q in custom) {
      if (!ProductivityQuotes.all.any((b) => b['id'] == q['id'])) {
        result.add(q);
      }
    }
    if (category != null && category != 'all') {
      return result.where((q) => q['cat'] == category).toList();
    }
    return result;
  }
}
