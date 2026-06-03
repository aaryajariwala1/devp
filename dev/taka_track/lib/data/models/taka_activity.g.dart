// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'taka_activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TakaActivityAdapter extends TypeAdapter<TakaActivity> {
  @override
  final int typeId = 1;

  @override
  TakaActivity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TakaActivity(
      id: fields[0] as String,
      designId: fields[1] as String,
      designName: fields[2] as String,
      delta: fields[3] as int,
      type: fields[4] as String,
      note: fields[5] as String?,
      timestamp: fields[6] as DateTime,
      thumbnailUrl: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, TakaActivity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.designId)
      ..writeByte(2)
      ..write(obj.designName)
      ..writeByte(3)
      ..write(obj.delta)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.thumbnailUrl);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TakaActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}
