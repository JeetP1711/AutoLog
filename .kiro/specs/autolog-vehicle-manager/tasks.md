# Implementation Plan: AutoLog Vehicle Manager

## Overview

Implement the AutoLog Flutter Android app incrementally, starting from project scaffolding and core data models, through repositories and services, up to all screens and the release APK. Each task builds directly on the previous ones so there is no orphaned code. All 11 correctness properties from the design document are covered by property-based test sub-tasks placed close to the relevant implementation.

## Tasks

- [x] 1. Project scaffolding and dependency setup
  - Create the Flutter project targeting Android with Dart null safety enabled
  - Write `pubspec.yaml` with exact version pins for: `flutter_riverpod`, `hive_flutter`, `hive_generator`, `build_runner`, `shared_preferences`, `flutter_local_notifications`, `intl`, `fl_chart`, `image_picker`, `file_picker`, `path_provider`, `permission_handler`, `go_router`, `uuid`, `crypto`, `fast_check`
  - Declare asset entries for fonts, images, and `assets/data/vehicle_database.json`
  - Create the full directory skeleton under `lib/`: `models/`, `data/`, `services/`, `providers/`, `screens/`, `widgets/`, `utils/`, `theme/`
  - Run `flutter pub get` and confirm zero import or asset errors
  - _Requirements: 18.1, 18.3, 18.4, 18.5_

- [x] 2. Theme and app entry point
  - [x] 2.1 Implement `theme/app_theme.dart` with Material 3 dark graphite + blue accent `ThemeData` and a matching light `ThemeData`
    - Define colour scheme, typography, card shape (rounded), and consistent spacing constants
    - _Requirements: 17.1, 17.2_
  - [x] 2.2 Implement `theme/theme_controller.dart` as a Riverpod `StateNotifier` that reads/writes `ThemeMode` from SharedPreferences
    - _Requirements: 14.1, 17.1_
  - [x] 2.3 Wire `main.dart` with `ProviderScope`, `MaterialApp.router` using `go_router`, and `ThemeController`
    - Initialise Hive, open all boxes, and handle initialisation failure with a full-screen retry widget
    - _Requirements: 1.5, 18.1_

- [ ] 3. Core domain models and Hive adapters
  - [x] 3.1 Implement all model files in `models/`: `Vehicle`, `FuelLog`, `ServiceLog`, `ExpenseLog`, `Document`, `Reminder`, `AppSettings` with `@HiveType`/`@HiveField` annotations, `copyWith`, `toJson`, and `fromJson`
    - Include all enumerations: `FuelType`, `VehicleType`, `DistanceUnit`, `ReminderType`
    - _Requirements: 5.2, 5.7, 6.1, 7.1, 8.1, 9.1, 10.1, 11.1, 18.2_
  - [x] 3.2 Run `build_runner` to generate `*.g.dart` TypeAdapter files; commit generated files
    - _Requirements: 18.5_
  - [-] 3.3 Write property test for Hive persistence round-trip (Property 9)
    - **Property 9: Hive persistence round-trip**
    - For each model type, generate random instances, write to a temporary Hive box, close and reopen the box, read back, and assert all field values are equal to the originals
    - **Validates: Requirements 1.3**

- [ ] 4. Data layer — repositories and Hive box initialisation
  - [~] 4.1 Implement `data/hive_boxes.dart` with box name constants and a single `HiveBoxes.init()` method that opens all six boxes
    - _Requirements: 1.1, 1.3_
  - [~] 4.2 Implement `data/vehicle_repository.dart`, `data/fuel_log_repository.dart`, `data/service_log_repository.dart`, `data/expense_log_repository.dart`, `data/document_repository.dart`, and `data/reminder_repository.dart`
    - Each exposes `getAll`, `getById`, `save`, `delete`, and `watchAll` (reactive stream)
    - _Requirements: 1.1, 1.3, 5.8, 7.6, 8.5, 9.4, 10.5, 11.4_
  - [~] 4.3 Implement `data/vehicle_database.dart` that loads `assets/data/vehicle_database.json` once at startup, caches it in memory, and exposes `getBrands()`, `getModels(brand)`, and `getYears(brand, model)`
    - Populate the JSON asset with all required Indian brands and their models/years
    - _Requirements: 5.4, 5.5, 5.6_
  - [~] 4.4 Write property test for vehicle database lookup consistency (Property 8)
    - **Property 8: Vehicle database lookup consistency**
    - For every brand in the bundled JSON, assert `getModels(brand)` returns a non-empty list; for every brand+model pair, assert `getYears(brand, model)` returns a non-empty list of integers; confirm no network call is made
    - **Validates: Requirements 5.4, 5.5**

