// Feature: autolog-vehicle-manager
// Property 8: Vehicle database lookup consistency
//
// For every brand in the bundled JSON, getModels(brand) returns a non-empty
// list. For every brand+model pair, getYears(brand, model) returns a non-empty
// list of integers. Neither call requires a network connection.
//
// Validates: Requirements 5.4, 5.5

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:autolog/data/vehicle_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Load the real asset bundle so the JSON file is available in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);

    await VehicleDatabase.instance.load();
  });

  group('VehicleDatabase — Property 8: lookup consistency', () {
    test('getBrands() returns a non-empty list', () {
      final brands = VehicleDatabase.instance.getBrands();
      expect(brands, isNotEmpty,
          reason: 'The vehicle database must contain at least one brand');
    });

    test('getModels(brand) returns a non-empty list for every brand', () {
      final brands = VehicleDatabase.instance.getBrands();
      for (final brand in brands) {
        final models = VehicleDatabase.instance.getModels(brand);
        expect(models, isNotEmpty,
            reason: 'Brand "$brand" must have at least one model');
      }
    });

    test('getYears(brand, model) returns a non-empty list of ints for every brand+model pair', () {
      final brands = VehicleDatabase.instance.getBrands();
      for (final brand in brands) {
        final models = VehicleDatabase.instance.getModels(brand);
        for (final model in models) {
          final years = VehicleDatabase.instance.getYears(brand, model);
          expect(years, isNotEmpty,
              reason: '"$brand / $model" must have at least one year');
          for (final year in years) {
            expect(year, isA<int>(),
                reason: 'Year values must be integers');
            expect(year, greaterThan(1900),
                reason: 'Year must be a plausible vehicle year');
          }
        }
      }
    });

    test('Indian brands are present in the database', () {
      final brands = VehicleDatabase.instance.getBrands();
      const expectedIndianBrands = [
        'Honda',
        'Maruti Suzuki',
        'Hyundai',
        'Tata',
        'Mahindra',
        'Toyota',
        'Bajaj',
        'Hero',
        'TVS',
        'Royal Enfield',
      ];
      for (final brand in expectedIndianBrands) {
        expect(brands, contains(brand),
            reason: 'Indian brand "$brand" must be in the database');
      }
    });

    test('load() is idempotent — calling it twice does not throw', () async {
      await expectLater(
        VehicleDatabase.instance.load(),
        completes,
      );
      // Data should still be intact after second load call
      expect(VehicleDatabase.instance.getBrands(), isNotEmpty);
    });

    test('getModels() returns empty list for unknown brand', () {
      final models = VehicleDatabase.instance.getModels('UnknownBrand_XYZ');
      expect(models, isEmpty);
    });

    test('getYears() returns empty list for unknown brand+model', () {
      final years = VehicleDatabase.instance.getYears('UnknownBrand_XYZ', 'UnknownModel');
      expect(years, isEmpty);
    });
  });
}
