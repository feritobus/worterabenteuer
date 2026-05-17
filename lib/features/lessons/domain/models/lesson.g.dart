// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lesson.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LessonAdapter extends TypeAdapter<Lesson> {
  @override
  final int typeId = 1;

  @override
  Lesson read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Lesson(
      id: fields[0] as String,
      title: fields[1] as String,
      titleSpanish: fields[2] as String,
      source: fields[3] as String,
      level: fields[4] as String,
      childId: fields[13] as String,
      status: fields[5] as String,
      wordsTotal: fields[6] as int,
      wordsDominated: fields[7] as int,
      wordsWithVoiceBonus: fields[8] as int,
      perfectRoundCompleted: fields[9] as bool,
      extraVocabUnlocked: fields[10] as bool,
      assignedAt: fields[11] as DateTime?,
      completedAt: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Lesson obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.titleSpanish)
      ..writeByte(3)
      ..write(obj.source)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.wordsTotal)
      ..writeByte(7)
      ..write(obj.wordsDominated)
      ..writeByte(8)
      ..write(obj.wordsWithVoiceBonus)
      ..writeByte(9)
      ..write(obj.perfectRoundCompleted)
      ..writeByte(10)
      ..write(obj.extraVocabUnlocked)
      ..writeByte(11)
      ..write(obj.assignedAt)
      ..writeByte(12)
      ..write(obj.completedAt)
      ..writeByte(13)
      ..write(obj.childId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LessonAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