- [ ] 5. Pure utility functions
  - [~] 5.1 Implement `utils/mileage_calculator.dart` with `MileageCalculator.calculate()` (all fuel type branches, zero-quantity guard, negative-distance guard) and `MileageCalculator.distance()`
    - _Requirements: 6.4, 6.5, 7.3, 7.4_
  - [~] 5.2 Write property test for mileage calculation chain (Property 2)
    - **Property 2: Mileage calculation chain**
    - Generate random pairs of consecutive odometer readings (current > previous) and positive quantities; assert `distance = current − previous`, `mileage = distance / quantity`, and both values are strictly positive
    - **Validates: Requirements 7.3, 7.4, 6.4**
  - [~] 5.3 Implement `utils/unit_converter.dart` with `UnitConverter.kmToMiles()`, `milesToKm()`, and `convertDistance()`
    - _Requirements: 14.3, 14.4_
  - [~] 5.4 Write property test for unit conversion round-trip (Property 3)
    - **Property 3: Unit conversion round-trip**
    - Generate random km values (including 0 and very large values); convert to miles then back to km; assert result is within ε = 1e-9 of the original
    - **Validates: Requirements 14.4**
  - [~] 5.5 Implement `utils/validators.dart` with field validators for all required fields (nickname, number plate, odometer, quantity, price, date, PIN)
    - _Requirements: 5.2, 7.1, 8.1, 9.1_
  - [~] 5.6 Write property test for whitespace-only input rejection (Property 4)
    - **Property 4: Whitespace-only inputs are rejected**
    - Generate strings composed entirely of spaces, tabs, and newlines; assert every field validator returns invalid for these inputs; assert no Vehicle, FuelLog, ServiceLog, or ExpenseLog can be created with a whitespace-only required field
    - **Validates: Requirements 5.2, 7.1, 8.1, 9.1**
  - [~] 5.7 Implement `utils/date_formatter.dart` and `utils/currency_formatter.dart`
    - _Requirements: 14.2, 17.2_

- [~] 6. Checkpoint — core utilities and data layer
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 7. Services layer
  - [~] 7.1 Implement `services/pin_service.dart` storing the PIN as a SHA-256 hash in SharedPreferences; expose `setPin`, `verifyPin`, `clearPin`, and `isPinEnabled`
    - _Requirements: 16.1, 16.4, 16.5_
  - [~] 7.2 Write unit tests for `PinService`
    - Test hash correctness, verify-correct, verify-incorrect, and that plaintext PIN is never stored
    - _Requirements: 16.4_
  - [~] 7.3 Implement `services/notification_service.dart` wrapping `flutter_local_notifications`; expose `init`, `scheduleReminder`, `cancelReminder`, and `cancelAllForVehicle`
    - Handle Android 13+ `POST_NOTIFICATIONS` permission; show persistent banner in Reminder Center if denied
    - _Requirements: 11.1, 11.2, 11.5, 11.6_
  - [~] 7.4 Write property test for notification payload completeness (Property 11)
    - **Property 11: Notification payload completeness**
    - Generate random `Reminder` records with associated vehicle nicknames; build the notification payload via `NotificationService`; assert the payload body contains the vehicle nickname, the reminder type label, and either the formatted due date or the due odometer value
    - **Validates: Requirements 11.2**
  - [~] 7.5 Implement `services/analytics_service.dart` as a pure computation service with `getMonthlyFuelSpend`, `getMileageTrend`, `getExpenseBreakdown`, and `getOwnershipCost`
    - _Requirements: 12.1, 12.2, 12.4_
  - [~] 7.6 Write unit tests for `AnalyticsService`
    - Test each method with known inputs and expected outputs; test empty-input edge cases
    - _Requirements: 12.1, 12.3_
  - [~] 7.7 Implement `services/backup_service.dart` with `exportToJson` (serialises all boxes + settings to a versioned JSON file saved to device storage) and `importFromJson` (validates structure, restores all records, leaves existing data untouched on failure)
    - _Requirements: 15.1, 15.2, 15.3, 15.5_
  - [~] 7.8 Write property test for backup round-trip (Property 1)
    - **Property 1: Backup round-trip preserves all data**
    - Generate random app states (arbitrary combinations of vehicles, fuel logs, service logs, expense logs, documents, reminders, and settings); export to JSON; import from JSON; assert structural equality of all records and all field values
    - **Validates: Requirements 15.4**

