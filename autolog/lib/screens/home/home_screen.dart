import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/analytics_provider.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/log_tile.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/stat_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehicleProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Scaffold(
            appBar: AppBar(
        title: const Text('AutoLog'),
        actions: [
          _AlertsBadge(ref: ref),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: vehiclesAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_rounded,
              title: 'No vehicles yet',
              subtitle: 'Add your first vehicle to start tracking',
              actionLabel: 'Add Vehicle',
              onAction: () => context.push(AppRoutes.vehiclesAdd),
            );
          }
          return _HomeBody(vehicles: vehicles, currency: currency);
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      children: const [
        SizedBox(height: AppSpacing.md),
        SkeletonCard(height: 100),
        SkeletonCard(height: 80),
        SkeletonCard(height: 80),
        SkeletonListTile(),
        SkeletonListTile(),
        SkeletonListTile(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeBody
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({required this.vehicles, required this.currency});
  final List<Vehicle> vehicles;
  final String currency;

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  Future<void> _refresh() async {
    ref.invalidate(vehicleProvider);
    ref.invalidate(allFuelLogsStreamProvider);
    ref.invalidate(allServiceLogsStreamProvider);
    ref.invalidate(allExpenseLogsStreamProvider);
    ref.invalidate(expiringSoonProvider);
    ref.invalidate(allServiceLogsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final monthlySpendAsync = ref.watch(currentMonthFuelSpendProvider);
    final yearlySpendAsync = ref.watch(currentYearTotalSpendProvider);
    final expiringSoonAsync = ref.watch(expiringSoonProvider);
    final serviceLogsAsync = ref.watch(allServiceLogsProvider);
    final currency = widget.currency;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primaryBlue,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          const SizedBox(height: AppSpacing.md),

          // ── Stats row ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Vehicles',
                    value: widget.vehicles.length.toString(),
                    icon: Icons.directions_car_rounded,
                    iconColor: AppColors.primaryBlue,
                    onTap: () => context.go(AppRoutes.vehicles),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: monthlySpendAsync.when(
                    loading: () => const SkeletonCard(height: 90),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (spend) => StatCard(
                      label: 'Fuel This Month',
                      value: CurrencyFormatter.formatCompact(spend, currency),
                      icon: Icons.local_gas_station_rounded,
                      iconColor: AppColors.fuelPetrol,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Yearly spend ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: yearlySpendAsync.when(
              loading: () => const SkeletonCard(height: 80),
              error: (_, __) => const SizedBox.shrink(),
              data: (spend) => StatCard(
                label: 'Total Spend This Year',
                value: CurrencyFormatter.format(spend, currency),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.success,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Expiring documents ─────────────────────────────────────────────
          expiringSoonAsync.when(
            loading: () => const SkeletonListTile(),
            error: (_, __) => const SizedBox.shrink(),
            data: (docs) {
              if (docs.isEmpty) return const SizedBox.shrink();
              return _Section(
                title: 'Expiring Documents',
                icon: Icons.warning_amber_rounded,
                iconColor: AppColors.warning,
                children: docs.take(3).map((doc) => LogTile(
                  icon: Icons.description_rounded,
                  iconColor: AppColors.warning,
                  title: doc.documentType,
                  subtitle: DateFormatter.formatExpiry(doc.expiryDate),
                  date: DateFormatter.format(doc.expiryDate),
                  onTap: () {},
                )).toList(),
              );
            },
          ),

          // ── Upcoming services ──────────────────────────────────────────────
          serviceLogsAsync.when(
            loading: () => const SkeletonListTile(),
            error: (_, __) => const SizedBox.shrink(),
            data: (logs) {
              final upcoming = logs.where((l) {
                if (l.nextDueDate == null) return false;
                return DateFormatter.daysUntil(l.nextDueDate!) <= 30;
              }).take(3).toList();
              if (upcoming.isEmpty) return const SizedBox.shrink();
              return _Section(
                title: 'Upcoming Services',
                icon: Icons.build_rounded,
                iconColor: AppColors.info,
                children: upcoming.map((log) => LogTile(
                  icon: Icons.build_rounded,
                  iconColor: AppColors.info,
                  title: log.serviceType,
                  subtitle: log.garageName ?? 'Service due',
                  date: log.nextDueDate != null
                      ? DateFormatter.format(log.nextDueDate!)
                      : '',
                  onTap: () {},
                )).toList(),
              );
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // ── Quick add buttons ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              'Quick Add',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondaryDark,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              children: [
                _QuickAddButton(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel',
                  color: AppColors.fuelPetrol,
                  onTap: () => context.push(AppRoutes.fuelLogAdd),
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickAddButton(
                  icon: Icons.build_rounded,
                  label: 'Service',
                  color: AppColors.info,
                  onTap: () => context.push(AppRoutes.serviceLogAdd),
                ),
                const SizedBox(width: AppSpacing.sm),
                _QuickAddButton(
                  icon: Icons.receipt_long_rounded,
                  label: 'Expense',
                  color: AppColors.success,
                  onTap: () => context.push(AppRoutes.expenseLogAdd),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AlertsBadge
// ─────────────────────────────────────────────────────────────────────────────

class _AlertsBadge extends ConsumerWidget {
  const _AlertsBadge({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiring = ref.watch(expiringSoonProvider).valueOrNull ?? [];
    final count = expiring.length;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_rounded),
          onPressed: () => context.push(AppRoutes.reminders),
        ),
        if (count > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Section
// ─────────────────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimaryDark,
                ),
              ),
            ],
          ),
        ),
        ...children,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _QuickAddButton
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
