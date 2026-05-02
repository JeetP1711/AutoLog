import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/document_repository.dart';
import '../data/expense_log_repository.dart';
import '../data/fuel_log_repository.dart';
import '../data/reminder_repository.dart';
import '../data/service_log_repository.dart';
import '../data/vehicle_repository.dart';
import '../models/models.dart';
import '../services/notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Repository providers
// ─────────────────────────────────────────────────────────────────────────────

final vehicleRepositoryProvider = Provider<VehicleRepository>(
  (_) => VehicleRepository(),
);
final fuelLogRepositoryProvider = Provider<FuelLogRepository>(
  (_) => FuelLogRepository(),
);
final serviceLogRepositoryProvider = Provider<ServiceLogRepository>(
  (_) => ServiceLogRepository(),
);
final expenseLogRepositoryProvider = Provider<ExpenseLogRepository>(
  (_) => ExpenseLogRepository(),
);
final documentRepositoryProvider = Provider<DocumentRepository>(
  (_) => DocumentRepository(),
);
final reminderRepositoryProvider = Provider<ReminderRepository>(
  (_) => ReminderRepository(),
);

// ─────────────────────────────────────────────────────────────────────────────
// Service providers
// ─────────────────────────────────────────────────────────────────────────────

final notificationServiceProvider = Provider<NotificationService>(
  (_) => NotificationService(),
);

// ─────────────────────────────────────────────────────────────────────────────
// VehicleNotifier
// ─────────────────────────────────────────────────────────────────────────────

class VehicleNotifier extends AsyncNotifier<List<Vehicle>> {
  @override
  Future<List<Vehicle>> build() async {
    return ref.read(vehicleRepositoryProvider).getAll();
  }

  /// Adds a new vehicle with a generated UUID.
  Future<void> addVehicle(Vehicle vehicle) async {
    final repo = ref.read(vehicleRepositoryProvider);
    await repo.save(vehicle);
    state = AsyncData(await repo.getAll());
  }

  /// Updates an existing vehicle.
  Future<void> updateVehicle(Vehicle vehicle) async {
    final repo = ref.read(vehicleRepositoryProvider);
    await repo.save(vehicle);
    state = AsyncData(await repo.getAll());
  }

  /// Deletes a vehicle and cascades to all associated records.
  Future<void> deleteVehicle(String vehicleId) async {
    final notifService = ref.read(notificationServiceProvider);
    final reminderRepo = ref.read(reminderRepositoryProvider);

    // Cancel all notifications for this vehicle
    await notifService.cancelAllForVehicle(vehicleId, reminderRepo);

    // Delete all associated records
    await ref.read(fuelLogRepositoryProvider).deleteByVehicle(vehicleId);
    await ref.read(serviceLogRepositoryProvider).deleteByVehicle(vehicleId);
    await ref.read(expenseLogRepositoryProvider).deleteByVehicle(vehicleId);
    await ref.read(documentRepositoryProvider).deleteByVehicle(vehicleId);
    await reminderRepo.deleteByVehicle(vehicleId);

    // Delete the vehicle itself
    await ref.read(vehicleRepositoryProvider).delete(vehicleId);
    state = AsyncData(await ref.read(vehicleRepositoryProvider).getAll());
  }
}

final vehicleProvider = AsyncNotifierProvider<VehicleNotifier, List<Vehicle>>(
  VehicleNotifier.new,
);

/// Convenience provider for a single vehicle by id.
final vehicleByIdProvider = Provider.family<Vehicle?, String>((ref, id) {
  return ref.watch(vehicleProvider).valueOrNull
      ?.firstWhere((v) => v.id == id, orElse: () => throw StateError('Vehicle $id not found'));
});

/// UUID generator instance.
const _uuid = Uuid();

/// Generates a new UUID v4.
String newId() => _uuid.v4();