- [ ] 8. Riverpod providers
  - [~] 8.1 Implement `providers/settings_provider.dart` as a `StateNotifier` backed by SharedPreferences; expose currency symbol, distance unit, theme mode, PIN enabled flag, and onboarding completed flag
    - _Requirements: 14.1, 14.2, 14.3, 2.4, 2.5_
  - [~] 8.2 Implement `providers/vehicle_provider.dart` as an `AsyncNotifier` backed by `VehicleRepository.watchAll()`; expose add, update, and delete actions (delete cascades to all associated logs, documents, and reminders)
    - _Requirements: 5.1, 5.8, 5.9, 5.10_
  - [~] 8.3 Implement `providers/fuel_log_provider.dart` as an `AsyncNotifier`; on save, compute distance and mileage via `MileageCalculator` and persist; on delete, recalculate the subsequent entry's mileage
    - _Requirements: 7.3, 7.4, 7.6, 7.7_
  - [~] 8.4 Write property test for fuel log deletion mileage recalculation (Property 6)
    - **Property 6: Fuel log deletion triggers correct mileage recalculation**
    - Generate ordered sequences of 3+ fuel logs for the same vehicle with strictly increasing odometers; delete the middle entry via the provider; assert the immediately following entry's mileage equals `(followingOdometer − precedingOdometer) / followingQuantity`
    - **Validates: Requirements 7.7**
  - [~] 8.5 Implement `providers/service_log_provider.dart`; on save, if `nextDueDate` or `nextDueOdometerKm` is set, create exactly one `Reminder` via `ReminderRepository` and schedule it via `NotificationService`
    - _Requirements: 8.4_
  - [~] 8.6 Write property test for automatic reminder creation (Property 5 — service log branch)
    - **Property 5: Automatic reminder creation (service log)**
    - Generate random service logs with a next due date or next due odometer; save via provider; assert exactly one reminder is created and persisted in `ReminderRepository`
    - **Validates: Requirements 8.4**
  - [~] 8.7 Implement `providers/document_provider.dart`; on save with an expiry date more than 30 days in the future, create exactly two reminders at `expiryDate − 30 days` and `expiryDate − 7 days`; on delete, cancel associated notifications
    - _Requirements: 10.4, 11.5_
  - [~] 8.8 Write property test for automatic reminder creation (Property 5 — document branch)
    - **Property 5: Automatic reminder creation (document)**
    - Generate random documents with expiry dates more than 30 days in the future; save via provider; assert exactly two reminders are created with due dates equal to `expiryDate − 30 days` and `expiryDate − 7 days`, both strictly before the expiry date
    - **Validates: Requirements 10.4**
  - [~] 8.9 Implement `providers/expense_log_provider.dart`, `providers/reminder_provider.dart`, and `providers/analytics_provider.dart`
    - `analytics_provider` derives chart data from all log providers via `AnalyticsService`
    - _Requirements: 9.4, 11.3, 11.4, 12.1, 12.2_

- [~] 9. Checkpoint — services and providers
  - Ensure all tests pass, ask the user if questions arise.

- [~] 10. Navigation and shell
  - Implement `go_router` configuration in `main.dart` or a dedicated `router.dart`; define all routes from the design (`/splash`, `/onboarding`, `/pin`, `/home` shell with five tabs, and all nested routes)
  - Wire the bottom navigation bar (five destinations: Home, Vehicles, Logs, Analytics, Settings) with state preservation across tab switches
  - _Requirements: 4.1, 4.2, 4.3_

- [ ] 11. Splash and onboarding screens
  - [~] 11.1 Implement `screens/splash_screen.dart` with the AutoLog logo animation (minimum 1.5 s, maximum 3 s); navigate to onboarding or home based on `onboardingCompleted` flag from `SettingsProvider`
    - _Requirements: 2.1, 2.5_
  - [~] 11.2 Implement `screens/onboarding_screen.dart` with a 3-slide PageView (Manage all vehicles / Track expenses / Never miss service dates), a Skip button, and a completion action that sets `onboardingCompleted = true` and navigates to Home
    - _Requirements: 2.2, 2.3, 2.4_

