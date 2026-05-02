// Feature: autolog-vehicle-manager
// Property 9: Hive persistence round-trip
//
// For each model type, generate random instances, write to a temporary Hive
// box, close and reopen the box, read back, and assert all field values are
// equal to the originals.
//
// Validates: Requirements 1.3

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Registers all Hive adapters once per test run.
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

/// Opens a fresh Hive box in [dir], writes [value] under key 0, closes the
/// box, reopens it, reads the value back, and returns it.
Future<T> _roundTrip<T>(Directory dir, String boxName, T value) async {
  final box = await Hive.openBox<T>(boxName, path: dir.path);
  await box.put(0, value);
  await box.close();

  final reopened = await Hive.openBox<T>(boxName, path: dir.path);
  final result = reopened.get(0) as T;
  await reopened.close();
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Arbitraries
// ─────────────────────────────────────────────────────────────────────────────

/// Generates a non-empty printable ASCII string of length 1–40.
Arbitrary<String> get _nonEmptyString =>
    string(minLength: 1, maxLength: 40).map((s) => s.isEmpty ? 'x' : s);

/// Generates an optional string (null or non-empty).
Arbitrary<String?> get _optionalString =>
    frequency([
      Tuple2(1, constant(null)),
      Tuple2(3, _nonEmptyString),
    ]);

/// Generates a DateTime between 2000-01-01 and 2030-12-31 (no sub-second
/// precision, since Hive stores DateTime as microseconds but equality uses
/// the full value — we strip microseconds to avoid floating-point drift).
Arbitrary<DateTime> get _dateTime => integer(min: 0, max: 10_000).map(
      (days) => DateTime(2000).add(Duration(days: days)),
    );

Arbitrary<DateTime?> get _optionalDateTime =>
    frequency([
      Tuple2(1, constant(null)),
      Tuple2(3, _dateTime),
    ]);

Arbitrary<FuelType> get _fuelType =>
    integer(min: 0, max: FuelType.values.length - 1)
        .map((i) => FuelType.values[i]);

Arbitrary<VehicleType> get _vehicleType =>
    integer(min: 0, max: VehicleType.values.length - 1)
        .map((i) => VehicleType.values[i]);

Arbitrary<ReminderType> get _reminderType =>
    integer(min: 0, max: ReminderType.values.length - 1)
        .map((i) => ReminderType.values[i]);

Arbitrary<double> get _positiveDouble =>
    float(min: 0.01, max: 999_999.0, withNaN: false, withInfinities: false);

Arbitrary<double?> get _optionalDouble =>
    frequency([
      Tuple2(1, constant(null)),
      Tuple2(3, _positiveDouble),
    ]);

Arbitrary<Vehicle> get _vehicle => combine7(
      _nonEmptyString,
      _nonEmptyString,
      _nonEmptyString,
      _nonEmptyString,
      _nonEmptyString,
      _fuelType,
      _vehicleType,
      (id, nickname, plate, brand, model, fuelType, vehicleType) => Vehicle(
        id: id,
        nickname: nickname,
        numberPlate: plate,
        brand: brand,
        model: model,
        year: 2020,
        fuelType: fuelType,
        vehicleType: vehicleType,
        odometerKm: 10000.0,
        createdAt: DateTime(2024),
      ),
    );

Arbitrary<FuelLog> get _fuelLog => combine7(
      _nonEmptyString,
      _nonEmptyString,
      _dateTime,
      _positiveDouble,
      _positiveDouble,
      _positiveDouble,
      boolean(),
      (id, vehicleId, date, qty, price, odo, fullTank) => FuelLog(
        id: id,
        vehicleId: vehicleId,
        date: date,
        quantity: qty,
        totalPrice: price,
        odometerKm: odo,
        isFullTank: fullTank,
      ),
    );

Arbitrary<ServiceLog> get _serviceLog => combine5(
      _nonEmptyString,
      _nonEmptyString,
      _dateTime,
      _nonEmptyString,
      _positiveDouble,
      (id, vehicleId, date, serviceType, cost) => ServiceLog(
        id: id,
        vehicleId: vehicleId,
        date: date,
        serviceType: serviceType,
        cost: cost,
      ),
    );

Arbitrary<ExpenseLog> get _expenseLog => combine5(
      _nonEmptyString,
      _nonEmptyString,
      _dateTime,
      _nonEmptyString,
      _positiveDouble,
      (id, vehicleId, date, category, amount) => ExpenseLog(
        id: id,
        vehicleId: vehicleId,
        date: date,
        category: category,
        amount: amount,
      ),
    );

Arbitrary<Document> get _document => combine4(
      _nonEmptyString,
      _nonEmptyString,
      _nonEmptyString,
      _dateTime,
      (id, vehicleId, docType, expiry) => Document(
        id: id,
        vehicleId: vehicleId,
        documentType: docType,
        expiryDate: expiry,
      ),
    );

Arbitrary<Reminder> get _reminder => combine5(
      _nonEmptyString,
      _nonEmptyString,
      _nonEmptyString,
      _nonEmptyString,
      _reminderType,
      (id, vehicleId, title, body, reminderType) => Reminder(
        id: id,
        vehicleId: vehicleId,
        title: title,
        body: body,
        reminderType: reminderType,
        isDismissed: false,
        createdAt: DateTime(2024),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('autolog_hive_test_');
    Hive.init(tempDir.path);
    _registerAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // Each test uses a unique box name to avoid cross-test contamination.

  test('Vehicle: Hive persistence round-trip', () async {
    property(
      forAll(_vehicle),
      (vehicle) async {
        final boxName = 'vehicles_${vehicle.id.hashCode.abs()}';
        final restored = await _roundTrip<Vehicle>(tempDir, boxName, vehicle);
        expect(restored, equals(vehicle),
            reason: 'Vehicle fields must survive a Hive write/close/reopen cycle');
      },
    );
  });

  test('FuelLog: Hive persistence round-trip', () async {
    property(
      forAll(_fuelLog),
      (log) async {
        final boxName = 'fuel_logs_${log.id.hashCode.abs()}';
        final restored = await _roundTrip<FuelLog>(tempDir, boxName, log);
        expect(restored, equals(log),
            reason: 'FuelLog fields must survive a Hive write/close/reopen cycle');
      },
    );
  });

  test('ServiceLog: Hive persistence round-trip', () async {
    property(
      forAll(_serviceLog),
      (log) async {
        final boxName = 'service_logs_${log.id.hashCode.abs()}';
        final restored = await _roundTrip<ServiceLog>(tempDir, boxName, log);
        expect(restored, equals(log),
            reason: 'ServiceLog fields must survive a Hive write/close/reopen cycle');
      },
    );
  });

  test('ExpenseLog: Hive persistence round-trip', () async {
    property(
      forAll(_expenseLog),
      (log) async {
        final boxName = 'expense_logs_${log.id.hashCode.abs()}';
        final restored = await _roundTrip<ExpenseLog>(tempDir, boxName, log);
        expect(restored, equals(log),
            reason: 'ExpenseLog fields must survive a Hive write/close/reopen cycle');
      },
    );
  });

  test('Document: Hive persistence round-trip', () async {
    property(
      forAll(_document),
      (doc) async {
        final boxName = 'documents_${doc.id.hashCode.abs()}';
        final restored = await _roundTrip<Document>(tempDir, boxName, doc);
        expect(restored, equals(doc),
            reason: 'Document fields must survive a Hive write/close/reopen cycle');
      },
    );
  });

  test('Reminder: Hive persistence round-trip', () async {
    property(
      forAll(_reminder),
      (reminder) async {
        final boxName = 'reminders_${reminder.id.hashCode.abs()}';
        final restored = await _roundTrip<Reminder>(tempDir, boxName, reminder);
        expect(restored, equals(reminder),
            reason: 'Reminder fields must survive a Hive write/close/reopen cycle');
      },
    );
  });
}
