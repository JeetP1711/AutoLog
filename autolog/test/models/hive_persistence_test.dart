// ignore_for_file: avoid_print

import 'dart:io';

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

/// Converts a TZDateTime (returned by kiri_check's dateTime()) to a plain
/// UTC DateTime so that Hive round-trips are lossless (Hive stores DateTime
/// as microseconds since epoch, which is timezone-agnostic).
DateTime _toUtc(DateTime dt) =>
    DateTime.fromMicrosecondsSinceEpoch(dt.microsecondsSinceEpoch, isUtc: true);

/// Nullable helper: generates either null or a value from [inner] with equal
/// probability.
Arbitrary<T?> nullable<T>(Arbitrary<T> inner) =>
    (frequency([
      (1, null_()),
      (1, inner),
    ]) as Arbitrary<dynamic>)
        .map((v) => v as T?);

// ---------------------------------------------------------------------------
// Custom arbitraries
// ---------------------------------------------------------------------------

Arbitrary<FuelType> _fuelTypeArb() =>
    constantFrom(FuelType.values);

Arbitrary<VehicleType> _vehicleTypeArb() =>
    constantFrom(VehicleType.values);

Arbitrary<ReminderType> _reminderTypeArb() =>
    constantFrom(ReminderType.values);

/// Non-empty alphanumeric ASCII string (avoids null bytes that Hive may reject).
Arbitrary<String> _safeString() => string(
      minLength: 1,
      maxLength: 40,
      characterSet: CharacterSet.alphanum(CharacterEncoding.ascii),
    );

Arbitrary<String?> _nullableString() => nullable(_safeString());

/// Positive finite double in a reasonable range.
Arbitrary<double> _positiveDouble() =>
    float(min: 0.01, max: 1000000.0, nan: false, infinity: false);

Arbitrary<double?> _nullableDouble() => nullable(_positiveDouble());

/// DateTime mapped to UTC to ensure round-trip equality.
Arbitrary<DateTime> _dateTimeArb() =>
    dateTime(
      min: DateTime(2000),
      max: DateTime(2099, 12, 31),
    ).map(_toUtc);

Arbitrary<DateTime?> _nullableDateTimeArb() => nullable(_dateTimeArb());

// --- Vehicle ---

Arbitrary<Vehicle> _vehicleArb() => combine8(
      _safeString(), // id
      _safeString(), // nickname
      _safeString(), // numberPlate
      _safeString(), // brand
      _safeString(), // model
      integer(min: 1900, max: 2099), // year
      _fuelTypeArb(),
      _vehicleTypeArb(),
    ).flatMap(
      (t) => combine8(
        constant(t.$1), // id
        constant(t.$2), // nickname
        constant(t.$3), // numberPlate
        constant(t.$4), // brand
        constant(t.$5), // model
        constant(t.$6), // year
        constant(t.$7), // fuelType
        constant(t.$8), // vehicleType
      ).flatMap(
        (inner) => combine8(
          constant(inner.$1),
          constant(inner.$2),
          constant(inner.$3),
          constant(inner.$4),
          constant(inner.$5),
          constant(inner.$6),
          constant(inner.$7),
          constant(inner.$8),
        ).flatMap(
          (_) => combine8(
            _positiveDouble(), // odometerKm
            _dateTimeArb(), // createdAt
            _nullableDateTimeArb(), // purchaseDate
            _nullableString(), // photoPath
            _nullableString(), // notes
            _nullableString(), // customFuelType
            _nullableString(), // customFuelUnit
            constant(t), // carry original tuple
          ).map(
            (extra) => Vehicle(
              id: t.$1,
              nickname: t.$2,
              numberPlate: t.$3,
              brand: t.$4,
              model: t.$5,
              year: t.$6,
              fuelType: t.$7,
              vehicleType: t.$8,
              odometerKm: extra.$1,
              createdAt: extra.$2,
              purchaseDate: extra.$3,
              photoPath: extra.$4,
              notes: extra.$5,
              customFuelType: extra.$6,
              customFuelUnit: extra.$7,
            ),
          ),
        ),
      ),
    );

// --- FuelLog ---

Arbitrary<FuelLog> _fuelLogArb() => combine8(
      _safeString(), // id
      _safeString(), // vehicleId
      _dateTimeArb(), // date
      _positiveDouble(), // quantity
      _positiveDouble(), // totalPrice
      _positiveDouble(), // odometerKm
      boolean(), // isFullTank
      _nullableString(), // stationName
    ).flatMap(
      (t) => combine3(
        _nullableString(), // notes
        _nullableDouble(), // mileage
        _nullableDouble(), // distanceKm
      ).map(
        (extra) => FuelLog(
          id: t.$1,
          vehicleId: t.$2,
          date: t.$3,
          quantity: t.$4,
          totalPrice: t.$5,
          odometerKm: t.$6,
          isFullTank: t.$7,
          stationName: t.$8,
          notes: extra.$1,
          mileage: extra.$2,
          distanceKm: extra.$3,
        ),
      ),
    );

// --- ServiceLog ---

