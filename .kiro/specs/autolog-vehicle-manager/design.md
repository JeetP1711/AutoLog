# Design Document: AutoLog Vehicle Manager

## Overview

AutoLog is a 100% offline Flutter Android application for personal vehicle management. Users can track fuel refills, service history, expenses, documents, and reminders for one or more vehicles — all stored locally on-device with no network dependency.

The app targets Android (APK release) and is built with Flutter's latest stable channel using Dart null safety. The design follows clean architecture principles with a clear separation between data, domain, and presentation layers. Material 3 with a dark graphite + blue accent theme provides the premium automotive aesthetic.

### Key Design Goals

- **Offline-first**: All reads and writes go to local storage only. No HTTP client is included.
- **Performance**: Local storage reads for lists of up to 10,000 entries must complete within 300 ms.
- **Maintainability**: Strict layer separation — screens never touch the database directly.
- **Correctness**: Mileage calculations, unit conversions, and backup round-trips are pure functions that are easy to test.
- **Extensibility**: New vehicle types, fuel types, and expense categories can be added without schema migrations.

---

## Architecture

The app uses a layered clean architecture:

```
┌─────────────────────────────────────────────────────┐
│                  Presentation Layer                  │
│   screens/  ·  widgets/  ·  theme/                  │
│   (Flutter Widgets, no business logic)               │
├─────────────────────────────────────────────────────┤
│                  State Layer                         │
│   providers/  (Riverpod StateNotifiers / Providers) │
├─────────────────────────────────────────────────────┤
│                  Service Layer                       │
│   services/  (BackupService, NotificationService,   │
│               PinService, AnalyticsService)          │
├─────────────────────────────────────────────────────┤
│                  Data Layer                          │
│   data/  (Hive boxes, repositories, DAO objects)    │
├─────────────────────────────────────────────────────┤
│                  Domain Models                       │
│   models/  (pure Dart, no Flutter imports)          │
└─────────────────────────────────────────────────────┘
```

### State Management: Riverpod

Riverpod is chosen over Provider for its compile-time safety, testability without `BuildContext`, and first-class support for async state. Each major feature area has a dedicated `StateNotifier` or `AsyncNotifier`.

### Local Database: Hive

Hive is chosen for its excellent Flutter integration, fast binary reads, and simple box-based API. Each model type maps to a dedicated Hive box. TypeAdapters are generated via `hive_generator`. Isar is noted as an alternative if full-text search performance becomes a concern, but Hive is sufficient for the target data volumes.

### Directory Structure

```
lib/
├── main.dart
├── models/
│   ├── vehicle.dart
│   ├── fuel_log.dart
│   ├── service_log.dart
│   ├── expense_log.dart
│   ├── document.dart
│   ├── reminder.dart
│   └── app_settings.dart
├── data/
│   ├── hive_boxes.dart          # box name constants + initialisation
│   ├── vehicle_repository.dart
│   ├── fuel_log_repository.dart
│   ├── service_log_repository.dart
│   ├── expense_log_repository.dart
│   ├── document_repository.dart
│   ├── reminder_repository.dart
│   └── vehicle_database.dart    # offline brand/model/year JSON loader
├── services/
│   ├── backup_service.dart
│   ├── notification_service.dart
│   ├── pin_service.dart
│   └── analytics_service.dart
├── providers/
│   ├── vehicle_provider.dart
│   ├── fuel_log_provider.dart
│   ├── service_log_provider.dart
│   ├── expense_log_provider.dart
│   ├── document_provider.dart
│   ├── reminder_provider.dart
│   ├── analytics_provider.dart
│   └── settings_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── home_screen.dart
│   ├── vehicles/
│   │   ├── vehicle_list_screen.dart
│   │   ├── vehicle_detail_screen.dart
│   │   └── add_edit_vehicle_screen.dart
│   ├── logs/
│   │   ├── logs_screen.dart
│   │   ├── add_edit_fuel_log_screen.dart
│   │   ├── add_edit_service_log_screen.dart
│   │   └── add_edit_expense_log_screen.dart
│   ├── documents/
│   │   ├── document_list_screen.dart
│   │   └── add_edit_document_screen.dart
│   ├── reminders/
│   │   └── reminder_center_screen.dart
│   ├── analytics/
│   │   └── analytics_screen.dart
│   ├── settings/
│   │   ├── settings_screen.dart
│   │   └── about_screen.dart
│   └── pin/
│       └── pin_lock_screen.dart
├── widgets/
│   ├── vehicle_card.dart
│   ├── log_tile.dart
│   ├── stat_card.dart
│   ├── empty_state.dart
│   ├── skeleton_loader.dart
│   ├── confirm_dialog.dart
│   └── chart_widgets/
│       ├── monthly_fuel_chart.dart
│       ├── mileage_trend_chart.dart
│       ├── expense_pie_chart.dart
│       └── ownership_cost_chart.dart
├── utils/
│   ├── mileage_calculator.dart
│   ├── unit_converter.dart
│   ├── date_formatter.dart
│   ├── currency_formatter.dart
│   └── validators.dart
└── theme/
    ├── app_theme.dart
    └── theme_controller.dart
```

