import 'package:flutter/material.dart';
import 'package:pomodoro_app/l10n/app_localizations.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/page_transitions.dart';
import 'session_history_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _chartView = 'week';
  String? _filterProjectId;

  AppLocalizations get l10n => AppLocalizations.of(context);

  List<Session> _filteredSessions({String? projectId, DateTime? since}) {
    var sessions = DatabaseService.getAllSessions().where((s) => s.completed);
    if (projectId != null) sessions = sessions.where((s) => s.projectId == projectId);
    if (since != null) sessions = sessions.where((s) => !s.date.isBefore(since));
    return sessions.toList();
  }

  int _filteredTodayMinutes() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _filteredSessions(projectId: _filterProjectId, since: startOfDay)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  int _filteredWeekMinutes() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday + 1) % 7));
    return _filteredSessions(projectId: _filterProjectId, since: startOfWeek)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  int _filteredMonthMinutes() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _filteredSessions(projectId: _filterProjectId, since: startOfMonth)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  int _filteredTodaySessions() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    return _filteredSessions(projectId: _filterProjectId, since: startOfDay).length;
  }

  int _filteredWeekSessions() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday + 1) % 7));
    return _filteredSessions(projectId: _filterProjectId, since: startOfWeek).length;
  }

  int _getLastMonthMinutes() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    return DatabaseService.getAllSessions()
        .where((s) => s.completed && s.date.year == lastMonth.year && s.date.month == lastMonth.month)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  int _getLastWeekMinutes() {
    final now = DateTime.now();
    final thisWeekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday + 1) % 7));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    return DatabaseService.getAllSessions()
        .where((s) => s.completed && !s.date.isBefore(lastWeekStart) && s.date.isBefore(thisWeekStart))
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dailyMinutes = _filterProjectId != null ? _getFilteredDailyMinutesThisWeek() : DatabaseService.getDailyMinutesThisWeek();
    final todayMinutes = _filteredTodayMinutes();
    final weekMinutes = _filteredWeekMinutes();
    final monthMinutes = _filteredMonthMinutes();
    final todaySessions = _filteredTodaySessions();
    final weekSessions = _filteredWeekSessions();
    final avgDuration = DatabaseService.getAverageSessionDuration();
    final bestProject = DatabaseService.getBestProjectThisWeek();
    final dailyGoalMin = DatabaseService.dailyTargetMinutes;
    final streak = _filterProjectId != null ? _getFilteredStreak() : DatabaseService.getOverallStreak();
    final totalMinutes = _filterProjectId != null ? _getFilteredTotalMinutes() : DatabaseService.getTotalAllTimeMinutes();
    final totalSessions = _filterProjectId != null ? _getFilteredTotalSessions() : DatabaseService.getTotalAllTimeSessions();
    final projectBreakdown = _filterProjectId != null ? _getFilteredProjectBreakdown() : DatabaseService.getProjectBreakdown();

    final dayNames = [l10n.sat, l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri];
    final goalProgress =
        dailyGoalMin > 0 ? (todayMinutes / dailyGoalMin) : 0.0;

    final displayMinutes = _chartView == 'week' ? dailyMinutes : _getMonthlyChart();
    final displayMax = displayMinutes.reduce((a, b) => a > b ? a : b);
    final displayLabels = _chartView == 'week' ? dayNames : ['W4', 'W3', 'W2', 'W1'];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statistics,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  AppPageRoute(page: const SessionHistoryScreen()),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    l10n.viewAllSessions,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildOverallStats(isDark, streak, totalMinutes, totalSessions),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    l10n.today,
                    '${todayMinutes}${l10n.minShort}',
                    '$todaySessions ${l10n.sessionsCount}',
                    Icons.access_time_rounded,
                    AppColors.focusColor,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    l10n.thisWeek,
                    '${weekMinutes}${l10n.minShort}',
                    '$weekSessions ${l10n.sessionsCount}',
                    Icons.calendar_view_week_rounded,
                    AppColors.success,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    l10n.thisMonth,
                    '${monthMinutes}${l10n.minShort}',
                    '',
                    Icons.calendar_month_rounded,
                    AppColors.warning,
                    isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    l10n.avgSession,
                    '${avgDuration.toStringAsFixed(0)}${l10n.minShort}',
                    '',
                    Icons.timer_rounded,
                    AppColors.accent,
                    isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGoalStats(isDark),
            const SizedBox(height: 16),
            _buildMonthComparison(isDark),
            const SizedBox(height: 20),
            _buildProjectFilter(isDark),
            const SizedBox(height: 16),
            _buildDailyGoalCard(todayMinutes, dailyGoalMin, goalProgress, isDark),
            const SizedBox(height: 16),
            _buildTodayTimeline(isDark),
            _buildChartPeriodToggle(isDark),
            const SizedBox(height: 8),
            _buildWeeklyChart(displayMinutes, displayLabels, displayMax, isDark),
            const SizedBox(height: 16),
            _buildHeatMap(isDark),
            if (projectBreakdown.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildProjectPieChart(projectBreakdown, isDark),
            ],
            if (bestProject != null) ...[
              const SizedBox(height: 16),
              _buildBestProjectCard(bestProject, isDark),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(
      bool isDark, int streak, int totalMinutes, int totalSessions) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildOverallStat(
              Icons.local_fire_department_rounded, '$streak', l10n.dayStreak, Colors.white),
          Container(
              height: 40,
              width: 1,
              color: Colors.white.withValues(alpha: 0.2)),
          _buildOverallStat(
              Icons.timer_rounded, '${(totalMinutes / 60).toStringAsFixed(0)}h', l10n.totalTime, Colors.white),
          Container(
              height: 40,
              width: 1,
              color: Colors.white.withValues(alpha: 0.2)),
          _buildOverallStat(
              Icons.flag_rounded, '$totalSessions', l10n.sessionsCount, Colors.white),
        ],
      ),
    );
  }

  Widget _buildOverallStat(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTimeline(bool isDark) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final sessions = DatabaseService.getAllSessions()
        .where((s) => !s.date.isBefore(startOfDay))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sessions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                l10n.timeline,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sessions.length} ${l10n.sessionsCount}',
                   style: const TextStyle(
                     fontSize: 11,
                     fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(sessions.length, (i) {
            final s = sessions[i];
            final project = s.projectId.isNotEmpty
                ? DatabaseService.getProject(s.projectId)
                : null;
            final color = project != null
                ? Color(project.colorValue)
                : AppColors.primary;
            final nextSession = i < sessions.length - 1 ? sessions[i + 1] : null;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        Text(
                          formatTime(s.date),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (nextSession != null)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: color.withValues(alpha: 0.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (project != null) ...[
                            Text(project.icon, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  project?.name ?? l10n.focusSession,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                if (s.notes != null && s.notes!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    s.notes!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                s.sessionType == 'tasbeeh'
                                    ? '${l10n.tasbeehType} • ${s.count ?? 0} ${l10n.timesWord}'
                                    : '${(s.actualMinutes ?? s.durationMinutes)}${l10n.minShort}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                              if (s.rating != null && s.rating! > 0) ...[
                                const SizedBox(height: 2),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: List.generate(5, (idx) {
                                    return Icon(
                                      idx < s.rating!
                                          ? Icons.star_rounded
                                          : Icons.star_border_rounded,
                                      size: 12,
                                      color: idx < s.rating!
                                          ? AppColors.star
                                          : Colors.grey,
                                    );
                                  }),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(
      int todayMinutes, int dailyGoalMin, double goalProgress, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                '${l10n.dailyGoalStat}: ${dailyGoalMin}${l10n.minShort}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: goalProgress >= 1
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(goalProgress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: goalProgress >= 1
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goalProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.grey.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                goalProgress >= 1 ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$todayMinutes ${l10n.dailyGoalProgress} $dailyGoalMin min',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<double> dailyMinutes, List<String> dayNames,
      double maxMinutes, bool isDark) {
    // RTL: reverse so Saturday is on the right side.
    final rMin = List<double>.from(dailyMinutes.reversed);
    final rName = List<String>.from(dayNames.reversed);
    final rToday = 6 - ((DateTime.now().weekday + 1) % 7);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.warning, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.weeklyOverview,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxMinutes > 0 ? maxMinutes + 10 : 100,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}${l10n.minShort}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < rName.length) {
                          final isToday = index == rToday;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              rName[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? AppColors.primary
                                    : Colors.grey[500],
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxMinutes > 0
                      ? (maxMinutes / 4).ceilToDouble()
                      : 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.withValues(alpha: 0.1),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(rMin.length, (index) {
                  final isToday = index == rToday;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: rMin[index],
                        color: isToday
                            ? AppColors.primary
                            : AppColors.primary.withValues(alpha: 0.2),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectPieChart(
      List<Map<String, dynamic>> breakdown, bool isDark) {
    final totalMinutes = breakdown.fold<int>(0, (sum, p) => sum + (p['minutes'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.pie_chart_rounded,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.projectBreakdown,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 36,
                      sections: breakdown.take(6).map((p) {
                        final minutes = p['minutes'] as int;
                        final percent =
                            totalMinutes > 0 ? minutes / totalMinutes : 0.0;
                        return PieChartSectionData(
                          value: minutes.toDouble(),
                          color: p['color'] as Color,
                          radius: 40,
                          title: '${(percent * 100).toInt()}%',
                          titleStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: breakdown.take(4).map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: p['color'] as Color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${p['icon']} ${p['name']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[300]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestProjectCard(String bestProject, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.bestProjectThisWeek,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bestProject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStats(bool isDark) {
    final goalMinutes = DatabaseService.dailyTargetMinutes;
    final dailyData =
        DatabaseService.getDailyCompletedMinutesThisWeek(onlyInWeeklyGoal: true);
    final daysAchieved = goalMinutes > 0
        ? dailyData.where((m) => m >= goalMinutes).length
        : 0;
    final bestDay = dailyData.isEmpty ? 0 : dailyData.reduce((a, b) => a > b ? a : b);
    final weekTotal = dailyData.fold(0, (sum, m) => sum + m);
    final daysSoFar = DateTime.now().weekday;
    final dailyAvg = daysSoFar > 0 ? (weekTotal / daysSoFar).round() : 0;
    final maxY = dailyData.isEmpty
        ? 60.0
        : (dailyData.reduce((a, b) => a > b ? a : b) * 1.2).clamp(60.0, 600.0);
    final dayNames = [l10n.sat, l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri];
    // RTL: reverse so Saturday is on the right.
    final rData = List<int>.from(dailyData.reversed);
    final rName = List<String>.from(dayNames.reversed);
    final rToday = 6 - ((DateTime.now().weekday + 1) % 7);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.flag_rounded,
                    color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.goalStats,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _goalStatMini(
                    Icons.event_available_rounded, '$daysAchieved', l10n.daysAchieved, AppColors.primary, isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _goalStatMini(
                    Icons.emoji_events_rounded, '${bestDay}${l10n.minShort}', l10n.bestDay, AppColors.warning, isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _goalStatMini(
                    Icons.calendar_view_week_rounded, '${(weekTotal / 60).toStringAsFixed(1)}${l10n.hourShort}',
                    l10n.weekTotal, AppColors.success, isDark),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              Expanded(
                child: _goalStatMini(
                    Icons.insights_rounded, '${dailyAvg}${l10n.minDay}', l10n.dailyAverage, AppColors.accent, isDark),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _goalStatMini(
                    Icons.flag_rounded, goalMinutes > 0 ? '${goalMinutes}min' : '—',
                    l10n.dailyGoalStat, AppColors.focusColor, isDark),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}${l10n.minShort}',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= 7) {
                          return const SizedBox.shrink();
                        }
                        final isToday = index == rToday;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            rName[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight:
                                  isToday ? FontWeight.bold : FontWeight.normal,
                              color: isToday
                                  ? AppColors.primary
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  rData.length,
                  (i) => BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: rData[i].toDouble(),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                        color: goalMinutes > 0 && rData[i] >= goalMinutes
                            ? AppColors.success
                            : (i == rToday
                                ? AppColors.primary
                                : AppColors.primary.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalStatMini(IconData icon, String value, String label, Color color,
      bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthComparison(bool isDark) {
    final thisWeek = DatabaseService.getWeekMinutes();
    final lastWeek = _getLastWeekMinutes();
    final thisMonth = DatabaseService.getMonthMinutes();
    final lastMonth = _getLastMonthMinutes();

    Widget buildCompare(String label, int current, int previous, Color color) {
      final diff = previous > 0 ? ((current - previous) / previous * 100).round() : (current > 0 ? 100 : 0);
      final isUp = current >= previous;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              children: [
                Text('${current}${l10n.minShort}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                if (previous > 0 || current > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isUp ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 12, color: isUp ? AppColors.success : AppColors.error),
                        const SizedBox(width: 2),
                        Text('$diff%', style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold,
                            color: isUp ? AppColors.success : AppColors.error)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.compare_arrows_rounded, color: AppColors.warning, size: 18),
            ),
            const SizedBox(width: 12),
            Text(l10n.periodComparison, style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: buildCompare(l10n.thisWeek, thisWeek, lastWeek, AppColors.success)),
            const SizedBox(width: 12),
            Expanded(child: buildCompare(l10n.thisMonth, thisMonth, lastMonth, AppColors.warning)),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectFilter(bool isDark) {
    final projects = DatabaseService.getAllProjects();
    if (projects.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.filter_list_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(l10n.filterByProject, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip(l10n.all, _filterProjectId == null, isDark, () {
                setState(() => _filterProjectId = null);
              }),
              ...projects.map((p) {
                final color = Color(p.colorValue);
                return _buildFilterChip(
                  '${p.icon} ${p.name}',
                  _filterProjectId == p.id,
                  isDark,
                  () => setState(() => _filterProjectId = p.id),
                  color: color,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, bool isDark, VoidCallback onTap, {Color? color}) {
    final chipColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? chipColor : chipColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : chipColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? Colors.white : chipColor,
          ),
        ),
      ),
    );
  }

  List<double> _getFilteredDailyMinutesThisWeek() {
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday + 1) % 7));
    final dailyMinutes = List<double>.filled(7, 0);
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      final daySessions = _filteredSessions(projectId: _filterProjectId, since: day)
          .where((s) => s.date.year == day.year && s.date.month == day.month && s.date.day == day.day);
      dailyMinutes[i] = daySessions.fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes)).toDouble();
    }
    return dailyMinutes;
  }

  int _getFilteredStreak() {
    int streak = 0;
    final now = DateTime.now();
    for (int i = 0; i < 365; i++) {
      final day = now.subtract(Duration(days: i));
      final daySessions = _filteredSessions(projectId: _filterProjectId)
          .where((s) => s.date.year == day.year && s.date.month == day.month && s.date.day == day.day);
      if (daySessions.isNotEmpty) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  int _getFilteredTotalMinutes() {
    return _filteredSessions(projectId: _filterProjectId)
        .fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes));
  }

  int _getFilteredTotalSessions() {
    return _filteredSessions(projectId: _filterProjectId).length;
  }

  List<Map<String, dynamic>> _getFilteredProjectBreakdown() {
    final sessions = _filteredSessions(projectId: _filterProjectId);
    final now = DateTime.now();
    final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: (now.weekday + 1) % 7));
    final weekSessions = sessions.where((s) => !s.date.isBefore(startOfWeek));
    final map = <String, int>{};
    for (final s in weekSessions) {
      map[s.projectId] = (map[s.projectId] ?? 0) + (s.actualMinutes ?? s.durationMinutes);
    }
    final list = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final project = DatabaseService.getProject(entry.key);
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

  List<double> _getMonthlyChart() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final weeklyMinutes = List<double>.filled(4, 0);
    for (int d = 1; d <= daysInMonth; d++) {
      final day = DateTime(now.year, now.month, d);
      var daySessions = DatabaseService.getSessionsForDate(day).where((s) => s.completed);
      if (_filterProjectId != null) daySessions = daySessions.where((s) => s.projectId == _filterProjectId);
      final weekIndex = ((d - 1) ~/ 7).clamp(0, 3);
      weeklyMinutes[weekIndex] += daySessions.fold(0, (sum, s) => sum + (s.actualMinutes ?? s.durationMinutes)).toDouble();
    }
    // RTL: reverse so most recent week (W4) is on the right.
    return List<double>.from(weeklyMinutes.reversed);
  }

  Widget _buildHeatMap(bool isDark) {
    final rawData = DatabaseService.getHeatMapData(weeks: 16);
    // RTL: reverse weeks so most recent is on the right.
    final data = List<List<int>>.from(rawData.reversed);
    final maxMins = data.expand((w) => w).where((m) => m >= 0).fold(0, (a, b) => a > b ? a : b);
    const cellSize = 14.0;
    const gap = 3.0;

    Color getColor(int mins) {
      if (mins < 0) return Colors.transparent;
      if (mins == 0) return isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.withValues(alpha: 0.08);
      final intensity = (mins / (maxMins > 0 ? maxMins : 1)).clamp(0.1, 1.0);
      return AppColors.primary.withValues(alpha: 0.15 + intensity * 0.7);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grid_view_rounded, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(l10n.activityHeatMap, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Row(
                children: [
                  Text(l10n.less, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                  const SizedBox(width: 4),
                  ...List.generate(5, (i) {
                    final opacity = 0.04 + (i / 4) * 0.76;
                    return Container(
                      width: 12, height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: i == 0 ? 0.08 : opacity),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                  const SizedBox(width: 4),
                  Text(l10n.more, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: (cellSize + gap) * 7 + 16,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [l10n.sat, '', l10n.mon, '', l10n.wed, '', l10n.fri].map((d) {
                      return SizedBox(
                        height: cellSize,
                        child: Text(d, style: TextStyle(fontSize: 9, color: Colors.grey[500])),
                      );
                    }).toList(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.map((week) {
                        return Padding(
                          padding: const EdgeInsets.only(right: gap),
                          child: Column(
                            children: week.map((mins) {
                              return Container(
                                width: cellSize,
                                height: cellSize,
                                margin: const EdgeInsets.only(bottom: gap),
                                decoration: BoxDecoration(
                                  color: getColor(mins),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPeriodToggle(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPeriodChip(l10n.weeklyChart, 'week', isDark),
        const SizedBox(width: 8),
        _buildPeriodChip(l10n.monthlyChart, 'month', isDark),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String value, bool isDark) {
    final isActive = _chartView == value;
    return GestureDetector(
      onTap: () => setState(() => _chartView = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.white : Colors.grey[500],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(title,
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ],
        ],
      ),
    );
  }
}
