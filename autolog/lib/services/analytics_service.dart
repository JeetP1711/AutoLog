import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data transfer objects
// ─────────────────────────────────────────────────────────────────────────────

/// Monthly fuel spend data point.
class MonthlyFuelPoint {
  const MonthlyFuelPoint({required this.month, required this.year, required this.totalSpend});
  final int month;
  final int year;
  final double totalSpend;
  String get label => _monthName(month);
}

/// Mileage trend data point.
class MileageTrendPoint {
  const MileageTrendPoint({required this.date, required this.mileage});
  final DateTime date;
  final double mileage;
}

/// Expense category breakdown entry.
class ExpenseBreakdownEntry {
  const ExpenseBreakdownEntry({required this.category, required this.total});
  final String category;
  final double total;
}

/// Total ownership cost for a vehicle.
class OwnershipCostData {
  const OwnershipCostData({
    required this.vehicleId,
    required this.vehicleNickname,
    required this.fuelCost,
    required this.serviceCost,
    required this.expenseCost,
  });
  final String vehicleId;
  final String vehicleNickname;
  final double fuelCost;
  final double serviceCost;
  final double expenseCost;
  double get totalCost => fuelCost + serviceCost + expenseCost;
}

/// Yearly maintenance cost data point.
class YearlyMaintenancePoint {
  const YearlyMaintenancePoint({required this.year, required this.totalCost});
  final int year;
  final double totalCost;
}

// ─────────────────────────────────────────────────────────────────────────────
// AnalyticsService
// ─────────────────────────────────────────────────────────────────────────────

/// Pure computation service for analytics charts.
///
/// All methods are synchronous and have no I/O — they take pre-loaded lists
/// and return chart-ready data structures. No network calls are made.
class AnalyticsService {
  const AnalyticsService();

  // ── Monthly fuel spend ─────────────────────────────────────────────────────

  /// Returns monthly fuel spend for [year] from [fuelLogs].
  ///
  /// Returns 12 entries (one per month), with zero for months with no data.
  List<MonthlyFuelPoint> getMonthlyFuelSpend(
    List<FuelLog> fuelLogs,
    int year,
  ) {
    final byMonth = <int, double>{};
    for (final log in fuelLogs) {
      if (log.date.year == year) {
        byMonth[log.date.month] = (byMonth[log.date.month] ?? 0) + log.totalPrice;
      }
    }
    return List.generate(
      12,
      (i) => MonthlyFuelPoint(month: i + 1, year: year, totalSpend: byMonth[i + 1] ?? 0),
    );
  }

  // ── Yearly maintenance cost ────────────────────────────────────────────────

  /// Returns yearly maintenance cost (service + expense) for the last [years] years.
  List<YearlyMaintenancePoint> getYearlyMaintenanceCost(
    List<ServiceLog> serviceLogs,
    List<ExpenseLog> expenseLogs, {
    int years = 5,
  }) {
    final currentYear = DateTime.now().year;
    final result = <YearlyMaintenancePoint>[];

    for (int y = currentYear - years + 1; y <= currentYear; y++) {
      final serviceCost = serviceLogs
          .where((l) => l.date.year == y)
          .fold(0.0, (sum, l) => sum + l.cost);
      final expenseCost = expenseLogs
          .where((l) => l.date.year == y)
          .fold(0.0, (sum, l) => sum + l.amount);
      result.add(YearlyMaintenancePoint(year: y, totalCost: serviceCost + expenseCost));
    }
    return result;
  }

  // ── Mileage trend ──────────────────────────────────────────────────────────

  /// Returns mileage trend data points from [fuelLogs] (full-tank entries only).
  ///
  /// Returns an empty list if fewer than 2 data points exist.
  List<MileageTrendPoint> getMileageTrend(List<FuelLog> fuelLogs) {
    final points = fuelLogs
        .where((l) => l.isFullTank && l.mileage != null && l.mileage! > 0)
        .map((l) => MileageTrendPoint(date: l.date, mileage: l.mileage!))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return points;
  }

  // ── Expense breakdown ──────────────────────────────────────────────────────

  /// Returns expense category breakdown combining fuel, service, and expense logs.
  List<ExpenseBreakdownEntry> getExpenseBreakdown(
    List<ExpenseLog> expenseLogs,
    List<FuelLog> fuelLogs,
    List<ServiceLog> serviceLogs,
  ) {
    final totals = <String, double>{};

    for (final log in expenseLogs) {
      totals[log.category] = (totals[log.category] ?? 0) + log.amount;
    }

    final fuelTotal = fuelLogs.fold(0.0, (sum, l) => sum + l.totalPrice);
    if (fuelTotal > 0) {
      totals['Fuel'] = (totals['Fuel'] ?? 0) + fuelTotal;
    }

    final serviceTotal = serviceLogs.fold(0.0, (sum, l) => sum + l.cost);
    if (serviceTotal > 0) {
      totals['Service'] = (totals['Service'] ?? 0) + serviceTotal;
    }

    return totals.entries
        .map((e) => ExpenseBreakdownEntry(category: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));
  }

  // ── Ownership cost ─────────────────────────────────────────────────────────

  /// Returns total ownership cost for [vehicle].
  OwnershipCostData getOwnershipCost(
    Vehicle vehicle,
    List<FuelLog> fuelLogs,
    List<ServiceLog> serviceLogs,
    List<ExpenseLog> expenseLogs,
  ) {
    final fuelCost = fuelLogs
        .where((l) => l.vehicleId == vehicle.id)
        .fold(0.0, (sum, l) => sum + l.totalPrice);
    final serviceCost = serviceLogs
        .where((l) => l.vehicleId == vehicle.id)
        .fold(0.0, (sum, l) => sum + l.cost);
    final expenseCost = expenseLogs
        .where((l) => l.vehicleId == vehicle.id)
        .fold(0.0, (sum, l) => sum + l.amount);

    return OwnershipCostData(
      vehicleId: vehicle.id,
      vehicleNickname: vehicle.nickname,
      fuelCost: fuelCost,
      serviceCost: serviceCost,
      expenseCost: expenseCost,
    );
  }

  // ── Dashboard helpers ──────────────────────────────────────────────────────

  /// Returns total fuel spend for the current calendar month.
  double monthlyFuelSpend(List<FuelLog> fuelLogs) {
    final now = DateTime.now();
    return fuelLogs
        .where((l) => l.date.year == now.year && l.date.month == now.month)
        .fold(0.0, (sum, l) => sum + l.totalPrice);
  }

  /// Returns total spend (fuel + service + expenses) for the current year.
  double yearlyTotalSpend(
    List<FuelLog> fuelLogs,
    List<ServiceLog> serviceLogs,
    List<ExpenseLog> expenseLogs,
  ) {
    final year = DateTime.now().year;
    final fuel = fuelLogs
        .where((l) => l.date.year == year)
        .fold(0.0, (sum, l) => sum + l.totalPrice);
    final service = serviceLogs
        .where((l) => l.date.year == year)
        .fold(0.0, (sum, l) => sum + l.cost);
    final expense = expenseLogs
        .where((l) => l.date.year == year)
        .fold(0.0, (sum, l) => sum + l.amount);
    return fuel + service + expense;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

String _monthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return names[month - 1];
}
