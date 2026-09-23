import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/day_goal.dart';
import '../models/project.dart';
import '../models/stage_item.dart';
import 'database_service.dart';

class GoalsService extends ChangeNotifier {
  Timer? _dayRolloverTimer;

  GoalsService() {
    _ensureTodayGoal();
    _scheduleDayRollover();
    DatabaseService.goalsRevision.addListener(notifyListeners);
  }

  int get dailyGoalMinutes => DatabaseService.dailyTargetMinutes;

  int get weeklyGoalMinutes => DatabaseService.weeklyGoalMinutes;

  bool get hasDailyGoal => dailyGoalMinutes > 0;
  bool get hasWeeklyGoal => weeklyGoalMinutes > 0;

  String get todayKey => DatabaseService.dateKeyOf(DateTime.now());

  DayGoal get todayGoal => DatabaseService.getOrCreateDayGoal(todayKey);

  int get todayTarget => todayGoal.goalMinutes + todayGoal.carryOverMinutes;

  int get completedToday =>
      DatabaseService.getCompletedMinutesForDay(DateTime.now());

  int get todayRemaining => (todayTarget - completedToday).clamp(0, 1 << 30);

  double get todayProgress => todayTarget > 0
      ? completedToday / todayTarget
      : 0.0;

  int get completedWeek =>
      DatabaseService.getCompletedMinutesForWeek(onlyInWeeklyGoal: true);

  int get weekRemaining => (weeklyGoalMinutes - completedWeek).clamp(0, 1 << 30);

  double get weekProgress => weeklyGoalMinutes > 0
      ? completedWeek / weeklyGoalMinutes
      : 0.0;

  int get daysLeftInWeek {
    final now = DateTime.now();
    return (7 - now.weekday).clamp(1, 7);
  }

  int get suggestedDailyFromWeekly {
    if (!hasWeeklyGoal) return 0;
    final remaining = weeklyGoalMinutes - completedWeek;
    if (remaining <= 0) return 0;
    final perDay = (remaining / daysLeftInWeek).ceil();
    return perDay.clamp(0, 24 * 60);
  }

