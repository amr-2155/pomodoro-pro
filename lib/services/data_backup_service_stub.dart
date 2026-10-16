import 'package:flutter/material.dart';

import '../utils/constants.dart';

void downloadBackup(BuildContext context, String json) {
  showDialog(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDarkAlt : Colors.white,
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
      backgroundColor: AppColors.amber,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
