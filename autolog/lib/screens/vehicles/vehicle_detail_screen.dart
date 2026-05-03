import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/document_provider.dart';
import '../../providers/expense_log_provider.dart';
import '../../providers/fuel_log_provider.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../utils/mileage_calculator.dart';
import '../../utils/unit_converter.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/log_tile.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/stat_card.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});
  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);

    return vehiclesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (vehicles) {
        final vehicle = vehicles.firstWhere(
          (v) => v.id == vehicleId,
          orElse: () => throw StateError('Vehicle not found'),
        );
        return _VehicleDetailView(vehicle: vehicle);
      },
    );
  }
}

class _VehicleDetailView extends ConsumerStatefulWidget {
  const _VehicleDetailView({required this.vehicle});
  final Vehicle vehicle;

  @override
  ConsumerState<_VehicleDetailView> createState() =>
      _VehicleDetailViewState();
}

class _VehicleDetailViewState extends ConsumerState<_VehicleDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final currency = ref.watch(currencySymbolProvider);
    final distanceUnit = ref.watch(distanceUnitProvider);
    final unitLabel = UnitConverter.label(distanceUnit);

    return Scaffold(
            appBar: AppBar(
        title: Text(v.nickname),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/vehicles/${v.id}/edit'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Fuel'),
            Tab(text: 'Service'),
            Tab(text: 'Expenses'),
            Tab(text: 'Documents'),
            Tab(text: 'Notes'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverviewTab(vehicle: v, currency: currency, unitLabel: unitLabel),
          _FuelLogsTab(vehicle: v, currency: currency),
          _ServiceLogsTab(vehicle: v, currency: currency),
          _ExpensesTab(vehicle: v, currency: currency),
          _DocumentsTab(vehicle: v),
          _NotesTab(vehicle: v),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab(
      {required this.vehicle,
      required this.currency,
      required this.unitLabel});
  final Vehicle vehicle;
  final String currency;
  final String unitLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelLogsAsync = ref.watch(fuelLogProvider(vehicle.id));
    final serviceLogsAsync = ref.watch(serviceLogProvider(vehicle.id));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // Vehicle header card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withAlpha(30),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _vehicleIcon(vehicle.vehicleType),
                    size: 34,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vehicle.nickname,
                          style: AppTextStyles.titleMedium
                              .copyWith(color: AppColors.textPrimaryDark)),
                      Text(
                          '${vehicle.brand} ${vehicle.model} · ${vehicle.year}',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondaryDark)),
                      Text(vehicle.numberPlate.toUpperCase(),
                          style: AppTextStyles.labelMedium
                              .copyWith(color: AppColors.primaryBlue)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Stats
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Odometer',
                value:
                    '${vehicle.odometerKm.toStringAsFixed(0)} $unitLabel',
                icon: Icons.speed_rounded,
                iconColor: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: fuelLogsAsync.when(
                loading: () => const SkeletonCard(height: 90),
                error: (_, __) => const SizedBox.shrink(),
                data: (logs) {
                  final withMileage = logs.where((l) => l.mileage != null).toList();
                  final avgMileage = withMileage.isEmpty
                      ? null
                      : withMileage.map((l) => l.mileage!).fold(0.0, (a, b) => a + b) /
                          withMileage.length;
                  final unit = MileageCalculator.efficiencyUnit(
                      vehicle.fuelType,
                      customUnit: vehicle.customFuelUnit);
                  return StatCard(
                    label: 'Avg Mileage',
                    value: avgMileage != null
                        ? '${avgMileage.toStringAsFixed(1)} $unit'
                        : 'N/A',
                    icon: Icons.local_gas_station_rounded,
                    iconColor: AppColors.fuelPetrol,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // Last service
        serviceLogsAsync.when(
          loading: () => const SkeletonCard(height: 80),
          error: (_, __) => const SizedBox.shrink(),
          data: (logs) {
            if (logs.isEmpty) return const SizedBox.shrink();
            final last = logs.first;
            return StatCard(
              label: 'Last Service',
              value: last.serviceType,
              subtitle: DateFormatter.format(last.date),
              icon: Icons.build_rounded,
              iconColor: AppColors.warning,
            );
          },
        ),
      ],
    );
  }

  IconData _vehicleIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Icons.directions_car_rounded;
      case VehicleType.bike:
        return Icons.two_wheeler_rounded;
      case VehicleType.scooter:
        return Icons.electric_scooter_rounded;
      case VehicleType.truck:
        return Icons.local_shipping_rounded;
      case VehicleType.custom:
        return Icons.commute_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fuel Logs Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FuelLogsTab extends ConsumerWidget {
  const _FuelLogsTab({required this.vehicle, required this.currency});
  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(fuelLogProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(
            '${AppRoutes.fuelLogAdd}?vehicleId=${vehicle.id}'),
        child: const Icon(Icons.add_rounded),
      ),
      body: logsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.local_gas_station_rounded,
              title: 'No fuel logs yet',
              subtitle: 'Tap + to add your first fuel entry',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 100),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return LogTile(
                icon: Icons.local_gas_station_rounded,
                iconColor: AppColors.fuelPetrol,
                title: log.mileage != null
                    ? '${log.mileage!.toStringAsFixed(1)} ${MileageCalculator.efficiencyUnit(vehicle.fuelType)}'
                    : '${log.quantity.toStringAsFixed(1)} ${MileageCalculator.quantityUnit(vehicle.fuelType)}',
                subtitle: log.stationName ?? 'Fuel refill',
                date: DateFormatter.formatShort(log.date),
                amount: log.totalPrice.toStringAsFixed(0),
                currencySymbol: currency,
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Fuel Log',
                    message: 'Delete this fuel entry?',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(fuelLogProvider(vehicle.id).notifier)
                        .deleteFuelLog(log.id, vehicle.fuelType);
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

// ─────────────────────────────────────────────────────────────────────────────
// Service Logs Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceLogsTab extends ConsumerWidget {
  const _ServiceLogsTab({required this.vehicle, required this.currency});
  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(serviceLogProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.serviceLogAdd),
        child: const Icon(Icons.add_rounded),
      ),
      body: logsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.build_rounded,
              title: 'No service logs yet',
              subtitle: 'Tap + to add a service entry',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 100),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return LogTile(
                icon: Icons.build_rounded,
                iconColor: AppColors.info,
                title: log.serviceType,
                subtitle: log.garageName ?? 'Service',
                date: DateFormatter.formatShort(log.date),
                amount: log.cost.toStringAsFixed(0),
                currencySymbol: currency,
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Service Log',
                    message: 'Delete this service entry?',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(serviceLogProvider(vehicle.id).notifier)
                        .deleteServiceLog(log.id);
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

// ─────────────────────────────────────────────────────────────────────────────
// Expenses Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.vehicle, required this.currency});
  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(expenseLogProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.expenseLogAdd),
        child: const Icon(Icons.add_rounded),
      ),
      body: logsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No expenses yet',
              subtitle: 'Tap + to add an expense',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 100),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return LogTile(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.success,
                title: log.category,
                subtitle: log.notes ?? 'Expense',
                date: DateFormatter.formatShort(log.date),
                amount: log.amount.toStringAsFixed(0),
                currencySymbol: currency,
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Expense',
                    message: 'Delete this expense entry?',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(expenseLogProvider(vehicle.id).notifier)
                        .deleteExpenseLog(log.id);
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

// ─────────────────────────────────────────────────────────────────────────────
// Documents Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.documentAdd),
        child: const Icon(Icons.add_rounded),
      ),
      body: docsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.description_rounded,
              title: 'No documents yet',
              subtitle: 'Tap + to add insurance, PUC, or other documents',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 100),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final daysLeft = DateFormatter.daysUntil(doc.expiryDate);
              final color = daysLeft <= 7
                  ? AppColors.error
                  : daysLeft <= 30
                      ? AppColors.warning
                      : AppColors.success;
              return LogTile(
                icon: Icons.description_rounded,
                iconColor: color,
                title: doc.documentType,
                subtitle: DateFormatter.formatExpiry(doc.expiryDate),
                date: DateFormatter.format(doc.expiryDate),
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Document',
                    message: 'Delete this document?',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(documentProvider(vehicle.id).notifier)
                        .deleteDocument(doc.id);
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

// ─────────────────────────────────────────────────────────────────────────────
// Notes Tab
// ─────────────────────────────────────────────────────────────────────────────

class _NotesTab extends StatelessWidget {
  const _NotesTab({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final notes = vehicle.notes;
    if (notes == null || notes.isEmpty) {
      return const EmptyState(
        icon: Icons.notes_rounded,
        title: 'No notes',
        subtitle: 'Edit the vehicle to add notes',
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Text(
        notes,
        style: AppTextStyles.bodyLarge
            .copyWith(color: AppColors.textPrimaryDark, height: 1.6),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SkeletonListTile(),
        SkeletonListTile(),
        SkeletonListTile(),
      ],
    );
  }
}
