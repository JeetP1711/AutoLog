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

class VehicleListScreen extends ConsumerWidget {
  const VehicleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: const Text('My Vehicles')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.vehiclesAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Vehicle'),
      ),
      body: vehiclesAsync.when(
        loading: () => ListView(
          children: const [
            SizedBox(height: AppSpacing.md),
            SkeletonCard(height: 90),
            SkeletonCard(height: 90),
            SkeletonCard(height: 90),
          ],
        ),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: TextStyle(color: AppColors.textSecondaryDark)),
        ),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_rounded,
              title: 'No vehicles yet',
              subtitle: 'Tap the button below to add your first vehicle',
              actionLabel: 'Add Vehicle',
              onAction: () => context.push(AppRoutes.vehiclesAdd),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.md,
              bottom: 100,
            ),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return VehicleCard(
                vehicle: vehicle,
                onTap: () => context.push('/vehicles/${vehicle.id}'),
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Vehicle',
                    message:
                        'Delete "${vehicle.nickname}"? All associated logs, documents, and reminders will also be deleted.',
                    confirmLabel: 'Delete',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(vehicleProvider.notifier)
                        .deleteVehicle(vehicle.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              '"${vehicle.nickname}" deleted'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
