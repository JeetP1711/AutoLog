import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/analytics_service.dart';
import 'vehicle_provider.dart';

const _analytics = AnalyticsService();

/// Provides monthly fuel spend data for the given year.
final monthlyFuelSpendProvider =
    FutureProvider.family<List<MonthlyFuelPoint>, int>((ref, year) async {
  final logs = await ref.read(fuelLogRepositoryProvider).getAll();
  return _analytics.getMonthlyFuelSpend(logs, year);
});

/// Provides mileage trend data for a specific vehicle.
final mileageTrendProvider =
    FutureProvider.family<List<MileageTrendPoint>, String>((ref, vehicleId) async {
  final logs = await ref.read(fuelLogRepositoryProvider).getByVehicle(vehicleId);
  return _analytics.getMileageTrend(logs);
});

/// Provides expense breakdown across all vehicles.
final expenseBreakdownProvider =
    FutureProvider<List<ExpenseBreakdownEntry>>((ref) async {
  final fuelLogs = await ref.read(fuelLogRepositoryProvider).getAll();
  final serviceLogs = await ref.read(serviceLogRepositoryProvider).getAll();
  final expenseLogs = await ref.read(expenseLogRepositoryProvider).getAll();
  return _analytics.getExpenseBreakdown(expenseLogs, fuelLogs, serviceLogs);
});

/// Provides ownership cost for a specific vehicle.
final ownershipCostProvider =
    FutureProvider.family<OwnershipCostData, Vehicle>((ref, vehicle) async {
  final fuelLogs = await ref.read(fuelLogRepositoryProvider).getByVehicle(vehicle.id);
  final serviceLogs = await ref.read(serviceLogRepositoryProvider).getByVehicle(vehicle.id);
  final expenseLogs = await ref.read(expenseLogRepositoryProvider).getByVehicle(vehicle.id);
  return _analytics.getOwnershipCost(vehicle, fuelLogs, serviceLogs, expenseLogs);
});

/// Provides the monthly fuel spend total for the current month.
final currentMonthFuelSpendProvider = FutureProvider<double>((ref) async {
  final logs = await ref.read(fuelLogRepositoryProvider).getAll();
  return _analytics.monthlyFuelSpend(logs);
});

/// Provides the yearly total spend for the current year.
final currentYearTotalSpendProvider = FutureProvider<double>((ref) async {
  final fuelLogs = await ref.read(fuelLogRepositoryProvider).getAll();
  final serviceLogs = await ref.read(serviceLogRepositoryProvider).getAll();
  final expenseLogs = await ref.read(expenseLogRepositoryProvider).getAll();
  return _analytics.yearlyTotalSpend(fuelLogs, serviceLogs, expenseLogs);
});

/// Provides yearly maintenance cost data.
final yearlyMaintenanceCostProvider =
    FutureProvider<List<YearlyMaintenancePoint>>((ref) async {
  final serviceLogs = await ref.read(serviceLogRepositoryProvider).getAll();
  final expenseLogs = await ref.read(expenseLogRepositoryProvider).getAll();
  return _analytics.getYearlyMaintenanceCost(serviceLogs, expenseLogs);
});
