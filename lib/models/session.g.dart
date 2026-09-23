// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 1;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      projectId: fields[1] as String,
      date: fields[2] as DateTime?,
      durationMinutes: fields[3] as int,
      completed: fields[4] as bool,
      sessionType: fields[5] as String,
      rating: fields[6] as int?,
      notes: fields[7] as String?,
      taskId: fields[8] as String?,
      actualMinutes: fields[9] as int?,
      startTime: fields[10] as DateTime?,
      endTime: fields[11] as DateTime?,
      actualSeconds: fields[12] as int?,
      count: fields[13] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.projectId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.durationMinutes)
      ..writeByte(4)
      ..write(obj.completed)
      ..writeByte(5)
      ..write(obj.sessionType)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.taskId)
      ..writeByte(9)
      ..write(obj.actualMinutes)
      ..writeByte(10)
      ..write(obj.startTime)
      ..writeByte(11)
      ..write(obj.endTime)
      ..writeByte(12)
      ..write(obj.actualSeconds)
      ..writeByte(13)
      ..write(obj.count);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
