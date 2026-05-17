// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitModelAdapter extends TypeAdapter<SplitModel> {
  @override
  final int typeId = 8;

  @override
  SplitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitModel(
      categoryId: fields[0] as String,
      amount: fields[1] as double,
      note: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SplitModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.categoryId)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
