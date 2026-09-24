import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/debug_logger.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/tasbeeh_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../utils/number_formatter.dart';
import '../widgets/timer_circle.dart';
import '../widgets/break_screen.dart';
import '../services/ambient_sound_service.dart';
import '../utils/page_transitions.dart';
import '../l10n/app_localizations.dart';
import '../utils/productivity_quotes.dart';
import '../utils/quote_library.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  String? _selectedProjectId;
  int _quoteOffset = 0;
  bool _tasbihMode = true;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
      final timerService = context.read<TimerService>();
      timerService.onBreakStart = _showBreakScreen;
      if (_selectedProjectId == null && timerService.currentProjectId != null) {
        setState(() => _selectedProjectId = timerService.currentProjectId);
        context.read<TasbeehService>().setProject(_selectedProjectId);
      }
      if (timerService.pendingRestorePrompt) {
        _showRestoreDialog(timerService);
      }
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DebugLogger.log('UI-LIFE', 'didChangeAppLifecycleState: state=$state');
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final timerService = context.read<TimerService>();
    timerService.onBreakStart = null;
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;
    final timer = context.read<TimerService>();
    if (event.logicalKey == LogicalKeyboardKey.space) {
      HapticFeedback.lightImpact();
      if (timer.running) {
        timer.pause();
      } else {
        timer.start();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.keyR) {
      HapticFeedback.lightImpact();
      timer.reset();
    } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
      HapticFeedback.lightImpact();
      timer.skip();
    }
  }

  void _showBreakScreen(int breakSeconds) {
    AmbientSoundService.stop();
    if (!mounted) return;
    Navigator.push(
      context,
      AppModalRoute(page: BreakScreen(
        breakSeconds: breakSeconds,
        onBreakComplete: () {
          AmbientSoundService.stop();
          if (mounted) {
            Navigator.pop(context);
            final timer = context.read<TimerService>();
            timer.reset();
            timer.setDurationSeconds(
              TimerMode.focus,
              DatabaseService.focusDuration,
            );
          }
        },
      )),
    );
  }

  void _showRestoreDialog(TimerService timer) {
    final running = timer.running;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(running ? AppLocalizations.of(context).stopwatchRunning : AppLocalizations.of(context).stopwatchSession),
          content: Text('${AppLocalizations.of(context).stopwatchSession} ${timer.formattedStopwatchTime}'),
          actions: [
            TextButton(
              onPressed: () {
                timer.consumePendingRestorePrompt();
                if (!running) {
                  timer.start();
                }
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(context).restoreSession),
            ),
            FilledButton(
              onPressed: () {
                timer.consumePendingRestorePrompt();
                Navigator.pop(ctx);
                timer.skip();
              },
              child: Text(AppLocalizations.of(context).endSession),
            ),
          ],
        );
      },
    );
  }

  void _handlePlayPause(TimerService timer) {
    HapticFeedback.lightImpact();
    if (timer.running) {
      timer.pause();
    } else if (timer.mode == TimerMode.stopwatch &&
        timer.stopwatchElapsed == Duration.zero) {
      _runCountInThen(() {
        if (mounted) {
          context.read<TimerService>().start();
        }
      });
    } else {
      timer.start();
    }
  }

  Future<void> _runCountInThen(VoidCallback onComplete) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      pageBuilder: (_, __, ___) => const _CountInOverlay(),
    );
    onComplete();
  }

  void _switchModeIfAllowed(TimerService timer, TimerMode mode) {
    if (timer.running) return;
    if (timer.mode == mode) return;
    if (timer.mode == TimerMode.stopwatch &&
        mode != TimerMode.stopwatch &&
        timer.stopwatchElapsed > Duration.zero) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context).discardStopwatch),
          content: Text(
            AppLocalizations.of(context).stopwatchRunning + ' ' + formatDurationLocalized(
              hours: timer.stopwatchElapsed.inHours,
              minutes: timer.stopwatchElapsed.inMinutes % 60,
              seconds: timer.stopwatchElapsed.inSeconds % 60,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(context).discard),
            ),
          ],
        ),
      ).then((discard) {
        if (discard == true && mounted) {
          timer.setMode(mode);
        }
      });
      return;
    }
    timer.setMode(mode);
  }

  void _loadSettings() {
    final timerService = context.read<TimerService>();
    timerService.setFocusDuration(DatabaseService.focusDuration);
    timerService.setShortBreakDuration(DatabaseService.shortBreakDuration);
    timerService.setLongBreakDuration(DatabaseService.longBreakDuration);
  }

  /// Circle label shows the real selected project's name; falls back to
  /// the localized mode label when no project is chosen.
  String _circleLabel(TimerService timer) {
    final pid = _selectedProjectId ?? timer.currentProjectId;
    if (pid != null && pid.isNotEmpty && timer.mode == TimerMode.focus) {
      final name = DatabaseService.getProject(pid)?.name;
      if (name != null && name.isNotEmpty) return name;
    }
    return switch (timer.mode) {
      TimerMode.focus => AppLocalizations.of(context).focus,
      TimerMode.shortBreak => AppLocalizations.of(context).shortBreak,
      TimerMode.longBreak => AppLocalizations.of(context).longBreak,
      TimerMode.stopwatch => AppLocalizations.of(context).stopwatch,
    };
  }


  Color _getModeColor(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return AppColors.focusColor;
      case TimerMode.shortBreak:
        return AppColors.shortBreakColor;
      case TimerMode.longBreak:
        return AppColors.longBreakColor;
      case TimerMode.stopwatch:
        return AppColors.accent;
    }
  }

  void _showDurationPicker(TimerService timer, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMinutes = timer.totalSeconds ~/ 60;
    final currentSeconds = timer.totalSeconds % 60;
    int selectedMinutes = currentMinutes;
    int selectedSeconds = currentSeconds;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text(
                    AppLocalizations.of(context).setDuration,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppLocalizations.of(context).longPressOnTimer,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPickerButton(Icons.remove_rounded, () {
                        if (selectedMinutes > 0) setModalState(() => selectedMinutes--);
                      }),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppLocalizations.of(context).minutes,
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          SizedBox(
                            width: 80,
                            child: Text(
                              '$selectedMinutes',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      _buildPickerButton(Icons.add_rounded, () {
                        if (selectedMinutes < 120) setModalState(() => selectedMinutes++);
                      }),
                      const SizedBox(width: 24),
                      _buildPickerButton(Icons.remove_rounded, () {
                        if (selectedSeconds > 0) setModalState(() => selectedSeconds--);
                      }),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppLocalizations.of(context).seconds,
                              style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          SizedBox(
                            width: 80,
                            child: Text(
                              selectedSeconds.toString().padLeft(2, '0'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      _buildPickerButton(Icons.add_rounded, () {
                        if (selectedSeconds < 59) setModalState(() => selectedSeconds++);
                      }),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$selectedMinutes:${selectedSeconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [5, 10, 15, 20, 25, 30, 45, 60, 90].map((m) {
                      final isSelected = selectedMinutes == m && selectedSeconds == 0;
                      return GestureDetector(
                        onTap: () => setModalState(() {
                          selectedMinutes = m;
                          selectedSeconds = 0;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${m}m',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : color,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        final total = selectedMinutes * 60 + selectedSeconds;
                        if (total < 1) {
                          setModalState(() => selectedSeconds = 1);
                          return;
                        }
                        timer.setDurationSeconds(timer.mode, total);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(AppLocalizations.of(context).setDuration, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPickerButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.primary, size: 26),
      ),
    );
  }

  void _showProjectPicker() {
    final projects = DatabaseService.getAllProjects();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).selectProject,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
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
                          child: Icon(Icons.folder_open_rounded,
                              size: 32, color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppLocalizations.of(context).noProjectsYet,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context).createProjectHint,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[400], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project = projects[index];
                      final isSelected = _selectedProjectId == project.id;
                      final color = Color(project.colorValue);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? color.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(project.icon,
                                  style: const TextStyle(fontSize: 18)),
                            ),
                          ),
                          title: Text(project.name,
                              style: const TextStyle(fontWeight: FontWeight.w500)),
                          trailing: isSelected
                              ? Icon(Icons.check_circle, color: color, size: 22)
                              : null,
                          onTap: () {
                            setState(() => _selectedProjectId = project.id);
                            final tasbeeh = context.read<TasbeehService>();
                            if (tasbeeh.projectId != project.id) {
                              tasbeeh.setProject(project.id);
                            }
                            final timer = context.read<TimerService>();
                            timer.setProject(project.id);
                            if (!timer.running && timer.mode == TimerMode.focus) {
                              timer.setDurationSeconds(TimerMode.focus, project.defaultDuration);
                            }
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              if (_selectedProjectId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() => _selectedProjectId = null);
                        final tasbeeh = context.read<TasbeehService>();
                        tasbeeh.finishAndSave(notifyUi: false);
                        tasbeeh.setProject(null);
                        final timer = context.read<TimerService>();
                        timer.setProject(null);
                        if (!timer.running && timer.mode == TimerMode.focus) {
                          timer.setDurationSeconds(TimerMode.focus, DatabaseService.focusDuration);
                        }
                        Navigator.pop(context);
                      },
                      child: Text(AppLocalizations.of(context).clearSelection,
                          style: const TextStyle(color: AppColors.error)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerService>();
    final color = _getModeColor(timer.mode);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final interval = DatabaseService.longBreakInterval;
    final todaySessions = timer.sessionCount;
    final todayMinutes = DatabaseService.getTodayMinutes();
    final dailyGoalMin = DatabaseService.dailyTargetMinutes;
    final goalProgress = dailyGoalMin > 0 ? (todayMinutes / dailyGoalMin) : 0.0;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        _handleKeyEvent(event);
        return KeyEventResult.handled;
      },
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
              children: [
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: TimerMode.values.map((mode) {
                      final isActive = timer.mode == mode;
                      final modeColor = _getModeColor(mode);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: GestureDetector(
                          onTap: () {
                            if (!timer.running) {
                              _switchModeIfAllowed(timer, mode);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: EdgeInsets.symmetric(
                                horizontal: mode == TimerMode.stopwatch
                                    ? 12
                                    : 20,
                                vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive ? modeColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              switch (mode) {
                                TimerMode.focus => AppLocalizations.of(context).focus,
                                TimerMode.shortBreak => AppLocalizations.of(context).shortBreak,
                                TimerMode.longBreak => AppLocalizations.of(context).longBreak,
                                TimerMode.stopwatch => '⏱ ${AppLocalizations.of(context).stopwatch}',
                              },
                              style: TextStyle(
                                color: isActive
                                    ? Colors.white
                                    : isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  ),
                ),
                 const SizedBox(height: 14),
                 // Timer / Tasbih elegant toggle.
                 Center(
                   child: Container(
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       color: isDark
                           ? Colors.white.withValues(alpha: 0.05)
                           : Colors.black.withValues(alpha: 0.03),
                       borderRadius: BorderRadius.circular(24),
                     ),
                     child: Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         _modeSwitchChip(
                           icon: Icons.timer_outlined,
                           label: AppLocalizations.of(context).timer,
                           active: !_tasbihMode,
                           isDark: isDark,
                           color: color,
                           onTap: () {
                             context.read<TasbeehService>().finishAndSave();
                             setState(() => _tasbihMode = false);
                           },
                         ),
                         _modeSwitchChip(
                           icon: Icons.circle_outlined,
                           label: AppLocalizations.of(context).tasbih,
                           active: _tasbihMode,
                           isDark: isDark,
                           color: AppColors.success,
                           onTap: () => setState(() => _tasbihMode = true),
                         ),
                       ],
                     ),
                   ),
                 ),
                 const SizedBox(height: 22),
                 if (_tasbihMode)
                   _TasbeehView(
                     isDark: isDark,
                     projectColor: color,
                     onPickProject: _showProjectPicker,
                   )
                  else ...[
                 TimerCircle(
                  progress: timer.mode == TimerMode.stopwatch
                      ? null
                      : timer.progress,
                  time: timer.mode == TimerMode.stopwatch
                      ? timer.formattedStopwatchTime
                      : timer.formattedTime,
                  label: _circleLabel(timer),
                  color: color,
                  isRunning: timer.running,
                  onTap: () => _handlePlayPause(timer),
                  onLongPress:
                      (timer.running || timer.mode == TimerMode.stopwatch)
                          ? null
                          : () => _showDurationPicker(timer, color),
                ),
                if (!timer.running && timer.mode != TimerMode.stopwatch)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                     child: Text(
                       AppLocalizations.of(context).longPressHint,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (timer.mode == TimerMode.focus) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(interval, (i) {
                      final filled = i < (todaySessions % interval);
                      final isCurrent = i == (todaySessions % interval);
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isCurrent ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: filled
                              ? color
                              : isCurrent
                                  ? color.withValues(alpha: 0.3)
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.grey.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                   Text(
                     '${todaySessions % interval}/$interval ${AppLocalizations.of(context).untilLongBreak}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                 const SizedBox(height: 8),
                 if (timer.running && timer.mode != TimerMode.stopwatch)
                   _SessionQuoteRotator(
                     key: ValueKey(_selectedProjectId ?? 'no-project'),
                     projectName: _circleLabel(timer) == AppLocalizations.of(context).focus
                         ? null
                         : _circleLabel(timer),
                     isDark: isDark,
                   )
                 else if (!timer.running && timer.seconds == timer.totalSeconds)
                   AnimatedSwitcher(
                     duration: const Duration(milliseconds: 500),
                     child: _QuoteOfDayChip(
                       key: ValueKey(timer.sessionCount + _quoteOffset),
                       isDark: isDark,
                       offset: _quoteOffset,
                       onShuffle: () =>
                           setState(() => _quoteOffset++),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: Icons.refresh_rounded,
                      label: timer.mode == TimerMode.stopwatch
                          ? AppLocalizations.of(context).reset
                          : AppLocalizations.of(context).reset,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        timer.reset();
                      },
                    ),
                    const SizedBox(width: 28),
                    _buildMainButton(timer, color),
                    const SizedBox(width: 28),
                    _buildControlButton(
                      icon: Icons.skip_next_rounded,
                      label: timer.mode == TimerMode.stopwatch
                          ? AppLocalizations.of(context).skip
                          : AppLocalizations.of(context).skip,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        timer.skip();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Space: Start/Pause  |  R: Reset  |  S: Skip',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 52,
                                  height: 52,
                                  child: CircularProgressIndicator(
                                    value: goalProgress.clamp(0.0, 1.0),
                                    strokeWidth: 5,
                                    backgroundColor: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      goalProgress >= 1 ? AppColors.success : color,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                  Text(
                                  '${(goalProgress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: goalProgress >= 1 ? AppColors.success : color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.today_rounded,
                                        color: color.withValues(alpha: 0.7), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context).todayProgress,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$todayMinutes / $dailyGoalMin min',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (goalProgress >= 1)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '✓ Done',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMiniStat(
                            Icons.access_time_rounded,
                            '${fmtMin(todayMinutes)}',
                            isDark,
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                          _buildMiniStat(
                            Icons.local_fire_department,
                            '$todaySessions sessions',
                            isDark,
                          ),
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.grey.withValues(alpha: 0.15),
                          ),
                          _buildMiniStat(
                            Icons.flag_rounded,
                            '${fmtMin(todayMinutes)} / ',
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                 ),
                 ],
                 const SizedBox(height: 12),
                 GestureDetector(
                   onTap: _showProjectPicker,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: _selectedProjectId != null
                          ? color.withValues(alpha: 0.08)
                          : isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedProjectId != null
                            ? color.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: _selectedProjectId == null
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder_open,
                            color: _selectedProjectId != null
                                ? color
                                : Colors.grey,
                            size: 20),
                        const SizedBox(width: 10),
                        Text(
                          _selectedProjectId != null
                              ? DatabaseService.getProject(_selectedProjectId!)
                                      ?.name ??
                                  AppLocalizations.of(context).selectProject
                              : AppLocalizations.of(context).selectProject,
                          style: TextStyle(
                            color: _selectedProjectId != null
                                ? (isDark ? Colors.white : Colors.black87)
                                : Colors.grey,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down,
                            color: _selectedProjectId != null
                                ? color
                                : Colors.grey,
                            size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String text, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.grey[400]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _modeSwitchChip({
    required IconData icon,
    required String label,
    required bool active,
    required bool isDark,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active
                    ? Colors.white
                    : isDark
                        ? Colors.grey[400]
                        : Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active
                    ? Colors.white
                    : isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(TimerService timer, Color color) {
    return GestureDetector(
      onTap: () => _handlePlayPause(timer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withValues(alpha: 0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          timer.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 38,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: AppColors.primary.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace')),
      ],
    );
  }
}

class _CountInOverlay extends StatefulWidget {
  const _CountInOverlay();

  @override
  State<_CountInOverlay> createState() => _CountInOverlayState();
}

class _CountInOverlayState extends State<_CountInOverlay> {
  static const _steps = ['3', '2', '1'];
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (t) {
      if (_index >= _steps.length) {
        t.cancel();
        Navigator.of(context).pop();
      } else {
        setState(() => _index++);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _index < _steps.length ? _steps[_index] : AppLocalizations.of(context).start,
            key: ValueKey(_index),
            style: TextStyle(
              fontSize: 96,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Deterministic quote of the day with a manual shuffle button.
class _QuoteOfDayChip extends StatelessWidget {
  final bool isDark;
  final int offset;
  final VoidCallback onShuffle;

  const _QuoteOfDayChip({
    super.key,
    required this.isDark,
    required this.offset,
    required this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final q = ProductivityQuotes.quoteOfDay(DateTime.now(), offset: offset);
    final text = ProductivityQuotes.textOf(q, l10n.isArabic);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Text(
            '\u201E$text\u201C',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontSize: 13.5,
              height: 1.5,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onShuffle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded,
                    size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
                const SizedBox(width: 3),
                Text(
                  l10n.anotherQuote,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Elegant tasbih counter replacing the timer circle when toggled.
class _SessionQuoteRotator extends StatefulWidget {
  final String? projectName;
  final bool isDark;

  const _SessionQuoteRotator({
    super.key,
    required this.projectName,
    required this.isDark,
  });

  static const rotationInterval = Duration(seconds: 30);

  @override
  State<_SessionQuoteRotator> createState() => _SessionQuoteRotatorState();
}

class _SessionQuoteRotatorState extends State<_SessionQuoteRotator> {
  late final List<Map<String, String>> _quotes;
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _quotes = QuoteLibrary.quotesForProject(widget.projectName);
    // Start at a stable pseudo-random offset so each session differs.
    _index = DateTime.now().minute % _quotes.length;
    _timer = Timer.periodic(_SessionQuoteRotator.rotationInterval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _quotes.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _quotes[_index];
    final text = QuoteLibrary.quoteText(q);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, anim) {
          final isIn = child.key == ValueKey(_index);
          final slide = Tween<Offset>(
            begin: isIn ? const Offset(0, 0.25) : const Offset(0, -0.25),
            end: Offset.zero,
          ).animate(anim);
          return FadeTransition(
              opacity: anim, child: SlideTransition(position: slide, child: child));
        },
        child: Text(
          '\u201E$text\u201C',
          key: ValueKey(_index),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13.5,
            height: 1.5,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}


/// ─────────────────────────────────────────────────────────────
/// Full tasbeeh activity view — project-aware, session-backed,
/// progress ring, goal celebration, long-press goal presets.
/// ─────────────────────────────────────────────────────────────


/// ─────────────────────────────────────────────────────────────
/// Tasbeeh v2 — single gesture owner (tap always counts), vivid
/// gradient circle + progress ring, dhikr chip, goal card, quick stats.
/// ─────────────────────────────────────────────────────────────
class _TasbeehView extends StatefulWidget {
  final bool isDark;
  final Color projectColor;
  final VoidCallback onPickProject;

  const _TasbeehView({
    required this.isDark,
    required this.projectColor,
    required this.onPickProject,
  });

  @override
  State<_TasbeehView> createState() => _TasbeehViewState();
}

class _TasbeehViewState extends State<_TasbeehView>
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
    // Live ascending time display while the dhikr session is active.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final svc = context.read<TasbeehService>();
      if (svc.isActive) {
        setState(() => _tick++);
      }
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
    // Pop the number 100 -> 108 -> 100 without delaying the increment.
    if (svc.count > before || svc.count == 1) {
      _pulse.forward(from: 0);
    }
    if (!widget.isDark && !DatabaseService.completionVibrationEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<TasbeehService>();
    final l10n = AppLocalizations.of(context);
    final project = svc.projectId.isNotEmpty
        ? DatabaseService.getProject(svc.projectId)
        : null;
    final accent =
        project != null ? Color(project.colorValue) : AppColors.success;
    final goal = svc.goal();
    final count = svc.count;
    final progress = goal > 0 ? (count / goal).clamp(0.0, 1.0) : 0.0;
    final reached = goal > 0 && count >= goal;

    return Column(
      children: [
        // ── Header label ──
        Text(
          l10n.tasbih,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
            color: accent.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 10),

        // ── Dhikr chip ──
        GestureDetector(
          onTap: () => _pickDhikr(svc),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: accent.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: widget.isDark ? 0.2 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  svc.currentDhikr,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Colors.grey[500]),
              ],
            ),
          ),
        ),

        // ── Project chip / pick hint ──
        const SizedBox(height: 8),
        GestureDetector(
          onTap: widget.onPickProject,
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
                          ? (widget.isDark
                              ? Colors.white70
                              : Colors.grey[700])
                          : AppColors.warning,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ── Live time + count header (ascending stopwatch) ──
        const SizedBox(height: 10),
        _LiveTasbeehTime(
          key: ValueKey(_tick),
          elapsed: svc.elapsedSeconds,
          active: svc.isActive,
          accent: accent,
          isDark: widget.isDark,
        ),
        const SizedBox(height: 12),

        // ── THE CIRCLE — single GestureDetector owns everything ──
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
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: reached
                        ? [
                            AppColors.success,
                            AppColors.tasbeehGreen,
                          ]
                        : [
                            accent,
                            accent.withValues(alpha: 0.7),
                          ],
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
                    // Progress ring hugging the inner edge.
                    SizedBox(
                      width: 244,
                      height: 244,
                      child: CustomPaint(
                        painter: _TasbeehRingPainter(
                          progress: progress,
                          showRing: goal > 0,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Pulsing number.
                        AnimatedBuilder(
                          animation: _pulse,
                          builder: (context, child) {
                            final t = _pulse.value;
                            final scale =
                                1.0 + 0.08 * (1.0 - (2 * t - 1).abs());
                            return Transform.scale(
                              scale: scale,
                              child: child,
                            );
                          },
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 68,
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
                            color:
                                Colors.white.withValues(alpha: 0.18),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: Text(
                            l10n.tapToCount,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color:
                                  Colors.white.withValues(alpha: 0.95),
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

        // ── Progress text ──
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

        // ── Actions ──
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TasbeehAction(
              icon: Icons.refresh_rounded,
              label: l10n.reset,
              isDark: widget.isDark,
              onTap: () => _confirmReset(context, svc),
            ),
            const SizedBox(width: 14),
            _TasbeehAction(
              icon: Icons.check_rounded,
              label: l10n.endSession,
              isDark: widget.isDark,
              filled: count > 0,
              onTap: count > 0 ? () => svc.finishAndSave() : null,
            ),
          ],
        ),

        // ── Goal card ──
        if (goal > 0) ...[
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: widget.isDark
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
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: progress),
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor:
                          accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          reached ? AppColors.success : accent),
                    ),
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

        // ── Quick stats card ──
        const SizedBox(height: 12),
        _QuickStatsCard(isDark: widget.isDark, accent: accent),
      ],
    );
  }

  void _pickDhikr(TasbeehService svc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
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
                  final selected = svc.dhikrIndex == i;
                  final isAr = AppLocalizations.of(ctx).isArabic;
                  final label = isAr
                      ? TasbeehService.dhikrOptions[i].$1
                      : TasbeehService.dhikrOptions[i].$2;
                  return ListTile(
                    title: Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selected
                            ? AppColors.success
                            : (isDark
                                ? Colors.white
                                : Colors.black87),
                      ),
                    ),
                    trailing: selected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppColors.success, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      svc.setDhikrIndex(i);
                    },
                  );
                }),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmReset(BuildContext context, TasbeehService svc) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resetCountTitle),
        content: Text(l10n.resetCountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              svc.resetCount();
            },
            child: Text(l10n.reset),
          ),
        ],
      ),
    );
  }

  void _showGoalSheet(TasbeehService svc, int currentGoal) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final ctrl = TextEditingController(
            text: currentGoal > 0 ? '$currentGoal' : '');
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(l10n.tasbeehGoalLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [33, 100, 300, 500, 1000].map((p) {
                    final active = currentGoal == p;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        svc.setGoal(p);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.success
                              : AppColors.success
                                  .withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.success.withValues(
                                  alpha: active ? 1 : 0.3)),
                        ),
                        child: Text('$p',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: active
                                    ? Colors.white
                                    : AppColors.success)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 7,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: l10n.customValue,
                    counterText: '',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onSubmitted: (v) {
                    final n = int.tryParse(v) ?? 0;
                    Navigator.pop(ctx);
                    svc.setGoal(n);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LiveTasbeehTime extends StatelessWidget {
  final int elapsed;
  final bool active;
  final Color accent;
  final bool isDark;

  const _LiveTasbeehTime({
    super.key,
    required this.elapsed,
    required this.active,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final mm = (elapsed ~/ 60).toString().padLeft(2, '0');
    final ss = (elapsed % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(active ? Icons.timer_rounded : Icons.timer_outlined,
              size: 15, color: active ? accent : Colors.grey[500]),
          const SizedBox(width: 6),
Text(
                            '$mm:$ss',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: active ? accent : Colors.grey[500],
                            ),
                          ),
          const SizedBox(width: 6),
          Text(
            l10n.ascendingTimeLabel,
            style: TextStyle(
                fontSize: 10.5, color: Colors.grey[500], height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsCard extends StatelessWidget {
  final bool isDark;
  final Color accent;

  const _QuickStatsCard({required this.isDark, required this.accent});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = DatabaseService.getTasbeehCountForDay(DateTime.now());
    final total = DatabaseService.getTasbeehTotalCount();

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 0, 28, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
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
                    style:
                        TextStyle(fontSize: 10.5, color: Colors.grey[500])),
              ],
            ),
          ),
          Container(width: 1, height: 30, color: Colors.grey.withValues(alpha: 0.2)),
          Expanded(
            child: Column(
              children: [
                Text('$total',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(l10n.totalTasbeehLabel,
                    style:
                        TextStyle(fontSize: 10.5, color: Colors.grey[500])),
              ],
            ),
          ),
        ],
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

class _TasbeehAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final bool filled;
  final VoidCallback? onTap;

  const _TasbeehAction({
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
