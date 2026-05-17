// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringModelAdapter extends TypeAdapter<RecurringModel> {
  @override
  final int typeId = 3;

  @override
  RecurringModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringModel(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as String,
      categoryId: fields[4] as String,
      frequency: fields[5] as String,
      dayOfMonth: fields[6] as int,
      nextDueDate: fields[7] as DateTime,
      isActive: fields[8] as bool,
      note: fields[9] as String?,
      walletId: fields[10] as String?,
      createdAt: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.type)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.frequency)
      ..writeByte(6)
      ..write(obj.dayOfMonth)
      ..writeByte(7)
      ..write(obj.nextDueDate)
      ..writeByte(8)
      ..write(obj.isActive)
      ..writeByte(9)
      ..write(obj.note)
      ..writeByte(10)
      ..write(obj.walletId)
      ..writeByte(11)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
