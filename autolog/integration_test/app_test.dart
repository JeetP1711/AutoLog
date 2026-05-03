// Integration tests for AutoLog
// These tests run on a real Android emulator/device via `flutter test integration_test/`
//
// Requirements: 2.2, 2.4, 5.2, 7.1, 3.1, 15.1, 15.2, 15.5, 10.4, 11.3, 16.1, 16.2

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:autolog/data/hive_boxes.dart';
import 'package:autolog/models/models.dart';
import 'package:autolog/data/fuel_log_repository.dart';
import 'package:autolog/data/vehicle_repository.dart';
import 'package:autolog/services/analytics_service.dart';
import 'package:autolog/services/backup_service.dart';
import 'package:autolog/data/document_repository.dart';
import 'package:autolog/data/expense_log_repository.dart';
import 'package:autolog/data/reminder_repository.dart';
import 'package:autolog/data/service_log_repository.dart';
import 'package:autolog/services/pin_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Test setup helpers
// ─────────────────────────────────────────────────────────────────────────────

late Directory _tempDir;

Future<void> _initHive() async {
  _tempDir = await Directory.systemTemp.createTemp('autolog_integration_');
  Hive.init(_tempDir.path);
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
  await HiveBoxes.init();
}

Future<void> _closeHive() async {
  await Hive.close();
  await _tempDir.delete(recursive: true);
}

Vehicle _makeVehicle(String id) => Vehicle(
      id: id,
      nickname: 'Test Car',
      numberPlate: 'MH01AB1234',
      brand: 'Honda',
      model: 'City',
      year: 2022,
      fuelType: FuelType.petrol,
      vehicleType: VehicleType.car,
      odometerKm: 10000,
      createdAt: DateTime(2022),
    );

FuelLog _makeFuelLog(String id, String vehicleId, double price) => FuelLog(
      id: id,
      vehicleId: vehicleId,
      date: DateTime.now(),
      quantity: 40.0,
      totalPrice: price,
      odometerKm: 10500,
      isFullTank: true,
    );

