import 'package:hive/hive.dart';

part 'session.g.dart';

@HiveType(typeId: 1)
class Session extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String projectId;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  int durationMinutes;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  String sessionType;

  @HiveField(6)
  int? rating;

  @HiveField(7)
  String? notes;

  @HiveField(8)
  String? taskId;

  Session({
    required this.id,
    required this.projectId,
    DateTime? date,
    required this.durationMinutes,
    this.completed = true,
    this.sessionType = 'focus',
    this.rating,
    this.notes,
    this.taskId,
  }) : date = date ?? DateTime.now();

  double get durationHours => durationMinutes / 60.0;
}
