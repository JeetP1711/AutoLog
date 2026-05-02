import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'hive_boxes.dart';

/// Repository for [FuelLog] records backed by a Hive box.
class FuelLogRepository {
  Box<FuelLog> get _box => HiveBoxes.fuelLogBox;

  /// Returns all fuel logs for [vehicleId] sorted by date ascending.
  Future<List<FuelLog>> getByVehicle(String vehicleId) async {
    return _box.values
        .where((l) => l.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Returns all fuel logs across all vehicles sorted by date descending.
  Future<List<FuelLog>> getAll() async {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns the fuel log with [id], or null if not found.
  Future<FuelLog?> getById(String id) async => _box.get(id);

  /// Saves (inserts or updates) a fuel log.
  Future<void> save(FuelLog log) async {
    await _box.put(log.id, log);
  }

  /// Permanently deletes the fuel log with [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Deletes all fuel logs belonging to [vehicleId].
  Future<void> deleteByVehicle(String vehicleId) async {
    final keys = _box.values
        .where((l) => l.vehicleId == vehicleId)
        .map((l) => l.id)
        .toList();
    await _box.deleteAll(keys);
  }

  /// Emits the full list for [vehicleId] whenever the box changes.
  Stream<List<FuelLog>> watchByVehicle(String vehicleId) {
    return _box.watch().map((_) => _box.values
        .where((l) => l.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date)));
  }

  /// Emits all fuel logs whenever the box changes.
  Stream<List<FuelLog>> watchAll() {
    return _box.watch().map((_) => _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }
}
