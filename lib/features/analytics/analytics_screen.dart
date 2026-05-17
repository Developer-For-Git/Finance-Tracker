import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/providers/finance_providers.dart';
import '../../shared/widgets/glass_card.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final symbol = settings['currencySymbol'] as String;
    final selectedYear = ref.watch(selectedYearProvider);
    final yearlyTrend = ref.watch(yearlyTrendProvider);
    final breakdown = ref.watch(categoryBreakdownProvider);
    final categories = ref.watch(categoriesProvider);
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          floating: true,
          toolbarHeight: 70,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Analytics', style: Theme.of(context).textTheme.headlineLarge),
              Text('Track your spending patterns',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Year selector
                _buildYearSelector(context, selectedYear),
                const SizedBox(height: 20),

                // Summary Row
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        label: 'This Month Income',
                        amount: monthlyIncome,
                        color: AppColors.income,
                        symbol: symbol,
                        icon: Icons.trending_up_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard(
                        context,
                        label: 'This Month Expense',
                        amount: monthlyExpense,
                        color: AppColors.expense,
                        symbol: symbol,
                        icon: Icons.trending_down_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Bar Chart (Yearly Trend)
                Text('Yearly Overview', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  'Monthly income vs expense for $selectedYear',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildLegend('Income', AppColors.income),
                          const SizedBox(width: 16),
                          _buildLegend('Expense', AppColors.expense),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: _buildBarChart(yearlyTrend),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Pie Chart (Category Breakdown)
                if (breakdown.isNotEmpty) ...[
                  Text('Spending Breakdown', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Current month expenses by category',
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  AppCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 220,
                          child: _buildPieChart(breakdown, categories),
                        ),
                        const SizedBox(height: 20),
                        _buildCategoryLegend(context, breakdown, categories, symbol),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ] else ...[
                  _buildNoDataCard(context),
                  const SizedBox(height: 24),
                ],

                // Line Chart (Savings Trend)
                Text('Net Savings Trend', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text('Month by month savings for $selectedYear',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    height: 200,
                    child: _buildLineChart(yearlyTrend, symbol),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildYearSelector(BuildContext context, int selectedYear) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () => ref.read(selectedYearProvider.notifier).state = selectedYear - 1,
          icon: const Icon(Icons.chevron_left_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.bgCard,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          selectedYear.toString(),
          style: Theme.of(context)
              .textTheme
              .headlineLarge
              ?.copyWith(color: AppColors.tealPrimary),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: selectedYear < DateTime.now().year
              ? () => ref.read(selectedYearProvider.notifier).state = selectedYear + 1
              : null,
          icon: const Icon(Icons.chevron_right_rounded),
          style: IconButton.styleFrom(
            backgroundColor: AppColors.bgCard,
            foregroundColor: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required String label,
    required double amount,
    required Color color,
    required String symbol,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            Formatters.formatCurrency(amount, symbol: symbol),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<int, Map<String, double>> data) {
    final maxVal = data.values
        .expand((m) => m.values)
        .fold(0.0, math.max);

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.2 + 1,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal * 0.3 + 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                final idx = v.toInt() - 1;
                if (idx < 0 || idx >= 12) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    months[idx],
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: List.generate(12, (i) {
          final m = i + 1;
          final inc = data[m]?['income'] ?? 0;
          final exp = data[m]?['expense'] ?? 0;
          return BarChartGroupData(
            x: m,
            barRods: [
              BarChartRodData(
                toY: inc,
                color: AppColors.income,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              BarChartRodData(
                toY: exp,
                color: AppColors.expense,
                width: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
            barsSpace: 4,
          );
        }),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> breakdown, List categories) {
    final total = breakdown.values.fold(0.0, (s, v) => s + v);
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = <PieChartSectionData>[];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final cat = categories.cast<dynamic>().firstWhere(
            (c) => c.id == entry.key,
            orElse: () => null,
          );
      final colorIdx = cat?.colorIndex ?? (i % AppColors.categoryColors.length);
      final color = AppColors.categoryColors[colorIdx % AppColors.categoryColors.length];
      final pct = total > 0 ? (entry.value / total * 100) : 0.0;
      final isTouched = _touchedIndex == i;

      sections.add(PieChartSectionData(
        color: color,
        value: entry.value,
        title: pct > 5 ? '${pct.toStringAsFixed(0)}%' : '',
        radius: isTouched ? 90 : 75,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (event, response) {
            setState(() {
              if (event.isInterestedForInteractions &&
                  response != null &&
                  response.touchedSection != null) {
                _touchedIndex = response.touchedSection!.touchedSectionIndex;
              } else {
                _touchedIndex = -1;
              }
            });
          },
        ),
        sections: sections,
        sectionsSpace: 3,
        centerSpaceRadius: 50,
      ),
    );
  }

  Widget _buildLineChart(Map<int, Map<String, double>> data, String symbol) {
    final spots = <FlSpot>[];
    for (int m = 1; m <= 12; m++) {
      final inc = data[m]?['income'] ?? 0;
      final exp = data[m]?['expense'] ?? 0;
      spots.add(FlSpot(m.toDouble(), inc - exp));
    }

    final maxVal = spots.map((s) => s.y.abs()).fold(0.0, math.max);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal * 0.4 + 1,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                const months = ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
                final idx = v.toInt() - 1;
                if (idx < 0 || idx >= 12) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    months[idx],
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            gradient: LinearGradient(
              colors: spots.any((s) => s.y < 0)
                  ? [AppColors.expense, AppColors.income]
                  : [AppColors.income, AppColors.tealLight],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.income.withOpacity(0.3),
                  AppColors.income.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                radius: 4,
                color: spot.y >= 0 ? AppColors.income : AppColors.expense,
                strokeWidth: 2,
                strokeColor: AppColors.bgCard,
              ),
            ),
          ),
        ],
        minY: spots.map((s) => s.y).fold(0.0, math.min) * 1.2 - 1,
        maxY: spots.map((s) => s.y).fold(0.0, math.max) * 1.2 + 1,
      ),
    );
  }

  Widget _buildCategoryLegend(
    BuildContext context,
    Map<String, double> breakdown,
    List categories,
    String symbol,
  ) {
    final total = breakdown.values.fold(0.0, (s, v) => s + v);
    final sortedEntries = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedEntries.take(6).map((entry) {
        final cat = categories.cast<dynamic>().firstWhere(
              (c) => c.id == entry.key,
              orElse: () => null,
            );
        final colorIdx = cat?.colorIndex ?? 0;
        final color =
            AppColors.categoryColors[colorIdx % AppColors.categoryColors.length];
        final pct = total > 0 ? (entry.value / total * 100) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                cat?.name ?? 'Other',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              const Spacer(),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(width: 12),
              Text(
                Formatters.formatCurrency(entry.value, symbol: symbol),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildNoDataCard(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          const Icon(Icons.pie_chart_outline_rounded,
              color: AppColors.textMuted, size: 48),
          const SizedBox(height: 12),
          Text('No expense data this month',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text('Add some expenses to see the breakdown',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
