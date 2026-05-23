import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section_header.dart';
import '../application/smart_coach_engine.dart';
import '../application/smart_coach_providers.dart';

class SmartCoachScreen extends ConsumerWidget {
  const SmartCoachScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(smartCoachInsightsProvider);

    return AppScaffold(
      title: 'Smart Coach',
      body: insights.when(
        data: (items) => _SmartCoachBody(insights: items),
        error: (error, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EmptyState(
              icon: Icons.error_outline,
              title: 'Could not load coach',
              message: '$error',
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _SmartCoachBody extends StatelessWidget {
  const _SmartCoachBody({required this.insights});

  final List<SmartCoachInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SectionHeader(
            title: 'Rule-based coaching',
            subtitle: 'Generated locally without paid AI APIs.',
          ),
          SizedBox(height: 16),
          EmptyState(
            icon: Icons.lightbulb_outline,
            title: 'Coach is waiting for data',
            message:
                'Complete, miss, recover, or skip routines to unlock local suggestions.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(
          title: 'Rule-based coaching',
          subtitle: 'Generated locally without paid AI APIs.',
        ),
        const SizedBox(height: 16),
        for (final insight in insights) ...[
          _InsightCard(insight: insight),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final SmartCoachInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorFor(context, insight.severity);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconFor(insight.category), color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    insight.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _SeverityPill(severity: insight.severity, color: color),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              insight.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward),
                label: Text(insight.actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(SmartCoachCategory category) {
    return switch (category) {
      SmartCoachCategory.overplanning => Icons.event_busy_outlined,
      SmartCoachCategory.routineHealth => Icons.trending_up,
      SmartCoachCategory.recovery => Icons.restart_alt,
      SmartCoachCategory.timing => Icons.schedule,
      SmartCoachCategory.categoryBalance => Icons.category_outlined,
    };
  }

  Color _colorFor(BuildContext context, SmartCoachSeverity severity) {
    final colorScheme = Theme.of(context).colorScheme;
    return switch (severity) {
      SmartCoachSeverity.warning => const Color(0xFFD97706),
      SmartCoachSeverity.success => const Color(0xFF16A34A),
      SmartCoachSeverity.info => colorScheme.primary,
    };
  }
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill({required this.severity, required this.color});

  final SmartCoachSeverity severity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        severity.name,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
