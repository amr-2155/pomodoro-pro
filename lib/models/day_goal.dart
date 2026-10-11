import 'package:hive/hive.dart';
import 'stage_item.dart';

@HiveType(typeId: 4)
class DayGoal extends HiveObject {
  @HiveField(0)
  String dateKey;

  @HiveField(1)
  int goalMinutes;

  @HiveField(2)
  int carryOverMinutes;

  @HiveField(3)
  List<StageItem> stages;

  @HiveField(4)
  int manuallyCompletedMinutes;

  DayGoal({
    required this.dateKey,
    required this.goalMinutes,
    this.carryOverMinutes = 0,
    List<StageItem>? stages,
    this.manuallyCompletedMinutes = 0,
  }) : stages = stages ?? [];

  Map<String, dynamic> toMap() {
    return {
      'dateKey': dateKey,
      'goalMinutes': goalMinutes,
      'carryOverMinutes': carryOverMinutes,
      'stages': stages.map((s) => s.toMap()).toList(),
      'manuallyCompletedMinutes': manuallyCompletedMinutes,
    };
  }

  factory DayGoal.fromMap(Map<String, dynamic> map) {
    final rawStages = map['stages'];
    final stages = <StageItem>[];
    if (rawStages is List) {
      for (final item in rawStages) {
        if (item is Map) {
          try {
            stages.add(
                StageItem.fromMap(Map<String, dynamic>.from(item)));
          } catch (_) {
            // Skip an unreadable stage rather than losing the whole day goal.
          }
        }
      }
    }
    return DayGoal(
      dateKey: map['dateKey'] ?? '',
      goalMinutes: (map['goalMinutes'] as num?)?.toInt() ?? 0,
      carryOverMinutes: (map['carryOverMinutes'] as num?)?.toInt() ?? 0,
      stages: stages,
      manuallyCompletedMinutes:
          (map['manuallyCompletedMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}

class DayGoalAdapter extends TypeAdapter<DayGoal> {
  @override
  final int typeId = 4;

  @override
  DayGoal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()
    };
    return DayGoal(
      dateKey: fields[0] as String,
      goalMinutes: fields[1] as int,
      carryOverMinutes: fields[2] as int? ?? 0,
      stages: (fields[3] as List?)?.cast<StageItem>() ?? [],
      manuallyCompletedMinutes: fields[4] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, DayGoal obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.goalMinutes)
      ..writeByte(2)
      ..write(obj.carryOverMinutes)
      ..writeByte(3)
      ..write(obj.stages)
      ..writeByte(4)
      ..write(obj.manuallyCompletedMinutes);
  }
}
