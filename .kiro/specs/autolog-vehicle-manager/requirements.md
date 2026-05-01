# Requirements Document

## Introduction

AutoLog is a premium personal offline vehicle management Android app built with Flutter. It enables users to track every aspect of vehicle ownership — fuel refills, mileage, service history, repairs, insurance and document expiry, expenses, and reminders — for one or more vehicles, entirely offline with no login, no cloud backend, and no internet dependency. The app targets personal use and must feel like a polished, Play Store-ready utility with a premium automotive design aesthetic.

---

## Glossary

- **App**: The AutoLog Flutter Android application.
- **Vehicle**: A user-registered car, bike, scooter, truck, or custom vehicle type.
- **Fuel Log**: A record of a single fuel refill event for a vehicle.
- **Service Log**: A record of a maintenance or repair event for a vehicle.
- **Expense Log**: A record of a miscellaneous vehicle-related expense.
- **Document**: An insurance, PUC, RC, or other certificate associated with a vehicle.
- **Reminder**: A local notification scheduled for a future date or odometer milestone.
- **Odometer**: The cumulative distance reading of a vehicle in km or miles.
- **Mileage**: Fuel efficiency expressed as km/litre, km/kg, or km/kWh depending on fuel type.
- **Analytics**: Aggregated charts and statistics derived from stored logs.
- **Backup**: A JSON file export of all app data for offline archival or restoration.
- **Database**: The local Hive or Isar embedded database storing all app data on-device.
- **Local_Storage**: The on-device storage layer (Database + SharedPreferences) used exclusively by the App.
- **Notification_Service**: The flutter_local_notifications-based service that schedules and delivers Reminders.
- **State_Manager**: The Riverpod or Provider state management layer.
- **Theme_Controller**: The component managing dark/light mode and accent color preferences.
- **Backup_Service**: The component responsible for JSON export and import of all app data.
- **Vehicle_Database**: The bundled local JSON file containing offline brand, model, and year data.
- **PIN_Lock**: The optional 4-digit app lock feature stored in SharedPreferences.

---

## Requirements

### Requirement 1: Offline-Only Data Storage

**User Story:** As a user, I want all my vehicle data stored entirely on my device, so that I never need an internet connection and my data remains private.

#### Acceptance Criteria

1. THE App SHALL store all user data exclusively in Local_Storage with no network calls at any time.
2. THE App SHALL function fully without an active internet connection, including on first launch.
3. THE Database SHALL persist all data across app restarts and device reboots.
4. THE App SHALL NOT require any user account, login, or signup to access any feature.
5. IF the Database fails to initialise, THEN THE App SHALL display an error message and prevent data loss by retrying initialisation before allowing writes.

---

### Requirement 2: Splash Screen and Onboarding

**User Story:** As a new user, I want a polished intro experience, so that I understand the app's value before I start using it.

#### Acceptance Criteria

1. WHEN the App is launched, THE App SHALL display a splash screen with the AutoLog logo animation for a minimum of 1.5 seconds and a maximum of 3 seconds before navigating to the next screen.
2. WHEN the App is launched for the first time, THE App SHALL display a 3-slide onboarding flow after the splash screen.
3. THE Onboarding SHALL present slides covering: (1) Manage all vehicles, (2) Track expenses, (3) Never miss service dates.
4. WHEN the user taps "Skip" or completes all onboarding slides, THE App SHALL navigate to the Home Dashboard and record that onboarding has been completed in Local_Storage.
5. WHEN the App is launched after onboarding has been completed, THE App SHALL navigate directly to the Home Dashboard after the splash screen, bypassing onboarding.

---

### Requirement 3: Home Dashboard

**User Story:** As a user, I want a single-screen overview of all my vehicles and activity, so that I can quickly assess the status of my fleet.

#### Acceptance Criteria

1. THE Home Dashboard SHALL display: total number of registered Vehicles, total fuel spend for the current calendar month across all Vehicles, upcoming service due dates within the next 30 days, Documents expiring within the next 30 days, a recent activity feed of the last 10 log entries, quick-add action buttons, total spend for the current calendar year, and an alerts badge showing the count of overdue or expiring items.
2. WHEN there are no registered Vehicles, THE Home Dashboard SHALL display an empty state illustration with a prompt to add the first Vehicle.
3. WHEN the user taps a quick-add button, THE App SHALL navigate to the corresponding log entry screen with the vehicle pre-selected if only one Vehicle exists.
4. WHEN new log data is saved, THE Home Dashboard SHALL reflect updated totals and activity without requiring a manual refresh.
5. THE Home Dashboard SHALL support pull-to-refresh to reload all summary data from Local_Storage.

---

### Requirement 4: Bottom Navigation

