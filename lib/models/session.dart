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

  @HiveField(9)
  int? actualMinutes;

  @HiveField(10)
  DateTime? startTime;

  @HiveField(11)
  DateTime? endTime;

  @HiveField(12)
  int? actualSeconds;

  /// Tasbeeh repetitions captured in this session (null for timer sessions).
  @HiveField(13)
  int? count;

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
    this.actualMinutes,
    this.startTime,
    this.endTime,
    this.actualSeconds,
    this.count,
  }) : date = date ?? startTime ?? DateTime.now();

  double get durationHours => durationMinutes / 60.0;
}
