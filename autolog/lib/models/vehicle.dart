import 'package:hive/hive.dart';

import 'enums.dart';

part 'vehicle.g.dart';

/// Represents a vehicle owned by the user.
@HiveType(typeId: 0)
class Vehicle {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nickname;

  @HiveField(2)
  final String numberPlate;

  @HiveField(3)
  final String brand;

  @HiveField(4)
  final String model;

  @HiveField(5)
  final int year;

  @HiveField(6)
  final FuelType fuelType;

  @HiveField(7)
  final VehicleType vehicleType;

  /// Odometer reading always stored in kilometres.
  @HiveField(8)
  final double odometerKm;

  @HiveField(9)
  final DateTime? purchaseDate;

  @HiveField(10)
  final String? photoPath;

  @HiveField(11)
  final String? notes;

  @HiveField(12)
  final DateTime createdAt;

  /// Used when [fuelType] == [FuelType.custom].
  @HiveField(13)
  final String? customFuelType;

  /// Used when [fuelType] == [FuelType.custom].
  @HiveField(14)
  final String? customFuelUnit;

  const Vehicle({
    required this.id,
    required this.nickname,
    required this.numberPlate,
    required this.brand,
    required this.model,
    required this.year,
    required this.fuelType,
    required this.vehicleType,
    required this.odometerKm,
    required this.createdAt,
    this.purchaseDate,
    this.photoPath,
    this.notes,
    this.customFuelType,
    this.customFuelUnit,
  });

  Vehicle copyWith({
    String? id,
    String? nickname,
    String? numberPlate,
    String? brand,
    String? model,
    int? year,
    FuelType? fuelType,
    VehicleType? vehicleType,
    double? odometerKm,
    DateTime? purchaseDate,
    String? photoPath,
    String? notes,
    DateTime? createdAt,
    String? customFuelType,
    String? customFuelUnit,
    bool clearPurchaseDate = false,
    bool clearPhotoPath = false,
    bool clearNotes = false,
    bool clearCustomFuelType = false,
    bool clearCustomFuelUnit = false,
  }) {
    return Vehicle(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      numberPlate: numberPlate ?? this.numberPlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      fuelType: fuelType ?? this.fuelType,
      vehicleType: vehicleType ?? this.vehicleType,
      odometerKm: odometerKm ?? this.odometerKm,
      purchaseDate: clearPurchaseDate ? null : (purchaseDate ?? this.purchaseDate),
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
      customFuelType: clearCustomFuelType ? null : (customFuelType ?? this.customFuelType),
      customFuelUnit: clearCustomFuelUnit ? null : (customFuelUnit ?? this.customFuelUnit),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nickname': nickname,
      'numberPlate': numberPlate,
      'brand': brand,
      'model': model,
      'year': year,
      'fuelType': fuelType.name,
      'vehicleType': vehicleType.name,
      'odometerKm': odometerKm,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'photoPath': photoPath,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'customFuelType': customFuelType,
      'customFuelUnit': customFuelUnit,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      nickname: json['nickname'] as String,
      numberPlate: json['numberPlate'] as String,
      brand: json['brand'] as String,
      model: json['model'] as String,
      year: json['year'] as int,
      fuelType: FuelType.values.byName(json['fuelType'] as String),
      vehicleType: VehicleType.values.byName(json['vehicleType'] as String),
      odometerKm: (json['odometerKm'] as num).toDouble(),
      purchaseDate: json['purchaseDate'] != null
          ? DateTime.parse(json['purchaseDate'] as String)
          : null,
      photoPath: json['photoPath'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      customFuelType: json['customFuelType'] as String?,
      customFuelUnit: json['customFuelUnit'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vehicle &&
        other.id == id &&
        other.nickname == nickname &&
        other.numberPlate == numberPlate &&
        other.brand == brand &&
        other.model == model &&
        other.year == year &&
        other.fuelType == fuelType &&
        other.vehicleType == vehicleType &&
        other.odometerKm == odometerKm &&
        other.purchaseDate == purchaseDate &&
        other.photoPath == photoPath &&
        other.notes == notes &&
        other.createdAt == createdAt &&
        other.customFuelType == customFuelType &&
        other.customFuelUnit == customFuelUnit;
  }

  @override
  int get hashCode => Object.hash(
        id,
        nickname,
        numberPlate,
        brand,
        model,
        year,
        fuelType,
        vehicleType,
        odometerKm,
        purchaseDate,
        photoPath,
        notes,
        createdAt,
        customFuelType,
        customFuelUnit,
      );

  @override
  String toString() {
    return 'Vehicle(id: $id, nickname: $nickname, numberPlate: $numberPlate, '
        'brand: $brand, model: $model, year: $year, fuelType: $fuelType, '
        'vehicleType: $vehicleType, odometerKm: $odometerKm, '
        'purchaseDate: $purchaseDate, createdAt: $createdAt)';
  }
}
