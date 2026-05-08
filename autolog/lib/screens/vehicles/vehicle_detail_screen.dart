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
import '../../utils/vehicle_image_helper.dart';
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
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
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
  ConsumerState<_VehicleDetailView> createState() => _VehicleDetailViewState();
}

class _VehicleDetailViewState extends ConsumerState<_VehicleDetailView> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currency = ref.watch(currencySymbolProvider);
    final distanceUnit = ref.watch(distanceUnitProvider);
    final unitLabel = UnitConverter.label(distanceUnit);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              stretch: true,
              elevation: 0,
              backgroundColor: cs.surface,
              leading: IconButton(
                onPressed: () => context.pop(),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cs.surface.withAlpha(200), shape: BoxShape.circle),
                  child: Icon(Icons.arrow_back_rounded, color: cs.onSurface, size: 20),
                ),
              ),
              actions: [
                IconButton(
                  onPressed: () => context.push('/vehicles/${v.id}/edit'),
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: cs.surface.withAlpha(200), shape: BoxShape.circle),
                    child: Icon(Icons.edit_rounded, color: cs.onSurface, size: 20),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              flexibleSpace: FlexibleSpaceBar(
                stretchModes: const [StretchMode.zoomBackground],
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [cs.primary.withAlpha(20), cs.surface],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Hero(
                          tag: 'vehicle_image_${v.id}',
                          child: VehicleImageHelper.getIllustration(
                            v.vehicleType,
                            brand: v.brand,
                            width: 240,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                centerTitle: false,
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                  child: Text(
                    v.nickname,
                    style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.5),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v.nickname,
                      style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${v.brand} ${v.model} • ${v.year}',
                      style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: cs.primary.withAlpha(40)),
                      ),
                      child: Text(
                        v.numberPlate.toUpperCase(),
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Fuel'),
                    Tab(text: 'Service'),
                    Tab(text: 'Expenses'),
                    Tab(text: 'Docs'),
                  ],
                ),
                cs.surface,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _OverviewTab(vehicle: v, currency: currency, unitLabel: unitLabel),
            _FuelLogsTab(vehicle: v, currency: currency),
            _ServiceLogsTab(vehicle: v, currency: currency),
            _ExpensesTab(vehicle: v, currency: currency),
            _DocumentsTab(vehicle: v),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.vehicle, required this.currency, required this.unitLabel});
  final Vehicle vehicle;
  final String currency;
  final String unitLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fuelLogsAsync = ref.watch(fuelLogProvider(vehicle.id));
    final serviceLogsAsync = ref.watch(serviceLogProvider(vehicle.id));
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: StatCard(
                label: 'Odometer',
                value: '${vehicle.odometerKm.toStringAsFixed(0)}',
                subtitle: unitLabel,
                icon: Icons.speed_rounded,
                iconColor: AppColors.info,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: fuelLogsAsync.when(
                loading: () => const SkeletonCard(height: 100),
                error: (_, __) => const SizedBox.shrink(),
                data: (logs) {
                  final withMileage = logs.where((l) => l.mileage != null).toList();
                  final avgMileage = withMileage.isEmpty
                      ? null
                      : withMileage.map((l) => l.mileage!).fold(0.0, (a, b) => a + b) / withMileage.length;
                  final unit = MileageCalculator.efficiencyUnit(vehicle.fuelType, customUnit: vehicle.customFuelUnit);
                  return StatCard(
                    label: 'Efficiency',
                    value: avgMileage != null ? avgMileage.toStringAsFixed(1) : 'N/A',
                    subtitle: unit,
                    icon: Icons.local_gas_station_rounded,
                    iconColor: AppColors.fuelPetrol,
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        serviceLogsAsync.when(
          loading: () => const SkeletonCard(height: 100),
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
        if (vehicle.notes != null && vehicle.notes!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Notes', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withAlpha(20)),
            ),
            child: Text(
              vehicle.notes!,
              style: TextStyle(color: cs.onSurfaceVariant, height: 1.5, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class _FuelLogsTab extends ConsumerWidget {
  const _FuelLogsTab({required this.vehicle, required this.currency});
  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(fuelLogProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('${AppRoutes.fuelLogAdd}?vehicleId=${vehicle.id}'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry'),
      ),
      body: logsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.local_gas_station_rounded,
              title: 'No fuel history',
              subtitle: 'Track your fuel consumption to see mileage analytics.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return LogTile(
                icon: Icons.local_gas_station_rounded,
                iconColor: AppColors.fuelPetrol,
                title: log.mileage != null
                    ? '${log.mileage!.toStringAsFixed(1)} ${MileageCalculator.efficiencyUnit(vehicle.fuelType)}'
                    : '${log.quantity.toStringAsFixed(1)} ${MileageCalculator.quantityUnit(vehicle.fuelType)}',
                subtitle: log.stationName ?? 'Fuel refilled',
                date: DateFormatter.formatShort(log.date),
                amount: log.totalPrice.toStringAsFixed(0),
                currencySymbol: currency,
                onDelete: () async {
                  final confirmed = await showConfirmDialog(context, title: 'Delete Entry', message: 'Remove this fuel entry from history?');
                  if (confirmed == true) {
                    await ref.read(fuelLogProvider(vehicle.id).notifier).deleteFuelLog(log.id, vehicle.fuelType);
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

class _ServiceLogsTab extends ConsumerWidget {
  const _ServiceLogsTab({required this.vehicle, required this.currency});
  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(serviceLogProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.serviceLogAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Service'),
      ),
      body: logsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.build_rounded,
              title: 'No service records',
              subtitle: 'Keep track of maintenance to ensure vehicle longevity.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return LogTile(
                icon: Icons.build_rounded,
                iconColor: AppColors.info,
                title: log.serviceType,
                subtitle: log.garageName ?? 'Service Center',
                date: DateFormatter.formatShort(log.date),
                amount: log.cost.toStringAsFixed(0),
                currencySymbol: currency,
                onDelete: () async {
                  final confirmed = await showConfirmDialog(context, title: 'Delete Record', message: 'Remove this service record?');
                  if (confirmed == true) {
                    await ref.read(serviceLogProvider(vehicle.id).notifier).deleteServiceLog(log.id);
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

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab({required this.vehicle, required this.currency});
  final Vehicle vehicle;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(expenseLogProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.expenseLogAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
      body: logsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_rounded,
              title: 'No expenses',
              subtitle: 'Track insurance, taxes, and other miscellaneous costs.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: logs.length,
            itemBuilder: (context, i) {
              final log = logs[i];
              return LogTile(
                icon: Icons.receipt_long_rounded,
                iconColor: AppColors.success,
                title: log.category,
                subtitle: log.notes ?? 'General expense',
                date: DateFormatter.formatShort(log.date),
                amount: log.amount.toStringAsFixed(0),
                currencySymbol: currency,
                onDelete: () async {
                  final confirmed = await showConfirmDialog(context, title: 'Delete Expense', message: 'Remove this expense entry?');
                  if (confirmed == true) {
                    await ref.read(expenseLogProvider(vehicle.id).notifier).deleteExpenseLog(log.id);
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

class _DocumentsTab extends ConsumerWidget {
  const _DocumentsTab({required this.vehicle});
  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(documentProvider(vehicle.id));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.documentAdd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Doc'),
      ),
      body: docsAsync.when(
        loading: () => const _SkeletonList(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (docs) {
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.description_rounded,
              title: 'No documents',
              subtitle: 'Store insurance, registration and PUC documents securely.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(top: 16, bottom: 100),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final daysLeft = DateFormatter.daysUntil(doc.expiryDate);
              final color = daysLeft <= 7 ? AppColors.error : daysLeft <= 30 ? AppColors.warning : AppColors.success;
              return LogTile(
                icon: Icons.description_rounded,
                iconColor: color,
                title: doc.documentType,
                subtitle: DateFormatter.formatExpiry(doc.expiryDate),
                date: DateFormatter.format(doc.expiryDate),
                onDelete: () async {
                  final confirmed = await showConfirmDialog(context, title: 'Delete Document', message: 'Permanently remove this document?');
                  if (confirmed == true) {
                    await ref.read(documentProvider(vehicle.id).notifier).deleteDocument(doc.id);
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
