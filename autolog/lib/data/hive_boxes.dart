import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';

/// Box name constants and initialisation for all Hive boxes used by AutoLog.
///
/// Call [HiveBoxes.init] once during app startup (after registering adapters)
/// to open every box. All repositories obtain their box via the typed getters.
abstract final class HiveBoxes {
  // ── Box name constants ────────────────────────────────────────────────────

  static const String vehicles = 'vehicles';
  static const String fuelLogs = 'fuel_logs';
  static const String serviceLogs = 'service_logs';
  static const String expenseLogs = 'expense_logs';
  static const String documents = 'documents';
  static const String reminders = 'reminders';

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Opens all six Hive boxes.
  ///
  /// Must be called after all TypeAdapters have been registered and after
  /// [Hive.initFlutter] has completed. Throws if any box fails to open.
  static Future<void> init() async {
    await Future.wait([
      Hive.openBox<Vehicle>(vehicles),
      Hive.openBox<FuelLog>(fuelLogs),
      Hive.openBox<ServiceLog>(serviceLogs),
      Hive.openBox<ExpenseLog>(expenseLogs),
      Hive.openBox<Document>(documents),
      Hive.openBox<Reminder>(reminders),
    ]);
  }

  // ── Typed box accessors ───────────────────────────────────────────────────

  /// Returns the already-open [Vehicle] box.
  static Box<Vehicle> get vehicleBox => Hive.box<Vehicle>(vehicles);

  /// Returns the already-open [FuelLog] box.
  static Box<FuelLog> get fuelLogBox => Hive.box<FuelLog>(fuelLogs);

  /// Returns the already-open [ServiceLog] box.
  static Box<ServiceLog> get serviceLogBox => Hive.box<ServiceLog>(serviceLogs);

  /// Returns the already-open [ExpenseLog] box.
  static Box<ExpenseLog> get expenseLogBox => Hive.box<ExpenseLog>(expenseLogs);

  /// Returns the already-open [Document] box.
  static Box<Document> get documentBox => Hive.box<Document>(documents);

  /// Returns the already-open [Reminder] box.
  static Box<Reminder> get reminderBox => Hive.box<Reminder>(reminders);
}
