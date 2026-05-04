import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/analytics_service.dart';
import 'vehicle_provider.dart';

const _analytics = AnalyticsService();

// ─────────────────────────────────────────────────────────────────────────────
// Raw data providers — watch Hive boxes via stream so they stay fresh
// ─────────────────────────────────────────────────────────────────────────────

/// All fuel logs — reactive stream provider.
final allFuelLogsStreamProvider = StreamProvider<List<FuelLog>>((ref) {
  return ref.read(fuelLogRepositoryProvider).watchAll();
});

/// All service logs — reactive stream provider.
final allServiceLogsStreamProvider = StreamProvider<List<ServiceLog>>((ref) {
  return ref.read(serviceLogRepositoryProvider).watchAll();
});

/// All expense logs — reactive stream provider.
final allExpenseLogsStreamProvider = StreamProvider<List<ExpenseLog>>((ref) {
  return ref.read(expenseLogRepositoryProvider).watchAll();
});

// Keep the FutureProvider aliases for backward compatibility with logs screen
final allFuelLogsProvider = FutureProvider<List<FuelLog>>((ref) async {
  return ref.read(fuelLogRepositoryProvider).getAll();
});

final allServiceLogsProvider = FutureProvider<List<ServiceLog>>((ref) async {
  return ref.read(serviceLogRepositoryProvider).getAll();
});

final allExpenseLogsProvider = FutureProvider<List<ExpenseLog>>((ref) async {
  return ref.read(expenseLogRepositoryProvider).getAll();
});

// ─────────────────────────────────────────────────────────────────────────────
// Analytics providers — derived from stream providers so they auto-update
// ─────────────────────────────────────────────────────────────────────────────

/// Monthly fuel spend for the given year — updates when fuel logs change.
final monthlyFuelSpendProvider =
    Provider.family<AsyncValue<List<MonthlyFuelPoint>>, int>((ref, year) {
  final logsAsync = ref.watch(allFuelLogsStreamProvider);
  return logsAsync.whenData(
    (logs) => _analytics.getMonthlyFuelSpend(logs, year),
  );
});

/// Mileage trend for a specific vehicle — updates when fuel logs change.
final mileageTrendProvider =
    Provider.family<AsyncValue<List<MileageTrendPoint>>, String>((ref, vehicleId) {
  final logsAsync = ref.watch(allFuelLogsStreamProvider);
  return logsAsync.whenData(
    (logs) => _analytics.getMileageTrend(
      logs.where((l) => l.vehicleId == vehicleId).toList(),
    ),
  );
});

/// Expense breakdown — updates when any log type changes.
final expenseBreakdownProvider =
    Provider<AsyncValue<List<ExpenseBreakdownEntry>>>((ref) {
  final fuelAsync = ref.watch(allFuelLogsStreamProvider);
  final serviceAsync = ref.watch(allServiceLogsStreamProvider);
  final expenseAsync = ref.watch(allExpenseLogsStreamProvider);

  if (fuelAsync.isLoading || serviceAsync.isLoading || expenseAsync.isLoading) {
    return const AsyncValue.loading();
  }
  if (fuelAsync.hasError) return AsyncValue.error(fuelAsync.error!, fuelAsync.stackTrace!);

  final fuelLogs = fuelAsync.valueOrNull ?? [];
  final serviceLogs = serviceAsync.valueOrNull ?? [];
  final expenseLogs = expenseAsync.valueOrNull ?? [];

  return AsyncValue.data(
    _analytics.getExpenseBreakdown(expenseLogs, fuelLogs, serviceLogs),
  );
});

/// Yearly maintenance cost — updates when service/expense logs change.
final yearlyMaintenanceCostProvider =
    Provider<AsyncValue<List<YearlyMaintenancePoint>>>((ref) {
  final serviceAsync = ref.watch(allServiceLogsStreamProvider);
  final expenseAsync = ref.watch(allExpenseLogsStreamProvider);

  if (serviceAsync.isLoading || expenseAsync.isLoading) {
    return const AsyncValue.loading();
  }

  final serviceLogs = serviceAsync.valueOrNull ?? [];
  final expenseLogs = expenseAsync.valueOrNull ?? [];

  return AsyncValue.data(
    _analytics.getYearlyMaintenanceCost(serviceLogs, expenseLogs),
  );
});

/// Monthly fuel spend total for the current month — reactive.
final currentMonthFuelSpendProvider = Provider<AsyncValue<double>>((ref) {
  final logsAsync = ref.watch(allFuelLogsStreamProvider);
  return logsAsync.whenData((logs) => _analytics.monthlyFuelSpend(logs));
});

/// Yearly total spend — reactive.
final currentYearTotalSpendProvider = Provider<AsyncValue<double>>((ref) {
  final fuelAsync = ref.watch(allFuelLogsStreamProvider);
  final serviceAsync = ref.watch(allServiceLogsStreamProvider);
  final expenseAsync = ref.watch(allExpenseLogsStreamProvider);

  if (fuelAsync.isLoading || serviceAsync.isLoading || expenseAsync.isLoading) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(_analytics.yearlyTotalSpend(
    fuelAsync.valueOrNull ?? [],
    serviceAsync.valueOrNull ?? [],
    expenseAsync.valueOrNull ?? [],
  ));
});

/// Ownership cost for a specific vehicle — reactive.
final ownershipCostProvider =
    Provider.family<AsyncValue<OwnershipCostData>, Vehicle>((ref, vehicle) {
  final fuelAsync = ref.watch(allFuelLogsStreamProvider);
  final serviceAsync = ref.watch(allServiceLogsStreamProvider);
  final expenseAsync = ref.watch(allExpenseLogsStreamProvider);

  if (fuelAsync.isLoading || serviceAsync.isLoading || expenseAsync.isLoading) {
    return const AsyncValue.loading();
  }

  return AsyncValue.data(_analytics.getOwnershipCost(
    vehicle,
    (fuelAsync.valueOrNull ?? []).where((l) => l.vehicleId == vehicle.id).toList(),
    (serviceAsync.valueOrNull ?? []).where((l) => l.vehicleId == vehicle.id).toList(),
    (expenseAsync.valueOrNull ?? []).where((l) => l.vehicleId == vehicle.id).toList(),
  ));
});