  int get carryOverFromYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final key = DatabaseService.dateKeyOf(yesterday);
    final g = DatabaseService.getDayGoal(key);
    if (g == null) return 0;
    final completed =
        DatabaseService.getCompletedMinutesForDay(yesterday);
    final diff = g.goalMinutes + g.carryOverMinutes - completed;
    return diff > 0 ? diff : 0;
  }

  List<StageItem> get todayStages => todayGoal.stages;

  int get todayStagesDone =>
      todayGoal.stages.where((s) => s.completed).length;

  bool get allStagesDone =>
      todayGoal.stages.isNotEmpty && todayStagesDone == todayGoal.stages.length;

  bool get dayComplete => todayTarget > 0 && completedToday >= todayTarget;

  Future<void> generateSmartPlan() async {
    final g = todayGoal;
    final target = g.goalMinutes > 0 ? g.goalMinutes : suggestedDailyFromWeekly;
    if (target <= 0) return;
    g.stages.clear();
    final chunk = 25;
    var remaining = target;
    var i = 1;
    while (remaining > 0 && g.stages.length < 6) {
      final dur = remaining >= chunk ? chunk : remaining;
      g.stages.add(StageItem(
        id: const Uuid().v4(),
        title: 'مهمة $i',
        icon: '📌',
        durationMinutes: dur,
        order: g.stages.length,
      ));
      remaining -= dur;
      i++;
    }
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  Future<void> setDailyGoal(int minutes) async {
    final g = todayGoal;
    g.goalMinutes = minutes;
    await DatabaseService.saveDayGoal(g);
    await DatabaseService.setDailyGoalMinutes(minutes);
    notifyListeners();
  }

  Future<void> setWeeklyGoal(int minutes) async {
    await DatabaseService.setWeeklyGoalMinutes(minutes);
    notifyListeners();
  }

  Future<void> applyCarryOver() async {
    final g = todayGoal;
    g.carryOverMinutes = carryOverFromYesterday;
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  Future<void> ignoreCarryOver() async {
    final g = todayGoal;
    g.carryOverMinutes = 0;
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  Future<void> addStage(String title,
      {int minutes = 25,
      String icon = '📌',
      String? projectId}) async {
    final g = todayGoal;
    g.stages.add(StageItem(
      id: const Uuid().v4(),
      title: title,
      icon: icon,
      durationMinutes: minutes,
      projectId: projectId,
      order: g.stages.length,
    ));
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  Future<void> updateStage(String stageId,
      {String? title,
      int? minutes,
      String? icon,
      String? projectId}) async {
    final g = todayGoal;
    final idx = g.stages.indexWhere((s) => s.id == stageId);
    if (idx < 0) return;
    final s = g.stages[idx];
    if (title != null) s.title = title;
    if (minutes != null) s.durationMinutes = minutes;
    if (icon != null) s.icon = icon;
    if (projectId != null) s.projectId = projectId;
    g.stages[idx] = s;
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  Future<void> deleteStage(String stageId) async {
    final g = todayGoal;
    g.stages.removeWhere((s) => s.id == stageId);
    for (int i = 0; i < g.stages.length; i++) {
      g.stages[i].order = i;
    }
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  Future<void> reorderStages(int oldIndex, int newIndex) async {
    final g = todayGoal;
    if (newIndex > oldIndex) newIndex--;
    final item = g.stages.removeAt(oldIndex);
    g.stages.insert(newIndex, item);
    for (int i = 0; i < g.stages.length; i++) {
      g.stages[i].order = i;
    }
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  Future<void> toggleStage(String stageId, {int? minutesDone}) async {
    final g = todayGoal;
    final idx = g.stages.indexWhere((s) => s.id == stageId);
    if (idx < 0) return;
    final s = g.stages[idx];
    s.completed = !s.completed;
    g.stages[idx] = s;
    if (s.completed && minutesDone != null) {
      g.manuallyCompletedMinutes += minutesDone;
    } else if (!s.completed && minutesDone != null) {
      g.manuallyCompletedMinutes =
          (g.manuallyCompletedMinutes - minutesDone).clamp(0, 1 << 30);
    }
    await DatabaseService.saveDayGoal(g);
    notifyListeners();
  }

  List<Project> get projectsInWeeklyGoal {
    return DatabaseService.getAllProjects()
        .where((p) => p.includeInWeeklyGoal && p.weeklyGoalMinutes > 0)
        .toList();
  }

  int weeklyProjectCompleted(String projectId) {
    final sessions = DatabaseService.getSessionsForWeek()
        .where((s) => s.completed && s.sessionType != 'tasbeeh' && s.projectId == projectId);
    return sessions.fold(
        0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  void _ensureTodayGoal() {
    final g = todayGoal;
    if (g.goalMinutes == 0 && dailyGoalMinutes > 0) {
      g.goalMinutes = dailyGoalMinutes;
      if (carryOverFromYesterday > 0 && g.carryOverMinutes == 0) {
        g.carryOverMinutes = carryOverFromYesterday;
      }
      DatabaseService.saveDayGoal(g);
    }
  }

  void _scheduleDayRollover() {
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day)
        .add(const Duration(days: 1));
    _dayRolloverTimer = Timer(
      nextDay.difference(now) + const Duration(seconds: 5),
      () {
        _ensureTodayGoal();
        notifyListeners();
        _scheduleDayRollover();
      },
    );
  }

  void recordSessionCompleted(String projectId) {
    _ensureTodayGoal();
    notifyListeners();
  }

  @override
  void dispose() {
    _dayRolloverTimer?.cancel();
    DatabaseService.goalsRevision.removeListener(notifyListeners);
    super.dispose();
  }
}
