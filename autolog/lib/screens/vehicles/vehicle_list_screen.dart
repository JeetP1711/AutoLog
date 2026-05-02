import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/vehicle_provider.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/vehicle_card.dart';

/// Displays the list of all user vehicles.
///
/// Shows skeleton loaders while loading, an [EmptyState] when no vehicles
/// exist, and a list of [VehicleCard] widgets otherwise. Each card supports
/// swipe-to-delete with a confirmation dialog. A FAB navigates to the
/// add-vehicle screen.
class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.vehiclesAdd),
        tooltip: 'Add vehicle',
        child: const Icon(Icons.add_rounded),
      ),
      body: vehiclesAsync.when(
        loading: () => _SkeletonList(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppColors.error,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Failed to load vehicles',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: () => ref.invalidate(vehicleProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_rounded,
              title: 'No vehicles yet',
              subtitle:
                  'Tap the + button to add your first vehicle and start tracking.',
              actionLabel: 'Add Vehicle',
              onAction: () => context.push(AppRoutes.vehiclesAdd),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(vehicleProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.only(
                top: AppSpacing.sm,
                bottom: AppSpacing.xxl + AppSpacing.xl, // space for FAB
              ),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _SwipeToDeleteVehicleCard(
                  key: ValueKey(vehicle.id),
                  vehicle: vehicle,
                  onTap: () => context.push('/vehicles/${vehicle.id}'),
                  onDelete: () async {
                    final confirmed = await showConfirmDialog(
                      context,
                      title: 'Delete Vehicle',
                      message:
                          'Delete "${vehicle.nickname}"? This will also remove all associated logs, documents, and reminders.',
                      confirmLabel: 'Delete',
                      isDestructive: true,
                    );
                    if (confirmed == true) {
                      await ref
                          .read(vehicleProvider.notifier)
                          .deleteVehicle(vehicle.id);
                    }
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Swipe-to-delete wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _SwipeToDeleteVehicleCard extends StatelessWidget {
  const _SwipeToDeleteVehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
    required this.onDelete,
  });

  final dynamic vehicle;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('dismissible_${vehicle.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final confirmed = await showConfirmDialog(
          context,
          title: 'Delete Vehicle',
          message:
              'Delete "${vehicle.nickname}"? This will also remove all associated logs, documents, and reminders.',
          confirmLabel: 'Delete',
          isDestructive: true,
        );
        return confirmed == true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(200),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: VehicleCard(
        vehicle: vehicle,
        onTap: onTap,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton loading list
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonCard(height: 96),
    );
  }
}
