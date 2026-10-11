import 'package:hive/hive.dart';

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isDone;

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  int estimatedPomodoros;

  @HiveField(5)
  int completedPomodoros;

  @HiveField(6)
  String? projectId;

  @HiveField(7)
  int priority;

  @HiveField(8)
  String? description;

  /// Manual ordering from the drag-and-drop reorder mode. -1 means "not
  /// manually ordered yet". Persisted because the previous implementation
  /// reordered a throw-away copy of the list, so the new order was lost on the
  /// very next build.
  @HiveField(9)
  int sortOrder;

  Task({
    required this.id,
    required this.title,
    this.isDone = false,
    DateTime? createdAt,
    this.estimatedPomodoros = 1,
    this.completedPomodoros = 0,
    this.projectId,
    this.priority = 0,
    this.description,
    this.sortOrder = -1,
  }) : createdAt = createdAt ?? DateTime.now();

  String get priorityLabel {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'None';
    }
  }
}

/// Hand-written adapter (like `DayGoalAdapter` / `StageItemAdapter`) so every
/// field falls back to its default when absent. The generated adapter emits a
/// bare `fields[9] as int`, which throws on records written before `sortOrder`
/// existed — that would make every existing user's task box unreadable.
class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 2;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      isDone: fields[2] as bool? ?? false,
      createdAt: fields[3] as DateTime? ?? DateTime.now(),
      estimatedPomodoros: fields[4] as int? ?? 1,
      completedPomodoros: fields[5] as int? ?? 0,
      projectId: fields[6] as String?,
      priority: fields[7] as int? ?? 0,
      description: fields[8] as String?,
      sortOrder: fields[9] as int? ?? -1,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.isDone)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.estimatedPomodoros)
      ..writeByte(5)
      ..write(obj.completedPomodoros)
      ..writeByte(6)
      ..write(obj.projectId)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
