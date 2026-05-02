// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseLogAdapter extends TypeAdapter<ExpenseLog> {
  @override
  final int typeId = 3;

  @override
  ExpenseLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseLog(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      category: fields[3] as String,
      amount: fields[4] as double,
      notes: fields[5] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseLog obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
