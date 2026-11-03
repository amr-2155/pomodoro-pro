import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Project extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int colorValue;

  @HiveField(3)
  String icon;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  int totalSessions;

  @HiveField(6)
  int totalMinutes;

  @HiveField(7)
  bool isArchived;

  @HiveField(8)
  String description;

  @HiveField(9)
  int weeklyGoalMinutes;

  @HiveField(10)
  int defaultDuration;

  @HiveField(11)
  String theme;

  @HiveField(12)
  int dailyGoalMinutes;

  @HiveField(13)
  bool includeInWeeklyGoal;

  /// Numeric tasbeeh goal (repetitions). 0 = no counter goal.
  @HiveField(14)
  int tasbeehGoal;

  Project({
    required this.id,
    required this.name,
    required this.colorValue,
    this.icon = '🎯',
    DateTime? createdAt,
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.isArchived = false,
    this.description = '',
    this.weeklyGoalMinutes = 0,
    this.defaultDuration = 1500,
    this.theme = 'default',
    this.dailyGoalMinutes = 0,
    this.includeInWeeklyGoal = true,
    this.tasbeehGoal = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  double get totalHours => totalMinutes / 60.0;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'colorValue': colorValue,
      'icon': icon,
      'createdAt': createdAt.toIso8601String(),
      'totalSessions': totalSessions,
      'totalMinutes': totalMinutes,
      'isArchived': isArchived,
      'description': description,
      'weeklyGoalMinutes': weeklyGoalMinutes,
      'defaultDuration': defaultDuration,
      'theme': theme,
      'dailyGoalMinutes': dailyGoalMinutes,
      'includeInWeeklyGoal': includeInWeeklyGoal,
      'tasbeehGoal': tasbeehGoal,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      colorValue: map['colorValue'] ?? 0xFF6C63FF,
      icon: map['icon'] ?? '🎯',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      totalSessions: map['totalSessions'] ?? 0,
      totalMinutes: map['totalMinutes'] ?? 0,
      isArchived: map['isArchived'] ?? false,
      description: map['description'] ?? '',
      weeklyGoalMinutes: map['weeklyGoalMinutes'] ?? 0,
      defaultDuration: map['defaultDuration'] ?? 1500,
      theme: map['theme'] ?? 'default',
      dailyGoalMinutes: map['dailyGoalMinutes'] ?? 0,
      includeInWeeklyGoal: map['includeInWeeklyGoal'] ?? true,
      tasbeehGoal: map['tasbeehGoal'] ?? 0,
    );
  }
}

/// Hand-written adapter (like `TaskAdapter` / `DayGoalAdapter` /
/// `StageItemAdapter`) so every field falls back to its default when absent.
///
/// The generated adapter emitted bare casts for the later fields —
/// `fields[12] as int`, `fields[13] as bool`, `fields[14] as int` — which throw
/// `type 'Null' is not a subtype of type 'int'` on any project record written
/// before those fields existed. `DatabaseService.init()` walks the whole
/// projects box, so a single legacy record made the box unreadable and broke
/// startup for every existing user.
class ProjectAdapter extends TypeAdapter<Project> {
  @override
  final int typeId = 0;

  @override
  Project read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Project(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int? ?? 0xFF6C63FF,
      icon: fields[3] as String? ?? '🎯',
      createdAt: fields[4] as DateTime? ?? DateTime.now(),
      totalSessions: fields[5] as int? ?? 0,
      totalMinutes: fields[6] as int? ?? 0,
      isArchived: fields[7] as bool? ?? false,
      description: fields[8] as String? ?? '',
      weeklyGoalMinutes: fields[9] as int? ?? 0,
      defaultDuration: fields[10] as int? ?? 1500,
      theme: fields[11] as String? ?? 'default',
      dailyGoalMinutes: fields[12] as int? ?? 0,
      includeInWeeklyGoal: fields[13] as bool? ?? true,
      tasbeehGoal: fields[14] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.icon)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.totalSessions)
      ..writeByte(6)
      ..write(obj.totalMinutes)
      ..writeByte(7)
      ..write(obj.isArchived)
      ..writeByte(8)
      ..write(obj.description)
      ..writeByte(9)
      ..write(obj.weeklyGoalMinutes)
      ..writeByte(10)
      ..write(obj.defaultDuration)
      ..writeByte(11)
      ..write(obj.theme)
      ..writeByte(12)
      ..write(obj.dailyGoalMinutes)
      ..writeByte(13)
      ..write(obj.includeInWeeklyGoal)
      ..writeByte(14)
      ..write(obj.tasbeehGoal);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
