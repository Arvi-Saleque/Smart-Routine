import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/analytics_providers.dart';
import '../data/analytics_repository.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(analyticsSummaryProvider);

    return AppScaffold(
      title: 'Analytics',
      body: summary.when(
        data: (data) => _AnalyticsBody(summary: data),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load analytics',
              message: '$error',
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _AnalyticsBody extends StatelessWidget {
  const _AnalyticsBody({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    if (!summary.hasAnyData) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionHeader(
            title: 'Productivity analytics',
            subtitle: 'Charts use local activity logs and focus sessions.',
          ),
          SizedBox(height: 16),
          EmptyState(
            icon: Icons.query_stats_outlined,
            title: 'No analytics yet',
            message:
                'Complete, skip, or focus on activities to build your first chart.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Productivity analytics',
          subtitle: 'Last 7 days from local activity.',
        ),
        const SizedBox(height: 16),
        _StatGrid(summary: summary),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Daily score',
          child: _DailyScoreChart(points: summary.dailyScores),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Weekly completion',
          child: _CompletionChart(points: summary.completionByDay),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Focus minutes',
          child: _FocusMinutesChart(points: summary.focusByDay),
        ),
        const SizedBox(height: 16),
        _ChartCard(
          title: 'Category completion',
          child: _CategoryCompletionChart(stats: summary.categoryStats),
        ),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.summary});

  final AnalyticsSummary summary;

  @override
  Widget build(BuildContext context) {
    final mostSkipped = summary.mostSkippedRoutine;
    final recoveryRate = summary.recoveryRate;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _StatTile(
          icon: Icons.score_outlined,
          label: 'Average score',
          value: '${summary.averageScore}',
        ),
        _StatTile(
          icon: Icons.check_circle_outline,
          label: 'Completed',
          value: '${summary.completedRoutines}',
        ),
        _StatTile(
          icon: Icons.timer_outlined,
          label: 'Focus minutes',
          value: '${summary.totalFocusMinutes}',
        ),
        _StatTile(
          icon: Icons.restart_alt,
          label: 'Recovery rate',
          value: recoveryRate == null
              ? '--'
              : '${(recoveryRate * 100).round()}%',
        ),
        _StatTile(
          icon: Icons.skip_next_outlined,
          label: 'Most skipped',
          value: mostSkipped == null
              ? '--'
              : '${mostSkipped.title} (${mostSkipped.skippedCount})',
          wide: true,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: wide ? double.infinity : 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(height: 10),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: child),
          ],
        ),
      ),
    );
  }
}

class _DailyScoreChart extends StatelessWidget {
  const _DailyScoreChart({required this.points});

  final List<DailyScorePoint> points;

  @override
  Widget build(BuildContext context) {
    if (!points.any((point) => point.hasScore)) {
      return const EmptyState(
        icon: Icons.show_chart,
        title: 'No score data',
        message: 'Daily scores appear after activity data is saved.',
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: false),
        titlesData: _titles(points.map((point) => point.dateKey).toList()),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var index = 0; index < points.length; index++)
                FlSpot(index.toDouble(), points[index].score.toDouble()),
            ],
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class _CompletionChart extends StatelessWidget {
  const _CompletionChart({required this.points});

  final List<CompletionPoint> points;

  @override
  Widget build(BuildContext context) {
    if (!points.any((point) => point.plannedCount > 0)) {
      return const EmptyState(
        icon: Icons.bar_chart,
        title: 'No completion data',
        message: 'Completion bars appear after activity logs exist.',
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return BarChart(
      BarChartData(
        maxY: 100,
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        titlesData: _titles(points.map((point) => point.dateKey).toList()),
        barGroups: [
          for (var index = 0; index < points.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points[index].completionRate * 100,
                  color: colorScheme.primary,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _FocusMinutesChart extends StatelessWidget {
  const _FocusMinutesChart({required this.points});

  final List<FocusMinutesPoint> points;

  @override
  Widget build(BuildContext context) {
    if (!points.any((point) => point.minutes > 0)) {
      return const EmptyState(
        icon: Icons.timer_outlined,
        title: 'No focus data',
        message: 'Focus minutes appear after sessions are saved.',
      );
    }

    final maxMinutes = points.fold<int>(
      0,
      (max, point) => point.minutes > max ? point.minutes : max,
    );
    final colorScheme = Theme.of(context).colorScheme;

    return BarChart(
      BarChartData(
        maxY: (maxMinutes <= 0 ? 10 : maxMinutes).toDouble(),
        borderData: FlBorderData(show: false),
        gridData: const FlGridData(show: true),
        titlesData: _titles(points.map((point) => point.dateKey).toList()),
        barGroups: [
          for (var index = 0; index < points.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: points[index].minutes.toDouble(),
                  color: colorScheme.tertiary,
                  width: 16,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CategoryCompletionChart extends StatelessWidget {
  const _CategoryCompletionChart({required this.stats});

  final List<CategoryCompletionStat> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const EmptyState(
        icon: Icons.pie_chart_outline,
        title: 'No category data',
        message: 'Category slices appear after activity logs exist.',
      );
    }

    return PieChart(
      PieChartData(
        centerSpaceRadius: 36,
        sectionsSpace: 2,
        sections: [
          for (final stat in stats.take(6))
            PieChartSectionData(
              value: stat.completedCount <= 0
                  ? 0.1
                  : stat.completedCount.toDouble(),
              title: '${(stat.completionRate * 100).round()}%',
              color: Color(stat.colorValue),
              radius: 70,
              titleStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
              badgeWidget: _CategoryBadge(label: stat.categoryName),
              badgePositionPercentageOffset: 1.25,
            ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
    );
  }
}

FlTitlesData _titles(List<String> dateKeys) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: true, reservedSize: 36),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 34,
        interval: 1,
        getTitlesWidget: (value, meta) {
          final index = value.toInt();
          if (index < 0 || index >= dateKeys.length) {
            return const SizedBox.shrink();
          }
          final parts = dateKeys[index].split('-');
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('${parts[1]}/${parts[2]}'),
          );
        },
      ),
    ),
  );
}
