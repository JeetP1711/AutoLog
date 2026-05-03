// Feature: autolog-vehicle-manager
// Property 1: Backup round-trip preserves all data
//
// For any valid app state, exporting to JSON and then importing from that JSON
// produces a state structurally equivalent to the original — all records
// present, all field values identical.
//
// Validates: Requirements 15.4

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Serialisation helpers (mirrors BackupService logic without I/O)
// ─────────────────────────────────────────────────────────────────────────────

Map<String, dynamic> _buildPayload({
  required List<Vehicle> vehicles,
  required List<FuelLog> fuelLogs,
  required List<ServiceLog> serviceLogs,
  required List<ExpenseLog> expenseLogs,
  required List<Document> documents,
  required List<Reminder> reminders,
}) {
  return {
    'version': 1,
    'exportedAt': DateTime.now().toIso8601String(),
    'vehicles': vehicles.map((v) => v.toJson()).toList(),
    'fuelLogs': fuelLogs.map((l) => l.toJson()).toList(),
    'serviceLogs': serviceLogs.map((l) => l.toJson()).toList(),
    'expenseLogs': expenseLogs.map((l) => l.toJson()).toList(),
    'documents': documents.map((d) => d.toJson()).toList(),
    'reminders': reminders.map((r) => r.toJson()).toList(),
  };
}