- [~] 12. PIN lock screen
  - Implement `screens/pin/pin_lock_screen.dart` with a 4-digit PIN entry UI; on correct PIN navigate to Home; on 5 consecutive incorrect attempts lock input for 60 seconds with a visible countdown; use `PinService` for verification
  - _Requirements: 16.1, 16.2, 16.3_

- [ ] 13. Home Dashboard screen
  - [~] 13.1 Implement `screens/home_screen.dart` displaying: vehicle count, monthly fuel spend, upcoming service due dates (≤ 30 days), expiring documents (≤ 30 days), recent activity feed (last 10 entries), quick-add buttons, yearly total spend, and alerts badge
    - Show skeleton loaders on initial load; show empty state illustration when no vehicles exist
    - _Requirements: 3.1, 3.2, 17.3, 17.4_
  - [~] 13.2 Wire pull-to-refresh and reactive updates so the dashboard reflects new log data without manual refresh
    - _Requirements: 3.4, 3.5_
  - [~] 13.3 Write property test for dashboard totals accuracy (Property 10)
    - **Property 10: Dashboard totals accuracy**
    - Generate random sets of fuel logs and expense logs for the current calendar month and year; assert the monthly fuel spend total equals the arithmetic sum of all `totalPrice` values for that month; assert the yearly total equals the sum of all fuel costs plus expense amounts for the year
    - **Validates: Requirements 3.1, 3.4**

- [ ] 14. Vehicle screens
  - [~] 14.1 Implement `screens/vehicles/vehicle_list_screen.dart` with a list of `VehicleCard` widgets, a FAB to add a vehicle, and swipe-to-delete with confirmation dialog
    - _Requirements: 5.8, 17.6, 17.7, 17.8_
  - [~] 14.2 Implement `screens/vehicles/add_edit_vehicle_screen.dart` with all required and optional fields; wire brand → model → year cascading dropdowns from `VehicleDatabase`; validate all required fields before save; show snackbar on success
    - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.6, 5.7, 5.9, 17.5_
  - [~] 14.3 Implement `screens/vehicles/vehicle_detail_screen.dart` with six tabs: Overview, Fuel Logs, Service Logs, Expenses, Documents, and Notes; each tab shows the relevant log list with FAB and swipe-to-delete
    - _Requirements: 5.11, 17.6, 17.7, 17.8_

- [ ] 15. Log entry screens
  - [~] 15.1 Implement `screens/logs/add_edit_fuel_log_screen.dart` with required fields (date, quantity, total price, odometer) and optional fields (station name, full-tank toggle, notes); validate and save via `FuelLogProvider`; show snackbar on success
    - _Requirements: 7.1, 7.2, 7.6, 17.5_
  - [~] 15.2 Implement `screens/logs/add_edit_service_log_screen.dart` with required fields (date, service type, cost) and optional fields (odometer, garage name, notes, next due date, next due odometer); validate and save via `ServiceLogProvider`
    - _Requirements: 8.1, 8.2, 8.3, 8.5, 17.5_
  - [~] 15.3 Implement `screens/logs/add_edit_expense_log_screen.dart` with required fields (date, category, amount) and optional notes; validate and save via `ExpenseLogProvider`
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 17.5_

- [~] 16. Documents screen
  - Implement `screens/documents/document_list_screen.dart` and `screens/documents/add_edit_document_screen.dart`
  - Required fields: document type, expiry date; optional: issue date, document number, file/photo picker
  - On save, trigger automatic reminder creation via `DocumentProvider`; show snackbar on success
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 17.5_

- [ ] 17. Unified Logs screen
  - [~] 17.1 Implement `screens/logs/logs_screen.dart` displaying a combined chronological timeline of all log types across all vehicles, sorted by date descending; show log type icon and vehicle name on each tile
    - _Requirements: 13.1_
  - [~] 17.2 Add search bar (free-text match on notes, garage names, station names) and filter controls (date range, vehicle, category); update the list reactively as filters change; show empty state when no results match
    - _Requirements: 13.2, 13.3, 13.4_
  - [~] 17.3 Write property test for log filter consistency (Property 7)
    - **Property 7: Log filter consistency**
    - Generate random log lists with embedded search terms; apply arbitrary combinations of search query, date range, vehicle filter, and category filter; assert every returned entry satisfies all active criteria and no matching entry is absent from the results
    - **Validates: Requirements 13.2, 13.3**
  - [~] 17.4 Implement swipe-to-delete on log tiles with confirmation dialog
    - _Requirements: 13.5, 17.6, 17.7_