### Navigation

The app uses `go_router` for declarative routing. The shell route wraps the five bottom-navigation destinations. Deep links from notifications navigate directly to the Reminder Center.

```
/splash
/onboarding
/pin
/home                          (shell)
  /vehicles
    /vehicles/:id
    /vehicles/add
    /vehicles/:id/edit
  /logs
    /logs/fuel/add
    /logs/fuel/:id/edit
    /logs/service/add
    /logs/service/:id/edit
    /logs/expense/add
    /logs/expense/:id/edit
  /analytics
  /settings
    /settings/about
  /reminders
```

---

## Components and Interfaces

### Repository Interface Pattern

Each repository exposes a consistent async interface. Screens never call Hive directly.

```dart
abstract class VehicleRepository {
  Future<List<Vehicle>> getAll();
  Future<Vehicle?> getById(String id);
  Future<void> save(Vehicle vehicle);
  Future<void> delete(String id);
  Stream<List<Vehicle>> watchAll();
}
```

All repositories follow the same pattern: `getAll`, `getById`, `save`, `delete`, `watchAll`. The `watchAll` stream allows Riverpod providers to reactively rebuild UI when data changes.

### VehicleDatabase (Offline Brand/Model/Year)

A bundled `assets/data/vehicle_database.json` file is loaded once at startup and cached in memory. It is never written to.

```dart
class VehicleDatabase {
  Future<void> load();                          // loads JSON asset
  List<String> getBrands();
  List<String> getModels(String brand);
  List<int> getYears(String brand, String model);
}
```

### NotificationService

Wraps `flutter_local_notifications`. All scheduling is done through this service; no screen calls the plugin directly.

```dart
class NotificationService {
  Future<void> init();
  Future<void> scheduleReminder(Reminder reminder);
  Future<void> cancelReminder(String reminderId);
  Future<void> cancelAllForVehicle(String vehicleId);
}
```

### BackupService

Handles JSON serialisation/deserialisation of the entire app state.

```dart
class BackupService {
  Future<String> exportToJson();                // returns file path
  Future<BackupResult> importFromJson(String filePath);
}

class BackupResult {
  final bool success;
  final String? errorMessage;
}
```

### AnalyticsService

Pure computation service — takes repository data and returns chart-ready structures. No I/O.

```dart
class AnalyticsService {
  MonthlyFuelData getMonthlyFuelSpend(List<FuelLog> logs, int year);
  MileageTrendData getMileageTrend(List<FuelLog> logs);
  ExpenseBreakdown getExpenseBreakdown(List<ExpenseLog> logs, List<FuelLog> fuelLogs, List<ServiceLog> serviceLogs);
  OwnershipCostData getOwnershipCost(Vehicle vehicle, List<FuelLog> fuelLogs, List<ServiceLog> serviceLogs, List<ExpenseLog> expenseLogs);
}
```

### MileageCalculator (Pure Utility)

```dart
class MileageCalculator {
  /// Returns km/litre, km/kg, or km/kWh depending on fuel type.
  static double? calculate({
    required double distanceKm,
    required double quantity,
    required FuelType fuelType,
  });

  /// Returns distance between two odometer readings.
  static double distance(double current, double previous);
}
```

### UnitConverter (Pure Utility)

```dart
class UnitConverter {
  static double kmToMiles(double km);
  static double milesToKm(double miles);
  static double convertDistance(double value, DistanceUnit from, DistanceUnit to);
}
```

### PinService

```dart
class PinService {
  Future<void> setPin(String pin);
  Future<bool> verifyPin(String input);
  Future<void> clearPin();
  Future<bool> isPinEnabled();
}
```

PIN is stored as a SHA-256 hash in SharedPreferences — never plaintext.

---

## Data Models

All models are plain Dart classes annotated with `@HiveType` and `@HiveField`. Each has a `copyWith` method and a `toJson`/`fromJson` pair for backup serialisation.

