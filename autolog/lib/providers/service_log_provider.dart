import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'vehicle_provider.dart';

class ServiceLogNotifier extends FamilyAsyncNotifier<List<ServiceLog>, String> {
  @override
  Future<List<ServiceLog>> build(String vehicleId) async {
    return ref.read(serviceLogRepositoryProvider).getByVehicle(vehicleId);
  }

  Future<void> saveServiceLog(ServiceLog log, String vehicleNickname) async {
    final repo = ref.read(serviceLogRepositoryProvider);
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);

    await repo.save(log);

    // Cancel any existing reminder for this service log
    final existing = await reminderRepo.getBySourceId(log.id);
    for (final r in existing) {
      await notifService.cancelReminder(r.id);
      await reminderRepo.delete(r.id);
    }

    // Create exactly one reminder if nextDueDate or nextDueOdometerKm is set
    if (log.nextDueDate != null || log.nextDueOdometerKm != null) {
      final reminder = Reminder(
        id: newId(),
        vehicleId: log.vehicleId,
        title: 'Service Due: ${log.serviceType}',
        body: '$vehicleNickname — ${log.serviceType} service is due',
        reminderType: ReminderType.serviceDue,
        dueDate: log.nextDueDate,
        dueOdometerKm: log.nextDueOdometerKm,
        sourceId: log.id,
        isDismissed: false,
        createdAt: DateTime.now(),
      );
      await reminderRepo.save(reminder);
      await notifService.scheduleReminder(reminder, vehicleNickname);
    }

    state = AsyncData(await repo.getByVehicle(log.vehicleId));
  }

  Future<void> deleteServiceLog(String logId) async {
    final repo = ref.read(serviceLogRepositoryProvider);
    final reminderRepo = ref.read(reminderRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);

    // Cancel and delete associated reminders
    final reminders = await reminderRepo.getBySourceId(logId);
    for (final r in reminders) {
      await notifService.cancelReminder(r.id);
    }
    await reminderRepo.deleteBySourceId(logId);
    await repo.delete(logId);
    state = AsyncData(await repo.getByVehicle(arg));
  }
}

final serviceLogProvider =
    AsyncNotifierProviderFamily<ServiceLogNotifier, List<ServiceLog>, String>(
  ServiceLogNotifier.new,
);

final allServiceLogsProvider = FutureProvider<List<ServiceLog>>((ref) async {
  return ref.read(serviceLogRepositoryProvider).getAll();
});
