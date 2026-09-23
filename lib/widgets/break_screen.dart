import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/completion_sound.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../services/ambient_sound_service.dart';
import 'package:pomodoro_app/l10n/app_localizations.dart';

class BreakScreen extends StatefulWidget {
  final int breakSeconds;
  final VoidCallback onBreakComplete;

  const BreakScreen({
    super.key,
    required this.breakSeconds,
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

  List<String> get _tips => AppLocalizations.of(context).breakTips;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.breakSeconds;
    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.breakSeconds),
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
        AudioService.playCompletionSound(
          completionSoundFromKey(DatabaseService.completionSoundType),
        );
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

  double get _progress => widget.breakSeconds > 0
      ? 1.0 - (_remainingSeconds / widget.breakSeconds)
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final size = (screenWidth * 0.62).clamp(180.0, 280.0);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF0F7F2),
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
                  color: isDark
                      ? AppColors.tasbeehGreen.withValues(alpha: 0.9)
                      : const Color(0xFF1E5B33),
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
                        Text(
                          AppLocalizations.of(context).breakTime,
                          style: const TextStyle(
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
                            _isPaused ? AppLocalizations.of(context).resume : AppLocalizations.of(context).pause,
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
                    AudioService.stopAllSounds();
                    widget.onBreakComplete();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    AppLocalizations.of(context).skipBreak,
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
          AppLocalizations.of(context).ambientSounds,
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
