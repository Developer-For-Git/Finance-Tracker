// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction_history_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TransactionHistoryModelAdapter
    extends TypeAdapter<TransactionHistoryModel> {
  @override
  final int typeId = 6;

  @override
  TransactionHistoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TransactionHistoryModel(
      id: fields[0] as String,
      transactionId: fields[1] as String,
      action: fields[2] as String,
      details: fields[3] as String,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TransactionHistoryModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transactionId)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.details)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionHistoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
