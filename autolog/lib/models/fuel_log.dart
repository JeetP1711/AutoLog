import 'package:hive/hive.dart';

part 'fuel_log.g.dart';

/// A single fuel refill entry for a vehicle.
@HiveType(typeId: 1)
class FuelLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String vehicleId;

  @HiveField(2)
  final DateTime date;

  /// Quantity of fuel added (litres, kg, or kWh depending on fuel type).
  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final double totalPrice;

  /// Odometer reading at the time of refill, always stored in kilometres.
  @HiveField(5)
  final double odometerKm;

  @HiveField(6)
  final bool isFullTank;

  @HiveField(7)
  final String? stationName;

  @HiveField(8)
  final String? notes;

  /// Computed and cached mileage (km/litre, km/kg, or km/kWh).
  @HiveField(9)
  final double? mileage;

  /// Computed and cached distance since the previous full-tank log.
  @HiveField(10)
  final double? distanceKm;

  const FuelLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.quantity,
    required this.totalPrice,
    required this.odometerKm,
    required this.isFullTank,
    this.stationName,
    this.notes,
    this.mileage,
    this.distanceKm,
  });

  FuelLog copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    double? quantity,
    double? totalPrice,
    double? odometerKm,
    bool? isFullTank,
    String? stationName,
    String? notes,
    double? mileage,
    double? distanceKm,
    bool clearStationName = false,
    bool clearNotes = false,
    bool clearMileage = false,
    bool clearDistanceKm = false,
  }) {
    return FuelLog(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      totalPrice: totalPrice ?? this.totalPrice,
      odometerKm: odometerKm ?? this.odometerKm,
      isFullTank: isFullTank ?? this.isFullTank,
      stationName: clearStationName ? null : (stationName ?? this.stationName),
      notes: clearNotes ? null : (notes ?? this.notes),
      mileage: clearMileage ? null : (mileage ?? this.mileage),
      distanceKm: clearDistanceKm ? null : (distanceKm ?? this.distanceKm),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'quantity': quantity,
      'totalPrice': totalPrice,
      'odometerKm': odometerKm,
      'isFullTank': isFullTank,
      'stationName': stationName,
      'notes': notes,
      'mileage': mileage,
      'distanceKm': distanceKm,
    };
  }

  factory FuelLog.fromJson(Map<String, dynamic> json) {
    return FuelLog(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: DateTime.parse(json['date'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      totalPrice: (json['totalPrice'] as num).toDouble(),
      odometerKm: (json['odometerKm'] as num).toDouble(),
      isFullTank: json['isFullTank'] as bool,
      stationName: json['stationName'] as String?,
      notes: json['notes'] as String?,
      mileage: json['mileage'] != null ? (json['mileage'] as num).toDouble() : null,
      distanceKm: json['distanceKm'] != null ? (json['distanceKm'] as num).toDouble() : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FuelLog &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.date == date &&
        other.quantity == quantity &&
        other.totalPrice == totalPrice &&
        other.odometerKm == odometerKm &&
        other.isFullTank == isFullTank &&
        other.stationName == stationName &&
        other.notes == notes &&
        other.mileage == mileage &&
        other.distanceKm == distanceKm;
  }

  @override
  int get hashCode => Object.hash(
        id,
        vehicleId,
        date,
        quantity,
        totalPrice,
        odometerKm,
        isFullTank,
        stationName,
        notes,
        mileage,
        distanceKm,
      );

  @override
  String toString() {
    return 'FuelLog(id: $id, vehicleId: $vehicleId, date: $date, '
        'quantity: $quantity, totalPrice: $totalPrice, odometerKm: $odometerKm, '
        'isFullTank: $isFullTank, mileage: $mileage, distanceKm: $distanceKm)';
  }
}
