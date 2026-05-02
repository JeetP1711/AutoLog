// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kiri_check/kiri_check.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import 'package:autolog/models/document.dart';
import 'package:autolog/models/enums.dart';
import 'package:autolog/models/expense_log.dart';
import 'package:autolog/models/fuel_log.dart';
import 'package:autolog/models/reminder.dart';
import 'package:autolog/models/service_log.dart';
import 'package:autolog/models/vehicle.dart';

/// **Validates: Requirements 1.3**
///
/// Property 9: Hive persistence round-trip
///
/// For any model instance (Vehicle, FuelLog, ServiceLog, ExpenseLog, Document,
/// or Reminder), writing it to its Hive box, closing the box, reopening the
/// box, and reading it back SHALL produce an instance with all field values
/// equal to the original.

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Registers all Hive TypeAdapters exactly once.
bool _adaptersRegistered = false;

void _registerAdapters() {
  if (_adaptersRegistered) return;
  Hive.registerAdapter(FuelTypeAdapter());
  Hive.registerAdapter(VehicleTypeAdapter());
  Hive.registerAdapter(DistanceUnitAdapter());
  Hive.registerAdapter(ReminderTypeAdapter());
  Hive.registerAdapter(VehicleAdapter());
  Hive.registerAdapter(FuelLogAdapter());
  Hive.registerAdapter(ServiceLogAdapter());
  Hive.registerAdapter(ExpenseLogAdapter());
  Hive.registerAdapter(DocumentAdapter());
  Hive.registerAdapter(ReminderAdapter());
  _adaptersRegistered = true;
}

/// Creates a fresh temporary directory for each test run.
Directory _createTempDir() {
  return Directory.systemTemp.createTempSync('hive_persistence_test_');
}

// ---------------------------------------------------------------------------
// Seeded random helpers
//
// kiri_check's `build()` arbitrary receives no seed, so we use a shared
// Random seeded from the test framework's implicit randomness. Each call to
// `build()` produces one instance; kiri_check calls the builder repeatedly
// with different internal seeds, giving us the variety we need.
// ---------------------------------------------------------------------------

final _rng = math.Random();

/// Returns a random alphanumeric string of length 1–20.
String _randString([int maxLen = 20]) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final len = 1 + _rng.nextInt(maxLen);
  return List.generate(len, (_) => chars[_rng.nextInt(chars.length)]).join();
}

/// Returns a random nullable string (50 % chance of null).
String? _randNullableString() => _rng.nextBool() ? _randString() : null;

/// Returns a random positive double in [0.01, 1_000_000].
double _randDouble() => 0.01 + _rng.nextDouble() * 999999.99;

/// Returns a random nullable double (50 % chance of null).
double? _randNullableDouble() => _rng.nextBool() ? _randDouble() : null;

/// Returns a random UTC DateTime between 2000-01-01 and 2099-12-31.
/// Stored as UTC so Hive round-trips are lossless (Hive stores microseconds
/// since epoch, which is timezone-agnostic).
DateTime _randDateTime() {
  final minMs = DateTime.utc(2000).microsecondsSinceEpoch;
  final maxMs = DateTime.utc(2099, 12, 31, 23, 59, 59).microsecondsSinceEpoch;
  final us = minMs + (_rng.nextDouble() * (maxMs - minMs)).toInt();
  return DateTime.fromMicrosecondsSinceEpoch(us, isUtc: true);
}

/// Returns a random nullable DateTime (50 % chance of null).
DateTime? _randNullableDateTime() => _rng.nextBool() ? _randDateTime() : null;

T _randEnum<T>(List<T> values) => values[_rng.nextInt(values.length)];

// ---------------------------------------------------------------------------
// Model builders
// ---------------------------------------------------------------------------

Vehicle _buildVehicle() => Vehicle(
      id: _randString(),
      nickname: _randString(),
      numberPlate: _randString(),
      brand: _randString(),
      model: _randString(),
      year: 1900 + _rng.nextInt(200),
      fuelType: _randEnum(FuelType.values),
      vehicleType: _randEnum(VehicleType.values),
      odometerKm: _randDouble(),
      createdAt: _randDateTime(),
      purchaseDate: _randNullableDateTime(),
      photoPath: _randNullableString(),
      notes: _randNullableString(),
      customFuelType: _randNullableString(),
      customFuelUnit: _randNullableString(),
    );

