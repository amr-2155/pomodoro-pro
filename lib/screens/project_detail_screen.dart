import 'package:flutter/material.dart';
import '../utils/number_formatter.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/project.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../services/timer_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  late Project _project;
  List<Session> _recentSessions = [];
  List<double> _weeklyMinutes = [];
  int _weekMinutes = 0;
  int _weekSessions = 0;
  int _streak = 0;
  int _todayMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _project = DatabaseService.getProject(widget.project.id) ?? widget.project;
      _recentSessions = DatabaseService.getRecentSessionsForProject(_project.id);
      _weeklyMinutes = DatabaseService.getProjectDailyMinutesThisWeek(_project.id);
      _weekMinutes = DatabaseService.getProjectWeekMinutes(_project.id);
      _weekSessions = DatabaseService.getProjectWeekSessions(_project.id);
      _streak = DatabaseService.getProjectStreak(_project.id);
      _todayMinutes = DatabaseService.getProjectTodayMinutes(_project.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(_project.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);
    final dayNames = [l10n.sat, l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri];
    final maxMin = _weeklyMinutes.isNotEmpty
        ? _weeklyMinutes.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: color,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.7)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(_project.icon,
                                    style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _project.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_project.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        _project.description,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.75),
                                          fontSize: 13,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuickStats(color, isDark),
                  const SizedBox(height: 20),
                  _buildWeeklyChart(dayNames, maxMin, color, isDark),
                  const SizedBox(height: 20),
                  _buildProjectBreakdown(color, isDark),
                  const SizedBox(height: 20),
                  _buildSessionHistory(isDark, color),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              final timer = context.read<TimerService>();
              timer.setProject(_project.id);
              timer.start();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              '${AppLocalizations.of(context).quickStart} — ${AppLocalizations.of(context).focus}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(Color color, bool isDark) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _buildMiniStat(l10n.today, '${fmtMin(_todayMinutes)}', Icons.today_rounded,
            color, isDark),
        const SizedBox(width: 10),
        _buildMiniStat(l10n.weeklyChart, '${fmtMin(_weekMinutes)}', Icons.date_range_rounded,
            color, isDark),
        const SizedBox(width: 10),
        _buildMiniStat(
            l10n.sessionsCount, '$_weekSessions', Icons.local_fire_department_rounded,
            color, isDark),
        const SizedBox(width: 10),
        _buildMiniStat(
            l10n.dayStreak, '$_streak', Icons.bolt_rounded, color, isDark),
      ],
    );
  }

  Widget _buildMiniStat(
      String label, String value, IconData icon, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(
      List<String> dayNames, double maxMin, Color color, bool isDark) {
    // RTL: reverse so Saturday is on the right.
    final rName = List<String>.from(dayNames.reversed);
    final rMin = List<double>.from(_weeklyMinutes.reversed);
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
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bar_chart_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).weeklyOverview,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxMin > 0 ? maxMin + 10 : 60,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${fmtMin(rod.toY.toInt())}',
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
                        if (index >= 0 && index < 7) {
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
                                color: isToday ? color : Colors.grey[500],
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
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxMin > 0 ? (maxMin / 4).ceilToDouble() : 15,
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
                barGroups: List.generate(7, (index) {
                  final isToday = index == rToday;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: rMin[index],
                        color: isToday
                            ? color
                            : color.withValues(alpha: 0.2),
                        width: 16,
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

  Widget _buildProjectBreakdown(Color color, bool isDark) {
    final progress = _project.weeklyGoalMinutes > 0
        ? (_weekMinutes / _project.weeklyGoalMinutes).clamp(0.0, 1.0)
        : 0.0;

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
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppColors.success, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                _project.weeklyGoalMinutes > 0
                    ? '${AppLocalizations.of(context).weeklyGoalMin}: '
                    : '${AppLocalizations.of(context).weeklyGoalMin}: ${AppLocalizations.of(context).off}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_project.weeklyGoalMinutes > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: progress >= 1
                        ? AppColors.success.withValues(alpha: 0.12)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      color: progress >= 1 ? AppColors.success : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (_project.weeklyGoalMinutes > 0) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? AppColors.success : color,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${fmtMin(_weekMinutes)}  ',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSessionHistory(bool isDark, Color color) {
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
                child: const Icon(Icons.history_rounded,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context).viewAllSessions,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentSessions.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  AppLocalizations.of(context).noSessionsYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            )
          else
            ...List.generate(_recentSessions.length, (index) {
              final session = _recentSessions[index];
              final isLast = index == _recentSessions.length - 1;
              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : Colors.grey.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: session.completed
                            ? AppColors.success
                            : AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.completed ? AppLocalizations.of(context).completed : AppLocalizations.of(context).skip,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          Text(
                            formatDate(session.date),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${fmtMin(session.actualMinutes ?? session.durationMinutes)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
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
}
