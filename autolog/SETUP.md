# AutoLog — Setup & Build Instructions

## App Overview

**AutoLog** is a premium personal offline vehicle management app for Android.  
Tagline: *Track Every Mile*

- 100% offline — no login, no cloud, no internet required
- Tracks fuel, service, expenses, documents, and reminders for multiple vehicles
- Built with Flutter (latest stable), Hive, Riverpod, and fl_chart

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.x stable (tested with 3.27+) |
| Dart | 3.x (null-safe) |
| Android Studio | Hedgehog or newer |
| Java | 17+ |
| Android SDK | API 21+ (minSdk), API 34 (targetSdk) |

---

## Running in Android Studio / VS Code

### 1. Clone / open the project

Open the `autolog/` folder as the project root in Android Studio or VS Code.

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Generate Hive TypeAdapters

The generated `*.g.dart` files are already committed. If you modify any model, regenerate with:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### 4. Run on a device or emulator

```bash
flutter run
```

Or use the Run button in Android Studio / VS Code with a connected Android device or emulator.

---

## APK Build Commands

### Debug APK

```bash
flutter build apk --debug
```

Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (unsigned, uses debug keystore)

```bash
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

> **Note:** The release build uses the debug signing key by default. For Play Store distribution, configure a proper keystore in `android/app/build.gradle.kts`.

### Release APK (if Gradle lint cache issues occur)

```bash
flutter clean
flutter pub get
flutter build apk --release --no-shrink
```

---

## Release Build Steps (Play Store)

1. Generate a keystore:
   ```bash
   keytool -genkey -v -keystore autolog-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias autolog
   ```

2. Create `android/key.properties`:
   ```
   storePassword=<your-store-password>
   keyPassword=<your-key-password>
   keyAlias=autolog
   storeFile=../autolog-release.jks
   ```

3. Update `android/app/build.gradle.kts` to reference the keystore:
   ```kotlin
   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

4. Build:
   ```bash
   flutter build apk --release
   ```

---

## Running Tests

### Unit & property-based tests

```bash
flutter test
```

### Widget tests

```bash
flutter test test/widget/
```

### Integration tests (requires connected device/emulator)

```bash
flutter test integration_test/app_test.dart
flutter test integration_test/performance_test.dart
```

---

## Project Structure

```
autolog/
├── lib/
│   ├── main.dart              # App entry point
│   ├── router.dart            # go_router configuration
│   ├── models/                # Hive data models + enums
│   ├── data/                  # Repositories + VehicleDatabase
│   ├── services/              # BackupService, NotificationService, PinService, AnalyticsService
│   ├── providers/             # Riverpod providers
│   ├── screens/               # All UI screens
│   ├── widgets/               # Reusable widgets
│   ├── utils/                 # MileageCalculator, UnitConverter, Validators, Formatters
│   └── theme/                 # AppTheme, AppColors, ThemeController
├── assets/
│   └── data/vehicle_database.json   # Offline brand/model/year database
├── test/                      # Unit, property-based, and widget tests
├── integration_test/          # Integration and performance tests
└── android/                   # Android-specific configuration
```

---

## Key Features

- **Multiple vehicles** — Car, Bike, Scooter, Truck, Custom
- **Fuel logs** — Auto mileage calculation (km/L, km/kg, km/kWh)
- **Service logs** — With next-due reminders
- **Expense tracking** — Toll, Parking, Insurance, etc.
- **Documents** — Insurance, PUC, RC with expiry reminders
- **Analytics** — fl_chart bar/line/pie charts
- **Backup/Restore** — JSON export/import
- **App Lock** — 4-digit PIN (SHA-256 hashed)
- **Dark/Light mode** — Material 3 design
- **100% offline** — No network calls ever
