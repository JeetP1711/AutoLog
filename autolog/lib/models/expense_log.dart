import 'package:hive/hive.dart';

part 'expense_log.g.dart';

/// A miscellaneous expense entry for a vehicle (e.g. insurance, parking, tax).
@HiveType(typeId: 3)
class ExpenseLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String vehicleId;

  @HiveField(2)
  final DateTime date;

  /// Expense category — either a well-known enum value name or a custom string.
  @HiveField(3)
  final String category;

  @HiveField(4)
  final double amount;

  @HiveField(5)
  final String? notes;

  const ExpenseLog({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.amount,
    this.notes,
  });

  ExpenseLog copyWith({
    String? id,
    String? vehicleId,
    DateTime? date,
    String? category,
    double? amount,
    String? notes,
    bool clearNotes = false,
  }) {
    return ExpenseLog(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      notes: clearNotes ? null : (notes ?? this.notes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'date': date.toIso8601String(),
      'category': category,
      'amount': amount,
      'notes': notes,
    };
  }

  factory ExpenseLog.fromJson(Map<String, dynamic> json) {
    return ExpenseLog(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      amount: (json['amount'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExpenseLog &&
        other.id == id &&
        other.vehicleId == vehicleId &&
        other.date == date &&
        other.category == category &&
        other.amount == amount &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(id, vehicleId, date, category, amount, notes);

  @override
  String toString() {
    return 'ExpenseLog(id: $id, vehicleId: $vehicleId, date: $date, '
        'category: $category, amount: $amount, notes: $notes)';
  }
}