FuelLog _buildFuelLog() => FuelLog(
      id: _randString(),
      vehicleId: _randString(),
      date: _randDateTime(),
      quantity: _randDouble(),
      totalPrice: _randDouble(),
      odometerKm: _randDouble(),
      isFullTank: _rng.nextBool(),
      stationName: _randNullableString(),
      notes: _randNullableString(),
      mileage: _randNullableDouble(),
      distanceKm: _randNullableDouble(),
    );

ServiceLog _buildServiceLog() => ServiceLog(
      id: _randString(),
      vehicleId: _randString(),
      date: _randDateTime(),
      serviceType: _randString(),
      cost: _randDouble(),
      odometerKm: _randNullableDouble(),
      garageName: _randNullableString(),
      notes: _randNullableString(),
      nextDueDate: _randNullableDateTime(),
      nextDueOdometerKm: _randNullableDouble(),
    );

ExpenseLog _buildExpenseLog() => ExpenseLog(
      id: _randString(),
      vehicleId: _randString(),
      date: _randDateTime(),
      category: _randString(),
      amount: _randDouble(),
      notes: _randNullableString(),
    );

Document _buildDocument() => Document(
      id: _randString(),
      vehicleId: _randString(),
      documentType: _randString(),
      expiryDate: _randDateTime(),
      issueDate: _randNullableDateTime(),
      documentNumber: _randNullableString(),
      filePath: _randNullableString(),
    );

Reminder _buildReminder() => Reminder(
      id: _randString(),
      vehicleId: _randString(),
      title: _randString(),
      body: _randString(),
      reminderType: _randEnum(ReminderType.values),
      isDismissed: _rng.nextBool(),
      createdAt: _randDateTime(),
      dueDate: _randNullableDateTime(),
      dueOdometerKm: _randNullableDouble(),
      sourceId: _randNullableString(),
    );

// ---------------------------------------------------------------------------
// Round-trip helper
// ---------------------------------------------------------------------------

