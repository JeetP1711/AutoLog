// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VehicleAdapter extends TypeAdapter<Vehicle> {
  @override
  final int typeId = 0;

  @override
  Vehicle read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vehicle(
      id: fields[0] as String,
      nickname: fields[1] as String,
      numberPlate: fields[2] as String,
      brand: fields[3] as String,
      model: fields[4] as String,
      year: fields[5] as int,
      fuelType: fields[6] as FuelType,
      vehicleType: fields[7] as VehicleType,
      odometerKm: fields[8] as double,
      createdAt: fields[12] as DateTime,
      purchaseDate: fields[9] as DateTime?,
      photoPath: fields[10] as String?,
      notes: fields[11] as String?,
      customFuelType: fields[13] as String?,
      customFuelUnit: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Vehicle obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.numberPlate)
      ..writeByte(3)
      ..write(obj.brand)
      ..writeByte(4)
      ..write(obj.model)
      ..writeByte(5)
      ..write(obj.year)
      ..writeByte(6)
      ..write(obj.fuelType)
      ..writeByte(7)
      ..write(obj.vehicleType)
      ..writeByte(8)
      ..write(obj.odometerKm)
      ..writeByte(9)
      ..write(obj.purchaseDate)
      ..writeByte(10)
      ..write(obj.photoPath)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.customFuelType)
      ..writeByte(14)
      ..write(obj.customFuelUnit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
