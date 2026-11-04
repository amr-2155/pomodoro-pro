import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:pomodoro_app/models/task.dart';
import 'package:pomodoro_app/services/database_service.dart';
import 'package:pomodoro_app/services/tasbeeh_service.dart';

// Regression coverage for data-safety fixes:
//
// * `TasbeehService.setProject` used to `return` after banking an in-flight
//   session, so the newly selected project was never applied — the counter
//   kept running under the OLD project while the UI showed the new one.
// * A backup restore silently dropped custom/edited quotes and every task's
//   manual drag-and-drop order (`sortOrder`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('pomodoro_persist_test');
    await DatabaseService.init(hivePath: tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close().timeout(const Duration(seconds: 5), onTimeout: () => <void>[]);
    if (tempDir.existsSync()) {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    }
  });

  test('init can be retried safely (startup-recovery path)', () async {
    // The boot error screen calls init() again after a failure. Re-running it
    // must not throw on already-registered adapters or already-open boxes.
    await DatabaseService.init(hivePath: tempDir.path);
    expect(DatabaseService.sessionCount, greaterThanOrEqualTo(0));
  });

  test('setProject applies the new project when idle', () {
    final svc = TasbeehService();
    svc.setProject('p1');
    expect(svc.projectId, 'p1');
  });

  test('setProject mid-session banks the old session AND switches', () {
    final svc = TasbeehService();
    svc.setProject('p1');
    svc.tap(); // starts a session under p1 with count 1
    expect(svc.isActive, isTrue);
    expect(svc.count, 1);

    svc.setProject('p2');

    expect(svc.projectId, 'p2',
        reason: 'the new selection must take effect, not be swallowed');
    expect(svc.isActive, isFalse, reason: 'the old session must be banked');
  });

  test('backup round-trip keeps custom quotes and task order', () async {
    await DatabaseService.saveQuote(
      id: 'custom_test_quote',
      ar: 'نص مخصص',
      en: 'custom text',
      cat: 'focus',
      author: 'مؤلف',
    );
    await DatabaseService.addTask(
      Task(id: 'task_ordered', title: 'مهمة', sortOrder: 7),
    );

    final backup = DatabaseService.createBackup();
    expect(backup.contains('custom_test_quote'), isTrue,
        reason: 'custom quotes must be part of a backup');

    final restored = await DatabaseService.restoreBackup(backup);
    expect(restored, greaterThan(0));

    expect(
      DatabaseService.getTaskById('task_ordered')!.sortOrder,
      7,
      reason: 'manual task order must survive a restore',
    );
    final quoteIds =
        DatabaseService.getMergedQuotes().map((q) => q['id']).toSet();
    expect(quoteIds.contains('custom_test_quote'), isTrue);
  });
}
