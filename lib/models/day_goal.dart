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