### Vehicle

```dart
@HiveType(typeId: 0)
class Vehicle {
  @HiveField(0) final String id;           // UUID
  @HiveField(1) final String nickname;
  @HiveField(2) final String numberPlate;
  @HiveField(3) final String brand;
  @HiveField(4) final String model;
  @HiveField(5) final int year;
  @HiveField(6) final FuelType fuelType;
  @HiveField(7) final VehicleType vehicleType;
  @HiveField(8) final double odometerKm;   // always stored in km
  @HiveField(9) final DateTime? purchaseDate;
  @HiveField(10) final String? photoPath;
  @HiveField(11) final String? notes;
  @HiveField(12) final DateTime createdAt;
}
```

### FuelLog

```dart
@HiveType(typeId: 1)
class FuelLog {
  @HiveField(0) final String id;
  @HiveField(1) final String vehicleId;
  @HiveField(2) final DateTime date;
  @HiveField(3) final double quantity;
  @HiveField(4) final double totalPrice;
  @HiveField(5) final double odometerKm;   // always stored in km
  @HiveField(6) final bool isFullTank;
  @HiveField(7) final String? stationName;
  @HiveField(8) final String? notes;
  @HiveField(9) final double? mileage;     // computed and cached
  @HiveField(10) final double? distanceKm; // computed and cached
}
```

### ServiceLog

```dart
@HiveType(typeId: 2)
class ServiceLog {
  @HiveField(0) final String id;
  @HiveField(1) final String vehicleId;
  @HiveField(2) final DateTime date;
  @HiveField(3) final String serviceType;  // enum value or custom string
  @HiveField(4) final double cost;
  @HiveField(5) final double? odometerKm;
  @HiveField(6) final String? garageName;
  @HiveField(7) final String? notes;
  @HiveField(8) final DateTime? nextDueDate;
  @HiveField(9) final double? nextDueOdometerKm;
}
```

### ExpenseLog

```dart
@HiveType(typeId: 3)
class ExpenseLog {
  @HiveField(0) final String id;
  @HiveField(1) final String vehicleId;
  @HiveField(2) final DateTime date;
  @HiveField(3) final String category;     // enum value or custom string
  @HiveField(4) final double amount;
  @HiveField(5) final String? notes;
}
```

### Document

```dart
@HiveType(typeId: 4)
class Document {
  @HiveField(0) final String id;
  @HiveField(1) final String vehicleId;
  @HiveField(2) final String documentType; // enum value or custom string
  @HiveField(3) final DateTime expiryDate;
  @HiveField(4) final DateTime? issueDate;
  @HiveField(5) final String? documentNumber;
  @HiveField(6) final String? filePath;    // local path to photo or PDF
}
```

### Reminder

```dart
@HiveType(typeId: 5)
class Reminder {
  @HiveField(0) final String id;
  @HiveField(1) final String vehicleId;
  @HiveField(2) final String title;
  @HiveField(3) final String body;
  @HiveField(4) final ReminderType reminderType;
  @HiveField(5) final DateTime? dueDate;
  @HiveField(6) final double? dueOdometerKm;
  @HiveField(7) final String? sourceId;   // FK to Document or ServiceLog
  @HiveField(8) final bool isDismissed;
  @HiveField(9) final DateTime createdAt;
}
```

### AppSettings

Stored in SharedPreferences (not Hive) as individual keys for simplicity.

```dart
class AppSettings {
  final ThemeMode themeMode;          // dark / light / system
  final String currencySymbol;        // default: ₹
  final DistanceUnit distanceUnit;    // km / miles
  final bool pinEnabled;
  final bool onboardingCompleted;
}
```

### Enumerations

```dart
enum FuelType { petrol, diesel, cng, electric, hybrid, lpg, hydrogen, custom }
enum VehicleType { car, bike, scooter, truck, custom }
enum DistanceUnit { km, miles }
enum ReminderType { insuranceExpiry, pucExpiry, serviceDue, odometerMilestone, custom }
```

### Hive Box Names

| Box Name | Model | typeId |
|---|---|---|
| `vehicles` | Vehicle | 0 |
| `fuel_logs` | FuelLog | 1 |
| `service_logs` | ServiceLog | 2 |
| `expense_logs` | ExpenseLog | 3 |
| `documents` | Document | 4 |
| `reminders` | Reminder | 5 |

### Backup JSON Schema

The backup file is a single JSON object:

