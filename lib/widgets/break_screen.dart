import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../utils/constants.dart';
import '../services/ambient_sound_service.dart';

class BreakScreen extends StatefulWidget {
  final int breakMinutes;
  final VoidCallback onBreakComplete;

  const BreakScreen({
    super.key,
    required this.breakMinutes,
    required this.onBreakComplete,
  });

  @override
  State<BreakScreen> createState() => _BreakScreenState();
}

class _BreakScreenState extends State<BreakScreen>
    with SingleTickerProviderStateMixin {
  int _remainingSeconds = 0;
  Timer? _timer;
  late AnimationController _animController;
  int _tipIndex = 0;
  bool _isPaused = false;
  double _ambientVolume = 0.4;

  static const _tips = [
    'Close your eyes and take 5 deep breaths.',
    'Stand up and stretch your arms above your head.',
    'Look at something far away for 20 seconds.',
    'Drink a glass of water to stay hydrated.',
    'Roll your shoulders backwards 10 times.',
    'Walk around for a minute to boost circulation.',
    'Massage your hands and fingers gently.',
    'Do 10 neck rotations slowly.',
    'Rest your eyes — close them for a minute.',
    'Take a moment to appreciate what you accomplished.',
    'Write down 3 things you are grateful for.',
    'Listen to your favorite calming song.',
  ];

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.breakMinutes * 60;
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.breakMinutes * 60),
    )..forward();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isPaused) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds % 20 == 0) {
          setState(() {
            _tipIndex = (_tipIndex + 1) % _tips.length;
          });
        }
      } else {
        t.cancel();
        AudioService.playFinish();
        widget.onBreakComplete();
      }
    });
  }

  void _togglePause() {
    setState(() => _isPaused = !_isPaused);
    if (_isPaused) {
      _animController.stop();
    } else {
      _animController.forward();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  double get _progress => widget.breakMinutes * 60 > 0
      ? 1.0 - (_remainingSeconds / (widget.breakMinutes * 60))
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final size = (screenWidth * 0.62).clamp(180.0, 280.0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1A2F) : const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _tips[_tipIndex],
                key: ValueKey(_tipIndex),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.green[200] : Colors.green[800],
                ),
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: size,
              height: size,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      value: _progress,
                      strokeWidth: 7,
                      backgroundColor: AppColors.success.withValues(alpha: 0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.success),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: (size * 0.22).clamp(28.0, 42.0),
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Break Time',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildAmbientSounds(isDark),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _togglePause,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    decoration: BoxDecoration(
                      color: _isPaused
                          ? AppColors.success
                          : AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          color: _isPaused ? Colors.white : AppColors.success,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isPaused ? 'Resume' : 'Pause',
                          style: TextStyle(
                            color: _isPaused ? Colors.white : AppColors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    _timer?.cancel();
                    AudioService.stopAlarm();
                    widget.onBreakComplete();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      'Skip Break',
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientSounds(bool isDark) {
    return Column(
      children: [
        Text(
          'Ambient Sounds',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: AmbientSoundType.values.map((type) {
            final isActive = AmbientSoundService.currentType == type;
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isActive) {
                    AmbientSoundService.stop();
                  } else {
                    AmbientSoundService.play(type);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.success.withValues(alpha: 0.15)
                      : isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? AppColors.success.withValues(alpha: 0.4)
                        : isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.grey.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color:
                                AppColors.success.withValues(alpha: 0.15),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AmbientSoundService.getSoundIcon(type),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      AmbientSoundService.getSoundName(type),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.w500,
                        color: isActive
                            ? AppColors.success
                            : isDark
                                ? Colors.grey[300]
                                : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        if (AmbientSoundService.isPlaying) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.volume_down_rounded,
                  color: isDark ? Colors.grey[500] : Colors.grey[400], size: 16),
              Expanded(
                child: Slider(
                  value: _ambientVolume,
                  min: 0.0,
                  max: 1.0,
                  activeColor: AppColors.success,
                  inactiveColor: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.withValues(alpha: 0.2),
                  onChanged: (v) {
                    setState(() => _ambientVolume = v);
                    AmbientSoundService.setVolume(v);
                  },
                ),
              ),
              Icon(Icons.volume_up_rounded,
                  color: isDark ? Colors.grey[500] : Colors.grey[400], size: 16),
            ],
          ),
        ],
      ],
    );
  }
}
