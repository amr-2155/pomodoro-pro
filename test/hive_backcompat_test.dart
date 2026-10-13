import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive/src/adapters/date_time_adapter.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/registry/type_registry_impl.dart';
import 'package:pomodoro_app/models/day_goal.dart';
import 'package:pomodoro_app/models/stage_item.dart';
import 'package:pomodoro_app/models/task.dart';

// Data-safety regression: the hand-written adapters must keep reading
// records that older builds already wrote.
//
// `sortOrder` (Task field 9) and the StageItem/DayGoal types were added
// after users had data on disk. A generated adapter emits a bare
// `fields[9] as int`, which THROWS on a record written before the field
// existed — that would make every existing user's task box unreadable.
// These tests write genuine legacy-shaped byte streams with Hive's own
// binary writer and assert the current adapter reads them with defaults.

TypeRegistryImpl _registry() {
  final r = TypeRegistryImpl();
  // Register the built-ins the same way the running app does at startup:
  // Hive.initFlutter() wires DateTime (typeId 16) and friends. We only need
  // DateTime here (Task.createdAt); the models are registered below.
  r
    ..registerAdapter(DateTimeWithTimezoneAdapter())
    ..registerAdapter(DateTimeAdapter<DateTimeWithoutTZ>());
  r
    ..registerAdapter(TaskAdapter())
    ..registerAdapter(DayGoalAdapter())
    ..registerAdapter(StageItemAdapter());
  return r;
}

/// Encodes a Task the way an OLD build did: 9 fields, no sortOrder.
Uint8List _encodeLegacyTask(TypeRegistry registry) {
  final w = BinaryWriterImpl(registry);
  w
    ..writeByte(9) // numOfFields — the old shape
    ..writeByte(0)
    ..write('legacy-task')
    ..writeByte(1)
    ..write('مهمة قديمة')
    ..writeByte(2)
    ..write(false)
    ..writeByte(3)
    ..write(DateTime.fromMillisecondsSinceEpoch(1700000000000))
    ..writeByte(4)
    ..write(3)
    ..writeByte(5)
    ..write(1)
    ..writeByte(6)
    ..write(null)
    ..writeByte(7)
    ..write(2)
    ..writeByte(8)
    ..write(null);
  return w.toBytes();
}

void main() {
  final registry = _registry();

  test('legacy Task (no sortOrder) reads with sortOrder defaulting to -1', () {
    final bytes = _encodeLegacyTask(registry);
    final task = TaskAdapter().read(BinaryReaderImpl(bytes, registry));

    expect(task.id, 'legacy-task');
    expect(task.title, 'مهمة قديمة');
    expect(task.estimatedPomodoros, 3);
    expect(task.completedPomodoros, 1);
    expect(task.projectId, isNull);
    expect(task.priority, 2);
    expect(task.description, isNull);
    expect(task.sortOrder, -1,
        reason: 'a field absent from old bytes must default, never throw');
  });

  test('current Task round-trips through the real writer and reader', () {
    final w = BinaryWriterImpl(registry);
    final original = Task(
      id: 't1',
      title: 'مهمة',
      estimatedPomodoros: 4,
      completedPomodoros: 2,
      priority: 1,
      description: 'وصف',
      sortOrder: 3,
    );
    TaskAdapter().write(w, original);
    final back = TaskAdapter().read(BinaryReaderImpl(w.toBytes(), registry));

    expect(back.id, original.id);
    expect(back.title, original.title);
    expect(back.priority, original.priority);
    expect(back.description, original.description);
    expect(back.sortOrder, 3);
  });

  test('StageItem round-trips including a null projectId', () {
    final w = BinaryWriterImpl(registry);
    final original = StageItem(
      id: 's1',
      title: 'قراءة',
      durationMinutes: 20,
      projectId: null,
    );
    StageItemAdapter().write(w, original);
    final back = StageItemAdapter().read(BinaryReaderImpl(w.toBytes(), registry));

    expect(back.id, 's1');
    expect(back.durationMinutes, 20);
    expect(back.projectId, isNull);
    expect(back.completed, isFalse);
  });

  test('adapter typeIds are stable and unique', () {
    expect(TaskAdapter().typeId, 2);
    expect(StageItemAdapter().typeId, 3);
    expect(DayGoalAdapter().typeId, 4);
  });
}