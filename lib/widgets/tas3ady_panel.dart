import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/tasbeeh_service.dart';
import '../utils/constants.dart';
import '../utils/dhikr_calculator.dart';
import '../utils/input_formatters.dart';

// ─────────────────────────────────────────────────────────────
// بخش «كيف تستفيد من تصاعدي؟» — نصائح عملية تدور كل 60 ثانية
// مكان الاقتباسات القديمة في وضع تصاعدي فقط. بدون خلل في حالة
// المؤقت أو باقي الصفحات.
// ─────────────────────────────────────────────────────────────
class Tas3adyTipsRotator extends StatefulWidget {
  final bool isDark;

  const Tas3adyTipsRotator({super.key, required this.isDark});

  static const rotationInterval = Duration(seconds: 60);

  @override
  State<Tas3adyTipsRotator> createState() => _Tas3adyTipsRotatorState();
}

class _Tas3adyTipsRotatorState extends State<Tas3adyTipsRotator> {
  int _index = 0;
  Timer? _timer;

  static const List<String> _tips = [
    'استخدم «تصاعدي» لقياس وردك الحقيقي: شغّله ثم اذكر ذِكرك كالمعتاد، وانظر كم استغرق فعليًا قبل أن تتحرر يدك وتضخم الرقم.',
    'ثبّت سرعتك الفعلية: عدّ 33 مرة بالسرعة الطبيعية، اقسم المدة على 33، وستحصل على ثوانٍ لكل تكرار — هذه هي سرعتك الحقيقية.',
    'وِرد الصباح: اختر استغفارًا (500 مثلًا) وقِس بالمؤقت كم يأخذ في الصباح، ثم رتّب وردك بالطول الأنسب لوقتك الحقيقي.',
    'الاستمرارية تُقاس بالوقت قبل الكم: النبي ﷺ «كان إذا عمل عملًا أثبته» — التزم بورد صغير كل يوم لا بوَرد كبير ينقطع.',
    'قاعدة الـ5 دقائق: اضرب سرعتك لكل تكرار في 300 ثانية (5 دقائق) لتعرف عدد التكرارات التي تناسبك في أي دقيقة فاضية.',
    'راكم أرقامك: شغّل التصاعدي كل يوم بنفس الذكر، ولاحظ هل سرعتك ثابتة أم زادت — الرقم حاسم، لا الانطباع.',
    'الوِرد التصاعدي: ابدأ بوَرد يضمن الاستمرارية، وأضف عليه 10% كل أسبوع فقط — الزيادة الصغيرة تتراكم.',
    'إذا انشغل قلبك أثناء الذكر، أكمل من حيث وصلت ولا تبدأ من الصفر؛ التصاعدي لن يحاسبك، لكنه يقيس الزمن بصدق.',
    'خصص وردك في وقت لا تُنازَع فيه: بعد الصلاة، أو في الانتظار، أو على الطريق — دع التصاعدي يشهد على البركة.',
    'استغل وقت الانتظار: في طابور أو مواصلات؟ شغّل التصاعدي واجعل الدقائق الضائعة أورادًا محسوبة.',
    'بعد كل جلسة اقرأ الدقائق الحقيقية، واجعل هدفك الأسبوعي مبنيًا على أرقامك أنت لا على افتراضات عامة.',
    'اجعل لكل تصاعدي نية صادقة (ذكرًا أو علمًا أو عملًا)، ثم لاحظ البركة في الوقت نفسه الذي كنت تهدره.',
    'الأوراد متشابهة اللفظ مختلفة الوزن: «سبحان الله وبحمده» خفيفة، لكن تكرارها 100 مرة يورث حضورًا يمتد لوجهك.',
    'جرّب التحدي: 1000 مرة براحة تامة — قسها الأسبوع الأول ثم قارن بنفسك ولا تقارن بغيرك.',
    'حاسة السرعة تخدعك: الذكر الهادئ يبدو سريعًا، لكن الرقم يكشف الحقيقة — اجعل القياس وسيلة لا غاية.',
    'لا تحوّل التصاعدي إلى سباق ضد الوقت؛ اجعله أداة لتثبيت الخشوع، فالزيادة في الحضور أولى من الزيادة في العدد.',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Tas3adyTipsRotator.rotationInterval, (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _tips.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tips[_index];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: widget.isDark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'كيف تستفيد من تصاعدي؟',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Text(
                'فكرة جديدة كل دقيقة',
                style: TextStyle(
                  fontSize: 11,
                  color: widget.isDark ? Colors.grey[500] : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final isIn = child.key == ValueKey(_index);
              final slide = Tween<Offset>(
                begin: isIn ? const Offset(0, 0.2) : const Offset(0, -0.2),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: slide, child: child),
              );
            },
            child: Text(
              tip,
              key: ValueKey(_index),
              textAlign: TextAlign.start,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: widget.isDark ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// حاسبة الذكر + قياس السرعة الفعلية — داخل صفحة تصاعدي.
// الوضع أ: كم يستغرق هذا الذكر؟  |  الوضع ب: أقدر أذكر كام مرة؟
// كل الحسابات محلية فورية بدون اعتماد على أي خدمة خارجية.
// ─────────────────────────────────────────────────────────────
class Tas3adyDhikrCalculator extends StatefulWidget {
  final bool isDark;

  const Tas3adyDhikrCalculator({super.key, required this.isDark});

  @override
  State<Tas3adyDhikrCalculator> createState() => _Tas3adyDhikrCalculatorState();
}

class _Tas3adyDhikrCalculatorState extends State<Tas3adyDhikrCalculator> {
  static const _repsPresets = [33, 100, 300, 500, 1000];
  static const _measurePresets = [10, 33, 50, 100];

  bool _expanded = true;
  int _mode = 0;
  int _dhikrIndex = 0;
  int? _repsPreset = 100;
  int _measureReps = 10;

  final _customDhikrCtrl = TextEditingController();
  final _customRepsCtrl = TextEditingController();
  final _customMeasureRepsCtrl = TextEditingController();
  final _speedCtrl = TextEditingController(text: '3');
  final _minutesCtrl = TextEditingController();

  bool _measuring = false;
  Stopwatch? _measureWatch;
  Timer? _measureTicker;
  Duration _measureElapsed = Duration.zero;
  double _measuredAvg = 0;
  bool _hasMeasurement = false;

  bool get _isCustomDhikr => _dhikrIndex >= TasbeehService.dhikrOptions.length;

  @override
  void dispose() {
    _measureTicker?.cancel();
    _customDhikrCtrl.dispose();
    _customRepsCtrl.dispose();
    _customMeasureRepsCtrl.dispose();
    _speedCtrl.dispose();
    _minutesCtrl.dispose();
    super.dispose();
  }

  double? _parsePositiveDouble(String raw) => parseLocalizedDouble(raw);

  int get _resolvedReps {
    final custom = _customRepsCtrl.text.trim();
    if (custom.isNotEmpty) {
      final n = parseLocalizedInt(custom);
      if (n != null && n > 0) return n;
    }
    return _repsPreset ?? 0;
  }

  int get _resolvedMeasureReps {
    final custom = _customMeasureRepsCtrl.text.trim();
    if (custom.isNotEmpty) {
      final n = parseLocalizedInt(custom);
      if (n != null && n > 0) return n;
    }
    return _measureReps;
  }

  double? get _speed {
    final v = _parsePositiveDouble(_speedCtrl.text);
    if (v == null || v <= 0) return null;
    return v;
  }

  double? get _minutes {
    final v = _parsePositiveDouble(_minutesCtrl.text);
    if (v == null || v <= 0) return null;
    return v;
  }

  void _onChanged() => setState(() {});

  void _startMeasurement() {
    _measureWatch = Stopwatch()..start();
    _measureElapsed = Duration.zero;
    _measuring = true;
    _hasMeasurement = false;
    _measureTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || !_measuring) return;
      setState(() => _measureElapsed = _measureWatch?.elapsed ?? Duration.zero);
    });
    HapticFeedback.lightImpact();
    setState(() {});
  }

  void _stopMeasurement() {
    _measureTicker?.cancel();
    _measureWatch?.stop();
    final elapsed = _measureWatch?.elapsed ?? Duration.zero;
    _measureElapsed = elapsed;
    final seconds = elapsed.inMilliseconds / 1000.0;
    _measuredAvg = DhikrCalculator.measureAverage(
      measuredRepetitions: _resolvedMeasureReps,
      totalSeconds: seconds,
    );
    _hasMeasurement = true;
    _measuring = false;
    HapticFeedback.mediumImpact();
    setState(() {});
  }

  void _applySpeed() {
    if (_measuredAvg <= 0) return;
    _speedCtrl.text = _measuredAvg == _measuredAvg.roundToDouble()
        ? _measuredAvg.toStringAsFixed(0)
        : _measuredAvg.toStringAsFixed(2);
    HapticFeedback.lightImpact();
    setState(() {});
  }

  String _formatElapsed() {
    final s = _measureElapsed.inSeconds;
    final ms = _measureElapsed.inMilliseconds % 1000;
    return '${_measureElapsed.inMinutes.toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}.'
        '${(ms ~/ 100)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.grey[300] : Colors.grey[800];
    final muted = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2E4F) : const Color(0xFFE4E7EF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded,
                      size: 20, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حاسبة الذكر والوقت',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'قدّر مدة وردك أو عدد مراته حسب سرعتك',
                          style: TextStyle(fontSize: 11.5, color: muted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: muted,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModeToggle(textColor, muted),
                  const SizedBox(height: 14),
                  _buildDhikrField(textColor, muted),
                  const SizedBox(height: 12),
                  if (_mode == 0) _buildRepsField(textColor, muted),
                  if (_mode == 1) _buildMinutesField(textColor, muted),
                  const SizedBox(height: 12),
                  _buildSpeedField(textColor, muted),
                  const SizedBox(height: 14),
                  _buildResultBox(textColor, muted),
                  const SizedBox(height: 8),
                  _buildExampleLine(muted),
                  const SizedBox(height: 16),
                  _buildDivider(),
                  const SizedBox(height: 12),
                  _buildMeasurementSection(textColor, muted),
                  const SizedBox(height: 10),
                  _buildDisclaimer(muted),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: widget.isDark ? const Color(0xFF2A2E4F) : const Color(0xFFE4E7EF),
    );
  }

  Widget _buildModeToggle(Color? textColor, Color? muted) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: widget.isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF0F1F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _modeChip(0, 'كم يستغرق؟', textColor, muted),
          ),
          const SizedBox(width: 3),
          Expanded(
            child: _modeChip(1, 'أقدر أذكر كام مرة؟', textColor, muted),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(int value, String label, Color? textColor, Color? muted) {
    final active = _mode == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _mode = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: widget.isDark ? 0.9 : 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : muted,
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text, Color? textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(Color? muted, {String? hint}) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      filled: true,
      fillColor: widget.isDark
          ? Colors.white.withValues(alpha: 0.05)
          : const Color(0xFFF7F8FB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color:
              widget.isDark ? const Color(0xFF2A2E4F) : const Color(0xFFE4E7EF),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }

  Widget _buildDhikrField(Color? textColor, Color? muted) {
    final options = [
      for (final d in TasbeehService.dhikrOptions) d.$1,
      'ذكر مخصص',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('الذكر', textColor),
        DropdownButtonFormField<int>(
          initialValue: _dhikrIndex,
          dropdownColor: widget.isDark ? AppColors.surfaceDark : Colors.white,
          iconEnabledColor: AppColors.primary,
          style: TextStyle(
            fontSize: 13.5,
            color: textColor,
          ),
          decoration: _inputDecoration(muted),
          items: [
            for (var i = 0; i < options.length; i++)
              DropdownMenuItem(value: i, child: Text(options[i])),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() => _dhikrIndex = v);
          },
        ),
        if (_isCustomDhikr) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _customDhikrCtrl,
            style: TextStyle(fontSize: 13.5, color: textColor),
            onChanged: (_) => _onChanged(),
            decoration:
                _inputDecoration(muted, hint: 'اكتب الذكر الذي تريد قياسه...'),
          ),
        ],
      ],
    );
  }

  Widget _buildRepsField(Color? textColor, Color? muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('عدد التكرارات', textColor),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in _repsPresets)
              _presetChip(
                  p, p == _repsPreset && _customRepsCtrl.text.trim().isEmpty),
            SizedBox(
              width: 92,
              child: TextField(
                controller: _customRepsCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [AppInputFormatters.digitsOnlyLocalized],
                onChanged: (_) => _onChanged(),
                style: TextStyle(fontSize: 13.5, color: textColor),
                decoration: _inputDecoration(muted, hint: 'مخصص'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _presetChip(int value, bool active) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          _repsPreset = value;
          _customRepsCtrl.clear();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary.withValues(alpha: widget.isDark ? 0.9 : 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary
                : widget.isDark
                    ? const Color(0xFF2A2E4F)
                    : const Color(0xFFE4E7EF),
          ),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: active
                ? Colors.white
                : widget.isDark
                    ? Colors.grey[400]
                    : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildMinutesField(Color? textColor, Color? muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('المدة المتاحة (بالدقائق)', textColor),
        TextField(
          controller: _minutesCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TextInputFormatter.withFunction((old, newValue) {
              final t = normalizeDigits(newValue.text).replaceAll(',', '.');
              if (t.isEmpty) return newValue;
              return double.tryParse(t) != null ? newValue : old;
            }),
          ],
          onChanged: (_) => _onChanged(),
          style: TextStyle(fontSize: 13.5, color: textColor),
          decoration: _inputDecoration(muted, hint: 'مثال: 10'),
        ),
      ],
    );
  }

  Widget _buildSpeedField(Color? textColor, Color? muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'السرعة (ثانية لكل تكرار)',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            InkWell(
              onTap: _hasMeasurement ? null : () => _speedCtrl.text = '3',
              child: Text(
                'الافتراضية: 3',
                style: TextStyle(
                  fontSize: 11,
                  color: _hasMeasurement ? muted : AppColors.info,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _speedCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TextInputFormatter.withFunction((old, newValue) {
              final t = normalizeDigits(newValue.text).replaceAll(',', '.');
              if (t.isEmpty) return newValue;
              if (t == '0') return old;
              return double.tryParse(t) != null ? newValue : old;
            }),
          ],
          onChanged: (_) => _onChanged(),
          style: TextStyle(fontSize: 13.5, color: textColor),
          decoration: _inputDecoration(muted, hint: 'مثال: 2.5'),
        ),
        const SizedBox(height: 6),
        Text(
          'يمكنك الكتابة بالكسور مثل 2.5 أو 2,5',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    );
  }

  Widget _buildResultBox(Color? textColor, Color? muted) {
    final speed = _speed;
    final String title;
    final String value;
    final bool valid;

    if (_mode == 0) {
      final reps = _resolvedReps;
      valid = reps > 0 && speed != null;
      if (valid) {
        final total = DhikrCalculator.estimateSeconds(
          repetitions: reps,
          secondsPerRep: speed,
        );
        title = 'سيأخذ هذا الوِرد تقريبًا';
        value = DhikrCalculator.formatDuration(total);
      } else {
        title = 'النتيجة';
        value = 'أدخل عدد التكرارات وسرعتك أولًا';
      }
    } else {
      final minutes = _minutes;
      valid = minutes != null && speed != null;
      if (valid) {
        final reps = DhikrCalculator.estimateRepetitions(
          availableSeconds: minutes * 60,
          secondsPerRep: speed,
        );
        title = 'أقدر أذكر تقريبًا';
        value = '$reps مرة';
      } else {
        title = 'النتيجة';
        value = 'أدخل المدة وسرعتك أولًا';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: widget.isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valid ? AppColors.success : muted,
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildExampleLine(Color? muted) {
    final speed = _speed;
    final List<String> items = [];

    if (_mode == 0 && speed != null) {
      final reps = _resolvedReps;
      if (reps > 0) {
        for (final d in [2, 3, 4]) {
          if (reps >= 200 && reps % d == 0) {
            final per = DhikrCalculator.estimateSeconds(
              repetitions: reps ~/ d,
              secondsPerRep: speed,
            );
            items.add('يمكن تقسيمها إلى $d دفعات × ${reps ~/ d} — '
                '${DhikrCalculator.formatDuration(per)} لكل دفعة');
            break;
          }
        }
        if (items.isEmpty && reps < 1000) {
          items.add(
              'جرّب أرقامًا أكبر: 1000 مرة — ${DhikrCalculator.formatDuration(DhikrCalculator.estimateSeconds(repetitions: 1000, secondsPerRep: speed))}');
        }
      }
    } else if (_mode == 1 && speed != null) {
      final minutes = _minutes;
      if (minutes != null) {
        final reps = DhikrCalculator.estimateRepetitions(
          availableSeconds: minutes * 60,
          secondsPerRep: speed,
        );
        if (reps > 0) {
          final d = (minutes / 3).clamp(1, 200).floor();
          items.add(
              'لو قسمت المدة على 3 دفعات: ${_fmtNumber(reps / 3)} مرة لكل دفعة تقريبًا');
          if (d > 1) {
            items.add(
                'لو قسمتها على $d دفعات: ${_fmtNumber(reps / d)} مرة تقريبًا');
          }
        }
      }
    }

    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(t, style: TextStyle(fontSize: 11.5, color: muted)),
          ),
      ],
    );
  }

  Widget _buildMeasurementSection(Color? textColor, Color? muted) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.speed_rounded, size: 17, color: AppColors.info),
            const SizedBox(width: 8),
            Text(
              'قياس سرعتك الفعلية',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final p in _measurePresets)
              _presetChipModel(
                  p,
                  p == _measureReps &&
                      _customMeasureRepsCtrl.text.trim().isEmpty, () {
                if (_measuring) return;
                setState(() {
                  _measureReps = p;
                  _customMeasureRepsCtrl.clear();
                });
              }, muted),
            SizedBox(
              width: 110,
              child: TextField(
                controller: _customMeasureRepsCtrl,
                enabled: !_measuring,
                keyboardType: TextInputType.number,
                inputFormatters: [AppInputFormatters.digitsOnlyLocalized],
                onChanged: (_) => _onChanged(),
                style: TextStyle(fontSize: 12.5, color: textColor),
                decoration: _inputDecoration(muted, hint: 'عدد مخصص'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _measuring ? _stopMeasurement : _startMeasurement,
                icon: Icon(
                  _measuring ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 18,
                  color: _measuring ? AppColors.error : AppColors.success,
                ),
                label: Text(
                  _measuring
                      ? 'إيقاف القياس'
                      : 'ابدأ القياس (عد $_resolvedMeasureReps مرة)',
                  style: TextStyle(
                      color: _measuring ? AppColors.error : AppColors.success),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      _measuring ? AppColors.error : AppColors.success,
                  side: BorderSide(
                    color: _measuring ? AppColors.error : AppColors.success,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
        if (_measuring ||
            _hasMeasurement ||
            _measureElapsed > Duration.zero) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF0F1F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatElapsed(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    color: _measuring ? AppColors.info : textColor,
                  ),
                ),
              ),
              if (_hasMeasurement) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$_resolvedMeasureReps تكرارات في '
                    '${DhikrCalculator.formatDuration(_measureElapsed.inMilliseconds / 1000.0)}'
                    ' = ${_fmtNumber(_measuredAvg)} ثانية/تكرار',
                    style: TextStyle(fontSize: 12, color: textColor),
                  ),
                ),
              ],
            ],
          ),
          if (_hasMeasurement) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _applySpeed,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('تطبيق هذه السرعة'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.info,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _hasMeasurement = false;
                      _measuredAvg = 0;
                      _measureElapsed = Duration.zero;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: muted,
                    side: BorderSide(color: muted!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                  ),
                  child: const Text('قياس جديد'),
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _presetChipModel(
      int value, bool active, VoidCallback onTap, Color? muted) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.info.withValues(alpha: widget.isDark ? 0.9 : 1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.info
                : widget.isDark
                    ? const Color(0xFF2A2E4F)
                    : const Color(0xFFE4E7EF),
          ),
        ),
        child: Text(
          '$value',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : muted,
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimer(Color? muted) {
    return Text(
      'هذه أرقام تقديرية تعتمد على سرعتك الشخصية — وليست وِردًا شرعيًا ولا حدًا للذكر. '
      'قدّر لنفسك ما يناسب قلبك ووقتك.',
      style: TextStyle(fontSize: 11, color: muted, height: 1.5),
    );
  }

  String _fmtNumber(double v) {
    if (!v.isFinite) return '—';
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}
