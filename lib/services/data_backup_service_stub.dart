import 'package:flutter/material.dart';

void downloadBackup(BuildContext context, String json) {
  showDialog(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E2130) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Backup Data'),
        content: Text(
          json,
          style: const TextStyle(fontSize: 10),
          maxLines: 12,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}

Future<void> pickAndRestore(BuildContext context) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Restore is only available on the web version'),
      backgroundColor: Color(0xFFF59E0B),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
