import 'package:hive/hive.dart';

part 'service_log.g.dart';

/// A vehicle service or maintenance entry.
@HiveType(typeId: 2)
class ServiceLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String vehicleId;

  @HiveField(2)
  final DateTime date;

  /// Service type — either a well-known enum value name or a custom string.
  @HiveField(3)
  final String serviceType;

  @HiveField(4)
  final double cost;

  /// Odometer reading at the time of service, always stored in kilometres.
  @HiveField(5)
  final double? odometerKm;

  @HiveField(6)
  final String? garageName;

  @HiveField(7)
  final String? notes;

  @HiveField(8)
  final DateTime? nextDueDate;

  @HiveField(9)
  final double? nextDueOdometerKm;

  const ServiceLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.serviceType,
    required this.cost,
    this.odometerKm,
    this.garageName,
    this.notes,
    this.nextDueDate,
    this.nextDueOdometerKm,
  });

  ServiceLog copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? serviceType,
    double? cost,
    double? odometerKm,
    String? garageName,
    String? notes,
    DateTime? nextDueDate,
    double? nextDueOdometerKm,
    bool clearOdometerKm = false,
    bool clearGarageName = false,
    bool clearNotes = false,
    bool clearNextDueDate = false,
    bool clearNextDueOdometerKm = false,
  }) {
    return ServiceLog(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      serviceType: serviceType ?? this.serviceType,
      cost: cost ?? this.cost,
      odometerKm: clearOdometerKm ? null : (odometerKm ?? this.odometerKm),
      garageName: clearGarageName ? null : (garageName ?? this.garageName),
      notes: clearNotes ? null : (notes ?? this.notes),
      nextDueDate: clearNextDueDate ? null : (nextDueDate ?? this.nextDueDate),
      nextDueOdometerKm: clearNextDueOdometerKm
          ? null
          : (nextDueOdometerKm ?? this.nextDueOdometerKm),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'serviceType': serviceType,
      'cost': cost,
      'odometerKm': odometerKm,
      'garageName': garageName,
      'notes': notes,
      'nextDueDate': nextDueDate?.toIso8601String(),
      'nextDueOdometerKm': nextDueOdometerKm,
    };
  }

  factory ServiceLog.fromJson(Map<String, dynamic> json) {
    return ServiceLog(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: DateTime.parse(json['date'] as String),
      serviceType: json['serviceType'] as String,
      cost: (json['cost'] as num).toDouble(),
      odometerKm: json['odometerKm'] != null
          ? (json['odometerKm'] as num).toDouble()
          : null,
      garageName: json['garageName'] as String?,
      notes: json['notes'] as String?,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.parse(json['nextDueDate'] as String)
          : null,
      nextDueOdometerKm: json['nextDueOdometerKm'] != null
          ? (json['nextDueOdometerKm'] as num).toDouble()
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceLog &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.date == date &&
        other.serviceType == serviceType &&
        other.cost == cost &&
        other.odometerKm == odometerKm &&
        other.garageName == garageName &&
        other.notes == notes &&
        other.nextDueDate == nextDueDate &&
        other.nextDueOdometerKm == nextDueOdometerKm;
  }

  @override
  int get hashCode => Object.hash(
        id,
        vehicleId,
        date,
        serviceType,
        cost,
        odometerKm,
        garageName,
        notes,
        nextDueDate,
        nextDueOdometerKm,
      );

  @override
  String toString() {
    return 'ServiceLog(id: $id, vehicleId: $vehicleId, date: $date, '
        'serviceType: $serviceType, cost: $cost, odometerKm: $odometerKm, '
        'garageName: $garageName, nextDueDate: $nextDueDate)';
  }
}
