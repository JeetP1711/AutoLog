// Feature: autolog-vehicle-manager
// Property 2: Mileage calculation chain
//
// For any pair of consecutive odometer readings (current > previous) and
// positive quantities, distance = current − previous, mileage = distance /
// quantity, and both values are strictly positive.
//
// Validates: Requirements 7.3, 7.4, 6.4

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/models/enums.dart';
import 'package:autolog/utils/mileage_calculator.dart';

void main() {
  group('MileageCalculator — Property 2: mileage calculation chain', () {
    // ── Property-based tests ────────────────────────────────────────────────

    test('distance is strictly positive when current > previous', () async {
      await property(
        forAll(
          combine2(
            float(min: 0.0, max: 500_000.0, withNaN: false, withInfinities: false),
            float(min: 0.01, max: 1_000.0, withNaN: false, withInfinities: false),
            (previous, delta) => (previous: previous, delta: delta),
          ),
        ),
        (pair) {
          final current = pair.previous + pair.delta;
          final d = MileageCalculator.distance(current, pair.previous);
          expect(d, isNotNull);
          expect(d!, greaterThan(0.0));
          expect(d, closeTo(pair.delta, 1e-6));
        },
      );
    });

    test('mileage = distance / quantity for all fuel types', () async {
      await property(
        forAll(
          combine3(
            float(min: 0.01, max: 1_000.0, withNaN: false, withInfinities: false),
            float(min: 0.01, max: 1_000.0, withNaN: false, withInfinities: false),
            integer(min: 0, max: FuelType.values.length - 1),
            (distance, quantity, fuelIndex) => (
              distance: distance,
              quantity: quantity,
              fuelType: FuelType.values[fuelIndex],
            ),
          ),
        ),
        (triple) {
          final mileage = MileageCalculator.calculate(
            distanceKm: triple.distance,
            quantity: triple.quantity,
            fuelType: triple.fuelType,
          );
          expect(mileage, isNotNull);
          expect(mileage!, greaterThan(0.0));
          expect(mileage, closeTo(triple.distance / triple.quantity, 1e-9));
        },
      );
    });

    // ── Edge-case unit tests ────────────────────────────────────────────────

    test('distance returns null when current == previous', () {
      expect(MileageCalculator.distance(1000.0, 1000.0), isNull);
    });

    test('distance returns null when current < previous', () {
      expect(MileageCalculator.distance(900.0, 1000.0), isNull);
    });

    test('calculate returns null when distanceKm is null', () {
      expect(
        MileageCalculator.calculate(
          distanceKm: null,
          quantity: 10.0,
          fuelType: FuelType.petrol,
        ),
        isNull,
      );
    });

    test('calculate returns null when distanceKm is zero', () {
      expect(
        MileageCalculator.calculate(
          distanceKm: 0.0,
          quantity: 10.0,
          fuelType: FuelType.petrol,
        ),
        isNull,
      );
    });

    test('calculate returns null when distanceKm is negative', () {
      expect(
        MileageCalculator.calculate(
          distanceKm: -50.0,
          quantity: 10.0,
          fuelType: FuelType.petrol,
        ),
        isNull,
      );
    });

    test('calculate returns null when quantity is zero', () {
      expect(
        MileageCalculator.calculate(
          distanceKm: 100.0,
          quantity: 0.0,
          fuelType: FuelType.petrol,
        ),
        isNull,
      );
    });

    test('calculate returns null when quantity is negative', () {
      expect(
        MileageCalculator.calculate(
          distanceKm: 100.0,
          quantity: -5.0,
          fuelType: FuelType.petrol,
        ),
        isNull,
      );
    });

    test('known example: 300 km / 30 L = 10 km/L', () {
      final mileage = MileageCalculator.calculate(
        distanceKm: 300.0,
        quantity: 30.0,
        fuelType: FuelType.petrol,
      );
      expect(mileage, closeTo(10.0, 1e-9));
    });

    test('known example: 200 km / 4 kg CNG = 50 km/kg', () {
      final mileage = MileageCalculator.calculate(
        distanceKm: 200.0,
        quantity: 4.0,
        fuelType: FuelType.cng,
      );
      expect(mileage, closeTo(50.0, 1e-9));
    });

    test('known example: 400 km / 80 kWh EV = 5 km/kWh', () {
      final mileage = MileageCalculator.calculate(
        distanceKm: 400.0,
        quantity: 80.0,
        fuelType: FuelType.electric,
      );
      expect(mileage, closeTo(5.0, 1e-9));
    });

    test('efficiencyUnit returns correct labels', () {
      expect(MileageCalculator.efficiencyUnit(FuelType.petrol), 'km/L');
      expect(MileageCalculator.efficiencyUnit(FuelType.diesel), 'km/L');
      expect(MileageCalculator.efficiencyUnit(FuelType.lpg), 'km/L');
      expect(MileageCalculator.efficiencyUnit(FuelType.hybrid), 'km/L');
      expect(MileageCalculator.efficiencyUnit(FuelType.cng), 'km/kg');
      expect(MileageCalculator.efficiencyUnit(FuelType.hydrogen), 'km/kg');
      expect(MileageCalculator.efficiencyUnit(FuelType.electric), 'km/kWh');
      expect(MileageCalculator.efficiencyUnit(FuelType.custom, customUnit: 'gal'), 'km/gal');
    });
  });
}