- [~] 18. Reminder Center screen
  - Implement `screens/reminders/reminder_center_screen.dart` listing all pending reminders with vehicle name, type, and due date/odometer; allow dismiss and delete; show notification-disabled banner if permission is denied
  - _Requirements: 11.3, 11.4_

- [~] 19. Analytics screen
  - Implement `screens/analytics/analytics_screen.dart` using `fl_chart` widgets from `widgets/chart_widgets/`: monthly fuel spend bar chart, yearly maintenance cost bar chart, mileage trend line chart, expense category pie chart, total ownership cost bar chart, and vehicle comparison bar chart (when > 1 vehicle)
  - Show informational empty state for any chart with fewer than 2 data points
  - _Requirements: 12.1, 12.2, 12.3, 12.4_

- [ ] 20. Settings and About screens
  - [~] 20.1 Implement `screens/settings/settings_screen.dart` with toggles and actions for: dark/light mode, currency symbol, distance unit, export backup, import backup, reset all data (with confirmation dialog), PIN lock enable/disable/change, and navigation to About
    - _Requirements: 14.1, 14.2, 14.3, 14.5, 14.6, 14.7, 14.8_
  - [~] 20.2 Implement `screens/settings/about_screen.dart` displaying app name, version, and tagline "Track Every Mile"
    - _Requirements: 14.9_
  - [~] 20.3 Wire distance unit change to convert all displayed odometer and distance values throughout the app via `UnitConverter`
    - _Requirements: 14.4_

- [~] 21. Shared widgets
  - Implement all reusable widgets: `widgets/vehicle_card.dart`, `widgets/log_tile.dart`, `widgets/stat_card.dart`, `widgets/empty_state.dart`, `widgets/skeleton_loader.dart`, and `widgets/confirm_dialog.dart`
  - Ensure rounded cards, consistent spacing, and Material 3 styling throughout
  - _Requirements: 17.2, 17.3, 17.4, 17.6_

- [~] 22. Checkpoint — all screens and widgets
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 23. Widget tests
  - [~] 23.1 Write widget tests for `HomeScreen` (empty state, populated state, pull-to-refresh)
    - Use `ProviderScope` overrides to inject mock repositories
    - _Requirements: 3.1, 3.2, 3.5_
  - [~] 23.2 Write widget tests for `VehicleDetailScreen` (tab navigation, correct data per tab)
    - _Requirements: 5.11_
  - [~] 23.3 Write widget tests for `AddEditFuelLogScreen` (form validation, save triggers provider update)
    - _Requirements: 7.1, 7.2_
  - [~] 23.4 Write widget tests for `PinLockScreen` (correct PIN navigates away, incorrect PIN increments counter, lockout after 5 attempts)
    - _Requirements: 16.1, 16.2, 16.3_
  - [~] 23.5 Write widget tests for `AnalyticsScreen` (empty state placeholders, chart renders with 2+ data points)
    - _Requirements: 12.3_

- [ ] 24. Integration tests
  - [~] 24.1 Write integration test: full onboarding → add vehicle → add fuel log → verify home dashboard totals
    - _Requirements: 2.2, 2.4, 5.2, 7.1, 3.1_
  - [~] 24.2 Write integration test: export backup → clear data → import backup → verify data restored
    - _Requirements: 15.1, 15.2, 15.5_
  - [~] 24.3 Write integration test: add document with expiry → verify two reminders created in Reminder Center
    - _Requirements: 10.4, 11.3_
  - [~] 24.4 Write integration test: enable PIN → relaunch app → verify PIN screen shown → enter correct PIN → verify home screen
    - _Requirements: 16.1, 16.2_
  - [~] 24.5 Write performance test: populate 10,000 fuel log entries via direct Hive writes; assert `FuelLogRepository.getAll()` completes in under 300 ms
    - _Requirements: 17.9_

- [~] 25. Release APK build
  - Configure `android/app/build.gradle` with a release signing config (keystore or debug key for CI)
  - Run `flutter build apk --release` and confirm the build completes without errors
  - Verify the APK installs and launches on an Android emulator or device
  - _Requirements: 18.6_

- [~] 26. Final checkpoint — full test suite and release build
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for a faster MVP
- Each task references specific requirements for full traceability
- Checkpoints at tasks 6, 9, 22, and 26 ensure incremental validation
- Property tests validate universal correctness properties (Properties 1–11 from the design document)
- Unit and widget tests validate specific examples and edge cases
- All 11 correctness properties from the design are covered by dedicated property-based test sub-tasks
