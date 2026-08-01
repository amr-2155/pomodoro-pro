import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'database_service.dart';
import '../utils/constants.dart';

void downloadBackup(BuildContext context, String json) {
  if (kIsWeb) {
    final blob = web.Blob([json.toJS].toJS,
        web.BlobPropertyBag(type: 'application/json'));
    final url = web.URL.createObjectURL(blob);
    final a = web.document.createElement('a') as web.HTMLAnchorElement;
    a.href = url;
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    a.download = 'pomodoro_backup_$dateStr.json';
    web.document.body?.appendChild(a);
    a.click();
    a.remove();
    web.URL.revokeObjectURL(url);
    _showSnack(context, 'Backup downloaded!', AppColors.success);
  } else {
    _showBackupDialog(context, json);
  }
}

Future<void> pickAndRestore(BuildContext context) async {
  if (!kIsWeb) {
    _showSnack(context, 'Restore is only available on the web version',
        AppColors.warning);
    return;
  }
  final input = web.document.createElement('input') as web.HTMLInputElement;
  input.type = 'file';
  input.accept = '.json';
  input.onChange.listen((event) async {
    final files = input.files;
    if (files == null || files.length == 0) return;
    final file = files.item(0);
    if (file == null) return;
    final reader = web.FileReader();
    reader.onLoadEnd.listen((_) async {
      final content = (reader.result as JSString).toDart;
      try {
        jsonDecode(content);
      } catch (_) {
        if (context.mounted) {
          _showSnack(context, 'Invalid backup file', AppColors.error);
        }
        return;
      }
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Restore Backup?'),
            content: const Text(
                'This will add all data from the backup. Existing data will not be deleted.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Restore'),
              ),
            ],
          );
        },
      );
      if (confirmed == true) {
        final count = await DatabaseService.restoreBackup(content);
        if (context.mounted) {
          _showSnack(context, 'Restored $count items from backup',
              AppColors.success);
        }
      }
    });
    reader.readAsText(file);
  });
  input.click();
}

void _showBackupDialog(BuildContext context, String json) {
  showDialog(
    context: context,
    builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
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

void _showSnack(BuildContext context, String message, Color color) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}