Arbitrary<ServiceLog> _serviceLogArb() => combine8(
      _safeString(), // id
      _safeString(), // vehicleId
      _dateTimeArb(), // date
      _safeString(), // serviceType
      _positiveDouble(), // cost
      _nullableDouble(), // odometerKm
      _nullableString(), // garageName
      _nullableString(), // notes
    ).flatMap(
      (t) => combine2(
        _nullableDateTimeArb(), // nextDueDate
        _nullableDouble(), // nextDueOdometerKm
      ).map(
        (extra) => ServiceLog(
          id: t.$1,
          vehicleId: t.$2,
          date: t.$3,
          serviceType: t.$4,
          cost: t.$5,
          odometerKm: t.$6,
          garageName: t.$7,
          notes: t.$8,
          nextDueDate: extra.$1,
          nextDueOdometerKm: extra.$2,
        ),
      ),
    );

// --- ExpenseLog ---

Arbitrary<ExpenseLog> _expenseLogArb() => combine6(
      _safeString(), // id
      _safeString(), // vehicleId
      _dateTimeArb(), // date
      _safeString(), // category
      _positiveDouble(), // amount
      _nullableString(), // notes
    ).map(
      (t) => ExpenseLog(
        id: t.$1,
        vehicleId: t.$2,
        date: t.$3,
        category: t.$4,
        amount: t.$5,
        notes: t.$6,
      ),
    );

// --- Document ---

Arbitrary<Document> _documentArb() => combine7(
      _safeString(), // id
      _safeString(), // vehicleId
      _safeString(), // documentType
      _dateTimeArb(), // expiryDate
      _nullableDateTimeArb(), // issueDate
      _nullableString(), // documentNumber
      _nullableString(), // filePath
    ).map(
      (t) => Document(
        id: t.$1,
        vehicleId: t.$2,
        documentType: t.$3,
        expiryDate: t.$4,
        issueDate: t.$5,
        documentNumber: t.$6,
        filePath: t.$7,
      ),
    );

// --- Reminder ---

Arbitrary<Reminder> _reminderArb() => combine8(
      _safeString(), // id
      _safeString(), // vehicleId
      _safeString(), // title
      _safeString(), // body
      _reminderTypeArb(),
      boolean(), // isDismissed
      _dateTimeArb(), // createdAt
      _nullableDateTimeArb(), // dueDate
    ).flatMap(
      (t) => combine2(
        _nullableDouble(), // dueOdometerKm
        _nullableString(), // sourceId
      ).map(
        (extra) => Reminder(
          id: t.$1,
          vehicleId: t.$2,
          title: t.$3,
          body: t.$4,
          reminderType: t.$5,
          isDismissed: t.$6,
          createdAt: t.$7,
          dueDate: t.$8,
          dueOdometerKm: extra.$1,
          sourceId: extra.$2,
        ),
      ),
    );

// ---------------------------------------------------------------------------
// Round-trip helper
// ---------------------------------------------------------------------------

/// Writes [value] to a fresh Hive box under [boxName], closes the box,
/// reopens it, reads the value back, and returns it.
Future<T> _roundTrip<T>(
  String boxName,
  T value,
  Directory dir,
) async {
  // Use a unique box name per call to avoid cross-test contamination.
  final uniqueBox = '${boxName}_${DateTime.now().microsecondsSinceEpoch}';

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

  // Each property test gets its own temp directory, cleaned up in tearDown.
  late Directory tempDir;

  setUp(() {
    tempDir = _createTempDir();
  });

  tearDown(() async {
    // Close any lingering boxes before deleting the directory.
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
        _vehicleArb(),
        maxExamples: 50,
        (original) async {
          final restored = await _roundTrip<Vehicle>(
            'vehicles',
            original,
            tempDir,
          );

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
        _fuelLogArb(),
        maxExamples: 50,
        (original) async {
          final restored = await _roundTrip<FuelLog>(
            'fuel_logs',
            original,
            tempDir,
          );

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
        _serviceLogArb(),
        maxExamples: 50,
        (original) async {
          final restored = await _roundTrip<ServiceLog>(
            'service_logs',
            original,
            tempDir,
          );

          expect(restored.id, equals(original.id));
          expect(restored.vehicleId, equals(original.vehicleId));
          expect(restored.date, equals(original.date));
          expect(restored.serviceType, equals(original.serviceType));
          expect(restored.cost, equals(original.cost));
          expect(restored.odometerKm, equals(original.odometerKm));
          expect(restored.garageName, equals(original.garageName));
          expect(restored.notes, equals(original.notes));
          expect(restored.nextDueDate, equals(original.nextDueDate));
          expect(restored.nextDueOdometerKm, equals(original.nextDueOdometerKm));
          expect(restored, equals(original));
        },
      );
    });

    property('ExpenseLog round-trip preserves all field values', () {
      forAll(
        _expenseLogArb(),
        maxExamples: 50,
        (original) async {
          final restored = await _roundTrip<ExpenseLog>(
            'expense_logs',
            original,
            tempDir,
          );

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
        _documentArb(),
        maxExamples: 50,
        (original) async {
          final restored = await _roundTrip<Document>(
            'documents',
            original,
            tempDir,
          );

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
        _reminderArb(),
        maxExamples: 50,
        (original) async {
          final restored = await _roundTrip<Reminder>(
            'reminders',
            original,
            tempDir,
          );

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
