import 'package:flutter/material.dart';

import '../../core/enums/routine_status.dart';

class RoutineCard extends StatelessWidget {
  const RoutineCard({
    super.key,
    required this.title,
    required this.timeRange,
    required this.status,
    this.category,
    this.goal,
    this.onStart,
    this.onComplete,
    this.onSkip,
    this.extraActions = const [],
  });

  final String title;
  final String timeRange;
  final RoutineStatus status;
  final Widget? category;
  final String? goal;
  final VoidCallback? onStart;
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;
  final List<Widget> extraActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(colorScheme);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 44,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(timeRange, style: theme.textTheme.labelLarge),
                      const SizedBox(height: 2),
                      Text(title, style: theme.textTheme.titleMedium),
                    ],
                  ),
                ),
                _StatusPill(label: status.label, color: statusColor),
              ],
            ),
            if (category != null || goal != null) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ?category,
                  if (goal != null)
                    Text(
                      goal!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
            if (onStart != null ||
                onComplete != null ||
                onSkip != null ||
                extraActions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onStart != null)
                    OutlinedButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start'),
                    ),
                  if (onComplete != null)
                    FilledButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.check),
                      label: const Text('Complete'),
                    ),
                  if (onSkip != null)
                    TextButton.icon(
                      onPressed: onSkip,
                      icon: const Icon(Icons.skip_next_outlined),
                      label: const Text('Skip'),
                    ),
                  ...extraActions,
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(ColorScheme colorScheme) {
    return switch (status) {
      RoutineStatus.active || RoutineStatus.started => colorScheme.primary,
      RoutineStatus.completed ||
      RoutineStatus.recovered => const Color(0xFF16A34A),
      RoutineStatus.skipped => colorScheme.outline,
      RoutineStatus.missed => const Color(0xFFDC2626),
      RoutineStatus.rescheduled => const Color(0xFFD97706),
      RoutineStatus.upcoming => colorScheme.secondary,
    };
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
