// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionModel(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      type: fields[3] as String,
      categoryId: fields[4] as String,
      date: fields[5] as DateTime,
      note: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      walletId: fields[8] as String?,
      isDeleted: fields[9] as bool,
      deletedAt: fields[10] as DateTime?,
      tags: (fields[11] as List).cast<String>(),
      receiptPath: fields[12] as String?,
      workspaceId: fields[13] as String,
      warrantyDate: fields[14] as DateTime?,
      returnDate: fields[15] as DateTime?,
      splits: (fields[16] as List?)?.cast<SplitModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer
      ..writeByte(17)
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
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.note)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.walletId)
      ..writeByte(9)
      ..write(obj.isDeleted)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.tags)
      ..writeByte(12)
      ..write(obj.receiptPath)
      ..writeByte(13)
      ..write(obj.workspaceId)
      ..writeByte(14)
      ..write(obj.warrantyDate)
      ..writeByte(15)
      ..write(obj.returnDate)
      ..writeByte(16)
      ..write(obj.splits);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
