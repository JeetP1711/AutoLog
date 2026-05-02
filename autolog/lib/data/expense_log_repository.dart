import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'hive_boxes.dart';

/// Repository for [ExpenseLog] records backed by a Hive box.
class ExpenseLogRepository {
  Box<ExpenseLog> get _box => HiveBoxes.expenseLogBox;

  /// Returns all expense logs for [vehicleId] sorted by date descending.
  Future<List<ExpenseLog>> getByVehicle(String vehicleId) async {
    return _box.values
        .where((l) => l.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns all expense logs across all vehicles sorted by date descending.
  Future<List<ExpenseLog>> getAll() async {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns the expense log with [id], or null if not found.
  Future<ExpenseLog?> getById(String id) async => _box.get(id);

  /// Saves (inserts or updates) an expense log.
  Future<void> save(ExpenseLog log) async {
    await _box.put(log.id, log);
  }

  /// Permanently deletes the expense log with [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Deletes all expense logs belonging to [vehicleId].
  Future<void> deleteByVehicle(String vehicleId) async {
    final keys = _box.values
        .where((l) => l.vehicleId == vehicleId)
        .map((l) => l.id)
        .toList();
    await _box.deleteAll(keys);
  }

  /// Emits the full list for [vehicleId] whenever the box changes.
  Stream<List<ExpenseLog>> watchByVehicle(String vehicleId) {
    return _box.watch().map((_) => _box.values
        .where((l) => l.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }

  /// Emits all expense logs whenever the box changes.
  Stream<List<ExpenseLog>> watchAll() {
    return _box.watch().map((_) => _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }
}
