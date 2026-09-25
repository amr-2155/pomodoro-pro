import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/tasbeeh_service.dart';
import '../utils/constants.dart';

/// حاسبة الذكر والوقت — standalone dhikr + live ascending time counter.
class DhikrScreen extends StatefulWidget {
  const DhikrScreen({super.key});

  @override
  State<DhikrScreen> createState() => _DhikrScreenState();
}

class _DhikrScreenState extends State<DhikrScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  Timer? _ticker;
  bool _pressed = false;
  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: 1.0,
    );
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final svc = context.read<TasbeehService>();
      if (svc.isActive) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _onTap(TasbeehService svc) {
    final before = svc.count;
    svc.tap();
    if (svc.count > before || svc.count == 1) _pulse.forward(from: 0);
    if (Theme.of(context).brightness != Brightness.dark &&
        !DatabaseService.completionVibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _pickDhikr(TasbeehService svc) async {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(TasbeehService.dhikrOptions.length, (i) {
                final sel = svc.dhikrIndex == i;
                final label = l10n.isArabic
                    ? TasbeehService.dhikrOptions[i].$1
                    : TasbeehService.dhikrOptions[i].$2;
                return ListTile(
                  title: Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          sel ? FontWeight.bold : FontWeight.w500,
                      color: sel
                          ? AppColors.success
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  trailing: sel
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 20)
                      : null,
                  onTap: () => Navigator.pop(ctx, i),
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (selected != null) svc.setDhikrIndex(selected);
  }

  Future<void> _showGoalSheet(TasbeehService svc, int currentGoal) async {
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController(
        text: currentGoal > 0 ? '$currentGoal' : '100');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final value = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.tasbeehGoalLabel,
                  style:
                      const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (v) =>
                    Navigator.pop(ctx, int.tryParse(v) ?? 0),
              ),
              const SizedBox(height: 12),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  minimumSize: const Size.fromHeight(46),
                ),
                onPressed: () =>
                    Navigator.pop(ctx, int.tryParse(ctrl.text) ?? 0),
                child: Text(l10n.save,
                    style: const TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
    if (value != null) svc.setGoal(value);
  }

  Future<bool> _confirmReset(TasbeehService svc) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.resetCountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.reset,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) svc.resetCount();
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<TasbeehService>();
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final project = svc.projectId.isNotEmpty
        ? DatabaseService.getProject(svc.projectId)
        : null;
    final accent =
        project != null ? Color(project.colorValue) : AppColors.success;
    final goal = svc.goal();
    final count = svc.count;
    final progress = goal > 0 ? (count / goal).clamp(0.0, 1.0) : 0.0;
    final reached = goal > 0 && count >= goal;
    final elapsed = svc.elapsedSeconds;
    final mm = (elapsed ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsed % 60).toString().padLeft(2, '0');
    final today = DatabaseService.getTasbeehCountForDay(DateTime.now());
    final total = DatabaseService.getTasbeehTotalCount();

    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.dhikrTimeCounterTitle,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.dhikrTimeCounterSub,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 16),

              // Live ascending time + count header.
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: accent.withValues(alpha: 0.35)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(svc.isActive
                        ? Icons.timer_rounded
                        : Icons.timer_outlined, size: 17, color: accent),
                    const SizedBox(width: 6),
                    Text('$mm:$ss',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: svc.isActive ? accent : Colors.grey[500],
                        )),
                    const SizedBox(width: 10),
                    Icon(Icons.arrow_upward_rounded,
                        size: 16, color: svc.isActive ? accent : Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text('$count',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Dhikr picker.
              GestureDetector(
                onTap: () => _pickDhikr(svc),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(svc.currentDhikr,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark ? Colors.white : Colors.black87,
                          )),
                      const SizedBox(width: 6),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: Colors.grey[500]),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 10),
              _ProjectChip(
                project: project,
                accent: accent,
                isDark: isDark,
                onPickProject: () => _showProjectPicker(svc),
              ),

              const SizedBox(height: 18),

              // THE CIRCLE.
              Listener(
                onPointerDown: (_) => setState(() => _pressed = true),
                onPointerUp: (_) => setState(() => _pressed = false),
                onPointerCancel: (_) => setState(() => _pressed = false),
                child: AnimatedScale(
                  scale: _pressed ? 0.965 : 1.0,
                  duration: const Duration(milliseconds: 110),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _onTap(svc),
                    onLongPress: () => _showGoalSheet(svc, goal),
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: reached
                              ? [AppColors.success, AppColors.tasbeehGreen]
                              : [accent, accent.withValues(alpha: 0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (reached ? AppColors.success : accent)
                                .withValues(alpha: 0.4),
                            blurRadius: 32,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 234,
                            height: 234,
                            child: CustomPaint(
                              painter: _TasbeehRingPainter(
                                  progress: progress, showRing: goal > 0),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (context, child) {
                                  final t = _pulse.value;
                                  final scale = 1.0 +
                                      0.08 * (1.0 - (2 * t - 1).abs());
                                  return Transform.scale(
                                      scale: scale, child: child);
                                },
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontSize: 66,
                                    height: 1.0,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  l10n.tapToCount,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white
                                        .withValues(alpha: 0.95),
                                  ),
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

              // Progress text.
              const SizedBox(height: 12),
              if (goal > 0)
                Text(
                  reached
                      ? '✓ $count / $goal · 100%'
                      : '$count / $goal · ${(progress * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: reached ? AppColors.success : Colors.grey[500],
                  ),
                )
              else
                Text(
                  l10n.noGoalSet,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[400]),
                ),

              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Action(
                    icon: Icons.refresh_rounded,
                    label: l10n.reset,
                    isDark: isDark,
                    onTap: () => _confirmReset(svc),
                  ),
                  const SizedBox(width: 14),
                  _Action(
                    icon: Icons.check_rounded,
                    label: l10n.endSession,
                    isDark: isDark,
                    filled: count > 0,
                    onTap: count > 0 ? () => svc.finishAndSave() : null,
                  ),
                ],
              ),

              // Goal card.
              if (goal > 0) ...[
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(l10n.goalCardTitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: accent)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _showGoalSheet(svc, goal),
                            child: Icon(Icons.edit_outlined,
                                size: 15, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 7,
                          backgroundColor:
                              accent.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation<Color>(
                              reached ? AppColors.success : accent),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$count ${l10n.timesWord} · ${(progress * 100).round()}%',
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 12),
              // Quick stats.
              Container(
                margin: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text('$today',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: accent)),
                          Text(l10n.todaySessionWord,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30,
                        color: Colors.grey.withValues(alpha: 0.2)),
                    Expanded(
                      child: Column(
                        children: [
                          Text('$total',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : Colors.black87)),
                          Text(l10n.totalTasbeehLabel,
                              style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey[500])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showProjectPicker(TasbeehService svc) async {
    final l10n = AppLocalizations.of(context);
    final projects = DatabaseService.getAllProjects();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              if (projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(l10n.noProjectsYet,
                      style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13)),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: projects.map((p) {
                      final color = Color(p.colorValue);
                      final isSel = svc.projectId == p.id;
                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(p.icon,
                                style: const TextStyle(fontSize: 18)),
                          ),
                        ),
                        title: Text(p.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        trailing: isSel
                            ? Icon(Icons.check_circle,
                                color: color, size: 22)
                            : null,
                        onTap: () => Navigator.pop(ctx, p.id),
                      );
                    }).toList(),
                  ),
                ),
              ListTile(
                leading: const Icon(Icons.clear_all_rounded),
                title: Text(l10n.clearSelection,
                    style: const TextStyle(color: AppColors.error)),
                onTap: () => Navigator.pop(ctx, ''),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (selectedId == null) return;
    if (selectedId.isNotEmpty) {
      final p = DatabaseService.getProject(selectedId);
      if (p != null) {
        svc.finishAndSave(notifyUi: false);
        svc.setProject(selectedId);
      }
    } else {
      svc.finishAndSave(notifyUi: false);
      svc.setProject(null);
    }
  }
}

