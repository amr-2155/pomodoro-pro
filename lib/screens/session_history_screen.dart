import 'package:flutter/material.dart';
import '../models/session.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../l10n/app_localizations.dart';
import '../utils/number_formatter.dart';

class SessionHistoryScreen extends StatefulWidget {
  const SessionHistoryScreen({super.key});

  @override
  State<SessionHistoryScreen> createState() => _SessionHistoryScreenState();
}

class _SessionHistoryScreenState extends State<SessionHistoryScreen> {
  List<Session> _sessions = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  void _loadSessions() {
    List<Session> all = DatabaseService.getRecentSessions(limit: 200);
    final now = DateTime.now();
    if (_filter == 'today') {
      all = all.where((s) =>
          s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day).toList();
    } else if (_filter == 'week') {
      final startOfWeek = now.subtract(Duration(days: (now.weekday + 1) % 7));
      all = all.where((s) => s.date.isAfter(startOfWeek.subtract(const Duration(days: 1)))).toList();
    } else if (_filter == 'month') {
      all = all.where((s) => s.date.year == now.year && s.date.month == now.month).toList();
    }
    setState(() => _sessions = all);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 20, color: isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    AppLocalizations.of(context).sessionHistory,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_sessions.length} ${AppLocalizations.of(context).sessionsCount}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(AppLocalizations.of(context).all, 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip(AppLocalizations.of(context).today, 'today'),
                  const SizedBox(width: 8),
                  _buildFilterChip(AppLocalizations.of(context).weeklyChart, 'week'),
                  const SizedBox(width: 8),
                  _buildFilterChip(AppLocalizations.of(context).monthlyChart, 'month'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.history_rounded,
                                size: 32, color: AppColors.primary.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 12),
                          Text('No sessions found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              )),
                          const SizedBox(height: 4),
                          Text('Complete a focus session to see it here',
                              style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _sessions.length,
                      itemBuilder: (context, index) {
                        final session = _sessions[index];
                        return _buildSessionItem(session, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () {
        _filter = value;
        _loadSessions();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

  Widget _buildSessionItem(Session session, bool isDark) {
    final project = DatabaseService.getProject(session.projectId);
    final color = project != null ? Color(project.colorValue) : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    project?.icon ?? '≡ا»',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project?.name ?? AppLocalizations.of(context).noProject,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (session.sessionType == 'tasbeeh' &&
                        (session.count ?? 0) > 0) ...[
                      Text(
                        '${AppLocalizations.of(context).tasbeehType} • ${session.count} ${AppLocalizations.of(context).timesWord}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      '${formatDate(session.date)} • ${formatTime(session.date)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: session.completed
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${fmtMin(session.actualMinutes ?? session.durationMinutes)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: session.completed ? AppColors.success : Colors.grey,
                      ),
                    ),
                  ),
                  if (session.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (i) {
                        return Icon(
                          i < session.rating! ? Icons.star_rounded : Icons.star_outline_rounded,
                          size: 14,
                          color: i < session.rating! ? AppColors.warning : Colors.grey[400],
                        );
                      }),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (session.notes != null && session.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.grey.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.notes!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
