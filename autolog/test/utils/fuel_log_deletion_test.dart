// Feature: autolog-vehicle-manager
// Property 6: Fuel log deletion triggers correct mileage recalculation
//
// For any ordered sequence of 3+ fuel logs with strictly increasing odometers,
// deleting the middle entry causes the following entry's mileage to be
// recalculated as (followingOdometer − precedingOdometer) / followingQuantity.
//
// Validates: Requirements 7.7

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/models/enums.dart';
import 'package:autolog/utils/mileage_calculator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper: simulate the recalculation logic from FuelLogNotifier.deleteFuelLog
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a minimal fuel log for testing purposes.
class _FuelEntry {
  const _FuelEntry({
    required this.odometer,
    required this.quantity,
    this.mileage,
    this.distanceKm,
  });
  final double odometer;
  final double quantity;
  final double? mileage;
  final double? distanceKm;
}

/// Simulates deleting the entry at [deleteIndex] from [entries] and
/// recalculating the mileage of the entry immediately after it.
///
/// Returns the recalculated mileage of the entry that was after the deleted one.
double? simulateDeletion(
  List<_FuelEntry> entries,
  int deleteIndex,
  FuelType fuelType,
) {
  assert(deleteIndex > 0 && deleteIndex < entries.length - 1,
      'deleteIndex must be a middle entry');

  final prev = entries[deleteIndex - 1];
  final next = entries[deleteIndex + 1];

  final distanceKm = MileageCalculator.distance(next.odometer, prev.odometer);
  return MileageCalculator.calculate(
    distanceKm: distanceKm,
    quantity: next.quantity,
    fuelType: fuelType,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('MileageCalculator — Property 6: deletion recalculation', () {
    test('deleting middle entry recalculates following entry mileage', () async {
      await property(
        forAll(
          combine2(
            // Generate 3 strictly increasing odometer values
            float(min: 0.0, max: 100_000.0, withNaN: false, withInfinities: false),
            combine2(
              float(min: 10.0, max: 500.0, withNaN: false, withInfinities: false),
              float(min: 10.0, max: 500.0, withNaN: false, withInfinities: false),
              (d1, d2) => (d1: d1, d2: d2),
            ),
            (base, deltas) => (base: base, d1: deltas.d1, d2: deltas.d2),
          ),
        ),
        (triple) {
          final odo0 = triple.base;
          final odo1 = odo0 + triple.d1; // middle entry
          final odo2 = odo1 + triple.d2; // following entry

          const quantity = 40.0;
          const fuelType = FuelType.petrol;

          final entries = [
            _FuelEntry(odometer: odo0, quantity: quantity),
            _FuelEntry(odometer: odo1, quantity: quantity), // will be deleted
            _FuelEntry(odometer: odo2, quantity: quantity),
          ];

          final recalculated = simulateDeletion(entries, 1, fuelType);

          // Expected: (odo2 - odo0) / quantity
          final expectedDistance = odo2 - odo0;
          final expectedMileage = expectedDistance / quantity;

          expect(recalculated, isNotNull,
              reason: 'Mileage must be calculable after deletion');
          expect(recalculated!, closeTo(expectedMileage, 1e-9),
              reason: 'Recalculated mileage must equal (odo2-odo0)/quantity');
          expect(recalculated, greaterThan(0.0),
              reason: 'Recalculated mileage must be strictly positive');
        },
      );
    });

    test('known example: delete middle of [0, 300, 600] with 30L each', () {
      final entries = [
        _FuelEntry(odometer: 0, quantity: 30),
        _FuelEntry(odometer: 300, quantity: 30), // deleted
        _FuelEntry(odometer: 600, quantity: 30),
      ];
      // After deletion: distance = 600 - 0 = 600, mileage = 600/30 = 20
      final result = simulateDeletion(entries, 1, FuelType.petrol);
      expect(result, closeTo(20.0, 1e-9));
    });

    test('known example: delete middle of [1000, 1200, 1500] with 20L', () {
      final entries = [
        _FuelEntry(odometer: 1000, quantity: 20),
        _FuelEntry(odometer: 1200, quantity: 20), // deleted
        _FuelEntry(odometer: 1500, quantity: 20),
      ];
      // After deletion: distance = 1500 - 1000 = 500, mileage = 500/20 = 25
      final result = simulateDeletion(entries, 1, FuelType.petrol);
      expect(result, closeTo(25.0, 1e-9));
    });

    test('works for CNG fuel type (km/kg)', () {
      final entries = [
        _FuelEntry(odometer: 0, quantity: 10),
        _FuelEntry(odometer: 200, quantity: 10), // deleted
        _FuelEntry(odometer: 400, quantity: 10),
      ];
      // After deletion: distance = 400, mileage = 400/10 = 40 km/kg
      final result = simulateDeletion(entries, 1, FuelType.cng);
      expect(result, closeTo(40.0, 1e-9));
    });
  });
}
