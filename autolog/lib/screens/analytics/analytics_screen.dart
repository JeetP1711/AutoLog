import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/analytics_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/vehicle_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/skeleton_loader.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final year = DateTime.now().year;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: CustomScrollView(
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
                'Statistics',
                style: tt.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MonthlyFuelChart(year: year, currency: currency),
                const SizedBox(height: 20),
                _MileageTrendChart(),
                const SizedBox(height: 20),
                _ExpensePieChart(currency: currency),
                const SizedBox(height: 20),
                _YearlyMaintenanceChart(currency: currency),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyFuelChart extends ConsumerWidget {
  const _MonthlyFuelChart({required this.year, required this.currency});
  final int year;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(monthlyFuelSpendProvider(year));
    final cs = Theme.of(context).colorScheme;

    return _ChartCard(
      title: 'Fuel Spend Monthly ($year)',
      icon: Icons.local_gas_station_rounded,
      color: AppColors.fuelPetrol,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 200),
        error: (_, __) => const _ChartError(),
        data: (points) {
          final nonZero = points.where((p) => p.totalSpend > 0).toList();
          if (nonZero.isEmpty) {
            return const _EmptyChart(message: 'Add fuel logs to see monthly spend data');
          }
          return SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: points.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalSpend,
                        color: cs.primary,
                        width: 12,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          points[v.toInt()].label.substring(0, 1),
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withAlpha(150),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.formatCompact(v, currency),
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withAlpha(150),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outline.withAlpha(20),
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

class _MileageTrendChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehicleProvider).valueOrNull ?? [];
    if (vehicles.isEmpty) return const SizedBox.shrink();

    final vehicleId = vehicles.first.id;
    final dataAsync = ref.watch(mileageTrendProvider(vehicleId));
    final cs = Theme.of(context).colorScheme;

    return _ChartCard(
      title: 'Mileage Trend',
      icon: Icons.trending_up_rounded,
      color: AppColors.success,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 200),
        error: (_, __) => const _ChartError(),
        data: (points) {
          if (points.isEmpty) {
            return const _EmptyChart(message: 'Add full-tank logs to analyze mileage trend');
          }
          return SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  LineChartBarData(
                    spots: points.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.mileage);
                    }).toList(),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.success.withAlpha(40),
                          AppColors.success.withAlpha(0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(1),
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withAlpha(150),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outline.withAlpha(20),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: points.length == 1 ? -0.5 : null,
                maxX: points.length == 1 ? 0.5 : null,
                minY: points.length == 1 ? (points.first.mileage - 1).clamp(0, double.infinity) : null,
                maxY: points.length == 1 ? points.first.mileage + 1 : null,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ExpensePieChart extends ConsumerWidget {
  const _ExpensePieChart({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(expenseBreakdownProvider);
    final cs = Theme.of(context).colorScheme;

    return _ChartCard(
      title: 'Expense Distribution',
      icon: Icons.pie_chart_rounded,
      color: AppColors.primaryBlue,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 220),
        error: (_, __) => const _ChartError(),
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptyChart(message: 'No expenses tracked yet');
          }
          final total = entries.fold(0.0, (s, e) => s + e.total);
          return Column(
            children: [
              SizedBox(
                height: 180,
                child: PieChart(
                  PieChartData(
                    sections: entries.asMap().entries.map((e) {
                      final color = AppColors.chartPalette[e.key % AppColors.chartPalette.length];
                      return PieChartSectionData(
                        value: e.value.total,
                        color: color,
                        title: '${(e.value.total / total * 100).toStringAsFixed(0)}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                        radius: 65,
                      );
                    }).toList(),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: entries.asMap().entries.map((e) {
                  final color = AppColors.chartPalette[e.key % AppColors.chartPalette.length];
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        e.value.category,
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _YearlyMaintenanceChart extends ConsumerWidget {
  const _YearlyMaintenanceChart({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(yearlyMaintenanceCostProvider);
    final cs = Theme.of(context).colorScheme;

    return _ChartCard(
      title: 'Maintenance Trend',
      icon: Icons.auto_graph_rounded,
      color: AppColors.info,
      child: dataAsync.when(
        loading: () => const SkeletonCard(height: 200),
        error: (_, __) => const _ChartError(),
        data: (points) {
          final nonZero = points.where((p) => p.totalCost > 0).toList();
          if (nonZero.isEmpty) {
            return const _EmptyChart(message: 'Add service history to see yearly cost trends');
          }
          return SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: points.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.totalCost,
                        color: AppColors.info,
                        width: 20,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          points[v.toInt()].year.toString(),
                          style: TextStyle(
                            color: cs.onSurfaceVariant.withAlpha(150),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 45,
                      getTitlesWidget: (v, _) => Text(
                        CurrencyFormatter.formatCompact(v, currency),
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withAlpha(150),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: cs.outline.withAlpha(20),
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

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: cs.outline.withAlpha(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 120,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant.withAlpha(150),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
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
        child: Text(
          'Could not load chart data',
          style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
