import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/database_service.dart';
import '../services/goals_service.dart';
import '../utils/constants.dart';
import '../utils/number_formatter.dart';

const int _kMinGoal = 1;
const int _kMaxGoal = 100000;

/// ─────────────────────────────────────────────────────────────
/// Daily Goal card — purple identity, big tappable number.
/// ─────────────────────────────────────────────────────────────
class DailyGoalCard extends StatelessWidget {
  const DailyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsService>();
    return _GoalCard(
      accent: AppColors.primary,
      title: AppLocalizations.of(context).dailyGoalTitle,
      subtitle: AppLocalizations.of(context).targetFocusTime,
      value: goals.dailyGoalMinutes,
      icon: Icons.flag_rounded,
      presets: const [15, 30, 45, 60, 90, 120, 180, 300],
      sheetTitle: (l10n) => l10n.editDailyGoal,
      onPersist: (m) async {
        await goals.setDailyGoal(m);
      },
    );
  }
}

/// ─────────────────────────────────────────────────────────────
/// Weekly Goal card — green identity, progress + avg/day hint.
/// ─────────────────────────────────────────────────────────────
class WeeklyGoalCard extends StatelessWidget {
  const WeeklyGoalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<GoalsService>();
    final weekly = goals.weeklyGoalMinutes;
    final completed = goals.completedWeek;
    final l10n = AppLocalizations.of(context);

    return _GoalCard(
      accent: AppColors.success,
      title: AppLocalizations.of(context).weeklyGoal,
      subtitle: AppLocalizations.of(context).targetFocusTime,
      value: weekly,
      icon: Icons.date_range_rounded,
      presets: const [300, 600, 900, 1200, 1500, 1800, 2400, 3000],
      sheetTitle: (l10n) => l10n.editWeeklyGoal,
      showSmartDurationPill: true,
      onPersist: (m) => goals.setWeeklyGoal(m),
      extraBelow: (weekly > 0)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${formatMinutesCompact(completed)} / ${toArabicNumerals('$weekly')} ${_unitShort(l10n)}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      toArabicNumerals('${(goals.weekProgress * 100).round()}%'),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: goals.weekProgress),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => LinearProgressIndicator(
                      value: v.clamp(0.0, 1.0),
                      minHeight: 8,
                      backgroundColor:
                          AppColors.success.withValues(alpha: 0.12),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success),
                    ),
                  ),
                ),
                if (weekly >= 7) ...[
                  const SizedBox(height: 10),
                  Text(
                    l10n.perDayAvg.replaceAll('{n}',
                        toArabicNumerals((weekly ~/ 7).toString())),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            )
          : null,
    );
  }
}

String _unitShort(AppLocalizations l10n) =>
    DatabaseService.localeNotifier.value.languageCode == 'ar' ? 'دقيقة' : 'min';

// ═════════════════════════════════════════════════════════════
// Shared premium goal card.
// ═════════════════════════════════════════════════════════════
class _GoalCard extends StatefulWidget {
  final Color accent;
  final String title;
  final String subtitle;
  final int value;
  final IconData icon;
  final List<int> presets;
  final String Function(AppLocalizations) sheetTitle;
  final Future<void> Function(int minutes) onPersist;
  final bool showSmartDurationPill;
  final Widget? extraBelow;

  const _GoalCard({
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.presets,
    required this.sheetTitle,
    required this.onPersist,
    this.showSmartDurationPill = false,
    this.extraBelow,
  });

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  bool _inlineEditing = false;
  late TextEditingController _inlineCtrl;
  Timer? _repeatTimer;

  @override
  void initState() {
    super.initState();
    _inlineCtrl = TextEditingController(text: '${widget.value}');
  }

  @override
  void didUpdateWidget(_GoalCard old) {
    super.didUpdateWidget(old);
    if (!_inlineEditing && old.value != widget.value) {
      _inlineCtrl.text = '${widget.value}';
    }
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    _inlineCtrl.dispose();
    super.dispose();
  }

  bool get _isDesktop {
    if (kIsWeb) return MediaQuery.of(context).size.width >= 900;
    return !defaultTargetPlatform.toString().contains('android') &&
        !defaultTargetPlatform.toString().contains('iOS') &&
        MediaQuery.of(context).size.width >= 900;
  }

  void _bump(int delta) {
    final next = (widget.value + delta).clamp(_kMinGoal, _kMaxGoal);
    if (next != widget.value) {
      HapticFeedback.selectionClick();
      widget.onPersist(next);
    }
  }

