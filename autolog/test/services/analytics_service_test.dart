import 'package:flutter_test/flutter_test.dart';

import 'package:autolog/models/models.dart';
import 'package:autolog/services/analytics_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test fixtures
// ─────────────────────────────────────────────────────────────────────────────

Vehicle _vehicle(String id, {String nickname = 'Test Car'}) => Vehicle(
      id: id,
      nickname: nickname,
      numberPlate: 'MH01AB1234',
      brand: 'Honda',
      model: 'City',
      year: 2022,
      fuelType: FuelType.petrol,
      vehicleType: VehicleType.car,
      odometerKm: 10000,
      createdAt: DateTime(2022),
    );

FuelLog _fuelLog(
  String id,
  String vehicleId, {
  required DateTime date,
  required double price,
  double? mileage,
  bool isFullTank = true,
}) =>
    FuelLog(
      id: id,
      vehicleId: vehicleId,
      date: date,
      quantity: 40.0,
      totalPrice: price,
      odometerKm: 10000,
      isFullTank: isFullTank,
      mileage: mileage,
    );

ServiceLog _serviceLog(
  String id,
  String vehicleId, {
  required DateTime date,
  required double cost,
}) =>
    ServiceLog(
      id: id,
      vehicleId: vehicleId,
      date: date,
      serviceType: 'Oil Change',
      cost: cost,
    );

