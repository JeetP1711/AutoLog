import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../data/document_repository.dart';
import '../data/expense_log_repository.dart';
import '../data/fuel_log_repository.dart';
import '../data/reminder_repository.dart';
import '../data/service_log_repository.dart';
import '../data/vehicle_repository.dart';
import '../models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Result type
// ─────────────────────────────────────────────────────────────────────────────

/// Result of a backup import operation.
class BackupResult {
  const BackupResult.success() : success = true, errorMessage = null;
  const BackupResult.failure(this.errorMessage) : success = false;

  final bool success;
  final String? errorMessage;
}

// ─────────────────────────────────────────────────────────────────────────────
// BackupService
// ─────────────────────────────────────────────────────────────────────────────

/// Handles JSON export and import of all app data.
///
/// The backup file is a single versioned JSON object. On import, the existing
/// data is left untouched if validation fails.
class BackupService {
  BackupService({
    required VehicleRepository vehicleRepo,
    required FuelLogRepository fuelLogRepo,
    required ServiceLogRepository serviceLogRepo,
    required ExpenseLogRepository expenseLogRepo,
    required DocumentRepository documentRepo,
    required ReminderRepository reminderRepo,
  })  : _vehicleRepo = vehicleRepo,
        _fuelLogRepo = fuelLogRepo,
        _serviceLogRepo = serviceLogRepo,
        _expenseLogRepo = expenseLogRepo,
        _documentRepo = documentRepo,
        _reminderRepo = reminderRepo;

  final VehicleRepository _vehicleRepo;
  final FuelLogRepository _fuelLogRepo;
  final ServiceLogRepository _serviceLogRepo;
  final ExpenseLogRepository _expenseLogRepo;
  final DocumentRepository _documentRepo;
  final ReminderRepository _reminderRepo;

  static const int _backupVersion = 1;

  // ── Export ─────────────────────────────────────────────────────────────────

  /// Serialises all data to a versioned JSON file in the app's documents dir.
  ///
  /// Returns the absolute path of the saved file.
  Future<String> exportToJson() async {
    final vehicles = await _vehicleRepo.getAll();
    final fuelLogs = await _fuelLogRepo.getAll();
    final serviceLogs = await _serviceLogRepo.getAll();
    final expenseLogs = await _expenseLogRepo.getAll();
    final documents = await _documentRepo.getAll();
    final reminders = await _reminderRepo.getAll();

    final payload = {
      'version': _backupVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'vehicles': vehicles.map((v) => v.toJson()).toList(),
      'fuelLogs': fuelLogs.map((l) => l.toJson()).toList(),
      'serviceLogs': serviceLogs.map((l) => l.toJson()).toList(),
      'expenseLogs': expenseLogs.map((l) => l.toJson()).toList(),
      'documents': documents.map((d) => d.toJson()).toList(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final file = File('${dir.path}/autolog_backup_$timestamp.json');
    await file.writeAsString(jsonEncode(payload));
    return file.path;
  }

  // ── Import ─────────────────────────────────────────────────────────────────

  /// Validates and restores all records from [filePath].
  ///
  /// On any validation or parse error, existing data is left untouched and a
  /// [BackupResult.failure] is returned with a descriptive message.
  Future<BackupResult> importFromJson(String filePath) async {
    // 1. Read file
    final file = File(filePath);
    if (!await file.exists()) {
      return const BackupResult.failure('Backup file not found.');
    }

    String raw;
    try {
      raw = await file.readAsString();
    } catch (e) {
      return BackupResult.failure('Could not read backup file: $e');
    }

    // 2. Parse JSON
    Map<String, dynamic> json;
    try {
      json = jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException catch (e) {
      return BackupResult.failure('Invalid JSON format: ${e.message}');
    }

    // 3. Validate version
    final version = json['version'];
    if (version == null || version is! int || version != _backupVersion) {
      return BackupResult.failure(
        'Unrecognised backup version: $version. Expected version $_backupVersion.',
      );
    }

    // 4. Deserialise all records (validate before writing)
    List<Vehicle> vehicles;
    List<FuelLog> fuelLogs;
    List<ServiceLog> serviceLogs;
    List<ExpenseLog> expenseLogs;
    List<Document> documents;
    List<Reminder> reminders;

    try {
      vehicles = _parseList(json['vehicles'], Vehicle.fromJson);
      fuelLogs = _parseList(json['fuelLogs'], FuelLog.fromJson);
      serviceLogs = _parseList(json['serviceLogs'], ServiceLog.fromJson);
      expenseLogs = _parseList(json['expenseLogs'], ExpenseLog.fromJson);
      documents = _parseList(json['documents'], Document.fromJson);
      reminders = _parseList(json['reminders'], Reminder.fromJson);
    } catch (e) {
      return BackupResult.failure('Backup data is corrupted: $e');
    }

    // 5. Write all records (only after successful validation)
    for (final v in vehicles) await _vehicleRepo.save(v);
    for (final l in fuelLogs) await _fuelLogRepo.save(l);
    for (final l in serviceLogs) await _serviceLogRepo.save(l);
    for (final l in expenseLogs) await _expenseLogRepo.save(l);
    for (final d in documents) await _documentRepo.save(d);
    for (final r in reminders) await _reminderRepo.save(r);

    return const BackupResult.success();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw == null) return [];
    if (raw is! List) throw FormatException('Expected a list but got ${raw.runtimeType}');
    return raw
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
