import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reminder_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';

class ReminderCenterScreen extends ConsumerWidget {
  const ReminderCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(reminderProvider);
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];
    final vehicleNames = {for (final v in vehicles) v.id: v.nickname};

    return Scaffold(
            appBar: AppBar(title: const Text('Reminders')),
      body: remindersAsync.when(
        loading: () => ListView(
          children: const [
            SkeletonListTile(),
            SkeletonListTile(),
            SkeletonListTile(),
          ],
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No pending reminders',
              subtitle:
                  'Reminders will appear here when you add documents or service logs with due dates',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 80),
            itemCount: reminders.length,
            itemBuilder: (context, i) {
              final reminder = reminders[i];
              final vehicleName =
                  vehicleNames[reminder.vehicleId] ?? 'Unknown Vehicle';
              final daysLeft = reminder.dueDate != null
                  ? DateFormatter.daysUntil(reminder.dueDate!)
                  : null;
              final urgencyColor = daysLeft == null
                  ? AppColors.info
                  : daysLeft <= 7
                      ? AppColors.error
                      : daysLeft <= 30
                          ? AppColors.warning
                          : AppColors.success;

              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: urgencyColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: urgencyColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    reminder.title,
                        ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondaryDark),
                      ),
                      if (reminder.dueDate != null)
                        Text(
                          DateFormatter.formatExpiry(reminder.dueDate!),
                          style: AppTextStyles.labelSmall
                              .copyWith(color: urgencyColor),
                        )
                      else if (reminder.dueOdometerKm != null)
                        Text(
                          'At ${reminder.dueOdometerKm!.toStringAsFixed(0)} km',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: urgencyColor),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline_rounded,
                            color: AppColors.success),
                        tooltip: 'Dismiss',
                        onPressed: () async {
                          await ref
                              .read(reminderProvider.notifier)
                              .dismissReminder(reminder.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.error),
                        tooltip: 'Delete',
                        onPressed: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'Delete Reminder',
                            message: 'Delete this reminder?',
                          );
                          if (confirmed == true) {
                            await ref
                                .read(reminderProvider.notifier)
                                .deleteReminder(reminder.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