**User Story:** As a user, I want persistent bottom navigation, so that I can switch between major sections of the app instantly.

#### Acceptance Criteria

1. THE App SHALL display a bottom navigation bar with exactly five destinations: Home, Vehicles, Logs, Analytics, and Settings.
2. WHEN the user taps a bottom navigation destination, THE App SHALL navigate to that section without losing the state of previously visited sections.
3. THE Bottom Navigation SHALL highlight the currently active destination.

---

### Requirement 5: Vehicle Management

**User Story:** As a user, I want to add and manage multiple vehicles with detailed profiles, so that I can track each vehicle independently.

#### Acceptance Criteria

1. THE App SHALL allow the user to add an unlimited number of Vehicles.
2. WHEN adding a Vehicle, THE App SHALL require: vehicle nickname, number plate, brand, model, manufacturing year, fuel type, and current odometer reading.
3. WHEN adding a Vehicle, THE App SHALL allow the user to optionally provide: purchase date, a photo from the device gallery, and free-text notes.
4. WHEN the user selects a brand, THE App SHALL load the corresponding model list from the Vehicle_Database without a network call.
5. WHEN the user selects a model, THE App SHALL load the corresponding year range from the Vehicle_Database without a network call.
6. THE Vehicle_Database SHALL include Indian brands as the primary list: Honda, Maruti Suzuki, Hyundai, Tata, Mahindra, Toyota, Bajaj, Hero, TVS, Royal Enfield, Yamaha, Suzuki, Kia, MG, Renault, Volkswagen, Skoda, Ford, Jeep, and Other.
7. THE App SHALL support the following vehicle types: Car, Bike, Scooter, Truck, and a user-defined custom type.
8. WHEN a Vehicle is saved, THE App SHALL display it in the Vehicles list screen.
9. THE App SHALL allow the user to edit any field of an existing Vehicle.
10. WHEN the user initiates deletion of a Vehicle, THE App SHALL display a confirmation dialog before permanently removing the Vehicle and all associated logs, documents, and reminders from Local_Storage.
11. THE Vehicle Detail Screen SHALL present the following tabs: Overview, Fuel Logs, Service Logs, Expenses, Documents, and Notes.

---

### Requirement 6: Fuel Type and Unit System

**User Story:** As a user, I want fuel types and units to match my vehicle's actual fuel, so that mileage calculations are accurate.

#### Acceptance Criteria

1. THE App SHALL support the following fuel types with their default units: Petrol → Litres, Diesel → Litres, CNG → KG, Electric → kWh, Hybrid → Litres + kWh, LPG → Litres, Hydrogen → KG.
2. WHEN a Fuel Log is created, THE App SHALL pre-select the unit corresponding to the Vehicle's fuel type.
3. THE App SHALL allow the user to define a custom fuel type with a custom unit name.
4. THE App SHALL calculate and display Mileage as: km/litre for Petrol/Diesel/LPG, km/kg for CNG/Hydrogen, and km/kWh for Electric.
5. WHERE a Vehicle uses the Hybrid fuel type, THE App SHALL calculate and display both km/litre and km/kWh Mileage figures.

---

### Requirement 7: Fuel Logs

**User Story:** As a user, I want to log every fuel refill with full details, so that I can track my fuel efficiency and spending over time.

#### Acceptance Criteria

1. WHEN adding a Fuel Log, THE App SHALL require: date, quantity, total price, and current odometer reading.
2. WHEN adding a Fuel Log, THE App SHALL allow the user to optionally provide: fuel station name, a full-tank toggle, and free-text notes.
3. WHEN a Fuel Log is saved, THE App SHALL automatically calculate distance as the difference between the current odometer and the previous Fuel Log's odometer for the same Vehicle.
4. WHEN a Fuel Log is saved and the full-tank toggle is enabled, THE App SHALL automatically calculate and store Mileage as distance divided by quantity.
5. THE Fuel Log list for a Vehicle SHALL display: average Mileage, cost per km, monthly fuel spend, and the best Mileage record.
6. THE App SHALL allow the user to edit or delete any Fuel Log entry.
7. WHEN a Fuel Log is deleted, THE App SHALL recalculate the Mileage for the subsequent Fuel Log entry if one exists.

---

### Requirement 8: Service and Repair Logs

**User Story:** As a user, I want to record every service and repair event, so that I have a complete maintenance history and can plan future services.

#### Acceptance Criteria

1. WHEN adding a Service Log, THE App SHALL require: date, service type, and cost.
2. WHEN adding a Service Log, THE App SHALL allow the user to optionally provide: odometer reading, garage or workshop name, free-text notes, next due date, and next due odometer reading.
3. THE App SHALL support the following service types: Oil Change, Brake Service, General Service, Washing, Detailing, Tyre Rotation, Battery Replacement, Engine Repair, AC Repair, and a user-defined custom type.
4. WHEN a next due date or next due odometer is saved in a Service Log, THE App SHALL create a corresponding Reminder automatically.
5. THE App SHALL allow the user to edit or delete any Service Log entry.

