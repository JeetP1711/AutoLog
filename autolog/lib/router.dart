import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/analytics/analytics_screen.dart';
import 'screens/documents/add_edit_document_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/logs/add_edit_expense_log_screen.dart';
import 'screens/logs/add_edit_fuel_log_screen.dart';
import 'screens/logs/add_edit_service_log_screen.dart';
import 'screens/logs/logs_screen.dart';
import 'screens/main_shell.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/pin/pin_lock_screen.dart';
import 'screens/reminders/reminder_center_screen.dart';
import 'screens/settings/about_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/vehicles/add_edit_vehicle_screen.dart';
import 'screens/vehicles/vehicle_detail_screen.dart';
import 'screens/vehicles/vehicle_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route path constants
// ─────────────────────────────────────────────────────────────────────────────

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String pin = '/pin';

  // Shell tabs
  static const String home = '/home';
  static const String vehicles = '/vehicles';
  static const String logs = '/logs';
  static const String analytics = '/analytics';
  static const String settings = '/settings';

  // Vehicles nested
  static const String vehiclesAdd = '/vehicles/add';
  static const String vehicleDetail = '/vehicles/:id';
  static const String vehicleEdit = '/vehicles/:id/edit';

  // Logs nested
  static const String fuelLogAdd = '/logs/fuel/add';
  static const String fuelLogEdit = '/logs/fuel/:id/edit';
  static const String serviceLogAdd = '/logs/service/add';
  static const String serviceLogEdit = '/logs/service/:id/edit';
  static const String expenseLogAdd = '/logs/expense/add';
  static const String expenseLogEdit = '/logs/expense/:id/edit';

  // Documents nested (accessible from within the shell)
  static const String documentAdd = '/documents/add';
  static const String documentEdit = '/documents/:id/edit';

  // Reminders
  static const String reminders = '/reminders';

  // Settings nested
  static const String about = '/settings/about';
}

// ─────────────────────────────────────────────────────────────────────────────
// GoRouter configuration
// ─────────────────────────────────────────────────────────────────────────────

/// The application-wide [GoRouter] instance.
///
/// The root `/` redirects to `/splash`. The five main tabs are wrapped in a
/// [StatefulShellRoute.indexedStack] so each branch preserves its own
/// navigation stack when the user switches tabs.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    // ── Redirect root ────────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      redirect: (_, __) => AppRoutes.splash,
    ),

    // ── Pre-shell screens ────────────────────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.pin,
      builder: (context, state) => const PinLockScreen(),
    ),

    // ── Shell route (bottom navigation) ─────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => MainShell(
        navigationShell: navigationShell,
      ),
      branches: [
        // Branch 0 — Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Branch 1 — Vehicles
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.vehicles,
              builder: (context, state) => const VehicleListScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) =>
                      const AddEditVehicleScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => VehicleDetailScreen(
                    vehicleId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => AddEditVehicleScreen(
                        vehicleId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // Branch 2 — Logs
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.logs,
              builder: (context, state) => const LogsScreen(),
              routes: [
                // Fuel logs
                GoRoute(
                  path: 'fuel/add',
                  builder: (context, state) => const AddEditFuelLogScreen(),
                ),
                GoRoute(
                  path: 'fuel/:id/edit',
                  builder: (context, state) => AddEditFuelLogScreen(
                    logId: state.pathParameters['id'],
                  ),
                ),
                // Service logs
                GoRoute(
                  path: 'service/add',
                  builder: (context, state) =>
                      const AddEditServiceLogScreen(),
                ),
                GoRoute(
                  path: 'service/:id/edit',
                  builder: (context, state) => AddEditServiceLogScreen(
                    logId: state.pathParameters['id'],
                  ),
                ),
                // Expense logs
                GoRoute(
                  path: 'expense/add',
                  builder: (context, state) =>
                      const AddEditExpenseLogScreen(),
                ),
                GoRoute(
                  path: 'expense/:id/edit',
                  builder: (context, state) => AddEditExpenseLogScreen(
                    logId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
            // Documents (nested under the Logs branch for shell access)
            GoRoute(
              path: '/documents/add',
              builder: (context, state) => const AddEditDocumentScreen(),
            ),
            GoRoute(
              path: '/documents/:id/edit',
              builder: (context, state) => AddEditDocumentScreen(
                documentId: state.pathParameters['id'],
              ),
            ),
            // Reminders
            GoRoute(
              path: AppRoutes.reminders,
              builder: (context, state) => const ReminderCenterScreen(),
            ),
          ],
        ),

        // Branch 3 — Analytics
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.analytics,
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),

        // Branch 4 — Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsScreen(),
              routes: [
                GoRoute(
                  path: 'about',
                  builder: (context, state) => const AboutScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
