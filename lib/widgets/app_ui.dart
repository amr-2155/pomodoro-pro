import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// Shared card shell. Unifies the duplicated
/// `color: isDark ? surfaceDark : Colors.white` + shadow + radius pattern
/// used ~15 times across the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppRadius.lg,
    this.color,
    this.borderColor,
    this.borderWidth = 0,
    this.shadows,
    this.onTap,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scheme = Theme.of(context).colorScheme;

    final Widget body = AnimatedContainer(
      duration: AppMotion.base,
      curve: AppMotion.easeOut,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ??
            (isDark ? AppColors.surfaceDark : scheme.surface),
        borderRadius: BorderRadius.circular(radius),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: borderWidth)
            : null,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 3),
              ),
            ],
      ),
      child: child,
    );

    if (onTap == null) return body;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: body,
    );
  }
}

/// Standard grab-handle shown at the top of modal bottom sheets.
class SheetHandleBar extends StatelessWidget {
  final double width;
  const SheetHandleBar({super.key, this.width = 40});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: 4,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.25)
            : Colors.grey.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Thin vertical divider used between inline stats.
class AppVDivider extends StatelessWidget {
  final double height;
  const AppVDivider({super.key, this.height = 24});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.borderDark
          : AppColors.borderLight,
    );
  }
}

/// Title bar for screen headers — honours theme text styles.
class ScreenTitle extends StatelessWidget {
  final String title;
  const ScreenTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.displaySmall);
  }
}

/// Standard icon-in-tinted-square badge.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 34,
    this.iconSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

/// Reusable empty-state (icon in a soft circle + title + subtitle).
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? color;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 30, color: c.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? Colors.grey[600] : Colors.grey[500],
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
