import 'package:hive/hive.dart';

part 'enums.g.dart';

/// Fuel type for a vehicle.
@HiveType(typeId: 10)
enum FuelType {
  @HiveField(0)
  petrol,

  @HiveField(1)
  diesel,

  @HiveField(2)
  cng,

  @HiveField(3)
  electric,

  @HiveField(4)
  hybrid,

  @HiveField(5)
  lpg,

  @HiveField(6)
  hydrogen,

  @HiveField(7)
  custom,
}

/// Vehicle body type.
@HiveType(typeId: 11)
enum VehicleType {
  @HiveField(0)
  car,

  @HiveField(1)
  bike,

  @HiveField(2)
  scooter,

  @HiveField(3)
  truck,

  @HiveField(4)
  custom,
}

/// Distance measurement unit.
@HiveType(typeId: 12)
enum DistanceUnit {
  @HiveField(0)
  km,

  @HiveField(1)
  miles,
}

/// Category of a reminder.
@HiveType(typeId: 13)
enum ReminderType {
  @HiveField(0)
  insuranceExpiry,

  @HiveField(1)
  pucExpiry,

  @HiveField(2)
  serviceDue,

  @HiveField(3)
  odometerMilestone,

  @HiveField(4)
  custom,
}
