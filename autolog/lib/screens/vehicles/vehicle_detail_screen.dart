import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/enums.dart';
import '../../models/vehicle.dart';
import '../../providers/document_provider.dart';
import '../../providers/expense_log_provider.dart';
import '../../providers/fuel_log_provider.dart';
import '../../providers/service_log_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/log_tile.dart';
import '../../widgets/skeleton_loader.dart';

/// Displays detailed information about a single vehicle across six tabs.
class VehicleDetailScreen extends ConsumerWidget {
  /// The ID of the vehicle to display.
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = ref.watch(vehicleByIdProvider(vehicleId));

    if (vehicle == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Vehicle')),
        body: const Center(
          child: Text('Vehicle not found.'),
        ),
      );
    }

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Text(vehicle.nickname),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit vehicle',
              onPressed: () => context.push('/vehicles/$vehicleId/edit'),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Fuel Logs'),
              Tab(text: 'Service Logs'),
              Tab(text: 'Expenses'),
              Tab(text: 'Documents'),
              Tab(text: 'Notes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(vehicle: vehicle),
            _FuelLogsTab(vehicleId: vehicleId, vehicle: vehicle),
            _ServiceLogsTab(vehicleId: vehicleId, vehicle: vehicle),
            _ExpensesTab(vehicleId: vehicleId, vehicle: vehicle),
            _DocumentsTab(vehicleId: vehicleId, vehicle: vehicle),
            _NotesTab(vehicle: vehicle),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Overview Tab
// ─────────────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        // ── Vehicle photo / icon ─────────────────────────────────────────────
        Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primaryBlue.withAlpha(60),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: vehicle.photoPath != null
                ? Image.file(
                    File(vehicle.photoPath!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _VehicleIcon(vehicle),
                  )
                : _VehicleIcon(vehicle),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Nickname ─────────────────────────────────────────────────────────
        Center(
          child: Text(
            vehicle.nickname,
            style: AppTextStyles.headlineSmall.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            '${vehicle.brand} ${vehicle.model} · ${vehicle.year}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondaryDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Info cards ───────────────────────────────────────────────────────
        _InfoCard(
          children: [
            _InfoRow(
              icon: Icons.pin_outlined,
              label: 'Number Plate',
              value: vehicle.numberPlate.toUpperCase(),
            ),
            _InfoRow(
              icon: Icons.speed_outlined,
              label: 'Odometer',
              value: '${vehicle.odometerKm.toStringAsFixed(0)} km',
            ),
            _InfoRow(
              icon: Icons.local_gas_station_outlined,
              label: 'Fuel Type',
              value: _fuelLabel(vehicle.fuelType),
            ),
            _InfoRow(
              icon: Icons.commute_outlined,
              label: 'Vehicle Type',
              value: _vehicleTypeLabel(vehicle.vehicleType),
            ),
            if (vehicle.purchaseDate != null)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                label: 'Purchase Date',
                value: DateFormat('dd MMM yyyy').format(vehicle.purchaseDate!),
              ),
          ],
        ),
      ],
    );
  }

  String _fuelLabel(FuelType type) {
    switch (type) {
      case FuelType.petrol:
        return 'Petrol';
      case FuelType.diesel:
        return 'Diesel';
      case FuelType.cng:
        return 'CNG';
      case FuelType.electric:
        return 'Electric';
      case FuelType.hybrid:
        return 'Hybrid';
      case FuelType.lpg:
        return 'LPG';
      case FuelType.hydrogen:
        return 'Hydrogen';
      case FuelType.custom:
        return 'Custom';
    }
  }

  String _vehicleTypeLabel(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.scooter:
        return 'Scooter';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.custom:
        return 'Custom';
    }
  }
}

