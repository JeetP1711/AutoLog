import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../utils/mileage_calculator.dart';
import 'vehicle_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// FuelLogNotifier (per-vehicle)
// ─────────────────────────────────────────────────────────────────────────────

class FuelLogNotifier extends FamilyAsyncNotifier<List<FuelLog>, String> {
  @override
  Future<List<FuelLog>> build(String vehicleId) async {
    return ref.read(fuelLogRepositoryProvider).getByVehicle(vehicleId);
  }

  /// Saves a fuel log, computing distance and mileage from the previous entry.
  Future<void> saveFuelLog(FuelLog log, FuelType fuelType) async {
    final repo = ref.read(fuelLogRepositoryProvider);
    final existing = await repo.getByVehicle(log.vehicleId);

    // Find the previous log (sorted ascending by date)
    final sorted = [...existing]..sort((a, b) => a.date.compareTo(b.date));
    final prevIndex = sorted.indexWhere((l) => l.id == log.id) - 1;
    final prevLog = prevIndex >= 0 ? sorted[prevIndex] : null;

    // If this is a new log, find the last entry before this log's date
    FuelLog? previousLog = prevLog;
    if (previousLog == null && existing.isNotEmpty) {
      final before = existing
          .where((l) => l.date.isBefore(log.date) && l.id != log.id)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      previousLog = before.isNotEmpty ? before.first : null;
    }

    final distanceKm = previousLog != null
        ? MileageCalculator.distance(log.odometerKm, previousLog.odometerKm)
        : null;

    final mileage = log.isFullTank
        ? MileageCalculator.calculate(
            distanceKm: distanceKm,
            quantity: log.quantity,
            fuelType: fuelType,
          )
        : null;

    final enriched = log.copyWith(
      distanceKm: distanceKm,
      mileage: mileage,
      clearDistanceKm: distanceKm == null,
      clearMileage: mileage == null,
    );

    await repo.save(enriched);
    state = AsyncData(await repo.getByVehicle(log.vehicleId));
  }

  /// Deletes a fuel log and recalculates the subsequent entry's mileage.
  Future<void> deleteFuelLog(String logId, FuelType fuelType) async {
    final repo = ref.read(fuelLogRepositoryProvider);
    final vehicleId = arg;
    final existing = await repo.getByVehicle(vehicleId);
    final sorted = [...existing]..sort((a, b) => a.date.compareTo(b.date));

    final deletedIndex = sorted.indexWhere((l) => l.id == logId);
    await repo.delete(logId);

    // Recalculate the entry immediately after the deleted one
    if (deletedIndex >= 0 && deletedIndex < sorted.length - 1) {
      final next = sorted[deletedIndex + 1];
      final prev = deletedIndex > 0 ? sorted[deletedIndex - 1] : null;

      final distanceKm = prev != null
          ? MileageCalculator.distance(next.odometerKm, prev.odometerKm)
          : null;
      final mileage = next.isFullTank
          ? MileageCalculator.calculate(
              distanceKm: distanceKm,
              quantity: next.quantity,
              fuelType: fuelType,
            )
          : null;

      final updated = next.copyWith(
        distanceKm: distanceKm,
        mileage: mileage,
        clearDistanceKm: distanceKm == null,
        clearMileage: mileage == null,
      );
      await repo.save(updated);
    }

    state = AsyncData(await repo.getByVehicle(vehicleId));
  }
}

final fuelLogProvider =
    AsyncNotifierProviderFamily<FuelLogNotifier, List<FuelLog>, String>(
  FuelLogNotifier.new,
);

/// Provider for all fuel logs across all vehicles (for analytics/logs screen).
final allFuelLogsProvider = FutureProvider<List<FuelLog>>((ref) async {
  return ref.read(fuelLogRepositoryProvider).getAll();
});
