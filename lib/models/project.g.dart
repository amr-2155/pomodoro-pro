// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
      colorValue: fields[2] as int,
      icon: fields[3] as String,
      createdAt: fields[4] as DateTime?,
      totalSessions: fields[5] as int,
      totalMinutes: fields[6] as int,
      isArchived: fields[7] as bool,
      description: fields[8] as String? ?? '',
      weeklyGoalMinutes: fields[9] as int? ?? 0,
      defaultDuration: fields[10] as int? ?? 25,
      theme: fields[11] as String? ?? 'default',
    );
  }

  @override
  void write(BinaryWriter writer, Project obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.theme);
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
