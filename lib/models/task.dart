import 'package:hive/hive.dart';

part 'task.g.dart';

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
