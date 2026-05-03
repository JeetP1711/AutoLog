import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autolog/models/models.dart';
import 'package:autolog/providers/document_provider.dart';
import 'package:autolog/providers/expense_log_provider.dart';
import 'package:autolog/providers/fuel_log_provider.dart';
import 'package:autolog/providers/service_log_provider.dart';
import 'package:autolog/providers/settings_provider.dart';
import 'package:autolog/providers/vehicle_provider.dart';
import 'package:autolog/screens/vehicles/vehicle_detail_screen.dart';
import 'package:autolog/theme/app_theme.dart';
import 'package:autolog/theme/theme_controller.dart';

Vehicle _makeVehicle() => const Vehicle(
      id: 'v1',
      nickname: 'My Swift',
      numberPlate: 'MH12AB1234',
      brand: 'Maruti Suzuki',
      model: 'Swift',
      year: 2022,
      fuelType: FuelType.petrol,
      vehicleType: VehicleType.car,
      odometerKm: 15000,
      createdAt: null,
    );

class _FakeVehicleNotifier extends VehicleNotifier {
  _FakeVehicleNotifier(this._vehicles);
  final List<Vehicle> _vehicles;

  @override
  Future<List<Vehicle>> build() async => _vehicles;
}

class _FakeFuelLogNotifier extends FuelLogNotifier {
  @override
  Future<List<FuelLog>> build(String vehicleId) async => [];
}

class _FakeServiceLogNotifier extends ServiceLogNotifier {
  @override
  Future<List<ServiceLog>> build(String vehicleId) async => [];
}

class _FakeExpenseLogNotifier extends ExpenseLogNotifier {
  @override
  Future<List<ExpenseLog>> build(String vehicleId) async => [];
}

class _FakeDocumentNotifier extends DocumentNotifier {
  @override
  Future<List<Document>> build(String vehicleId) async => [];
}

void main() {
  group('VehicleDetailScreen widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    Widget buildScreen() {
      final vehicle = _makeVehicle();
      return ProviderScope(
        overrides: [
          vehicleProvider.overrideWith(
              () => _FakeVehicleNotifier([vehicle])),
          fuelLogProvider.overrideWith(() => _FakeFuelLogNotifier()),
          serviceLogProvider.overrideWith(() => _FakeServiceLogNotifier()),
          expenseLogProvider.overrideWith(() => _FakeExpenseLogNotifier()),
          documentProvider.overrideWith(() => _FakeDocumentNotifier()),
          sharedPreferencesProvider.overrideWithValue(prefs),
          themeControllerProvider.overrideWith(
            () => ThemeController(prefs),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.darkTheme(),
          home: const VehicleDetailScreen(vehicleId: 'v1'),
        ),
      );
    }

    testWidgets('shows vehicle nickname in app bar', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      expect(find.text('My Swift'), findsOneWidget);
    });

    testWidgets('shows all 6 tabs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Fuel'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('fuel tab shows empty state when no logs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Tap Fuel tab
      await tester.tap(find.text('Fuel'));
      await tester.pumpAndSettle();

      expect(find.text('No fuel logs yet'), findsOneWidget);
    });

    testWidgets('service tab shows empty state when no logs', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Service'));
      await tester.pumpAndSettle();

      expect(find.text('No service logs yet'), findsOneWidget);
    });

    testWidgets('notes tab shows no notes message when empty', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      expect(find.text('No notes'), findsOneWidget);
    });
  });
}
