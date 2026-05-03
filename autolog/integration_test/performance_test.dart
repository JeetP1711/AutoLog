// Performance test: FuelLogRepository.getAll() must complete in under 300 ms
// for lists of up to 10,000 entries.
//
// Requirements: 17.9

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:autolog/data/fuel_log_repository.dart';
import 'package:autolog/data/hive_boxes.dart';
import 'package:autolog/models/models.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('autolog_perf_');
    Hive.init(tempDir.path);
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
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('FuelLogRepository.getAll() completes in under 300 ms for 10,000 entries',
      () async {
    const entryCount = 10000;
    final box = HiveBoxes.fuelLogBox;

    // Populate 10,000 fuel log entries directly via Hive
    final entries = <String, FuelLog>{};
    for (int i = 0; i < entryCount; i++) {
      final log = FuelLog(
        id: 'f$i',
        vehicleId: 'v1',
        date: DateTime(2020).add(Duration(days: i)),
        quantity: 40.0,
        totalPrice: 2500.0,
        odometerKm: 10000.0 + (i * 50),
        isFullTank: true,
        mileage: 18.5,
        distanceKm: 50.0,
      );
      entries[log.id] = log;
    }

    // Write all entries at once
    await box.putAll(entries);
    expect(box.length, entryCount);

    // Measure getAll() time
    final repo = FuelLogRepository();
    final stopwatch = Stopwatch()..start();
    final result = await repo.getAll();
    stopwatch.stop();

    expect(result.length, entryCount);
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(300),
      reason:
          'FuelLogRepository.getAll() took ${stopwatch.elapsedMilliseconds} ms '
          'for $entryCount entries — must be under 300 ms',
    );

    // ignore: avoid_print
    print(
        'Performance: getAll() for $entryCount entries = ${stopwatch.elapsedMilliseconds} ms');
  });
}
