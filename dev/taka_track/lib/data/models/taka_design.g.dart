// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taka_design.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TakaDesignAdapter extends TypeAdapter<TakaDesign> {
  @override
  final int typeId = 0;

  @override
  TakaDesign read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TakaDesign(
      id: fields[0] as String,
      designName: fields[1] as String,
      currentTakaCount: fields[2] as int,
      lowStockThreshold: fields[3] as int,
      thumbnailUrl: fields[4] as String?,
      createdAt: fields[5] as DateTime,
      updatedAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TakaDesign obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.designName)
      ..writeByte(2)
      ..write(obj.currentTakaCount)
      ..writeByte(3)
      ..write(obj.lowStockThreshold)
      ..writeByte(4)
      ..write(obj.thumbnailUrl)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.updatedAt);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TakaDesignAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
