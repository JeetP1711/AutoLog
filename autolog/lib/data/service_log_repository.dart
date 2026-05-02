import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'hive_boxes.dart';

/// Repository for [ServiceLog] records backed by a Hive box.
class ServiceLogRepository {
  Box<ServiceLog> get _box => HiveBoxes.serviceLogBox;

  /// Returns all service logs for [vehicleId] sorted by date descending.
  Future<List<ServiceLog>> getByVehicle(String vehicleId) async {
    return _box.values
        .where((l) => l.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns all service logs across all vehicles sorted by date descending.
  Future<List<ServiceLog>> getAll() async {
    return _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Returns the service log with [id], or null if not found.
  Future<ServiceLog?> getById(String id) async => _box.get(id);

  /// Saves (inserts or updates) a service log.
  Future<void> save(ServiceLog log) async {
    await _box.put(log.id, log);
  }

  /// Permanently deletes the service log with [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Deletes all service logs belonging to [vehicleId].
  Future<void> deleteByVehicle(String vehicleId) async {
    final keys = _box.values
        .where((l) => l.vehicleId == vehicleId)
        .map((l) => l.id)
        .toList();
    await _box.deleteAll(keys);
  }

  /// Emits the full list for [vehicleId] whenever the box changes.
  Stream<List<ServiceLog>> watchByVehicle(String vehicleId) {
    return _box.watch().map((_) => _box.values
        .where((l) => l.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }

  /// Emits all service logs whenever the box changes.
  Stream<List<ServiceLog>> watchAll() {
    return _box.watch().map((_) => _box.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date)));
  }
}