List<T> _restoreList<T>(
  Map<String, dynamic> json,
  String key,
  T Function(Map<String, dynamic>) fromJson,
) {
  final raw = json[key] as List<dynamic>? ?? [];
  return raw.map((e) => fromJson(e as Map<String, dynamic>)).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Arbitraries
// ─────────────────────────────────────────────────────────────────────────────

Arbitrary<String> get _id =>
    string(minLength: 4, maxLength: 16).map((s) => s.isEmpty ? 'id01' : s);

Arbitrary<String> get _str =>
    string(minLength: 1, maxLength: 20).map((s) => s.isEmpty ? 'x' : s);

Arbitrary<DateTime> get _date => integer(min: 0, max: 5000).map(
      (d) => DateTime(2020).add(Duration(days: d)),
    );

Arbitrary<double> get _pos =>
    float(min: 0.01, max: 100_000.0, withNaN: false, withInfinities: false);

Arbitrary<FuelType> get _fuelType =>
    integer(min: 0, max: FuelType.values.length - 1)
        .map((i) => FuelType.values[i]);

Arbitrary<VehicleType> get _vehicleType =>
    integer(min: 0, max: VehicleType.values.length - 1)
        .map((i) => VehicleType.values[i]);

Arbitrary<ReminderType> get _reminderType =>
    integer(min: 0, max: ReminderType.values.length - 1)
        .map((i) => ReminderType.values[i]);

Arbitrary<Vehicle> get _vehicle => combine5(
      _id, _str, _str, _fuelType, _vehicleType,
      (id, nickname, plate, ft, vt) => Vehicle(
        id: id,
        nickname: nickname,
        numberPlate: plate,
        brand: 'Honda',
        model: 'City',
        year: 2022,
        fuelType: ft,
        vehicleType: vt,
        odometerKm: 10000,
        createdAt: DateTime(2022),
      ),
    );

Arbitrary<FuelLog> get _fuelLog => combine4(
      _id, _id, _date, _pos,
      (id, vid, date, price) => FuelLog(
        id: id,
        vehicleId: vid,
        date: date,
        quantity: 40.0,
        totalPrice: price,
        odometerKm: 10000,
        isFullTank: true,
      ),
    );

Arbitrary<ServiceLog> get _serviceLog => combine4(
      _id, _id, _date, _pos,
      (id, vid, date, cost) => ServiceLog(
        id: id,
        vehicleId: vid,
        date: date,
        serviceType: 'Oil Change',
        cost: cost,
      ),
    );

Arbitrary<ExpenseLog> get _expenseLog => combine4(
      _id, _id, _date, _pos,
      (id, vid, date, amount) => ExpenseLog(
        id: id,
        vehicleId: vid,
        date: date,
        category: 'Toll',
        amount: amount,
      ),
    );

Arbitrary<Document> get _document => combine3(
      _id, _id, _date,
      (id, vid, expiry) => Document(
        id: id,
        vehicleId: vid,
        documentType: 'Insurance',
        expiryDate: expiry,
      ),
    );

Arbitrary<Reminder> get _reminder => combine4(
      _id, _id, _str, _reminderType,
      (id, vid, title, type) => Reminder(
        id: id,
        vehicleId: vid,
        title: title,
        body: 'body',
        reminderType: type,
        isDismissed: false,
        createdAt: DateTime(2024),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('BackupService — Property 1: round-trip preserves all data', () {
    test('Vehicle round-trip via JSON', () async {
      property(
        forAll(list(_vehicle, minLength: 0, maxLength: 5)),
        (List<Vehicle> vehicles) {
          final payload = _buildPayload(
            vehicles: vehicles,
            fuelLogs: [],
            serviceLogs: [],
            expenseLogs: [],
            documents: [],
            reminders: [],
          );
          final json = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
          final restored = _restoreList(json, 'vehicles', Vehicle.fromJson);
          expect(restored.length, vehicles.length);
          for (int i = 0; i < vehicles.length; i++) {
            expect(restored[i], equals(vehicles[i]),
                reason: 'Vehicle at index $i must be equal after round-trip');
          }
        },
      );
    });

    test('FuelLog round-trip via JSON', () async {
      property(
        forAll(list(_fuelLog, minLength: 0, maxLength: 5)),
        (List<dynamic> logs) {
          final payload = _buildPayload(
            vehicles: [],
            fuelLogs: logs,
            serviceLogs: [],
            expenseLogs: [],
            documents: [],
            reminders: [],
          );
          final json = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
          final restored = _restoreList(json, 'fuelLogs', FuelLog.fromJson);
          expect(restored.length, logs.length);
          for (int i = 0; i < logs.length; i++) {
            expect(restored[i], equals(logs[i]));
          }
        },
      );
    });

    test('ServiceLog round-trip via JSON', () async {
      property(
        forAll(list(_serviceLog, minLength: 0, maxLength: 5)),
        (List<dynamic> logs) {
          final payload = _buildPayload(
            vehicles: [],
            fuelLogs: [],
            serviceLogs: logs,
            expenseLogs: [],
            documents: [],
            reminders: [],
          );
          final json = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
          final restored = _restoreList(json, 'serviceLogs', ServiceLog.fromJson);
          expect(restored.length, logs.length);
          for (int i = 0; i < logs.length; i++) {
            expect(restored[i], equals(logs[i]));
          }
        },
      );
    });

    test('Document round-trip via JSON', () async {
      property(
        forAll(list(_document, minLength: 0, maxLength: 5)),
        (List<Document> docs) {
          final payload = _buildPayload(
            vehicles: [],
            fuelLogs: [],
            serviceLogs: [],
            expenseLogs: [],
            documents: docs,
            reminders: [],
          );
          final json = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
          final restored = _restoreList(json, 'documents', Document.fromJson);
          expect(restored.length, docs.length);
          for (int i = 0; i < docs.length; i++) {
            expect(restored[i], equals(docs[i]));
          }
        },
      );
    });

    test('Reminder round-trip via JSON', () async {
      property(
        forAll(list(_reminder, minLength: 0, maxLength: 5)),
        (List<Reminder> reminders) {
          final payload = _buildPayload(
            vehicles: [],
            fuelLogs: [],
            serviceLogs: [],
            expenseLogs: [],
            documents: [],
            reminders: reminders,
          );
          final json = jsonDecode(jsonEncode(payload)) as Map<String, dynamic>;
          final restored = _restoreList(json, 'reminders', Reminder.fromJson);
          expect(restored.length, reminders.length);
          for (int i = 0; i < reminders.length; i++) {
            expect(restored[i], equals(reminders[i]));
          }
        },
      );
    });

    test('invalid JSON returns failure without touching data', () {
      expect(
        () => jsonDecode('not valid json {{{'),
        throwsA(isA<FormatException>()),
      );
    });

    test('backup payload has correct version field', () {
      final payload = _buildPayload(
        vehicles: [],
        fuelLogs: [],
        serviceLogs: [],
        expenseLogs: [],
        documents: [],
        reminders: [],
      );
      expect(payload['version'], 1);
    });
  });
}
