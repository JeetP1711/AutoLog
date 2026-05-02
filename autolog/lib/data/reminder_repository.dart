import 'package:hive_flutter/hive_flutter.dart';

import '../models/models.dart';
import 'hive_boxes.dart';

/// Repository for [Reminder] records backed by a Hive box.
class ReminderRepository {
  Box<Reminder> get _box => HiveBoxes.reminderBox;

  /// Returns all non-dismissed reminders sorted by due date ascending.
  Future<List<Reminder>> getPending() async {
    return _box.values
        .where((r) => !r.isDismissed)
        .toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
  }

  /// Returns all reminders for [vehicleId].
  Future<List<Reminder>> getByVehicle(String vehicleId) async {
    return _box.values.where((r) => r.vehicleId == vehicleId).toList();
  }

  /// Returns all reminders whose [Reminder.sourceId] matches [sourceId].
  Future<List<Reminder>> getBySourceId(String sourceId) async {
    return _box.values.where((r) => r.sourceId == sourceId).toList();
  }

  /// Returns all reminders across all vehicles.
  Future<List<Reminder>> getAll() async => _box.values.toList();

  /// Returns the reminder with [id], or null if not found.
  Future<Reminder?> getById(String id) async => _box.get(id);

  /// Saves (inserts or updates) a reminder.
  Future<void> save(Reminder reminder) async {
    await _box.put(reminder.id, reminder);
  }

  /// Permanently deletes the reminder with [id].
  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  /// Deletes all reminders belonging to [vehicleId].
  Future<void> deleteByVehicle(String vehicleId) async {
    final keys = _box.values
        .where((r) => r.vehicleId == vehicleId)
        .map((r) => r.id)
        .toList();
    await _box.deleteAll(keys);
  }

  /// Deletes all reminders whose [Reminder.sourceId] matches [sourceId].
  Future<void> deleteBySourceId(String sourceId) async {
    final keys = _box.values
        .where((r) => r.sourceId == sourceId)
        .map((r) => r.id)
        .toList();
    await _box.deleteAll(keys);
  }

  /// Emits all pending reminders whenever the box changes.
  Stream<List<Reminder>> watchPending() {
    return _box.watch().map((_) => _box.values
        .where((r) => !r.isDismissed)
        .toList()
      ..sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      }));
  }

  /// Emits all reminders whenever the box changes.
  Stream<List<Reminder>> watchAll() {
    return _box.watch().map((_) => _box.values.toList());
  }
}
