import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/number_formatter.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';
import '../services/timer_service.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';
import '../l10n/app_localizations.dart';

class CompletionCelebration extends StatefulWidget {
  final int sessionCount;
  final bool isMilestone;
  final String quote;
  final String quoteSource;
  final String modeLabel;
  final int durationMinutes;
  final VoidCallback onDismiss;
  final String? projectName;
  final String? sessionId;

  const CompletionCelebration({
    super.key,
    required this.sessionCount,
    required this.isMilestone,
    required this.quote,
    this.quoteSource = '',
    required this.modeLabel,
    required this.durationMinutes,
    required this.onDismiss,
    this.projectName,
    this.sessionId,
  });

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _entrance;
  late AnimationController _confetti;
  late AnimationController _glow;

  final List<_Confetti> _pieces = [];
  final _random = Random();
  int _selectedRating = 0;
  final _notesController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();

    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _confetti = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..forward(from: 0);

    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Elegant falling confetti — slim ribbons from above.
    final colors = [
      AppColors.primary,
      AppColors.accent,
      AppColors.success,
      AppColors.warning,
      const Color(0xFF00BCD4),
      const Color(0xFF9C27B0),
    ];
    for (int i = 0; i < 42; i++) {
      _pieces.add(_Confetti(
        x: _random.nextDouble(),
        delay: _random.nextDouble() * 0.45,
        speed: 0.75 + _random.nextDouble() * 0.6,
        size: 3.5 + _random.nextDouble() * 5.5,
        color: colors[_random.nextInt(colors.length)],
        sway: 14 + _random.nextDouble() * 26,
        phase: _random.nextDouble() * 2 * pi,
        round: _random.nextBool(),
      ));
    }

    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _confetti.dispose();
    _glow.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveRating() {
    if (_saved || widget.sessionId == null) return;
    if (_selectedRating > 0 || _notesController.text.isNotEmpty) {
      DatabaseService.rateSession(
        widget.sessionId!,
        _selectedRating > 0 ? _selectedRating : 3,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      _saved = true;
    }
  }

  // Staggered intervals for a refined cascade.
  Animation<double> _stage(double start, double end) =>
      CurvedAnimation(parent: _entrance, curve: Interval(start, end, curve: Curves.easeOutCubic));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;
    final cardWidth = min(screenW * 0.88, 400.0);
    final l10n = AppLocalizations.of(context);

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _confetti,
            builder: (context, _) => CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _ConfettiPainter(pieces: _pieces, progress: _confetti.value),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(_stage(0.0, 0.55)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Glowing emblem above the card.
                  FadeTransition(
                    opacity: _stage(0.05, 0.4),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, -0.35),
                        end: Offset.zero,
                      ).animate(_stage(0.05, 0.5)),
                      child: AnimatedBuilder(
                        animation: _glow,
                        builder: (context, child) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.25 + _glow.value * 0.2),
                                blurRadius: 34 + _glow.value * 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.primaryLight,
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.isMilestone ? '\u{1F3C6}' : '\u{1F389}',
                            style: const TextStyle(fontSize: 38),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Card.
                  FadeTransition(
                    opacity: _stage(0.15, 0.65),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(_stage(0.15, 0.7)),
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: cardWidth,
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.surfaceDark : Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.white.withValues(alpha: 0.8),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.12),
                                blurRadius: 44,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStopButton(l10n),
                                const SizedBox(height: 12),
                                Text(
                                  _title(l10n),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontSize: 21, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _subtitle(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 13, color: Colors.grey[500]),
                                ),
                                const SizedBox(height: 14),
                                _buildQuoteCard(isDark),
                                const SizedBox(height: 14),
                                _buildStatsRow(l10n),
                                const SizedBox(height: 14),
                                _buildRatingSection(isDark, l10n),
                                const SizedBox(height: 18),
                                _buildContinueButton(l10n),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStopButton(AppLocalizations l10n) {
    return ListenableBuilder(
      listenable: context.watch<TimerService>(),
      builder: (context, _) {
        final timer = context.read<TimerService>();
        if (!AudioService.isCompletionLooping) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            AudioService.stopCompletionLoop();
            timer.stopCompletionLoop();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.volume_off_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  l10n.stopAlarm,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _title(AppLocalizations l10n) {
    if (widget.projectName != null && !widget.isMilestone) {
      return '${l10n.wellDone}!';
    }
    final titles = widget.isMilestone
        ? [l10n.milestoneReached, l10n.greatJob]
        : [l10n.sessionComplete, l10n.greatJob];
    return titles[widget.sessionCount % titles.length];
  }

  String _subtitle() {
    final projectName = widget.projectName;
    final base =
        '${fmtMin(widget.durationMinutes)} ${widget.modeLabel}';
    return projectName != null ? '$base \u2014 $projectName' : base;
  }

  Widget _buildQuoteCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.format_quote_rounded,
              size: 20,
              color: AppColors.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 4),
          Text(
            '\u201E${widget.quote}\u201C',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              height: 1.6,
              color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textLight,
            ),
          ),
          if (widget.quoteSource.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.quoteSource,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStatChip(
          icon: Icons.local_fire_department,
          label: '${widget.sessionCount}',
          color: AppColors.warning,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          icon: Icons.timer,
          label: fmtMin(widget.durationMinutes),
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          icon: Icons.bolt,
          label: '${l10n.total}: ${fmtMin(widget.sessionCount * widget.durationMinutes)}',
          color: AppColors.success,
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(bool isDark, AppLocalizations l10n) {
    return Column(
      children: [
        Text(
          l10n.howWasSession,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            final isSelected = _selectedRating >= starIndex;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = starIndex),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedScale(
                  scale: isSelected ? 1.2 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? AppColors.warning : Colors.grey[400],
                    size: 32,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: l10n.addNote,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.withValues(alpha: 0.06),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            isDense: true,
          ),
          maxLines: 2,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildContinueButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: () {
        _saveRating();
        widget.onDismiss();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          l10n.continueLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _Confetti {
  final double x;       // horizontal position 0-1
  final double delay;   // start offset in [0,1] of timeline
  final double speed;   // fall speed multiplier
  final double size;
  final Color color;
  final double sway;    // horizontal sway amplitude px
  final double phase;   // sway phase
  final bool round;     // circle or ribbon rectangle

  _Confetti({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.sway,
    required this.phase,
    required this.round,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> pieces;
  final double progress;

  _ConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      // Local normalized time after its own delay.
      final t = ((progress - p.delay) / p.speed);
      if (t <= 0 || t >= 1) continue;

      final y = t * (size.height + 60) - 40;
      final x = p.x * size.width +
          sin(t * 4 * pi + p.phase) * p.sway;

      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - t).clamp(0.0, 1.0) * 0.85);

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 6 * pi + p.phase);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size * 0.5, paint);
      } else {
        // Slim ribbon.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: p.size * 0.55,
              height: p.size * 1.8,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
