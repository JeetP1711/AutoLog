// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FuelTypeAdapter extends TypeAdapter<FuelType> {
  @override
  final int typeId = 10;

  @override
  FuelType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return FuelType.petrol;
      case 1:
        return FuelType.diesel;
      case 2:
        return FuelType.cng;
      case 3:
        return FuelType.electric;
      case 4:
        return FuelType.hybrid;
      case 5:
        return FuelType.lpg;
      case 6:
        return FuelType.hydrogen;
      case 7:
        return FuelType.custom;
      case 8:
        return FuelType.petrolCng;
      default:
        return FuelType.petrol;
    }
  }

  @override
  void write(BinaryWriter writer, FuelType obj) {
    switch (obj) {
      case FuelType.petrol:
        writer.writeByte(0);
        break;
      case FuelType.diesel:
        writer.writeByte(1);
        break;
      case FuelType.cng:
        writer.writeByte(2);
        break;
      case FuelType.electric:
        writer.writeByte(3);
        break;
      case FuelType.hybrid:
        writer.writeByte(4);
        break;
      case FuelType.lpg:
        writer.writeByte(5);
        break;
      case FuelType.hydrogen:
        writer.writeByte(6);
        break;
      case FuelType.custom:
        writer.writeByte(7);
        break;
      case FuelType.petrolCng:
        writer.writeByte(8);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FuelTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VehicleTypeAdapter extends TypeAdapter<VehicleType> {
  @override
  final int typeId = 11;

  @override
  VehicleType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return VehicleType.car;
      case 1:
        return VehicleType.bike;
      case 2:
        return VehicleType.scooter;
      case 3:
        return VehicleType.truck;
      case 4:
        return VehicleType.custom;
      default:
        return VehicleType.car;
    }
  }

  @override
  void write(BinaryWriter writer, VehicleType obj) {
    switch (obj) {
      case VehicleType.car:
        writer.writeByte(0);
        break;
      case VehicleType.bike:
        writer.writeByte(1);
        break;
      case VehicleType.scooter:
        writer.writeByte(2);
        break;
      case VehicleType.truck:
        writer.writeByte(3);
        break;
      case VehicleType.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DistanceUnitAdapter extends TypeAdapter<DistanceUnit> {
  @override
  final int typeId = 12;

  @override
  DistanceUnit read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return DistanceUnit.km;
      case 1:
        return DistanceUnit.miles;
      default:
        return DistanceUnit.km;
    }
  }

  @override
  void write(BinaryWriter writer, DistanceUnit obj) {
    switch (obj) {
      case DistanceUnit.km:
        writer.writeByte(0);
        break;
      case DistanceUnit.miles:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DistanceUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReminderTypeAdapter extends TypeAdapter<ReminderType> {
  @override
  final int typeId = 13;

  @override
  ReminderType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ReminderType.insuranceExpiry;
      case 1:
        return ReminderType.pucExpiry;
      case 2:
        return ReminderType.serviceDue;
      case 3:
        return ReminderType.odometerMilestone;
      case 4:
        return ReminderType.custom;
      default:
        return ReminderType.insuranceExpiry;
    }
  }

  @override
  void write(BinaryWriter writer, ReminderType obj) {
    switch (obj) {
      case ReminderType.insuranceExpiry:
        writer.writeByte(0);
        break;
      case ReminderType.pucExpiry:
        writer.writeByte(1);
        break;
      case ReminderType.serviceDue:
        writer.writeByte(2);
        break;
      case ReminderType.odometerMilestone:
        writer.writeByte(3);
        break;
      case ReminderType.custom:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
