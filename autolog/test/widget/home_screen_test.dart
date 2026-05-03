import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autolog/models/models.dart';
import 'package:autolog/providers/analytics_provider.dart';
import 'package:autolog/providers/document_provider.dart';
import 'package:autolog/providers/service_log_provider.dart';
import 'package:autolog/providers/settings_provider.dart';
import 'package:autolog/providers/vehicle_provider.dart';
import 'package:autolog/screens/home/home_screen.dart';
import 'package:autolog/theme/app_theme.dart';
import 'package:autolog/theme/theme_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

Vehicle _makeVehicle(String id) => Vehicle(
      id: id,
      nickname: 'Test Car $id',
      numberPlate: 'MH01AB1234',
      brand: 'Honda',
      model: 'City',
      year: 2022,
      fuelType: FuelType.petrol,
      vehicleType: VehicleType.car,
      odometerKm: 10000,
      createdAt: DateTime(2022),
    );

Widget _buildTestApp({
  List<Vehicle> vehicles = const [],
  double monthlySpend = 0,
  double yearlySpend = 0,
}) {
  SharedPreferences.setMockInitialValues({});

  return ProviderScope(
    overrides: [
      vehicleProvider.overrideWith(() => _FakeVehicleNotifier(vehicles)),
      currentMonthFuelSpendProvider.overrideWith((_) async => monthlySpend),
      currentYearTotalSpendProvider.overrideWith((_) async => yearlySpend),
      expiringSoonProvider.overrideWith((_) async => []),
      allServiceLogsProvider.overrideWith((_) async => []),
      sharedPreferencesProvider.overrideWithValue(
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.getInstance() as SharedPreferences,
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme(),
      home: const HomeScreen(),
    ),
  );
}

// Fake notifier that returns a fixed list
class _FakeVehicleNotifier extends VehicleNotifier {
  _FakeVehicleNotifier(this._vehicles);
  final List<Vehicle> _vehicles;

  @override
  Future<List<Vehicle>> build() async => _vehicles;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('HomeScreen widget tests', () {
    testWidgets('shows empty state when no vehicles exist', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier([])),
            currentMonthFuelSpendProvider.overrideWith((_) async => 0.0),
            currentYearTotalSpendProvider.overrideWith((_) async => 0.0),
            expiringSoonProvider.overrideWith((_) async => []),
            allServiceLogsProvider.overrideWith((_) async => []),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
              () => ThemeController(prefs),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty state
      expect(find.text('No vehicles yet'), findsOneWidget);
      expect(find.text('Add Vehicle'), findsOneWidget);
    });

    testWidgets('shows vehicle count when vehicles exist', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final vehicles = [_makeVehicle('v1'), _makeVehicle('v2')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(
                () => _FakeVehicleNotifier(vehicles)),
            currentMonthFuelSpendProvider
                .overrideWith((_) async => 3500.0),
            currentYearTotalSpendProvider
                .overrideWith((_) async => 42000.0),
            expiringSoonProvider.overrideWith((_) async => []),
            allServiceLogsProvider.overrideWith((_) async => []),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
              () => ThemeController(prefs),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show vehicle count
      expect(find.text('2'), findsOneWidget);
      // Should show Vehicles label
      expect(find.text('Vehicles'), findsOneWidget);
    });

    testWidgets('shows AutoLog app bar title', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier([])),
            currentMonthFuelSpendProvider.overrideWith((_) async => 0.0),
            currentYearTotalSpendProvider.overrideWith((_) async => 0.0),
            expiringSoonProvider.overrideWith((_) async => []),
            allServiceLogsProvider.overrideWith((_) async => []),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
              () => ThemeController(prefs),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const HomeScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('AutoLog'), findsOneWidget);
    });
  });
}
