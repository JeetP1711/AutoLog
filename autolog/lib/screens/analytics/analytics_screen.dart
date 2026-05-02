import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../services/analytics_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton_loader.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final year = DateTime.now().year;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(title: const Text('Analytics')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _MonthlyFuelChart(year: year, currency: currency),
          const SizedBox(height: AppSpacing.lg),
          _MileageTrendChart(),
          const SizedBox(height: AppSpacing.lg),
          _ExpensePieChart(currency: currency),
          const SizedBox(height: AppSpacing.lg),
          _YearlyMaintenanceChart(currency: currency),
          const SizedBox(height: AppSpacing.lg),
          _VehicleComparisonChart(currency: currency),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Monthly Fuel Spend Bar Chart
// ─────────────────────────────────────────────────────────────────────────────

class _MonthlyFuelChart extends ConsumerWidget {
  const _MonthlyFuelChart({required this.year, required this.currency});
  final int year;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(monthlyFuelSpendProvider(year));

    return _ChartCard(
      title: 'Monthly Fuel Spend ($year)',
      icon: Icons.local_gas_station_rounded,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 180),
        error: (_, __) => const _ChartError(),
        data: (points) {
          final nonZero = points.where((p) => p.totalSpend > 0).toList();
          if (nonZero.length < 2) {
            return const _EmptyChart(message: 'Add more fuel logs to see trends');
          }
          return SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: points.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalSpend,
                        color: AppColors.primaryBlue,
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        points[v.toInt()].label,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.formatCompact(v, currency),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.darkDivider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mileage Trend Line Chart
// ─────────────────────────────────────────────────────────────────────────────

class _MileageTrendChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];
    if (vehicles.isEmpty) return const SizedBox.shrink();

    final vehicleId = vehicles.first.id;
    final dataAsync = ref.watch(mileageTrendProvider(vehicleId));

    return _ChartCard(
      title: 'Mileage Trend',
      icon: Icons.trending_up_rounded,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 180),
        error: (_, __) => const _ChartError(),
        data: (points) {
          if (points.length < 2) {
            return const _EmptyChart(
                message: 'Add more full-tank fuel logs to see mileage trends');
          }
          return SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: points.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.mileage);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.success.withAlpha(30),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.darkDivider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expense Pie Chart
// ─────────────────────────────────────────────────────────────────────────────

class _ExpensePieChart extends ConsumerWidget {
  const _ExpensePieChart({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(expenseBreakdownProvider);

    return _ChartCard(
      title: 'Expense Breakdown',
      icon: Icons.pie_chart_rounded,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 200),
        error: (_, __) => const _ChartError(),
        data: (entries) {
          if (entries.length < 2) {
            return const _EmptyChart(
                message: 'Add more logs to see expense breakdown');
          }
          final total = entries.fold(0.0, (s, e) => s + e.total);
          return SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: entries.asMap().entries.map((e) {
                        final color = AppColors
                            .chartPalette[e.key % AppColors.chartPalette.length];
                        return PieChartSectionData(
                          value: e.value.total,
                          color: color,
                          title: '${(e.value.total / total * 100).toStringAsFixed(0)}%',
                          titleStyle: AppTextStyles.labelSmall
                              .copyWith(color: Colors.white),
                          radius: 70,
                        );
                      }).toList(),
                      sectionsSpace: 2,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.take(6).map((e) {
                    final color = AppColors
                        .chartPalette[e.key % AppColors.chartPalette.length];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                  color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(
                            e.value.category,
                            style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textSecondaryDark),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yearly Maintenance Bar Chart
// ─────────────────────────────────────────────────────────────────────────────

class _YearlyMaintenanceChart extends ConsumerWidget {
  const _YearlyMaintenanceChart({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(yearlyMaintenanceCostProvider);

    return _ChartCard(
      title: 'Yearly Maintenance Cost',
      icon: Icons.bar_chart_rounded,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 180),
        error: (_, __) => const _ChartError(),
        data: (points) {
          final nonZero = points.where((p) => p.totalCost > 0).toList();
          if (nonZero.length < 2) {
            return const _EmptyChart(
                message: 'Add more service and expense logs to see yearly trends');
          }
          return SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                barGroups: points.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalCost,
                        color: AppColors.warning,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        points[v.toInt()].year.toString(),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.formatCompact(v, currency),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textSecondaryDark),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppColors.darkDivider,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Comparison Chart
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleComparisonChart extends ConsumerWidget {
  const _VehicleComparisonChart({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];
    if (vehicles.length < 2) return const SizedBox.shrink();

    return _ChartCard(
      title: 'Vehicle Comparison',
      icon: Icons.compare_arrows_rounded,
      child: SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Select a vehicle to view ownership cost',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondaryDark),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared chart widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ChartCard extends StatelessWidget {
  const _ChartCard(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  title,
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.textPrimaryDark),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondaryDark),
        ),
      ),
    );
  }
}

class _ChartError extends StatelessWidget {
  const _ChartError();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 80,
      child: Center(
        child: Text('Failed to load chart data',
            style: TextStyle(color: AppColors.error)),
      ),
    );
  }
}
