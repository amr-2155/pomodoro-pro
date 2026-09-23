import 'dart:math';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

/// Professional, lightweight project-completion celebration:
/// glowing success ring + animated checkmark + minimal confetti.
class ProjectCompletionOverlay extends StatefulWidget {
  final String projectName;
  final int goalMinutes;

  const ProjectCompletionOverlay({
    super.key,
    required this.projectName,
    required this.goalMinutes,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectName,
    required int goalMinutes,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: ProjectCompletionOverlay(
          projectName: projectName,
          goalMinutes: goalMinutes,
        ),
      ),
    );
  }

  @override
  State<ProjectCompletionOverlay> createState() =>
      _ProjectCompletionOverlayState();
}

class _ProjectCompletionOverlayState extends State<ProjectCompletionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _ring;
  late Animation<double> _check;
  late Animation<double> _cardScale;
  List<_MiniConfetti> _pieces = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
    );
    _check = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOutBack),
    );
    _cardScale = Tween(begin: 0.9, end: 1.0).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));

    final rng = Random();
    final colors = [
      AppColors.success,
      AppColors.primary,
      AppColors.warning,
      const Color(0xFF00BCD4),
    ];
    for (int i = 0; i < 24; i++) {
      _pieces.add(_MiniConfetti(
        x: rng.nextDouble(),
        delay: rng.nextDouble() * 0.4,
        speed: 0.8 + rng.nextDouble() * 0.6,
        size: 3 + rng.nextDouble() * 4,
        color: colors[rng.nextInt(colors.length)],
        sway: 10 + rng.nextDouble() * 20,
      ));
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _MiniConfettiPainter(
                  pieces: _pieces, progress: _controller.value),
            ),
          ),
          Center(
            child: ScaleTransition(
              scale: _cardScale,
              child: Container(
                width: min(MediaQuery.of(context).size.width * 0.85, 340),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.35),
                      blurRadius: 44,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Success ring + check.
                    SizedBox(
                      width: 108,
                      height: 108,
                      child: CustomPaint(
                        painter: _RingCheckPainter(
                          ringProgress: _ring.value,
                          checkProgress: _check.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '${l10n.congratsTitle} 🎉',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${l10n.projectCompletedBody} ${widget.projectName}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.5,
                          height: 1.4,
                          color: isDark ? Colors.white70 : Colors.grey[700]),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.goalMinutes} ${l10n.minutesDoneLabel}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [
                            AppColors.success,
                            Color(0xFF66BB6A),
                          ]),
                          borderRadius: BorderRadius.circular(14),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painters ─────────────────────────────────────────────────

class _RingCheckPainter extends CustomPainter {
  final double ringProgress;
  final double checkProgress;

  _RingCheckPainter({
    required this.ringProgress,
    required this.checkProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;

    // Soft glow behind the ring.
    final glow = Paint()
      ..color = AppColors.success.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(center, radius, glow);

    // Progress ring.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        startAngle: -pi / 2,
        endAngle: 3 * pi / 2,
        colors: [AppColors.success, Color(0xFF66BB6A)],
        transform: GradientRotation(-pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * ringProgress.clamp(0.0, 1.0),
      false,
      ringPaint,
    );

    // Track (faint full circle under the arc).
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..color = AppColors.success.withValues(alpha: 0.1);
    canvas.drawCircle(center, radius, track);

    // Animated check path.
    if (checkProgress > 0) {
      final p = checkProgress.clamp(0.0, 1.0);
      final start = Offset(center.dx - radius * 0.42, center.dy + radius * 0.04);
      final mid = Offset(center.dx - radius * 0.10, center.dy + radius * 0.36);
      final end = Offset(center.dx + radius * 0.46, center.dy - radius * 0.30);

      final seg1Len = (mid - start).distance;
      final seg2Len = (end - mid).distance;
      final total = seg1Len + seg2Len;
      final drawn = total * p;

      final checkPath = Path()..moveTo(start.dx, start.dy);
      if (drawn <= seg1Len) {
        final t = drawn / seg1Len;
        final pt = Offset.lerp(start, mid, t)!;
        checkPath.lineTo(pt.dx, pt.dy);
      } else {
        checkPath.lineTo(mid.dx, mid.dy);
        final t = ((drawn - seg1Len) / seg2Len).clamp(0.0, 1.0);
        final pt = Offset.lerp(mid, end, t)!;
        checkPath.lineTo(pt.dx, pt.dy);
      }

      final checkPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.success;
      canvas.drawPath(checkPath, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingCheckPainter old) =>
      old.ringProgress != ringProgress || old.checkProgress != checkProgress;
}

class _MiniConfetti {
  final double x;
  final double delay;
  final double speed;
  final double size;
  final Color color;
  final double sway;

  _MiniConfetti({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
    required this.color,
    required this.sway,
  });
}

class _MiniConfettiPainter extends CustomPainter {
  final List<_MiniConfetti> pieces;
  final double progress;

  _MiniConfettiPainter({required this.pieces, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final t = (progress - p.delay) / p.speed;
      if (t <= 0 || t >= 1) continue;
      final y = t * (size.height + 60) - 40;
      final x = p.x * size.width + sin(t * 4 * pi) * p.sway;
      final paint = Paint()
        ..color = p.color.withValues(alpha: (1 - t) * 0.8);
      canvas.drawCircle(Offset(x, y), p.size * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniConfettiPainter old) =>
      old.progress != progress;
}