  void _startRepeat(int delta) {
    _bump(delta);
    _repeatTimer?.cancel();
    _repeatTimer = Timer(const Duration(milliseconds: 450), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 110), (_) => _bump(delta));
    });
  }

  void _stopRepeat() => _repeatTimer?.cancel();

  Future<void> _openEditor() async {
    HapticFeedback.lightImpact();
    if (_isDesktop) {
      setState(() {
        _inlineEditing = true;
        _inlineCtrl.text = '${widget.value}';
      });
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GoalEditSheet(
        accent: widget.accent,
        title: widget.sheetTitle(AppLocalizations.of(context)),
        initialValue: widget.value,
        presets: widget.presets,
        onPersist: widget.onPersist,
      ),
    );
  }

  Future<void> _commitInline() async {
    final parsed = int.tryParse(_inlineCtrl.text.trim());
    if (parsed == null || parsed < _kMinGoal || parsed > _kMaxGoal) {
      HapticFeedback.heavyImpact();
      return; // keep editing state; invalid input not accepted
    }
    setState(() => _inlineEditing = false);
    await widget.onPersist(parsed);
  }

  void _cancelInline() => setState(() => _inlineEditing = false);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textLight)),
                    Text(widget.subtitle,
                        style:
                            TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Big number (hero element).
          Center(
            child: GestureDetector(
              onTap: _openEditor,
              child: AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.center,
                child: _inlineEditing ? _buildInlineInput(isDark) : _buildBigNumber(accent),
              ),
            ),
          ),

          // Optional smart duration pill under number.
          if (!widget.showSmartDurationPill) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                formatMinutesSmart(widget.value),
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  formatMinutesSmart(widget.value),
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: accent.withValues(alpha: 0.9)),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // −15 / +15 chips with long-press repeat.
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepChip(
                label: '\u221215',
                accent: accent,
                onTap: () => _bump(-15),
                onLongPressStart: () => _startRepeat(-15),
                onLongPressEnd: _stopRepeat,
              ),
              const SizedBox(width: 14),
              _StepChip(
                label: '+15',
                accent: accent,
                onTap: () => _bump(15),
                onLongPressStart: () => _startRepeat(15),
                onLongPressEnd: _stopRepeat,
              ),
            ],
          ),

          // Weekly progress block.
          if (widget.extraBelow != null) ...[
            const SizedBox(height: 16),
            widget.extraBelow!,
          ] else ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                l10n.changeToAnyValue,
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[400]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBigNumber(Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) {
              final isIn =
                  child.key == ValueKey(widget.value); // entering child
              final slide = Tween<Offset>(
                begin: isIn ? const Offset(0, 0.35) : const Offset(0, -0.35),
                end: Offset.zero,
              ).animate(anim);
              return FadeTransition(
                  opacity: anim,
                  child: SlideTransition(position: slide, child: child));
            },
            child: Text(
              toArabicNumerals('${widget.value}'),
              key: ValueKey(widget.value),
              style: TextStyle(
                fontSize: 54,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: accent,
                letterSpacing: -1,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _unitShort(AppLocalizations.of(context)),
            style: TextStyle(fontSize: 13.5, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineInput(bool isDark) {
    final accent = widget.accent;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _cancelInline,
        const SingleActivator(LogicalKeyboardKey.enter): _commitInline,
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 110,
            child: TextField(
              controller: _inlineCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: accent),
              decoration: InputDecoration(
                isDense: true,
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent.withValues(alpha: 0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: accent, width: 2),
                ),
              ),
              maxLength: 6,
              onSubmitted: (_) => _commitInline(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _commitInline,
            icon: Icon(Icons.check_circle_rounded, color: accent, size: 26),
            tooltip: 'Enter',
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// ± step chip with long-press auto repeat.
// ═════════════════════════════════════════════════════════════
class _StepChip extends StatelessWidget {
  final String label;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const _StepChip({
    required this.label,
    required this.accent,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onLongPressStart(),
      onLongPressEnd: (_) => onLongPressEnd(),
      onLongPressCancel: onLongPressEnd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// Bottom-sheet editor: quick presets + custom value + save ✓.
// ═════════════════════════════════════════════════════════════
class _GoalEditSheet extends StatefulWidget {
  final Color accent;
  final String title;
  final int initialValue;
  final List<int> presets;
  final Future<void> Function(int minutes) onPersist;

  const _GoalEditSheet({
    required this.accent,
    required this.title,
    required this.initialValue,
    required this.presets,
    required this.onPersist,
  });

  @override
  State<_GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<_GoalEditSheet> {
  late final TextEditingController _ctrl;
  int? _selected;
  String? _error;
  bool _saving = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.initialValue}');
    _selected = widget.initialValue;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  int? get _parsedValue {
    final raw = _ctrl.text.trim();
    if (raw.isEmpty) return null;
    final v = int.tryParse(raw);
    if (v == null || v < _kMinGoal || v > _kMaxGoal) return null;
    return v;
  }

  Future<void> _save() async {
    final v = _parsedValue;
    if (v == null) {
      setState(() => _error =
          AppLocalizations.of(context).invalidGoalValue);
      HapticFeedback.heavyImpact();
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await widget.onPersist(v);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = true;
        });
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.accent;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 22),
        child: SingleChildScrollView(
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
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textLight),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  _previewText(),
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
              ),
              const SizedBox(height: 16),

              // Custom input.
              TextField(
                controller: _ctrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                maxLength: 6,
                style: TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800, color: accent),
                decoration: InputDecoration(
                  hintText: l10n.enterMinutesHint,
                  hintStyle: TextStyle(fontSize: 15, color: Colors.grey[400]),
                  counterText: '',
                  suffixIcon: Padding(
                    padding: const EdgeInsets.only(right: 12, left: 4),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        _unitShort(l10n),
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                  suffixIconConstraints:
                      const BoxConstraints(minWidth: 0, minHeight: 0),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.grey.withValues(alpha: 0.05),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: accent.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: accent, width: 2),
                  ),
                ),
                onChanged: (t) => setState(() {
                  _selected = null;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 6),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.error)),
              ],
              const SizedBox(height: 16),

              // Quick presets.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(l10n.quickPicks,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500])),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.presets.map((p) {
                  final active = _selected == p;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selected = p;
                        _ctrl.text = '$p';
                        _error = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? accent
                            : accent.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: active
                              ? accent
                              : accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '${toArabicNumerals('$p')} ${_unitShort(l10n)}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : accent,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Save button with success morph.
              SizedBox(
                height: 50,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _saved
                      ? Container(
                          key: const ValueKey('ok'),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 22),
                              const SizedBox(width: 6),
                              Text(l10n.goalSaved,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          key: const ValueKey('save'),
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                              Colors.white)))
                              : Text(l10n.save,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _previewText() {
    final v = _parsedValue;
    if (v == null) return '';
    return formatMinutesSmart(v);
  }
}