---

### Requirement 9: Expense Logs

**User Story:** As a user, I want to log miscellaneous vehicle expenses, so that I can track the total cost of ownership.

#### Acceptance Criteria

1. WHEN adding an Expense Log, THE App SHALL require: date, category, and amount.
2. WHEN adding an Expense Log, THE App SHALL allow the user to optionally provide free-text notes.
3. THE App SHALL support the following expense categories: Toll, Parking, Fine, Accessories, Insurance Payment, Repairs, Loan EMI, and Miscellaneous.
4. THE App SHALL allow the user to edit or delete any Expense Log entry.

---

### Requirement 10: Documents Module

**User Story:** As a user, I want to store and track vehicle documents with expiry dates, so that I never miss a renewal deadline.

#### Acceptance Criteria

1. THE App SHALL support the following document types: Insurance, PUC, RC, Fitness Certificate, Warranty, Licence Copy, Pollution Certificate, and a user-defined custom type.
2. WHEN adding a Document, THE App SHALL require: document type and expiry date.
3. WHEN adding a Document, THE App SHALL allow the user to optionally provide: issue date, document number, and a photo or PDF file path from local storage.
4. WHEN a Document with an expiry date is saved, THE App SHALL automatically create a Reminder for 30 days before the expiry date and another for 7 days before the expiry date.
5. THE App SHALL allow the user to edit or delete any Document entry.
6. WHEN a Document's expiry date is within 30 days, THE Home Dashboard SHALL include it in the expiring documents alert count.

---

### Requirement 11: Reminder Center

**User Story:** As a user, I want local push notifications for upcoming deadlines and service milestones, so that I never miss an important vehicle event.

#### Acceptance Criteria

1. THE Notification_Service SHALL schedule local notifications for: Insurance expiry, PUC expiry, service due dates, service due odometer milestones, battery check reminders, tyre replacement reminders, and user-defined custom reminders.
2. WHEN a Reminder is triggered, THE Notification_Service SHALL deliver a local notification with the vehicle name, reminder type, and due date or due odometer in the notification body.
3. THE App SHALL allow the user to view all pending Reminders in the Reminder Center screen.
4. THE App SHALL allow the user to dismiss or delete any Reminder.
5. WHEN a Document or Service Log that generated a Reminder is deleted, THE Notification_Service SHALL cancel the associated scheduled notifications.
6. THE Notification_Service SHALL function without an internet connection.

---

### Requirement 12: Analytics Module

**User Story:** As a user, I want visual charts of my vehicle spending and efficiency, so that I can understand trends and make informed decisions.

#### Acceptance Criteria

1. THE Analytics Module SHALL display the following charts using fl_chart: monthly fuel spend (bar chart), yearly maintenance cost (bar chart), Mileage trend over time (line chart), expense category breakdown (pie chart), and total ownership cost per Vehicle (bar chart).
2. WHERE the user has more than one Vehicle, THE Analytics Module SHALL display a vehicle comparison chart showing total spend per Vehicle.
3. WHEN there is insufficient data to render a chart (fewer than 2 data points), THE Analytics Module SHALL display an informational empty state instead of a broken chart.
4. THE Analytics Module SHALL derive all chart data exclusively from Local_Storage with no network calls.

---

### Requirement 13: Logs Screen

**User Story:** As a user, I want a unified timeline of all my vehicle activity, so that I can review and search my complete history in one place.

#### Acceptance Criteria

1. THE Logs Screen SHALL display a combined chronological timeline of all Fuel Logs, Service Logs, Expense Logs, and Document entries across all Vehicles, sorted by date descending.
2. THE Logs Screen SHALL provide search functionality that filters entries by free-text matching against notes, garage names, and fuel station names.
3. THE Logs Screen SHALL provide filter controls for: date range, specific Vehicle, and log category (Fuel, Service, Expense, Document).
4. WHEN search or filter criteria are active, THE Logs Screen SHALL display only matching entries.
5. THE Logs Screen SHALL support swipe-to-delete on individual log entries with a confirmation dialog.

---

### Requirement 14: Settings Module

**User Story:** As a user, I want to customise the app's appearance and behaviour, so that it fits my preferences and regional standards.

#### Acceptance Criteria

