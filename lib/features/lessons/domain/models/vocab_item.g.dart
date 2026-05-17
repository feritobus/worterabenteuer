// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vocab_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VocabItemAdapter extends TypeAdapter<VocabItem> {
  @override
  final int typeId = 2;

  @override
  VocabItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VocabItem(
      id: fields[0] as String,
      german: fields[1] as String,
      spanish: fields[2] as String,
      type: fields[3] as String,
      order: fields[13] as int,
      grammarNote: fields[4] as String?,
      dominated: fields[5] as bool,
      voiceBonus: fields[6] as bool,
      flashCardViews: fields[7] as int,
      typedCorrect: fields[8] as int,
      handwrittenAttempts: fields[9] as int,
      handwrittenCorrect: fields[10] as int,
      voiceAttempts: fields[11] as int,
      voiceCorrect: fields[12] as int,
      addedToReviewRound: fields[14] as bool,
      reviewRoundPassed: fields[15] as bool,
      imageUrl: fields[16] as String?,
      audioUrl: fields[17] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VocabItem obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.german)
      ..writeByte(2)
      ..write(obj.spanish)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.grammarNote)
      ..writeByte(5)
      ..write(obj.dominated)
      ..writeByte(6)
      ..write(obj.voiceBonus)
      ..writeByte(7)
      ..write(obj.flashCardViews)
      ..writeByte(8)
      ..write(obj.typedCorrect)
      ..writeByte(9)
      ..write(obj.handwrittenAttempts)
      ..writeByte(10)
      ..write(obj.handwrittenCorrect)
      ..writeByte(11)
      ..write(obj.voiceAttempts)
      ..writeByte(12)
      ..write(obj.voiceCorrect)
      ..writeByte(13)
      ..write(obj.order)
      ..writeByte(14)
      ..write(obj.addedToReviewRound)
      ..writeByte(15)
      ..write(obj.reviewRoundPassed)
      ..writeByte(16)
      ..write(obj.imageUrl)
      ..writeByte(17)
      ..write(obj.audioUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VocabItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