```json
{
  "version": 1,
  "exportedAt": "ISO-8601 timestamp",
  "settings": { ... },
  "vehicles": [ ... ],
  "fuelLogs": [ ... ],
  "serviceLogs": [ ... ],
  "expenseLogs": [ ... ],
  "documents": [ ... ],
  "reminders": [ ... ]
}
```

The `version` field enables forward-compatible migration logic in `BackupService.importFromJson`.

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Backup round-trip preserves all data

*For any* valid app state (any combination of vehicles, fuel logs, service logs, expense logs, documents, reminders, and settings), exporting to JSON and then importing from that JSON file SHALL produce a state that is structurally equivalent to the original state — all records present, all field values identical.

**Validates: Requirements 15.4**

---

### Property 2: Mileage calculation chain

*For any* pair of consecutive fuel logs for the same vehicle where the later log has the full-tank toggle enabled and the current odometer is strictly greater than the previous odometer, the computed distance SHALL equal `currentOdometer − previousOdometer`, and the computed mileage SHALL equal `distance / quantity`, and both values SHALL be strictly positive.

**Validates: Requirements 7.3, 7.4, 6.4**

---

### Property 3: Unit conversion round-trip

*For any* distance value in kilometres (including 0 and very large values), converting to miles and then converting back to kilometres SHALL produce a value within floating-point epsilon (1e-9) of the original.

**Validates: Requirements 14.4**

---

### Property 4: Whitespace-only inputs are rejected

*For any* string composed entirely of whitespace characters (spaces, tabs, newlines), the field validators SHALL classify it as invalid, and no vehicle, fuel log, service log, or expense log record SHALL be created or updated with that value as a required field.

**Validates: Requirements 5.2, 7.1, 8.1, 9.1**

---

### Property 5: Automatic reminder creation

*For any* service log saved with a next due date or next due odometer, exactly one reminder SHALL be created and persisted. *For any* document saved with an expiry date more than 30 days in the future, exactly two reminders SHALL be created with due dates of `expiryDate − 30 days` and `expiryDate − 7 days` respectively, both strictly before the expiry date.

**Validates: Requirements 8.4, 10.4**

---

### Property 6: Fuel log deletion triggers correct mileage recalculation

*For any* ordered sequence of three or more fuel logs for the same vehicle, deleting the middle entry SHALL cause the mileage of the immediately following entry to be recalculated as `(followingOdometer − precedingOdometer) / followingQuantity`, where `precedingOdometer` is now the odometer of the entry that was two positions ahead of the deleted entry.

**Validates: Requirements 7.7**

---

### Property 7: Log filter consistency

*For any* combination of search query, date range, vehicle filter, and category filter applied to the unified log timeline, every returned entry SHALL satisfy all active filter criteria, and no entry that satisfies all active filter criteria SHALL be absent from the results.

**Validates: Requirements 13.2, 13.3**

---

### Property 8: Vehicle database lookup consistency

*For any* brand present in the bundled vehicle database, `getModels(brand)` SHALL return a non-empty list. *For any* brand and model pair present in the database, `getYears(brand, model)` SHALL return a non-empty list of integers. Neither call SHALL require a network connection.

**Validates: Requirements 5.4, 5.5**

---

### Property 9: Hive persistence round-trip

*For any* model instance (Vehicle, FuelLog, ServiceLog, ExpenseLog, Document, or Reminder), writing it to its Hive box, closing the box, reopening the box, and reading it back SHALL produce an instance with all field values equal to the original.

**Validates: Requirements 1.3**

---

### Property 10: Dashboard totals accuracy

*For any* set of fuel logs and expense logs for the current calendar month, the monthly fuel spend total displayed on the Home Dashboard SHALL equal the arithmetic sum of all `totalPrice` values in the fuel logs for that month, and the yearly total SHALL equal the sum of all expense amounts plus fuel costs for the current calendar year.

**Validates: Requirements 3.1, 3.4**

---

### Property 11: Notification payload completeness

*For any* reminder record, the notification payload generated by `NotificationService` SHALL contain the vehicle's nickname, the reminder type label, and either the due date (formatted as a human-readable string) or the due odometer value — whichever is applicable — in the notification body.

**Validates: Requirements 11.2**

---

## Error Handling

### Database Initialisation Failure (Requirement 1.5)

If `Hive.initFlutter()` or any `Hive.openBox()` call throws, the app displays a full-screen error widget with a "Retry" button. Writes are blocked until all boxes are confirmed open. The error is logged to the device console (no remote logging).

### Backup Import Validation

