// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceLogAdapter extends TypeAdapter<ServiceLog> {
  @override
  final int typeId = 2;

  @override
  ServiceLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceLog(
      id: fields[0] as String,
      vehicleId: fields[1] as String,
      date: fields[2] as DateTime,
      serviceType: fields[3] as String,
      cost: fields[4] as double,
      odometerKm: fields[5] as double?,
      garageName: fields[6] as String?,
      notes: fields[7] as String?,
      nextDueDate: fields[8] as DateTime?,
      nextDueOdometerKm: fields[9] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceLog obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.vehicleId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.serviceType)
      ..writeByte(4)
      ..write(obj.cost)
      ..writeByte(5)
      ..write(obj.odometerKm)
      ..writeByte(6)
      ..write(obj.garageName)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.nextDueDate)
      ..writeByte(9)
      ..write(obj.nextDueOdometerKm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
