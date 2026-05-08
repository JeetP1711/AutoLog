import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../providers/service_log_provider.dart';
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
      body: vehiclesAsync.when(
        loading: () => _buildSkeleton(),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyState(
              icon: Icons.directions_car_rounded,
              title: 'Welcome to AutoLog',
              subtitle: 'Add your first vehicle to start tracking expenses, services, and fuel mileage.',
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
        SizedBox(height: 100),
        SkeletonCard(height: 120),
        SizedBox(height: 20),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: SkeletonCard(height: 100)),
              SizedBox(width: 10),
              Expanded(child: SkeletonCard(height: 100)),
            ],
          ),
        ),
        SizedBox(height: 20),
        SkeletonListTile(),
        SkeletonListTile(),
      ],
    );
  }
}

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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    
    final monthlySpendAsync = ref.watch(currentMonthFuelSpendProvider);
    final yearlySpendAsync = ref.watch(currentYearTotalSpendProvider);
    final expiringSoonAsync = ref.watch(expiringSoonProvider);
    final serviceLogsAsync = ref.watch(allServiceLogsProvider);

    return RefreshIndicator(
      onRefresh: _refresh,
      color: cs.primary,
      edgeOffset: 100,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Header / Greeting ──────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.surface,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              title: Text(
                'Dashboard',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: cs.onSurface,
                ),
              ),
            ),
            actions: [
              _AlertsBadge(ref: ref),
              const SizedBox(width: 16),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning!',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Main Stats ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'GARAGE',
                          value: '${widget.vehicles.length} Vehicles',
                          icon: Icons.directions_car_rounded,
                          iconColor: AppColors.primaryBlue,
                          onTap: () => context.go(AppRoutes.vehicles),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: monthlySpendAsync.when(
                          loading: () => const SkeletonCard(height: 90),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (spend) => StatCard(
                            label: 'FUEL THIS MONTH',
                            value: CurrencyFormatter.formatCompact(spend, widget.currency),
                            icon: Icons.local_gas_station_rounded,
                            iconColor: AppColors.fuelPetrol,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  yearlySpendAsync.when(
                    loading: () => const SkeletonCard(height: 90),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (spend) => StatCard(
                      label: 'TOTAL EXPENDITURE 2024',
                      value: CurrencyFormatter.format(spend, widget.currency),
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: AppColors.success,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Quick Actions ──────────────────────────────────────────
                  Text(
                    'Quick Actions',
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _QuickAction(
                        icon: Icons.local_gas_station_rounded,
                        label: 'Fuel',
                        color: AppColors.fuelPetrol,
                        onTap: () => context.push(AppRoutes.fuelLogAdd),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.build_rounded,
                        label: 'Service',
                        color: AppColors.info,
                        onTap: () => context.push(AppRoutes.serviceLogAdd),
                      ),
                      const SizedBox(width: 12),
                      _QuickAction(
                        icon: Icons.receipt_long_rounded,
                        label: 'Expense',
                        color: AppColors.success,
                        onTap: () => context.push(AppRoutes.expenseLogAdd),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // ── Expiring documents ─────────────────────────────────────────────
          expiringSoonAsync.when(
            loading: () => const SliverToBoxAdapter(child: SkeletonListTile()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (docs) {
              if (docs.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(title: 'Expiring Soon', icon: Icons.warning_amber_rounded, color: AppColors.warning),
                  ...docs.take(3).map((doc) => LogTile(
                    icon: Icons.description_rounded,
                    iconColor: AppColors.warning,
                    title: doc.documentType,
                    subtitle: DateFormatter.formatExpiry(doc.expiryDate),
                    date: DateFormatter.format(doc.expiryDate),
                    onTap: () {},
                  )),
                  const SizedBox(height: 16),
                ]),
              );
            },
          ),

          // ── Upcoming services ──────────────────────────────────────────────
          serviceLogsAsync.when(
            loading: () => const SliverToBoxAdapter(child: SkeletonListTile()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            data: (logs) {
              final upcoming = logs.where((l) {
                if (l.nextDueDate == null) return false;
                return DateFormatter.daysUntil(l.nextDueDate!) <= 30;
              }).take(3).toList();
              if (upcoming.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
              return SliverList(
                delegate: SliverChildListDelegate([
                  _SectionHeader(title: 'Upcoming Service', icon: Icons.build_rounded, color: AppColors.info),
                  ...upcoming.map((log) => LogTile(
                    icon: Icons.build_rounded,
                    iconColor: AppColors.info,
                    title: log.serviceType,
                    subtitle: log.garageName ?? 'Service due',
                    date: log.nextDueDate != null ? DateFormatter.format(log.nextDueDate!) : '',
                    onTap: () {},
                  )),
                  const SizedBox(height: 100), // Space for floating nav
                ]),
              );
            },
          ),
          
          if (!expiringSoonAsync.hasValue && !serviceLogsAsync.hasValue)
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

class _AlertsBadge extends ConsumerWidget {
  const _AlertsBadge({required this.ref});
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expiring = ref.watch(expiringSoonProvider).valueOrNull ?? [];
    final count = expiring.length;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withAlpha(100),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface, size: 22),
              onPressed: () => context.push(AppRoutes.reminders),
            ),
          ),
          if (count > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  count > 9 ? '9+' : count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.icon, required this.color});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outline.withAlpha(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
