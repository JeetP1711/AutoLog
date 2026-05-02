import 'package:hive/hive.dart';

import 'enums.dart';

part 'reminder.g.dart';

/// A scheduled reminder associated with a vehicle.
@HiveType(typeId: 5)
class Reminder {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String vehicleId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final String body;

  @HiveField(4)
  final ReminderType reminderType;

  @HiveField(5)
  final DateTime? dueDate;

  /// Due odometer reading in kilometres.
  @HiveField(6)
  final double? dueOdometerKm;

  /// Foreign key to the source [Document] or [ServiceLog] that created this reminder.
  @HiveField(7)
  final String? sourceId;

  @HiveField(8)
  final bool isDismissed;

  @HiveField(9)
  final DateTime createdAt;

  const Reminder({
    required this.id,
    required this.vehicleId,
    required this.title,
    required this.body,
    required this.reminderType,
    required this.isDismissed,
    required this.createdAt,
    this.dueDate,
    this.dueOdometerKm,
    this.sourceId,
  });

  Reminder copyWith({
    String? id,
    String? vehicleId,
    String? title,
    String? body,
    ReminderType? reminderType,
    DateTime? dueDate,
    double? dueOdometerKm,
    String? sourceId,
    bool? isDismissed,
    DateTime? createdAt,
    bool clearDueDate = false,
    bool clearDueOdometerKm = false,
    bool clearSourceId = false,
  }) {
    return Reminder(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      title: title ?? this.title,
      body: body ?? this.body,
      reminderType: reminderType ?? this.reminderType,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueOdometerKm:
          clearDueOdometerKm ? null : (dueOdometerKm ?? this.dueOdometerKm),
      sourceId: clearSourceId ? null : (sourceId ?? this.sourceId),
      isDismissed: isDismissed ?? this.isDismissed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'title': title,
      'body': body,
      'reminderType': reminderType.name,
      'dueDate': dueDate?.toIso8601String(),
      'dueOdometerKm': dueOdometerKm,
      'sourceId': sourceId,
      'isDismissed': isDismissed,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      reminderType: ReminderType.values.byName(json['reminderType'] as String),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueOdometerKm: json['dueOdometerKm'] != null
          ? (json['dueOdometerKm'] as num).toDouble()
          : null,
      sourceId: json['sourceId'] as String?,
      isDismissed: json['isDismissed'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reminder &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.title == title &&
        other.body == body &&
        other.reminderType == reminderType &&
        other.dueDate == dueDate &&
        other.dueOdometerKm == dueOdometerKm &&
        other.sourceId == sourceId &&
        other.isDismissed == isDismissed &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        vehicleId,
        title,
        body,
        reminderType,
        dueDate,
        dueOdometerKm,
        sourceId,
        isDismissed,
        createdAt,
      );

  @override
  String toString() {
    return 'Reminder(id: $id, vehicleId: $vehicleId, title: $title, '
        'reminderType: $reminderType, dueDate: $dueDate, '
        'dueOdometerKm: $dueOdometerKm, isDismissed: $isDismissed)';
  }
}
