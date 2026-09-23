import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/number_formatter.dart';
import '../l10n/app_localizations.dart';
import '../models/project.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onQuickStart;
  final VoidCallback? onEdit;
  final bool isSelected;
  final bool showStats;

  const ProjectCard({
    super.key,
    required this.project,
    this.onTap,
    this.onLongPress,
    this.onDelete,
    this.onQuickStart,
    this.onEdit,
    this.isSelected = false,
    this.showStats = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(project.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final todayMin = DatabaseService.getProjectTodayMinutes(project.id);
    final weekMin = DatabaseService.getProjectWeekMinutes(project.id);
    final streak = DatabaseService.getProjectStreak(project.id);
    final progress = project.weeklyGoalMinutes > 0
        ? (weekMin / project.weeklyGoalMinutes).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.08)
              : isDark
                  ? AppColors.surfaceDark
                  : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.4)
                : isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (project.weeklyGoalMinutes > 0)
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CustomPaint(
                          painter: _ProgressRingPainter(
                            progress: progress,
                            color: color,
                          ),
                        ),
                      ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          project.icon,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${project.totalSessions} ${AppLocalizations.of(context).sessions} · ${project.totalHours.toStringAsFixed(1)}h',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (progress >= 1) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                AppLocalizations.of(context).completedBadge,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (onQuickStart != null)
                  GestureDetector(
                    onTap: onQuickStart,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.success,
                        size: 22,
                      ),
                    ),
                  ),
                if (onEdit != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
                if (onDelete != null) ...[
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.error,
                        size: 19,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.grey.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildChip(
                    Icons.today_rounded,
                    '${fmtMin(todayMin)}',
                    'Today',
                    color,
                    isDark,
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.15),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  _buildChip(
                    Icons.date_range_rounded,
                    '${fmtMin(weekMin)}',
                    'Week',
                    color,
                    isDark,
                  ),
                  Container(
                    height: 24,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.15),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  _buildChip(
                    Icons.bolt_rounded,
                    '${streak}d',
                    'Streak',
                    color,
                    isDark,
                  ),
                  if (project.weeklyGoalMinutes > 0) ...[
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.grey.withValues(alpha: 0.15),
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    _buildChip(
                      Icons.flag_rounded,
                      '${(progress * 100).toInt()}%',
                      'Goal',
                      progress >= 1 ? AppColors.success : color,
                      isDark,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(
      IconData icon, String value, String label, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ProgressRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawCircle(center, radius, bgPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progress >= 1 ? AppColors.success : color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        2 * pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress;
}
