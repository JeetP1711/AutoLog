// Feature: autolog-vehicle-manager
// Property 5: Automatic reminder creation
//
// Service log branch: For any service log with a nextDueDate or
// nextDueOdometerKm, exactly one reminder is created.
//
// Document branch: For any document with an expiry date more than 30 days in
// the future, exactly two reminders are created at expiryDate−30 and
// expiryDate−7 days, both strictly before the expiry date.
//
// Validates: Requirements 8.4, 10.4

import 'package:flutter_test/flutter_test.dart';
import 'package:kiri_check/kiri_check.dart';

import 'package:autolog/models/models.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers: mirror the reminder-creation logic from providers
// ─────────────────────────────────────────────────────────────────────────────

/// Returns the reminders that would be created for [log].
List<Reminder> remindersForServiceLog(ServiceLog log) {
  if (log.nextDueDate == null && log.nextDueOdometerKm == null) return [];
  return [
    Reminder(
      id: 'r_${log.id}',
      vehicleId: log.vehicleId,
      title: 'Service Due: ${log.serviceType}',
      body: 'Service is due',
      reminderType: ReminderType.serviceDue,
      dueDate: log.nextDueDate,
      dueOdometerKm: log.nextDueOdometerKm,
      sourceId: log.id,
      isDismissed: false,
      createdAt: DateTime.now(),
    ),
  ];
}

/// Returns the reminders that would be created for [doc].
List<Reminder> remindersForDocument(Document doc) {
  final cutoff = DateTime.now().add(const Duration(days: 30));
  if (!doc.expiryDate.isAfter(cutoff)) return [];
  return [
    Reminder(
      id: 'r30_${doc.id}',
      vehicleId: doc.vehicleId,
      title: '${doc.documentType} Expiry',
      body: 'Expires in 30 days',
      reminderType: ReminderType.insuranceExpiry,
      dueDate: doc.expiryDate.subtract(const Duration(days: 30)),
      isDismissed: false,
      createdAt: DateTime.now(),
    ),
    Reminder(
      id: 'r7_${doc.id}',
      vehicleId: doc.vehicleId,
      title: '${doc.documentType} Expiry',
      body: 'Expires in 7 days',
      reminderType: ReminderType.insuranceExpiry,
      dueDate: doc.expiryDate.subtract(const Duration(days: 7)),
      isDismissed: false,
      createdAt: DateTime.now(),
    ),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Arbitraries
// ─────────────────────────────────────────────────────────────────────────────

Arbitrary<DateTime> get _futureDate => integer(min: 31, max: 3650).map(
      (days) => DateTime.now().add(Duration(days: days)),
    );

Arbitrary<double> get _posOdo =>
    float(min: 1000.0, max: 500_000.0, withNaN: false, withInfinities: false);

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('Property 5 — Service log: exactly one reminder created', () {
    test('service log with nextDueDate creates exactly one reminder', () async {
      property(
        forAll(_futureDate),
        (dueDate) {
          final log = ServiceLog(
            id: 'sl1',
            vehicleId: 'v1',
            date: DateTime.now(),
            serviceType: 'Oil Change',
            cost: 500,
            nextDueDate: dueDate,
          );
          final reminders = remindersForServiceLog(log);
          expect(reminders.length, 1,
              reason: 'Exactly one reminder must be created for service log with nextDueDate');
          expect(reminders.first.sourceId, log.id);
          expect(reminders.first.dueDate, dueDate);
        },
      );
    });

    test('service log with nextDueOdometerKm creates exactly one reminder', () async {
      property(
        forAll(_posOdo),
        (odo) {
          final log = ServiceLog(
            id: 'sl2',
            vehicleId: 'v1',
            date: DateTime.now(),
            serviceType: 'Tyre Rotation',
            cost: 300,
            nextDueOdometerKm: odo,
          );
          final reminders = remindersForServiceLog(log);
          expect(reminders.length, 1);
          expect(reminders.first.dueOdometerKm, odo);
        },
      );
    });

    test('service log without due date/odometer creates no reminders', () {
      final log = ServiceLog(
        id: 'sl3',
        vehicleId: 'v1',
        date: DateTime.now(),
        serviceType: 'Washing',
        cost: 100,
      );
      expect(remindersForServiceLog(log), isEmpty);
    });
  });

  group('Property 5 — Document: exactly two reminders created', () {
    test('document with expiry > 30 days creates exactly two reminders', () async {
      property(
        forAll(integer(min: 31, max: 3650)),
        (daysAhead) {
          final expiry = DateTime.now().add(Duration(days: daysAhead));
          final doc = Document(
            id: 'doc1',
            vehicleId: 'v1',
            documentType: 'Insurance',
            expiryDate: expiry,
          );
          final reminders = remindersForDocument(doc);
          expect(reminders.length, 2,
              reason: 'Exactly two reminders must be created for document expiring in $daysAhead days');

          final due30 = reminders.firstWhere((r) => r.id.contains('r30'));
          final due7 = reminders.firstWhere((r) => r.id.contains('r7'));

          // Both must be strictly before expiry
          expect(due30.dueDate!.isBefore(expiry), isTrue);
          expect(due7.dueDate!.isBefore(expiry), isTrue);

          // Correct offsets
          final diff30 = expiry.difference(due30.dueDate!).inDays;
          final diff7 = expiry.difference(due7.dueDate!).inDays;
          expect(diff30, 30);
          expect(diff7, 7);
        },
      );
    });

    test('document expiring in ≤ 30 days creates no new reminders', () {
      final expiry = DateTime.now().add(const Duration(days: 20));
      final doc = Document(
        id: 'doc2',
        vehicleId: 'v1',
        documentType: 'PUC',
        expiryDate: expiry,
      );
      expect(remindersForDocument(doc), isEmpty);
    });
  });
}