1. THE Settings Module SHALL allow the user to toggle between dark mode and light mode, with the preference persisted in Local_Storage.
2. THE Settings Module SHALL allow the user to set the currency symbol, defaulting to INR (₹), with support for at least USD ($), EUR (€), GBP (£), and a free-text custom currency option.
3. THE Settings Module SHALL allow the user to toggle the distance unit between kilometres (km) and miles, with the preference persisted in Local_Storage.
4. WHEN the distance unit is changed, THE App SHALL display all stored odometer and distance values converted to the selected unit throughout the App.
5. THE Settings Module SHALL provide an "Export Backup" action that triggers the Backup_Service.
6. THE Settings Module SHALL provide an "Import Backup" action that triggers the Backup_Service.
7. THE Settings Module SHALL provide a "Reset All Data" action that, after a confirmation dialog, permanently deletes all data from Local_Storage.
8. THE Settings Module SHALL allow the user to enable, disable, and set a 4-digit PIN_Lock.
9. THE Settings Module SHALL include an About page displaying the app name, version, and tagline "Track Every Mile".

---

### Requirement 15: Backup and Restore

**User Story:** As a user, I want to export and import all my data as a JSON file, so that I can back up my records and restore them on the same or a different device.

#### Acceptance Criteria

1. WHEN the user triggers "Export Backup", THE Backup_Service SHALL serialise all Vehicles, Fuel Logs, Service Logs, Expense Logs, Documents, Reminders, and Settings into a single JSON file and save it to a user-accessible location on the device storage.
2. WHEN the user triggers "Import Backup", THE Backup_Service SHALL allow the user to select a JSON file from device storage, validate its structure, and restore all records into Local_Storage.
3. IF the selected import file has an invalid or unrecognised structure, THEN THE Backup_Service SHALL display a descriptive error message and leave existing data unchanged.
4. FOR ALL valid data sets, exporting then importing SHALL produce a state equivalent to the original data set (round-trip property).
5. WHEN an import completes successfully, THE App SHALL display a success message and refresh all screens to reflect the restored data.

---

### Requirement 16: App Lock (PIN)

**User Story:** As a user, I want to protect the app with a PIN, so that my vehicle and financial data remains private on a shared device.

#### Acceptance Criteria

1. WHEN PIN_Lock is enabled and the App is launched or resumed from background, THE App SHALL display a PIN entry screen before granting access to any other screen.
2. WHEN the user enters the correct PIN, THE App SHALL navigate to the Home Dashboard.
3. IF the user enters an incorrect PIN 5 consecutive times, THEN THE App SHALL lock the PIN entry screen for 60 seconds before allowing further attempts.
4. THE PIN_Lock SHALL be stored securely in Local_Storage using SharedPreferences with no plaintext exposure in logs.
5. WHEN PIN_Lock is disabled by the user in Settings, THE App SHALL remove the stored PIN from Local_Storage.

---

### Requirement 17: UI and Interaction Standards

**User Story:** As a user, I want a smooth, premium interface, so that the app feels polished and enjoyable to use daily.

#### Acceptance Criteria

1. THE App SHALL implement Material 3 design with a dark graphite primary theme and blue accent colour, with an optional light mode.
2. THE App SHALL use rounded cards, smooth page transition animations, and consistent elegant spacing throughout all screens.
3. THE App SHALL display skeleton loading states while data is being read from Local_Storage on initial screen load.
4. THE App SHALL display empty state illustrations with descriptive prompts on all list screens when no data exists.
5. THE App SHALL display snackbar confirmations after every successful create, update, or delete action.
6. WHEN the user initiates a delete action on any log entry or Vehicle, THE App SHALL display a confirmation dialog before executing the deletion.
7. THE App SHALL support swipe-to-delete gestures on all log list items.
8. THE App SHALL provide floating action buttons for primary create actions on list screens.
9. THE App SHALL remain responsive and complete all Local_Storage read operations within 300ms for lists of up to 10,000 log entries.

---

### Requirement 18: Project Structure and Code Quality

**User Story:** As a developer, I want a clean, well-organised codebase, so that the app is maintainable and extensible.

#### Acceptance Criteria

1. THE App SHALL organise source code into the following top-level directories under `lib/`: `main.dart`, `models/`, `data/`, `services/`, `providers/`, `screens/`, `widgets/`, `utils/`, and `theme/`.
2. THE App SHALL use null-safe Dart throughout with no implicit dynamic types.
3. THE App's `pubspec.yaml` SHALL declare exact version constraints for all dependencies including: flutter_riverpod or provider, hive_flutter or isar_flutter_libs, shared_preferences, flutter_local_notifications, intl, fl_chart, image_picker, file_picker, path_provider, and permission_handler.
4. THE App SHALL include all required asset declarations in `pubspec.yaml` for fonts, images, and the Vehicle_Database JSON file.
5. THE App SHALL compile and run successfully after `flutter pub get` with no import errors or missing asset errors.
6. THE App SHALL produce a release APK via `flutter build apk --release` without build errors.