/// Writes [value] to a fresh Hive box, closes the box, reopens it, reads the
/// value back, and returns it.  A unique box name is used per call to avoid
/// cross-iteration contamination.
Future<T> _roundTrip<T>(String boxPrefix, T value, Directory dir) async {
  final uniqueBox =
      '${boxPrefix}_${DateTime.now().microsecondsSinceEpoch}_${_rng.nextInt(1 << 30)}';

  Hive.init(dir.path);

  final writeBox = await Hive.openBox<T>(uniqueBox);
  await writeBox.put('key', value);
  await writeBox.close();

  final readBox = await Hive.openBox<T>(uniqueBox);
  final result = readBox.get('key') as T;
  await readBox.close();

  return result;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    _registerAdapters();
  });

  late Directory tempDir;

  setUp(() {
    tempDir = _createTempDir();
  });

  tearDown(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {
      // Best-effort cleanup.
    }
  });

  // -------------------------------------------------------------------------
  // Property 9: Hive persistence round-trip
  // -------------------------------------------------------------------------

  group('Property 9: Hive persistence round-trip', () {
    property('Vehicle round-trip preserves all field values', () {
      forAll(
        build(_buildVehicle),
        maxExamples: 50,
        (original) async {
          final restored =
              await _roundTrip<Vehicle>('vehicles', original, tempDir);

          expect(restored.id, equals(original.id));
          expect(restored.nickname, equals(original.nickname));
          expect(restored.numberPlate, equals(original.numberPlate));
          expect(restored.brand, equals(original.brand));
          expect(restored.model, equals(original.model));
          expect(restored.year, equals(original.year));
          expect(restored.fuelType, equals(original.fuelType));
          expect(restored.vehicleType, equals(original.vehicleType));
          expect(restored.odometerKm, equals(original.odometerKm));
          expect(restored.createdAt, equals(original.createdAt));
          expect(restored.purchaseDate, equals(original.purchaseDate));
          expect(restored.photoPath, equals(original.photoPath));
          expect(restored.notes, equals(original.notes));
          expect(restored.customFuelType, equals(original.customFuelType));
          expect(restored.customFuelUnit, equals(original.customFuelUnit));
          expect(restored, equals(original));
        },
      );
    });

    property('FuelLog round-trip preserves all field values', () {
      forAll(
        build(_buildFuelLog),
        maxExamples: 50,
        (original) async {
          final restored =
              await _roundTrip<FuelLog>('fuel_logs', original, tempDir);

          expect(restored.id, equals(original.id));
          expect(restored.vehicleId, equals(original.vehicleId));
          expect(restored.date, equals(original.date));
          expect(restored.quantity, equals(original.quantity));
          expect(restored.totalPrice, equals(original.totalPrice));
          expect(restored.odometerKm, equals(original.odometerKm));
          expect(restored.isFullTank, equals(original.isFullTank));
          expect(restored.stationName, equals(original.stationName));
          expect(restored.notes, equals(original.notes));
          expect(restored.mileage, equals(original.mileage));
          expect(restored.distanceKm, equals(original.distanceKm));
          expect(restored, equals(original));
        },
      );
    });

    property('ServiceLog round-trip preserves all field values', () {
      forAll(
        build(_buildServiceLog),
        maxExamples: 50,
        (original) async {
          final restored =
              await _roundTrip<ServiceLog>('service_logs', original, tempDir);

          expect(restored.id, equals(original.id));
          expect(restored.vehicleId, equals(original.vehicleId));
          expect(restored.date, equals(original.date));
          expect(restored.serviceType, equals(original.serviceType));
          expect(restored.cost, equals(original.cost));
          expect(restored.odometerKm, equals(original.odometerKm));
          expect(restored.garageName, equals(original.garageName));
          expect(restored.notes, equals(original.notes));
          expect(restored.nextDueDate, equals(original.nextDueDate));
          expect(
              restored.nextDueOdometerKm, equals(original.nextDueOdometerKm));
          expect(restored, equals(original));
        },
      );
    });

    property('ExpenseLog round-trip preserves all field values', () {
      forAll(
        build(_buildExpenseLog),
        maxExamples: 50,
        (original) async {
          final restored =
              await _roundTrip<ExpenseLog>('expense_logs', original, tempDir);

          expect(restored.id, equals(original.id));
          expect(restored.vehicleId, equals(original.vehicleId));
          expect(restored.date, equals(original.date));
          expect(restored.category, equals(original.category));
          expect(restored.amount, equals(original.amount));
          expect(restored.notes, equals(original.notes));
          expect(restored, equals(original));
        },
      );
    });

    property('Document round-trip preserves all field values', () {
      forAll(
        build(_buildDocument),
        maxExamples: 50,
        (original) async {
          final restored =
              await _roundTrip<Document>('documents', original, tempDir);

          expect(restored.id, equals(original.id));
          expect(restored.vehicleId, equals(original.vehicleId));
          expect(restored.documentType, equals(original.documentType));
          expect(restored.expiryDate, equals(original.expiryDate));
          expect(restored.issueDate, equals(original.issueDate));
          expect(restored.documentNumber, equals(original.documentNumber));
          expect(restored.filePath, equals(original.filePath));
          expect(restored, equals(original));
        },
      );
    });

    property('Reminder round-trip preserves all field values', () {
      forAll(
        build(_buildReminder),
        maxExamples: 50,
        (original) async {
          final restored =
              await _roundTrip<Reminder>('reminders', original, tempDir);

          expect(restored.id, equals(original.id));
          expect(restored.vehicleId, equals(original.vehicleId));
          expect(restored.title, equals(original.title));
          expect(restored.body, equals(original.body));
          expect(restored.reminderType, equals(original.reminderType));
          expect(restored.isDismissed, equals(original.isDismissed));
          expect(restored.createdAt, equals(original.createdAt));
          expect(restored.dueDate, equals(original.dueDate));
          expect(restored.dueOdometerKm, equals(original.dueOdometerKm));
          expect(restored.sourceId, equals(original.sourceId));
          expect(restored, equals(original));
        },
      );
    });
  });
}
