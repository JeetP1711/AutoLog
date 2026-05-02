// Feature: autolog-vehicle-manager
// Property 10: Dashboard totals accuracy
//
// For any set of fuel logs and expense logs for the current calendar month,
// the monthly fuel spend total equals the arithmetic sum of all totalPrice
// values for that month. The yearly total equals the sum of all fuel costs
// plus expense amounts for the current calendar year.
//
// Validates: Requirements 3.1, 3.4

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/models/models.dart';
import 'package:autolog/services/analytics_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

FuelLog _fuelLog(String id, DateTime date, double price) => FuelLog(
      id: id,
      vehicleId: 'v1',
      date: date,
      quantity: 40.0,
      totalPrice: price,
      odometerKm: 10000,
      isFullTank: true,
    );

ExpenseLog _expenseLog(String id, DateTime date, double amount) => ExpenseLog(
      id: id,
      vehicleId: 'v1',
      date: date,
      category: 'Toll',
      amount: amount,
    );

ServiceLog _serviceLog(String id, DateTime date, double cost) => ServiceLog(
      id: id,
      vehicleId: 'v1',
      date: date,
      serviceType: 'Oil Change',
      cost: cost,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  const service = AnalyticsService();
  final now = DateTime.now();

  group('AnalyticsService — Property 10: dashboard totals accuracy', () {
    // ── Property-based tests ────────────────────────────────────────────────

    test('monthly fuel spend equals arithmetic sum of current-month logs', () async {
      await property(
        forAll(
          list(
            float(min: 0.01, max: 10_000.0, withNaN: false, withInfinities: false),
            minLength: 0,
            maxLength: 20,
          ),
        ),
        (prices) {
          final logs = prices.asMap().entries.map((e) => _fuelLog(
                'f${e.key}',
                DateTime(now.year, now.month, 1 + (e.key % 28)),
                e.value,
              )).toList();

          final total = service.monthlyFuelSpend(logs);
          final expected = prices.fold(0.0, (sum, p) => sum + p);

          expect(total, closeTo(expected, 1e-6),
              reason: 'Monthly fuel spend must equal sum of all totalPrice values');
        },
      );
    });

    test('yearly total equals sum of fuel + service + expense for current year', () async {
      await property(
        forAll(
          combine3(
            list(float(min: 0.01, max: 5000.0, withNaN: false, withInfinities: false), minLength: 0, maxLength: 10),
            list(float(min: 0.01, max: 5000.0, withNaN: false, withInfinities: false), minLength: 0, maxLength: 10),
            list(float(min: 0.01, max: 5000.0, withNaN: false, withInfinities: false), minLength: 0, maxLength: 10),
            (fuelPrices, serviceCosts, expenseAmounts) => (
              fuelPrices: fuelPrices,
              serviceCosts: serviceCosts,
              expenseAmounts: expenseAmounts,
            ),
          ),
        ),
        (triple) {
          final fuelLogs = triple.fuelPrices.asMap().entries.map((e) =>
              _fuelLog('f${e.key}', DateTime(now.year, 1 + (e.key % 12), 1), e.value)).toList();
          final serviceLogs = triple.serviceCosts.asMap().entries.map((e) =>
              _serviceLog('s${e.key}', DateTime(now.year, 1 + (e.key % 12), 1), e.value)).toList();
          final expenseLogs = triple.expenseAmounts.asMap().entries.map((e) =>
              _expenseLog('e${e.key}', DateTime(now.year, 1 + (e.key % 12), 1), e.value)).toList();

          final total = service.yearlyTotalSpend(fuelLogs, serviceLogs, expenseLogs);
          final expectedFuel = triple.fuelPrices.fold(0.0, (s, p) => s + p);
          final expectedService = triple.serviceCosts.fold(0.0, (s, c) => s + c);
          final expectedExpense = triple.expenseAmounts.fold(0.0, (s, a) => s + a);
          final expected = expectedFuel + expectedService + expectedExpense;

          expect(total, closeTo(expected, 1e-6),
              reason: 'Yearly total must equal sum of fuel + service + expense');
        },
      );
    });

    // ── Edge cases ──────────────────────────────────────────────────────────

    test('monthly spend is 0 when no logs exist', () {
      expect(service.monthlyFuelSpend([]), 0.0);
    });

    test('monthly spend ignores logs from other months', () {
      final lastMonth = DateTime(now.year, now.month - 1 == 0 ? 12 : now.month - 1, 1);
      final logs = [_fuelLog('f1', lastMonth, 5000)];
      expect(service.monthlyFuelSpend(logs), 0.0);
    });

    test('yearly total is 0 when no logs exist', () {
      expect(service.yearlyTotalSpend([], [], []), 0.0);
    });

    test('yearly total ignores logs from other years', () {
      final lastYear = DateTime(now.year - 1, 6, 1);
      final fuelLogs = [_fuelLog('f1', lastYear, 9999)];
      expect(service.yearlyTotalSpend(fuelLogs, [], []), 0.0);
    });

    test('known example: 3 fuel logs of 1000 each = 3000 monthly', () {
      final logs = List.generate(3, (i) =>
          _fuelLog('f$i', DateTime(now.year, now.month, i + 1), 1000));
      expect(service.monthlyFuelSpend(logs), closeTo(3000, 0.01));
    });
  });
}
