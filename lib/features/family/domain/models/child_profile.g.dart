// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChildProfileAdapter extends TypeAdapter<ChildProfile> {
  @override
  final int typeId = 0;

  @override
  ChildProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChildProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      avatar: fields[2] as String,
      age: fields[3] as int,
      level: fields[4] as String,
      totalPoints: fields[5] as int,
      effectiveTimeMinutesWeek: fields[6] as int,
      effectiveTimeMinutesTotal: fields[7] as int,
      currentStreak: fields[8] as int,
      longestStreak: fields[9] as int,
      earnedScreenTimePending: fields[10] as int,
      earnedScreenTimeApproved: fields[11] as int,
      lastActiveDate: fields[12] as DateTime?,
      colorScheme: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ChildProfile obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatar)
      ..writeByte(3)
      ..write(obj.age)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.totalPoints)
      ..writeByte(6)
      ..write(obj.effectiveTimeMinutesWeek)
      ..writeByte(7)
      ..write(obj.effectiveTimeMinutesTotal)
      ..writeByte(8)
      ..write(obj.currentStreak)
      ..writeByte(9)
      ..write(obj.longestStreak)
      ..writeByte(10)
      ..write(obj.earnedScreenTimePending)
      ..writeByte(11)
      ..write(obj.earnedScreenTimeApproved)
      ..writeByte(12)
      ..write(obj.lastActiveDate)
      ..writeByte(13)
      ..write(obj.colorScheme);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
