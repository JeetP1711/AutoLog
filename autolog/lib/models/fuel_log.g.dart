// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fuel_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelLogAdapter extends TypeAdapter<FuelLog> {
  @override
  final int typeId = 1;

  @override
  FuelLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FuelLog(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      quantity: fields[3] as double,
      totalPrice: fields[4] as double,
      odometerKm: fields[5] as double,
      isFullTank: fields[6] as bool,
      stationName: fields[7] as String?,
      notes: fields[8] as String?,
      mileage: fields[9] as double?,
      distanceKm: fields[10] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, FuelLog obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.totalPrice)
      ..writeByte(5)
      ..write(obj.odometerKm)
      ..writeByte(6)
      ..write(obj.isFullTank)
      ..writeByte(7)
      ..write(obj.stationName)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.mileage)
      ..writeByte(10)
      ..write(obj.distanceKm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
