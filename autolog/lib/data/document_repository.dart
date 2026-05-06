import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'hive_boxes.dart';

/// Repository for [Document] records backed by a Hive box.
class DocumentRepository {
  Box<Document> get _box => HiveBoxes.documentBox;

  /// Returns all documents for [vehicleId] sorted by expiry date ascending.
  Future<List<Document>> getByVehicle(String vehicleId) async {
    return _box.values
        .where((d) => d.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  /// Returns all documents across all vehicles sorted by expiry date ascending.
  Future<List<Document>> getAll() async {
    return _box.values.toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  /// Returns the document with [id], or null if not found.
  Future<Document?> getById(String id) async => _box.get(id);

  /// Returns all documents expiring within [days] days from now.
  Future<List<Document>> getExpiringSoon({int days = 30}) async {
    final cutoff = DateTime.now().add(Duration(days: days));
    return _box.values
        .where((d) => d.expiryDate.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
  }

  /// Saves (inserts or updates) a document.
  Future<void> save(Document document) async {
    await _box.put(document.id, document);
  }

  /// Permanently deletes the document with [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Deletes all documents belonging to [vehicleId].
  Future<void> deleteByVehicle(String vehicleId) async {
    final keys = _box.values
        .where((d) => d.vehicleId == vehicleId)
        .map((d) => d.id)
        .toList();
    await _box.deleteAll(keys);
  }

  /// Emits the full list for [vehicleId] whenever the box changes.
  Stream<List<Document>> watchByVehicle(String vehicleId) async* {
    yield await getByVehicle(vehicleId);
    yield* _box.watch().map((_) => _box.values
        .where((d) => d.vehicleId == vehicleId)
        .toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate)));
  }

  /// Emits all documents whenever the box changes.
  Stream<List<Document>> watchAll() async* {
    yield await getAll();
    yield* _box.watch().map((_) => _box.values.toList()
      ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate)));
  }
}
