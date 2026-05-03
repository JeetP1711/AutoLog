import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autolog/models/models.dart';
import 'package:autolog/providers/analytics_provider.dart';
import 'package:autolog/providers/settings_provider.dart';
import 'package:autolog/providers/vehicle_provider.dart';
import 'package:autolog/screens/analytics/analytics_screen.dart';
import 'package:autolog/services/analytics_service.dart';
import 'package:autolog/theme/app_theme.dart';
import 'package:autolog/theme/theme_controller.dart';

class _FakeVehicleNotifier extends VehicleNotifier {
  _FakeVehicleNotifier(this._vehicles);
  final List<Vehicle> _vehicles;

  @override
  Future<List<Vehicle>> build() async => _vehicles;
}

void main() {
  group('AnalyticsScreen widget tests', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('shows Analytics app bar title', (tester) async {
      final year = DateTime.now().year;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier([])),
            monthlyFuelSpendProvider.overrideWith(
              (ref, y) async => List.generate(
                12,
                (i) => MonthlyFuelPoint(month: i + 1, year: year, totalSpend: 0),
              ),
            ),
            mileageTrendProvider.overrideWith((ref, id) async => []),
            expenseBreakdownProvider.overrideWith((ref) async => []),
            yearlyMaintenanceCostProvider.overrideWith((ref) async => []),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
                () => ThemeController(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const AnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Analytics'), findsOneWidget);
    });

    testWidgets('shows empty chart message when insufficient data', (tester) async {
      final year = DateTime.now().year;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier([])),
            monthlyFuelSpendProvider.overrideWith(
              (ref, y) async => List.generate(
                12,
                (i) => MonthlyFuelPoint(month: i + 1, year: year, totalSpend: 0),
              ),
            ),
            mileageTrendProvider.overrideWith((ref, id) async => []),
            expenseBreakdownProvider.overrideWith((ref) async => []),
            yearlyMaintenanceCostProvider.overrideWith((ref) async => []),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
                () => ThemeController(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const AnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show empty chart messages
      expect(
        find.text('Add more fuel logs to see trends'),
        findsOneWidget,
      );
    });

    testWidgets('shows chart section titles', (tester) async {
      final year = DateTime.now().year;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vehicleProvider.overrideWith(() => _FakeVehicleNotifier([])),
            monthlyFuelSpendProvider.overrideWith(
              (ref, y) async => List.generate(
                12,
                (i) => MonthlyFuelPoint(month: i + 1, year: year, totalSpend: 0),
              ),
            ),
            mileageTrendProvider.overrideWith((ref, id) async => []),
            expenseBreakdownProvider.overrideWith((ref) async => []),
            yearlyMaintenanceCostProvider.overrideWith((ref) async => []),
            sharedPreferencesProvider.overrideWithValue(prefs),
            themeControllerProvider.overrideWith(
                () => ThemeController(prefs)),
          ],
          child: MaterialApp(
            theme: AppTheme.darkTheme(),
            home: const AnalyticsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('Monthly Fuel Spend'), findsOneWidget);
      expect(find.text('Expense Breakdown'), findsOneWidget);
    });
  });
}
