import 'package:hive/hive.dart';

part 'project.g.dart';

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
    this.defaultDuration = 25,
    this.theme = 'default',
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
      defaultDuration: map['defaultDuration'] ?? 25,
      theme: map['theme'] ?? 'default',
    );
  }
}
