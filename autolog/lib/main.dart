import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/hive_boxes.dart';
import 'models/document.dart';
import 'models/enums.dart';
import 'models/expense_log.dart';
import 'models/fuel_log.dart';
import 'models/reminder.dart';
import 'models/service_log.dart';
import 'models/vehicle.dart';
import 'router.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialise SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Initialise Hive
  await Hive.initFlutter();

  // Register enum adapters
  Hive.registerAdapter(FuelTypeAdapter());
  Hive.registerAdapter(VehicleTypeAdapter());
  Hive.registerAdapter(DistanceUnitAdapter());
  Hive.registerAdapter(ReminderTypeAdapter());
  // Register model adapters
  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(FuelLogAdapter());
  Hive.registerAdapter(ServiceLogAdapter());
  Hive.registerAdapter(ExpenseLogAdapter());
  Hive.registerAdapter(DocumentAdapter());
  Hive.registerAdapter(ReminderAdapter());

  // Open all Hive boxes
  bool dbInitFailed = false;
  try {
    await HiveBoxes.init();
  } catch (e, stackTrace) {
    debugPrint('Failed to open Hive boxes: $e\n$stackTrace');
    dbInitFailed = true;
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: dbInitFailed
          ? const _DatabaseInitErrorApp()
          : const AutoLogApp(),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Root app widget
// ─────────────────────────────────────────────────────────────────────────────

/// Root widget for the AutoLog application.
///
/// Consumes [themeControllerProvider] to apply the user's persisted theme
/// preference and wires up the [appRouter] for declarative navigation.
class AutoLogApp extends ConsumerWidget {
  const AutoLogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'AutoLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      routerConfig: appRouter,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Database initialisation error — standalone app shell
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal [MaterialApp] wrapper shown when Hive fails to initialise.
///
/// Renders [DatabaseInitError] with the dark AppTheme so the error screen
/// still looks polished even without a [ProviderScope] theme controller.
class _DatabaseInitErrorApp extends StatelessWidget {
  const _DatabaseInitErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoLog',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),
      home: const DatabaseInitError(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DatabaseInitError widget
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen error widget displayed when the Hive database fails to open.
///
/// Provides a "Retry" button that re-runs [main] to attempt re-initialisation.
class DatabaseInitError extends StatelessWidget {
  const DatabaseInitError({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon / logo
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.darkDivider,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.directions_car_rounded,
                    size: 52,
                    color: AppColors.primaryBlue,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // App name
                const Text(
                  'AutoLog',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimaryDark,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Error message
                const Text(
                  'Failed to initialise database',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondaryDark,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                const Text(
                  'Please check available storage and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textDisabledDark,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Retry button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: main,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