class _ProjectChip extends StatelessWidget {
  final dynamic project;
  final Color accent;
  final bool isDark;
  final VoidCallback onPickProject;

  const _ProjectChip({
    required this.project,
    required this.accent,
    required this.isDark,
    required this.onPickProject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onPickProject,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: project != null
              ? accent.withValues(alpha: 0.1)
              : AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: project != null
                ? accent.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project != null) ...[
              Text(project.icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                project?.name ?? l10n.chooseProjectHint,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: project != null
                      ? (isDark ? Colors.white70 : Colors.grey[700])
                      : AppColors.warning,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool filled;
  final VoidCallback? onTap;

  const _Action({
    required this.icon,
    required this.label,
    required this.isDark,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.success
              : (isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(26),
          border: filled
              ? null
              : Border.all(color: Colors.grey.withValues(alpha: 0.25)),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.45,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 18,
                  color: filled
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.grey[700])),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: filled
                        ? Colors.white
                        : (isDark ? Colors.white70 : Colors.grey[700]),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TasbeehRingPainter extends CustomPainter {
  final double progress;
  final bool showRing;

  _TasbeehRingPainter({required this.progress, required this.showRing});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final rect = Rect.fromCircle(center: center, radius: radius - 5);

    if (showRing) {
      final track = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withValues(alpha: 0.3);
      canvas.drawArc(rect, 0, 2 * pi, false, track);

      final arc = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..color = AppColors.warning;
      canvas.drawArc(
          rect, -pi / 2, 2 * pi * progress.clamp(0.0, 1.0), false, arc);
    } else {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = Colors.white.withValues(alpha: 0.35);
      canvas.drawArc(rect, 0, 2 * pi, false, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _TasbeehRingPainter old) =>
      old.progress != progress;
}