// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScanRecordAdapter extends TypeAdapter<ScanRecord> {
  @override
  final typeId = 1;

  @override
  ScanRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ScanRecord(
      id: fields[0] as String,
      createdAt: fields[1] as DateTime,
      sourceLang: fields[2] as String,
      targetLang: fields[3] as String,
      originalText: fields[4] as String,
      translatedText: fields[5] as String,
      summaryJson: fields[6] as String?,
      originalImagePath: fields[7] as String?,
      renderedImagePath: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ScanRecord obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.sourceLang)
      ..writeByte(3)
      ..write(obj.targetLang)
      ..writeByte(4)
      ..write(obj.originalText)
      ..writeByte(5)
      ..write(obj.translatedText)
      ..writeByte(6)
      ..write(obj.summaryJson)
      ..writeByte(7)
      ..write(obj.originalImagePath)
      ..writeByte(8)
      ..write(obj.renderedImagePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