ExpenseLog _expenseLog(
  String id,
  String vehicleId, {
  required DateTime date,
  required double amount,
  String category = 'Toll',
}) =>
    ExpenseLog(
      id: id,
      vehicleId: vehicleId,
      date: date,
      category: category,
      amount: amount,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const service = AnalyticsService();

  group('AnalyticsService.getMonthlyFuelSpend', () {
    test('returns 12 entries for the given year', () {
      final result = service.getMonthlyFuelSpend([], 2024);
      expect(result.length, 12);
    });

    test('all entries are zero when no logs exist', () {
      final result = service.getMonthlyFuelSpend([], 2024);
      for (final point in result) {
        expect(point.totalSpend, 0.0);
      }
    });

    test('sums fuel spend correctly per month', () {
      final logs = [
        _fuelLog('f1', 'v1', date: DateTime(2024, 3, 10), price: 2000),
        _fuelLog('f2', 'v1', date: DateTime(2024, 3, 20), price: 1500),
        _fuelLog('f3', 'v1', date: DateTime(2024, 5, 5), price: 3000),
      ];
      final result = service.getMonthlyFuelSpend(logs, 2024);
      expect(result[2].totalSpend, closeTo(3500, 0.01)); // March (index 2)
      expect(result[4].totalSpend, closeTo(3000, 0.01)); // May (index 4)
      expect(result[0].totalSpend, 0.0); // January
    });

    test('ignores logs from other years', () {
      final logs = [
        _fuelLog('f1', 'v1', date: DateTime(2023, 6, 1), price: 5000),
      ];
      final result = service.getMonthlyFuelSpend(logs, 2024);
      for (final point in result) {
        expect(point.totalSpend, 0.0);
      }
    });
  });

  group('AnalyticsService.getMileageTrend', () {
    test('returns empty list when no full-tank logs exist', () {
      final result = service.getMileageTrend([]);
      expect(result, isEmpty);
    });

    test('returns only full-tank logs with mileage', () {
      final logs = [
        _fuelLog('f1', 'v1', date: DateTime(2024, 1, 1), price: 2000, mileage: 18.5),
        _fuelLog('f2', 'v1', date: DateTime(2024, 2, 1), price: 2000, isFullTank: false),
        _fuelLog('f3', 'v1', date: DateTime(2024, 3, 1), price: 2000, mileage: 20.0),
      ];
      final result = service.getMileageTrend(logs);
      expect(result.length, 2);
      expect(result[0].mileage, 18.5);
      expect(result[1].mileage, 20.0);
    });

    test('results are sorted by date ascending', () {
      final logs = [
        _fuelLog('f2', 'v1', date: DateTime(2024, 3, 1), price: 2000, mileage: 20.0),
        _fuelLog('f1', 'v1', date: DateTime(2024, 1, 1), price: 2000, mileage: 18.5),
      ];
      final result = service.getMileageTrend(logs);
      expect(result[0].date, DateTime(2024, 1, 1));
      expect(result[1].date, DateTime(2024, 3, 1));
    });
  });

  group('AnalyticsService.getExpenseBreakdown', () {
    test('returns empty list when no data', () {
      final result = service.getExpenseBreakdown([], [], []);
      expect(result, isEmpty);
    });

    test('includes fuel and service as categories', () {
      final fuelLogs = [
        _fuelLog('f1', 'v1', date: DateTime(2024, 1, 1), price: 3000),
      ];
      final serviceLogs = [
        _serviceLog('s1', 'v1', date: DateTime(2024, 2, 1), cost: 1500),
      ];
      final result = service.getExpenseBreakdown([], fuelLogs, serviceLogs);
      final categories = result.map((e) => e.category).toList();
      expect(categories, contains('Fuel'));
      expect(categories, contains('Service'));
    });

    test('sums expense categories correctly', () {
      final expenseLogs = [
        _expenseLog('e1', 'v1', date: DateTime(2024, 1, 1), amount: 200, category: 'Toll'),
        _expenseLog('e2', 'v1', date: DateTime(2024, 2, 1), amount: 300, category: 'Toll'),
        _expenseLog('e3', 'v1', date: DateTime(2024, 3, 1), amount: 500, category: 'Parking'),
      ];
      final result = service.getExpenseBreakdown(expenseLogs, [], []);
      final toll = result.firstWhere((e) => e.category == 'Toll');
      final parking = result.firstWhere((e) => e.category == 'Parking');
      expect(toll.total, closeTo(500, 0.01));
      expect(parking.total, closeTo(500, 0.01));
    });
  });

  group('AnalyticsService.getOwnershipCost', () {
    test('returns zero costs when no logs exist', () {
      final v = _vehicle('v1');
      final result = service.getOwnershipCost(v, [], [], []);
      expect(result.fuelCost, 0.0);
      expect(result.serviceCost, 0.0);
      expect(result.expenseCost, 0.0);
      expect(result.totalCost, 0.0);
    });

    test('sums costs correctly for the given vehicle', () {
      final v = _vehicle('v1');
      final fuelLogs = [
        _fuelLog('f1', 'v1', date: DateTime(2024, 1, 1), price: 2000),
        _fuelLog('f2', 'v2', date: DateTime(2024, 1, 1), price: 9999), // different vehicle
      ];
      final serviceLogs = [
        _serviceLog('s1', 'v1', date: DateTime(2024, 2, 1), cost: 1500),
      ];
      final expenseLogs = [
        _expenseLog('e1', 'v1', date: DateTime(2024, 3, 1), amount: 300),
      ];
      final result = service.getOwnershipCost(v, fuelLogs, serviceLogs, expenseLogs);
      expect(result.fuelCost, closeTo(2000, 0.01));
      expect(result.serviceCost, closeTo(1500, 0.01));
      expect(result.expenseCost, closeTo(300, 0.01));
      expect(result.totalCost, closeTo(3800, 0.01));
    });
  });

  group('AnalyticsService.monthlyFuelSpend', () {
    test('returns 0 when no logs for current month', () {
      expect(service.monthlyFuelSpend([]), 0.0);
    });

    test('sums only current month logs', () {
      final now = DateTime.now();
      final logs = [
        _fuelLog('f1', 'v1', date: DateTime(now.year, now.month, 5), price: 1000),
        _fuelLog('f2', 'v1', date: DateTime(now.year, now.month, 15), price: 2000),
        _fuelLog('f3', 'v1', date: DateTime(now.year - 1, now.month, 5), price: 9999),
      ];
      expect(service.monthlyFuelSpend(logs), closeTo(3000, 0.01));
    });
  });
}
