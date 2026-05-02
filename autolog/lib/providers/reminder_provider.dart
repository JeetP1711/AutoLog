import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import 'vehicle_provider.dart';

class ReminderNotifier extends AsyncNotifier<List<Reminder>> {
  @override
  Future<List<Reminder>> build() async {
    return ref.read(reminderRepositoryProvider).getPending();
  }

  Future<void> dismissReminder(String reminderId) async {
    final repo = ref.read(reminderRepositoryProvider);
    final reminder = await repo.getById(reminderId);
    if (reminder == null) return;
    await repo.save(reminder.copyWith(isDismissed: true));
    state = AsyncData(await repo.getPending());
  }

  Future<void> deleteReminder(String reminderId) async {
    final repo = ref.read(reminderRepositoryProvider);
    final notifService = ref.read(notificationServiceProvider);
    await notifService.cancelReminder(reminderId);
    await repo.delete(reminderId);
    state = AsyncData(await repo.getPending());
  }

  Future<void> refresh() async {
    state = AsyncData(
      await ref.read(reminderRepositoryProvider).getPending(),
    );
  }
}

final reminderProvider =
    AsyncNotifierProvider<ReminderNotifier, List<Reminder>>(
  ReminderNotifier.new,
);
