import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/project.dart';
import '../services/timer_service.dart';
import '../services/database_service.dart';
import '../services/ambient_sound_service.dart';
import '../widgets/completion_celebration.dart';
import '../widgets/break_screen.dart';
import '../utils/page_transitions.dart';

class ImmersiveFocusScreen extends StatefulWidget {
  final Project project;

  const ImmersiveFocusScreen({super.key, required this.project});

  @override
  State<ImmersiveFocusScreen> createState() => _ImmersiveFocusScreenState();
}

class _ImmersiveFocusScreenState extends State<ImmersiveFocusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;
  bool _controlsVisible = true;
  bool _showCountdown = true;
  int _countdownValue = 3;
  double _ambientVolume = 0.4;
  late AnimationController _countdownController;
  late Animation<double> _countdownScale;
  late Animation<double> _countdownOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    _countdownController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _countdownScale = Tween<double>(begin: 2.0, end: 0.5).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.easeOutBack),
    );
    _countdownOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _countdownController, curve: Curves.easeIn),
    );

    _startCountdown();
  }

  void _startCountdown() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _countdownValue = i);
      _countdownController.reset();
      _countdownController.forward();
      await Future.delayed(const Duration(milliseconds: 800));
    }
    if (!mounted) return;
    setState(() => _showCountdown = false);
    _startTimer();
  }

  void _startTimer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timer = context.read<TimerService>();
      timer.onSessionComplete = _onSessionComplete;
      timer.onBreakStart = _onBreakStart;
      timer.setProject(widget.project.id);
      timer.setDuration(TimerMode.focus, widget.project.defaultDuration);
      timer.start();
    });
  }

  @override
  void dispose() {
    final timer = context.read<TimerService>();
    timer.onSessionComplete = null;
    timer.onBreakStart = null;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _fadeController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  void _onSessionComplete() {
    final timer = context.read<TimerService>();
    AmbientSoundService.stop();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        CompletionCelebration.show(
          context,
          sessionCount: timer.sessionCount,
          isMilestone: timer.isMilestone,
          quote: timer.completionQuote,
          sessionId: timer.lastCompletedSessionId,
          modeLabel: 'Focus',
          durationMinutes: timer.totalSeconds ~/ 60,
          projectName: widget.project.name,
        ).then((_) {
          if (mounted && DatabaseService.autoStartBreaks) {
            final breakMin = timer.mode == TimerMode.longBreak
                ? DatabaseService.longBreakDuration
                : DatabaseService.shortBreakDuration;
            _onBreakStart(breakMin);
          } else if (mounted && DatabaseService.autoStartPomodoros) {
            timer.start();
          }
        });
      }
    });
  }

  void _onBreakStart(int breakMinutes) {
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
            timer.setDuration(TimerMode.focus, widget.project.defaultDuration);
            timer.start();
          }
        },
      )),
    );
  }

  void _toggleControls() {
    setState(() {
      _controlsVisible = !_controlsVisible;
    });
    if (_controlsVisible) {
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  Color get _projectColor => Color(widget.project.colorValue);

  void _showAmbientSoundPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1D3A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ambient Sounds',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
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
                      Navigator.pop(ctx);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
                        color: isActive
                            ? _projectColor.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isActive
                              ? _projectColor.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.08),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AmbientSoundService.getSoundIcon(type),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AmbientSoundService.getSoundName(type),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w500,
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (AmbientSoundService.isPlaying) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Icon(Icons.volume_down_rounded, color: Colors.white54, size: 18),
                    Expanded(
                      child: Slider(
                        value: _ambientVolume,
                        min: 0.0,
                        max: 1.0,
                        activeColor: _projectColor,
                        inactiveColor: Colors.white.withValues(alpha: 0.1),
                        onChanged: (v) {
                          setState(() => _ambientVolume = v);
                          AmbientSoundService.setVolume(v);
                        },
                      ),
                    ),
                    const Icon(Icons.volume_up_rounded, color: Colors.white54, size: 18),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final timer = context.watch<TimerService>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(isDark),
            _buildParticles(isDark),
            if (_showCountdown) _buildCountdown(),
            AnimatedBuilder(
              animation: _fadeAnim,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnim.value,
                  child: _controlsVisible ? _buildControls(timer, isDark) : const SizedBox.shrink(),
                );
              },
            ),
            if (!_controlsVisible)
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Tap anywhere to show controls',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(bool isDark) {
    final color = _projectColor;
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topCenter,
          radius: 1.5,
          colors: [
            color.withValues(alpha: 0.15),
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: AnimatedBuilder(
        animation: _countdownController,
        builder: (context, child) {
          return Transform.scale(
            scale: _countdownScale.value,
            child: Opacity(
              opacity: _countdownOpacity.value,
              child: Text(
                '$_countdownValue',
                style: TextStyle(
                  fontSize: 120,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: -4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticles(bool isDark) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _BackgroundParticles(
        color: _projectColor,
      ),
    );
  }

  Widget _buildControls(TimerService timer, bool isDark) {
    final size = min(MediaQuery.of(context).size.width * 0.6, 250.0);

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    timer.pause();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white70, size: 22),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _projectColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _projectColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.project.icon, style: const TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      Text(
                        widget.project.name,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _showAmbientSoundPicker,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AmbientSoundService.isPlaying
                          ? _projectColor.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      AmbientSoundService.isPlaying
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
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
                    value: timer.progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(_projectColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timer.formattedTime,
                      style: TextStyle(
                        fontSize: size * 0.25,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timer.running ? 'Focusing...' : 'Paused',
                      style: TextStyle(
                        fontSize: 14,
                        color: _projectColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Spacer(),
          FadeTransition(
            opacity: _fadeAnim,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.refresh_rounded,
                  onTap: timer.reset,
                ),
                const SizedBox(width: 40),
                _buildMainButton(timer),
                const SizedBox(width: 40),
                _buildControlButton(
                  icon: Icons.skip_next_rounded,
                  onTap: timer.skip,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          FadeTransition(
            opacity: _fadeAnim,
            child: Text(
              '${timer.sessionCount} sessions today',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildMainButton(TimerService timer) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (timer.running) {
          timer.pause();
        } else {
          timer.start();
        }
        setState(() => _controlsVisible = true);
        _fadeController.forward();
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [_projectColor, _projectColor.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: _projectColor.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          timer.running ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(icon, color: Colors.white54, size: 20),
      ),
    );
  }
}

class _BackgroundParticles extends CustomPainter {
  final Color color;
  final _random = Random(42);

  _BackgroundParticles({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 25; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final r = 1.0 + _random.nextDouble() * 2;
      final paint = Paint()
        ..color = color.withValues(alpha: 0.06 + _random.nextDouble() * 0.06)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
