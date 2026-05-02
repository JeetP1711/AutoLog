import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'vehicle_provider.dart';

class DocumentNotifier extends FamilyAsyncNotifier<List<Document>, String> {
  @override
  Future<List<Document>> build(String vehicleId) async {
    return ref.read(documentRepositoryProvider).getByVehicle(vehicleId);
  }

  Future<void> saveDocument(Document doc, String vehicleNickname) async {
    final repo = ref.read(documentRepositoryProvider);
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);

    await repo.save(doc);

    // Cancel and delete any existing reminders for this document
    final existing = await reminderRepo.getBySourceId(doc.id);
    for (final r in existing) {
      await notifService.cancelReminder(r.id);
      await reminderRepo.delete(r.id);
    }

    // Create two reminders if expiry is more than 30 days away
    final cutoff = DateTime.now().add(const Duration(days: 30));
    if (doc.expiryDate.isAfter(cutoff)) {
      final due30 = doc.expiryDate.subtract(const Duration(days: 30));
      final due7 = doc.expiryDate.subtract(const Duration(days: 7));

      final reminder30 = Reminder(
        id: newId(),
        vehicleId: doc.vehicleId,
        title: '${doc.documentType} Expiry',
        body: '$vehicleNickname — ${doc.documentType} expires in 30 days',
        reminderType: _reminderTypeForDoc(doc.documentType),
        dueDate: due30,
        sourceId: doc.id,
        isDismissed: false,
        createdAt: DateTime.now(),
      );
      final reminder7 = Reminder(
        id: newId(),
        vehicleId: doc.vehicleId,
        title: '${doc.documentType} Expiry',
        body: '$vehicleNickname — ${doc.documentType} expires in 7 days',
        reminderType: _reminderTypeForDoc(doc.documentType),
        dueDate: due7,
        sourceId: doc.id,
        isDismissed: false,
        createdAt: DateTime.now(),
      );

      await reminderRepo.save(reminder30);
      await reminderRepo.save(reminder7);
      await notifService.scheduleReminder(reminder30, vehicleNickname);
      await notifService.scheduleReminder(reminder7, vehicleNickname);
    }

    state = AsyncData(await repo.getByVehicle(doc.vehicleId));
  }

  Future<void> deleteDocument(String docId) async {
    final repo = ref.read(documentRepositoryProvider);
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);

    final reminders = await reminderRepo.getBySourceId(docId);
    for (final r in reminders) {
      await notifService.cancelReminder(r.id);
    }
    await reminderRepo.deleteBySourceId(docId);
    await repo.delete(docId);
    state = AsyncData(await repo.getByVehicle(arg));
  }
}

ReminderType _reminderTypeForDoc(String docType) {
  switch (docType.toLowerCase()) {
    case 'insurance':
      return ReminderType.insuranceExpiry;
    case 'puc':
    case 'pollution certificate':
      return ReminderType.pucExpiry;
    default:
      return ReminderType.custom;
  }
}

final documentProvider =
    AsyncNotifierProviderFamily<DocumentNotifier, List<Document>, String>(
  DocumentNotifier.new,
);

final allDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  return ref.read(documentRepositoryProvider).getAll();
});

final expiringSoonProvider = FutureProvider<List<Document>>((ref) async {
  return ref.read(documentRepositoryProvider).getExpiringSoon(days: 30);
});
