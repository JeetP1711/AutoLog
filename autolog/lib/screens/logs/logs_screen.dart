import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/models.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/log_tile.dart';
import '../../widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Unified log entry model
// ─────────────────────────────────────────────────────────────────────────────

enum _LogCategory { fuel, service, expense, document }

class _LogEntry {
  const _LogEntry({
    required this.id,
    required this.vehicleId,
    required this.date,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.amount,
  });
  final String id;
  final String vehicleId;
  final DateTime date;
  final _LogCategory category;
  final String title;
  final String subtitle;
  final double? amount;
}

// ─────────────────────────────────────────────────────────────────────────────
// LogsScreen
// ─────────────────────────────────────────────────────────────────────────────

class LogsScreen extends ConsumerStatefulWidget {
  const LogsScreen({super.key});

  @override
  ConsumerState<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends ConsumerState<LogsScreen> {
  String _searchQuery = '';
  String? _vehicleFilter;
  _LogCategory? _categoryFilter;
  DateTimeRange? _dateRange;

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final fuelAsync = ref.watch(allFuelLogsProvider);
    final serviceAsync = ref.watch(allServiceLogsProvider);
    final expenseAsync = ref.watch(allExpenseLogsProvider);
    final currency = ref.watch(currencySymbolProvider);

    final isLoading = vehiclesAsync.isLoading ||
        fuelAsync.isLoading ||
        serviceAsync.isLoading ||
        expenseAsync.isLoading;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Activity Log'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textPrimaryDark),
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppColors.textSecondaryDark),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: AppColors.textSecondaryDark),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? ListView(
              children: const [
                SkeletonListTile(),
                SkeletonListTile(),
                SkeletonListTile(),
                SkeletonListTile(),
              ],
            )
          : _buildBody(
              context,
              vehicles: vehiclesAsync.valueOrNull ?? [],
              fuelLogs: fuelAsync.valueOrNull ?? [],
              serviceLogs: serviceAsync.valueOrNull ?? [],
              expenseLogs: expenseAsync.valueOrNull ?? [],
              currency: currency,
            ),
    );
  }

  Widget _buildBody(
    BuildContext context, {
    required List<Vehicle> vehicles,
    required List<FuelLog> fuelLogs,
    required List<ServiceLog> serviceLogs,
    required List<ExpenseLog> expenseLogs,
    required String currency,
  }) {
    // Build vehicle name map
    final vehicleNames = {for (final v in vehicles) v.id: v.nickname};

    // Build unified entries
    final entries = <_LogEntry>[
      ...fuelLogs.map((l) => _LogEntry(
            id: l.id,
            vehicleId: l.vehicleId,
            date: l.date,
            category: _LogCategory.fuel,
            title: 'Fuel Refill',
            subtitle: l.stationName ?? vehicleNames[l.vehicleId] ?? '',
            amount: l.totalPrice,
          )),
      ...serviceLogs.map((l) => _LogEntry(
            id: l.id,
            vehicleId: l.vehicleId,
            date: l.date,
            category: _LogCategory.service,
            title: l.serviceType,
            subtitle: l.garageName ?? vehicleNames[l.vehicleId] ?? '',
            amount: l.cost,
          )),
      ...expenseLogs.map((l) => _LogEntry(
            id: l.id,
            vehicleId: l.vehicleId,
            date: l.date,
            category: _LogCategory.expense,
            title: l.category,
            subtitle: l.notes ?? vehicleNames[l.vehicleId] ?? '',
            amount: l.amount,
          )),
    ];

    // Sort by date descending
    entries.sort((a, b) => b.date.compareTo(a.date));

    // Apply filters
    final filtered = entries.where((e) {
      if (_vehicleFilter != null && e.vehicleId != _vehicleFilter) return false;
      if (_categoryFilter != null && e.category != _categoryFilter) return false;
      if (_dateRange != null) {
        if (e.date.isBefore(_dateRange!.start) ||
            e.date.isAfter(_dateRange!.end)) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!e.title.toLowerCase().contains(q) &&
            !e.subtitle.toLowerCase().contains(q)) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return EmptyState(
        icon: Icons.history_rounded,
        title: _searchQuery.isNotEmpty ? 'No results found' : 'No activity yet',
        subtitle: _searchQuery.isNotEmpty
            ? 'Try a different search term'
            : 'Add fuel, service, or expense logs to see them here',
      );
    }

    return Column(
      children: [
        // Filter chips
        if (vehicles.length > 1 || _categoryFilter != null)
          _FilterBar(
            vehicles: vehicles,
            selectedVehicle: _vehicleFilter,
            selectedCategory: _categoryFilter,
            onVehicleChanged: (v) => setState(() => _vehicleFilter = v),
            onCategoryChanged: (c) => setState(() => _categoryFilter = c),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: 80),
            itemCount: filtered.length,
            itemBuilder: (context, i) {
              final entry = filtered[i];
              final vehicleName = vehicleNames[entry.vehicleId] ?? '';
              return LogTile(
                icon: _categoryIcon(entry.category),
                iconColor: _categoryColor(entry.category),
                title: entry.title,
                subtitle: vehicleName.isNotEmpty
                    ? '$vehicleName · ${entry.subtitle}'
                    : entry.subtitle,
                date: DateFormatter.formatShort(entry.date),
                amount: entry.amount?.toStringAsFixed(0),
                currencySymbol: currency,
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _categoryIcon(_LogCategory cat) {
    switch (cat) {
      case _LogCategory.fuel:
        return Icons.local_gas_station_rounded;
      case _LogCategory.service:
        return Icons.build_rounded;
      case _LogCategory.expense:
        return Icons.receipt_long_rounded;
      case _LogCategory.document:
        return Icons.description_rounded;
    }
  }

  Color _categoryColor(_LogCategory cat) {
    switch (cat) {
      case _LogCategory.fuel:
        return AppColors.fuelPetrol;
      case _LogCategory.service:
        return AppColors.info;
      case _LogCategory.expense:
        return AppColors.success;
      case _LogCategory.document:
        return AppColors.warning;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.vehicles,
    required this.selectedVehicle,
    required this.selectedCategory,
    required this.onVehicleChanged,
    required this.onCategoryChanged,
  });

  final List<Vehicle> vehicles;
  final String? selectedVehicle;
  final _LogCategory? selectedCategory;
  final void Function(String?) onVehicleChanged;
  final void Function(_LogCategory?) onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      child: Row(
        children: [
          // Category filters
          ..._LogCategory.values.map((cat) {
            final isSelected = selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: FilterChip(
                label: Text(_catLabel(cat)),
                selected: isSelected,
                onSelected: (_) => onCategoryChanged(isSelected ? null : cat),
                selectedColor: AppColors.primaryBlue.withAlpha(60),
                labelStyle: AppTextStyles.labelSmall.copyWith(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : AppColors.textSecondaryDark,
                ),
              ),
            );
          }),
          // Vehicle filters
          if (vehicles.length > 1)
            ...vehicles.map((v) {
              final isSelected = selectedVehicle == v.id;
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: FilterChip(
                  label: Text(v.nickname),
                  selected: isSelected,
                  onSelected: (_) =>
                      onVehicleChanged(isSelected ? null : v.id),
                  selectedColor: AppColors.primaryBlue.withAlpha(60),
                  labelStyle: AppTextStyles.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.primaryBlue
                        : AppColors.textSecondaryDark,
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _catLabel(_LogCategory cat) {
    switch (cat) {
      case _LogCategory.fuel:
        return 'Fuel';
      case _LogCategory.service:
        return 'Service';
      case _LogCategory.expense:
        return 'Expense';
      case _LogCategory.document:
        return 'Document';
    }
  }
}