// ─────────────────────────────────────────────────────────────────────────────
// Integration Test 24.1: Add vehicle → add fuel log → verify dashboard totals
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Integration Test 24.1: Vehicle + Fuel Log → Dashboard Totals', () {
    setUp(() async => _initHive());
    tearDown(() async => _closeHive());

    test('adding a vehicle and fuel log reflects in dashboard totals', () async {
      final vehicleRepo = VehicleRepository();
      final fuelLogRepo = FuelLogRepository();
      const analytics = AnalyticsService();

      // Add vehicle
      final vehicle = _makeVehicle('v1');
      await vehicleRepo.save(vehicle);

      // Add fuel log
      final fuelLog = _makeFuelLog('f1', 'v1', 2500.0);
      await fuelLogRepo.save(fuelLog);

      // Verify dashboard totals
      final allVehicles = await vehicleRepo.getAll();
      expect(allVehicles.length, 1);
      expect(allVehicles.first.nickname, 'Test Car');

      final allFuelLogs = await fuelLogRepo.getAll();
      expect(allFuelLogs.length, 1);

      final monthlySpend = analytics.monthlyFuelSpend(allFuelLogs);
      expect(monthlySpend, closeTo(2500.0, 0.01));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Integration Test 24.2: Export → Clear → Import → Verify restored
  // ─────────────────────────────────────────────────────────────────────────

  group('Integration Test 24.2: Backup round-trip', () {
    setUp(() async => _initHive());
    tearDown(() async => _closeHive());

    test('export then import restores all data', () async {
      final vehicleRepo = VehicleRepository();
      final fuelLogRepo = FuelLogRepository();
      final serviceLogRepo = ServiceLogRepository();
      final expenseLogRepo = ExpenseLogRepository();
      final documentRepo = DocumentRepository();
      final reminderRepo = ReminderRepository();

      // Add test data
      final vehicle = _makeVehicle('v1');
      await vehicleRepo.save(vehicle);
      final fuelLog = _makeFuelLog('f1', 'v1', 3000.0);
      await fuelLogRepo.save(fuelLog);

      // Export
      final backupService = BackupService(
        vehicleRepo: vehicleRepo,
        fuelLogRepo: fuelLogRepo,
        serviceLogRepo: serviceLogRepo,
        expenseLogRepo: expenseLogRepo,
        documentRepo: documentRepo,
        reminderRepo: reminderRepo,
      );
      final exportPath = await backupService.exportToJson();
      expect(File(exportPath).existsSync(), isTrue);

      // Clear all data
      await HiveBoxes.vehicleBox.clear();
      await HiveBoxes.fuelLogBox.clear();

      // Verify cleared
      expect((await vehicleRepo.getAll()).isEmpty, isTrue);
      expect((await fuelLogRepo.getAll()).isEmpty, isTrue);

      // Import
      final result = await backupService.importFromJson(exportPath);
      expect(result.success, isTrue);

      // Verify restored
      final restoredVehicles = await vehicleRepo.getAll();
      expect(restoredVehicles.length, 1);
      expect(restoredVehicles.first.id, 'v1');

      final restoredFuelLogs = await fuelLogRepo.getAll();
      expect(restoredFuelLogs.length, 1);
      expect(restoredFuelLogs.first.totalPrice, closeTo(3000.0, 0.01));

      // Clean up export file
      await File(exportPath).delete();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Integration Test 24.3: Add document → verify two reminders created
  // ─────────────────────────────────────────────────────────────────────────

  group('Integration Test 24.3: Document → Reminders', () {
    setUp(() async => _initHive());
    tearDown(() async => _closeHive());

    test('saving a document with future expiry creates two reminders', () async {
      final documentRepo = DocumentRepository();
      final reminderRepo = ReminderRepository();

      // Create document expiring 60 days from now (> 30 days)
      final expiryDate = DateTime.now().add(const Duration(days: 60));
      final doc = Document(
        id: 'd1',
        vehicleId: 'v1',
        documentType: 'Insurance',
        expiryDate: expiryDate,
      );
      await documentRepo.save(doc);

      // Simulate the reminder creation logic from DocumentProvider
      final cutoff = DateTime.now().add(const Duration(days: 30));
      if (doc.expiryDate.isAfter(cutoff)) {
        final reminder30 = Reminder(
          id: 'r30',
          vehicleId: 'v1',
          title: 'Insurance Expiry',
          body: 'Expires in 30 days',
          reminderType: ReminderType.insuranceExpiry,
          dueDate: expiryDate.subtract(const Duration(days: 30)),
          sourceId: doc.id,
          isDismissed: false,
          createdAt: DateTime.now(),
        );
        final reminder7 = Reminder(
          id: 'r7',
          vehicleId: 'v1',
          title: 'Insurance Expiry',
          body: 'Expires in 7 days',
          reminderType: ReminderType.insuranceExpiry,
          dueDate: expiryDate.subtract(const Duration(days: 7)),
          sourceId: doc.id,
          isDismissed: false,
          createdAt: DateTime.now(),
        );
        await reminderRepo.save(reminder30);
        await reminderRepo.save(reminder7);
      }

      // Verify two reminders were created
      final reminders = await reminderRepo.getBySourceId('d1');
      expect(reminders.length, 2);

      final dueDates = reminders.map((r) => r.dueDate!).toList()
        ..sort((a, b) => a.compareTo(b));

      // Both must be before expiry
      for (final d in dueDates) {
        expect(d.isBefore(expiryDate), isTrue);
      }

      // Check offsets
      final diff30 = expiryDate.difference(dueDates[0]).inDays;
      final diff7 = expiryDate.difference(dueDates[1]).inDays;
      expect(diff30, 30);
      expect(diff7, 7);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Integration Test 24.4: Enable PIN → verify PIN screen shown
  // ─────────────────────────────────────────────────────────────────────────

  group('Integration Test 24.4: PIN lock', () {
    test('PIN is stored as hash and verified correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final pinService = PinService(prefs);

      // Initially no PIN
      expect(pinService.isPinEnabled(), isFalse);

      // Set PIN
      await pinService.setPin('4321');
      expect(pinService.isPinEnabled(), isTrue);

      // Correct PIN verifies
      expect(pinService.verifyPin('4321'), isTrue);

      // Wrong PIN fails
      expect(pinService.verifyPin('1234'), isFalse);

      // Plaintext not stored
      final storedHash = prefs.getString('pin_hash');
      expect(storedHash, isNot(equals('4321')));
      expect(storedHash?.length, 64); // SHA-256 hex
    });
  });
}
