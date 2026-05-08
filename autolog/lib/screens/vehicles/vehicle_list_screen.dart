import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/vehicle_provider.dart';
import '../../router.dart';
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: vehiclesAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_rounded,
              title: 'Garage is empty',
              subtitle: 'Add your vehicles here to manage fuel, services and documents in one place.',
              actionLabel: 'Add First Vehicle',
              onAction: () => context.push(AppRoutes.vehiclesAdd),
            );
          }
          
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                elevation: 0,
                backgroundColor: cs.surface,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  title: Text(
                    'My Garage',
                    style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => context.push(AppRoutes.vehiclesAdd),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_rounded, color: cs.primary, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final vehicle = vehicles[index];
                      return VehicleCard(
                        vehicle: vehicle,
                        onTap: () => context.push('/vehicles/${vehicle.id}'),
                        onDelete: () async {
                          final confirmed = await showConfirmDialog(
                            context,
                            title: 'Delete Vehicle',
                            message: 'Are you sure you want to delete "${vehicle.nickname}"? This action cannot be undone.',
                            confirmLabel: 'Delete',
                          );
                          if (confirmed == true) {
                            await ref.read(vehicleProvider.notifier).deleteVehicle(vehicle.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('"${vehicle.nickname}" removed from garage'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: cs.error,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                    childCount: vehicles.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      children: const [
        SizedBox(height: 100),
        SkeletonCard(height: 100),
        SkeletonCard(height: 100),
        SkeletonCard(height: 100),
      ],
    );
  }
}
