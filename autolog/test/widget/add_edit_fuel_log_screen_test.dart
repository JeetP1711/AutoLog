import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autolog/models/models.dart';
import 'package:autolog/providers/fuel_log_provider.dart';
import 'package:autolog/providers/settings_provider.dart';
import 'package:autolog/providers/vehicle_provider.dart';
import 'package:autolog/screens/logs/add_edit_fuel_log_screen.dart';
import 'package:autolog/theme/app_theme.dart';
import 'package:autolog/theme/theme_controller.dart';

Vehicle _makeVehicle() => const Vehicle(
      id: 'v1',
      nickname: 'My Car',
      numberPlate: 'MH01AB1234',
      brand: 'Honda',
      model: 'City',
      year: 2022,
      fuelType: FuelType.petrol,
      vehicleType: VehicleType.car,
      odometerKm: 10000,
      createdAt: null,
    );

class _FakeVehicleNotifier extends VehicleNotifier {
  @override
  Future<List<Vehicle>> build() async => [_makeVehicle()];
}

class _FakeFuelLogNotifier extends FuelLogNotifier {
  bool saveCalled = false;

  @override
  Future<List<FuelLog>> build(String vehicleId) async => [];

  @override
  Future<void> saveFuelLog(FuelLog log, FuelType fuelType) async {
    saveCalled = true;
  }
}

void main() {
  group('AddEditFuelLogScreen widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('shows required field labels', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier()),
            fuelLogProvider.overrideWith(() => _FakeFuelLogNotifier()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
                () => ThemeController(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const AddEditFuelLogScreen(vehicleId: 'v1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Add Fuel Log'), findsOneWidget);
      expect(find.text('Quantity (L)'), findsOneWidget);
      expect(find.text('Total Price (₹)'), findsOneWidget);
      expect(find.text('Odometer (km)'), findsOneWidget);
    });

    testWidgets('shows validation errors when saving empty form', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier()),
            fuelLogProvider.overrideWith(() => _FakeFuelLogNotifier()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
                () => ThemeController(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const AddEditFuelLogScreen(vehicleId: 'v1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Save without filling in fields
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.text('Quantity is required'), findsOneWidget);
    });

    testWidgets('full tank toggle is visible and toggleable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier()),
            fuelLogProvider.overrideWith(() => _FakeFuelLogNotifier()),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
                () => ThemeController(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const AddEditFuelLogScreen(vehicleId: 'v1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Full Tank'), findsOneWidget);

      // Toggle the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
    });
  });
}
