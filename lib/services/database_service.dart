import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/project.dart';
import '../models/session.dart';
import '../models/task.dart';
import '../utils/constants.dart';

class DatabaseService {
  static const String _projectsBox = 'projects';
  static const String _sessionsBox = 'sessions';
  static const String _tasksBox = 'tasks';
  static const String _settingsBox = 'settings';

  static late Box<Project> _projects;
  static late Box<Session> _sessions;
  static late Box<Task> _tasks;
  static late Box _settings;

  static final ValueNotifier<bool> darkModeNotifier = ValueNotifier(false);
  static final ValueNotifier<double> zoomNotifier = ValueNotifier(1.0);

  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(ProjectAdapter());
    Hive.registerAdapter(SessionAdapter());
    Hive.registerAdapter(TaskAdapter());

    _projects = await Hive.openBox<Project>(_projectsBox);
    _sessions = await Hive.openBox<Session>(_sessionsBox);
    _tasks = await Hive.openBox<Task>(_tasksBox);
    _settings = await Hive.openBox(_settingsBox);

    darkModeNotifier.value = darkMode;
    zoomNotifier.value = appZoom;
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
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
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

  static Future<void> addSession(Session session) async {
    await _sessions.put(session.id, session);

    final project = _projects.get(session.projectId);
    if (project != null && session.completed) {
      project.totalSessions++;
      project.totalMinutes += session.durationMinutes;
      await project.save();
    }
  }

  static Future<void> deleteSession(String id) async {
    final session = _sessions.get(id);
    if (session != null) {
      final project = _projects.get(session.projectId);
      if (project != null && session.completed) {
        project.totalSessions--;
        project.totalMinutes -= session.durationMinutes;
        await project.save();
      }
      await _sessions.delete(id);
    }
  }

  // Statistics
  static int getTodayMinutes() {
    final sessions = getSessionsForDate(DateTime.now());
    return sessions
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  static int getWeekMinutes() {
    final sessions = getSessionsForWeek();
    return sessions
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  static int getMonthMinutes() {
    final sessions = getSessionsForMonth();
    return sessions
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  static int getTodaySessions() {
    return getSessionsForDate(DateTime.now())
        .where((s) => s.completed)
        .length;
  }

  static int getWeekSessions() {
    return getSessionsForWeek()
        .where((s) => s.completed)
        .length;
  }

  static Map<String, int> getProjectMinutesThisWeek() {
    final sessions = getSessionsForWeek().where((s) => s.completed);
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.projectId] = (map[s.projectId] ?? 0) + s.durationMinutes;
    }
    return map;
  }

  static List<double> getDailyMinutesThisWeek() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dailyMinutes = List<double>.filled(7, 0);

    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final daySessions = getSessionsForDate(day).where((s) => s.completed);
      dailyMinutes[i] =
          daySessions.fold(0, (sum, s) => sum + s.durationMinutes).toDouble();
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
    final sessions = _sessions.values.where((s) => s.completed).toList();
    if (sessions.isEmpty) return 0;
    final total = sessions.fold(0, (sum, s) => sum + s.durationMinutes);
    return total / sessions.length;
  }

