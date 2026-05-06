import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'hive_boxes.dart';

/// Repository for [Vehicle] records backed by a Hive box.
///
/// All writes use the vehicle's [Vehicle.id] as the Hive key so lookups are
/// O(1). The [watchAll] stream re-emits the full list whenever any box event
/// occurs, allowing Riverpod providers to rebuild reactively.
class VehicleRepository {
  Box<Vehicle> get _box => HiveBoxes.vehicleBox;

  /// Returns all vehicles sorted by creation date descending.
  Future<List<Vehicle>> getAll() async {
    return _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Returns the vehicle with [id], or null if not found.
  Future<Vehicle?> getById(String id) async => _box.get(id);

  /// Saves (inserts or updates) a vehicle using its id as the key.
  Future<void> save(Vehicle vehicle) async {
    await _box.put(vehicle.id, vehicle);
  }

  /// Permanently deletes the vehicle with [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Emits the full vehicle list whenever the box changes.
  Stream<List<Vehicle>> watchAll() async* {
    yield await getAll();
    yield* _box.watch().map((_) => _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  }
}
