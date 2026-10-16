import 'package:flutter/material.dart';

/// Centres and constrains the UI to a comfortable reading width on large
/// screens (desktop web, tablets, foldables). On phones the constraint is a
/// no-op and the layout stays exactly as before.
///
/// The child is given a matching [MediaQuery] so widgets that branch on
/// `MediaQuery.size` keep seeing the width they are actually laid out in.
class ResponsiveFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveFrame({
    super.key,
    required this.child,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width <= maxWidth) return child;

        final theme = Theme.of(context);
        final height = constraints.hasBoundedHeight ? constraints.maxHeight : null;
        final media = MediaQuery.of(context);

        return ColoredBox(
          color: theme.scaffoldBackgroundColor,
          child: Center(
            child: Container(
              width: maxWidth,
              height: height,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.24),
                    blurRadius: 32,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: MediaQuery(
                data: media.copyWith(
                  size: Size(maxWidth, height ?? media.size.height),
                ),
                child: ClipRect(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}
