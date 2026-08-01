import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../services/audio_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../widgets/timer_circle.dart';
import '../widgets/completion_celebration.dart';
import '../widgets/break_screen.dart';
import '../services/ambient_sound_service.dart';
import '../utils/page_transitions.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> with WidgetsBindingObserver {
  String? _selectedProjectId;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timerService = context.read<TimerService>();
      timerService.onSessionComplete = _showCelebration;
      timerService.onBreakStart = _showBreakScreen;
      _focusNode.requestFocus();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadSettings();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final timerService = context.read<TimerService>();
    timerService.onSessionComplete = null;
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

  void _showCelebration() {
    final timer = context.read<TimerService>();
    final projectName = _selectedProjectId != null
        ? DatabaseService.getProject(_selectedProjectId!)?.name
        : null;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        CompletionCelebration.show(
          context,
          sessionCount: timer.sessionCount,
          isMilestone: timer.isMilestone,
          quote: timer.completionQuote,
          sessionId: timer.lastCompletedSessionId,
          modeLabel: timer.completedMode == TimerMode.focus
              ? 'Focus'
              : timer.completedMode == TimerMode.shortBreak
                  ? 'Short Break'
                  : 'Long Break',
          durationMinutes: timer.totalSeconds ~/ 60,
          projectName: projectName,
        ).then((_) {
          if (mounted && timer.completedMode == TimerMode.focus && DatabaseService.autoStartBreaks) {
            final breakMin = timer.mode == TimerMode.longBreak
                ? DatabaseService.longBreakDuration
                : DatabaseService.shortBreakDuration;
            _showBreakScreen(breakMin);
          } else if (mounted && timer.completedMode != TimerMode.focus && DatabaseService.autoStartPomodoros) {
            timer.start();
          }
        });
      }
    });
  }
  void _showBreakScreen(int breakMinutes) {
    AmbientSoundService.stop();
    if (!mounted) return;
    Navigator.push(
      context,
      AppModalRoute(page: BreakScreen(
        breakMinutes: breakMinutes,
        onBreakComplete: () {
          AmbientSoundService.stop();
          if (mounted) {
            Navigator.pop(context);
            final timer = context.read<TimerService>();
            timer.reset();
            timer.setDuration(
              TimerMode.focus,
              DatabaseService.focusDuration,
            );
          }
        },
      )),
    );
  }

  void _loadSettings() {
    final timerService = context.read<TimerService>();
    timerService.setFocusDuration(DatabaseService.focusDuration);
    timerService.setShortBreakDuration(DatabaseService.shortBreakDuration);
    timerService.setLongBreakDuration(DatabaseService.longBreakDuration);
    timerService.setAutoStartBreaks(DatabaseService.autoStartBreaks);
    timerService.setAutoStartPomodoros(DatabaseService.autoStartPomodoros);
  }

  Color _getModeColor(TimerMode mode) {
    switch (mode) {
      case TimerMode.focus:
        return AppColors.focusColor;
      case TimerMode.shortBreak:
        return AppColors.shortBreakColor;
      case TimerMode.longBreak:
        return AppColors.longBreakColor;
    }
  }

  void _showDurationPicker(TimerService timer, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentMinutes = timer.totalSeconds ~/ 60;
    int selectedMinutes = currentMinutes;
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
                  const Text(
                    'Set Duration',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Long press on the timer circle to pick',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildPickerButton(Icons.remove_rounded, () {
                        if (selectedMinutes > 1) setModalState(() => selectedMinutes--);
                      }),
                      Container(
                        width: 80,
                        alignment: Alignment.center,
                        child: Text(
                          '$selectedMinutes min',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _buildPickerButton(Icons.add_rounded, () {
                        if (selectedMinutes < 120) setModalState(() => selectedMinutes++);
                      }),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [5, 10, 15, 20, 25, 30, 45, 60, 90].map((m) {
                      final isSelected = selectedMinutes == m;
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedMinutes = m),
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
                        timer.setDuration(timer.mode, selectedMinutes);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Set Duration', style: TextStyle(fontWeight: FontWeight.bold)),
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
              const Text(
                'Select Project',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          'No projects yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create a project in the Projects tab\nthen select it here to start tracking',
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
                            final timer = context.read<TimerService>();
                            timer.setProject(project.id);
                            if (!timer.running && timer.mode == TimerMode.focus) {
                              timer.setDuration(TimerMode.focus, project.defaultDuration);
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
                        final timer = context.read<TimerService>();
                        timer.setProject(null);
                        if (!timer.running && timer.mode == TimerMode.focus) {
                          timer.setDuration(TimerMode.focus, DatabaseService.focusDuration);
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Clear Selection',
                          style: TextStyle(color: AppColors.error)),
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
    final dailyGoal = DatabaseService.dailyGoal;
    final goalProgress = dailyGoal > 0 ? (todayMinutes / (dailyGoal * 60.0)) : 0.0;

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
                Container(
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
                              timer.setDuration(
                                  mode,
                                  mode == TimerMode.focus
                                      ? DatabaseService.focusDuration
                                      : mode == TimerMode.shortBreak
                                          ? DatabaseService.shortBreakDuration
                                          : DatabaseService.longBreakDuration);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: isActive ? modeColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              mode == TimerMode.focus
                                  ? 'Focus'
                                  : mode == TimerMode.shortBreak
                                      ? 'Short'
                                      : 'Long',
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
                const SizedBox(height: 36),
                TimerCircle(
                  progress: timer.progress,
                  time: timer.formattedTime,
                  label: timer.modeLabel,
                  color: color,
                  isRunning: timer.running,
                  onTap: () {
                    if (timer.running) {
                      timer.pause();
                    } else {
                      timer.start();
                    }
                  },
                  onLongPress: timer.running ? null : () => _showDurationPicker(timer, color),
                ),
                if (!timer.running)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Long press to set duration',
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
                    '${todaySessions % interval}/$interval until long break',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (AudioService.isAlarmPlaying)
                  GestureDetector(
                    onTap: timer.stopAlarm,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.error,
                            AppColors.error.withValues(alpha: 0.8)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stop_rounded,
                              color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Stop Alarm',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (!timer.running && timer.seconds == timer.totalSeconds)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Padding(
                      key: ValueKey(timer.sessionCount),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        timer.motivationalQuote,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildControlButton(
                      icon: Icons.refresh_rounded,
                      label: 'Reset',
                      onTap: () { HapticFeedback.lightImpact(); timer.reset(); },
                    ),
                    const SizedBox(width: 28),
                    _buildMainButton(timer, color),
                    const SizedBox(width: 28),
                    _buildControlButton(
                      icon: Icons.skip_next_rounded,
                      label: 'Skip',
                      onTap: () { HapticFeedback.lightImpact(); timer.skip(); },
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
                                  '${(goalProgress * 100).clamp(0, 100).toInt()}',
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
                                      "Today's Progress",
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
                                  '$todayMinutes / ${dailyGoal * 60} min',
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
                            '${todayMinutes}min',
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
                            '$todayMinutes/${dailyGoal * 60}min',
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                                  'Select Project'
                              : 'Select Project',
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

  Widget _buildMainButton(TimerService timer, Color color) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (timer.running) {
          timer.pause();
        } else {
          timer.start();
        }
      },
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