  static int getProjectTodayMinutes(String projectId) {
    return getSessionsForDate(DateTime.now())
        .where((s) => s.completed && s.projectId == projectId)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  static int getProjectWeekMinutes(String projectId) {
    return getSessionsForWeek()
        .where((s) => s.completed && s.projectId == projectId)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  static int getProjectWeekSessions(String projectId) {
    return getSessionsForWeek()
        .where((s) => s.completed && s.projectId == projectId)
        .length;
  }

  static int getProjectStreak(String projectId) {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final daySessions = getSessionsForDate(day)
          .where((s) => s.completed && s.projectId == projectId);
      if (daySessions.isNotEmpty) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  static List<double> getProjectDailyMinutesThisWeek(String projectId) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final dailyMinutes = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final daySessions = getSessionsForDate(day)
          .where((s) => s.completed && s.projectId == projectId);
      dailyMinutes[i] =
          daySessions.fold(0, (sum, s) => sum + s.durationMinutes).toDouble();
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
    final sessions = getSessionsForWeek().where((s) => s.completed);
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.projectId] = (map[s.projectId] ?? 0) + s.durationMinutes;
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
    list.sort((a, b) => b['minutes'] as int);
    return list;
  }

  static int getOverallStreak() {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final daySessions =
          getSessionsForDate(day).where((s) => s.completed);
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
        .where((s) => s.completed)
        .fold(0, (sum, s) => sum + s.durationMinutes);
  }

  static int getTotalAllTimeSessions() {
    return _sessions.values.where((s) => s.completed).length;
  }

  static List<Session> getRecentSessions({int limit = 50}) {
    final sessions = _sessions.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sessions.take(limit).toList();
  }

  static List<List<int>> getHeatMapData({int weeks = 16}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = today.subtract(Duration(days: today.weekday - 1 + (weeks - 1) * 7));
    final data = <List<int>>[];
    for (int w = 0; w < weeks; w++) {
      final week = <int>[];
      for (int d = 0; d < 7; d++) {
        final day = startDay.add(Duration(days: w * 7 + d));
        if (day.isAfter(today)) {
          week.add(-1);
        } else {
          final mins = getSessionsForDate(day)
              .where((s) => s.completed)
              .fold(0, (sum, s) => sum + s.durationMinutes);
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

  static int get focusDuration => getSetting('focusDuration', defaultValue: 25);
  static int get shortBreakDuration =>
      getSetting('shortBreakDuration', defaultValue: 5);
  static int get longBreakDuration =>
      getSetting('longBreakDuration', defaultValue: 15);
  static bool get darkMode => getSetting('darkMode', defaultValue: false);
  static bool get autoStartBreaks =>
      getSetting('autoStartBreaks', defaultValue: true);
  static bool get autoStartPomodoros =>
      getSetting('autoStartPomodoros', defaultValue: false);
  static bool get soundEnabled =>
      getSetting('soundEnabled', defaultValue: true);
  static int get dailyGoal => getSetting('dailyGoal', defaultValue: AppConstants.dailyGoalDefault);
  static double get appZoom => getSetting('appZoom', defaultValue: 1.0);
  static int get longBreakInterval => getSetting('longBreakInterval', defaultValue: 4);
  static bool get tickSoundEnabled => getSetting('tickSoundEnabled', defaultValue: true);
  static double get ambientVolume => getSetting('ambientVolume', defaultValue: 0.4);
  static int get startOfWeek => getSetting('startOfWeek', defaultValue: 1); // 1=Monday, 7=Sunday

  static Future<void> deleteAllData() async {
    await _sessions.clear();
    await _projects.clear();
    await _tasks.clear();
    await _settings.clear();
    darkModeNotifier.value = false;
    zoomNotifier.value = 1.0;
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
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  static Future<int> restoreBackup(String jsonString) async {
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    int count = 0;

    final projects = data['projects'] as Map<String, dynamic>? ?? {};
    for (final entry in projects.entries) {
      await _projects.put(entry.key, Project.fromMap(entry.value));
      count++;
    }

    final sessions = data['sessions'] as Map<String, dynamic>? ?? {};
    for (final entry in sessions.entries) {
      final s = entry.value;
      await _sessions.put(entry.key, Session(
        id: s['id'] ?? entry.key,
        projectId: s['projectId'] ?? '',
        date: s['date'] != null ? DateTime.parse(s['date']) : DateTime.now(),
        durationMinutes: s['durationMinutes'] ?? 0,
        completed: s['completed'] ?? true,
        sessionType: s['sessionType'] ?? 'focus',
        rating: s['rating'],
        notes: s['notes'],
        taskId: s['taskId'],
      ));
      count++;
    }

    final tasks = data['tasks'] as Map<String, dynamic>? ?? {};
    for (final entry in tasks.entries) {
      final t = entry.value;
      await _tasks.put(entry.key, Task(
        id: t['id'] ?? entry.key,
        title: t['title'] ?? '',
        isDone: t['isDone'] ?? false,
        createdAt: t['createdAt'] != null ? DateTime.parse(t['createdAt']) : DateTime.now(),
        estimatedPomodoros: t['estimatedPomodoros'] ?? 1,
        completedPomodoros: t['completedPomodoros'] ?? 0,
        projectId: t['projectId'],
        priority: t['priority'] ?? 0,
        description: t['description'],
      ));
      count++;
    }

    final settings = data['settings'] as Map<String, dynamic>? ?? {};
    for (final entry in settings.entries) {
      await _settings.put(entry.key, entry.value);
      count++;
    }

    darkModeNotifier.value = darkMode;
    zoomNotifier.value = appZoom;

    return count;
  }
}