`BackupService.importFromJson` validates:
1. The file is valid JSON (catches `FormatException`).
2. The top-level object contains a `version` field with a recognised integer value.
3. Each array element can be deserialised into its target model without null violations.

On any validation failure, the existing Hive boxes are left untouched and a descriptive `SnackBar` is shown.

### Notification Permission Denied

On Android 13+, `POST_NOTIFICATIONS` permission is required. If denied, the app continues to function but shows a persistent banner in the Reminder Center explaining that notifications are disabled. Reminders are still stored in the database and visible in the UI.

### Image / File Picker Errors

If `image_picker` or `file_picker` returns null (user cancelled) or throws a `PlatformException`, the form field is left empty and no error is shown. If the picked file path becomes invalid after saving (e.g., file deleted externally), the document detail screen shows a "File not found" placeholder instead of crashing.

### PIN Lockout

After 5 consecutive incorrect PIN attempts, the PIN entry screen disables input for 60 seconds. A countdown timer is displayed. The attempt counter is stored in memory only (not persisted), so a force-quit resets it — this is an acceptable trade-off for a personal-use app.

### Odometer Regression

If a new fuel log's odometer reading is less than the previous log's odometer, the app shows a validation warning (not a hard block) and sets the computed distance to 0, storing `null` for mileage. This handles edge cases like odometer resets after repairs.

---

## Testing Strategy

### Unit Tests

Unit tests cover pure functions and service logic with no Flutter widget tree or Hive dependency:

- `MileageCalculator`: all fuel type branches, zero quantity guard, negative distance guard.
- `UnitConverter`: km↔miles round-trip, boundary values (0, very large numbers).
- `BackupService` serialisation/deserialisation: round-trip with representative model instances.
- `AnalyticsService`: chart data computation with known inputs and expected outputs.
- `Validators`: empty string, whitespace-only strings, valid inputs for each field type.
- `PinService`: hash correctness, verify-correct, verify-incorrect.

### Property-Based Tests

Property-based tests use the `fast_check` Dart package (or `dart_test` with a custom generator harness). Each test runs a minimum of 100 iterations.

**Tag format: Feature: autolog-vehicle-manager, Property {N}: {property_text}**

| Property | Test Description |
|---|---|
| Property 1 | Generate random app state → export to JSON → import from JSON → assert structural equality of all records |
| Property 2 | Generate random consecutive odometer pairs + quantity (all positive) → assert distance = later − earlier, mileage = distance / quantity |
| Property 3 | Generate random km value → convert to miles → convert back → assert within ε (1e-9) |
| Property 4 | Generate whitespace-only strings (spaces, tabs, newlines) → assert all field validators return invalid |
| Property 5 | Generate random service logs with next due dates and documents with future expiry dates → assert correct reminder counts and due dates |
| Property 6 | Generate random fuel log sequences of 3+ entries → delete middle entry → assert subsequent entry mileage recalculated correctly |
| Property 7 | Generate random log lists with embedded search terms → apply filter combinations → assert completeness and precision |
| Property 8 | For each brand in vehicle database → assert getModels returns non-empty; for each brand+model → assert getYears returns non-empty |
| Property 9 | Generate random model instances → write to Hive → close box → reopen → read back → assert field equality |
| Property 10 | Generate random fuel/expense log sets for a month → assert dashboard totals equal arithmetic sums |
| Property 11 | Generate random reminder records → build notification payload → assert vehicle name, type label, and due info present |

### Widget Tests

Widget tests use `flutter_test` with a `ProviderScope` override to inject mock repositories:

- `HomeScreen`: empty state, populated state, pull-to-refresh.
- `VehicleDetailScreen`: tab navigation, correct data display per tab.
- `AddEditFuelLogScreen`: form validation, save triggers provider update.
- `PinLockScreen`: correct PIN navigates away, incorrect PIN increments counter, lockout after 5 attempts.
- `AnalyticsScreen`: empty state chart placeholders, chart renders with 2+ data points.

### Integration Tests

Integration tests run on a real Android emulator using `integration_test`:

- Full onboarding → add vehicle → add fuel log → verify home dashboard totals.
- Export backup → clear data → import backup → verify data restored.
- Add document with expiry → verify two reminders created in Reminder Center.
- Enable PIN → relaunch app → verify PIN screen shown → enter correct PIN → verify home screen.

### Performance Tests

A dedicated integration test populates 10,000 fuel log entries via direct Hive writes and measures the time for `FuelLogRepository.getAll()` to complete. The test asserts the duration is under 300 ms on a mid-range Android device (Pixel 4a equivalent).
