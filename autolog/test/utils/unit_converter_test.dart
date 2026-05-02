// Feature: autolog-vehicle-manager
// Property 3: Unit conversion round-trip
//
// For any distance value in kilometres (including 0 and very large values),
// converting to miles and then converting back to kilometres produces a value
// within floating-point epsilon (1e-9) of the original.
//
// Validates: Requirements 14.4

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/models/enums.dart';
import 'package:autolog/utils/unit_converter.dart';

void main() {
  group('UnitConverter — Property 3: round-trip', () {
    // ── Property-based tests ────────────────────────────────────────────────

    test('km → miles → km round-trip within ε = 1e-9', () async {
      await property(
        forAll(
          float(min: 0.0, max: 1_000_000.0, withNaN: false, withInfinities: false),
        ),
        (km) {
          final miles = UnitConverter.kmToMiles(km);
          final restored = UnitConverter.milesToKm(miles);
          expect(restored, closeTo(km, 1e-9),
              reason: 'km=$km → miles=$miles → km=$restored must be within ε=1e-9');
        },
      );
    });

    test('miles → km → miles round-trip within ε = 1e-9', () async {
      await property(
        forAll(
          float(min: 0.0, max: 1_000_000.0, withNaN: false, withInfinities: false),
        ),
        (miles) {
          final km = UnitConverter.milesToKm(miles);
          final restored = UnitConverter.kmToMiles(km);
          expect(restored, closeTo(miles, 1e-9),
              reason: 'miles=$miles → km=$km → miles=$restored must be within ε=1e-9');
        },
      );
    });

    test('convertDistance round-trip (km → miles → km)', () async {
      await property(
        forAll(
          float(min: 0.0, max: 1_000_000.0, withNaN: false, withInfinities: false),
        ),
        (km) {
          final miles = UnitConverter.convertDistance(
            km,
            from: DistanceUnit.km,
            to: DistanceUnit.miles,
          );
          final restored = UnitConverter.convertDistance(
            miles,
            from: DistanceUnit.miles,
            to: DistanceUnit.km,
          );
          expect(restored, closeTo(km, 1e-9));
        },
      );
    });

    // ── Edge-case unit tests ────────────────────────────────────────────────

    test('0 km converts to 0 miles', () {
      expect(UnitConverter.kmToMiles(0.0), closeTo(0.0, 1e-12));
    });

    test('0 miles converts to 0 km', () {
      expect(UnitConverter.milesToKm(0.0), closeTo(0.0, 1e-12));
    });

    test('1 mile = 1.609344 km', () {
      expect(UnitConverter.milesToKm(1.0), closeTo(1.609344, 1e-9));
    });

    test('1 km ≈ 0.621371 miles', () {
      expect(UnitConverter.kmToMiles(1.0), closeTo(0.6213711922, 1e-9));
    });

    test('convertDistance returns same value when from == to (km)', () {
      expect(
        UnitConverter.convertDistance(
          500.0,
          from: DistanceUnit.km,
          to: DistanceUnit.km,
        ),
        500.0,
      );
    });

    test('convertDistance returns same value when from == to (miles)', () {
      expect(
        UnitConverter.convertDistance(
          300.0,
          from: DistanceUnit.miles,
          to: DistanceUnit.miles,
        ),
        300.0,
      );
    });

    test('label returns correct strings', () {
      expect(UnitConverter.label(DistanceUnit.km), 'km');
      expect(UnitConverter.label(DistanceUnit.miles), 'mi');
    });
  });
}
