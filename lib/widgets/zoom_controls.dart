import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../utils/constants.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      right: 14,
      bottom: 80,
      child: ValueListenableBuilder<double>(
        valueListenable: DatabaseService.zoomNotifier,
        builder: (context, zoom, _) {
          return Container(
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDark.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _zoomButton(
                  context,
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onTap: () {
                    final newZoom = (zoom + 0.1).clamp(0.5, 2.0);
                    DatabaseService.setSetting('appZoom', newZoom);
                  },
                ),
                Container(
                  height: 1,
                  width: 28,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                _zoomButton(
                  context,
                  icon: Icons.restart_alt_rounded,
                  tooltip: 'Reset',
                  onTap: () {
                    DatabaseService.setSetting('appZoom', 1.0);
                  },
                ),
                Container(
                  height: 1,
                  width: 28,
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
                _zoomButton(
                  context,
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onTap: () {
                    final newZoom = (zoom - 0.1).clamp(0.5, 2.0);
                    DatabaseService.setSetting('appZoom', newZoom);
                  },
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${(zoom * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _zoomButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
