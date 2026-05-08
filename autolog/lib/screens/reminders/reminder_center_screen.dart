import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/reminder_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';

class ReminderCenterScreen extends ConsumerWidget {
  const ReminderCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final remindersAsync = ref.watch(reminderProvider);
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];
    final vehicleNames = {for (final v in vehicles) v.id: v.nickname};

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Reminders',
                style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
            ),
          ),
          remindersAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (reminders) {
              if (reminders.isEmpty) {
                return const SliverFillRemaining(
                  child: EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'All caught up!',
                    subtitle: 'Any upcoming service or document renewals will show up here.',
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reminder = reminders[index];
                      final vehicleName = vehicleNames[reminder.vehicleId] ?? 'My Vehicle';
                      final daysLeft = reminder.dueDate != null ? DateFormatter.daysUntil(reminder.dueDate!) : null;

                      Color statusColor = cs.primary;
                      if (daysLeft != null) {
                        if (daysLeft <= 7) statusColor = Colors.redAccent;
                        else if (daysLeft <= 30) statusColor = Colors.orangeAccent;
                        else statusColor = Colors.greenAccent;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outline.withAlpha(30)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () {},
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(color: statusColor.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                                    child: Icon(Icons.notifications_active_rounded, color: statusColor, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(reminder.title, style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w900, color: cs.onSurface)),
                                        const SizedBox(height: 2),
                                        Text(vehicleName, style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        if (reminder.dueDate != null)
                                          Row(
                                            children: [
                                              Icon(Icons.calendar_month_rounded, size: 12, color: statusColor),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Due: ${DateFormatter.format(reminder.dueDate!)}',
                                                style: tt.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w900),
                                              ),
                                            ],
                                          )
                                        else if (reminder.dueOdometerKm != null)
                                          Text(
                                            'Due at: ${reminder.dueOdometerKm!.toStringAsFixed(0)} km',
                                            style: tt.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w900),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.check_circle_outline_rounded, color: Colors.green.shade400, size: 24),
                                        onPressed: () => ref.read(reminderProvider.notifier).dismissReminder(reminder.id),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: reminders.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
