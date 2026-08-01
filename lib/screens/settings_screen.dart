import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/database_service.dart';
import '../services/data_backup_service.dart';
import '../services/pwa_service.dart';
import '../services/timer_service.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late int _focusDuration;
  late int _shortBreakDuration;
  late int _longBreakDuration;
  late bool _darkMode;
  late bool _autoStartBreaks;
  late bool _autoStartPomodoros;
  late bool _soundEnabled;
  late bool _tickSoundEnabled;
  late int _dailyGoal;
  late int _longBreakInterval;
  late double _ambientVolume;
  late int _startOfWeek;

  @override
  void initState() {
    super.initState();
    _focusDuration = DatabaseService.focusDuration;
    _shortBreakDuration = DatabaseService.shortBreakDuration;
    _longBreakDuration = DatabaseService.longBreakDuration;
    _darkMode = DatabaseService.darkMode;
    _autoStartBreaks = DatabaseService.autoStartBreaks;
    _autoStartPomodoros = DatabaseService.autoStartPomodoros;
    _soundEnabled = DatabaseService.soundEnabled;
    _tickSoundEnabled = DatabaseService.tickSoundEnabled;
    _dailyGoal = DatabaseService.dailyGoal;
    _longBreakInterval = DatabaseService.longBreakInterval;
    _ambientVolume = DatabaseService.ambientVolume;
    _startOfWeek = DatabaseService.startOfWeek;
  }

  void _saveSetting(String key, dynamic value) {
    DatabaseService.setSetting(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Timer'),
            _buildDurationTile(
              'Focus Duration',
              _focusDuration,
              (v) {
                setState(() => _focusDuration = v);
                _saveSetting('focusDuration', v);
              },
              min: 1,
              max: 90,
            ),
            _buildDurationTile(
              'Short Break',
              _shortBreakDuration,
              (v) {
                setState(() => _shortBreakDuration = v);
                _saveSetting('shortBreakDuration', v);
              },
              min: 1,
              max: 30,
            ),
            _buildDurationTile(
              'Long Break',
              _longBreakDuration,
              (v) {
                setState(() => _longBreakDuration = v);
                _saveSetting('longBreakDuration', v);
              },
              min: 1,
              max: 60,
            ),
            _buildSwitchTile(
              'Auto-start Breaks',
              'Automatically start break after a focus session',
              _autoStartBreaks,
              (v) {
                setState(() => _autoStartBreaks = v);
                _saveSetting('autoStartBreaks', v);
              },
            ),
            _buildSwitchTile(
              'Auto-start Focus',
              'Automatically start focus after a break',
              _autoStartPomodoros,
              (v) {
                setState(() => _autoStartPomodoros = v);
                _saveSetting('autoStartPomodoros', v);
              },
            ),
            _buildDurationTile(
              'Sessions Before Long Break',
              _longBreakInterval,
              (v) {
                setState(() => _longBreakInterval = v);
                _saveSetting('longBreakInterval', v);
              },
              min: 2,
              max: 8,
            ),

            const SizedBox(height: 12),
            _buildSectionTitle('Goals'),
            _buildDurationTile(
              'Daily Goal (hours)',
              _dailyGoal,
              (v) {
                setState(() => _dailyGoal = v);
                _saveSetting('dailyGoal', v);
              },
              min: 1,
              max: 16,
            ),

            const SizedBox(height: 12),
            _buildSectionTitle('Sound & Vibration'),
            _buildSwitchTile(
              'Sound Effects',
              'Play chime when session completes',
              _soundEnabled,
              (v) {
                setState(() => _soundEnabled = v);
                _saveSetting('soundEnabled', v);
              },
            ),
            _buildSwitchTile(
              'Tick Sound',
              'Play countdown tick in last 10 seconds',
              _tickSoundEnabled,
              (v) {
                setState(() => _tickSoundEnabled = v);
                _saveSetting('tickSoundEnabled', v);
              },
            ),
            _buildSliderTile(
              'Ambient Volume',
              _ambientVolume,
              (v) {
                setState(() => _ambientVolume = v);
                _saveSetting('ambientVolume', v);
              },
            ),

            const SizedBox(height: 12),
            _buildSectionTitle('Appearance'),
            _buildSwitchTile(
              'Dark Mode',
              'Use dark theme',
              _darkMode,
              (v) {
                setState(() => _darkMode = v);
                _saveSetting('darkMode', v);
              },
            ),
            _buildStartOfWeekTile(),

            const SizedBox(height: 12),
            _buildSectionTitle('Data'),
            _buildActionTile(
              'Create Backup',
              'Download all data as a JSON backup file',
              Icons.cloud_download_rounded,
              () => _createBackup(),
            ),
            _buildActionTile(
              'Restore Backup',
              'Import data from a backup file',
              Icons.cloud_upload_rounded,
              () => _restoreBackup(),
            ),
            _buildActionTile(
              'Export CSV',
              'Export sessions as a spreadsheet-friendly CSV file',
              Icons.table_chart_rounded,
              () => _exportData(),
            ),
            _buildActionTile(
              'Reset All Data',
              'Delete all sessions and projects',
              Icons.delete_forever_rounded,
              () => _confirmReset(),
              isDestructive: true,
            ),

            const SizedBox(height: 12),
            _buildSectionTitle('About'),
            if (!PwaService.isStandalone)
              _buildActionTile(
                'Install App',
                'Add Pomodoro Pro to your home screen',
                Icons.install_mobile_rounded,
                () => _installPwa(),
              ),
            _buildActionTile(
              'Pomodoro Pro v1.0.0',
              'Built with Flutter & Web Audio API',
              Icons.info_outline_rounded,
              () {},
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'Pomodoro Pro v1.0.0',
                style: TextStyle(
                    color: Colors.grey[400], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDurationTile(
    String title,
    int value,
    ValueChanged<int> onChanged, {
    int min = 1,
    int max = 90,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          _buildValueButton(
            icon: Icons.remove_rounded,
            onPressed: value > min ? () => onChanged(value - 1) : null,
          ),
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Text(
              '$value min',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildValueButton(
            icon: Icons.add_rounded,
            onPressed: value < max ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildValueButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: AppColors.primary,
        padding: EdgeInsets.zero,
        iconSize: 22,
        splashRadius: 20,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(title,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDestructive ? AppColors.error : AppColors.primary)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon,
                      color: isDestructive ? AppColors.error : AppColors.primary,
                      size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDestructive ? AppColors.error : null,
                        ),
                      ),
                      Text(subtitle,
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderTile(String title, double value, ValueChanged<double> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                Text('${(value * 100).round()}%',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.primary,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              inactiveTrackColor: Colors.grey[300],
            ),
            child: Slider(
              value: value,
              onChanged: onChanged,
              min: 0,
              max: 1,
              divisions: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartOfWeekTile() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start of Week',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(_startOfWeek == 1 ? 'Monday' : 'Sunday',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 1, label: Text('Mon')),
              ButtonSegment(value: 7, label: Text('Sun')),
            ],
            selected: {_startOfWeek},
            onSelectionChanged: (v) {
              setState(() => _startOfWeek = v.first);
              _saveSetting('startOfWeek', v.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _createBackup() {
    DataBackupService.downloadBackup(context, DatabaseService.createBackup());
  }

  void _restoreBackup() {
    DataBackupService.pickAndRestore(context);
  }

  void _installPwa() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Use your browser menu > "Add to Home screen" or "Install App"',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _exportData() {
    final sessions = DatabaseService.getAllSessions();
    final tasks = DatabaseService.getAllTasks();
    final csv = StringBuffer();
    csv.writeln('=== SESSIONS ===');
    csv.writeln('Date,Project,Duration (min),Completed,Type,Rating,Notes');
    for (final s in sessions) {
      final project = DatabaseService.getProject(s.projectId);
      final projectName = _csvEscape(project?.name ?? s.projectId);
      final rating = s.rating?.toString() ?? '';
      final notes = _csvEscape(s.notes ?? '');
      csv.writeln(
          '${s.date.toIso8601String()},$projectName,${s.durationMinutes},${s.completed},${s.sessionType},$rating,$notes');
    }
    csv.writeln('');
    csv.writeln('=== TASKS ===');
    csv.writeln('Title,Project,Priority,Estimated,Completed,Done,Description');
    for (final t in tasks) {
      final project = t.projectId != null ? DatabaseService.getProject(t.projectId!) : null;
      final projectName = _csvEscape(project?.name ?? t.projectId ?? '');
      final desc = _csvEscape(t.description ?? '');
      csv.writeln(
          '${_csvEscape(t.title)},$projectName,${t.priorityLabel},${t.estimatedPomodoros},${t.completedPomodoros},${t.isDone},$desc');
    }
    Share.share(csv.toString(), subject: 'Pomodoro Data Export');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data exported!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  String _csvEscape(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  void _confirmReset() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Reset All Data'),
        content: const Text(
            'This will delete all your sessions and projects. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              context.read<TimerService>().reset();
              context.read<TimerService>().setProject(null);
              DatabaseService.deleteAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All data has been reset'),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