class _VehicleIcon extends StatelessWidget {
  const _VehicleIcon(this.vehicle);
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Icon(
      _icon(vehicle.vehicleType),
      size: 56,
      color: AppColors.primaryBlue,
    );
  }

  IconData _icon(VehicleType type) {
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          children: children
              .expand((w) => [w, const Divider(height: 1)])
              .toList()
            ..removeLast(),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fuel Logs Tab
// ─────────────────────────────────────────────────────────────────────────────

class _FuelLogsTab extends ConsumerWidget {
  const _FuelLogsTab({required this.vehicleId, required this.vehicle});
  final String vehicleId;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(fuelLogProvider(vehicleId));

    return Scaffold(
      body: logsAsync.when(
        loading: () => _buildSkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              icon: Icons.local_gas_station_rounded,
              title: 'No fuel logs yet',
              subtitle: 'Tap + to record your first refill.',
            );
          }
          final sorted = [...logs]
            ..sort((a, b) => b.date.compareTo(a.date));
          return ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxl + AppSpacing.xl,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final log = sorted[index];
              return LogTile(
                key: ValueKey(log.id),
                icon: Icons.local_gas_station_rounded,
                iconColor: AppColors.fuelPetrol,
                title:
                    '${log.quantity.toStringAsFixed(1)} L · ${log.isFullTank ? 'Full tank' : 'Partial'}',
                subtitle: log.stationName ?? 'Odometer: ${log.odometerKm.toStringAsFixed(0)} km',
                date: DateFormat('dd MMM yyyy').format(log.date),
                amount: log.totalPrice.toStringAsFixed(0),
                onTap: () => context.push(
                  '/logs/fuel/${log.id}/edit',
                ),
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Fuel Log',
                    message: 'Delete this fuel log entry?',
                    confirmLabel: 'Delete',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(fuelLogProvider(vehicleId).notifier)
                        .deleteFuelLog(log.id, vehicle.fuelType);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fuel_fab',
        onPressed: () => context.push(AppRoutes.fuelLogAdd),
        tooltip: 'Add fuel log',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonListTile(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service Logs Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceLogsTab extends ConsumerWidget {
  const _ServiceLogsTab({required this.vehicleId, required this.vehicle});
  final String vehicleId;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(serviceLogProvider(vehicleId));

    return Scaffold(
      body: logsAsync.when(
        loading: () => _buildSkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              icon: Icons.build_outlined,
              title: 'No service logs yet',
              subtitle: 'Tap + to record a service or maintenance entry.',
            );
          }
          final sorted = [...logs]
            ..sort((a, b) => b.date.compareTo(a.date));
          return ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxl + AppSpacing.xl,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final log = sorted[index];
              return LogTile(
                key: ValueKey(log.id),
                icon: Icons.build_rounded,
                iconColor: AppColors.warning,
                title: log.serviceType,
                subtitle: log.garageName ?? (log.odometerKm != null
                    ? 'Odometer: ${log.odometerKm!.toStringAsFixed(0)} km'
                    : 'No odometer recorded'),
                date: DateFormat('dd MMM yyyy').format(log.date),
                amount: log.cost.toStringAsFixed(0),
                onTap: () => context.push(
                  '/logs/service/${log.id}/edit',
                ),
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Service Log',
                    message: 'Delete this service log entry?',
                    confirmLabel: 'Delete',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(serviceLogProvider(vehicleId).notifier)
                        .deleteServiceLog(log.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'service_fab',
        onPressed: () => context.push(AppRoutes.serviceLogAdd),
        tooltip: 'Add service log',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonListTile(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expenses Tab
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.vehicleId, required this.vehicle});
  final String vehicleId;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(expenseLogProvider(vehicleId));

    return Scaffold(
      body: logsAsync.when(
        loading: () => _buildSkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No expenses yet',
              subtitle: 'Tap + to record an expense.',
            );
          }
          final sorted = [...logs]
            ..sort((a, b) => b.date.compareTo(a.date));
          return ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxl + AppSpacing.xl,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final log = sorted[index];
              return LogTile(
                key: ValueKey(log.id),
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.info,
                title: log.category,
                subtitle: log.notes ?? 'No notes',
                date: DateFormat('dd MMM yyyy').format(log.date),
                amount: log.amount.toStringAsFixed(0),
                onTap: () => context.push(
                  '/logs/expense/${log.id}/edit',
                ),
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Expense',
                    message: 'Delete this expense entry?',
                    confirmLabel: 'Delete',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(expenseLogProvider(vehicleId).notifier)
                        .deleteExpenseLog(log.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'expense_fab',
        onPressed: () => context.push(AppRoutes.expenseLogAdd),
        tooltip: 'Add expense',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonListTile(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Documents Tab
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.vehicleId, required this.vehicle});
  final String vehicleId;
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentProvider(vehicleId));

    return Scaffold(
      body: docsAsync.when(
        loading: () => _buildSkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return EmptyState(
              icon: Icons.folder_outlined,
              title: 'No documents yet',
              subtitle: 'Tap + to add insurance, PUC, or other documents.',
            );
          }
          final sorted = [...docs]
            ..sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
          return ListView.builder(
            padding: const EdgeInsets.only(
              top: AppSpacing.sm,
              bottom: AppSpacing.xxl + AppSpacing.xl,
            ),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              final doc = sorted[index];
              final isExpired = doc.expiryDate.isBefore(DateTime.now());
              final isExpiringSoon = !isExpired &&
                  doc.expiryDate
                      .isBefore(DateTime.now().add(const Duration(days: 30)));
              return LogTile(
                key: ValueKey(doc.id),
                icon: Icons.description_rounded,
                iconColor: isExpired
                    ? AppColors.error
                    : isExpiringSoon
                        ? AppColors.warning
                        : AppColors.success,
                title: doc.documentType,
                subtitle: doc.documentNumber != null
                    ? 'No. ${doc.documentNumber}'
                    : 'Expires: ${DateFormat('dd MMM yyyy').format(doc.expiryDate)}',
                date: DateFormat('dd MMM yyyy').format(doc.expiryDate),
                onTap: () => context.push(
                  '/documents/${doc.id}/edit',
                ),
                onDelete: () async {
                  final confirmed = await showConfirmDialog(
                    context,
                    title: 'Delete Document',
                    message: 'Delete "${doc.documentType}"?',
                    confirmLabel: 'Delete',
                  );
                  if (confirmed == true) {
                    await ref
                        .read(documentProvider(vehicleId).notifier)
                        .deleteDocument(doc.id);
                  }
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'document_fab',
        onPressed: () => context.push(AppRoutes.documentAdd),
        tooltip: 'Add document',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      itemCount: 5,
      itemBuilder: (_, __) => const SkeletonListTile(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notes Tab
// ─────────────────────────────────────────────────────────────────────────────

class _NotesTab extends ConsumerWidget {
  const _NotesTab({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = vehicle.notes;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: notes != null && notes.isNotEmpty
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notes',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textSecondaryDark,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          notes,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textPrimaryDark,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : EmptyState(
                icon: Icons.notes_rounded,
                title: 'No notes',
                subtitle: 'Edit the vehicle to add notes.',
                actionLabel: 'Edit Vehicle',
                onAction: () =>
                    context.push('/vehicles/${vehicle.id}/edit'),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        onPressed: () => context.push('/vehicles/${vehicle.id}/edit'),
        tooltip: 'Edit vehicle notes',
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}
