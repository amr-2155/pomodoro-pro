import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/data_backup_service.dart';
import '../services/pwa_service.dart';
import '../services/timer_service.dart';
import '../services/completion_sound.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../widgets/goal_cards.dart';
import 'quote_library_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.settings,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle(l10n.timerSettings),
            _buildTimeTile(l10n.focusDuration, DatabaseService.focusDuration, 'focusDuration'),
            _buildTimeTile(l10n.shortBreakDuration, DatabaseService.shortBreakDuration, 'shortBreakDuration'),
            _buildTimeTile(l10n.longBreakDuration, DatabaseService.longBreakDuration, 'longBreakDuration'),
            _buildSwitchTile(
              l10n.autoStartBreaks,
              l10n.autoStartBreaksDesc,
              DatabaseService.autoStartBreaks,
              'autoStartBreaks',
            ),
            _buildSwitchTile(
              l10n.autoStartFocus,
              l10n.autoStartFocusDesc,
              DatabaseService.autoStartPomodoros,
              'autoStartPomodoros',
            ),
            _buildDurationTile(
              l10n.sessionsBeforeLongBreak,
              DatabaseService.longBreakInterval,
              'longBreakInterval',
              min: 2,
              max: 8,
            ),

            const SizedBox(height: 12),
            _buildSectionTitle(l10n.goalsSettings),
            const DailyGoalCard(),
            const WeeklyGoalCard(),

            const SizedBox(height: 12),
            _buildSectionTitle(l10n.soundSettings),
            _buildCompletionSoundCard(l10n),
            _buildCountdownSoundCard(l10n),
            _buildSwitchTile(
              l10n.vibrateOnComplete,
              l10n.vibrateOnCompleteDesc,
              DatabaseService.completionVibrationEnabled,
              'completionVibrationEnabled',
            ),

            const SizedBox(height: 12),
            _buildSectionTitle(l10n.appearanceSettings),
            _buildSwitchTile(
              l10n.darkMode,
              l10n.darkModeDesc,
              DatabaseService.darkMode,
              'darkMode',
            ),

            const SizedBox(height: 12),
            _buildSectionTitle(l10n.languageSettings),
            _buildLanguageTile(l10n),
            _buildActionTile(
              l10n.quoteLibrary,
              l10n.quoteOfDay,
              Icons.format_quote_rounded,
              () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const QuoteLibraryScreen()),
              ),
            ),

            const SizedBox(height: 12),
            _buildSectionTitle(l10n.dataSettings),
            _buildActionTile(l10n.createBackup, l10n.createBackupDesc, Icons.cloud_download_rounded, () => _createBackup(context)),
            _buildActionTile(l10n.restoreBackup, l10n.restoreBackupDesc, Icons.cloud_upload_rounded, () => _restoreBackup(context)),
            _buildActionTile(l10n.exportCsv, l10n.exportCsvDesc, Icons.table_chart_rounded, () => _exportData(context)),
            _buildActionTile(l10n.resetAllData, l10n.resetAllDataDesc, Icons.delete_forever_rounded, () => _confirmReset(context), isDestructive: true),

            const SizedBox(height: 12),
            _buildSectionTitle(l10n.aboutSettings),
            if (!PwaService.isStandalone)
              _buildActionTile(l10n.installApp, l10n.installAppDesc, Icons.install_mobile_rounded, () => _installPwa(context)),
            _buildActionTile(l10n.appVersion, l10n.builtWith, Icons.info_outline_rounded, () {}),

            const SizedBox(height: 40),
            Center(
              child: Text(
                l10n.appVersion,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
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

  Widget _buildTimeTile(String title, int valueSeconds, String settingKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minutes = valueSeconds ~/ 60;
    final seconds = valueSeconds % 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          _buildValueButton(
            icon: Icons.remove_rounded,
            onPressed: valueSeconds > 60
                ? () {
                    final newValue = valueSeconds - 300 < 60 ? 60 : valueSeconds - 300;
                    DatabaseService.setSetting(settingKey, newValue);
                    setState(() {});
                  }
                : null,
          ),
          GestureDetector(
            onTap: () => _showDurationPicker(title, valueSeconds, settingKey),
            child: Container(
              width: 65,
              alignment: Alignment.center,
              child: Text(
                seconds > 0 ? '$minutes:${seconds.toString().padLeft(2, '0')}' : '$minutes',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          _buildValueButton(
            icon: Icons.add_rounded,
            onPressed: () {
              final newValue = valueSeconds + 300;
              DatabaseService.setSetting(settingKey, newValue);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void _showDurationPicker(String title, int currentSeconds, String settingKey) {
    final l10n = AppLocalizations.of(context);
    final currentMinutes = currentSeconds ~/ 60;
    final controller = TextEditingController(text: '$currentMinutes');
    final presets = [15, 25, 45, 60, 90];

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(border: InputBorder.none),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(l10n.minutes, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: presets.map((m) {
                    final isSelected = m == currentMinutes;
                    return GestureDetector(
                      onTap: () {
                        controller.text = '$m';
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          '$m ${l10n.minutes}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final val = int.tryParse(controller.text);
                      if (val != null && val >= 1 && val <= 999) {
                        DatabaseService.setSetting(settingKey, val * 60);
                        Navigator.pop(ctx);
                        setState(() {});
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(l10n.save, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationTile(String title, int value, String settingKey, {int min = 1, int max = 90}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
          _buildValueButton(
            icon: Icons.remove_rounded,
            onPressed: value > min ? () {
              DatabaseService.setSetting(settingKey, value - 1);
              setState(() {});
            } : null,
          ),
          Container(
            width: 52,
            alignment: Alignment.center,
            child: Text(
              '$value',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          _buildValueButton(
            icon: Icons.add_rounded,
            onPressed: value < max ? () {
              DatabaseService.setSetting(settingKey, value + 1);
              setState(() {});
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildValueButton({required IconData icon, required VoidCallback? onPressed}) {
    return SizedBox(
      width: 36, height: 36,
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

  Widget _buildSwitchTile(String title, String subtitle, bool value, String settingKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: _cardDecoration(isDark),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        value: value,
        onChanged: (v) {
          DatabaseService.setSetting(settingKey, v);
          if (settingKey == 'darkMode') {
            DatabaseService.darkModeNotifier.value = v;
          }
          setState(() {});
        },
        activeThumbColor: AppColors.primary,
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }

  Widget _buildLanguageTile(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLang = DatabaseService.localeNotifier.value.languageCode;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: _cardDecoration(isDark),
      child: Row(
        children: [
          const Icon(Icons.language, size: 20, color: AppColors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(l10n.languageSettings, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          ),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
              ButtonSegment(value: 'en', label: Text(l10n.english)),
            ],
            selected: {currentLang},
            onSelectionChanged: (v) {
              final lang = v.first;
              DatabaseService.setSetting('language', lang);
              DatabaseService.localeNotifier.value = Locale(lang);
              setState(() {});
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

  Widget _buildCompletionSoundCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final current = completionSoundFromKey(DatabaseService.completionSoundType);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(isDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCompletionSoundPicker(l10n),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🔔', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.completionSoundTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(current.nameAr, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCompletionSoundPicker(AppLocalizations l10n) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SoundPickerSheet(
        title: l10n.completionSoundTitle,
        subtitle: l10n.completionSoundDesc,
        items: CompletionSoundType.values.map((t) => _SoundItem(t.icon, t.nameAr, t)).toList(),
        selectedIndex: CompletionSoundType.values.indexOf(completionSoundFromKey(DatabaseService.completionSoundType)),
        onPreview: (type) {
          AudioService.stopPreview();
          AudioService.playPreviewTracked(type as CompletionSoundType);
        },
        onStopPreview: () => AudioService.stopPreview(),
      ),
    );
    AudioService.stopPreview();
    if (result != null) {
      final type = result['selected'] as CompletionSoundType;
      DatabaseService.setSetting('completionSoundType', type.key);
      setState(() {});
    }
  }

  Widget _buildCountdownSoundCard(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final countdownEnabled = DatabaseService.countdownSoundEnabled;
    final current = countdownSoundFromKey(DatabaseService.countdownSoundType);
    final seconds = DatabaseService.countdownSeconds;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(isDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showCountdownSoundPicker(l10n),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('⏱️', style: TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.countdownSoundTitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      Text(
                        '${current.nameAr} — ${l10n.lastSeconds} $seconds ${l10n.secondsLabel}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: countdownEnabled,
                  onChanged: (v) {
                    DatabaseService.setSetting('countdownSoundEnabled', v);
                    setState(() {});
                  },
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCountdownSoundPicker(AppLocalizations l10n) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountdownPickerSheet(
        selectedType: countdownSoundFromKey(DatabaseService.countdownSoundType),
        selectedSeconds: DatabaseService.countdownSeconds,
        l10n: l10n,
      ),
    );
    AudioService.stopPreview();
    if (result != null) {
      DatabaseService.setSetting('countdownSoundType', (result['selected'] as CountdownSoundType).key);
      DatabaseService.setSetting('countdownSeconds', result['seconds'] as int);
      setState(() {});
    }
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: _cardDecoration(isDark),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDestructive ? AppColors.error : AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: isDestructive ? AppColors.error : AppColors.primary, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDestructive ? AppColors.error : null,
                      )),
                      Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  void _createBackup(BuildContext context) {
    DataBackupService.downloadBackup(context, DatabaseService.createBackup());
  }

  void _restoreBackup(BuildContext context) {
    DataBackupService.pickAndRestore(context);
  }

  void _installPwa(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Use your browser menu > "Add to Home screen"'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _exportData(BuildContext context) {
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
      csv.writeln('${s.date.toIso8601String()},$projectName,${s.actualMinutes ?? s.durationMinutes},${s.completed},${s.sessionType},$rating,$notes');
    }
    csv.writeln('');
    csv.writeln('=== TASKS ===');
    csv.writeln('Title,Project,Priority,Estimated,Completed,Done,Description');
    for (final t in tasks) {
      final project = t.projectId != null ? DatabaseService.getProject(t.projectId!) : null;
      final projectName = _csvEscape(project?.name ?? t.projectId ?? '');
      final desc = _csvEscape(t.description ?? '');
      csv.writeln('${_csvEscape(t.title)},$projectName,${t.priorityLabel},${t.estimatedPomodoros},${t.completedPomodoros},${t.isDone},$desc');
    }
    Share.share(csv.toString(), subject: 'Pomodoro Data Export');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data exported!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _csvEscape(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  void _confirmReset(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.resetConfirmTitle),
        content: Text(l10n.resetConfirmDesc),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () {
              final timerService = context.read<TimerService>();
              timerService.reset();
              timerService.resetSessionCount();
              timerService.setProject(null);
              DatabaseService.deleteAllData();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.dataReset), backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.resetBtn),
          ),
        ],
      ),
    );
  }
}

// ─── Sound Picker Sheet ───

class _SoundItem {
  final String icon;
  final String name;
  final dynamic type;
  _SoundItem(this.icon, this.name, this.type);
}

class _SoundPickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<_SoundItem> items;
  final int selectedIndex;
  final ValueChanged<dynamic> onPreview;
  final VoidCallback onStopPreview;

  const _SoundPickerSheet({
    required this.title, required this.subtitle, required this.items,
    required this.selectedIndex, required this.onPreview, required this.onStopPreview,
  });

  @override
  State<_SoundPickerSheet> createState() => _SoundPickerSheetState();
}

class _SoundPickerSheetState extends State<_SoundPickerSheet> {
  bool _isPlaying = false;
  int _playingIndex = -1;

  void _toggle(int index) {
    setState(() {
      if (_isPlaying && _playingIndex == index) {
        _isPlaying = false;
        _playingIndex = -1;
        widget.onStopPreview();
      } else {
        _isPlaying = true;
        _playingIndex = index;
        widget.onPreview(widget.items[index].type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(widget.subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ])),
            ]),
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final isSelected = index == widget.selectedIndex;
                final isPlaying = _isPlaying && _playingIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Text(item.icon, style: const TextStyle(fontSize: 22)),
                    title: Text(item.name, style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    )),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        onTap: () => _toggle(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: isPlaying ? AppColors.error : AppColors.primary, size: 20,
                          ),
                        ),
                      ),
                      if (isSelected) ...[const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)],
                    ]),
                    onTap: () {
                      widget.onStopPreview();
                      Navigator.pop(context, {'selected': item.type});
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Countdown Picker Sheet ───

class _CountdownPickerSheet extends StatefulWidget {
  final CountdownSoundType selectedType;
  final int selectedSeconds;
  final AppLocalizations l10n;

  const _CountdownPickerSheet({
    required this.selectedType, required this.selectedSeconds, required this.l10n,
  });

  @override
  State<_CountdownPickerSheet> createState() => _CountdownPickerSheetState();
}

class _CountdownPickerSheetState extends State<_CountdownPickerSheet> {
  bool _isPlaying = false;
  CountdownSoundType? _playingType;
  late CountdownSoundType _selectedType;
  late int _selectedSeconds;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.selectedType;
    _selectedSeconds = widget.selectedSeconds;
  }

  void _toggle(CountdownSoundType type) {
    setState(() {
      if (_isPlaying && _playingType == type) {
        _isPlaying = false;
        _playingType = null;
        AudioService.stopPreview();
      } else {
        _isPlaying = true;
        _playingType = type;
        AudioService.playCountdownPreviewTracked(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Align(alignment: Alignment.centerRight,
              child: Text(l10n.countdownSoundTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(children: [
              Text('${l10n.lastSeconds} ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ...[5, 10, 15].map((s) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text('$s', style: TextStyle(fontSize: 12, color: s == _selectedSeconds ? Colors.white : AppColors.primary)),
                  selected: s == _selectedSeconds,
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _selectedSeconds = s),
                  visualDensity: VisualDensity.compact,
                ),
              )),
              Text(' ${l10n.secondsLabel}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            ]),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: CountdownSoundType.values.length,
              itemBuilder: (context, index) {
                final type = CountdownSoundType.values[index];
                final isSelected = type == _selectedType;
                final isPlaying = _isPlaying && _playingType == type;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: Text(type.icon, style: const TextStyle(fontSize: 22)),
                    title: Text(type.nameAr, style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? AppColors.primary : null,
                    )),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        onTap: () => _toggle(type),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? AppColors.error.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                            color: isPlaying ? AppColors.error : AppColors.primary, size: 20,
                          ),
                        ),
                      ),
                      if (isSelected) ...[const SizedBox(width: 6),
                        Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18)],
                    ]),
                    onTap: () => setState(() => _selectedType = type),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  AudioService.stopPreview();
                  Navigator.pop(context, {'selected': _selectedType, 'seconds': _selectedSeconds});
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.save, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
