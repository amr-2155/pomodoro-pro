import 'package:hive/hive.dart';

@HiveType(typeId: 3)
class StageItem extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String icon;

  @HiveField(3)
  int durationMinutes;

  @HiveField(4)
  bool completed;

  @HiveField(5)
  String? projectId;

  @HiveField(6)
  int order;

  StageItem({
    required this.id,
    required this.title,
    this.icon = '📌',
    required this.durationMinutes,
    this.completed = false,
    this.projectId,
    this.order = 0,
  });
}

class StageItemAdapter extends TypeAdapter<StageItem> {
  @override
  final int typeId = 3;

  @override
  StageItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()
    };
    return StageItem(
      id: fields[0] as String,
      title: fields[1] as String,
      icon: fields[2] as String? ?? '📌',
      durationMinutes: fields[3] as int,
      completed: fields[4] as bool? ?? false,
      projectId: fields[5] as String?,
      order: fields[6] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, StageItem obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.icon)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.projectId)
      ..writeByte(6)
      ..write(obj.order);
  }
}
