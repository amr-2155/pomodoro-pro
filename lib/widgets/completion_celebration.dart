import 'dart:math';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class CompletionCelebration extends StatefulWidget {
  final int sessionCount;
  final bool isMilestone;
  final String quote;
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
    required this.modeLabel,
    required this.durationMinutes,
    required this.onDismiss,
    this.projectName,
    this.sessionId,
  });

  static Future<void> show(
    BuildContext context, {
    required int sessionCount,
    required bool isMilestone,
    required String quote,
    required String modeLabel,
    required int durationMinutes,
    String? projectName,
    String? sessionId,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'celebration',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        return CompletionCelebration(
          sessionCount: sessionCount,
          isMilestone: isMilestone,
          quote: quote,
          modeLabel: modeLabel,
          durationMinutes: durationMinutes,
          projectName: projectName,
          sessionId: sessionId,
          onDismiss: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  @override
  State<CompletionCelebration> createState() => _CompletionCelebrationState();
}

class _CompletionCelebrationState extends State<CompletionCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnim;
  late Animation<Offset> _slideAnim;

  final List<_Particle> _particles = [];
  final _random = Random();
  int _selectedRating = 0;
  final _notesController = TextEditingController();
  bool _saved = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 4 + _random.nextDouble() * 8,
        color: [
          AppColors.primary,
          AppColors.accent,
          AppColors.success,
          AppColors.warning,
          const Color(0xFF00BCD4),
          const Color(0xFF9C27B0),
        ][_random.nextInt(6)],
        speed: 0.5 + _random.nextDouble() * 1.5,
        angle: _random.nextDouble() * 2 * pi,
      ));
    }

    _scaleController.forward();
    _slideController.forward();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _particleController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;
    final cardWidth = min(screenW * 0.85, 380.0);

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          _saveRating();
          widget.onDismiss();
        },
        child: Stack(
          children: [
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, _) {
                return CustomPaint(
                  size: MediaQuery.of(context).size,
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _particleController.value,
                  ),
                );
              },
            ),
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: cardWidth,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildEmoji(),
                            const SizedBox(height: 12),
                            _buildTitle(),
                            const SizedBox(height: 6),
                            _buildSubtitle(),
                            const SizedBox(height: 16),
                            _buildQuoteCard(isDark),
                            const SizedBox(height: 16),
                            _buildStatsRow(),
                            const SizedBox(height: 16),
                            _buildRatingSection(isDark),
                            const SizedBox(height: 20),
                            _buildContinueButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmoji() {
    return Text(
      widget.isMilestone ? '🏆' : '🎉',
      style: const TextStyle(fontSize: 48),
    );
  }

  Widget _buildTitle() {
    final titles = widget.isMilestone
        ? ['Milestone Reached!', 'Incredible Achievement!', 'You\'re on Fire!']
        : ['Session Complete!', 'Great Work!', 'Well Done!'];
    final title = titles[widget.sessionCount % titles.length];

    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSubtitle() {
    final projectName = widget.projectName;
    return Text(
      projectName != null
          ? '${widget.durationMinutes}min ${widget.modeLabel} — $projectName'
          : '${widget.durationMinutes}min ${widget.modeLabel}',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
    );
  }

  Widget _buildQuoteCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.accent.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        widget.quote,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.italic,
          color: isDark ? Colors.white70 : AppColors.textLight,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
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
          label: '${widget.durationMinutes}min',
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        _buildStatChip(
          icon: Icons.bolt,
          label: '${widget.sessionCount * widget.durationMinutes}min total',
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

  Widget _buildRatingSection(bool isDark) {
    return Column(
      children: [
        Text(
          'How was this session?',
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
            hintText: 'Add a note... (optional)',
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

  Widget _buildContinueButton() {
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
        child: const Text(
          'Continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double size;
  final Color color;
  final double speed;
  final double angle;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.speed,
    required this.angle,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final dx = p.x * size.width + cos(p.angle) * progress * 100 * p.speed;
      final dy = p.y * size.height +
          sin(p.angle) * progress * 100 * p.speed -
          progress * 50;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(dx, dy),
        p.size * (1.0 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}
